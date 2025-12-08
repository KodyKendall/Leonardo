# Phase 1: RSB Tendering System - Scope Document

**Timeline:** 6 weeks (2 sprints of 3 weeks each)
**Sprint 1:** Nov 24 - Dec 12 (3 weeks)
**Sprint 2:** Dec 15 - Jan 2 (3 weeks)
**Status:** IN PROGRESS (Week 3 of 6)
**Document Version:** 1.1
**Last Updated:** December 8, 2025

---

## Implementation Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **A. BOQ Import & Setup** | 🟡 Partial | Upload works, AI parsing needs refinement |
| **B. Rate Management** | 🟢 Complete | Material supplies, suppliers, rates CRUD done |
| **C. Tender Configuration** | 🟡 Partial | Inclusions/exclusions UI built, crane breakdown in progress |
| **D. Line Item Rate Build-Up** | 🟡 Partial | UI complete, auto-calculations pending |
| **E. P&G (Preliminaries)** | 🔴 Not Started | Planned for Sprint 2 |
| **F. Tender Output** | 🔴 Not Started | Planned for Sprint 2 |

See [Vertical Slice Scopes](#vertical-slice-scopes) for detailed breakdown of remaining work.

---

## 1. Overview & Objectives

Replace RSB's manual Excel-based tendering workflow with a unified, reliable system that eliminates human error, standardizes calculations, and reduces tender preparation time from 2-3 hours to 30-60 minutes per tender.

### Key Goals
- Centralize all tender data into one system
- Eliminate manual calculations and spreadsheet errors
- Reduce tender preparation time by 50%
- Standardize rates, rules, and configurations
- Create the foundation for budget tracking and claims in future phases

### Success Metrics

| Metric | Target |
|--------|--------|
| Tender preparation time | 30-60 minutes per tender (vs 2-3 hours) |
| Calculation errors | Zero |
| Rate update time | Single update propagates automatically |
| Training time | 2-3 days (vs 2-4 weeks) |
| Tender throughput | 4+ BOQs per day |

---

## 2. What We Are Building in Phase 1

### A. BOQ Import & Setup
- Upload BOQ (CSV)
- AI-assisted parsing of line items (page, item, description, unit, qty)
- Editable review screen before finalizing

### B. Rate Management
- Material supply rate updates (monthly)
- Processing rate updates (annually)
- Automatic versioning of all rate changes
- Default "second cheapest" supplier selection, with override

### C. Tender Configuration
- Inclusions/exclusions toggles (fabrication, erection, bolts, delivery, etc.)
- On-site parameters: roof area, erection rate, crane requirements
- Equipment selection (booms, scissors, telehandlers)
- Tender-level margin setting

### D. Line Item Rate Build-Up
- Automatic calculation of full rate per tonne
- Material breakdown (UB/UC, plate %, CFLC rules, etc.)
- Extra overs (castellating, curving, MPI, weld testing)
- Per-line overrides where needed
- Correct rounding rules (R50, R20, R10) applied automatically

### E. P&G (Preliminaries & General)
- Add custom P&G items (site establishment, accommodation, etc.)
- Automatic rate-per-tonne distribution
- Logic preventing double-counting with crainage/cherry pickers

### F. Tender Output
- Final tender summary page
- Section headers, subtotals, tonnage totals
- Generate client-facing PDF with RSB branding
- Submit tender + status tracking

---

## 3. What's NOT Included in Phase 1

These are planned for later phases:

- Budget tracking
- Claims processing
- Project execution tracking
- Supplier integrations / EDI
- Mobile application
- Multi-company support
- Automatic bolt threshold logic
- AI-assisted material type classification
- Accounting system integrations

---

## 4. Database Schema (REQUIRED)

### Master Data Tables

#### suppliers
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| name | string | NOT NULL |
| contact_person | string | |
| email | string | |
| phone | string | |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

#### material_supplies
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| code | string | NOT NULL, unique |
| name | string | NOT NULL |
| category | string | (sections, plate, gutters, etc.) |
| base_rate_per_tonne | decimal | NOT NULL |
| waste_percentage | decimal | DEFAULT 0.075 |
| effective_from | date | NOT NULL |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

#### material_supply_rates
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| material_supply_id | bigint | FK to material_supplies |
| supplier_id | bigint | FK to suppliers |
| rate_per_tonne | decimal | NOT NULL |
| effective_from | date | NOT NULL |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

#### processing_rates
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| code | string | NOT NULL, unique |
| name | string | NOT NULL |
| base_rate_per_tonne | decimal | NOT NULL |
| work_type | string | (structural, platework, piping) |
| factor | decimal | DEFAULT 1.0 |
| is_active | boolean | DEFAULT true |
| effective_from | date | NOT NULL |
| created_at | datetime | |
| updated_at | datetime | |

#### equipment_types
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| category | string | NOT NULL |
| model | string | NOT NULL |
| working_height_m | decimal | |
| base_rate_monthly | decimal | NOT NULL |
| damage_waiver_pct | decimal | DEFAULT 0.06 |
| diesel_allowance_monthly | decimal | |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

#### crane_rates
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| size | string | NOT NULL |
| ownership_type | string | (owned, rental) |
| dry_rate_per_day | decimal | NOT NULL |
| diesel_per_day | decimal | |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

#### crane_complements
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| area_min_sqm | decimal | NOT NULL |
| area_max_sqm | decimal | NOT NULL |
| complement_description | string | NOT NULL |
| default_wet_rate_per_day | decimal | NOT NULL |
| created_at | datetime | |
| updated_at | datetime | |

#### extra_over_types
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| code | string | NOT NULL, unique |
| name | string | NOT NULL |
| default_rate | decimal | NOT NULL |
| default_factor | decimal | |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

#### galvanizing_rates
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| base_dip_rate | decimal | NOT NULL |
| zinc_mass_factor | decimal | DEFAULT 0.075 |
| fettling_per_tonne | decimal | |
| delivery_per_tonne | decimal | |
| effective_from | date | NOT NULL |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

### Transactional Data Tables

#### clients
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| name | string | NOT NULL |
| contact_person | string | |
| email | string | |
| phone | string | |
| address | string | |
| is_active | boolean | DEFAULT true |
| created_at | datetime | |
| updated_at | datetime | |

#### tenders
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_number | string | NOT NULL, unique |
| project_name | string | NOT NULL |
| client_id | bigint | FK to clients |
| created_by_id | bigint | FK to users |
| assigned_to_id | bigint | FK to users |
| tender_date | date | NOT NULL |
| expiry_date | date | |
| project_type | string | (commercial, mining) |
| margin_pct | decimal | DEFAULT 0.0 |
| status | string | (draft, in_progress, ready_for_review, approved, submitted, won, lost) |
| notes | text | |
| total_tonnage | decimal | |
| subtotal_amount | decimal | |
| grand_total | decimal | |
| created_at | datetime | |
| updated_at | datetime | |

#### tender_inclusions_exclusions
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_id | bigint | FK to tenders |
| include_fabrication | boolean | DEFAULT true |
| include_overheads | boolean | DEFAULT true |
| include_shop_priming | boolean | DEFAULT false |
| include_onsite_painting | boolean | DEFAULT false |
| include_delivery | boolean | DEFAULT true |
| include_bolts | boolean | DEFAULT true |
| include_erection | boolean | DEFAULT true |
| include_crainage | boolean | DEFAULT false |
| include_cherry_picker | boolean | DEFAULT false |
| include_galvanizing | boolean | DEFAULT false |
| created_at | datetime | |
| updated_at | datetime | |

#### tender_on_site_breakdown
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_id | bigint | FK to tenders |
| total_roof_area_sqm | decimal | |
| erection_rate_sqm_per_day | decimal | |
| splicing_crane_required | boolean | DEFAULT false |
| splicing_crane_size | string | |
| splicing_crane_days | integer | |
| misc_crane_required | boolean | DEFAULT false |
| misc_crane_size | string | |
| misc_crane_days | integer | |
| program_duration_days | integer | |
| created_at | datetime | |
| updated_at | datetime | |

#### tender_line_items
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_id | bigint | FK to tenders |
| page_number | integer | |
| item_number | integer | |
| description | string | NOT NULL |
| unit | string | DEFAULT 't' |
| quantity | decimal | NOT NULL |
| category | string | |
| line_type | string | (standard, bolt, anchor, gutter, pg, shop_drawings, provisional) |
| section_header | string | |
| rate_per_unit | decimal | |
| line_amount | decimal | |
| margin_amount | decimal | |
| sort_order | integer | |
| created_at | datetime | |
| updated_at | datetime | |

#### line_item_rate_build_ups
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_line_item_id | bigint | FK to tender_line_items |
| material_supply_rate | decimal | |
| fabrication_rate | decimal | |
| fabrication_factor | decimal | DEFAULT 1.0 |
| fabrication_included | boolean | DEFAULT true |
| overheads_rate | decimal | |
| overheads_included | boolean | DEFAULT true |
| shop_priming_rate | decimal | |
| shop_priming_included | boolean | DEFAULT false |
| onsite_painting_rate | decimal | |
| onsite_painting_included | boolean | DEFAULT false |
| delivery_rate | decimal | |
| delivery_included | boolean | DEFAULT true |
| bolts_rate | decimal | |
| bolts_included | boolean | DEFAULT true |
| erection_rate | decimal | |
| erection_included | boolean | DEFAULT true |
| crainage_rate | decimal | |
| crainage_included | boolean | DEFAULT false |
| cherry_picker_rate | decimal | |
| cherry_picker_included | boolean | DEFAULT false |
| galvanizing_rate | decimal | |
| galvanizing_included | boolean | DEFAULT false |
| subtotal | decimal | |
| margin_amount | decimal | |
| total_before_rounding | decimal | |
| rounded_rate | decimal | |
| created_at | datetime | |
| updated_at | datetime | |

#### line_item_materials
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_line_item_id | bigint | FK to tender_line_items |
| material_supply_id | bigint | FK to material_supplies |
| proportion | decimal | NOT NULL |
| created_at | datetime | |
| updated_at | datetime | |

#### line_item_extra_overs
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_line_item_id | bigint | FK to tender_line_items |
| extra_over_type_id | bigint | FK to extra_over_types |
| is_included | boolean | DEFAULT false |
| rate_override | decimal | |
| factor_override | decimal | |
| created_at | datetime | |
| updated_at | datetime | |

#### tender_crane_selections
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_id | bigint | FK to tenders |
| crane_rate_id | bigint | FK to crane_rates |
| quantity | integer | NOT NULL |
| purpose | string | (main, splicing, miscellaneous) |
| duration_days | integer | NOT NULL |
| total_cost | decimal | |
| created_at | datetime | |
| updated_at | datetime | |

#### tender_equipment_selections
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_id | bigint | FK to tenders |
| equipment_type_id | bigint | FK to equipment_types |
| units_required | integer | NOT NULL |
| period_months | integer | NOT NULL |
| purpose | string | |
| monthly_cost_override | decimal | |
| total_cost | decimal | |
| created_at | datetime | |
| updated_at | datetime | |

#### tender_preliminary_items
| Field | Type | Constraints |
|-------|------|-------------|
| id | bigint | PK |
| tender_id | bigint | FK to tenders |
| item_code | string | |
| description | string | NOT NULL |
| calculation_notes | text | |
| lump_sum_amount | decimal | NOT NULL |
| rate_per_tonne | decimal | |
| is_included | boolean | DEFAULT true |
| sort_order | integer | |
| created_at | datetime | |
| updated_at | datetime | |

---

## 5. UI Composition & Scaffolding

### Screen Hierarchy

```
Tenders Index (/tenders)
    |
    +-- Tender Show (/tenders/:id)
            |
            +-- BOQ Upload (/tenders/:id/boq)
            +-- Line Items (/tenders/:id/line_items)
            +-- Tender Configuration (/tenders/:id/configuration)
            +-- P&G Items (/tenders/:id/preliminary_items)
            +-- Tender Output (/tenders/:id/output)
```

### Key Views

#### Tenders Index
- Lists all tenders with status, client, total, submission date
- Filters by status, client, date range
- Quick actions: create, view, edit, submit

#### Tender Show
- Main tender dashboard
- Displays: tender number, project name, client, status
- Navigation to BOQ, configuration, line items, P&G, output

#### BOQ Upload
- File upload (CSV)
- AI parsing preview
- Editable grid for line item review

#### Line Items
- Table view of all line items with descriptions, units, quantities
- Expandable detail rows showing rate build-up
- Inline editing for quantities, categories, materials
- Add/remove line items

#### Tender Configuration
- Inclusions/exclusions toggle switches
- On-site parameters (roof area, erection rate)
- Crane selection
- Equipment selection with modal
- Margin setting

#### P&G Items
- List of preliminary items
- Add custom items with lump sums
- Display calculated rate per tonne

#### Tender Output
- Summary page showing final calculations
- Section totals, tonnage, grand total
- Generate PDF button
- Submit tender workflow

---

## 6. Calculations & Business Rules

### Core Calculations

**Material Supply Cost:**
```
material_supply_rate_with_waste = base_rate_per_tonne × (1 + waste_percentage) × proportion
```

**Line Item Rate Build-up:**
```
line_rate = material_supply_rate + (fabrication_rate × fabrication_factor × include_fabrication) 
          + (overheads_rate × include_overheads) + ... + (galvanizing_rate × include_galvanizing)
subtotal = line_rate
margin = subtotal × margin_pct
total_before_rounding = subtotal + margin
rounded_rate = CEILING(total_before_rounding, 50)
line_amount = rounded_rate × quantity
```

**Equipment Cost:**
```
monthly_cost = base_rate_monthly × (1 + damage_waiver_pct) + diesel_allowance_monthly
total_equipment_cost = monthly_cost × units × months
equipment_rate_per_tonne = total_equipment_cost / total_tonnage
```

**Crainage Rate:**
```
program_duration = CEILING(total_roof_area / erection_rate_sqm_day, 1)
main_crane_cost = wet_rate_per_day × program_duration
total_crane_cost = main_crane_cost + splicing_cost + misc_cost
crainage_rate_per_tonne = CEILING(total_crane_cost / total_tonnage, 20)
```

**P&G Rate:**
```
pg_rate_per_tonne = (lump_sum_amount / total_tonnage)
rounded_pg_rate = CEILING(pg_rate_per_tonne, 50)
```

### Business Rules

| Rule | Description |
|------|-------------|
| BR-001 | Rate Rounding: All line item rates rounded up to nearest R50 |
| BR-002 | Crainage Rounding: Crainage rate rounded to nearest R20 |
| BR-003 | Cherry Picker Rounding: Cherry picker rate rounded to nearest R10 |
| BR-004 | Waste Application: Waste % applied to base material rate before aggregation |
| BR-005 | Toggle Application: Boolean flags multiply rate by 0 or 1 |
| BR-006 | Margin Calculation: Applied to subtotal before rounding |
| BR-007 | CFLC Fabrication: CFLC and cold-rolled items always have fabrication = 0 |
| BR-008 | Lump Sum Distribution: Fixed costs divided by total tonnage |
| BR-009 | Damage Waiver: Access equipment always includes 6% damage waiver |
| BR-010 | Crane Mutual Exclusion: Crainage included in line items OR P&G, not both |
| BR-011 | Material Proportions: Must sum to exactly 100% |
| BR-012 | Fabrication Multiplier: Different work types (structural, platework, piping) use factors |

---

## 7. Roles & Permissions

| Permission | Admin | QS | Buyer | Office Staff |
|------------|-------|-----|-------|--------------|
| Create tender | Yes | Yes | No | Yes |
| Edit tender | Yes | Yes | No | Limited |
| View tender | Yes | Yes | Yes | Yes |
| Submit tender | Yes | Yes | No | No |
| Edit inclusions | Yes | Yes | No | No |
| Edit rates | Yes | No | Yes | No |
| View rates | Yes | Yes | Yes | Yes |

---

## 8. Open Questions & Assumptions

### Open Questions

| Question | Status |
|----------|--------|
| Approval threshold for director sign-off? | Pending |
| Multi-currency or ZAR only? | Assumed ZAR only |
| BOQ size limit handling? | Leonardo API: 50 items currently |
| Should BOQ templates be created for common types? | Pending |

### Assumptions

- All users have internet access
- Currency is ZAR only
- BOQs provided as CSV or manual entry
- 6% damage waiver is constant
- Processing rates update annually
- Material rates update monthly
- Tender validity default 30 days
- Single QS reviews each tender
- No integration with external systems in Phase 1

---

## 9. Sprint Planning Overview

### Sprint 1: Core Foundations (Nov 24 - Dec 12)
**Focus:** BOQ import, tender builder scaffolding, rate calculations, crane equipment

- Week 1a: BOQ Parsing + Tender Builder Scaffolding (Rate Buildups & Material Breakdowns)
- Week 1b: Tender Builder Calculations + Crane Rate Scaffolding
- Week 1c: All Tender Level Inputs for Builder, P&Gs, Inclusions/Exclusions

**Deliverables:** BOQ can be uploaded, parsed, configured with materials and rates, and scaffolding ready for calculation engine

### Sprint 2: Material Supply & Iteration (Dec 15 - Jan 2)
**Focus:** Material supply rates, templates, testing, and iteration

- Week 2a: Material Supply Rates
- Week 2b: Material_Supply Templates
- Week 2c: Rapid Iteration, Testing, & Debugging

**Deliverables:** Material supply workflow complete, system tested and refined, ready for production

---

---

## 10. Vertical Slice Scopes

The remaining work is organized into thin, full-stack vertical slices that can be built and demoed independently.

### Active Vertical Slices (Week 3)

| Slice | Scope Doc | Priority | Est. Days |
|-------|-----------|----------|-----------|
| BOQ Parsing Improvements | [BOQ_PARSING_SCOPE.md](BOQ_PARSING_SCOPE.md) | High | 2-3 |
| Rate Auto-Population | [RATE_AUTOPOPULATION_SCOPE.md](RATE_AUTOPOPULATION_SCOPE.md) | High | 2-3 |
| Crane Cost Calculations | [CRANE_CALC_SCOPE.md](CRANE_CALC_SCOPE.md) | High | 2-3 |
| UX/Turbo Fixes | [UX_FIXES_SCOPE.md](UX_FIXES_SCOPE.md) | High | 1-2 |

### Planned Vertical Slices (Sprint 2)

| Slice | Scope Doc | Priority | Est. Days |
|-------|-----------|----------|-----------|
| P&G Configuration | TBD | Medium | 2-3 |
| Equipment Selection | TBD | Medium | 2-3 |
| Tender PDF Output | TBD | Medium | 2-3 |
| Rounding Rules Engine | TBD | Medium | 1-2 |

### Completed Vertical Slices

| Slice | Completed | Notes |
|-------|-----------|-------|
| Tender Builder SPA | Week 1a | Line items, materials, rate build-up UI |
| User Authentication | Week 1b | Devise, roles, permissions |
| Master Data CRUD | Week 1a-1b | Suppliers, materials, rates |
| BOQ Upload | Week 1b | CSV upload, preview, header detection |

---

**Document Status:** In Progress
**Last Updated:** December 8, 2025
