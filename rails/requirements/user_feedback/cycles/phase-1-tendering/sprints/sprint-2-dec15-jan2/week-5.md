# Sprint 2, Week 5: Equipment & P&G (Dec 23-29)

**Duration:** 1 week
**Focus:** Access equipment selection, P&G items, inclusions/exclusions
**Deliverable:** Complete equipment costing and preliminary items with mutual exclusion logic
**Status:** 🔴 PENDING
**Last Updated:** December 15, 2025

---

## Week Overview

Week 5 implements access equipment selection (non-crane equipment), P&G (Preliminaries & General) items, and tender-level inclusions/exclusions. This includes the mutual exclusion logic to prevent double-counting crainage/cherry picker costs in both line items and P&G.

**Note:** Holiday period (Dec 23-Jan 2) - availability may be limited. Critical work front-loaded in Week 4.

---

## Vertical Slice Breakdown

| Slice | Scope Doc | Priority | Est. Days | Status | Assigned |
|-------|-----------|----------|-----------|--------|----------|
| Access Equipment | New scope needed | High | 2 | 🔴 Pending | - |
| P&G Items | New scope needed | High | 2 | 🔴 Pending | - |
| Inclusions/Exclusions | Part of TENDER_BUILDER_SCOPE | High | 1 | 🔴 Pending | - |

---

## Capability D: Access Equipment Selection

### Use Case UC-501: Equipment Type Selection from Catalog

**Description:** User selects access equipment from pre-defined catalog

**Acceptance Criteria:**
- [ ] AC-501.1: Dropdown shows all equipment types (scissors, booms, telehandlers)
- [ ] AC-501.2: Each equipment type displays base monthly rate
- [ ] AC-501.3: Equipment catalog editable by admin (rate updates)
- [ ] AC-501.4: Equipment rates include diesel allowance field

**Equipment Catalog:**
| Type | Description | Base Monthly Rate | Diesel/Month |
|------|-------------|-------------------|--------------|
| Scissor Lift | 26ft/32ft/40ft | R8,500 - R15,000 | R1,500 |
| Boom Lift | 40ft/60ft/80ft | R18,000 - R35,000 | R2,500 |
| Telehandler | 4m/6m/9m | R22,000 - R38,000 | R3,000 |

### Use Case UC-502: Multiple Equipment Selections per Tender

**Description:** User can add multiple equipment lines with different configurations

**Acceptance Criteria:**
- [ ] AC-502.1: User can add multiple equipment lines
- [ ] AC-502.2: Each line has: equipment type, quantity, period (months)
- [ ] AC-502.3: User can remove equipment lines
- [ ] AC-502.4: Calculations update when lines added/removed

**Example Configuration:**
```
Line 1: 3 × Boom 60ft for 1 month
Line 2: 1 × Boom 60ft for 2 months
Line 3: 2 × Scissor 32ft for 3 months
```

### Use Case UC-503: Damage Waiver Calculation (6%)

**Description:** 6% damage waiver automatically applies to equipment rental rates

**Acceptance Criteria:**
- [ ] AC-503.1: Damage waiver (6%) auto-applies to all equipment rates
- [ ] AC-503.2: Display shows base rate and damage waiver separately
- [ ] AC-503.3: Total = (base_rate + diesel) × (1 + 0.06) × quantity × months
- [ ] AC-503.4: Damage waiver percentage configurable (default 6%)

**Calculation Example:**
```
Equipment: Boom 60ft
Base rate: R25,000/month
Diesel: R2,500/month
Quantity: 2
Period: 3 months

Subtotal = (R25,000 + R2,500) × 1.06 = R29,150/month
Total = R29,150 × 2 × 3 = R174,900
```

### Use Case UC-504: Equipment Cost per Tonne Distribution

**Description:** Equipment costs distributed across tender tonnage as rate per tonne

**Acceptance Criteria:**
- [ ] AC-504.1: Equipment rate per tonne = CEILING(total_cost / tonnage, 10)
- [ ] AC-504.2: R10 rounding applies to equipment rates
- [ ] AC-504.3: Rate per tonne displays on equipment summary
- [ ] AC-504.4: Can choose to include in P&G OR line item rates

---

## Capability E: P&G (Preliminaries & General)

### Use Case UC-505: Add Custom P&G Items

**Description:** User can add custom P&G items with descriptions and lump sums

**Acceptance Criteria:**
- [ ] AC-505.1: User can add P&G items with description field
- [ ] AC-505.2: Each P&G item has lump sum amount field
- [ ] AC-505.3: User can edit/delete P&G items
- [ ] AC-505.4: P&G items persist with tender

**Common P&G Items:**
| Item | Typical Amount | Notes |
|------|---------------|-------|
| Site Establishment | R50,000 - R150,000 | Varies by project |
| Site De-establishment | R25,000 - R75,000 | Usually 50% of establishment |
| Plant Establishment | R30,000 - R100,000 | Equipment mobilization |
| Plant De-establishment | R15,000 - R50,000 | Usually 50% of establishment |
| Accommodation (PM) | R5,000/week | Per person |
| Travel | Varies | Distance-based |
| Safety File & Audits | R30,000 | Standard item |

### Use Case UC-506: Standard P&G Item Templates

**Description:** Pre-defined P&G items available for quick selection

**Acceptance Criteria:**
- [ ] AC-506.1: Standard item: Safety File & Audits = R30,000 lump sum
- [ ] AC-506.2: Template items available via "Add Standard Item" button
- [ ] AC-506.3: Template amounts are editable after adding
- [ ] AC-506.4: Templates include: Safety File, Site Est/De-est, Plant Est/De-est

### Use Case UC-507: P&G Rate per Tonne Calculation

**Description:** P&G lump sums converted to rate per tonne for distribution

**Acceptance Criteria:**
- [ ] AC-507.1: P&G rate per tonne = sum(lump_sums) / total_tonnage
- [ ] AC-507.2: P&G rate rounds to nearest R50
- [ ] AC-507.3: P&G rate displays on tender summary
- [ ] AC-507.4: P&G can be shown as lump sum OR rate per tonne

**Example:**
```
Total P&G Items: R285,000
Total Tonnage: 931.62 t
P&G Rate = R285,000 / 931.62 = R305.96 → R350 (rounded to R50)
```

### Use Case UC-508: Crainage/Equipment Mutual Exclusion

**Description:** Crainage and cherry picker costs can be in line items OR P&G, not both

**Acceptance Criteria:**
- [ ] AC-508.1: If crainage in P&G, line item crainage flag = 0
- [ ] AC-508.2: If cherry picker in P&G, line item cherry picker flag = 0
- [ ] AC-508.3: Toggle UI shows mutual exclusion clearly
- [ ] AC-508.4: Warning displays if user tries to enable both
- [ ] AC-508.5: System prevents double-counting automatically

**UI Approach:**
```
[Crainage Allocation]
○ Include in Line Item Rates (rate per tonne distributed)
○ Include in P&G (lump sum shown separately)

[Cherry Picker Allocation]
○ Include in Line Item Rates
○ Include in P&G
```

---

## Capability F: Tender Inclusions/Exclusions

### Use Case UC-509: Tender-Level Inclusion Toggles

**Description:** Toggle switches control which cost components are included in the tender

**Acceptance Criteria:**
- [ ] AC-509.1: Toggle switches for each inclusion type
- [ ] AC-509.2: Toggles apply to all line items by default
- [ ] AC-509.3: Toggle state persists with tender
- [ ] AC-509.4: Changing toggle recalculates affected line items

**Inclusion Toggle List:**
| Toggle | Default | Description |
|--------|---------|-------------|
| Fabrication | ON | Include fabrication costs |
| Erection | ON | Include erection labor |
| Bolts | ON | Include bolt costs |
| Delivery | ON | Include delivery costs |
| Shop Priming | ON | Include shop primer |
| On-Site Painting | OFF | Include corrosion protection |
| Crainage | ON | Include crane costs in rates |
| Cherry Picker | OFF | Include cherry picker in rates |
| Galvanizing | OFF | Include hot-dip galvanizing |

### Use Case UC-510: Line-Item Level Overrides

**Description:** Individual line items can override tender-level settings

**Acceptance Criteria:**
- [ ] AC-510.1: Individual line items can override tender-level settings
- [ ] AC-510.2: Override indicator shows when line item differs from tender
- [ ] AC-510.3: Override can be removed to revert to tender default
- [ ] AC-510.4: Tooltip explains override vs default

**UI Approach:**
- Toggle appears with highlight/border when overridden
- "Reset to tender default" option available
- Visual indicator (e.g., asterisk) on overridden items

---

## P&G vs Line Item Cost Allocation

### Cost Flow Diagram
```
                    ┌─────────────────────────────────────┐
                    │         TOTAL PROJECT COSTS          │
                    └─────────────────────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │  LINE ITEM RATES │    │   P&G SECTION    │    │   SHOP DRAWINGS │
    │  (per tonne)     │    │   (lump sums)    │    │   (lump sum)    │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
              │                       │
              │  If "Include in       │  If "Include in
              │  Line Items" ON       │  P&G" ON
              ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐
    │ Material Supply  │    │ Site Est/De-est │
    │ Fabrication     │    │ Plant Est/De-est│
    │ Overheads       │    │ Accommodation   │
    │ Shop Priming    │    │ Travel          │
    │ Delivery        │    │ Safety File     │
    │ Bolts           │    │ *Crainage       │
    │ Erection        │    │ *Cherry Picker  │
    │ *Crainage       │    │ *Galvanizing    │
    │ *Cherry Picker  │    └─────────────────┘
    │ *Galvanizing    │
    └─────────────────┘

    * = Mutual exclusion - can only be in ONE section
```

---

## Recommended Build Order

**Day 1: Access Equipment Selection**
- Equipment type dropdown with rates
- Add/remove equipment lines
- Quantity and period inputs
- Damage waiver calculation (6%)

**Day 2: Equipment Calculations**
- Total equipment cost calculation
- Rate per tonne with R10 rounding
- Equipment summary display
- Integration with tender totals

**Day 3: P&G Items**
- Add custom P&G items UI
- Lump sum amount input
- Standard P&G templates (Safety File, etc.)
- P&G rate per tonne calculation

**Day 4: Mutual Exclusion Logic**
- Crainage allocation toggle (Line Items vs P&G)
- Cherry picker allocation toggle
- Warning/prevention of double-counting
- Auto-update line items when toggle changes

**Day 5: Inclusions/Exclusions UI**
- Tender-level toggle switches
- Line-item override capability
- Visual indicators for overrides
- Recalculation on toggle change

---

## Key Files to Create/Modify

### Models
- `app/models/tender_equipment_selection.rb` - New model
- `app/models/tender_preliminary_item.rb` - New model
- `app/models/tender_inclusions_exclusion.rb` - Enhance existing

### Controllers
- `app/controllers/tender_equipment_selections_controller.rb` - New
- `app/controllers/tender_preliminary_items_controller.rb` - New
- `app/controllers/tender_inclusions_exclusions_controller.rb` - Enhance

### Views
- `app/views/tender_equipment_selections/` - New directory
- `app/views/tender_preliminary_items/` - New directory
- `app/views/tenders/_inclusions_exclusions.html.erb` - New partial

### Stimulus Controllers
- `app/javascript/controllers/equipment_calculator_controller.js` - New
- `app/javascript/controllers/png_calculator_controller.js` - New
- `app/javascript/controllers/inclusion_toggle_controller.js` - New

---

## Testing Scenarios

### Access Equipment Test
1. Add equipment: 2 × Boom 60ft for 3 months
2. Base rate: R25,000, Diesel: R2,500
3. Verify: (R25,000 + R2,500) × 1.06 × 2 × 3 = R174,900
4. Verify rate per tonne: R174,900 / 931.62 = R188 → R190 (R10 rounded)

### P&G Test
1. Add items: Site Est R100,000, Safety File R30,000, Travel R50,000
2. Total P&G: R180,000
3. Verify rate per tonne: R180,000 / 931.62 = R193 → R200 (R50 rounded)

### Mutual Exclusion Test
1. Set "Crainage in P&G" = ON
2. Verify all line item crainage flags = 0
3. Verify P&G shows crainage lump sum
4. Toggle to "Crainage in Line Items"
5. Verify line item crainage flags restored
6. Verify P&G crainage removed

---

## Acceptance Criteria Summary

### Critical (Must Complete)
- [ ] AC-501.1-4: Equipment type selection working
- [ ] AC-502.1-4: Multiple equipment lines working
- [ ] AC-503.1-4: Damage waiver calculation correct
- [ ] AC-505.1-4: Custom P&G items working
- [ ] AC-508.1-5: Mutual exclusion enforced

### High Priority
- [ ] AC-504.1-4: Equipment rate per tonne working
- [ ] AC-506.1-4: P&G templates working
- [ ] AC-507.1-4: P&G rate per tonne calculation working
- [ ] AC-509.1-4: Tender-level toggles working

### Medium Priority
- [ ] AC-510.1-4: Line-item overrides working

---

## Stakeholder Meeting

| Date | Attendees | Purpose | Notes |
|------|-----------|---------|-------|
| Dec 23 (Tue) | Richard, Kody | Weekly sync | Moved from Dec 22 (holiday) |

---

**Week Status:** Pending
**Last Updated:** December 15, 2025
