from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from dotenv import load_dotenv
load_dotenv()

from langgraph.graph import MessagesState
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from langgraph.graph import START, StateGraph
from langgraph.prebuilt import tools_condition
from langgraph.prebuilt import ToolNode
from langgraph.prebuilt.chat_agent_executor import AgentState


import asyncio
from pathlib import Path
import os

from openai import OpenAI
from app.agents.utils.images import encode_image
from app.agents.leonardo.llm_factory import get_llm

# Authenticated HTTP into the Rails app, scoped to the SIGNED-IN USER: it sends the
# per-user token Rails minted (state["api_token"], see LlamaPressState below) as
# `Authorization: LlamaBot <token>`. Rails verifies the signature, signs that user in,
# and applies its own gates — so this tool can only do what that user could do.
# LlamaBot cannot forge a token (it has no secret_key_base), which is what makes this
# safe to hand to a low-privilege user. Full writeup: LlamaBot docs/dev/user_api_mode.md.
from app.lib.llamapress_api import LlamaPressAPIState, rails_api_request

# Define base paths relative to project root
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent  # Go up to LlamaBot root
APP_DIR = PROJECT_ROOT / 'app'

# Global tools list
#
# Every tool added here is bounded ONLY by what it does itself. `rails_api_request` is
# bounded by the user's Rails permissions; a tool like `bash_command` would not be, and
# would hand whoever can select this mode the Rails console. Add deliberately.
tools = [rails_api_request]

# System message
sys_msg = """You are a helpful assistant. Your favorite animal is cyborg llama.

You can call this LlamaPress app's JSON API with the `rails_api_request` tool. It runs
as the signed-in user, with their permissions — so if a request comes back 403, that is
the correct answer: say so plainly rather than looking for another route to the data.
Only paths under /api/ are reachable.

Available today:
  GET  /api/users        list users (supports ?q=<substring>)
  GET  /api/users/:id    fetch one user
  POST /api/users        create a user — body: {"user": {"email": ..., "password": ..., "name": ...}}

Before any POST, tell the user exactly what you're about to send and get their OK."""
# Warning: Brittle - None type will break this when it's injected into the state for the tool call, and it silently fails. So if it doesn't map state types properly from the frontend, it will break. (must be exactly what's defined here).
class LlamaPressState(LlamaPressAPIState):
    agent_prompt: str

# Node
def leo(state: LlamaPressState):
#    read_rails_file("app/agents/llamabot/nodes.py") # Testing.
   llm = get_llm("deepseek-v4-flash")
   llm_with_tools = llm.bind_tools(tools)

   custom_prompt_instructions_from_llamapress_dev = state.get("agent_prompt")
   full_sys_msg = SystemMessage(content=f"""{sys_msg} Here are additional instructions provided by the developer: <DEVELOPER_INSTRUCTIONS> {custom_prompt_instructions_from_llamapress_dev} </DEVELOPER_INSTRUCTIONS>""")

   return {"messages": [llm_with_tools.invoke([full_sys_msg] + state["messages"])]}

def build_workflow(checkpointer=None):
    # Graph
    builder = StateGraph(LlamaPressState)

    # Define nodes: these do the work
    builder.add_node("leo", leo)
    builder.add_node("tools", ToolNode(tools))

    # Define edges: these determine how the control flow moves
    builder.add_edge(START, "leo")
    builder.add_conditional_edges(
        "leo",
        # If the latest message (result) from leo is a tool call -> tools_condition routes to tools
        # If the latest message (result) from leo is a not a tool call -> tools_condition routes to END
        tools_condition,
    )
    builder.add_edge("tools", "leo")
    react_graph = builder.compile(checkpointer=checkpointer)

    return react_graph