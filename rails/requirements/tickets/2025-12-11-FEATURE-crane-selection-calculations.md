## 2025-12-11 – FEATURE: Crane Selection Calculations and Summary Display

### Metadata
- **Category:** Feature – New Calculation/Display Flow
- **Severity:** High
- **Environment:** `/on_site_mobile_crane_breakdowns/:id/builder`
- **Reported by:** Demi (Quantity Surveyor)

### User-Facing Summary

As a Quantity Surveyor, I cannot see total crane calculations for a tender after making crane selections. When I add cranes to a tender, all values (duration, rate, and cost) remain at zero, and there is no summary showing the total crane cost or rate per tonne. This prevents me from understanding the financial impact of my crane selections and completing accurate tender pricing.

### Current Behavior

- User navigates to Mobile Crane Breakdown Builder page at `/on_site_mobile_crane_breakdowns/:id/builder`
- Section 3 "Selected Cranes" displays "No tender crane selections found" when empty
- User can click "Add Row" to create a `TenderCraneSelection` record
- **All calculated fields default to zero:**
  - `duration_days` = 0 (should be auto-populated from breakdown parameters)
  - `wet_rate_per_day` = 0 (should be calculated from `CraneRate.dry_rate + diesel`)
  - `total_cost` = 0 (should be `quantity × duration_days × wet_rate_per_day`)
- **No summary section exists** showing total crane cost, total daily rate, or rate per tonne
- Values are not saved to database in a calculated state

### Desired Behavior (Product Decision – implement this)

**Source of Truth Rules:**
- `OnSiteMobileCraneBreakdown.program_duration_days` is the source of truth for main crane duration
- `OnSiteMobileCraneBreakdown.splicing_crane_days` is the source of truth for splicing crane duration
- `OnSiteMobileCraneBreakdown.misc_crane_days` is the source of truth for misc crane duration
- `CraneRate.dry_rate_per_day + CraneRate.diesel_per_day` is the source of truth for wet rate
- All cost fields are **derived and read-only** – no manual overrides in this iteration

**Auto-Population on Create:**
1. When a `TenderCraneSelection` is created:
   - `duration_days` auto-populates based on `purpose`:
     - `main` → `on_site_mobile_crane_breakdown.program_duration_days`
     - `splicing` → `on_site_mobile_crane_breakdown.splicing_crane_days`
     - `misc` → `on_site_mobile_crane_breakdown.misc_crane_days`
   - `wet_rate_per_day` auto-populates from `crane_rate.dry_rate_per_day + crane_rate.diesel_per_day`
   - `total_cost` auto-calculates: `quantity × duration_days × wet_rate_per_day`

**Recalculation on Update:**
2. When `quantity`, `duration_days`, or `crane_rate_id` changes, recalculate `total_cost` and re-derive `wet_rate_per_day` if crane changed

**Summary Display:**
3. Below the crane selections list, display a "Crane Cost Summary" section showing:
   - **Total Daily Crane Rate:** Sum of all `wet_rate_per_day × quantity`
   - **Total Crane Cost:** Sum of all `total_cost` values
   - **Crane Cost Per Tonne:** `CEILING(total_crane_cost / tender.total_tonnage, 20)`

**Persistence:**
4. All calculated values must be saved to the database on create/update

**Duration Override:**
5. Users CAN manually adjust `duration_days` after auto-population for project-specific needs

**Summary Calculation:**
6. Summary values are computed on-the-fly from `tender_crane_selections` (no caching column needed initially)

### Acceptance Criteria

1. **Given** a tender with `program_duration_days = 66`, **when** a user clicks "Add Row" and selects a main crane (25t rental), **then** `duration_days` auto-fills to 66, `wet_rate_per_day` shows `dry_rate + diesel` from `CraneRate`, and `total_cost` = `1 × 66 × wet_rate`

2. **Given** a crane selection exists, **when** the user changes `quantity` from 1 to 2, **then** `total_cost` recalculates to `2 × duration_days × wet_rate_per_day` and saves to database

3. **Given** `splicing_crane_days = 70` in the breakdown, **when** a user adds a crane with `purpose = "splicing"`, **then** `duration_days` auto-fills to 70

4. **Given** multiple crane selections exist with calculated costs, **when** the page loads, **then** a "Crane Cost Summary" section displays: total daily rate, total crane cost, and crane cost per tonne

5. **Given** `tender.total_tonnage = 931.62` and total crane cost = R1,001,500, **when** summary displays, **then** crane cost per tonne shows R1,080 (using `CEILING(..., 20)` rounding)

6. **Given** no crane selections exist, **when** the page loads, **then** the summary section shows "No crane selections" or zeros gracefully

7. **Given** a crane selection with auto-populated `duration_days`, **when** user manually changes the duration, **then** the new value is saved and `total_cost` recalculates accordingly

### Implementation Notes (for Leonardo / dev)

**Models:**
- `TenderCraneSelection` – add `before_save :calculate_costs` callback
  - Calculate `wet_rate_per_day` from associated `CraneRate`
  - Calculate `total_cost = quantity × duration_days × wet_rate_per_day`
- `TenderCraneSelection` – add `before_create :populate_duration_from_breakdown` callback
  - Lookup duration based on `purpose` enum from parent `OnSiteMobileCraneBreakdown`
- `OnSiteMobileCraneBreakdown` – add aggregate methods:
  - `total_crane_cost` → sum of `tender_crane_selections.total_cost`
  - `total_daily_crane_rate` → sum of `wet_rate_per_day × quantity`
  - `crainage_rate_per_tonne` → `(total_crane_cost / tender.total_tonnage).ceil_to(20)`

**Controller:**
- `TenderCraneSelectionsController#create` – ensure `purpose` defaults correctly; let model callbacks handle calculations
- `TenderCraneSelectionsController#update` – let model callbacks recalculate on save

**Views:**
- `app/views/tender_crane_selections/_index.html.erb` – add summary section after the list
- `app/views/tender_crane_selections/_tender_crane_selection.html.erb` – display `total_cost` per row
- Consider Turbo Stream broadcast to update summary when a selection changes

**Key Associations:**
- `TenderCraneSelection belongs_to :tender, :crane_rate`
- `Tender has_one :on_site_mobile_crane_breakdown`
- Access breakdown via: `tender_crane_selection.tender.on_site_mobile_crane_breakdown`

### Constraints / Guardrails

- **No manual editing of `wet_rate_per_day` or `total_cost`:** These are always derived
- **Duration CAN be manually adjusted** after auto-population for project-specific needs
- **Rate per tonne rounding:** Always use `CEILING(..., 20)` to round up to nearest R20
- **No new background jobs** – calculations happen synchronously on save
- **Maintain Turbo compatibility** – use Turbo Streams for live updates if inline editing is enabled
