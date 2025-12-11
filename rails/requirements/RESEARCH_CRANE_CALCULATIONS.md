# Research: Missing Crane Calculations Feature

**Date:** December 2025  
**Observer:** Demi (Quantity Surveyor)  
**Route:** `/on_site_mobile_crane_breakdowns/26/builder`  
**Issue:** No total crane calculations appear or are calculated

---

## 1. OBSERVATION SUMMARY

### Current Behavior
- User navigates to the Mobile Crane Breakdown Builder page
- Section 3 "Selected Cranes" displays: **"No tender crane selections found."**
- There is an "Add Row" button to create selections, but no calculations are displayed
- No total crane cost, daily rates, or cost per tonne metrics visible

### Desired Behavior
- View **total crane calculations** after selections have been made
- See **total rates per day** across all selected cranes
- See **total cost of cranes** for the tender
- Have these values **saved in database** for later retrieval

---

## 2. DATABASE ARCHITECTURE

### Tables Involved in Crane Calculations

#### `on_site_mobile_crane_breakdowns`
**Purpose:** Stores on-site parameters needed to calculate crane requirements

| Column | Type | Current Value | Notes |
|--------|------|---------------|-------|
| id | bigint | PK | |
| tender_id | bigint | FK | Unique constraint: one per tender |
| total_roof_area_sqm | decimal | 19609.00 | Area to be erected |
| erection_rate_sqm_per_day | decimal | 300.00 | Area erected per day |
| program_duration_days | integer | Calculated | **CALCULATED:** ceil(roof_area / erection_rate) |
| ownership_type | string | "rental" | "rental" or "rsb_owned" |
| splicing_crane_required | boolean | true | Extra crane for splicing? |
| splicing_crane_size | string | "25t" | Size if required |
| splicing_crane_days | integer | 70 | Duration of splicing crane |
| misc_crane_required | boolean | false | Miscellaneous crane? |
| misc_crane_size | string | null | Size if required |
| misc_crane_days | integer | 0 | Duration if required |

**Key Calculation:** `program_duration_days = CEIL(total_roof_area_sqm / erection_rate_sqm_per_day)`

---

#### `tender_crane_selections`
**Purpose:** Stores user's selected cranes for a tender (editable list)

| Column | Type | Current State | Notes |
|--------|------|---------------|-------|
| id | bigint | PK | |
| tender_id | bigint | FK | Links to tender |
| crane_rate_id | bigint | FK | Links to crane_rates |
| purpose | enum | "main", "splicing" | Type of crane use |
| quantity | integer | 1 | Number of this crane type |
| duration_days | integer | 0 | **NO VALUE SET** |
| wet_rate_per_day | decimal | 0.0 | **NO VALUE SET** |
| total_cost | decimal | 0.0 | **ALWAYS ZERO - NOT CALCULATED** |
| sort_order | integer | 0 | Display order |

**Current Issue:** 
- `duration_days` defaults to 0 and is NOT auto-populated
- `wet_rate_per_day` is stored but NOT auto-calculated from crane_rates
- `total_cost` is stored but NEVER calculated (= quantity × duration_days × wet_rate_per_day)

---

#### `crane_rates`
**Purpose:** Master rates for crane rentals/ownership

| Column | Type | Example | Notes |
|--------|------|---------|-------|
| id | bigint | PK | |
| size | string | "25t" | Crane capacity |
| ownership_type | string | "rental" | "rental" or "rsb_owned" |
| dry_rate_per_day | decimal | 1660.00 | 9-hour dry rate |
| diesel_per_day | decimal | 750.00 | Daily diesel allowance |
| is_active | boolean | true | Current rates only |
| effective_from | date | 2024-01-01 | Version tracking |

**Wet Rate Calculation:** `wet_rate = dry_rate + diesel_rate`

---

#### `crane_complements`
**Purpose:** Lookup table for default crane combinations by area

| Column | Type | Example | Notes |
|--------|------|---------|-------|
| id | bigint | PK | |
| area_min_sqm | decimal | 250.00 | Minimum erection area |
| area_max_sqm | decimal | 350.00 | Maximum erection area |
| crane_recommendation | string | "1 x 10t + 2 x 25t" | Suggested crane complement |
| default_wet_rate_per_day | decimal | 8300.00 | Combined daily rate |

**Purpose in System:** Reference data for intelligent defaults when user enters erection_rate_sqm_per_day

---

## 3. ARCHITECTURAL GAPS IDENTIFIED

### Gap 1: No Automatic Duration Population
**Status:** ❌ **MISSING**

When a user creates a `TenderCraneSelection`, the `duration_days` field is NOT automatically set.

**Should Be:**
- Main cranes: duration_days = `on_site_mobile_crane_breakdown.program_duration_days`
- Splicing crane: duration_days = `on_site_mobile_crane_breakdown.splicing_crane_days`
- Misc crane: duration_days = `on_site_mobile_crane_breakdown.misc_crane_days`

**Current Code:** `TenderCraneSelectionsController#create` sets `duration_days: 0`

---

### Gap 2: No Wet Rate Population from Crane Rates
**Status:** ❌ **MISSING**

When a user selects a crane (sets `crane_rate_id`), the `wet_rate_per_day` is NOT automatically pulled from the associated `CraneRate`.

**Should Be:**
```
wet_rate_per_day = crane_rate.dry_rate_per_day + crane_rate.diesel_per_day
```

**Current Code:** `wet_rate_per_day` starts at 0.0 and is never updated

---

### Gap 3: No Total Cost Calculation
**Status:** ❌ **MISSING**

The `total_cost` field is stored in the database but NEVER calculated.

**Should Be:**
```
total_cost = quantity × duration_days × wet_rate_per_day
```

**Current Code:** Hardcoded to 0.0, no calculation trigger

---

### Gap 4: No Total Crane Cost Summary
**Status:** ❌ **MISSING**

There is no aggregated calculation showing:
- **Sum of all tender_crane_selections.total_cost** (Total tender crane cost)
- **Sum of all wet_rate_per_day values** (Total daily crane cost)
- **Crane cost per tonne** (Total crane cost ÷ tender.total_tonnage)

**Required Display:** 
Per REQUIREMENTS.md section 6.1.4, Demi needs to see:
- Total crainage cost
- Crainage rate per tonne (for line item inclusion)
- Whether crainage is included in line items OR P&G (not both)

---

### Gap 5: No UI Display of Calculations
**Status:** ❌ **MISSING**

The builder page shows an empty list with "No tender crane selections found" — even if selections existed, there would be no summary section displaying:
- Total daily crane cost
- Total crane cost for duration
- Rate per tonne
- These calculations saved in database

**View File:** `app/views/on_site_mobile_crane_breakdowns/builder.html.erb` (line 108-112)
**Partial:** `app/views/tender_crane_selections/_index.html.erb` — shows list but no totals

---

## 4. REQUIRED CALCULATIONS PER REQUIREMENTS.md

### Calculation Formula (Section 6.1.4 - Crainage Calculation)

```
-- Step 1: Lookup crane complement based on erection rate
crane_complement = LOOKUP(erection_rate_sqm_day, crane_complement_lookup)
wet_rate_per_day = 8,300 (for 250-350 m/day, from complement)

-- Step 2: Calculate program duration
program_duration = CEILING(total_roof_area / erection_rate_sqm_day, 1)
= CEILING(19,609 / 300, 1)
= 66 days (rounded up)

-- Step 3: Calculate main crane cost
main_crane_cost = wet_rate_per_day × program_duration
= 8,300 × 100 = R830,000

-- Step 4: Add splicing crane if required
splicing_crane_rate = LOOKUP(splicing_crane_size, crane_rates)
= 2,450 (for 25t)
splicing_cost = splicing_crane_rate × splicing_crane_days
= 2,450 × 70 = R171,500

-- Step 5: Total crane cost
total_crane_cost = main_crane_cost + splicing_cost + misc_cost
= 830,000 + 171,500 + 0 = R1,001,500

-- Step 6: Rate per tonne
crainage_rate_per_tonne = CEILING(total_crane_cost / total_tonnage, 20)
= CEILING(1,001,500 / 931.62, 20)
= CEILING(1,075.02, 20)
= R1,080 per tonne
```

---

## 5. MODELS & ASSOCIATIONS

### Current State

**OnSiteMobileCraneBreakdown Model:**
```ruby
class OnSiteMobileCraneBreakdown < ApplicationRecord
  belongs_to :tender
  has_many :tender_crane_selections, through: :tender
  
  before_save :calculate_program_duration  # ✅ Calculates duration correctly
end
```

**TenderCraneSelection Model:**
```ruby
class TenderCraneSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :crane_rate
  
  # ❌ NO VALIDATIONS
  # ❌ NO CALCULATIONS
  # ❌ NO ASSOCIATIONS TO on_site_mobile_crane_breakdown
end
```

**Issues:**
1. `TenderCraneSelection` belongs_to `tender`, but should also reference `on_site_mobile_crane_breakdown` for easier data access
2. No callbacks or validations to trigger calculations
3. No scopes for "main", "splicing", "misc" cranes

---

## 6. UI COMPONENT ANALYSIS

### Current Turbo Frame Structure

**Builder Page** (`app/views/on_site_mobile_crane_breakdowns/builder.html.erb`):
- Line 108-112: Turbo frame renders `_index` partial
- Shows crane selections list
- **MISSING:** Summary totals section

**Index Partial** (`app/views/tender_crane_selections/_index.html.erb`):
- Lines 6-28: Shows list of selections (currently empty)
- Lines 31-36: "Add Row" button
- **MISSING:** Total calculations display below the list

**Individual Crane View** (`app/views/tender_crane_selections/_tender_crane_selection.html.erb`):
- Lines 42-64: Fields are readonly (cannot edit inline)
- All fields default to 0 or empty
- **MISSING:** Auto-calculation triggered on change

---

## 7. CONTROLLER LOGIC GAPS

**TenderCraneSelectionsController#create** (lines 28-59):
```ruby
# Sets defaults:
- crane_rate_id: first active rate
- purpose: "main"
- quantity: 1
- duration_days: 0              # ❌ Should be from on_site_mobile_crane_breakdown
- wet_rate_per_day: 0            # ❌ Should be from crane_rate
- total_cost: 0                  # ❌ Should be calculated
```

**TenderCraneSelectionsController#update** (lines 63-74):
```ruby
# Just saves whatever is passed
# ❌ No calculation of total_cost
# ❌ No validation of duration_days
# ❌ No trigger to update line_item_rate_build_ups
```

---

## 8. MISSING FUNCTIONALITY CHECKLIST

### During Create
- [ ] Auto-populate `duration_days` from `on_site_mobile_crane_breakdown`
- [ ] Auto-populate `wet_rate_per_day` from `crane_rate.dry_rate + crane_rate.diesel`
- [ ] Calculate `total_cost = quantity × duration_days × wet_rate_per_day`
- [ ] Save `total_cost` to database

### During Update
- [ ] Recalculate `total_cost` if quantity or duration_days changes
- [ ] Re-validate duration_days against breakdown parameters
- [ ] Update line_item_rate_build_ups if crainage_included flag is set

### In Views
- [ ] Display `total_cost` on individual crane selections
- [ ] Display summary totals:
  - Total daily rate (sum of wet_rate_per_day for all cranes)
  - Total crane cost for duration (sum of total_cost)
  - Crane cost per tonne (total ÷ tender.total_tonnage)
- [ ] Add section for "Crane Calculation Summary"

### In Database
- [ ] Ensure `total_cost` is persisted correctly
- [ ] Create method to query total crane cost by purpose (main, splicing, misc)
- [ ] Create method to calculate rate per tonne

---

## 9. RELATIONSHIP MAP

```
Tender (1)
  ├── OnSiteMobileCraneBreakdown (1:1)
  │   ├── total_roof_area_sqm
  │   ├── erection_rate_sqm_per_day
  │   ├── program_duration_days ← CALCULATED
  │   ├── splicing_crane_required
  │   ├── splicing_crane_days
  │   ├── misc_crane_required
  │   └── misc_crane_days
  │
  └── TenderCraneSelections (1:many)
      ├── crane_rate (n:1) → CraneRate
      │   ├── size
      │   ├── dry_rate_per_day
      │   ├── diesel_per_day
      │   └── is_active
      ├── purpose ← Enum: main, splicing, misc
      ├── quantity
      ├── duration_days ← **NEEDS AUTO-POPULATION**
      ├── wet_rate_per_day ← **NEEDS AUTO-CALCULATION**
      └── total_cost ← **NEEDS CALCULATION: qty × days × rate**
```

---

## 10. KEY FINDINGS & RECOMMENDATIONS

### Engineering Tasks Required

1. **Model Enhancements (TenderCraneSelection)**
   - Add callback: `before_save :calculate_total_cost`
   - Add callback: `before_save :populate_duration_from_breakdown`
   - Add method: `calculate_wet_rate_per_day`
   - Add method: `total_cost_calculation`
   - Add association: `belongs_to :on_site_mobile_crane_breakdown`
   - Add scopes: `main_cranes`, `splicing_cranes`, `misc_cranes`

2. **Controller Enhancements (TenderCraneSelectionsController)**
   - Populate `duration_days` from breakdown in `#create`
   - Populate `wet_rate_per_day` from crane_rate in `#create`
   - Trigger calculation in `#create` and `#update`
   - Add response to update line_item_rate_build_ups

3. **View Enhancements (tender_crane_selections/**)**
   - Add summary section to `_index.html.erb` showing totals
   - Display calculated `total_cost` in `_tender_crane_selection.html.erb`
   - Add section to builder page for "Crane Cost Summary"
   - Show rate per tonne calculation

4. **Database Queries Needed**
   - `OnSiteMobileCraneBreakdown#total_crane_cost` → sum of all selections
   - `OnSiteMobileCraneBreakdown#total_daily_crane_rate` → sum of wet_rates
   - `OnSiteMobileCraneBreakdown#crainage_rate_per_tonne` → total ÷ tender tonnage
   - `OnSiteMobileCraneBreakdown#crane_selections_by_purpose` → group by purpose

5. **Stimulus Controller Update (inline-edit)**
   - Enable fields from readonly to editable
   - Add Turbo Stream broadcast on save to recalculate totals
   - Trigger calculation when quantity or duration_days changes

---

## 11. TEST SCENARIOS

### Scenario 1: Basic Crane Selection
1. User enters roof area = 19,609 sqm
2. User enters erection rate = 300 sqm/day
3. System calculates program_duration = 66 days
4. User clicks "Add Row" for main crane (25t rental)
5. **Expected:** duration_days auto-fills to 66, wet_rate auto-filled, total_cost calculated
6. **Current:** All fields stay at 0

### Scenario 2: Multiple Cranes
1. User adds: 1× 25t rental for 66 days @ R2,410/day = R159,060
2. User adds: 1× 10t splicing crane for 70 days @ R1,660/day = R116,200
3. **Expected:** Summary shows Total = R275,260; Rate per tonne = R295.50
4. **Current:** Summary doesn't exist; totals always zero

### Scenario 3: Splicing Crane Auto-Population
1. on_site_mobile_crane_breakdown has splicing_crane_size = "25t", splicing_crane_days = 70
2. User selects splicing crane from dropdown
3. **Expected:** duration_days auto-fills to 70, wet_rate auto-filled
4. **Current:** Manual entry required; no defaults

---

## 12. REQUIREMENTS.MD ALIGNMENT

**Section 2.2 User Story US-032:**
> "As Demi, I want to manually adjust the crane complement so that I can account for project-specific requirements"

**Current Blocker:** Without total cost calculations, Demi cannot see the impact of her crane selections on overall tender cost.

**Section 6.1.4 - Crainage Calculation:**
> "Step 6: Rate per tonne = CEILING(total_crane_cost / total_tonnage, 20)"

**Current Blocker:** No way to calculate or store this value. `line_item_rate_build_ups.crainage_rate` field exists but is never populated from crane selections.

---

## Next Steps

This research should inform:
1. **Engineering Mode:** Code changes to add calculations
2. **Scope Definition:** `CRANE_CALCULATIONS_SCOPE.md` defining the vertical slice to build
3. **Sprint Tasks:** Broken down by component (model, controller, views, calculations)

