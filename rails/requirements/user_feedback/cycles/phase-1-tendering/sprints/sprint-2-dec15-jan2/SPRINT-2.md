# Sprint 2: Feature Completion & Integration (Dec 15 - Jan 5)

**Duration:** 3 weeks
**Focus:** Rate engine, equipment selection, P&G items, PDF output
**Goal:** Complete all Phase 1 features to enable end-to-end tender creation
**Status:** IN PROGRESS (Week 4)
**Last Updated:** December 15, 2025

---

## Sprint Status Summary

| Week | Dates | Status | Key Deliverables |
|------|-------|--------|------------------|
| 4 (2a) | Dec 15-22 | 🟡 IN PROGRESS | Rate auto-population, line item templates, rounding rules |
| 5 (2b) | Dec 23-29 | 🔴 PENDING | Access equipment selection, P&G items, inclusions/exclusions |
| 6 (2c) | Dec 30-Jan 5 | 🔴 PENDING | PDF generation, tender summary, final integration |

---

## Sprint Overview

Sprint 2 completes the remaining Phase 1 features, building on the foundation from Sprint 1. We're implementing the rate calculation engine, equipment selection, P&G items, and PDF output to enable end-to-end tender creation.

**Key Outcomes to Achieve:**
- ✅ Rate auto-population from master data
- ✅ Business rule rounding (R50/R20/R10)
- ✅ Category-based line item templates
- ✅ Access equipment costing (non-crane)
- ✅ P&G items with mutual exclusion logic
- ✅ Tender inclusions/exclusions toggles
- ✅ Client-facing PDF generation
- ✅ Permission refinements

---

## Week Breakdown

### Week 4 (Dec 15-22): Rate Engine & Line Item Templates
**Status:** 🟡 IN PROGRESS

**Focus Areas:**
- Rate auto-population engine (material + processing rates)
- Rounding rules (R50 default, R20 crainage, R10 cherry picker)
- Line item templates by category
- Sprint 1 crane calculation rollover

See [week-4.md](week-4.md) for details.

### Week 5 (Dec 23-29): Equipment & P&G
**Status:** 🔴 PENDING

**Focus Areas:**
- Access equipment selection (scissors, booms, telehandlers)
- P&G (Preliminaries & General) items
- Tender-level inclusions/exclusions
- Mutual exclusion logic (crainage/cherry picker in items OR P&G)

See [week-5.md](week-5.md) for details.

### Week 6 (Dec 30-Jan 5): Output & Integration
**Status:** 🔴 PENDING

**Focus Areas:**
- Tender summary page (matching Excel "Page 1")
- PDF generation with RSB branding
- Permission refinements
- Final integration and polish

See [week-6.md](week-6.md) for details.

---

## Sprint 2 Capabilities

### Capability A: Rate Auto-Population Engine
**Epic:** Automatic rate population from master data

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-401 | Material rate auto-fill from material_supply_rates | High |
| UC-402 | Processing rate auto-fill from processing_rates | High |
| UC-403 | Waste percentage application | High |
| UC-404 | Blended material cost calculation | High |

### Capability B: Rounding Rules Engine
**Epic:** Business rule rounding applied to all calculations

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-405 | Standard rate rounding (R50) | High |
| UC-406 | Crainage rate rounding (R20) | High |
| UC-407 | Cherry picker/corrosion protection rounding (R10) | High |

### Capability C: Line Item Templates
**Epic:** Pre-configured defaults by steel category

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-408 | Category-based material defaults | High |
| UC-409 | Category-based rate build-up defaults | Medium |
| UC-410 | Tender-level rate override page | Medium |

### Capability D: Access Equipment Selection
**Epic:** Non-crane equipment costing

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-501 | Equipment type selection from catalog | High |
| UC-502 | Multiple equipment selections per tender | High |
| UC-503 | Damage waiver calculation (6%) | High |
| UC-504 | Equipment cost per tonne distribution | High |

### Capability E: P&G (Preliminaries & General)
**Epic:** Custom preliminary items with rate distribution

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-505 | Add custom P&G items | High |
| UC-506 | Standard P&G item templates | Medium |
| UC-507 | P&G rate per tonne calculation | High |
| UC-508 | Crainage/equipment mutual exclusion | High |

### Capability F: Tender Inclusions/Exclusions
**Epic:** Tender-level configuration toggles

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-509 | Tender-level inclusion toggles | High |
| UC-510 | Line-item level overrides | Medium |

### Capability G: Tender Summary Page
**Epic:** Final tender overview matching Excel "Page 1"

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-601 | Tender summary view | High |
| UC-602 | Section headers and subtotals | High |
| UC-603 | Grand total and tonnage | High |

### Capability H: PDF Generation
**Epic:** Client-facing tender document

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-604 | Generate tender PDF | High |
| UC-605 | RSB branding and formatting | High |
| UC-606 | Validity period display | Medium |

### Capability I: Permission Refinements
**Epic:** Role-based access enforcement

| Use Case ID | Description | Priority |
|-------------|-------------|----------|
| UC-607 | Material supply rate editing restricted | High |
| UC-608 | Supplier selection restricted | High |

---

## Implementation Status by Feature

### A. Rate Engine
| Task | Status |
|------|--------|
| Material rate auto-fill | 🔴 Pending |
| Waste percentage application | 🔴 Pending |
| Processing rate auto-fill | 🔴 Pending |
| Blended material calculation | 🔴 Pending |
| R50 rounding (line items) | 🔴 Pending |
| R20 rounding (crainage) | 🔴 Pending |
| R10 rounding (cherry picker) | 🔴 Pending |
| CFLC fabrication = 0 rule | 🔴 Pending |

### B. Line Item Templates
| Task | Status |
|------|--------|
| Category material defaults | 🔴 Pending |
| Category inclusion defaults | 🔴 Pending |
| Tender-level rate override | 🔴 Pending |

### C. Access Equipment
| Task | Status |
|------|--------|
| Equipment types seeded | ✅ Complete |
| Equipment selection UI | 🔴 Pending |
| Multiple equipment lines | 🔴 Pending |
| Damage waiver (6%) calc | 🔴 Pending |
| Equipment rate per tonne | 🔴 Pending |

### D. P&G Items
| Task | Status |
|------|--------|
| P&G model | ✅ Complete |
| Add custom P&G items | 🔴 Pending |
| Standard P&G templates | 🔴 Pending |
| P&G rate per tonne calc | 🔴 Pending |
| Mutual exclusion logic | 🔴 Pending |

### E. Inclusions/Exclusions
| Task | Status |
|------|--------|
| Inclusions model | ✅ Complete |
| Tender-level toggles UI | 🔴 Pending |
| Line-item overrides | 🔴 Pending |

### F. Tender Output
| Task | Status |
|------|--------|
| Summary page view | 🔴 Pending |
| Section headers/subtotals | 🔴 Pending |
| PDF generation | 🔴 Pending |
| RSB branding | 🔴 Pending |

### G. Permissions
| Task | Status |
|------|--------|
| Material rate edit restriction | 🔴 Pending |
| Supplier selection restriction | 🔴 Pending |

---

## Rollover from Sprint 1

**Crane Calculations (must complete first):**
| Task | Status |
|------|--------|
| Program duration auto-calc | 🔴 Pending |
| Crane complement auto-lookup | 🔴 Pending |
| Wet rate auto-fill | 🔴 Pending |
| Total crane cost calculation | 🔴 Pending |
| Crainage rate per tonne | 🔴 Pending |

---

## Testing Period (Jan 5-19)

### Test Approach
After Sprint 2 completion, a 2-week testing period focuses on:
- Recreating real tenders (DeMarco, Suzuki) in the new system
- Comparing output to Excel originals
- Documenting and fixing critical bugs
- No new features during this period

### Test Tenders
1. **DeMarco** - Converted project (known good outcome)
2. **Suzuki** - Recent tender with complete workings
3. Additional tenders from Richard's historical data

### Success Criteria
- [ ] System produces identical rates to Excel for test tenders
- [ ] PDF output matches current deliverable format
- [ ] End-to-end workflow completes without errors
- [ ] Demi and Richard can use system without assistance

---

## Stakeholder Meetings

| Date | Attendees | Purpose | Notes |
|------|-----------|---------|-------|
| Dec 15 (Mon) | Richard, Kody | Sprint 1 wrap-up | ✅ Completed - Sprint 2 priorities confirmed |
| Dec 19 (Thu) | Demi, Kody | Sprint 2 kickoff | Scheduled 6pm SAST |
| Dec 23 (Tue) | Richard, Kody | Weekly sync | Moved from Dec 22 (father-in-law's birthday) |
| Jan 8 (Wed) | Demi, Kody | Testing period kickoff | First meeting after holiday |

---

## Key Insights from Dec 15 Richard Meeting

### Sprint 2 Priorities Confirmed
- **Project-level buildups** (rates page) - material supply rates at tender level
- **P&G items** - preliminary items with lump sums
- **Inclusions/exclusions** - tender and line item level toggles
- **Access equipment** - non-crane equipment selection
- **Tender line item templates** - category-based defaults
- **PDF output** - client-facing tender document

### Permission Requirements
- Only Richard, Ruan, Maria can edit material_supply_rates
- Only Richard, Ruan, Maria can change supplier checkbox selections
- Demi can override rates at tender level only

### Testing Approach
- Use DeMarco (converted project) and Suzuki as primary test tenders
- Richard sending 5+ historical tender examples for testing
- Testing period Jan 5-19 with Demi and Richard
- Go-live target: Jan 19, 2026

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Holiday availability (Dec 23-Jan 2) | Medium | Front-load critical work in Week 4 |
| PDF generation complexity | Medium | Research gems early (Prawn, wicked_pdf) |
| Testing data availability | Low | Richard sending tender examples |
| Rate calculation edge cases | Medium | Test against Excel formulas early |

---

## Key Files & Controllers

### Existing (from Sprint 1)
- `TendersController` - Tender CRUD, builder
- `TenderLineItemsController` - Line item CRUD
- `OnSiteMobileCraneBreakdownsController` - Crane breakdown
- `MaterialSuppliesController` - Material CRUD

### New for Sprint 2
- `TenderEquipmentSelectionsController` - Access equipment
- `TenderPreliminaryItemsController` - P&G items
- `TenderInclusionsExclusionsController` - Toggle management
- `TenderPdfsController` - PDF generation

### Stimulus Controllers
- `rate_calculator_controller.js` - Rate calculations (enhance)
- `rounding_controller.js` - Business rule rounding (new)
- `equipment_calculator_controller.js` - Equipment costs (new)

---

**Sprint Status:** In Progress (Week 4 of 3)
**Last Updated:** December 15, 2025
