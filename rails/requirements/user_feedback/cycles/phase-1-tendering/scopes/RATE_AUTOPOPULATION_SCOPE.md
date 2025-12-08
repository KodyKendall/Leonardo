# Rate Auto-Population - Vertical Slice Scope

> **VERTICAL SLICE**: Auto-populate material supply and processing rates from lookup tables into line item rate build-ups. Core calculation engine.

**Timeline:** 2-3 days
**Status:** NOT STARTED
**Priority:** High
**Document Version:** 1.0
**Last Updated:** December 8, 2025

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| Material Supplies Table | ✅ Complete | 22 material types seeded |
| Material Supply Rates | ✅ Complete | Rates per supplier available |
| Processing Rates Table | ✅ Complete | Fabrication, overheads, etc. seeded |
| Line Item Materials UI | ✅ Complete | Dropdown selection working |
| Rate Build-up UI | ✅ Complete | 11 components displayed |
| Material Rate Auto-fill | 🔴 Pending | Select material → rate appears |
| Waste % Application | 🔴 Pending | base_rate × (1 + waste_pct) |
| Processing Rate Auto-fill | 🔴 Pending | Default rates from processing_rates |
| Blended Material Calc | 🔴 Pending | Weighted average from proportions |
| Rounding Logic | 🔴 Pending | R50 default, R20 crainage, R10 cherry picker |

---

## 1. Problem Statement

Currently rates must be manually entered in the rate build-up. Users have to:
1. Remember/lookup material supply rates
2. Manually calculate waste percentage
3. Manually enter processing rates
4. Manually calculate blended material rates

This defeats the purpose of the system. Rates should auto-populate from master data.

---

## 2. User Stories

| ID | Story | AC | Priority |
|----|-------|-----|----------|
| US-RATE-01 | As Demi, when I select a material, I want its rate to auto-fill | Rate appears instantly | High |
| US-RATE-02 | As Demi, I want waste % automatically applied to material rate | Rate shows base × (1 + waste%) | High |
| US-RATE-03 | As Demi, I want processing rates (fabrication, overheads) pre-filled | Default rates from master data | High |
| US-RATE-04 | As Demi, I want blended material rate calculated from proportions | Weighted avg shows in rate build-up | High |
| US-RATE-05 | As Demi, I want the final rate rounded correctly | R50 for standard, R20 crainage, R10 cherry picker | High |

---

## 3. Data Flow

```
User selects material "UB/UC Local" at 85% proportion
    ↓
System looks up: material_supplies.find_by(name: "UB/UC Local")
    → base_rate_per_tonne: R15,900
    → waste_percentage: 7.5%
    ↓
System calculates: 15,900 × 1.075 = R17,092.50 (rate with waste)
    ↓
System calculates weighted rate: R17,092.50 × 0.85 = R14,528.63
    ↓
(Repeat for each material, sum for blended total)
    ↓
System auto-fills processing rates from processing_rates table:
    → fabrication_rate: R8,000 (factor × base)
    → overheads_rate: R4,150
    → shop_priming_rate: R1,380
    → etc.
    ↓
System calculates subtotal = Σ(included rates)
    ↓
System applies rounding: CEILING(subtotal, 50)
    ↓
Rate build-up complete!
```

---

## 4. Tasks

### 4.1 Material Rate Auto-fill on Selection
**Priority:** High | **Est:** 0.5 days

**Trigger:** User selects material from dropdown
**Action:** AJAX call to get rate, populate field

**Implementation Options:**
1. **Stimulus Controller** - On change, fetch rate via AJAX
2. **Turbo Frame** - Replace rate field with server-rendered value
3. **Data attributes** - Embed rates in option values, read on change

**Recommended:** Stimulus controller for responsiveness

**Files:**
- `app/javascript/controllers/material_rate_controller.js` (new)
- `app/controllers/material_supplies_controller.rb` - Add `show.json` endpoint
- `app/views/line_item_materials/_fields.html.erb` - Add data-action

**Code Sketch:**
```javascript
// material_rate_controller.js
export default class extends Controller {
  static targets = ["select", "rate", "waste"]

  connect() {
    this.updateRate()
  }

  updateRate() {
    const materialId = this.selectTarget.value
    if (!materialId) return

    fetch(`/material_supplies/${materialId}.json`)
      .then(r => r.json())
      .then(data => {
        const rateWithWaste = data.base_rate_per_tonne * (1 + data.waste_percentage)
        this.rateTarget.value = rateWithWaste.toFixed(2)
        this.wasteTarget.textContent = `${(data.waste_percentage * 100).toFixed(1)}%`
      })
  }
}
```

### 4.2 Waste Percentage Display
**Priority:** High | **Est:** 0.25 days

Show waste % next to material rate so user understands calculation.

**UI Change:**
```
Material: [UB/UC Local ▼]  Rate: R17,092.50  Waste: 7.5%
```

### 4.3 Processing Rates Auto-fill
**Priority:** High | **Est:** 0.5 days

When line item created or category changed, populate processing rates from master data.

**Trigger:** Line item save, or on builder load
**Action:** Query processing_rates, set defaults

**Implementation:**
```ruby
# line_item_rate_build_up.rb
before_validation :set_default_rates, on: :create

def set_default_rates
  self.fabrication_rate ||= ProcessingRate.find_by(code: 'FABRICATION')&.base_rate_per_tonne
  self.overheads_rate ||= ProcessingRate.find_by(code: 'OVERHEADS')&.base_rate_per_tonne
  # ... etc for all 10 processing rates
end
```

### 4.4 Blended Material Rate Calculation
**Priority:** High | **Est:** 0.5 days

Sum weighted material rates into single material_supply_rate in rate build-up.

**Calculation:**
```ruby
def calculate_blended_material_rate
  line_item_materials.sum do |lim|
    material = lim.material_supply
    rate_with_waste = material.base_rate_per_tonne * (1 + material.waste_percentage)
    rate_with_waste * lim.proportion
  end
end
```

**Trigger:** After material save, recalculate and update rate build-up.

### 4.5 Rounding Rules Engine
**Priority:** High | **Est:** 0.5 days

Apply correct rounding based on rate type:
- Default line items: R50
- Crainage: R20
- Cherry picker: R10
- Corrosion protection: R10
- Chemical anchors: R10
- Mechanical anchors: R10

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

### 4.6 CFLC Fabrication Auto-Zero
**Priority:** High | **Est:** 0.25 days

Business rule: CFLC and cold-rolled items always have fabrication = 0

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

---

## 5. Demo Success Criteria

1. Create new line item
2. Select "UB/UC Local" at 85% + "Plate" at 15%
3. Rate build-up shows:
   - Material Supply: R17,194.88 (blended with waste)
   - Fabrication: R8,000 (auto-filled)
   - Overheads: R4,150 (auto-filled)
   - ... all processing rates pre-filled
4. Subtotal calculates correctly
5. Rounded rate shows R34,700 (nearest R50)
6. Change material proportions → rates recalculate instantly
7. Select CFLC category → fabrication auto-zeros

---

## 6. Files to Modify

| File | Change |
|------|--------|
| `app/javascript/controllers/material_rate_controller.js` | New - fetch rate on select |
| `app/controllers/material_supplies_controller.rb` | Add JSON endpoint |
| `app/models/line_item_rate_build_up.rb` | Default rates, calculations |
| `app/models/line_item_material_breakdown.rb` | Blended rate calculation |
| `app/views/line_item_materials/_fields.html.erb` | Wire up Stimulus |
| `app/views/line_item_rate_build_ups/_fields.html.erb` | Display waste %, auto-updates |

---

## 7. Dependencies

- Material supplies must be seeded with correct rates and waste %
- Processing rates must be seeded
- Stimulus controllers must be importmapped correctly

---

## 8. Testing Checklist

- [ ] Select single material → rate auto-fills
- [ ] Select two materials → blended rate calculates
- [ ] Proportions must sum to 100% (validation)
- [ ] Processing rates pre-fill on create
- [ ] CFLC category → fabrication = 0
- [ ] Rounding applies correctly (R50 default)
- [ ] Rate changes persist on save
- [ ] Grand total updates after rate change
