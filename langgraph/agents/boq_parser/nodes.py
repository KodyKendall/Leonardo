from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langgraph.graph import StateGraph, START
from langgraph.prebuilt import tools_condition, ToolNode, InjectedState
from langgraph.prebuilt.chat_agent_executor import AgentState
from langchain_core.messages import SystemMessage
from typing import Annotated, Optional, List, Dict, Any
from app.agents.utils.make_api_request_to_llamapress import make_api_request_to_llamapress
import logging
import csv
import io

logger = logging.getLogger(__name__)

# System message for the BOQ parser agent
sys_msg = """You are an expert Bill of Quantities (BOQ) parsing assistant. Your role is to:

1. Analyze CSV files containing construction or project cost breakdowns
2. Extract line items with proper categorization
3. Parse quantities, units of measure, and descriptions
4. Identify and structure section categories
5. Create properly formatted line items in the system

When given a CSV file content, you should:
- Identify the column headers and data structure
- Extract each line item with all relevant fields
- Standardize units of measure (e.g., m², kg, pieces, etc.)
- Organize items by section or category when applicable
- Handle any parsing issues gracefully

Always parse the CSV content thoroughly and create structured line items. 
After parsing, call update_boq_attributes to update BOQ metadata and create_boq_line_items to add the parsed items."""

# Define custom state extending AgentState
class BoqParserAgentState(AgentState):
    api_token: str
    boq_id: Optional[int]
    boq_name: Optional[str]
    client_name: Optional[str]
    client_reference: Optional[str]
    qs_name: Optional[str]
    csv_content: Optional[str]
    boq_metadata: Optional[Dict[str, Any]]

# Tool implementations
@tool
async def parse_csv_content(
    state: Annotated[dict, InjectedState],
    instructions: Optional[str] = None,
) -> str:
    """Analyze and parse the CSV content from the BOQ file.
    
    This tool helps you understand the structure of the CSV file before parsing.
    Returns a summary of detected columns and sample rows.
    
    Args:
        instructions (Optional[str]): Any special parsing instructions or notes.
    """
    logger.info("Analyzing CSV content structure")
    
    csv_content = state.get("csv_content")
    if not csv_content:
        return "Error: No CSV content available in state"
    
    try:
        # Parse CSV to understand structure
        csv_reader = csv.DictReader(io.StringIO(csv_content))
        headers = csv_reader.fieldnames if csv_reader else []
        
        sample_rows = []
        for idx, row in enumerate(csv_reader):
            if idx < 3:  # Get first 3 rows as samples
                sample_rows.append(row)
            else:
                break
        
        total_rows = sum(1 for _ in io.StringIO(csv_content))
        
        analysis = {
            'headers': headers,
            'sample_rows': sample_rows,
            'total_rows': total_rows - 1,  # Subtract header
            'instructions': instructions
        }
        
        return str({
            'tool_name': 'parse_csv_content',
            'analysis': analysis,
            'message': f'CSV structure identified: {len(headers)} columns, {total_rows - 1} data rows'
        })
    except Exception as e:
        return f"Error parsing CSV structure: {str(e)}"

@tool
async def update_boq_attributes(
    state: Annotated[dict, InjectedState],
    boq_name: Optional[str] = None,
    client_name: Optional[str] = None,
    client_reference: Optional[str] = None,
    qs_name: Optional[str] = None,
    notes: Optional[str] = None,
) -> str:
    """Update BOQ metadata attributes like client name, QS name, and notes.
    
    Args:
        boq_name (Optional[str]): Name of the BOQ
        client_name (Optional[str]): Client organization name
        client_reference (Optional[str]): Client reference number
        qs_name (Optional[str]): Quantity Surveyor name
        notes (Optional[str]): Any notes about the BOQ
    """
    logger.info(f"Updating BOQ attributes for BOQ {state.get('boq_id')}")
    
    api_token = state.get("api_token")
    boq_id = state.get("boq_id")
    
    if not api_token:
        return "Error: api_token is required but not provided in state"
    
    if not boq_id:
        return "Error: boq_id is required but not provided in state"
    
    # Build update payload with only provided fields
    boq_data = {"boq": {}}
    if boq_name:
        boq_data["boq"]["boq_name"] = boq_name
    if client_name:
        boq_data["boq"]["client_name"] = client_name
    if client_reference:
        boq_data["boq"]["client_reference"] = client_reference
    if qs_name:
        boq_data["boq"]["qs_name"] = qs_name
    if notes:
        boq_data["boq"]["notes"] = notes
    
    if not boq_data["boq"]:
        return "No attributes provided to update"
    
    result = await make_api_request_to_llamapress(
        method="PATCH",
        endpoint=f"/boqs/{boq_id}/update_attributes.json",
        api_token=api_token,
        payload=boq_data,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'update_boq_attributes',
        'tool_args': boq_data,
        'tool_output': result,
        'message': 'BOQ attributes updated successfully'
    })

@tool
async def create_boq_line_items(
    line_items: List[Dict[str, Any]],
    state: Annotated[dict, InjectedState],
) -> str:
    """Create BOQ line items from parsed CSV data.
    
    Each line item should have:
    - item_number: Unique identifier for the item
    - item_description: Detailed description of the item
    - unit_of_measure: UOM (m², kg, pieces, etc.)
    - quantity: Quantity as a number
    - section_category: Category or section (optional)
    - notes: Additional notes (optional)
    
    Args:
        line_items (List[Dict]): List of line item dictionaries with required fields
    """
    logger.info(f"Creating {len(line_items)} BOQ line items")
    
    api_token = state.get("api_token")
    boq_id = state.get("boq_id")
    
    if not api_token:
        return "Error: api_token is required but not provided in state"
    
    if not boq_id:
        return "Error: boq_id is required but not provided in state"
    
    if not line_items or len(line_items) == 0:
        return "Error: At least one line item is required"
    
    # Validate and clean line items
    cleaned_items = []
    for idx, item in enumerate(line_items):
        if not item.get("item_description"):
            logger.warning(f"Skipping item {idx}: missing item_description")
            continue
        
        cleaned_item = {
            "item_number": item.get("item_number", f"ITEM-{idx+1}"),
            "item_description": item.get("item_description", ""),
            "unit_of_measure": item.get("unit_of_measure", ""),
            "quantity": float(item.get("quantity", 0)) if item.get("quantity") else 0.0,
            "section_category": item.get("section_category", ""),
            "notes": item.get("notes", ""),
        }
        cleaned_items.append(cleaned_item)
    
    if not cleaned_items:
        return "Error: No valid line items to create after validation"
    
    payload = {
        "line_items": cleaned_items
    }
    
    result = await make_api_request_to_llamapress(
        method="POST",
        endpoint=f"/boqs/{boq_id}/create_line_items.json",
        api_token=api_token,
        payload=payload,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'create_boq_line_items',
        'tool_args': {'line_items_count': len(cleaned_items)},
        'tool_output': result,
        'message': f'Successfully created {len(cleaned_items)} BOQ line items'
    })

@tool
async def get_boq_current_state(
    state: Annotated[dict, InjectedState],
) -> str:
    """Get the current state of the BOQ being parsed.
    
    Returns current metadata and existing line items.
    """
    logger.info(f"Getting current state for BOQ {state.get('boq_id')}")
    
    api_token = state.get("api_token")
    boq_id = state.get("boq_id")
    
    if not api_token:
        return "Error: api_token is required"
    
    if not boq_id:
        return "Error: boq_id is required"
    
    result = await make_api_request_to_llamapress(
        method="GET",
        endpoint=f"/boqs/{boq_id}.json",
        api_token=api_token,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'get_boq_current_state',
        'tool_output': result,
        'message': 'Retrieved current BOQ state'
    })

# Build workflow
def build_workflow(checkpointer=None):
    builder = StateGraph(BoqParserAgentState)
    
    # Define agent node
    def agent_node(state: BoqParserAgentState):
        llm = ChatOpenAI(model="gpt-4o-mini")
        llm_with_tools = llm.bind_tools(tools)
        
        # Build system message with CSV context
        system_context = sys_msg
        if state.get("csv_content"):
            system_context += f"\n\nCSV File Content:\n```\n{state['csv_content'][:2000]}\n...\n```"
        
        full_sys_msg = SystemMessage(content=system_context)
        return {"messages": [llm_with_tools.invoke([full_sys_msg] + state["messages"])]}
    
    builder.add_node("agent", agent_node)
    builder.add_node("tools", ToolNode(tools))
    
    builder.add_edge(START, "agent")
    builder.add_conditional_edges("agent", tools_condition)
    builder.add_edge("tools", "agent")
    
    return builder.compile(checkpointer=checkpointer)

# Register all tools
tools = [
    parse_csv_content,
    update_boq_attributes,
    create_boq_line_items,
    get_boq_current_state,
]
