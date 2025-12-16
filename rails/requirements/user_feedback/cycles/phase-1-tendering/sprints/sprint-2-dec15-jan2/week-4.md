# Sprint 2, Week 4: Rate Engine & Line Item Templates (Dec 15-22)

**Duration:** 1 week
**Focus:** Rate auto-population, rounding rules, line item templates, crane calculation rollover
**Deliverable:** Full rate calculation engine with automatic population from master data
**Status:** 🟡 IN PROGRESS
**Last Updated:** December 15, 2025

---

## Week Overview

Week 4 implements the rate calculation engine that automatically populates rates from master data, applies business rule rounding, and provides category-based line item templates. This week also completes the crane calculations rolled over from Sprint 1.

**Priority Order:**
1. Sprint 1 crane calculation rollover (must complete first)
2. Rate auto-population engine (material + processing rates)
3. Rounding rules (R50/R20/R10)
4. Line item templates by category

---

## Vertical Slice Breakdown

| Slice | Scope Doc | Priority | Est. Days | Status | Assigned |
|-------|-----------|----------|-----------|--------|----------|
| Crane Calculations | [CRANE_CALC_SCOPE.md](../../scopes/CRANE_CALC_SCOPE.md) | Critical | 1-2 | 🔴 Rollover | - |
| Rate Auto-Population | [RATE_AUTOPOPULATION_SCOPE.md](../../scopes/RATE_AUTOPOPULATION_SCOPE.md) | High | 2-3 | 🔴 Pending | - |
| Rounding Rules | New | High | 1 | 🔴 Pending | - |
| Line Item Templates | New | Medium | 1-2 | 🔴 Pending | - |

---

## Capability A: Rate Auto-Population Engine

### Use Case UC-401: Material Rate Auto-Fill

**Description:** When a material is selected, the rate auto-populates from the "checked" supplier in material_supply_rates

**Acceptance Criteria:**
- [ ] AC-401.1: When user selects a material type from dropdown, the rate field auto-populates
- [ ] AC-401.2: Rate comes from the material_supply_rate where `is_selected = true` for that material
- [ ] AC-401.3: If no supplier is selected, use the second-cheapest rate
- [ ] AC-401.4: Rate field is editable (user can override the auto-filled value)

**Implementation Notes:**
```ruby
# In LineItemMaterial model or controller
def default_rate_for(material_supply_id)
  selected_rate = MaterialSupplyRate
    .where(material_supply_id: material_supply_id, is_selected: true)
    .order(effective_date: :desc)
    .first

  selected_rate&.rate_per_tonne || second_cheapest_rate(material_supply_id)
end
```

### Use Case UC-402: Processing Rate Auto-Fill

**Description:** Processing rates (fabrication, overheads, etc.) auto-populate from processing_rates table

**Acceptance Criteria:**
- [ ] AC-402.1: Fabrication rate auto-populates from processing_rates with work type multiplier
- [ ] AC-402.2: CFLC and cold-rolled items have fabrication auto-set to 0
- [ ] AC-402.3: Overheads rate auto-populates (no multiplier)
- [ ] AC-402.4: Shop priming rate auto-populates
- [ ] AC-402.5: Delivery rate auto-populates
- [ ] AC-402.6: All auto-filled rates are overridable

**Business Rules:**
| Category | Fabrication Multiplier | Notes |
|----------|------------------------|-------|
| Standard steel | 1.0x | Default |
| Light work | 0.75x | Simple structures |
| Heavy work | 1.75x | Complex fabrication |
| Very heavy | 2.0x | Specialized work |
| Extreme | 3.0x | Maximum complexity |
| CFLC | 0 | No fabrication |
| Cold-rolled | 0 | No fabrication |

### Use Case UC-403: Waste Percentage Application

**Description:** Waste percentage auto-fills based on material type and applies to rate calculation

**Acceptance Criteria:**
- [ ] AC-403.1: Waste percentage auto-fills when material selected (from material_supply.waste_percentage)
- [ ] AC-403.2: Material supply total = base_rate × (1 + waste_percentage) × proportion
- [ ] AC-403.3: Waste percentage is editable per line item
- [ ] AC-403.4: Calculation updates automatically when waste % changes

**Standard Waste Percentages:**
| Material Type | Default Waste % |
|---------------|-----------------|
| UB/UC Sections | 7.5% |
| Plate | 10% |
| CHS/RHS/SHS | 10% |
| Angles | 12.5% |
| Channels | 10% |
| Flats | 15% |

### Use Case UC-404: Blended Material Cost Calculation

**Description:** When multiple materials are used, the blended cost calculates correctly

**Acceptance Criteria:**
- [ ] AC-404.1: Blended material cost = sum of (rate_with_waste × proportion) for all materials
- [ ] AC-404.2: Proportions must sum to 1.0 (validation)
- [ ] AC-404.3: Warning displays if proportions don't sum to 1.0
- [ ] AC-404.4: Calculation auto-updates when any material row changes

**Example Calculation:**
```
Material 1: UB (85%), rate R12,500, waste 7.5%
Material 2: Plate (15%), rate R13,800, waste 10%

Material 1 cost = R12,500 × 1.075 × 0.85 = R11,421.88
Material 2 cost = R13,800 × 1.10 × 0.15 = R2,277.00
Blended total = R11,421.88 + R2,277.00 = R13,698.88
```

---

## Capability B: Rounding Rules Engine

### Use Case UC-405: Standard Rate Rounding (R50)

**Acceptance Criteria:**
- [ ] AC-405.1: Line item final rate rounds UP to nearest R50
- [ ] AC-405.2: Rounding applies after all calculations complete
- [ ] AC-405.3: Display shows both calculated and rounded values
- [ ] AC-405.4: Amount = rounded_rate × quantity

**Formula:**
```ruby
def round_to_nearest(value, multiple)
  (value / multiple.to_f).ceil * multiple
end

# Example: R13,698.88 → R13,700 (rounded to nearest R50)
rounded_rate = round_to_nearest(calculated_rate, 50)
```

### Use Case UC-406: Crainage Rate Rounding (R20)

**Acceptance Criteria:**
- [ ] AC-406.1: Crainage rate per tonne rounds UP to nearest R20
- [ ] AC-406.2: Applies to on-site mobile crane breakdown calculations
- [ ] AC-406.3: Display shows calculated value with R20 rounded result

### Use Case UC-407: Cherry Picker/Corrosion Protection Rounding (R10)

**Acceptance Criteria:**
- [ ] AC-407.1: Cherry picker rate per tonne rounds UP to nearest R10
- [ ] AC-407.2: Corrosion protection rates round UP to nearest R10
- [ ] AC-407.3: Chemical anchor rates round to nearest R10

---

## Capability C: Line Item Templates

### Use Case UC-408: Category-Based Material Defaults

**Description:** Pre-configured material proportions by steel category

**Acceptance Criteria:**
- [ ] AC-408.1: Steel sections category defaults to UB/UC material
- [ ] AC-408.2: Plate category defaults to plate material
- [ ] AC-408.3: CFLC category defaults to CFLC material with fabrication=0
- [ ] AC-408.4: Bolts category defaults to bolt-specific rates
- [ ] AC-408.5: User can modify defaults after auto-population

**Default Material Templates:**
| Category | Default Material | Default Proportion |
|----------|-----------------|-------------------|
| Steel Sections | UB/UC | 100% |
| Mixed Steelwork | UB/UC 85%, Plate 15% | Split |
| Plate Work | Plate | 100% |
| CFLC | Cold-formed light steel | 100% |
| Hollow Sections | CHS/RHS/SHS | 100% |

### Use Case UC-409: Category-Based Rate Build-Up Defaults

**Description:** Pre-configured inclusion flags by category

**Acceptance Criteria:**
- [ ] AC-409.1: Each category has default inclusion flags
- [ ] AC-409.2: Defaults apply when line item created
- [ ] AC-409.3: User can override any default flag

**Default Inclusion Flags:**
| Category | Fab | Erect | Bolts | Delivery | Paint | Crainage | Cherry | Galv |
|----------|-----|-------|-------|----------|-------|----------|--------|------|
| Steel Sections | 1 | 1 | 1 | 1 | 0 | 1 | 0 | 0 |
| CFLC | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 0 |
| Gutters | 0 | 1 | 0 | 1 | 0 | 0 | 1 | 0 |
| Bolts | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |

### Use Case UC-410: Tender-Level Rate Override Page

**Description:** QS can override material rates at tender level

**Acceptance Criteria:**
- [ ] AC-410.1: Tender-level rates page shows all default rates for the tender
- [ ] AC-410.2: Page displays current material rates (from master data)
- [ ] AC-410.3: QS can enter override rate for specific materials
- [ ] AC-410.4: Override applies to all line items in that tender
- [ ] AC-410.5: Clear indicator shows which rates are overridden

---

## Sprint 1 Rollover: Crane Calculations

### Pending Items (Must Complete First)

| Task | Acceptance Criteria | Status |
|------|---------------------|--------|
| Program duration auto-calc | AC-CR.1: duration = CEILING(roof_area / erection_rate, 1) | 🔴 |
| Crane complement lookup | AC-CR.2: Auto-lookup based on erection rate bracket | 🔴 |
| Wet rate auto-fill | AC-CR.3: Wet rate populates when crane selected | 🔴 |
| Total crane cost | AC-CR.4: cost = wet_rate × duration × quantity | 🔴 |
| Crainage rate/tonne | AC-CR.5: CEILING(total_cost / tonnage, 20) | 🔴 |

**Erection Rate Brackets:**
| Erection Rate (m²/day) | Recommended Cranes |
|------------------------|-------------------|
| < 250 | 2 × 10t |
| 250-350 | 1 × 10t + 1 × 25t |
| 350-450 | 3 × 10t |
| 450-550 | 1 × 10t + 2 × 25t |
| > 550 | 2 × 10t + 1 × 40t |

---

## Recommended Build Order

**Day 1-2: Crane Calculations Rollover**
- Complete program duration auto-calculation
- Implement crane complement lookup
- Wet rate auto-fill on crane selection
- Total crane cost calculation
- Crainage rate per tonne with R20 rounding

**Day 2-3: Rate Auto-Population**
- Material rate auto-fill from selected supplier
- Waste percentage auto-fill and application
- Blended material cost calculation
- Processing rate auto-fill (fabrication, overheads, etc.)
- CFLC/cold-rolled fabrication = 0 rule

**Day 4: Rounding Rules**
- R50 rounding for line item rates
- R20 rounding for crainage (verify with crane calc)
- R10 rounding for cherry picker/corrosion protection

**Day 5: Line Item Templates**
- Category-based material defaults
- Category-based inclusion flag defaults
- Tender-level rate override page

---

## Testing Scenarios

### Rate Auto-Population Test
1. Create new tender with BOQ
2. Add line item with Steel Sections category
3. Verify material auto-fills with UB/UC and correct rate
4. Verify waste percentage auto-fills (7.5%)
5. Verify calculated rate matches Excel formula

### Rounding Test
1. Calculate line item rate (e.g., R13,698.88)
2. Verify rounds to R13,700 (nearest R50)
3. Verify amount = rounded_rate × qty

### Crane Calculation Test
1. Enter roof area: 19,609 m²
2. Enter erection rate: 300 m²/day
3. Verify program duration: 66 days
4. Verify crane recommendation: 1 × 10t + 2 × 25t
5. Verify total cost calculation
6. Verify R20 rounding on crainage rate/tonne

---

## Key Files to Modify

### Models
- `app/models/line_item_material.rb` - Add rate auto-population
- `app/models/line_item_rate_build_up.rb` - Add processing rate auto-fill
- `app/models/tender.rb` - Add tender-level rate overrides
- `app/models/concerns/rate_calculator.rb` - Centralize rate calculations (new)

### Controllers
- `app/controllers/tender_line_items_controller.rb` - Template application
- `app/controllers/on_site_mobile_crane_breakdowns_controller.rb` - Crane calcs

### Views
- `app/views/tender_line_items/_form.html.erb` - Auto-fill display
- `app/views/tenders/_rates_page.html.erb` - Tender-level overrides (new)
- `app/views/on_site_mobile_crane_breakdowns/builder.html.erb` - Crane calcs

### Stimulus Controllers
- `app/javascript/controllers/rate_calculator_controller.js` - Enhance
- `app/javascript/controllers/rounding_controller.js` - New

---

## Acceptance Criteria Summary

### Critical (Must Complete)
- [ ] AC-CR.1-5: All crane calculations working
- [ ] AC-401.1-4: Material rate auto-fill working
- [ ] AC-402.1-6: Processing rate auto-fill working
- [ ] AC-403.1-4: Waste percentage application working
- [ ] AC-405.1-4: R50 rounding working

### High Priority
- [ ] AC-404.1-4: Blended material calculation working
- [ ] AC-406.1-3: R20 crainage rounding working
- [ ] AC-408.1-5: Category material defaults working

### Medium Priority
- [ ] AC-407.1-3: R10 rounding working
- [ ] AC-409.1-3: Category inclusion defaults working
- [ ] AC-410.1-5: Tender-level override page working

---

**Week Status:** In Progress
**Last Updated:** December 15, 2025
