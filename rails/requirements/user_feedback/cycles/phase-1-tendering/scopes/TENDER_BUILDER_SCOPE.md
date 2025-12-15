# Phase 1: Tender Builder - Vertical Slice Scope

> **VERTICAL SLICE REQUIREMENT**: This scope defines a standalone, demo-able full stack feature covering Tender creation, Tender Line Items, Line Item Rate Build-ups, and Material Breakdown/Material Items. It's independently buildable and demo-able in 2-3 weeks, without depending on BOQ parsing or equipment/crainage calculations.

**Timeline:** 2-3 weeks (one focused development sprint)
**Status:** MOSTLY COMPLETE - Core UI Done, Calculations Pending
**Document Version:** 1.1
**Last Updated:** December 8, 2025

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| Tender CRUD | ✅ Complete | Create, edit, delete tenders working |
| E-number Generation | ✅ Complete | Auto-generates E + Year + Sequence |
| Line Items CRUD | ✅ Complete | Add, edit, delete line items |
| Material Breakdown UI | ✅ Complete | Add/remove materials, proportion input |
| Rate Build-up UI | ✅ Complete | 11 rate components with checkboxes |
| Real-time Calculations | ✅ Complete | Subtotal calc works, auto-population pending |
| Material Rate Auto-fill | 🟡 Partial | Needs to pull from material_supplies table |
| Rounding Logic | 🟡 Partial | R50/R20/R10 rules not implemented |
| Grand Total Updates | ✅ Complete | Basic sum works, needs Turbo Stream polish |

### What's Working (Dec 8 Demo)
- Create tender with project name, client, tender date
- Add line items with description, unit, quantity, category
- Expand rate build-up section per line item
- Add/remove materials with dropdown selection
- Enter material proportion (currently labeled "Qty" - needs rename)
- Rate build-up shows all 11 components with include checkboxes
- Basic subtotal calculation via Stimulus controller

### What's Pending
- Auto-populate material supply rate from lookup table
- Auto-populate processing rates from lookup table
- Apply waste percentage to material rates
- Apply rounding rules (R50 default)
- CFLC fabrication auto-zero rule
- Material proportion validation (must sum to 100%)
- Rename "Qty" column to "Material Ratio" or "Proportion"

---

## 1. Overview & Objectives

### 1.1 Problem Statement

The current RSB tendering process relies on complex, interconnected Excel spreadsheets where:
- Line item cost calculations are manual and error-prone (22-level nested IF formulas)
- Material type selection and blending requires expertise
- Rate overrides and configuration changes manually propagate (or don't)
- No audit trail of what changed when
- Training new staff takes weeks due to spreadsheet complexity

**Goal:** Build a unified, reliable system where tenders can be created with line items, materials configured, and costs calculated automatically with full transparency and auditability.

### 1.2 Demo Scenario

**Initial Setup:**
- Admin has pre-loaded 22 material supply types with rates and waste percentages
- Admin has configured processing rates (fabrication, overheads, shop priming, etc.)
- QS user is ready to work

**Workflow:**
1. **Create Tender:** Demi creates tender E3801 for "RPP Transformers" project
2. **Add Line Items:** Manually adds 3 steel section line items (U-beams, I-sections, plate)
3. **Configure Materials:** For each line item:
   - Selects material composition (e.g., 85% UB/UC Local, 15% Plate)
   - System automatically calculates weighted material rate with waste %
4. **View Rate Build-up:** Expands one line item to see complete cost breakdown:
   - Material supply cost: R17,092.50
   - Fabrication: R8,000 (included)
   - Overheads: R4,150 (included)
   - Shop priming: R0 (excluded)
   - Subtotal: R34,672.50
   - Rounded: R34,700
5. **Override & Recalculate:** Changes one material to 100% UB/UC, system recalculates instantly
6. **View Summary:** Final tender shows all line items with rates, quantities, line amounts, and grand total

**Success Criteria:**
- Create tender with name, client, and date
- Add/edit/delete line items with descriptions, units, quantities
- Configure material breakdown per line item (proportions must sum to 100%)
- System calculates material rate with waste % automatically
- System calculates full rate build-up per line item
- All calculations match Excel exactly
- User can save and retrieve tender at any time
- Material changes recalculate instantly

---

## 2. Personas & User Stories

### 2.1 Personas

**Demi (QS)** - Quantity Surveyor
- Creates and reviews tenders
- Configures line item details, materials, and costs
- Needs: Fast, reliable calculations; ability to see and override costs; clear feedback on errors

**Elmarie (Office Staff)** - Initial Data Entry
- Does initial tender setup (client, project name)
- May add basic line items from BOQ
- Needs: Simple, clear forms; doesn't need to understand rate calculations

**Richard (Admin/Director)** - Strategy & Oversight
- Sets master rates and configuration
- Reviews final tenders before submission
- Needs: Audit trail of changes; confidence in calculations

### 2.2 User Stories

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-100 | As Demi, I want to create a new tender with project name, client, and date so that I can begin costing | Tender form creates record; generates E-number; displays on list | High |
| US-101 | As Elmarie, I want to add line items to a tender by entering description, unit, and quantity so that I have a BOQ to cost | Add button opens form; saves line items; displays in table; can add multiple items | High |
| US-102 | As Demi, I want to edit line item quantities and descriptions so that I can correct parsing errors | Click to edit; inline form; saves on blur; shows updated line amount | High |
| US-103 | As Demi, I want to delete line items so that I can remove duplicates or errors | Delete button; confirmation dialog; removes from table and database | High |
| US-104 | As Demi, I want to select material composition for each line item so that the correct blended rate is used | Material selector shows all 22 types; can assign %; proportions must sum to 100%; system rejects if < or > 100% | High |
| US-105 | As Demi, I want to see the calculated material rate with waste applied so that I understand the cost basis | Displays: "UB/UC Local 85% @ 15,900 + waste 7.5% = 17,092.50" | High |
| US-106 | As Demi, I want to view the complete rate build-up for each line item so that I can verify each cost component | Expandable detail shows all components, flags, calculations, total before rounding, rounded rate | High |
| US-107 | As Demi, I want to override a line item's material rate if negotiated pricing differs so that special deals are captured | Material rate field shows default; user can edit; system recalculates total with override | Medium |
| US-108 | As Demi, I want fabrication to be automatically 0 for CFLC items so that I don't have to remember this rule | Category = "CFLC" → fabrication_included = false automatically | High |
| US-109 | As Demi, I want to see a summary showing total tonnage, line amounts, and subtotal so that I can verify calculations | Summary section at bottom shows: total tonnage, subtotal (sum of line amounts), margin, grand total | High |
| US-110 | As Richard, I want an audit log showing who changed what and when so that I can track tender evolution | Audit entries for: tender created, line item added/edited/deleted, material changed, rate override applied | Medium |

---

## 3. Current (As-Is) Process

### 3.1 Data Entry Narrative

**Current Excel Workflow:**

1. **Create Tender**: Elmarie copies template, enters client name, project name, tender date, assigns tender number (format: E + date, e.g., E3801)

2. **Enter Line Items**: Elmarie copies BOQ data into "Tender Data" sheet manually (Page, Item, Description, Unit, Qty, Category)

3. **Assign Material Type**: 
   - Manual lookup using 22-level nested IF formula
   - Error-prone, requires expertise
   - No validation that materials sum to 100%

4. **Calculate Material Rate**:
   - Formula: `base_rate × (1 + waste_percentage) × proportion`
   - If multiple materials: `sum of (rate × proportion)`
   - Currently hardcoded in Excel, recalculation is manual

5. **Calculate Full Rate Build-up**:
   - 19-row formula per line item in "Costing Sheet"
   - If rates change, must manually recalculate or copy new formula
   - Formula errors (#REF!) sometimes occur

6. **Apply Rounding Rules**:
   - Ceiling to nearest R50 for standard items
   - R20 for crainage, R10 for cherry pickers
   - Manual rounding, easy to miss

7. **Review & Submit**: Demi reviews "Page 1" output, verifies totals, prepares PDF for client

### 3.2 Key Pain Points

| Pain Point | Current Impact | System Solution |
|------------|----------------|-----------------|
| Manual material lookup | 20+ mins per tender | Dropdown selector with validation |
| Nested IF formula errors | Unknown calculation errors | Transparent formula engine |
| Rates change globally | Must manually update all tenders using old rates | Versioned rates; new tenders use current rates; old tenders frozen |
| Material proportions not validated | User could enter 90% + 15% = 105% | System validates sum = 100% before saving |
| No audit trail | Cannot trace why rate changed | Every change logged with user, timestamp, old/new values |
| Rounding mistakes | R48,750 not rounded to R48,800 | Automatic rounding applied always |
| Recalculation delays | User waits for Excel to recalculate | Real-time calculations with Turbo |

---

## 4. Future (To-Be) Process

### 4.1 Step-by-Step Workflow

#### Step 1: Create Tender
- User navigates to /tenders
- Clicks "New Tender"
- Form: Project name, Client (dropdown), Tender date, Notes (optional)
- System generates E-number automatically
- Saves tender in draft status

#### Step 2: Add Line Items
- User in tender show page clicks "Add Line Item"
- Modal form: Description (text), Unit (dropdown: t, m, no., etc.), Quantity (decimal)
- User can add multiple items sequentially
- Each item appears in table immediately (Turbo Frame refresh)

#### Step 3: Configure Material for Line Item
- User clicks "Edit Materials" on a line item row
- Modal opens showing all 22 material types
- User selects first material (e.g., "UB/UC Local") and enters proportion (e.g., 85%)
- User can add second material (e.g., "Plate") at 15%
- System validates proportions = 100% before save
- On save, system calculates: `(15,900 × 1.075 × 0.85) + (16,500 × 1.075 × 0.15) = R17,194.88`

#### Step 4: View Line Item Rate Build-up
- User clicks "View Details" on a line item
- Expandable detail row (or slide panel) shows:
  - **Material Supply**: R17,194.88 (with breakdown: UB/UC Local 85% @ R15,900 + waste)
  - **Cost Components**: Fabrication R8,000 (✓), Overheads R4,150 (✓), Shop Priming R1,380 (✗), Delivery R700 (✓), etc.
  - **Subtotal**: R34,644.88
  - **Margin**: R0 (tender margin 0%)
  - **Before Rounding**: R34,644.88
  - **Rounded Rate**: R34,650
  - **Line Amount**: R34,650 × qty = line total

#### Step 5: Override if Needed
- User can click "Override Rate" button
- Modal shows current calculated rate
- User enters override value (e.g., R34,500 negotiated)
- System saves override, recalculates line amount, updates summary

#### Step 6: View Summary
- Bottom of line items table shows:
  - **Total Tonnage**: 931.62 t
  - **Subtotal**: R23,400,066
  - **Margin**: R0
  - **Grand Total**: R23,400,066

---

## 5. Database Schema (REQUIRED)

### 5.1 Table Definitions

#### Table: tenders
Stores the main tender/quote record.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_number | string(20) | NOT NULL, unique | E-number format (E + sequential) |
| project_name | string(255) | NOT NULL | Project description |
| client_id | bigint | FK to clients | Reference to customer |
| created_by_id | bigint | FK to users | User who created |
| assigned_to_id | bigint | FK to users | Currently assigned user (QS) |
| tender_date | date | NOT NULL | Date tender created |
| expiry_date | date | | Validity end date |
| project_type | string(50) | DEFAULT 'commercial' | 'commercial' or 'mining' |
| margin_pct | decimal(10,4) | DEFAULT 0.0 | Tender-level margin percentage |
| status | string(50) | DEFAULT 'draft' | draft, in_progress, ready_for_review, approved, submitted, won, lost |
| notes | text | | Internal notes |
| total_tonnage | decimal(12,3) | DEFAULT 0.0 | Calculated total mass |
| subtotal_amount | decimal(14,2) | DEFAULT 0.0 | Sum before margin |
| grand_total | decimal(14,2) | DEFAULT 0.0 | Final tender value |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

#### Table: tender_line_items
Individual line items (steel sections, plates, bolts, etc.).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_id | bigint | FK to tenders, CASCADE | Reference to parent tender |
| page_number | integer | | Page from original BOQ |
| item_number | integer | | Item sequence within BOQ |
| description | text | NOT NULL | Item description (e.g., "305 x 165mm x 40kg/m I-section columns") |
| unit_of_measure | string(20) | DEFAULT 't' | Unit: t, m, no., m², etc. |
| quantity | decimal(12,3) | NOT NULL | Quantity in unit |
| category | string(100) | | Category for material lookup (Steel Sections, Bolts, etc.) |
| line_type | string(50) | DEFAULT 'standard' | standard, bolt, anchor, gutter, pg, shop_drawings, provisional |
| section_header | string(255) | | Grouping header (e.g., "STEEL COLUMNS AND BEAMS") |
| sort_order | integer | | Display order |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

#### Table: line_item_material_breakdowns
Parent record for material composition of a line item (one per line item).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_line_item_id | bigint | FK to tender_line_items, CASCADE | Reference to line item |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

#### Table: line_item_materials
Material supply composition (child records of line_item_material_breakdowns).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| line_item_material_breakdown_id | bigint | FK to line_item_material_breakdowns, CASCADE | Reference to parent breakdown |
| tender_line_item_id | bigint | FK to tender_line_items | Denormalized ref for queries |
| material_supply_id | bigint | FK to material_supplies | Reference to material type |
| proportion | decimal(5,4) | NOT NULL (0.0-1.0) | Percentage as decimal (0.85 = 85%) |
| quantity | decimal(12,3) | | Calculated quantity (for future use) |
| rate | decimal(12,2) | | Calculated rate for this material |
| thickness | decimal(12,3) | | Material thickness (if applicable) |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

#### Table: line_item_rate_build_ups
Complete cost breakdown for each line item.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_line_item_id | bigint | FK to tender_line_items, CASCADE | Reference to line item |
| material_supply_rate | decimal(12,2) | DEFAULT 0.0 | Material cost per unit (with waste %) |
| fabrication_rate | decimal(12,2) | DEFAULT 0.0 | Base fabrication rate |
| fabrication_factor | decimal(5,2) | DEFAULT 1.0 | Multiplier (1.0 structural, 1.75 platework, 3.0 piping) |
| fabrication_included | boolean | DEFAULT true | Is fabrication included? |
| overheads_rate | decimal(12,2) | DEFAULT 0.0 | Overheads cost |
| overheads_included | boolean | DEFAULT true | Is overheads included? |
| shop_priming_rate | decimal(12,2) | DEFAULT 0.0 | Shop priming cost |
| shop_priming_included | boolean | DEFAULT false | Is shop priming included? |
| onsite_painting_rate | decimal(12,2) | DEFAULT 0.0 | On-site painting cost |
| onsite_painting_included | boolean | DEFAULT false | Is on-site painting included? |
| delivery_rate | decimal(12,2) | DEFAULT 0.0 | Delivery cost |
| delivery_included | boolean | DEFAULT true | Is delivery included? |
| bolts_rate | decimal(12,2) | DEFAULT 0.0 | Bolts cost |
| bolts_included | boolean | DEFAULT true | Is bolts included? |
| erection_rate | decimal(12,2) | DEFAULT 0.0 | Erection cost |
| erection_included | boolean | DEFAULT true | Is erection included? |
| crainage_rate | decimal(12,2) | DEFAULT 0.0 | Crainage cost |
| crainage_included | boolean | DEFAULT false | Is crainage included in line items? |
| cherry_picker_rate | decimal(12,2) | DEFAULT 0.0 | Cherry picker cost |
| cherry_picker_included | boolean | DEFAULT false | Is cherry picker included in line items? |
| galvanizing_rate | decimal(12,2) | DEFAULT 0.0 | Galvanizing cost |
| galvanizing_included | boolean | DEFAULT false | Is galvanizing included? |
| subtotal | decimal(14,2) | DEFAULT 0.0 | Sum of all included components |
| margin_amount | decimal(14,2) | DEFAULT 0.0 | Margin applied (tender margin % × subtotal) |
| total_before_rounding | decimal(14,2) | DEFAULT 0.0 | Subtotal + margin |
| rounded_rate | decimal(14,2) | DEFAULT 0.0 | Final rate (rounded to nearest R50) |
| rate_override | decimal(14,2) | | Manual override if different from calculated |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

#### Table: material_supplies
Master data: 22 material supply types.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| code | string(50) | NOT NULL, unique | Short code (UB_UC_LOCAL) |
| name | string(255) | NOT NULL | Display name (Local UB & UC Sections) |
| category | string(100) | | Category (sections, plate, gutters, etc.) |
| base_rate_per_tonne | decimal(12,2) | NOT NULL | Current base rate in R/t |
| waste_percentage | decimal(5,4) | DEFAULT 0.075 | Waste % as decimal (0.075 = 7.5%) |
| effective_from | date | NOT NULL | Date rate became active |
| is_active | boolean | DEFAULT true | Whether material is currently active |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

#### Table: processing_rates
Master data: fabrication, overheads, delivery, etc.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| code | string(50) | NOT NULL, unique | Rate code (FABRICATION, OVERHEADS, etc.) |
| name | string(255) | NOT NULL | Display name |
| base_rate_per_tonne | decimal(12,2) | NOT NULL | Base rate in R/t |
| work_type | string(50) | | Work type (structural, platework, piping) |
| factor | decimal(5,2) | DEFAULT 1.0 | Multiplier for this work type |
| is_active | boolean | DEFAULT true | Whether rate is active |
| effective_from | date | NOT NULL | Date rate became active |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

#### Table: clients
Customer master data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| business_name | string(255) | NOT NULL | Company name |
| contact_name | string(255) | | Primary contact |
| contact_email | string(255) | | Contact email |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

---

### 5.2 Relationships & Cardinality

| Parent Table | Child Table | Relationship | Foreign Key | On Delete |
|--------------|-------------|--------------|-------------|-----------|
| tenders | tender_line_items | 1:many | tender_id | cascade |
| tender_line_items | line_item_material_breakdowns | 1:1 | tender_line_item_id | cascade |
| line_item_material_breakdowns | line_item_materials | 1:many | line_item_material_breakdown_id | cascade |
| tender_line_items | line_item_rate_build_ups | 1:1 | tender_line_item_id | cascade |
| material_supplies | line_item_materials | 1:many | material_supply_id | restrict |
| clients | tenders | 1:many | client_id | restrict |
| users | tenders | 1:many (created_by) | created_by_id | restrict |
| users | tenders | 1:many (assigned_to) | assigned_to_id | nullify |

### 5.3 Entity Relationship Diagram

```
Clients (1)
    |
    +-- (1:many) --> Tenders
                        |
                        +-- (1:many) --> Tender_Line_Items
                                            |
                                            +-- (1:1) --> Line_Item_Material_Breakdowns
                                            |                 |
                                            |                 +-- (1:many) --> Line_Item_Materials
                                            |                                       |
                                            |                                       +-- FK to Material_Supplies
                                            |
                                            +-- (1:1) --> Line_Item_Rate_Build_Ups
                                                              |
                                                              +-- FK to Processing_Rates (for each rate type)
```

### 5.4 Indexes

| Table | Index Name | Columns | Type | Purpose |
|-------|------------|---------|------|---------|
| tenders | idx_tender_number | tender_number | unique | Fast lookup by E-number |
| tenders | idx_status | status | btree | Filter tenders by status |
| tender_line_items | idx_tender_id | tender_id | btree | Find all line items for tender |
| line_item_materials | idx_material_breakdown | line_item_material_breakdown_id | btree | Find materials for breakdown |
| line_item_rate_build_ups | idx_line_item | tender_line_item_id | unique | Find rate build-up for item |
| material_supplies | idx_code | code | unique | Fast lookup by material code |
| processing_rates | idx_code | code | unique | Fast lookup by rate code |

---

## 6. UI Composition & Scaffolding (REQUIRED)

### 6.1 Screen Hierarchy

```
[Tenders Index: /tenders]
    |
    +-- [Tender Show: /tenders/:id]
            |
            +-- [Line Items Section: /tenders/:id#line-items]
            |       |
            |       +-- [Edit Line Item Modal]
            |       +-- [Material Breakdown Modal]
            |       +-- [Rate Build-up Detail View]
            |
            +-- [Summary Section: /tenders/:id#summary]
```

### 6.2 View Specifications

#### View: Tenders Index
- **Route**: `/tenders`
- **Primary Table**: tenders
- **Displays**: E-number, Project name, Client, Status, Total value, Created date, Actions (View, Edit, Delete)
- **Actions**: Create New Tender, View Tender, Edit Tender, Delete Tender
- **Filters**: Status (Draft, In Progress, Submitted), Client (dropdown), Date range

#### View: Tender Show
- **Route**: `/tenders/:id`
- **Primary Table**: tenders
- **Displays**: 
  - Header: Tender E-number, Project name, Client, Status, Tender date, Expiry date
  - Tabs/Sections: Line Items, Summary
- **Actions**: Edit tender details, Add line item, Save draft, Submit tender

#### View: Line Items Section
- **Route**: `/tenders/:id#line-items`
- **Primary Table**: tender_line_items + line_item_rate_build_ups
- **Displays**: Table with columns:
  - Page | Item | Description | Unit | Qty | Rate | Line Amount | Actions
- **Row Details**: Expandable detail view showing rate build-up
- **Actions**: 
  - Add Line Item (button → modal form)
  - Edit Line Item (click row → inline edit or modal)
  - Configure Materials (button → modal)
  - View Rate Build-up (expandable row or slide panel)
  - Delete Line Item (confirmation dialog)

#### View: Add/Edit Line Item Modal
- **Fields**:
  - Description (text input, required)
  - Unit of Measure (dropdown: t, m, m², no., etc.)
  - Quantity (decimal input, required)
  - Category (dropdown, optional)
  - Section Header (text, optional - for BOQ grouping)
- **Actions**: Save, Cancel
- **Validation**: Description and Quantity required; Quantity > 0

#### View: Material Breakdown Modal
- **Title**: "Configure Materials for [Line Item Description]"
- **Display**: 
  - Message: "Proportions must sum to exactly 100%"
  - List of selected materials with proportion sliders or input fields
  - Button: "Add Material" (shows dropdown of 22 material types)
  - Error message if proportions ≠ 100%
- **Calculation Display**:
  - Material 1: "UB/UC Local 85% @ R15,900 + waste 7.5% = R17,092.50 per tonne"
  - Material 2: "Plate 15% @ R16,500 + waste 7.5% = R17,738.50 per tonne"
  - **Weighted Rate**: "R17,194.88 per tonne"
- **Actions**: Save, Cancel
- **Validation**: Proportions must sum to exactly 100%; reject if not

#### View: Rate Build-up Detail (Expandable Row or Slide Panel)
- **Title**: "Rate Build-up for [Line Item Description]"
- **Sections**:

```
Material Supply Cost
├─ UB/UC Local (85%): R15,900 × 1.075 × 0.85 = R14,528.63
├─ Plate (15%): R16,500 × 1.075 × 0.15 = R2,666.25
└─ Weighted Total: R17,194.88

Cost Components (per tonne)
├─ Fabrication: R8,000 (1.0x) ✓ Included
├─ Overheads: R4,150 ✓ Included
├─ Shop Priming: R1,380 ✗ Not Included
├─ On-Site Painting: R1,565 ✗ Not Included
├─ Delivery: R700 ✓ Included
├─ Bolts: R1,500 ✓ Included
├─ Erection: R1,800 ✓ Included
├─ Crainage: R1,080 ✗ Not Included (P&G only)
├─ Cherry Picker: R1,430 ✗ Not Included
└─ Galvanizing: R11,000 ✗ Not Included

Calculation
├─ Subtotal: R34,644.88
├─ Margin (0%): R0.00
├─ Total Before Rounding: R34,644.88
└─ Rounded Rate (R50): R34,650

Line Amount
└─ R34,650 × 11.19 t = R387,493.50
```

- **Actions**: Override Rate (button), Edit Inclusions (button)

#### View: Tender Summary
- **Route**: `/tenders/:id#summary`
- **Displays**:
```
Summary
├─ Total Tonnage: 931.62 t
├─ Number of Items: 47
├─ Subtotal (Sum of line amounts): R23,400,066.00
├─ Margin (Tender margin %): 0%
├─ Grand Total: R23,400,066.00
└─ Actions: Generate PDF, Submit Tender
```

### 6.3 UI Composition Rules

| Parent View | Child Component | Display Style | Interaction |
|-------------|-----------------|---------------|-------------|
| Line Items Table | Expandable detail row | Slide-down panel within row | Click "Details" to expand/collapse |
| Material Breakdown Modal | Material list | Grid with proportions | Drag slider or type percentage |
| Rate Build-up Detail | Cost components | Formatted list with checkmarks | Read-only (edit from configuration) |
| Tender Show | Summary section | Sticky footer or fixed box | Always visible; updates on save |

---

## 7. Calculations & Business Rules (REQUIRED)

### 7.1 Ephemeral Calculations

#### 7.1.1 Material Supply Cost Calculation

**Single Material:**
```
material_supply_rate_with_waste = base_rate_per_tonne × (1 + waste_percentage)

Example for UB_UC_LOCAL at 100% proportion:
= 15,900 × (1 + 0.075)
= 15,900 × 1.075
= R17,092.50 per tonne
```

**Blended Material Supplies:**
```
total_material_supply_rate = Σ (material_supply_rate_with_waste × proportion)

Example with 85% UB/UC Local and 15% Plate:
UB/UC: 15,900 × 1.075 × 0.85 = 14,528.63
Plate: 16,500 × 1.075 × 0.15 = 2,666.25
Total: 14,528.63 + 2,666.25 = R17,194.88 per tonne
```

**Constraint:** `SUM(proportions) MUST = 1.0 (100%)` - System rejects if not exact.

#### 7.1.2 Line Item Rate Build-up

**Full Rate Calculation:**
```
line_rate_per_unit =
    material_supply_rate                                                  -- e.g., 17,194.88
  + (fabrication_rate × fabrication_factor × fabrication_included)        -- 8,000 × 1.0 × 1 = 8,000
  + (overheads_rate × overheads_included)                                 -- 4,150 × 1 = 4,150
  + (shop_priming_rate × shop_priming_included)                           -- 1,380 × 0 = 0
  + (onsite_painting_rate × onsite_painting_included)                     -- 1,565 × 0 = 0
  + (delivery_rate × delivery_included)                                   -- 700 × 1 = 700
  + (bolts_rate × bolts_included)                                         -- 1,500 × 1 = 1,500
  + (erection_rate × erection_included)                                   -- 1,800 × 1 = 1,800
  + (crainage_rate × crainage_included)                                   -- 1,080 × 0 = 0
  + (cherry_picker_rate × cherry_picker_included)                         -- 1,430 × 0 = 0
  + (galvanizing_rate × galvanizing_included)                             -- 11,000 × 0 = 0

subtotal = 17,194.88 + 8,000 + 4,150 + 0 + 0 + 700 + 1,500 + 1,800 + 0 + 0 + 0
         = R34,644.88

margin_amount = subtotal × tender_margin_pct = 34,644.88 × 0% = R0

total_before_rounding = subtotal + margin_amount = 34,644.88 + 0 = R34,644.88

rounded_rate = CEILING(total_before_rounding, 50) = R34,650

line_amount = rounded_rate × quantity = 34,650 × 11.19 = R387,493.50
```

#### 7.1.3 Fabrication Multiplier (Per Work Type)

**Structural Work (Default):**
```
fabrication_cost = base_fabrication_rate × 1.0 × fabrication_included
                 = 8,000 × 1.0 × 1 = R8,000
```

**Platework:**
```
fabrication_cost = base_fabrication_rate × 1.75 × fabrication_included
                 = 8,000 × 1.75 × 1 = R14,000
```

**Piping:**
```
fabrication_cost = base_fabrication_rate × 3.0 × fabrication_included
                 = 8,000 × 3.0 × 1 = R24,000
```

#### 7.1.4 Tender Totals Calculation

```
total_tonnage = SUM(quantity for all line items where unit = 't')

subtotal_amount = SUM(line_amount for all line items)

grand_total = subtotal_amount + tender_margin_pct × subtotal_amount
            (or just subtotal_amount if margin applied per line)

NOTE: Margin can be applied:
- At tender level: affects final total
- At line level: affects each line rate before rounding
- Currently: applied per line before rounding (subtotal = line components + margin)
```

### 7.2 Business Rules Summary

| Rule ID | Rule Name | Description | Implementation |
|---------|-----------|-------------|-----------------|
| BR-001 | Rate Rounding | All line item rates rounded up to nearest R50 | `CEILING(rate, 50)` |
| BR-002 | Waste Application | Waste % applied to base material supply rate | `base_rate × (1 + waste_pct)` |
| BR-003 | Toggle Application | Boolean flags multiply rate by 0 or 1 | `rate × (include_flag ? 1 : 0)` |
| BR-004 | Margin Calculation | Applied to line subtotal before rounding | `subtotal × (1 + margin_pct)` |
| BR-005 | Material Proportions | Must sum to exactly 100% | Validation before save |
| BR-006 | CFLC Fabrication | CFLC/cold-rolled items always have fabrication = 0 | Auto-set if category = "CFLC" |
| BR-007 | Blended Material Cost | If multiple materials, calculate weighted average | `Σ(rate × proportion)` |
| BR-008 | Fabrication Multiplier | Work type scales base rate (1.0x structural, 1.75x platework, 3.0x piping) | `base_rate × factor × include` |
| BR-009 | Rate Override | User can override calculated rate | Store override; use instead of calculation |

### 7.3 Edge Cases

| Case ID | Scenario | Expected Behavior |
|---------|----------|-------------------|
| EC-001 | Zero quantity line item | Calculate rate normally; line amount = R0 |
| EC-002 | Missing material rate | Flag error; do not calculate; require user action |
| EC-003 | Negative quantity | Reject; quantities must be > 0 |
| EC-004 | All toggles off | Calculate material cost only; warn user of low total |
| EC-005 | Material proportions = 95% | Reject with message: "Proportions must sum to 100% (currently 95%)" |
| EC-006 | Material proportions = 105% | Reject with message: "Proportions must sum to 100% (currently 105%)" |
| EC-007 | Rate override to R0 | Allow; may be needed for special circumstances |
| EC-008 | Edit tender after submitted | System allows (does not lock); warn user that changes may not be submitted |
| EC-009 | Delete line item | Recalculate tender totals immediately |
| EC-010 | Rate update while tender open | Existing tender uses old rates (rates versioned); next tender gets new rates |

---

## 8. Sprint Task Generation (REQUIRED)

### 8.1 Component Build Order (Leaf First - Independently Testable)

Build and test bottom-up: leaf models first, then parents. Each component is independently testable using Rails scaffold forms + Turbo.

| Order | Model | Database Setup | Controller Actions | Route | Depends On |
|-------|-------|-----------------|-------------------|-------|-----------|
| 1 | MaterialSupply | Seed 22 materials with rates & waste % | index, show | /material_supplies | None |
| 2 | ProcessingRate | Seed processing rates (fab, overhead, etc.) | index, show | /processing_rates | None |
| 3 | Client | CRUD | index, show, new, create, edit, update | /clients | None |
| 4 | Tender | CRUD + generate E-number | index, show, new, create, edit, update | /tenders | Client |
| 5 | TenderLineItem | CRUD | index (nested), show (nested), new, create, edit, update, delete | /tenders/:id/line_items | Tender |
| 6 | LineItemMaterialBreakdown | Create on line item create | auto-create | auto | TenderLineItem |
| 7 | LineItemMaterial | CRUD materials per breakdown | create, update, delete (nested) | /breakdowns/:id/materials | LineItemMaterialBreakdown |
| 8 | LineItemRateBuildUp | Auto-create + recalculate on change | auto-recalculate | auto | TenderLineItem + LineItemMaterial |

### 8.2 Per-Component Task Breakdown

#### Component 1: Material Supply Setup
**Files:**
- `app/models/material_supply.rb`
- `app/views/material_supplies/index.html.erb`
- `app/views/material_supplies/show.html.erb`
- `db/seeds.rb` (seed 22 materials)

**Task:**
1. Create MaterialSupply model with validations
2. Add index and show views
3. Seed database with 22 material types from REQUIREMENTS.md
4. Verify all 22 materials load correctly

**Acceptance Criteria:**
- [ ] 22 materials exist in database with correct codes, names, base rates, waste %
- [ ] /material_supplies index displays all materials
- [ ] /material_supplies/1 show displays single material details

---

#### Component 2: Processing Rate Setup
**Files:**
- `app/models/processing_rate.rb`
- `app/views/processing_rates/index.html.erb`
- `app/views/processing_rates/show.html.erb`
- `db/seeds.rb` (seed processing rates)

**Task:**
1. Create ProcessingRate model with validations
2. Add index and show views
3. Seed database with processing rates (FABRICATION base_rate=8000, OVERHEADS=4150, etc.)
4. Support work_type factors (structural=1.0, platework=1.75, piping=3.0)

**Acceptance Criteria:**
- [ ] 10+ processing rates exist (SHOP_DRAWINGS, FABRICATION, OVERHEADS, etc.)
- [ ] Each processing rate has correct base rate and factor
- [ ] /processing_rates index displays all rates
- [ ] /processing_rates/1 show displays rate details including factor

---

#### Component 3: Client CRUD
**Files:**
- `app/models/client.rb`
- `app/controllers/clients_controller.rb`
- `app/views/clients/index.html.erb`
- `app/views/clients/show.html.erb`
- `app/views/clients/_form.html.erb`

**Task:**
1. Create Client model with associations to Tender
2. Build CRUD controller (index, show, new, create, edit, update, delete)
3. Build form partial for client details
4. Add validations (business_name required)

**Acceptance Criteria:**
- [ ] Can create new client with name and contact info
- [ ] Can view all clients on index
- [ ] Can edit client details
- [ ] Can delete client (only if no tenders reference it)
- [ ] Deleted client show 404

---

#### Component 4: Tender CRUD + E-Number Generation
**Files:**
- `app/models/tender.rb`
- `app/models/clients.rb` (add association)
- `app/controllers/tenders_controller.rb`
- `app/views/tenders/index.html.erb`
- `app/views/tenders/show.html.erb`
- `app/views/tenders/_form.html.erb`

**Task:**
1. Create Tender model with associations to Client, Users
2. Add E-number generation (format: E + sequential ID)
3. Build CRUD controller (index, show, new, create, edit, update, delete)
4. Build form: project name, client, tender date, notes
5. Build show page displaying tender header

**Acceptance Criteria:**
- [ ] New tender form creates record with generated E-number (e.g., E1, E2)
- [ ] Tender show displays: E-number, project name, client name, tender date, status
- [ ] Can edit tender details (project name, notes)
- [ ] Tender index lists all tenders with status, client, date
- [ ] Status dropdown shows: draft, in_progress, ready_for_review, approved, submitted, won, lost
- [ ] Tender date defaults to today

---

#### Component 5: Tender Line Items CRUD
**Files:**
- `app/models/tender_line_item.rb`
- `app/models/tender.rb` (add association `has_many :tender_line_items`)
- `app/controllers/tender_line_items_controller.rb`
- `app/views/tenders/show.html.erb` (add line items section)
- `app/views/tender_line_items/_line_item_row.html.erb`
- `app/views/tender_line_items/_form.html.erb`

**Task:**
1. Create TenderLineItem model with association to Tender
2. Build controller: create, update, delete (nested under tenders)
3. Build form partial: description, unit, quantity, category
4. Build line item table display on tender show page
5. Add Turbo Frame for line items list refresh

**Acceptance Criteria:**
- [ ] POST /tenders/:id/line_items creates line item and displays in table
- [ ] Line items table shows: Page, Item, Description, Unit, Qty, Actions
- [ ] Click "Add Line Item" opens modal form
- [ ] Form validation: description and quantity required, quantity > 0
- [ ] Can edit quantity/description inline or via modal
- [ ] DELETE button removes line item from table and database
- [ ] Turbo Frame updates line items table without page reload

---

#### Component 6: Material Breakdown - Auto-create & Nested Materials
**Files:**
- `app/models/line_item_material_breakdown.rb`
- `app/models/tender_line_item.rb` (add association `has_one :line_item_material_breakdown`)
- `app/models/line_item_material.rb`

**Task:**
1. Create LineItemMaterialBreakdown model (auto-created with line item)
2. Create LineItemMaterial model with association to breakdown and material_supply
3. Update TenderLineItem to auto-create breakdown on create
4. Add validations for proportion (0.0-1.0)

**Acceptance Criteria:**
- [ ] Create new line item → LineItemMaterialBreakdown auto-creates
- [ ] Can add line_item_materials to breakdown
- [ ] Each material has: material_supply_id, proportion (0-1.0)
- [ ] proportion value can be fetched and saved
- [ ] Delete line item → breakdown and materials cascade delete

---

#### Component 7: Material Selection UI - Modal
**Files:**
- `app/views/line_items/_material_modal.html.erb`
- `app/controllers/line_item_materials_controller.rb`
- `app/views/line_item_materials/_form.html.erb`
- `app/javascript/controllers/material_breakdown_controller.js`

**Task:**
1. Build modal form for material breakdown configuration
2. Display dropdown of 22 material supplies
3. Allow adding multiple materials with proportion inputs
4. Display real-time validation: proportions must sum to 100%
5. Show error if not exactly 100%
6. Calculate weighted material rate on save

**Acceptance Criteria:**
- [ ] Modal displays all 22 material supplies in dropdown
- [ ] Can add material and set proportion (e.g., 85%)
- [ ] Can add second material (e.g., 15%)
- [ ] Display: "UB/UC Local 85% @ R15,900 + waste 7.5% = R17,092.50"
- [ ] Display weighted total: "R17,194.88"
- [ ] Error if proportions ≠ 100% (e.g., "Proportions must sum to 100% (currently 95%)")
- [ ] Save button disabled if proportions invalid
- [ ] On save, materials persist to database

---

#### Component 8: Line Item Rate Build-up - Auto-calculate
**Files:**
- `app/models/line_item_rate_build_up.rb`
- `app/models/tender_line_item.rb` (add association `has_one :line_item_rate_build_up`)
- `app/services/rate_calculator_service.rb` (calculation logic)
- `app/views/tender_line_items/_rate_build_up_detail.html.erb`

**Task:**
1. Create LineItemRateBuildUp model
2. Auto-create with line item
3. Implement rate calculation logic in service:
   - Material supply cost (blended if multiple)
   - Fetch processing rates (fabrication, overheads, etc.)
   - Apply inclusion toggles (all default to true except painting, crainage, etc.)
   - Calculate subtotal
   - Apply margin
   - Apply rounding
4. Build detail view showing all components
5. Update on material change (Turbo refresh)

**Acceptance Criteria:**
- [ ] Create line item → LineItemRateBuildUp auto-creates with default rates
- [ ] Rate build-up calculates: material + fabrication + overheads + delivery + bolts + erection
- [ ] Rounding applied: CEILING to nearest R50
- [ ] Detail view displays all components with checkmarks
- [ ] Update material → rates recalculate instantly (Turbo)
- [ ] Line amount (rate × qty) displays correctly
- [ ] Calculations match Excel exactly (test with known tender data)

---

### 8.3 Fields Per Component

| Model | Editable Fields | Calculated Fields | Child Collection |
|-------|-----------------|-------------------|------------------|
| MaterialSupply | code, name, category, base_rate, waste_pct | — | line_item_materials |
| ProcessingRate | code, name, base_rate, work_type, factor | — | — |
| Client | business_name, contact_name, contact_email | — | tenders |
| Tender | project_name, client_id, tender_date, notes, status, margin_pct | E-number, total_tonnage, subtotal, grand_total | line_items |
| TenderLineItem | description, unit, quantity, category, section_header | rate, line_amount | material_breakdown, rate_build_up |
| LineItemMaterial | proportion | calculated_rate | — |
| LineItemRateBuildUp | rate_override, inclusion toggles | material_supply_rate, fabrication_cost, total, rounded_rate | — |

### 8.4 Stimulus Controllers Needed

| Controller | Purpose | Models Using It | Events |
|------------|---------|-----------------|--------|
| material-breakdown | Material proportion validation, calculate weighted rate | LineItemMaterial | change, blur |
| line-item-rate | Display/hide rate build-up detail, copy to clipboard | LineItemRateBuildUp | toggle, click |
| tender-summary | Recalculate tender totals on line item change | Tender | turbo:load, line-item:updated |

### 8.5 Seed Data Requirements

| Model | # Records | Seed File | Purpose |
|-------|-----------|-----------|---------|
| MaterialSupply | 22 | db/seeds.rb (per REQUIREMENTS.md) | All material types for selection dropdown |
| ProcessingRate | 10+ | db/seeds.rb | Fabrication, overheads, etc. |
| Client | 3 | db/seeds.rb or test fixtures | Sample clients for testing |
| Tender | 2-3 | db/test/fixtures or integration tests | Test tenders with known data |

### 8.6 Dependencies

**External Dependencies:**
- Turbo Rails (for Frames & Streams to refresh components)
- Stimulus JS (for validation, calculations on client)
- Decimal math library (for precise R calculations)

**Internal Dependencies:**
- Tender → Client (must exist)
- TenderLineItem → Tender (parent)
- LineItemMaterial → LineItemMaterialBreakdown, MaterialSupply
- LineItemRateBuildUp → TenderLineItem, ProcessingRate

---

## 9. Open Questions & Assumptions

### 9.1 Open Questions

| Question | Impact | Proposed Answer | Status |
|----------|--------|-----------------|--------|
| Should material rates versioned per tender (frozen) or always use latest? | High | Use latest rates for new tenders; existing tenders keep rates at submission time | Pending confirmation |
| Should tender margin be per-line or per-tender? | High | Per-line (margin applied before rounding per line item); affects all line rates | Confirmed in REQUIREMENTS |
| Should CFLC auto-detect from category or user must select? | Medium | Auto-detect based on category field; user can override | Phase 1: Manual, Phase 2: Auto-detect |
| Can user have multiple tenders open in parallel? | Medium | Yes; no locking; concurrent edits allowed | Assumed yes |
| Should tender totals update in real-time or on save? | Medium | Update on save (via Turbo after line item CRUD); not live as typing | Assumed on save |

### 9.2 Assumptions

| Assumption | Rationale |
|-----------|-----------|
| All rates in ZAR | No multi-currency mentioned in REQUIREMENTS |
| Single timezone (RSB is single-location) | Simplifies timestamp handling |
| Material proportions must sum to exactly 100% | Business rule per REQUIREMENTS |
| Processing rates don't change mid-tender | Rates frozen at tender creation; changes apply to new tenders |
| Users can edit tenders after submission | No audit lock; changes tracked in audit log |
| Web-only (no offline required) | Phase 1 scope; offline deferred |
| No approval workflow in Phase 1 | Status field exists but no approval logic |
| Max 100 line items per tender (MVP) | Can scale later if needed |

---

## 10. Demo Success Criteria

**By end of this 2-3 week sprint, demo should show:**

1. ✅ Create new tender "E1001 - RPP Transformers"
2. ✅ Add 5 line items with descriptions, units, quantities
3. ✅ Configure materials for first line item:
   - Select 85% UB/UC Local + 15% Plate
   - See calculated material rate with waste
4. ✅ View rate build-up detail showing all components
5. ✅ Update material breakdown → see rates recalculate instantly
6. ✅ View tender summary:
   - Total tonnage: 931.62 t
   - Subtotal: R23,400,066
   - Grand Total: R23,400,066
7. ✅ Calculations match Excel exactly (bit-for-bit accuracy)
8. ✅ Can save and reload tender (persistence)

---

**Document Status:** Ready for Development  
**Next Phase:** BOQ import & parsing (separate scope)  
**Last Updated:** December 1, 2025
