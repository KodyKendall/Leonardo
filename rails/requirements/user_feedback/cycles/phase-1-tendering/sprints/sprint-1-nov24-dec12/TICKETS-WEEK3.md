# Week 3 Tickets

**Created:** December 8, 2025
**Sprint:** Sprint 1, Week 3 (Dec 8-12)

---

## UX/Turbo Fixes

### TICKET-UX-001: Fix page refresh on Save Changes (green checkmark)

**Type:** Bug Fix
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
Clicking the checkmark to save changes causes a full page reload.

**Expected Behavior:**
PATCH request via Turbo, field updates in place, no page reload.

**Actual Behavior:**
Full form POST, page reloads completely.

**Debugging Steps:**

1. **Isolate JavaScript logs:**
   - Open the app in an external browser tab (not embedded preview)
   - Open DevTools (F12 or Cmd+Shift+I)
   - Go to Console tab
   - Add `console.log()` statements to relevant JS files

2. **Check Network requests:**
   - Open DevTools → Network tab
   - Filter by "Fetch/XHR" to see AJAX requests
   - Look for: Red entries (failed requests), status codes, request/response payloads

3. **View Rails logs in real-time:**
   - Open VSCode terminal
   - Run: `ssh leonardo`
   - Run: `cd Leonardo`
   - Run: `./bin/rails_logs`
   - Clear terminal before reproducing bug
   - Add `Rails.logger.info "DEBUG: #{variable.inspect}"` to Ruby code

4. **Specific checks:**
   - Check form `method` attribute (should be PATCH)
   - Check form `data-turbo` attribute
   - Check controller `respond_to` format handling

5. **CLEANUP (REQUIRED):**
   - Remove ALL `console.log()` statements after fix
   - Remove ALL `Rails.logger.info "DEBUG:..."` statements after fix

**Files to Check:**
- `app/controllers/tender_line_items_controller.rb`
- `app/views/tender_line_items/update.turbo_stream.erb` (may need to create)
- `app/views/tender_line_items/_form.html.erb`

**Acceptance Criteria:**
- [ ] Edit a field, click green checkmark
- [ ] Changes save without page reload
- [ ] Can continue editing other fields
- [ ] No JavaScript console errors
- [ ] All debugging statements removed

---

### TICKET-UX-002: Rename "Qty" column to "Proportion"

**Type:** UX Iteration
**Severity:** Medium
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
The "Qty" column in material breakdown is misleading - it represents proportion/percentage, not quantity.

**Change:**
```erb
<%# Before %>
<th>Qty</th>

<%# After %>
<th>Proportion</th>
```

**Files to Modify:**
- `app/views/line_item_materials/_fields.html.erb`
- `app/views/line_item_material_breakdowns/_fields.html.erb`

**Acceptance Criteria:**
- [ ] Column header shows "Proportion" (not "Qty")
- [ ] Any form labels updated to match

---

### TICKET-UX-003: Fix "Rsb owned" capitalization to "RSB Owned"

**Type:** Bug Fix
**Severity:** Low
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
Crane ownership dropdown shows "Rsb owned" instead of "RSB Owned".

**Root Cause:**
Enum value being titleized (`rsb_owned.titleize` -> "Rsb Owned")

**Fix:**
```erb
<%# Use explicit options instead of titleize %>
<%= f.select :ownership_type, [['RSB Owned', 'rsb_owned'], ['Rental', 'rental']] %>
```

**Files to Check:**
- `app/views/tender_crane_selections/_form.html.erb`
- `app/views/on_site_mobile_crane_breakdowns/_form.html.erb`

**Acceptance Criteria:**
- [ ] Dropdown shows "RSB Owned" (not "Rsb owned")
- [ ] Selection saves correctly to database

---

## BOQ Parsing Fixes

### TICKET-BOQ-001: Remove line item count from "Next Step" message

**Type:** UX Iteration
**Severity:** Medium
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
The "Next Step" card on `/boqs/:id` displays the number of BOQ line items parsed, which can be confusing or misleading (count display has shown incorrect numbers in the past).

**Current State:**
```
Next Step
Copy BOQ into [Tender Name]
25 line items ready to be transferred to the tender builder.
```

**Desired State:**
```
Next Step
Copy BOQ into [Tender Name]
Line items ready to be transferred to the tender builder.
```

**File to Modify:**
- `app/views/boqs/show.html.erb` (line 717-718)

**Change:**
```erb
<%# Before (line 717-718) %>
<p class="text-sm text-gray-500 mt-2">
  <%= @boq_items.count %> line items ready to be transferred to the tender builder.
</p>

<%# After %>
<p class="text-sm text-gray-500 mt-2">
  Line items ready to be transferred to the tender builder.
</p>
```

**Acceptance Criteria:**
- [ ] "Next Step" card no longer shows the line item count
- [ ] Message still displays correctly
- [ ] "Open Builder" button still works

---

### TICKET-BOQ-002: Test and fix large BOQ handling (50+ items)

**Type:** Testing/Bug Fix
**Severity:** High
**Est:** 1 day
**Status:** Not Started

**Problem:**
BOQ parsing has only been tested with ~25 items. Larger BOQs may timeout, hit memory limits, or exceed AI token limits.

**Test Cases:**
1. 25-item BOQ (current working size - baseline)
2. 50-item BOQ
3. 100-item BOQ
4. 200-item BOQ (stress test)

**Potential Issues to Watch:**
- API timeout
- Memory limits
- Token limits in AI response
- Parsing progress UI stalling

**Files to Check:**
- `langgraph/agents/boq_parser/nodes.py` - Parsing logic
- `app/controllers/boqs_controller.rb` - Timeout settings

**Fix Options (if issues found):**
1. Batch parsing (parse in chunks of 25)
2. Increase timeout limits
3. Streaming response handling
4. Background job processing with progress updates

**Acceptance Criteria:**
- [ ] 50-item BOQ parses successfully
- [ ] 100-item BOQ parses successfully (or graceful error)
- [ ] Progress UI updates correctly during parsing
- [ ] All items transferred to tender builder correctly

---

### TICKET-BOQ-003: Add category allocation tooltips

**Type:** Enhancement
**Severity:** Medium
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
Elmarie needs guidance on which category to select for BOQ line items. Currently no help text or tooltips explain what each category includes.

**Categories Available:**
- Steel Sections
- Paintwork
- Bolts
- Anchors (Chemical)
- Anchors (Mechanical)
- HD Bolts
- Gutters
- CFLC
- Plate
- Provisional Sums

**Implementation:**
Add tooltip/info icon next to category dropdown showing description on hover.

Example tooltips:
- "Steel Sections: UB, UC, PFC, I-beams, angles"
- "CFLC: Cold-formed light-gauge steel, purlins, girts"
- "Plate: Flat plate, base plates, stiffener plates"

**Files to Modify:**
- `app/views/boq_items/_form.html.erb` - Add tooltip to category dropdown
- `app/views/tender_line_items/_form.html.erb` - Add tooltip to category dropdown

**Acceptance Criteria:**
- [ ] Info icon appears next to category dropdown
- [ ] Hover shows description of category
- [ ] Descriptions are helpful for categorization decisions

---

## Rate Auto-Population

### TICKET-RATE-001: Auto-fill material supply rate on selection

**Type:** Feature
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
When user selects a material from dropdown, the rate should auto-populate from the MaterialSupply lookup table. Currently users must enter rates manually.

**Expected Behavior:**
1. User selects "UB/UC Local" from material dropdown
2. System looks up MaterialSupply record
3. Rate field auto-populates with base_rate_per_tonne (e.g., R15,900)
4. Waste percentage displays (e.g., 7.5%)

**Implementation:**

```javascript
// material_rate_controller.js
export default class extends Controller {
  static targets = ["select", "rate", "waste"]

  updateRate() {
    const materialId = this.selectTarget.value
    if (!materialId) return

    fetch(`/material_supplies/${materialId}.json`)
      .then(r => r.json())
      .then(data => {
        this.rateTarget.value = data.base_rate_per_tonne
        this.wasteTarget.textContent = `${(data.waste_percentage * 100).toFixed(1)}%`
      })
  }
}
```

**Files to Create/Modify:**
- `app/javascript/controllers/material_rate_controller.js` (new)
- `app/controllers/material_supplies_controller.rb` - Add `show.json` endpoint
- `app/views/line_item_materials/_fields.html.erb` - Wire up Stimulus controller

**Acceptance Criteria:**
- [ ] Select material from dropdown
- [ ] Rate auto-fills from MaterialSupply table
- [ ] Waste percentage displays next to rate
- [ ] No page refresh occurs

---

### TICKET-RATE-002: Apply waste percentage to material rate

**Type:** Feature
**Severity:** High
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
Material rates should include waste percentage in the calculation. Currently the base rate is used without waste adjustment.

**Calculation:**
```
rate_with_waste = base_rate_per_tonne × (1 + waste_percentage)

Example:
UB/UC Local: R15,900 × 1.075 = R17,092.50
```

**UI Display:**
```
Material: [UB/UC Local ▼]  Rate: R17,092.50  (Waste: 7.5%)
```

**Files to Modify:**
- `app/javascript/controllers/material_rate_controller.js` - Calculate rate with waste
- `app/views/line_item_materials/_fields.html.erb` - Display waste info

**Acceptance Criteria:**
- [ ] Rate displayed includes waste percentage
- [ ] Waste percentage shown for transparency
- [ ] Calculation matches: base_rate × (1 + waste_pct)

---

### TICKET-RATE-003: Auto-fill processing rates from master data

**Type:** Feature
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
Processing rates (fabrication, overheads, shop priming, etc.) should auto-populate from ProcessingRate master data when a line item is created.

**Processing Rates to Auto-fill:**
- Fabrication
- Overheads
- Shop Priming
- Corrosion Protection
- Hot Dip Galvanizing
- Touch-up / Site Coat
- Cherry Picker
- Crainage
- Delivery
- Installation

**Implementation:**
```ruby
# line_item_rate_build_up.rb
before_validation :set_default_rates, on: :create

def set_default_rates
  self.fabrication_rate ||= ProcessingRate.find_by(code: 'FABRICATION')&.base_rate_per_tonne
  self.overheads_rate ||= ProcessingRate.find_by(code: 'OVERHEADS')&.base_rate_per_tonne
  # ... etc for all processing rates
end
```

**Files to Modify:**
- `app/models/line_item_rate_build_up.rb` - Add default rate callbacks

**Acceptance Criteria:**
- [ ] Create new line item
- [ ] Rate build-up shows pre-filled processing rates
- [ ] Rates match ProcessingRate master data values
- [ ] User can still override any rate

---

### TICKET-RATE-004: Calculate blended material rate from proportions

**Type:** Feature
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
When multiple materials are used (e.g., 85% UB/UC + 15% Plate), the system should calculate a weighted average "blended" material rate.

**Calculation:**
```ruby
def calculate_blended_material_rate
  line_item_materials.sum do |lim|
    material = lim.material_supply
    rate_with_waste = material.base_rate_per_tonne * (1 + material.waste_percentage)
    rate_with_waste * lim.proportion
  end
end

# Example:
# UB/UC: R17,092.50 × 0.85 = R14,528.63
# Plate: R18,200 × 0.15 = R2,730.00
# Blended: R17,258.63
```

**Files to Modify:**
- `app/models/line_item_rate_build_up.rb` - Add blended rate calculation
- `app/models/line_item_material_breakdown.rb` - Trigger recalculation on change

**Acceptance Criteria:**
- [ ] Add two materials with proportions (e.g., 85% + 15%)
- [ ] Material Supply rate in rate build-up shows weighted average
- [ ] Change proportions → rate recalculates
- [ ] Proportions must sum to 100% (validation)

---

### TICKET-RATE-005: Implement rounding rules (R50/R20/R10)

**Type:** Feature
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
Final rates need to be rounded according to business rules:
- Default line items: Round to nearest R50
- Crainage: Round to nearest R20
- Cherry Picker: Round to nearest R10
- Corrosion Protection: Round to nearest R10
- Chemical/Mechanical Anchors: Round to nearest R10

**Implementation:**
```ruby
# line_item_rate_build_up.rb
def calculate_rounded_rate
  base = total_before_rounding

  rounding = case line_item.category
             when 'Corrosion Protection', 'Chemical Anchors', 'Mechanical Anchors'
               10
             else
               50
             end

  (base / rounding.to_f).ceil * rounding
end
```

**Files to Modify:**
- `app/models/line_item_rate_build_up.rb` - Add rounding logic

**Acceptance Criteria:**
- [ ] Standard line item rounds to R50 (e.g., R34,678 → R34,700)
- [ ] Crainage rate rounds to R20
- [ ] Cherry picker rounds to R10
- [ ] Corrosion protection rounds to R10
- [ ] Calculations match business expectation

---

### TICKET-RATE-006: CFLC category auto-zeros fabrication rate

**Type:** Feature
**Severity:** Medium
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
Business rule: CFLC (Cold-Formed Light-gauge steel) and cold-rolled items always have fabrication = R0 because they come pre-fabricated.

**Implementation:**
```ruby
# line_item_rate_build_up.rb
before_save :apply_cflc_rule

def apply_cflc_rule
  if tender_line_item.category == 'CFLC'
    self.fabrication_rate = 0
    self.fabrication_included = false
  end
end
```

**Files to Modify:**
- `app/models/line_item_rate_build_up.rb` - Add CFLC callback

**Acceptance Criteria:**
- [ ] Create line item with category "CFLC"
- [ ] Fabrication rate auto-set to R0
- [ ] Fabrication checkbox unchecked
- [ ] Other categories still have normal fabrication rate

---

## Crane Calculations

### TICKET-CRANE-001: Auto-calculate program duration

**Type:** Feature
**Severity:** High
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
Program duration should auto-calculate when roof area and erection rate are entered:
```
program_duration_days = CEILING(total_roof_area / erection_rate, 1)
```

**Current State:**
UI exists but calculation may not trigger automatically on input change.

**Expected Behavior:**
1. User enters Total Roof Area: 19,609 m²
2. User enters Erection Rate: 300 m²/day
3. Program Duration auto-displays: 66 days (ceiling of 65.36)

**Files to Check/Modify:**
- `app/models/on_site_mobile_crane_breakdown.rb` - `before_save :calculate_program_duration`
- `app/javascript/controllers/site_config_controller.js` - Live calculation on input

**Acceptance Criteria:**
- [ ] Enter roof area and erection rate
- [ ] Program duration calculates immediately (client-side)
- [ ] Value persists on save
- [ ] Calculation: CEILING(19609/300) = 66

---

### TICKET-CRANE-002: Auto-lookup crane complement from erection rate

**Type:** Feature
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
When erection rate is entered, system should auto-lookup the recommended crane complement from the crane_complements table.

**Lookup Logic:**
```ruby
complement = CraneComplement.where(
  "area_min_sqm <= ? AND area_max_sqm >= ?",
  erection_rate, erection_rate
).first
```

**Brackets:**
- 0-200 m²/day: 1 × 10t
- 200-250 m²/day: 1 × 10t + 1 × 20t
- 250-350 m²/day: 1 × 10t + 2 × 25t
- 350-500 m²/day: 2 × 25t + 1 × 35t
- 500+ m²/day: 2 × 35t + 1 × 50t

**Expected Behavior:**
1. User enters erection rate: 300 m²/day
2. System displays: "Recommended: 1 × 10t + 2 × 25t"
3. System displays combined daily rate: R7,020/day

**Files to Modify:**
- `app/models/crane_complement.rb` - Add `for_erection_rate(rate)` scope
- `app/controllers/on_site_mobile_crane_breakdowns_controller.rb` - Return complement
- `app/views/on_site_mobile_crane_breakdowns/_form.html.erb` - Display recommendation

**Acceptance Criteria:**
- [ ] Enter erection rate of 300
- [ ] System shows "Recommended: 1 × 10t + 2 × 25t"
- [ ] Combined rate shows R7,020/day
- [ ] User can override with manual selection

---

### TICKET-CRANE-003: Auto-populate wet rate from crane selection

**Type:** Feature
**Severity:** High
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
When a crane is selected from the dropdown, the wet rate should auto-populate from the crane_rates table.

**Calculation:**
```
wet_rate = dry_rate_per_day + diesel_per_day

Example for 25t rental:
wet_rate = 1,660 + 750 = R2,410/day
```

**Expected Behavior:**
1. User selects "25t" crane
2. System auto-fills wet rate: R2,410/day (for rental)
3. Rate stored as snapshot on tender_crane_selection

**Files to Modify:**
- `app/models/tender_crane_selection.rb` - `before_save :snapshot_wet_rate`
- `app/javascript/controllers/crane_selection_controller.js` - Fetch rate on change

**Acceptance Criteria:**
- [ ] Select crane size from dropdown
- [ ] Wet rate auto-populates
- [ ] Rate reflects RSB Owned vs Rental selection
- [ ] Rate persists as snapshot (won't change if master data updates)

---

### TICKET-CRANE-004: Calculate total crane cost

**Type:** Feature
**Severity:** High
**Est:** 0.25 day
**Status:** Not Started

**Problem:**
Total cost for each crane selection should auto-calculate:
```
total_cost = wet_rate_per_day × quantity × duration_days

Example: 2 × 25t cranes for 66 days
= 2,410 × 2 × 66 = R318,120
```

**Files to Modify:**
- `app/models/tender_crane_selection.rb` - `before_save :calculate_total_cost`
- `app/javascript/controllers/crane_selection_controller.js` - Live calculation

**Acceptance Criteria:**
- [ ] Enter/change quantity, duration, or crane size
- [ ] Total cost recalculates immediately
- [ ] Calculation matches: rate × qty × days
- [ ] Cost summary updates after save

---

### TICKET-CRANE-005: Calculate crainage rate per tonne with R20 rounding

**Type:** Feature
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
Total crainage cost needs to be divided by tender tonnage and rounded to nearest R20.

**Calculation:**
```ruby
raw_rate = total_crainage_cost / total_tonnage
crainage_rate_per_tonne = (raw_rate / 20.0).ceil * 20

# Example:
# raw_rate = 632,020 / 931.62 = 678.52
# rounded = ceil(678.52 / 20) * 20 = ceil(33.93) * 20 = 34 * 20 = R680
```

**Implementation:**
```ruby
# crainage_calculator_service.rb
def calculate_rate_per_tonne
  return 0 if tender.total_tonnage.zero?

  raw_rate = total_crainage_cost / tender.total_tonnage
  (raw_rate / 20.0).ceil * 20
end
```

**Files to Create/Modify:**
- `app/services/crainage_calculator_service.rb` - Create service
- Call from TenderCraneSelection after_save

**Acceptance Criteria:**
- [ ] Add/modify crane selections
- [ ] Crainage rate per tonne displays in summary
- [ ] Rate rounded to nearest R20
- [ ] Calculation: 632,020 / 931.62 = R680/t

---

### TICKET-CRANE-006: Implement CrainageCalculatorService

**Type:** Feature
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
Need a centralized service to:
1. Sum all crane selection costs
2. Calculate crainage rate per tonne
3. Distribute to line items OR P&G based on inclusion setting

**Service Methods:**
```ruby
class CrainageCalculatorService
  def call(tender)
    calculate_total_cost
    calculate_rate_per_tonne
    distribute_crainage
  end

  def distribute_to_line_items
    # Update line_item_rate_build_ups.crainage_rate
  end

  def distribute_to_pg
    # Create/update tender_preliminary_item with CRAINAGE code
  end
end
```

**Files to Create:**
- `app/services/crainage_calculator_service.rb`

**Acceptance Criteria:**
- [ ] Service calculates correct total_crainage_cost
- [ ] Service calculates correct rate_per_tonne with R20 rounding
- [ ] When include_crainage=true, line item rates updated
- [ ] When include_crainage=false, P&G item created/updated
- [ ] Called automatically on crane selection changes

---

## UX Fixes (Additional)

### TICKET-UX-004: Fix page refresh on Add Material

**Type:** Bug Fix
**Severity:** High
**Est:** 0.5 day
**Status:** Not Started

**Problem:**
Clicking "+ Add Material" causes a full page reload, losing scroll position and context.

**Expected Behavior:**
1. User clicks "+ Add Material"
2. New material row appears via DOM manipulation or Turbo Stream
3. No page reload
4. Scroll position maintained

**Root Cause:** Likely form submission not prevented, or missing Turbo Stream response.

**Fix Options:**

**Option A: Pure Stimulus (Preferred)**
```javascript
// nested_form_controller.js
addItem(event) {
  event.preventDefault() // Prevent form submission
  const template = this.templateTarget.innerHTML
  const newId = new Date().getTime()
  const content = template.replace(/NEW_RECORD/g, newId)
  this.containerTarget.insertAdjacentHTML('beforeend', content)
}
```

**Option B: Turbo Stream**
```ruby
# line_item_materials_controller.rb
def new
  @material = @line_item.materials.build
  respond_to do |format|
    format.turbo_stream
  end
end
```

**Files to Check/Modify:**
- `app/javascript/controllers/nested_form_controller.js`
- `app/views/line_item_materials/_fields.html.erb`
- Check button `data-turbo` attributes

**Acceptance Criteria:**
- [ ] Click "+ Add Material"
- [ ] New row appears without page refresh
- [ ] Scroll position maintained
- [ ] Can fill in material details immediately
- [ ] No JavaScript console errors

---

## Summary

| Ticket | Type | Severity | Est |
|--------|------|----------|-----|
| TICKET-UX-001 | Bug Fix | High | 0.5 day |
| TICKET-UX-002 | UX Iteration | Medium | 0.25 day |
| TICKET-UX-003 | Bug Fix | Low | 0.25 day |
| TICKET-UX-004 | Bug Fix | High | 0.5 day |
| TICKET-BOQ-001 | UX Iteration | Medium | 0.25 day |
| TICKET-BOQ-002 | Testing | High | 1 day |
| TICKET-BOQ-003 | Enhancement | Medium | 0.5 day |
| TICKET-RATE-001 | Feature | High | 0.5 day |
| TICKET-RATE-002 | Feature | High | 0.25 day |
| TICKET-RATE-003 | Feature | High | 0.5 day |
| TICKET-RATE-004 | Feature | High | 0.5 day |
| TICKET-RATE-005 | Feature | High | 0.5 day |
| TICKET-RATE-006 | Feature | Medium | 0.25 day |
| TICKET-CRANE-001 | Feature | High | 0.25 day |
| TICKET-CRANE-002 | Feature | High | 0.5 day |
| TICKET-CRANE-003 | Feature | High | 0.25 day |
| TICKET-CRANE-004 | Feature | High | 0.25 day |
| TICKET-CRANE-005 | Feature | High | 0.5 day |
| TICKET-CRANE-006 | Feature | High | 0.5 day |

**Total Estimated:** ~8 days

---

## Recommended Build Order

**Day 1: UX Fixes (Quick Wins)**
1. TICKET-UX-001: Fix page refresh on Save Changes
2. TICKET-UX-004: Fix page refresh on Add Material
3. TICKET-UX-002: Rename "Qty" to "Proportion"
4. TICKET-UX-003: Fix "RSB Owned" capitalization
5. TICKET-BOQ-001: Remove line item count from message

**Day 2: BOQ Parsing**
1. TICKET-BOQ-002: Test large BOQ handling
2. TICKET-BOQ-003: Add category tooltips

**Day 2-4: Rate Auto-Population**
1. TICKET-RATE-001: Material rate auto-fill
2. TICKET-RATE-002: Waste percentage application
3. TICKET-RATE-003: Processing rates auto-fill
4. TICKET-RATE-004: Blended material calculation
5. TICKET-RATE-005: Rounding rules
6. TICKET-RATE-006: CFLC auto-zero fabrication

**Day 3-5: Crane Calculations**
1. TICKET-CRANE-001: Program duration auto-calculate
2. TICKET-CRANE-002: Crane complement lookup
3. TICKET-CRANE-003: Wet rate auto-fill
4. TICKET-CRANE-004: Total cost calculation
5. TICKET-CRANE-005: Crainage rate per tonne
6. TICKET-CRANE-006: CrainageCalculatorService
