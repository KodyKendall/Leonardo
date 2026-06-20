"""
User Mode (API) agent — interacts with the LlamaPress Rails app through its
authenticated HTTP API (the "llamapress_api" layer), NOT the Rails console.

How this differs from `rails_user_mode_agent`:
- `rails_user_mode_agent` runs `bundle exec rails runner ...` via `bash_command`, i.e.
  raw ActiveRecord access to the database (CREATE/READ/UPDATE/DELETE everything).
- This agent can only do what the app exposes over HTTP and what the signed-in user is
  allowed to do. Every request is authenticated with the per-request `api_token`
  (`Authorization: LlamaBot <token>`) and only reaches Rails actions explicitly marked
  `llama_bot_allow`. It is the safe, app-mediated way to "do things through the
  LlamaPress App" (e.g. query Users).

Wiring (per-instance overlay, no image rebuild):
- Registered in `langgraph/langgraph.json` as
  `"user_api_agent": "./user_agents/user_api_agent/nodes.py:build_workflow"`.
  (Host path is `langgraph/agents/user_api_agent/nodes.py`; the compose mount
  `./langgraph/agents:/app/app/user_agents` renames the dir to `user_agents`
  inside the container, so the overlay namespace is `./user_agents/...` — same
  as the `leo` agent. `./agents/...` entries are the LlamaBot image's built-ins.)
- `api_token` arrives in agent state from the Rails `AgentStateBuilder`.
- Tools call `make_api_request_to_llamapress(...)` from `app/agents/utils/`.
"""

import json
import logging
from datetime import date
from typing import NotRequired

from langchain.agents import create_agent, AgentState
from langchain.tools import tool, ToolRuntime
from langchain_core.messages import SystemMessage

from app.agents.leonardo.llm_factory import get_llm
from app.agents.utils.make_api_request_to_llamapress import make_api_request_to_llamapress

logger = logging.getLogger(__name__)


class UserApiState(AgentState):
    # WARNING (brittle): these keys must match what the Rails AgentStateBuilder sends,
    # or LangGraph will silently fail to map state into the graph. `api_token`
    # authenticates the HTTP calls back into the LlamaPress app.
    api_token: str
    agent_prompt: NotRequired[str]
    llm_model: NotRequired[str]


def _format(result) -> str:
    """`make_api_request_to_llamapress` returns parsed JSON on success or an error string."""
    if isinstance(result, str):
        return result
    return json.dumps(result, default=str)


@tool
async def search_users(query: str, runtime: ToolRuntime) -> str:
    """Search the LlamaPress app's Users by email or name.

    Args:
        query: Substring to match against a user's email or name. Pass "" to list users.

    Returns up to 25 matches as a JSON array of {id, email, name, admin, created_at}.
    """
    api_token = runtime.state.get("api_token")
    result = await make_api_request_to_llamapress(
        "GET", "/api/users", api_token=api_token, params={"q": query}
    )
    return _format(result)


@tool
async def get_user(user_id: int, runtime: ToolRuntime) -> str:
    """Fetch a single LlamaPress User by id. Returns the user as JSON, or an error string."""
    api_token = runtime.state.get("api_token")
    result = await make_api_request_to_llamapress(
        "GET", f"/api/users/{user_id}", api_token=api_token
    )
    return _format(result)


SYSTEM_PROMPT = """You are **Leonardo User Mode** — you help the user inspect and work with
their LlamaPress application's data by calling the app's own HTTP API (never the database
directly).

Available tools:
- search_users(query): find users by email or name (empty query lists users)
- get_user(user_id): look up a single user by id

Guidelines:
- Use the tools to answer questions about the app's data; never invent or guess values.
- Every call runs as the authenticated user and is limited to what the app permits. If a
  call returns an authorization or HTTP error, explain it plainly instead of retrying blindly.
- Be concise: summarize results clearly and show the key fields (for lists, id + email + name).
"""

TOOLS = [search_users, get_user]


def build_workflow(checkpointer=None):
    """Build the User Mode (API) agent workflow."""
    today = date.today().strftime("%Y-%m-%d")
    system_prompt = SystemMessage(content=f"{SYSTEM_PROMPT}\n\n---\nToday's Date: {today}")

    return create_agent(
        model=get_llm("deepseek-v4-flash"),
        tools=TOOLS,
        system_prompt=system_prompt,
        state_schema=UserApiState,
        checkpointer=checkpointer,
    )
