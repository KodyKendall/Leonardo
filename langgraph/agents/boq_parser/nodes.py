from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langgraph.graph import StateGraph, START
from langgraph.prebuilt import tools_condition, ToolNode, InjectedState
from langgraph.prebuilt.chat_agent_executor import AgentState
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage, ToolMessage
from typing import Annotated, Optional, List, Dict, Any
from app.agents.utils.make_api_request_to_llamapress import make_api_request_to_llamapress
import logging
import csv
import io
from tiktoken import encoding_for_model

logger = logging.getLogger(__name__)

# System message for the BOQ parser agent - OPTIMIZED for token efficiency
sys_msg = """You are a Bill of Quantities (BOQ) parsing expert that directly parses CSV content.

TASK: Parse raw CSV content and create BOQ line items directly in the database.
User will provide:
1. A BOQ database ID (the target BOQ to populate)
2. Raw CSV content (pasted directly between <CSV> tags)

YOUR WORKFLOW:
1. Extract the BOQ ID from the user message (e.g., "BOQ with id = 4")
2. Call get_boq_items(boq_id) to retrieve existing BOQ items (understanding current state)
3. DIRECTLY PARSE the CSV content from the user's messages
   - Identify the CSV header row (contains: RECORD, DESCRIPTION, UNIT, QUANTITY, etc.)
   - Extract rows AFTER the header with numeric QUANTITY values
   - Filter out rows where QUANTITY is empty, zero, or non-numeric
   - Filter out preamble/instructional text rows (ignore rows with long descriptions that look like terms/conditions)
   - Keep only rows that represent actual BOQ line items
4. Build a list of valid line items by extracting:
   - item_number: from RECORD or ITEM column
   - item_description: from DESCRIPTION column (trim quotes if present)
   - unit_of_measure: from UNIT column (standardize: m², kg, pieces, m, l, etc.)
   - quantity: from QUANTITY column (must be numeric)
   - section_category: infer from section headers or DESCRIPTION text using the valid enum values (see VALID SECTION CATEGORIES below)
5. Show preview to user with:
   - Count of items found
   - Sample of first 3-5 items with all details
   - Any items that were filtered out and why
6. Ask for confirmation: "Ready to create X items. Should I proceed?"
7. Upon confirmation, call create_boq_item() for EACH valid line item with all required parameters
8. Report final summary:
   - ✅ Items successfully created
   - ❌ Items that failed
   - ⚠️ Any errors encountered

VALID SECTION CATEGORIES (ENUM VALUES):
You MUST use ONLY these exact enum values for section_category:
- Blank
- Steel Sections
- Paintwork
- Bolts
- Gutter Meter
- M16 Mechanical Anchor
- M16 Chemical
- M20 Chemical
- M24 Chemical
- M16 HD Bolt
- M20 HD Bolt
- M24 HD Bolt
- M30 HD Bolt
- M36 HD Bolt
- M42 HD Bolt

CATEGORY INFERENCE RULES:
1. Look for explicit section headers in the CSV (e.g., "STEEL SECTIONS", "PAINTWORK", "BOLTS")
2. Match description keywords to appropriate categories:
   - "M16", "M20", "M24", "M30", "M36", "M42" with "mechanical" → M16/M20/M24/M30/M36/M42 Mechanical Anchor
   - "M16", "M20", "M24", "M30", "M36", "M42" with "chemical" → M16/M20/M24 Chemical
   - "M16", "M20", "M24", "M30", "M36", "M42" with "HD bolt" or "HD" → M16/M20/M24/M30/M36/M42 HD Bolt
   - "steel", "section", "profile" → Steel Sections
   - "paint", "coating" → Paintwork
   - "bolt" (standalone) → Bolts
   - "gutter", "meter" → Gutter Meter
   - If no match found → use "Blank"

KEY REQUIREMENTS:
- parse CSV directly into individual BOQ items and use the tools to add them to app/database using the given ID
- CSV content is ALWAYS available in state from user's <CSV> tags
- Parse the CSV structure intelligently: skip meta-information and preamble rows
- Only create items with numeric quantities > 0
- Standardize units: m², kg, pieces, m, l, m³, l, hr, each, set, etc.
- Show a clear preview before taking action
- ALWAYS ask for confirmation before creating items
- Process items one by one for reliability and clear reporting
- ALWAYS use one of the valid enum values for section_category - never create custom values

PARSING INTELLIGENCE:
1. Identify header row by looking for RECORD, DESCRIPTION, UNIT, QUANTITY pattern
2. Rows WITHOUT numeric quantity values are non-data (skip them)
3. Rows with empty UNIT or QUANTITY columns are section headers/preambles (skip them)
4. Long descriptive text (>200 chars) in DESCRIPTION that mention "shall", "include", "described" = preamble text (skip)
5. Only parse actual line items: RECORD (numeric), DESCRIPTION (item name), UNIT (UOM), QUANTITY (number)"""

# Define custom state extending AgentState
class BoqParserAgentState(AgentState):
    api_token: str
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
    boq_id: int,
    state: Annotated[dict, InjectedState],
    boq_name: Optional[str] = None,
    client_name: Optional[str] = None,
    client_reference: Optional[str] = None,
    qs_name: Optional[str] = None,
    notes: Optional[str] = None,
) -> str:
    """Update BOQ metadata attributes like client name, QS name, and notes.
    
    Args:
        boq_id (int): ID of the BOQ to update
        boq_name (Optional[str]): Name of the BOQ
        client_name (Optional[str]): Client organization name
        client_reference (Optional[str]): Client reference number
        qs_name (Optional[str]): Quantity Surveyor name
        notes (Optional[str]): Any notes about the BOQ
    """
    logger.info(f"Updating BOQ attributes for BOQ {boq_id}")
    
    api_token = state.get("api_token")
    
    if not api_token:
        return "Error: api_token is required but not provided in state"
    
    if not boq_id:
        return "Error: boq_id is required as a parameter"
    
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
    boq_id: int,
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
        boq_id (int): ID of the BOQ to add items to
        line_items (List[Dict]): List of line item dictionaries with required fields
    """
    logger.info(f"Creating {len(line_items)} BOQ line items for BOQ {boq_id}")
    
    api_token = state.get("api_token")
    
    if not api_token:
        return "Error: api_token is required but not provided in state"
    
    if not boq_id:
        return "Error: boq_id is required as a parameter"
    
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
async def get_boq_items(
    boq_id: int,
    state: Annotated[dict, InjectedState],
) -> str:
    """Get all BOQ items for a specific BOQ.
    
    Returns a list of all line items associated with the BOQ including their descriptions, quantities, and other details.
    
    Args:
        boq_id (int): ID of the BOQ to retrieve items from
    """
    logger.info(f"Getting BOQ items for BOQ {boq_id}")
    
    api_token = state.get("api_token")
    
    if not api_token:
        return "Error: api_token is required"
    
    if not boq_id:
        return "Error: boq_id is required as a parameter"
    
    result = await make_api_request_to_llamapress(
        method="GET",
        endpoint=f"/boqs/{boq_id}.json",
        api_token=api_token,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'get_boq_items',
        'tool_args': {'boq_id': boq_id},
        'tool_output': result,
        'message': 'Retrieved BOQ with all line items'
    })

@tool
async def update_boq(
    boq_id: int,
    state: Annotated[dict, InjectedState],
    boq_name: Optional[str] = None,
    client_name: Optional[str] = None,
    client_reference: Optional[str] = None,
    qs_name: Optional[str] = None,
    notes: Optional[str] = None,
) -> str:
    """Update BOQ metadata fields.
    
    Allows updating the BOQ's name, client information, QS name, and notes.
    
    Args:
        boq_id (int): ID of the BOQ to update
        boq_name (Optional[str]): Name of the BOQ
        client_name (Optional[str]): Client organization name
        client_reference (Optional[str]): Client reference number
        qs_name (Optional[str]): Quantity Surveyor name
        notes (Optional[str]): Additional notes about the BOQ
    """
    logger.info(f"Updating BOQ {boq_id}")
    
    api_token = state.get("api_token")
    
    if not api_token:
        return "Error: api_token is required"
    
    if not boq_id:
        return "Error: boq_id is required as a parameter"
    
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
        return "No fields provided to update"
    
    result = await make_api_request_to_llamapress(
        method="PUT",
        endpoint=f"/boqs/{boq_id}.json",
        api_token=api_token,
        payload=boq_data,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'update_boq',
        'tool_args': boq_data,
        'tool_output': result,
        'message': 'BOQ updated successfully'
    })

@tool
async def create_boq_item(
    boq_id: int,
    item_number: str,
    item_description: str,
    unit_of_measure: str,
    quantity: float,
    state: Annotated[dict, InjectedState],
    section_category: Optional[str] = None,
    notes: Optional[str] = None,
) -> str:
    """Create a new BOQ line item.
    
    Adds a new item to the BOQ with description, quantity, unit of measure, and optional category.
    
    Args:
        boq_id (int): ID of the BOQ to add the item to
        item_number (str): Unique identifier for the item
        item_description (str): Detailed description of the item
        unit_of_measure (str): Unit of measurement (m², kg, pieces, etc.)
        quantity (float): Quantity as a number
        section_category (Optional[str]): Category or section for the item
        notes (Optional[str]): Additional notes about the item
    """
    logger.info(f"Creating BOQ item for BOQ {boq_id}")
    
    api_token = state.get("api_token")
    
    if not api_token:
        return "Error: api_token is required"
    
    if not boq_id:
        return "Error: boq_id is required as a parameter"
    
    boq_item_data = {
        "boq_item": {
            "boq_id": boq_id,
            "item_number": item_number,
            "item_description": item_description,
            "unit_of_measure": unit_of_measure,
            "quantity": quantity,
        }
    }
    
    if section_category:
        boq_item_data["boq_item"]["section_category"] = section_category
    if notes:
        boq_item_data["boq_item"]["notes"] = notes
    
    result = await make_api_request_to_llamapress(
        method="POST",
        endpoint="/boq_items.json",
        api_token=api_token,
        payload=boq_item_data,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'create_boq_item',
        'tool_args': {'item_number': item_number, 'item_description': item_description},
        'tool_output': result,
        'message': 'BOQ item created successfully'
    })

@tool
async def update_boq_item(
    boq_item_id: int,
    state: Annotated[dict, InjectedState],
    item_number: Optional[str] = None,
    item_description: Optional[str] = None,
    unit_of_measure: Optional[str] = None,
    quantity: Optional[float] = None,
    section_category: Optional[str] = None,
    notes: Optional[str] = None,
) -> str:
    """Update an existing BOQ line item.
    
    Modifies any of the fields for a specific BOQ item. Only provided fields will be updated.
    
    Args:
        boq_item_id (int): ID of the BOQ item to update
        item_number (Optional[str]): New item number
        item_description (Optional[str]): New description
        unit_of_measure (Optional[str]): New unit of measurement
        quantity (Optional[float]): New quantity
        section_category (Optional[str]): New category
        notes (Optional[str]): New notes
    """
    logger.info(f"Updating BOQ item {boq_item_id}")
    
    api_token = state.get("api_token")
    
    if not api_token:
        return "Error: api_token is required"
    
    # Build update payload with only provided fields
    boq_item_data = {"boq_item": {}}
    if item_number:
        boq_item_data["boq_item"]["item_number"] = item_number
    if item_description:
        boq_item_data["boq_item"]["item_description"] = item_description
    if unit_of_measure:
        boq_item_data["boq_item"]["unit_of_measure"] = unit_of_measure
    if quantity is not None:
        boq_item_data["boq_item"]["quantity"] = quantity
    if section_category:
        boq_item_data["boq_item"]["section_category"] = section_category
    if notes:
        boq_item_data["boq_item"]["notes"] = notes
    
    if not boq_item_data["boq_item"]:
        return "No fields provided to update"
    
    result = await make_api_request_to_llamapress(
        method="PUT",
        endpoint=f"/boq_items/{boq_item_id}.json",
        api_token=api_token,
        payload=boq_item_data,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'update_boq_item',
        'tool_args': {'boq_item_id': boq_item_id},
        'tool_output': result,
        'message': 'BOQ item updated successfully'
    })

@tool
async def delete_boq_item(
    boq_item_id: int,
    state: Annotated[dict, InjectedState],
) -> str:
    """Delete a BOQ line item.
    
    Removes a specific BOQ item from the BOQ.
    
    Args:
        boq_item_id (int): ID of the BOQ item to delete
    """
    logger.info(f"Deleting BOQ item {boq_item_id}")
    
    api_token = state.get("api_token")
    
    if not api_token:
        return "Error: api_token is required"
    
    result = await make_api_request_to_llamapress(
        method="DELETE",
        endpoint=f"/boq_items/{boq_item_id}.json",
        api_token=api_token,
    )
    
    if isinstance(result, str):
        return result
    
    return str({
        'tool_name': 'delete_boq_item',
        'tool_args': {'boq_item_id': boq_item_id},
        'tool_output': result,
        'message': 'BOQ item deleted successfully'
    })

# @tool
# async def get_boq_current_state(
#     state: Annotated[dict, InjectedState],
# ) -> str:
#     """Get the current state of the BOQ being parsed.
    
#     Returns current metadata and existing line items.
#     """
#     logger.info(f"Getting current state for BOQ {state.get('boq_id')}")
    
#     api_token = state.get("api_token")
#     boq_id = state.get("boq_id")
    
#     if not api_token:
#         return "Error: api_token is required"
    
#     if not boq_id:
#         return "Error: boq_id is required"
    
#     result = await make_api_request_to_llamapress(
#         method="GET",
#         endpoint=f"/boqs/{boq_id}.json",
#         api_token=api_token,
#     )
    
#     if isinstance(result, str):
#         return result
    
#     return str({
#         'tool_name': 'get_boq_current_state',
#         'tool_output': result,
#         'message': 'Retrieved current BOQ state'
#     })

# Build workflow
def build_workflow(checkpointer=None):
    builder = StateGraph(BoqParserAgentState)
    
    # Define agent node
    def agent_node(state: BoqParserAgentState):
        llm = ChatOpenAI(
            model="gpt-5-codex",
            use_responses_api=True,
            reasoning={"effort": "low"}
        )
        llm_with_tools = llm.bind_tools(tools)
        
        # Build system message with CSV context
        system_context = sys_msg
        # csv_content = state.get("csv_content")
        
        # if csv_content:
        #     # Include full CSV content or truncate if very large
        #     csv_preview = csv_content if len(csv_content) < 10000 else f"{csv_content[:10000]}\n\n... (truncated, {len(csv_content)} total characters)"
        #     system_context += f"\n\n📋 CSV FILE CONTENT (Ready for parsing):\n```csv\n{csv_preview}\n```"
        #     logger.info(f"✅ CSV content loaded: {len(csv_content)} characters")
        # else:
        #     logger.warning("⚠️ No CSV content available in agent state")
        #     system_context += "\n\n⚠️ NOTE: No CSV file content was provided. Ask the user to ensure a CSV file is attached to the BOQ."
        
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
    update_boq_attributes,
    create_boq_line_items,
    get_boq_items,
    update_boq,
    create_boq_item,
    update_boq_item,
    delete_boq_item,
]
