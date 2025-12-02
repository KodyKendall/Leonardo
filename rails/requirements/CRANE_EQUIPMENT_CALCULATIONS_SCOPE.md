# Crane Equipment Calculations & Selection Requirements

**Scope Document Version:** 1.0  
**Extracted From:** REQUIREMENTS.md (v1.01)  
**Extraction Date:** December 2025  
**Status:** Independent Scope Definition

---

## Table of Contents

1. [Overview & Goals](#1-overview--goals)
2. [User Stories](#2-user-stories)
3. [Current Process](#3-current-process)
4. [Future Process](#4-future-process)
5. [Data Model](#5-data-model)
6. [Calculations & Formulas](#6-calculations--formulas)
7. [Business Rules](#7-business-rules)
8. [Edge Cases & Constraints](#8-edge-cases--constraints)
9. [Acceptance Criteria](#9-acceptance-criteria)

---

## 1. Overview & Goals

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

### 1.2 Goals

| Goal | Description |
|------|-------------|
| G-031 | Automate crane complement lookup based on erection rate |
| G-032 | Calculate and track multiple crane selections per tender |
| G-033 | Support both RSB-owned and rental crane options |
| G-034 | Calculate crainage rate per tonne for distribution across items |
| G-035 | Enable manual override of crane selections for project-specific needs |
| G-036 | Support splicing and miscellaneous cranes as optional add-ons |
| G-037 | Integrate crainage into line item rates OR P&G (mutual exclusion) |

### 1.3 Scope Boundaries

**In Scope (MVP):**
- Crane complement auto-lookup based on erection area and rate
- Main crane selection (quantity, duration, cost calculation)
- Splicing crane selection (optional, with size and duration)
- Miscellaneous crane selection (optional, with size and duration)
- Crainage rate calculation (rounded to nearest R20)
- Support for RSB-owned vs rental crane rates
- Manual override of crane selections
- P&G vs line-item inclusion mutual exclusion logic

**Out of Scope (Future):**
- Multi-location crane depot management
- Crane availability tracking/scheduling
- Crane maintenance and downtime tracking
- Fuel indexing on rates
- Crane insurance cost allocation

---

## 2. User Stories

### 2.1 Crane Selection & Configuration

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-030 | As Demi, I want to enter the total roof area and erection rate (m/day) so that crane requirements are calculated | Input fields with automatic crane complement lookup | High |
| US-031 | As Richard, I want to select RSB-owned cranes vs rental cranes so that we can use our own equipment when available | Crane ownership type selection per tender | High |
| US-032 | As Demi, I want to manually adjust the crane complement so that I can account for project-specific requirements | Editable crane selections with recalculation | High |
| US-033 | As Demi, I want to add multiple equipment selections (e.g., 3 booms for 1 month + 1 boom for 2 months) so that I can model complex equipment needs | Multiple equipment line items per type | High |

### 2.2 P&G Integration

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-042 | As Demi, I want crainage and cherry picker costs to either be included in line item rates OR in P&G (not both) so that there's no double-counting | Mutual exclusion logic between line items and P&G | High |

---

## 3. Current Process

### 3.1 Narrative

**Step 1: Data Entry (Demi)**
- Enters total roof area in m² (e.g., 19,609 m)
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
- Example: CEILING(19,609 / 300, 1) = 66 days (rounded up)

**Step 5: Crane Cost Calculation (Manual in Excel)**
- Main crane cost = wet_rate_per_day × program_duration
- Add splicing crane cost if applicable
- Add miscellaneous crane cost if applicable
- Total crane cost = sum of all crane costs

**Step 6: Rate per Tonne**
- System divides total crane cost by total tonnage
- Rounded to nearest R20
- Result fed into either:
  - Line item rates (if include_crainage = true)
  - P&G items (if include_crainage = false)

### 3.2 Current Spreadsheet Structure

| Sheet | Section | Purpose | Key Data |
|-------|---------|---------|----------|
| **Rates Page** | E36:H48 | On-site calculations | Roof area, erection rate, crane complement lookup, calculated rates |
| **DATA SHEET LOCKED** | Crane Complement Table | Lookup by erection area | Min/max m/day brackets → crane combination descriptions |
| **DATA SHEET LOCKED** | Crane Rates Table | Mobile crane rates | Size (10t–90t), ownership type, dry rate/day, diesel/day |
| **ACCESS EQUIPMENT** | Equipment Catalog | Equipment catalog | (Separate from crane; handled differently) |

### 3.3 Current Pain Points

| Pain Point | Description |
|------------|-------------|
| Complex lookup logic | Nested IF or VLOOKUP embedded in Excel; hard to understand |
| Manual crane selection | User must know crane complement table; error-prone |
| No audit trail | Cannot track which cranes were selected or why |
| Difficult overrides | Manual recalculation needed if crane complement changed |
| Mutual exclusion not enforced | User can accidentally double-count crainage in items + P&G |
| Rate synchronization | Crane rate changes require manual update in multiple places |

---

## 4. Future Process

### 4.1 Flows

#### Flow: Configure On-Site Parameters (Step 2.2)

**Step 2.2.1: Enter Site Parameters**
- User navigates to Tender Settings
- Enters: Total Roof Area (m²)
- Enters: Area to be Erected Per Day (m²/day)
- System displays: Program duration (calculated)

**Step 2.2.2: Auto-Lookup Crane Complement**
- System queries crane_complements table for matching bracket
- Lookup by erection_rate_sqm_per_day
- Returns: default crane combination
- Displays: "Recommended: 1 × 10t + 2 × 25t (combined rate R8,300/day)"

**Step 2.2.3: Configure Main Cranes**
- User can override crane selection if needed
- Updates: individual crane sizes, quantities
- System recalculates: total wet rate per day, total crane cost

**Step 2.2.4: Optional Splicing Crane**
- User indicates: Splicing crane required? (Yes/No)
- If yes:
  - Selects: crane size (dropdown from crane_rates)
  - Enters: duration in days (or system auto-calculates from program duration)
  - System calculates: splicing crane cost

**Step 2.2.5: Optional Miscellaneous Crane**
- User indicates: Miscellaneous crane required? (Yes/No)
- If yes:
  - Selects: crane size
  - Enters: duration in days
  - System calculates: miscellaneous crane cost

**Step 2.2.6: Manual Adjustment**
- User can override entire crane selection
- System recalculates total crainage cost
- System recalculates crainage rate per tonne

#### Flow: Integrate Crainage into Tender

**Step 3.2: Line Item Configuration**
- User reviews line item rate build-up
- Crainage rate automatically included (if include_crainage toggle = true at tender level)
- Or excluded (if include_crainage = false, then included in P&G)

**Step 4.1: P&G Summary**
- If include_crainage = false (in tender_inclusions_exclusions)
- System adds P&G line item:
  - Description: "Crainage"
  - Lump sum: total_crane_cost
  - Rate per tonne: total_crane_cost / total_tonnage

### 4.2 Roles & Responsibilities

| Step | Role | Action |
|------|------|--------|
| Enter site parameters | QS (Demi) | Enters roof area, erection rate |
| Review crane complement | QS (Demi) | Reviews auto-lookup, approves or overrides |
| Select crane ownership | Admin (Richard) | May indicate RSB-owned vs rental preference |
| Configure splicing/misc cranes | QS (Demi) | Adds optional cranes with durations |
| Set P&G vs line-item crainage | QS (Demi) | Toggles include_crainage at tender level |
| Review final crainage rate | QS (Demi) | Verifies rate per tonne calculation |

---

## 5. Data Model

### 5.1 Master Data Tables

#### 5.1.1 crane_rates

Mobile crane rental rates.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| id | integer | Unique identifier | 1 |
| size | string | Crane capacity | "25t" |
| ownership_type | string | RSB-owned or rental | "rental" |
| dry_rate_per_day | decimal | 9-hour dry rate (no operator, no diesel) | 1,660.00 |
| diesel_per_day | decimal | Daily diesel allowance | 750.00 |
| is_active | boolean | Whether rate is active | true |

**Crane Sizes:**
- Current: 10t, 20t, 25t, 30t, 35t, 50t, 90t
- Future: 110t, 130t, 160t, 200t, 250t

**Ownership Types:**
- "rsb_owned" – RSB Contracts owns the crane
- "rental" – Crane rented from external supplier

**Rate Calculation:**
- Wet rate (with operator & diesel) = dry_rate_per_day + diesel_per_day
- Example for 25t rental: 1,660 + 750 = R2,410/day

#### 5.1.2 crane_complements

Lookup table for default crane combinations based on erection area.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| id | integer | Unique identifier | 1 |
| area_min_sqm | decimal | Minimum m²/day | 250 |
| area_max_sqm | decimal | Maximum m²/day | 350 |
| complement_description | string | Crane combination text | "1 × 10t + 2 × 25t" |
| default_wet_rate_per_day | decimal | Combined daily rate | 8,300.00 |

**Bracket Logic:**
- User enters erection_rate_sqm_per_day (e.g., 300)
- System finds row where: area_min_sqm ≤ 300 ≤ area_max_sqm
- Returns: complement_description and default_wet_rate_per_day

**Example Lookup Table:**

| area_min_sqm | area_max_sqm | complement_description | default_wet_rate_per_day |
|--------------|--------------|------------------------|--------------------------|
| 100 | 200 | 1 × 10t | 2,500.00 |
| 200 | 250 | 1 × 10t + 1 × 20t | 4,800.00 |
| 250 | 350 | 1 × 10t + 2 × 25t | 8,300.00 |
| 350 | 500 | 2 × 25t + 1 × 35t | 11,200.00 |
| 500+ | 999999 | 2 × 35t + 1 × 50t | 15,000.00 |

### 5.2 Transactional Data Tables

#### 5.2.1 tender_site_configs

On-site parameters for crane and equipment calculations.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| id | integer | Unique identifier | 1 |
| tender_id | integer (FK) | Reference to tender | 1 |
| total_roof_area_sqm | decimal | Total roof area | 19,609.00 |
| erection_rate_sqm_per_day | decimal | Area erected per day | 300.00 |
| splicing_crane_required | boolean | Extra crane for splicing? | true |
| splicing_crane_size | string | Crane size for splicing | "25t" |
| splicing_crane_days | integer | Duration in days | 70 |
| misc_crane_required | boolean | Miscellaneous crane needed? | false |
| misc_crane_size | string | Crane size | null |
| misc_crane_days | integer | Duration | 0 |
| program_duration_days | integer | Calculated program length | 100 |

**Calculations:**
- program_duration_days = CEILING(total_roof_area_sqm / erection_rate_sqm_per_day, 1)

#### 5.2.2 tender_crane_selections

Crane selections for the tender (editable).

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| id | integer | Unique identifier | 1 |
| tender_id | integer (FK) | Reference to tender | 1 |
| crane_rate_id | integer (FK) | Reference to crane rate | 3 |
| quantity | integer | Number of cranes | 2 |
| purpose | enum | Usage type | "main" |
| duration_days | integer | Duration in days | 100 |
| total_cost | decimal | Calculated cost | 490,000.00 |

**Purpose Values:**
- "main" – main erection cranes (from crane_complements lookup)
- "splicing" – splicing crane (optional)
- "miscellaneous" – miscellaneous crane (optional)

**Cost Calculation:**
```
total_cost = (crane_rate.dry_rate_per_day + crane_rate.diesel_per_day) 
           × quantity 
           × duration_days
```

Example:
```
total_cost = (1,660 + 750) × 2 × 100
           = 2,410 × 2 × 100
           = R482,000
```

#### 5.2.3 tender_inclusions_exclusions (Crane-related fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| id | integer | Unique identifier | 1 |
| tender_id | integer (FK) | Reference to tender | 1 |
| include_crainage | boolean | Include crainage in line item rates? | false |
| include_cherry_picker | boolean | Include cherry picker in line item rates? | false |

**Mutual Exclusion Rule:**
- If include_crainage = true: crainage included in line item rates; NOT in P&G
- If include_crainage = false: crainage NOT in line item rates; included in P&G

---

## 6. Calculations & Formulas

### 6.1 Program Duration Calculation

```
program_duration_days = CEILING(total_roof_area_sqm / erection_rate_sqm_per_day, 1)

Example:
= CEILING(19,609 / 300, 1)
= CEILING(65.36, 1)
= 66 days
```

**Purpose:** Determines how many days the main crane(s) are needed on site.

### 6.2 Crane Complement Auto-Lookup

```
LOOKUP Logic:
1. Query crane_complements table
2. Find row where: area_min_sqm ≤ erection_rate_sqm_per_day ≤ area_max_sqm
3. Return: complement_description, default_wet_rate_per_day

Example:
Input: erection_rate_sqm_per_day = 300
Lookup: area_min_sqm=250, area_max_sqm=350
Return: "1 × 10t + 2 × 25t", dry_rate = R8,300/day
```

**If No Exact Match:**
- Use nearest bracket (round up if between brackets)
- Flag warning to user: "Using 350 m²/day bracket; may need adjustment"

### 6.3 Main Crane Cost Calculation

```
main_crane_cost = (crane_rate.dry_rate_per_day + crane_rate.diesel_per_day) 
                × complement_quantity 
                × program_duration_days

Example with 1 × 10t + 2 × 25t over 100 days:

10t crane (quantity=1):
  dry_rate = 1,500/day
  diesel = 700/day
  wet_rate = 2,200/day
  cost = 2,200 × 1 × 100 = R220,000

25t crane (quantity=2):
  dry_rate = 1,660/day
  diesel = 750/day
  wet_rate = 2,410/day
  cost = 2,410 × 2 × 100 = R482,000

Total main crane cost = 220,000 + 482,000 = R702,000
```

### 6.4 Splicing Crane Cost (If Required)

```
splicing_cost = (crane_rate.dry_rate_per_day + crane_rate.diesel_per_day) 
              × 1 
              × splicing_crane_days

Example with 25t for 70 days:
= (1,660 + 750) × 1 × 70
= 2,410 × 70
= R168,700
```

### 6.5 Miscellaneous Crane Cost (If Required)

```
misc_crane_cost = (crane_rate.dry_rate_per_day + crane_rate.diesel_per_day) 
                × 1 
                × misc_crane_days

Example with 20t for 50 days:
= (1,450 + 650) × 1 × 50
= 2,100 × 50
= R105,000
```

### 6.6 Total Crainage Cost

```
total_crainage_cost = main_crane_cost + splicing_cost + misc_cost

Example:
= 702,000 + 168,700 + 105,000
= R975,700
```

### 6.7 Crainage Rate per Tonne

```
crainage_rate_per_tonne = total_crainage_cost / total_tonnage

Example:
= 975,700 / 931.62
= R1,047.25

Rounded to nearest R20:
= CEILING(1,047.25, 20)
= R1,060 per tonne
```

**Rounding Rule (BR-002):** Always round crainage to nearest R20 (upward).

### 6.8 Crainage Line Item Inclusion (in Line Item Rates)

If include_crainage = true:

```
line_rate_per_tonne = material + fabrication + overheads + ... + crainage_rate_per_tonne

crainage_included = crainage_rate_per_tonne
```

### 6.9 Crainage P&G Inclusion (Not in Line Items)

If include_crainage = false:

```
-- Crainage appears as P&G item instead
tender_preliminary_item:
  description: "Crainage"
  lump_sum_amount: total_crainage_cost
  rate_per_tonne: crainage_rate_per_tonne
  is_included: true

p&g_line_amount = crainage_rate_per_tonne × total_tonnage
                = 1,060 × 931.62
                = R987,918
```

---

## 7. Business Rules

### 7.1 Crane Selection Rules

| Rule ID | Rule Name | Description | Formula/Logic |
|---------|-----------|-------------|---------------|
| BR-002 | Crainage Rounding | Crainage rate rounded to nearest R20 | `CEILING(rate, 20)` |
| BR-010 | Crane Rate Components | Wet rate includes dry rate + diesel allowance | `dry_rate_per_day + diesel_per_day` |
| BR-012 | Crane Mutual Exclusion | Crainage included in line items OR P&G, not both | Toggle: include_crainage |
| BR-018 | Program Duration Ceiling | Program duration rounded up to nearest day | `CEILING(roof_area / erection_rate, 1)` |
| BR-019 | Crane Complement Lookup | Lookup based on erection rate bracket | Query crane_complements table |
| BR-020 | RSB vs Rental Selection | Support both RSB-owned and rental crane options | crane_rate.ownership_type |
| BR-021 | Splicing Crane Optional | Splicing crane added only if required | tender_site_configs.splicing_crane_required |
| BR-022 | Miscellaneous Crane Optional | Miscellaneous crane added only if required | tender_site_configs.misc_crane_required |
| BR-023 | Manual Crane Override | User can override auto-lookup crane selection | Editable tender_crane_selections |

### 7.2 Calculation Precedence

1. **Program Duration** – Calculated from roof area and erection rate
2. **Main Crane Complement** – Looked up from crane_complements table
3. **Main Crane Cost** – Calculated from complement, rates, and duration
4. **Optional Cranes** – Splicing and miscellaneous added if required
5. **Total Crainage Cost** – Sum of all crane costs
6. **Crainage Rate per Tonne** – Total cost divided by tonnage, rounded to R20
7. **Inclusion Decision** – Applied to either line items or P&G (not both)

---

## 8. Edge Cases & Constraints

### 8.1 Edge Cases

| Case ID | Scenario | Expected Behavior |
|---------|----------|-------------------|
| EC-001 | Erection rate not in any bracket | Use nearest bracket; warn user |
| EC-002 | Zero total tonnage | Cannot calculate rate per tonne; flag error |
| EC-003 | Splicing/misc crane days > program duration | Allowed (different durations OK); warn if unusual |
| EC-004 | User selects non-existent crane size | System rejects; dropdown limited to active sizes |
| EC-005 | Crainage in both line items and P&G | System enforces mutual exclusion; recalculates to fix |
| EC-006 | Crane rate changes after tender created | Tender uses rates at time of creation; snapshots maintained |
| EC-007 | Negative crane quantity | Reject; quantities must be ≥ 1 |
| EC-008 | Zero program duration | Reject; erection rate must be > 0 |

### 8.2 Constraints

| Constraint | Description | Example |
|-----------|-------------|---------|
| Minimum roof area | Must be > 0 m² | 1 m² OK, 0 rejected |
| Minimum erection rate | Must be > 0 m²/day | 1 m²/day OK, 0 rejected |
| Crane quantity | Must be ≥ 1 per selection | 1–9 typical |
| Duration | Must be ≥ 1 day | 1–365 days typical |
| Crane size | Must be from crane_rates table | 10t, 20t, 25t, 30t, 35t, 50t, 90t |
| Rate rounding | Crainage rounds to nearest R20 | R1,040–1,059 → R1,060 |
| Ownership type | Must be "rsb_owned" or "rental" | Dropdown only |

---

## 9. Acceptance Criteria

### 9.1 Functional Acceptance Criteria

#### A-C 1: Crane Complement Auto-Lookup
- **Given**: User enters erection_rate_sqm_per_day = 300
- **When**: System queries crane_complements table
- **Then**: System returns "1 × 10t + 2 × 25t" and default_wet_rate = R8,300/day
- **And**: UI displays recommended crane combination

#### A-C 2: Program Duration Calculation
- **Given**: roof_area = 19,609 m², erection_rate = 300 m²/day
- **When**: System calculates program duration
- **Then**: Result = CEILING(19,609/300, 1) = 66 days
- **And**: Result stored in tender_site_configs.program_duration_days

#### A-C 3: Main Crane Cost Calculation
- **Given**: 1 × 10t @ R2,200/day + 2 × 25t @ R2,410/day for 100 days
- **When**: System calculates main_crane_cost
- **Then**: Cost = (2,200 × 1 × 100) + (2,410 × 2 × 100) = R702,000
- **And**: Cost stored in tender_crane_selections.total_cost

#### A-C 4: Splicing Crane Optional
- **Given**: splicing_crane_required = true, size = 25t, days = 70
- **When**: System calculates splicing_crane_cost
- **Then**: Cost = 2,410 × 1 × 70 = R168,700
- **And**: Splicing crane selection created with purpose = "splicing"

#### A-C 5: Miscellaneous Crane Optional
- **Given**: misc_crane_required = false
- **When**: User navigates to site config form
- **Then**: Miscellaneous crane section hidden or disabled
- **And**: No misc_crane_selection created

#### A-C 6: Total Crainage Cost
- **Given**: Main = R702,000, Splicing = R168,700, Misc = R0
- **When**: System sums all crane costs
- **Then**: Total = R870,700

#### A-C 7: Crainage Rate per Tonne (with Rounding)
- **Given**: Total crainage cost = R870,700, total tonnage = 931.62 t
- **When**: System calculates and rounds crainage rate per tonne
- **Then**: Rate = CEILING(870,700 / 931.62, 20) = CEILING(934.37, 20) = R940/tonne
- **And**: Value stored in line_item_rate_build_ups.crainage_rate

#### A-C 8: Mutual Exclusion - Line Items
- **Given**: include_crainage = true
- **When**: System builds line item rates
- **Then**: Crainage rate automatically included in line_item_rate_build_ups
- **And**: Crainage NOT added to P&G items

#### A-C 9: Mutual Exclusion - P&G
- **Given**: include_crainage = false
- **When**: System builds P&G items
- **Then**: Crainage added as P&G item with:
  - description = "Crainage"
  - lump_sum_amount = total crainage cost
  - rate_per_tonne = crainage rate per tonne
- **And**: Crainage NOT included in line_item_rate_build_ups

#### A-C 10: Manual Crane Override
- **Given**: Auto-lookup suggests "1 × 10t + 2 × 25t"
- **When**: User clicks "Edit Crane Selection"
- **Then**: User can modify quantities, sizes, durations
- **And**: System recalculates total crainage cost automatically
- **And**: Changes reflected in line items or P&G based on toggle

#### A-C 11: RSB-Owned vs Rental Selection
- **Given**: User creates tender
- **When**: User navigates to site config
- **Then**: User can toggle between:
  - RSB-owned cranes (lower rates)
  - Rental cranes (higher rates)
- **And**: Rates look up from crane_rates where ownership_type matches selection
- **And**: Total cost recalculated based on selected ownership type

#### A-C 12: Rate Persistence
- **Given**: Tender created on 2025-12-01 with crane rates as of that date
- **When**: Crane rates updated on 2025-12-15
- **Then**: Existing tender still uses 2025-12-01 rates
- **And**: New tenders use 2025-12-15 rates
- **And**: Audit log shows rate changes

### 9.2 Data Integrity Acceptance Criteria

#### A-C 13: Crane Quantity Validation
- **Given**: User enters crane quantity = 0
- **When**: Form submitted
- **Then**: System rejects with error: "Quantity must be ≥ 1"

#### A-C 14: Duration Validation
- **Given**: User enters splicing crane duration = -5 days
- **When**: Form submitted
- **Then**: System rejects with error: "Duration must be ≥ 1"

#### A-C 15: Roof Area Validation
- **Given**: User enters total_roof_area_sqm = 0
- **When**: Form submitted
- **Then**: System rejects with error: "Roof area must be > 0"

#### A-C 16: Erection Rate Validation
- **Given**: User enters erection_rate_sqm_per_day = 0
- **When**: Form submitted
- **Then**: System rejects with error: "Erection rate must be > 0"

#### A-C 17: Bracket Fallback
- **Given**: Erection rate = 50 (below minimum bracket of 100)
- **When**: System performs lookup
- **Then**: System uses 100–200 bracket
- **And**: Warning displayed: "Erection rate outside standard brackets; using 100–200 bracket"

### 9.3 UI/UX Acceptance Criteria

#### A-C 18: Crane Complement Display
- **Given**: User on site config page
- **When**: Page loads after erection rate entered
- **Then**: UI displays:
  - "Recommended Crane Complement: 1 × 10t + 2 × 25t"
  - "Combined Daily Rate: R8,300 (wet)"
  - "Estimated Program Duration: 66 days"
  - "Edit" button to override

#### A-C 19: Optional Crane Toggles
- **Given**: User on site config page
- **When**: Page loads
- **Then**: UI displays:
  - Checkbox: "Splicing crane required?"
  - If checked: dropdown for size + input for days
  - Checkbox: "Miscellaneous crane required?"
  - If checked: dropdown for size + input for days

#### A-C 20: Cost Summary Display
- **Given**: All crane selections configured
- **When**: Site config form rendered
- **Then**: UI displays summary:
  - Main crane cost: R702,000
  - Splicing crane cost: R168,700 (if applicable)
  - Miscellaneous crane cost: R0
  - **Total crainage cost: R870,700**
  - **Crainage rate per tonne: R940**

#### A-C 21: Mutual Exclusion Toggle
- **Given**: User on tender settings page
- **When**: Page loads
- **Then**: UI displays:
  - Radio or toggle: "Where should crainage be charged?"
  - Option 1: "Include in line item rates"
  - Option 2: "Include in P&G (Preliminaries & General)"
  - Help text: "Selecting here prevents double-counting"

### 9.4 Reporting & Audit Acceptance Criteria

#### A-C 22: Crainage Calculation Audit Trail
- **Given**: Tender with crainage calculations
- **When**: User views tender audit log
- **Then**: Log includes:
  - "Crane complement calculated: 1 × 10t + 2 × 25t"
  - "Program duration: 66 days"
  - "Total crainage cost: R870,700"
  - "Crainage rate per tonne: R940"
  - "Timestamp: 2025-12-01 14:30:00"
  - "User: demi@rsb.co.za"

#### A-C 23: Rate History Snapshot
- **Given**: Tender submitted
- **When**: System creates rate snapshot
- **Then**: Snapshot includes:
  - Crane rates used (10t, 25t, etc. with ownership type)
  - Crane rates as of submission date
  - Crane complement table as of submission date
  - Total crainage cost calculated
  - Crainage rate per tonne calculated

---

## Implementation Notes

### Phase 1 (MVP)

- Implement basic crane complement lookup
- Support main, splicing, and miscellaneous crane selections
- Calculate crainage rate per tonne with R20 rounding
- Enforce mutual exclusion between line items and P&G
- Manual override capability for crane selections

### Phase 2 (Future)

- Crane availability tracking and scheduling
- Multiple depot/location support
- Fuel indexing and cost adjustments
- Crane maintenance cost allocation
- Advanced analytics on crane utilization

---

## References

- **Source Document**: REQUIREMENTS.md (v1.01), Section 6.1.4 (Crainage Calculation)
- **Related**: ACCESS_EQUIPMENT_SCOPE.md (separate from cranes; handled differently)
- **Related**: LINE_ITEM_RATE_BUILDUP_SCOPE.md (how crainage integrates into line rates)
- **Related**: P&G_SCOPE.md (how crainage integrates into P&G)
