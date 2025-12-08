# Crane Equipment Calculations - Vertical Slice Scope

> **VERTICAL SLICE REQUIREMENT**: This scope defines a standalone, demo-able full stack feature covering crane selection, cost calculation, and crainage rate distribution. It's independently buildable and demo-able in 2 weeks, building on existing Tender infrastructure.

**Timeline:** 2 weeks (one focused development sprint)
**Status:** IN PROGRESS - UI Built, Calculations Pending
**Document Version:** 2.1
**Last Updated:** December 8, 2025

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| Crane Rates Model | ✅ Complete | 7 sizes × 2 ownership types seeded |
| Crane Complements Model | ✅ Complete | Model exists, needs seed data verification |
| On-Site Breakdown Model | ✅ Complete | roof_area, erection_rate, program_duration fields |
| On-Site Breakdown UI | ✅ Complete | Edit form with inline editing |
| Tender Crane Selections | ✅ Complete | CRUD for crane selections working |
| Crane Rates Table Display | ✅ Complete | Shows all crane sizes and rates |
| Add Crane Selection | ✅ Complete | Add row with crane dropdown |
| Program Duration Calc | 🟡 Partial | Formula exists, needs auto-update |
| Crane Complement Lookup | 🔴 Pending | Auto-lookup based on erection rate |
| Wet Rate Auto-fill | 🔴 Pending | Should auto-populate from crane_rates |
| Total Cost Calculation | 🔴 Pending | duration × wet_rate × quantity |
| Crainage Rate/Tonne | 🔴 Pending | total_cost / tonnage with R20 rounding |
| P&G Integration | 🔴 Pending | Create P&G item from crane costs |
| Mutual Exclusion | 🔴 Pending | Line items OR P&G toggle |

### What's Working (Dec 8 Demo)
- On-site breakdown form with roof area and erection rate inputs
- Crane rates lookup table displayed for reference
- Add/remove crane selections
- Crane type dropdown (populated from crane_rates)
- RSB Owned vs Rental designation
- Splicing crane toggle and fields
- Miscellaneous crane toggle and fields

### What's Pending (This Week Priority)
1. Auto-calculate program duration from roof_area / erection_rate
2. Auto-lookup crane complement based on erection rate bracket
3. Auto-populate wet_rate when crane selected
4. Calculate total_cost = wet_rate × duration × quantity
5. Sum all crane costs for total crainage
6. Calculate crainage_rate_per_tonne with R20 rounding
7. Feed crane costs into P&G or line item rates

---

## 1. Overview & Objectives

### 1.1 Problem Statement

The current crane equipment selection and costing process is manual and complex, requiring expert knowledge to:
- Calculate required crane complement based on roof area and erection rate
- Lookup and select appropriate crane sizes and quantities
- Calculate program duration and total crane costs
- Apply rates per tonne for crainage allocation across line items

The process is embedded in a complex Excel lookup table (DATA SHEET LOCKED) and requires understanding of:
- Crane complement lookup logic (area brackets to crane combinations)
- Crane rate tables (wet vs dry rates, ownership types, sizes)
- Splicing and miscellaneous crane optional requirements
- P&G vs line-item inclusion mutual exclusion

### 1.2 Demo Scenario

**Initial Setup:**
- Admin has pre-loaded crane rates for 7 sizes (10t-90t) with RSB-owned and rental options
- Admin has configured crane complement lookup table (5 erection rate brackets)
- Tender E3801 "RPP Transformers" exists with total tonnage of 931.62 t
- QS user (Demi) is ready to configure crane requirements

**Workflow:**
1. **Navigate to Site Config:** Demi opens Tender E3801 and clicks "Site Configuration"
2. **Enter Site Parameters:**
   - Total Roof Area: 19,609 m²
   - Area Erected Per Day: 300 m²/day
   - System calculates: Program Duration = CEILING(19,609/300) = 66 days
3. **View Auto-Lookup Result:**
   - System displays: "Recommended: 1 × 10t + 2 × 25t (combined rate R8,300/day)"
   - User sees breakdown of main crane costs
4. **Configure Splicing Crane (Optional):**
   - Demi checks "Splicing crane required"
   - Selects: 25t crane for 70 days
   - System calculates: R2,410/day × 70 = R168,700
5. **Skip Miscellaneous Crane:**
   - Leaves "Miscellaneous crane required" unchecked
6. **Review Cost Summary:**
   - Main Crane Cost: R547,800 (66 days × R8,300/day)
   - Splicing Crane Cost: R168,700
   - Total Crainage: R716,500
   - Crainage Rate per Tonne: CEILING(716,500/931.62, 20) = R780/t
7. **Set Inclusion Mode:**
   - Selects "Include in P&G" (not line item rates)
   - P&G line item auto-created with R716,500 lump sum
8. **Save and Verify:**
   - All values persist; line item rates exclude crainage
   - P&G shows crainage line

**Success Criteria:**
- Enter roof area and erection rate → program duration auto-calculates
- Crane complement auto-lookup returns correct combination for 300 m²/day bracket
- Optional splicing/misc cranes can be added with size and duration
- Total crainage cost sums all crane selections
- Crainage rate per tonne calculates correctly with R20 rounding
- Mutual exclusion enforced: crainage in line items OR P&G (not both)
- Calculations match Excel exactly

---

## 2. Personas & User Stories

### 2.1 Personas

**Demi (QS)** - Quantity Surveyor
- Configures crane requirements for tenders
- Needs: Quick lookup, easy overrides, clear cost breakdown

**Richard (Admin/Director)** - Strategy & Oversight
- Sets crane rates and ownership preferences
- Needs: Audit trail, rate management

### 2.2 User Stories

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-030 | As Demi, I want to enter the total roof area and erection rate so that crane requirements are calculated | Input fields with automatic program duration and crane complement lookup | High |
| US-031 | As Richard, I want to select RSB-owned cranes vs rental cranes so that we can use our own equipment when available | Ownership type selection per tender | High |
| US-032 | As Demi, I want to manually adjust the crane complement so that I can account for project-specific requirements | Editable crane selections with recalculation | High |
| US-033 | As Demi, I want to add splicing and miscellaneous cranes so that specialized lifting needs are captured | Optional crane sections with size/duration inputs | High |
| US-034 | As Demi, I want to see the total crainage cost and rate per tonne so that I can verify the calculation | Summary section with breakdown | High |
| US-035 | As Demi, I want to choose whether crainage goes in line items or P&G so that there's no double-counting | Radio toggle with mutual exclusion | High |

---

## 3. Current (As-Is) Process

### 3.1 Data Entry Narrative

**Step 1: Data Entry (Demi)**
- Enters total roof area in m² (e.g., 19,609 m²)
- Enters erection rate (area erected per day) in m/day (e.g., 300 m/day)

**Step 2: Crane Complement Lookup (Automatic in Excel)**
- System looks up crane complement table (DATA SHEET LOCKED)
- Table keyed by erection rate brackets (e.g., 250–350 m/day)
- Lookup returns: crane combination description (e.g., "1 × 10t + 2 × 25t")
- Lookup returns: wet rate per day (combined daily rate)

**Step 3: Optional Splicing/Misc Crane (Manual)**
- Demi manually enters if splicing crane required (Yes/No)
- If yes, selects crane size from available options
- Enters duration in days
- Lookup rate from crane rates table

**Step 4: Program Duration Calculation**
- System calculates: program_duration = CEILING(total_roof_area / erection_rate_sqm_day, 1)

**Step 5: Crane Cost Calculation (Manual in Excel)**
- Main crane cost = wet_rate_per_day × program_duration
- Add splicing crane cost if applicable
- Add miscellaneous crane cost if applicable
- Total crane cost = sum of all crane costs

**Step 6: Rate per Tonne**
- System divides total crane cost by total tonnage
- Rounded to nearest R20
- Result fed into either line item rates or P&G items

### 3.2 Current Pain Points

| Pain Point | Description |
|------------|-------------|
| Complex lookup logic | Nested IF or VLOOKUP embedded in Excel; hard to understand |
| Manual crane selection | User must know crane complement table; error-prone |
| No audit trail | Cannot track which cranes were selected or why |
| Difficult overrides | Manual recalculation needed if crane complement changed |
| Mutual exclusion not enforced | User can accidentally double-count crainage in items + P&G |

---

## 4. Future (To-Be) Process

### 4.1 Step-by-Step Workflow

#### Step 1: Navigate to On-Site Mobile Crane Breakdown
- User opens Tender show page
- Clicks "On-Site Mobile Crane Breakdown" tab or button
- System displays crane breakdown form

#### Step 2: Enter Site Parameters
- Input: Total Roof Area (m²)
- Input: Area Erected Per Day (m²/day)
- System auto-calculates: Program Duration (days)
- Display: "Program Duration: 66 days"

#### Step 3: View Crane Complement Auto-Lookup
- System queries crane_complements table
- Finds bracket where erection rate falls
- Displays: "Recommended: 1 × 10t + 2 × 25t"
- Displays: "Combined Rate: R8,300/day (wet)"
- Button: "Override Crane Selection"

#### Step 4: Configure Main Cranes (If Override)
- User clicks "Override"
- Modal shows editable crane selections
- Can change quantities, sizes
- System recalculates total daily rate

#### Step 5: Configure Optional Cranes
- Checkbox: "Splicing crane required?"
  - If checked: Size dropdown + Duration input
  - System calculates cost
- Checkbox: "Miscellaneous crane required?"
  - If checked: Size dropdown + Duration input
  - System calculates cost

#### Step 6: Select Ownership Type
- Radio: "RSB-Owned" or "Rental"
- System updates all crane rates based on selection

#### Step 7: View Cost Summary
- Main Crane Cost: R___
- Splicing Crane Cost: R___ (if applicable)
- Misc Crane Cost: R___ (if applicable)
- **Total Crainage Cost: R___**
- **Crainage Rate per Tonne: R___** (rounded to R20)

#### Step 8: Set Crainage Inclusion
- Radio: "Include in Line Item Rates" / "Include in P&G"
- System enforces mutual exclusion
- If P&G: auto-creates/updates P&G line item

#### Step 9: Save Configuration
- All values persist to database
- Tender line items or P&G updated accordingly

---

## 5. Database Schema (REQUIRED)

### 5.1 Table Definitions

#### Table: crane_rates
Master data: Mobile crane rental rates by size and ownership.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| size | string(10) | NOT NULL | Crane capacity (10t, 20t, 25t, 30t, 35t, 50t, 90t) |
| ownership_type | string(20) | NOT NULL, DEFAULT 'rental' | 'rsb_owned' or 'rental' |
| dry_rate_per_day | decimal(12,2) | NOT NULL | 9-hour dry rate (no operator, no diesel) |
| diesel_per_day | decimal(12,2) | NOT NULL, DEFAULT 0 | Daily diesel allowance |
| is_active | boolean | DEFAULT true | Whether rate is currently active |
| effective_from | date | NOT NULL | Date rate became active |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Business Logic:**
- Wet rate (with operator & diesel) = dry_rate_per_day + diesel_per_day
- Example for 25t rental: 1,660 + 750 = R2,410/day

---

#### Table: crane_complements
Lookup table for default crane combinations based on erection rate.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| area_min_sqm | decimal(10,2) | NOT NULL | Minimum m²/day for this bracket |
| area_max_sqm | decimal(10,2) | NOT NULL | Maximum m²/day for this bracket |
| crane_recommendation | string(100) | NOT NULL | Crane combination text (e.g., "1 × 10t + 2 × 25t") |
| default_wet_rate_per_day | decimal(12,2) | NOT NULL | Combined daily wet rate |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Bracket Logic:**
- Query: `WHERE area_min_sqm <= erection_rate AND area_max_sqm >= erection_rate`
- If below minimum bracket, use lowest bracket
- If above maximum bracket, use highest bracket

---

#### Table: on_site_mobile_crane_breakdown
On-site parameters for crane and equipment calculations (one per tender).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_id | bigint | FK to tenders, UNIQUE, CASCADE | Reference to tender |
| total_roof_area_sqm | decimal(12,2) | DEFAULT 0.0 | Total roof area in m² |
| erection_rate_sqm_per_day | decimal(10,2) | DEFAULT 0.0 | Area erected per day |
| program_duration_days | integer | DEFAULT 0 | Calculated program length |
| ownership_type | string(20) | DEFAULT 'rental' | 'rsb_owned' or 'rental' for all cranes |
| splicing_crane_required | boolean | DEFAULT false | Is splicing crane needed? |
| splicing_crane_size | string(10) | | Crane size for splicing (e.g., "25t") |
| splicing_crane_days | integer | DEFAULT 0 | Duration in days |
| misc_crane_required | boolean | DEFAULT false | Is miscellaneous crane needed? |
| misc_crane_size | string(10) | | Crane size for misc |
| misc_crane_days | integer | DEFAULT 0 | Duration in days |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Calculations:**
```
program_duration_days = CEILING(total_roof_area_sqm / erection_rate_sqm_per_day, 1)
```

---

#### Table: tender_crane_selections
Individual crane selections for the tender (supports multiple cranes).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_id | bigint | FK to tenders, CASCADE | Reference to tender |
| crane_rate_id | bigint | FK to crane_rates | Reference to crane rate used |
| purpose | string(20) | NOT NULL, DEFAULT 'main' | 'main', 'splicing', or 'miscellaneous' |
| quantity | integer | NOT NULL, DEFAULT 1 | Number of cranes of this type |
| duration_days | integer | NOT NULL | Duration in days |
| wet_rate_per_day | decimal(12,2) | NOT NULL | Rate used (snapshot from crane_rate) |
| total_cost | decimal(14,2) | DEFAULT 0.0 | Calculated: wet_rate × quantity × duration |
| sort_order | integer | DEFAULT 0 | Display order |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Cost Calculation:**
```
total_cost = wet_rate_per_day × quantity × duration_days
```

---

#### Table: tender_inclusions_exclusions
Toggle settings for what's included in line items vs P&G (one per tender).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_id | bigint | FK to tenders, UNIQUE, CASCADE | Reference to tender |
| include_crainage | boolean | DEFAULT false | Include crainage in line item rates? |
| include_cherry_picker | boolean | DEFAULT false | Include cherry picker in line item rates? |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Mutual Exclusion Rule:**
- If include_crainage = true: crainage included in line_item_rate_build_ups.crainage_rate
- If include_crainage = false: crainage appears as P&G line item (lump sum)

---

#### Table: tender_preliminary_items (P&G Items)
P&G line items including crainage when not in line rates.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | Primary key |
| tender_id | bigint | FK to tenders, CASCADE | Reference to tender |
| code | string(50) | NOT NULL | Item code (CRAINAGE, CHERRY_PICKER, etc.) |
| description | string(255) | NOT NULL | Display description |
| lump_sum_amount | decimal(14,2) | DEFAULT 0.0 | Total lump sum cost |
| rate_per_tonne | decimal(12,2) | DEFAULT 0.0 | Rate per tonne (for reference) |
| is_included | boolean | DEFAULT true | Whether included in tender total |
| sort_order | integer | DEFAULT 0 | Display order |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

---

### 5.2 Relationships & Cardinality

| Parent Table | Child Table | Relationship | Foreign Key | On Delete |
|--------------|-------------|--------------|-------------|-----------|
| tenders | on_site_mobile_crane_breakdown | 1:1 | tender_id | cascade |
| tenders | tender_crane_selections | 1:many | tender_id | cascade |
| tenders | tender_inclusions_exclusions | 1:1 | tender_id | cascade |
| tenders | tender_preliminary_items | 1:many | tender_id | cascade |
| crane_rates | tender_crane_selections | 1:many | crane_rate_id | restrict |

### 5.3 Entity Relationship Diagram

```
Crane_Rates (Master)                Crane_Complements (Master)
    |                                      |
    +-- (1:many) ----+                     | (lookup only)
                     |                     |
                     v                     v
                Tender_Crane_Selections    |
                     ^                     |
                     |                     |
Tenders -------------+---------------------+
    |
    +-- (1:1) --> On_Site_Mobile_Crane_Breakdown
    |
    +-- (1:1) --> Tender_Inclusions_Exclusions
    |
    +-- (1:many) --> Tender_Preliminary_Items
    |
    +-- (1:many) --> Tender_Line_Items
                         |
                         +-- (1:1) --> Line_Item_Rate_Build_Ups
                                           |
                                           +-- crainage_rate (from calc)
```

### 5.4 Indexes

| Table | Index Name | Columns | Type | Purpose |
|-------|------------|---------|------|---------|
| crane_rates | idx_crane_size_ownership | size, ownership_type | btree | Fast lookup by crane type |
| crane_rates | idx_crane_active | is_active | btree | Filter active rates |
| crane_complements | idx_complement_bracket | area_min_sqm, area_max_sqm | btree | Fast bracket lookup |
| on_site_mobile_crane_breakdown | idx_site_tender | tender_id | unique | One config per tender |
| tender_crane_selections | idx_crane_sel_tender | tender_id | btree | Find all selections for tender |
| tender_crane_selections | idx_crane_sel_purpose | tender_id, purpose | btree | Find by purpose type |
| tender_inclusions_exclusions | idx_incl_tender | tender_id | unique | One record per tender |
| tender_preliminary_items | idx_prelim_tender | tender_id | btree | Find P&G items for tender |
| tender_preliminary_items | idx_prelim_code | tender_id, code | unique | One item per code per tender |

---

## 6. UI Composition & Scaffolding (REQUIRED)

### 6.1 Screen Hierarchy

**Routing Principles:**
- Every model has its own independent `/show` route
- Parent models index their children inline (no modals)
- All edits happen inline with dirty-form indicators
- Each partial is independently testable via its own route

```
[OnSiteMobileCraneBreakdown Show: /on_site_mobile_crane_breakdowns/:id]
    |
    +-- [Editable Partial: _on_site_mobile_crane_breakdown.html.erb]
    |       |
    |       +-- Total Roof Area (editable, Turbo Frame)
    |       +-- Erection Rate (editable, Turbo Frame)
    |       +-- Program Duration (read-only, calculated)
    |       +-- Ownership Type Radio (editable, Turbo Frame)
    |       +-- Splicing Crane Required Checkbox
    |       +-- Misc Crane Required Checkbox
    |
    +-- [Crane Complements Index: /crane_complements]
    |       |
    |       +-- (read-only master data for reference)
    |
    +-- [Tender Crane Selections Index: /tenders/:tender_id/crane_selections]
            |
            +-- [Crane Selection 1 Show: /tender_crane_selections/:id]
            |       |
            |       +-- [Editable Partial: _tender_crane_selection.html.erb]
            |               |
            |               +-- Purpose (main/splicing/misc, read-only)
            |               +-- Size Dropdown (editable, Turbo Frame)
            |               +-- Quantity (editable, Turbo Frame)
            |               +-- Duration Days (editable, Turbo Frame)
            |               +-- Wet Rate (read-only snapshot, auto-calculated)
            |               +-- Total Cost (read-only, calculated)
            |               +-- Delete button (Turbo Stream)
            |
            +-- [Crane Selection 2 Show: /tender_crane_selections/:id]
            |
            +-- [+ Add Crane button] → creates new selection
            |
            +-- [Cost Summary (read-only calculated display)]
            |       |
            |       +-- Main Crane Cost
            |       +-- Splicing Crane Cost
            |       +-- Misc Crane Cost
            |       +-- Total Crainage
            |       +-- Rate per Tonne
            |
            +-- [Tender Inclusion Exclusion Show: /tender_inclusions_exclusions/:id]
                    |
                    +-- [Editable Partial: _tender_inclusion_exclusion.html.erb]
                            |
                            +-- Include in Line Items Radio (editable, Turbo Frame)
                            +-- Include in P&G Radio (editable, Turbo Frame)
```

### 6.2 View Specifications

#### View 1: On-Site Mobile Crane Breakdown Show
- **Route**: `/on_site_mobile_crane_breakdowns/:id`
- **Primary Table**: on_site_mobile_crane_breakdown
- **Turbo Frame**: `turbo_frame_tag dom_id(@breakdown)`
- **Parent Page**: Links back to `/tenders/:tender_id` 
- **Layout**: Just renders `_on_site_mobile_crane_breakdown.html.erb` partial

**Page displays:**
```
+----------------------------------------------------------+
| Site Configuration for E3801                              |
| [← Back to Tender]                                        |
+----------------------------------------------------------+
| 
| ⏱ Last updated 2 minutes ago
|
| Total Roof Area:      [19,609    ✏] m²   [✓ Save]
| Erection Rate:        [   300    ✏] m²/day
| Program Duration:     66 days (calculated)
| 
| Ownership Type:
| (•) Rental    ( ) RSB-Owned
|
| [✓] Splicing crane required?
| [ ] Miscellaneous crane required?
|
| [View All Crane Selections] ← Links to crane_selections index
|
+----------------------------------------------------------+
```

**Key Points:**
- All fields are inline editable (pencil icon)
- Dirty indicator shows unsaved changes
- Save via Checkmark → async POST/PATCH, no page reload
- "View All Crane Selections" links to `/tenders/:tender_id/crane_selections`

---

#### View 2: Tender Crane Selections Index
- **Route**: `/tenders/:tender_id/crane_selections`
- **Primary Table**: tender_crane_selections (index of records for tender)
- **Parent**: OnSiteMobileCraneBreakdown (via tender)
- **Layout**: Page renders a list of `_tender_crane_selection.html.erb` partials, one per selection

**Page displays:**
```
+----------------------------------------------------------+
| Crane Selections for E3801                                |
| [← Back to Site Config]                                  |
+----------------------------------------------------------+
|
| Crane Selection #1: Main Crane                            
| ┌─────────────────────────────────────────────────────┐  |
| │ Purpose:    Main         (read-only label)          │  |
| │ Size:       [10t ▼ ✏]   (edit via dropdown)        │  |
| │ Quantity:   [1    ✏]                               │  |
| │ Duration:   [66   ✏] days                          │  |
| │ Wet Rate:   R2,200/day (read-only, from crane_rates)  │  |
| │ Total Cost: R145,200 (calculated)                   │  |
| │                                      [Edit] [Delete] │  |
| └─────────────────────────────────────────────────────┘  |
|
| Crane Selection #2: Main Crane (2nd)                      
| ┌─────────────────────────────────────────────────────┐  |
| │ Purpose:    Main                                    │  |
| │ Size:       [25t ▼ ✏]                              │  |
| │ Quantity:   [2    ✏]                               │  |
| │ Duration:   [66   ✏] days                          │  |
| │ Wet Rate:   R2,410/day                             │  |
| │ Total Cost: R318,120                               │  |
| │                                      [Edit] [Delete] │  |
| └─────────────────────────────────────────────────────┘  |
|
| Crane Selection #3: Splicing Crane                        
| ┌─────────────────────────────────────────────────────┐  |
| │ Purpose:    Splicing                               │  |
| │ Size:       [25t ▼ ✏]                              │  |
| │ Quantity:   [1    ✏]                               │  |
| │ Duration:   [70   ✏] days                          │  |
| │ Wet Rate:   R2,410/day                             │  |
| │ Total Cost: R168,700                               │  |
| │                                      [Edit] [Delete] │  |
| └─────────────────────────────────────────────────────┘  |
|
| [+ Add Crane Selection]  ← Creates new, appends to index
|
| ─────────────────────────────────────────────────────────
| COST SUMMARY (read-only, calculated):
| Main Crane Cost:        R463,320
| Splicing Crane Cost:    R168,700
| Miscellaneous Cost:     R      0
| ────────────────────────────────
| TOTAL CRAINAGE:         R632,020
| Crainage Rate/Tonne:    R    780 (rounded to nearest R20)
|
+----------------------------------------------------------+
```

**Key Points:**
- Each crane selection renders as an editable card
- Edit/Delete buttons on each card
- All field edits happen inline with Turbo Frame wrapping
- Changes recalculate costs in real-time (Stimulus controller)
- Cost summary updates after each save
- "[+ Add Crane Selection]" button POSTs to create new record, appends to list
- "Delete" button removes via TURBO STREAM (no page reload)

---

#### View 3: Tender Crane Selection Show
- **Route**: `/tender_crane_selections/:id`
- **Primary Table**: tender_crane_selection (single record)
- **Turbo Frame**: `turbo_frame_tag dom_id(@selection)`
- **Layout**: Renders just the `_tender_crane_selection.html.erb` partial

**Page displays:**
```
+----------------------------------------------------------+
| Crane Selection #2                                        |
| [← Back to Crane Selections]                             |
+----------------------------------------------------------+
|
| Purpose:    Main (read-only)
| Size:       [25t ▼ ✏]   (edit inline, Turbo Frame)
| Quantity:   [2    ✏]
| Duration:   [66   ✏] days
| Wet Rate:   R2,410/day (read-only snapshot)
| Total Cost: R318,120 (read-only calculated)
|
| ⏱ Last updated 5 minutes ago
|
| [Edit Crane]  [Delete]  [Back to List]
|
+----------------------------------------------------------+
```

**Key Points:**
- Developer can iterate on this component independently
- No parent views needed to test
- Edit via inline Turbo Frames
- Delete via Turbo Stream confirmation
- Breadcrumb links back to crane_selections index

---

#### View 4: Tender Inclusion/Exclusion Show
- **Route**: `/tender_inclusions_exclusions/:id`
- **Primary Table**: tender_inclusion_exclusion (one per tender)
- **Parent**: Tender
- **Layout**: Renders just the `_tender_inclusion_exclusion.html.erb` partial

**Page displays:**
```
+----------------------------------------------------------+
| Crainage Inclusion Settings for E3801                    |
| [← Back to Tender]                                       |
+----------------------------------------------------------+
|
| Where should crainage be charged?
|
| ( ) Include in Line Item Rates
|     (All line items get crainage_rate added to their cost)
|
| (•) Include in P&G (Preliminaries & General)
|     (Single lump-sum P&G line item for total crainage)
|
| ⓘ These are mutually exclusive. Selecting one 
|   automatically deselects the other to prevent 
|   double-counting.
|
| ⏱ Last updated 10 minutes ago
|
| [Back to Tender]
|
+----------------------------------------------------------+
```

**Key Points:**
- Radio buttons for include_crainage toggle
- On selection → async PATCH, no page reload
- Mutually exclusive enforcement in model/controller
- After save, triggers CrainageCalculatorService to redistribute

---

#### View 5: Cost Summary (Displayed on Multiple Views)
- **Location**: Fixed card/sidebar shown on:
  - `/tender_crane_selections` (crane selections index)
  - `/on_site_mobile_crane_breakdowns/:id` (site config)
- **Updates**: Via Turbo Stream after each selection save
- **Read-only**: All fields calculated, no user input

**Display:**
```
┌─────────────────────────────────────┐
│ CRAINAGE COST SUMMARY               │
├─────────────────────────────────────┤
│ Main Cranes (66 days)               │
│   1 × 10t @ R2,200/day =  R145,200  │
│   2 × 25t @ R2,410/day =  R318,120  │
│   Subtotal:               R463,320  │
│                                     │
│ Splicing Crane (70 days)            │
│   1 × 25t @ R2,410/day =  R168,700  │
│                                     │
│ Miscellaneous:            R      0  │
├─────────────────────────────────────┤
│ TOTAL CRAINAGE:           R632,020  │
│                                     │
│ Total Tonnage:            931.62 t  │
│ Rate per Tonne:           R    780  │
│ (rounded to nearest R20)            │
└─────────────────────────────────────┘
```

**Key Points:**
- Displayed as a separate Turbo Frame
- Updates after CrainageCalculatorService runs
- No direct user interaction (read-only summary)

### 6.3 UI Composition Rules

**RULE 1: NO MODALS** - All editing happens inline or on dedicated show pages.

**RULE 2: INLINE EDITING** - Every field is editable inline with Turbo Frame wrapping:
- Pencil icon on hover
- Edit mode: input field + Checkmark (save) + X (cancel)
- Dirty indicator: shows unsaved changes
- On Checkmark: async PATCH request, no page reload
- All updates via Turbo Streams

**RULE 3: INDEPENDENT ROUTES** - Every model has its own `/show` route:
- `/on_site_mobile_crane_breakdowns/:id` — Site config editable
- `/tender_crane_selections/:id` — Individual crane selection editable
- `/tender_inclusions_exclusions/:id` — Inclusion toggle editable
- Developers can test each component in isolation

**RULE 4: PARENT INDEXES CHILDREN** - Parent show pages render child collections:
- `/tender_crane_selections` (index) renders list of `_tender_crane_selection.html.erb` partials
- Each partial is independently editable inline
- "+ Add" button creates new child, appends to list via Turbo Stream
- Delete button removes child via Turbo Stream

| View | Route | Primary Table | Editable Fields | Layout |
|------|-------|---------------|-----------------|--------|
| Site Config | `/on_site_mobile_crane_breakdowns/:id` | on_site_mobile_crane_breakdown | roof_area, erection_rate, ownership_type, splicing_required, misc_required | Partial only; edit inline |
| Crane Selections (Index) | `/tenders/:tender_id/crane_selections` | tender_crane_selections | List of partials; each has inline editable size, quantity, duration | Index page renders multiple `_tender_crane_selection.html.erb` partials |
| Crane Selection (Show) | `/tender_crane_selections/:id` | tender_crane_selection (single) | size, quantity, duration | Partial only; edit inline |
| Inclusion/Exclusion | `/tender_inclusions_exclusions/:id` | tender_inclusion_exclusion | include_crainage (radio toggle) | Partial only; edit inline |
| Cost Summary | (embedded on crane_selections index & site config) | (calculated, read-only) | None (read-only) | Turbo Frame, updates after each selection save |

---

## 7. Calculations & Business Rules (REQUIRED)

### 7.1 Ephemeral Calculations

#### 7.1.1 Program Duration Calculation

```ruby
program_duration_days = (total_roof_area_sqm / erection_rate_sqm_per_day).ceil

# Example:
# = (19,609 / 300).ceil
# = 65.36.ceil
# = 66 days
```

**Trigger:** On change of total_roof_area_sqm or erection_rate_sqm_per_day

#### 7.1.2 Crane Complement Lookup

```ruby
# Query crane_complements where rate falls in bracket
complement = CraneComplement.where(
  "area_min_sqm <= ? AND area_max_sqm >= ?",
  erection_rate,
  erection_rate
).first

# Returns: complement_description, default_wet_rate_per_day
```

**Fallback Rules:**
- If erection_rate < minimum bracket → use lowest bracket
- If erection_rate > maximum bracket → use highest bracket

#### 7.1.3 Wet Rate Calculation

```ruby
wet_rate_per_day = dry_rate_per_day + diesel_per_day

# Example for 25t rental:
# = 1,660 + 750
# = R2,410/day
```

#### 7.1.4 Individual Crane Cost

```ruby
crane_cost = wet_rate_per_day × quantity × duration_days

# Example: 2 × 25t cranes for 66 days
# = 2,410 × 2 × 66
# = R318,120
```

#### 7.1.5 Total Crainage Cost

```ruby
total_crainage_cost = main_crane_cost + splicing_crane_cost + misc_crane_cost

# Sum of all tender_crane_selections.total_cost for tender
```

#### 7.1.6 Crainage Rate per Tonne (with R20 Rounding)

```ruby
raw_rate = total_crainage_cost / total_tonnage
crainage_rate_per_tonne = (raw_rate / 20.0).ceil * 20

# Example:
# raw_rate = 716,500 / 931.62 = 769.17
# rounded = ceil(769.17 / 20) * 20 = ceil(38.46) * 20 = 39 * 20 = R780
```

**Trigger:** Recalculate whenever any crane selection changes or tonnage changes

#### 7.1.7 Crainage Distribution

**If include_crainage = true (Line Items):**
```ruby
# Update all line_item_rate_build_ups for tender
line_item_rate_build_up.crainage_rate = crainage_rate_per_tonne
line_item_rate_build_up.crainage_included = true
# Recalculate subtotal and rounded_rate
```

**If include_crainage = false (P&G):**
```ruby
# Create/update tender_preliminary_item
tender_preliminary_item.code = 'CRAINAGE'
tender_preliminary_item.description = 'Crainage'
tender_preliminary_item.lump_sum_amount = total_crainage_cost
tender_preliminary_item.rate_per_tonne = crainage_rate_per_tonne

# Ensure line items exclude crainage
line_item_rate_build_up.crainage_included = false
```

### 7.2 Business Rules Summary

| Rule ID | Rule Name | Description | Implementation |
|---------|-----------|-------------|-----------------|
| BR-002 | Crainage Rounding | Crainage rate rounded to nearest R20 | `((rate / 20).ceil * 20)` |
| BR-010 | Wet Rate Components | Wet rate = dry rate + diesel allowance | `dry_rate_per_day + diesel_per_day` |
| BR-012 | Crane Mutual Exclusion | Crainage in line items OR P&G, not both | Toggle: include_crainage |
| BR-018 | Program Duration Ceiling | Program duration rounded up to nearest day | `(roof_area / erection_rate).ceil` |
| BR-019 | Crane Complement Lookup | Lookup based on erection rate bracket | Query crane_complements table |
| BR-020 | RSB vs Rental Selection | Support both ownership types | crane_rate.ownership_type filter |
| BR-021 | Splicing Crane Optional | Only if required flag is true | on_site_mobile_crane_breakdown.splicing_crane_required |
| BR-022 | Miscellaneous Crane Optional | Only if required flag is true | on_site_mobile_crane_breakdown.misc_crane_required |
| BR-023 | Manual Crane Override | User can override auto-lookup selection | Editable tender_crane_selections |
| BR-024 | Rate Snapshot | Crane rates frozen at selection time | Store wet_rate_per_day in tender_crane_selection |

### 7.3 Edge Cases

| Case ID | Scenario | Expected Behavior |
|---------|----------|-------------------|
| EC-001 | Erection rate not in any bracket | Use nearest bracket; display warning |
| EC-002 | Zero total tonnage | Cannot calculate rate per tonne; display error |
| EC-003 | Splicing crane days > program duration | Allowed; display info message |
| EC-004 | User selects non-existent crane size | System rejects; dropdown limited to active sizes |
| EC-005 | Zero roof area | Cannot calculate duration; display error |
| EC-006 | Zero erection rate | Cannot calculate duration; display error (division by zero) |
| EC-007 | Negative crane quantity | Reject; quantities must be ≥ 1 |
| EC-008 | Delete all crane selections | Total crainage = R0; rate per tonne = R0 |

---

## 8. Sprint Task Generation (REQUIRED)

### 8.1 Component Build Order (Leaf First - Independently Testable)

Build and test bottom-up: master data first, then transactional, then UI. Each component is independently testable.

| Order | Model | Database Setup | Controller Actions | Route | Depends On |
|-------|-------|-----------------|-------------------|-------|-----------|
| 1 | CraneRate | Seed 14 rates (7 sizes × 2 ownership) | index, show | /crane_rates | None |
| 2 | CraneComplement | Seed 5 bracket lookups | index, show | /crane_complements | None |
| 3 | TenderSiteConfig | One per tender | show, update | /on_site_mobile_crane_breakdowns/:id | Tender |
| 4 | TenderCraneSelection | Multiple per tender | create, update, destroy | /tender_crane_selections | TenderSiteConfig |
| 5 | TenderInclusionExclusion | One per tender | show, update | /tender_inclusions_exclusions/:id | Tender |
| 6 | TenderPreliminaryItem | P&G line items | index, show, update | /tender_preliminary_items | Tender |
| 7 | CrainageCalculatorService | Calculate totals | N/A (service) | N/A | All above |
| 8 | Crane Breakdown UI (Integration) | Full page | crane_breakdown action on TendersController | /tenders/:id/crane_breakdown | All above |

### 8.2 Per-Component Task Breakdown

#### Component 1: Crane Rate Setup (Master Data)
**Files:**
- `app/models/crane_rate.rb`
- `app/views/crane_rates/index.html.erb`
- `app/views/crane_rates/_crane_rate.html.erb`
- `db/migrate/xxx_create_crane_rates.rb`
- `db/seeds.rb` (crane rates section)

**Tasks:**
1. Create migration for crane_rates table
2. Create CraneRate model with validations
3. Add index view displaying all rates grouped by ownership type
4. Add partial for single crane rate row
5. Seed database with 14 crane rates (7 sizes × 2 ownership types)

**Acceptance Criteria:**
- [ ] 14 crane rates exist in database (10t through 90t, rental and RSB-owned)
- [ ] /crane_rates index displays all rates with size, ownership, dry_rate, diesel, wet_rate
- [ ] wet_rate displays as dry_rate + diesel
- [ ] Can filter by ownership type

---

#### Component 2: Crane Complement Lookup (Master Data)
**Files:**
- `app/models/crane_complement.rb`
- `app/views/crane_complements/index.html.erb`
- `app/views/crane_complements/_crane_complement.html.erb`
- `db/migrate/xxx_create_crane_complements.rb`
- `db/seeds.rb` (crane complements section)

**Tasks:**
1. Create migration for crane_complements table
2. Create CraneComplement model with bracket lookup scope
3. Add index view displaying all brackets
4. Add class method: `CraneComplement.for_erection_rate(rate)`
5. Seed database with 5 bracket lookups

**Acceptance Criteria:**
- [ ] 5 crane complement brackets exist (100-200, 200-250, 250-350, 350-500, 500+)
- [ ] /crane_complements index displays brackets with description and rate
- [ ] `CraneComplement.for_erection_rate(300)` returns "1 × 10t + 2 × 25t" bracket
- [ ] Edge case: rate below minimum returns lowest bracket
- [ ] Edge case: rate above maximum returns highest bracket

---

#### Component 3: On-Site Mobile Crane Breakdown (Site Config)
**Files:**
- `app/models/on_site_mobile_crane_breakdown.rb`
- `app/controllers/on_site_mobile_crane_breakdowns_controller.rb`
- `app/views/on_site_mobile_crane_breakdowns/show.html.erb`
- `app/views/on_site_mobile_crane_breakdowns/_on_site_mobile_crane_breakdown.html.erb`
- `app/javascript/controllers/site-config_controller.js`
- `db/migrate/xxx_create_on_site_mobile_crane_breakdowns.rb`

**Tasks:**
1. Create migration for on_site_mobile_crane_breakdowns table
2. Create OnSiteMobileCraneBreakdown model with:
   - `belongs_to :tender`
   - `before_save :calculate_program_duration`
   - Validations for numeric fields
3. Add to Tender model: `has_one :on_site_mobile_crane_breakdown, dependent: :destroy`
4. Build controller:
   - `show` action: displays partial wrapped in layout
   - `update` action: PATCH endpoint that responds with Turbo Stream
5. Build `show.html.erb`: Header + breadcrumb + partial + link to crane_selections index
6. Build `_on_site_mobile_crane_breakdown.html.erb` partial:
   - Wrapped in `turbo_frame_tag dom_id(@breakdown)` 
   - Each field: `<input>` with pencil icon, inline edit with Checkmark/X buttons
   - Checkmark → async PATCH to controller
7. Build `site-config_controller.js` Stimulus controller:
   - Listen for input changes
   - Calculate program_duration on change (client-side ephemeral calc)
   - Display updated duration in real-time
8. Auto-create site config when tender is created (callback)

**Acceptance Criteria:**
- [ ] Create tender → OnSiteMobileCraneBreakdown auto-creates
- [ ] GET /on_site_mobile_crane_breakdowns/:id displays standalone page
- [ ] Each field shows pencil icon on hover
- [ ] Click field → inline edit mode with Checkmark/X buttons
- [ ] Enter roof area + erection rate → program duration calculates live (no API call)
- [ ] Checkmark → async PATCH, Turbo Stream response, no page reload
- [ ] Dirty indicator shows when changes unsaved
- [ ] Validation: roof area > 0, erection rate > 0, both required
- [ ] Breadcrumb links back to tender show page

---

#### Component 4: Tender Crane Selection (Main + Optional Cranes)
**Files:**
- `app/models/tender_crane_selection.rb`
- `app/controllers/tender_crane_selections_controller.rb`
- `app/views/tender_crane_selections/index.html.erb`
- `app/views/tender_crane_selections/show.html.erb`
- `app/views/tender_crane_selections/_tender_crane_selection.html.erb`
- `app/views/tender_crane_selections/create.turbo_stream.erb`
- `app/views/tender_crane_selections/update.turbo_stream.erb`
- `app/views/tender_crane_selections/destroy.turbo_stream.erb`
- `app/javascript/controllers/crane-selection_controller.js`
- `db/migrate/xxx_create_tender_crane_selections.rb`

**Tasks:**
1. Create migration for tender_crane_selections table
2. Create TenderCraneSelection model with:
   - `belongs_to :tender`
   - `belongs_to :crane_rate`
   - `before_save :calculate_total_cost`
   - `before_save :snapshot_wet_rate`
   - `after_save :recalculate_crainage` (calls CrainageCalculatorService)
   - `after_destroy :recalculate_crainage`
3. Add to Tender: `has_many :tender_crane_selections, dependent: :destroy`
4. Build controller:
   - `index` action: GET /tenders/:tender_id/crane_selections — renders all selections + cost summary
   - `show` action: GET /tender_crane_selections/:id — renders single selection for independent testing
   - `create` action: POST — creates new selection, responds with Turbo Stream that appends to index
   - `update` action: PATCH /tender_crane_selections/:id — updates field, responds with Turbo Stream
   - `destroy` action: DELETE — removes selection, responds with Turbo Stream remove action
5. Build `index.html.erb`: 
   - Breadcrumb + header + link back to site config
   - For each selection: render `_tender_crane_selection.html.erb` partial in Turbo Frame
   - "+ Add Crane Selection" button (POST to create with default values)
   - Cost summary card (read-only, updates via Turbo Stream after each save)
6. Build `show.html.erb`:
   - Breadcrumb: [Tender] > [Crane Selections] > [Selection #2]
   - Render single `_tender_crane_selection.html.erb` partial
   - Allow independent testing/iteration on this component
7. Build `_tender_crane_selection.html.erb` partial:
   - Wrapped in `turbo_frame_tag dom_id(@selection)` 
   - Field: Purpose (read-only label: main/splicing/misc)
   - Field: Size (editable dropdown with pencil icon)
   - Field: Quantity (editable number field)
   - Field: Duration Days (editable number field)
   - Field: Wet Rate (read-only, displays snapshot)
   - Field: Total Cost (read-only, calculated)
   - Buttons: [Edit] (optional, can expand to show all fields), [Delete]
   - On any field change: Checkmark/X inline, PATCH request triggers recalculation
8. Build `crane-selection_controller.js` Stimulus:
   - Listen for quantity/duration/size changes
   - Calculate total_cost client-side (ephemeral, for preview)
   - Display updated cost in real-time
   - On blur/Checkmark → PATCH to server
9. Build Turbo Stream responses:
   - `create.turbo_stream.erb`: Append new selection to list, update cost summary
   - `update.turbo_stream.erb`: Replace updated selection row, update cost summary
   - `destroy.turbo_stream.erb`: Remove selection row, update cost summary

**Acceptance Criteria:**
- [ ] GET /tenders/:tender_id/crane_selections displays all selections
- [ ] GET /tender_crane_selections/:id displays single selection standalone
- [ ] "+ Add Crane Selection" button creates new with default values (size='10t', qty=1, duration=66)
- [ ] New selection appears via Turbo Stream at bottom of list (no page reload)
- [ ] Each field has pencil icon, inline editable with Checkmark/X
- [ ] Edit size dropdown → cost recalculates (Stimulus controller)
- [ ] Edit quantity → cost recalculates
- [ ] Edit duration → cost recalculates
- [ ] Checkmark → PATCH request, Turbo Stream response updates row, cost summary updates
- [ ] Delete button removes selection via Turbo Stream
- [ ] wet_rate_per_day snapshot stored on create and never changes
- [ ] After each PATCH/DELETE, CrainageCalculatorService runs to update total crainage + rate/tonne
- [ ] Cost summary card updates after each change (via Turbo Stream)

---

#### Component 5: Tender Inclusions/Exclusions (Crainage Distribution)
**Files:**
- `app/models/tender_inclusion_exclusion.rb`
- `app/controllers/tender_inclusions_exclusions_controller.rb`
- `app/views/tender_inclusions_exclusions/show.html.erb`
- `app/views/tender_inclusions_exclusions/_tender_inclusion_exclusion.html.erb`
- `db/migrate/xxx_create_tender_inclusions_exclusions.rb`

**Tasks:**
1. Create migration for tender_inclusions_exclusions table
2. Create TenderInclusionExclusion model with:
   - `belongs_to :tender`
   - `after_save :recalculate_crainage_distribution` (calls CrainageCalculatorService)
   - Validates mutual exclusion of include_crainage flags
3. Add to Tender: `has_one :tender_inclusion_exclusion, dependent: :destroy`
4. Build controller:
   - `show` action: GET /tender_inclusions_exclusions/:id — renders standalone page
   - `update` action: PATCH /tender_inclusions_exclusions/:id — updates radio selection, responds Turbo Stream
5. Build `show.html.erb`:
   - Breadcrumb: [Tender] > [Crainage Settings]
   - Header + explanation text
   - Render `_tender_inclusion_exclusion.html.erb` partial
6. Build `_tender_inclusion_exclusion.html.erb` partial:
   - Wrapped in `turbo_frame_tag dom_id(@inclusion_exclusion)`
   - Radio buttons: "Include in Line Item Rates" / "Include in P&G"
   - Explanation text: "Selecting one excludes the other to prevent double-counting"
   - On radio change: async PATCH request (no page reload)
   - Dirty indicator shows unsaved changes
7. Auto-create when tender is created (callback in Tender model)

**Acceptance Criteria:**
- [ ] Create tender → TenderInclusionExclusion auto-creates with default include_crainage=false
- [ ] GET /tender_inclusions_exclusions/:id displays standalone page
- [ ] Radio buttons: one for "Line Items", one for "P&G"
- [ ] Click radio → async PATCH, Turbo Stream response, no page reload
- [ ] After PATCH, CrainageCalculatorService.call(tender) runs to redistribute crainage
- [ ] include_crainage=true → line_item_rate_build_ups.crainage_rate updated for tender
- [ ] include_crainage=false → tender_preliminary_item CRAINAGE created/updated with lump sum
- [ ] Mutual exclusion: only one radio can be selected at a time
- [ ] Dirty indicator updates correctly

---

#### Component 6: Tender Preliminary Items (P&G)
**Files:**
- `app/models/tender_preliminary_item.rb`
- `app/controllers/tender_preliminary_items_controller.rb`
- `app/views/tender_preliminary_items/_tender_preliminary_item.html.erb`
- `db/migrate/xxx_create_tender_preliminary_items.rb`

**Tasks:**
1. Create migration for tender_preliminary_items table
2. Create TenderPreliminaryItem model with validations
3. Add to Tender: `has_many :tender_preliminary_items, dependent: :destroy`
4. Build controller with index, show, update actions
5. Build partial for displaying P&G items
6. Method to find_or_create crainage item

**Acceptance Criteria:**
- [ ] Can view P&G items list for tender
- [ ] CRAINAGE item auto-created when include_crainage = false
- [ ] CRAINAGE item displays lump_sum_amount and rate_per_tonne
- [ ] Item removed/zeroed when include_crainage = true

---

#### Component 7: Crainage Calculator Service
**Files:**
- `app/services/crainage_calculator_service.rb`

**Tasks:**
1. Create service class with `call(tender)` method
2. Implement calculations:
   - Sum all tender_crane_selections.total_cost
   - Divide by tender.total_tonnage
   - Round to nearest R20
3. Implement distribution methods:
   - `distribute_to_line_items(tender, rate)`
   - `distribute_to_pg(tender, total_cost, rate)`
4. Call service from:
   - TenderCraneSelection after_save/after_destroy
   - TenderInclusionExclusion after_save

**Acceptance Criteria:**
- [ ] Service calculates correct total_crainage_cost
- [ ] Service calculates correct crainage_rate_per_tonne with R20 rounding
- [ ] include_crainage = true → line_item_rate_build_ups.crainage_rate updated
- [ ] include_crainage = false → tender_preliminary_item CRAINAGE created/updated
- [ ] Calculations match Excel: 716,500 / 931.62 → R780/t

---

#### Component 8: Routes & Navigation Integration
**Files:**
- `config/routes.rb` (add nested routes)
- Tender show page link additions
- Breadcrumb components

**Tasks:**
1. Add routes:
   ```ruby
   resources :tenders do
     resources :crane_selections, only: [:index]
   end
   resources :on_site_mobile_crane_breakdowns, only: [:show, :update]
   resources :tender_crane_selections, only: [:show, :create, :update, :destroy]
   resources :tender_inclusions_exclusions, only: [:show, :update]
   ```
2. Update Tender show page to link to crane config:
   - Add button/link: "Configure Crane Requirements" → `/on_site_mobile_crane_breakdowns/:id`
   - Or add tab/section that embeds crane config
3. Implement breadcrumb helper for nested views:
   - Tender > Site Config > Crane Selections
   - Tender > Crane Selection #2
   - Tender > Crainage Settings

**Acceptance Criteria:**
- [ ] All routes accessible and working
- [ ] Breadcrumbs navigate correctly between views
- [ ] Links from Tender show page lead to site config
- [ ] Links from site config lead to crane selections
- [ ] Back buttons work at all levels
- [ ] No dead links or routing errors

---

### 8.3 Fields Per Component

| Model | Editable Fields | Calculated Fields | Child Collection |
|-------|-----------------|-------------------|------------------|
| CraneRate | size, ownership_type, dry_rate_per_day, diesel_per_day, is_active | wet_rate (virtual) | tender_crane_selections |
| CraneComplement | area_min_sqm, area_max_sqm, complement_description, default_wet_rate_per_day | — | — |
| TenderSiteConfig | total_roof_area_sqm, erection_rate_sqm_per_day, ownership_type, splicing_*, misc_* | program_duration_days | — |
| TenderCraneSelection | crane_rate_id, purpose, quantity, duration_days | wet_rate_per_day (snapshot), total_cost | — |
| TenderInclusionExclusion | include_crainage, include_cherry_picker | — | — |
| TenderPreliminaryItem | description, is_included | lump_sum_amount, rate_per_tonne (from service) | — |

### 8.4 Stimulus Controllers Needed

| Controller | Purpose | Models Using It | Events |
|------------|---------|-----------------|--------|
| site-config | Calculate program duration, trigger complement lookup | TenderSiteConfig | input, change |
| crane-selection | Calculate individual crane costs, update totals | TenderCraneSelection | input, change |
| crane-summary | Display and update cost summary in real-time | TenderCraneSelection | turbo:before-stream-render |
| dirty-form | Track unsaved changes (existing) | All editable partials | input, change, submit |

### 8.5 Seed Data Requirements

| Model | # Records | Seed Data | Purpose |
|-------|-----------|-----------|---------|
| CraneRate | 14 | 7 sizes (10t, 20t, 25t, 30t, 35t, 50t, 90t) × 2 ownership types | Crane rate lookup |
| CraneComplement | 5 | Brackets: 100-200, 200-250, 250-350, 350-500, 500+ | Complement auto-lookup |
| Tender | 1 | Test tender E3801 with tonnage | Integration testing |
| TenderSiteConfig | 1 | Config for E3801 | Integration testing |
| TenderCraneSelection | 3 | Main cranes + splicing for E3801 | Integration testing |

**Seed Data: Crane Rates**
```ruby
crane_rates_data = [
  { size: '10t', ownership_type: 'rental', dry_rate_per_day: 1500, diesel_per_day: 700 },
  { size: '10t', ownership_type: 'rsb_owned', dry_rate_per_day: 800, diesel_per_day: 700 },
  { size: '20t', ownership_type: 'rental', dry_rate_per_day: 1450, diesel_per_day: 650 },
  { size: '20t', ownership_type: 'rsb_owned', dry_rate_per_day: 750, diesel_per_day: 650 },
  { size: '25t', ownership_type: 'rental', dry_rate_per_day: 1660, diesel_per_day: 750 },
  { size: '25t', ownership_type: 'rsb_owned', dry_rate_per_day: 900, diesel_per_day: 750 },
  { size: '30t', ownership_type: 'rental', dry_rate_per_day: 1800, diesel_per_day: 800 },
  { size: '30t', ownership_type: 'rsb_owned', dry_rate_per_day: 950, diesel_per_day: 800 },
  { size: '35t', ownership_type: 'rental', dry_rate_per_day: 2100, diesel_per_day: 850 },
  { size: '35t', ownership_type: 'rsb_owned', dry_rate_per_day: 1100, diesel_per_day: 850 },
  { size: '50t', ownership_type: 'rental', dry_rate_per_day: 2800, diesel_per_day: 950 },
  { size: '50t', ownership_type: 'rsb_owned', dry_rate_per_day: 1500, diesel_per_day: 950 },
  { size: '90t', ownership_type: 'rental', dry_rate_per_day: 4500, diesel_per_day: 1200 },
  { size: '90t', ownership_type: 'rsb_owned', dry_rate_per_day: 2500, diesel_per_day: 1200 },
]
```

**Seed Data: Crane Complements**
```ruby
crane_complements_data = [
  { area_min_sqm: 0, area_max_sqm: 200, complement_description: '1 × 10t', default_wet_rate_per_day: 2200 },
  { area_min_sqm: 200, area_max_sqm: 250, complement_description: '1 × 10t + 1 × 20t', default_wet_rate_per_day: 4300 },
  { area_min_sqm: 250, area_max_sqm: 350, complement_description: '1 × 10t + 2 × 25t', default_wet_rate_per_day: 7020 },
  { area_min_sqm: 350, area_max_sqm: 500, complement_description: '2 × 25t + 1 × 35t', default_wet_rate_per_day: 9770 },
  { area_min_sqm: 500, area_max_sqm: 999999, complement_description: '2 × 35t + 1 × 50t', default_wet_rate_per_day: 13650 },
]
```

### 8.6 Dependencies

**External Dependencies:**
- Turbo Rails (for Frames & Streams)
- Stimulus JS (for live calculations)
- Existing Tender model and infrastructure

**Internal Dependencies (Build Order):**
1. CraneRate → None
2. CraneComplement → None
3. TenderSiteConfig → Tender
4. TenderCraneSelection → Tender, CraneRate
5. TenderInclusionExclusion → Tender
6. TenderPreliminaryItem → Tender
7. CrainageCalculatorService → All models
8. Site Config UI → All of the above

---

## 9. Open Questions & Assumptions

### 9.1 Open Questions

| Question | Impact | Proposed Answer | Status |
|----------|--------|-----------------|--------|
| Should crane rates be versioned per tender (frozen) or always use latest? | High | Snapshot wet_rate_per_day in tender_crane_selection at selection time | Assumed snapshot |
| Should site config auto-save on change or require explicit save? | Medium | Explicit save button with dirty form indicator | Assumed explicit save |
| Should crane complement lookup happen server-side or client-side? | Low | Server-side via AJAX/Turbo for accuracy | Assumed server-side |
| Can user have multiple ownership types in same tender? | Medium | No - single ownership type per tender | Assumed single |

### 9.2 Assumptions

| Assumption | Rationale |
|-----------|-----------|
| All rates in ZAR | RSB is South Africa based |
| Single ownership type per tender | Simplifies UI; user selects RSB-owned or rental for all cranes |
| Crane rates don't change mid-tender | Rates frozen at selection; changes apply to new tenders |
| Program duration used for all main cranes | Same duration for main crane complement |
| Splicing/misc can have different durations | User enters specific duration for each |
| Max 10 crane selections per tender | Reasonable limit for MVP |

---

## 10. Demo Success Criteria

**By end of this 2-week sprint, demo should show:**

1. ✅ View crane rates master data (14 rates across 7 sizes, 2 ownership types)
2. ✅ View crane complement lookup table (5 brackets)
3. ✅ Open tender E3801, navigate to Site Configuration
4. ✅ Enter: Roof Area = 19,609 m², Erection Rate = 300 m²/day
5. ✅ See program duration auto-calculate: 66 days
6. ✅ See crane complement auto-lookup: "1 × 10t + 2 × 25t @ R7,020/day"
7. ✅ Add splicing crane: 25t for 70 days
8. ✅ View cost summary:
   - Main: R463,320 (66 days × R7,020)
   - Splicing: R168,700 (70 days × R2,410)
   - Total: R632,020
   - Rate per Tonne: R680 (rounded to R20)
9. ✅ Toggle inclusion to P&G → see P&G item created
10. ✅ Toggle inclusion to Line Items → see line item rates updated
11. ✅ Calculations match Excel exactly

---

**Document Status:** Ready for Development
**Depends On:** Existing Tender, TenderLineItem, LineItemRateBuildUp models
**Last Updated:** December 2025