# Sprint 1: Core Foundations (Nov 24 - Dec 12)

**Duration:** 3 weeks
**Focus:** Database setup, authentication, tender builder, BOQ import, crane breakdown
**Goal:** Full tender builder with line items, materials, rate build-ups, and crane configuration
**Status:** IN PROGRESS (Week 3)
**Last Updated:** December 8, 2025

---

## Sprint Status Summary

| Week | Dates | Status | Key Deliverables |
|------|-------|--------|------------------|
| 1 | Nov 24-28 | ✅ COMPLETE | Database, seed data, Tender Builder SPA |
| 2 | Dec 1-5 | ✅ COMPLETE | Authentication, roles, BOQ upload |
| 3 | Dec 8-12 | 🟡 IN PROGRESS | BOQ parsing, crane calculations, rate engine |

---

## Sprint Overview

Sprint 1 establishes the foundational infrastructure for the RSB Tendering System. We've built the database schema, user authentication, Tender Builder SPA with line items and rate build-ups, BOQ upload and parsing, and crane breakdown UI.

**Key Outcomes Achieved:**
- ✅ Users can log in with email/password and role-based access
- ✅ Tenders can be created with E-number auto-generation
- ✅ Line items can be added with rate build-up and material breakdown
- ✅ BOQ can be uploaded, parsed by AI, and transferred to builder
- ✅ Crane breakdown UI with crane selection interface
- 🟡 Rate auto-population from master data (in progress)
- 🟡 Crane cost calculations (in progress)

---

## Week Breakdown

### Week 1 (Nov 24-28): Database & Tender Builder SPA
**Status:** ✅ COMPLETE

**Delivered:**
- All master data tables (suppliers, materials, rates, cranes, equipment)
- Seed data with 22 material types, processing rates, crane rates
- Tender Builder SPA with Hotwire (Turbo + Stimulus)
- Line Items CRUD with nested forms
- Rate Build-up component with 11 rate categories
- Material Breakdown component with add/remove functionality
- Real-time calculations via Stimulus controllers

See [week-1.md](week-1.md) for details.

### Week 2 (Dec 1-5): Authentication & BOQ Upload
**Status:** ✅ COMPLETE

**Delivered:**
- Devise authentication with email/password
- Role-based access (Admin, QS, Office Staff, Buyer)
- Seeded users: Richard (admin), Demi (QS), Elmarie (office staff)
- Client and Tender models with CRUD
- BOQ upload with CSV preview and header detection
- BOQ model with status tracking

See [week-2.md](week-2.md) for details.

### Week 3 (Dec 8-12): BOQ Parsing, Crane Calculations, Rate Engine
**Status:** 🟡 IN PROGRESS

**Delivered:**
- AI-powered BOQ parsing via LlamaBot
- BOQ review grid with category editing
- Transfer to Builder workflow
- On-site crane breakdown UI
- Crane selection interface with add/remove

**In Progress (Vertical Slices):**
| Slice | Scope Doc | Priority | Est. Days |
|-------|-----------|----------|-----------|
| UX/Turbo Fixes | [UX_FIXES_SCOPE.md](../../scopes/UX_FIXES_SCOPE.md) | High | 1-2 |
| BOQ Parsing Fixes | [BOQ_PARSING_SCOPE.md](../../scopes/BOQ_PARSING_SCOPE.md) | High | 1-2 |
| Rate Auto-Population | [RATE_AUTOPOPULATION_SCOPE.md](../../scopes/RATE_AUTOPOPULATION_SCOPE.md) | High | 2-3 |
| Crane Cost Calculations | [CRANE_CALC_SCOPE.md](../../scopes/CRANE_CALC_SCOPE.md) | High | 2-3 |

See [week-3.md](week-3.md) for details.

---

## Implementation Status by Feature

### A. Database & Master Data
| Task | Status |
|------|--------|
| Suppliers table & CRUD | ✅ Complete |
| Material supplies (22 types) | ✅ Complete |
| Material supply rates | ✅ Complete |
| Processing rates | ✅ Complete |
| Crane rates (7 sizes × 2 types) | ✅ Complete |
| Crane complements lookup | ✅ Complete |
| Equipment types | ✅ Complete |
| Extra over types | ✅ Complete |
| Seed data loaded | ✅ Complete |

### B. Authentication & Authorization
| Task | Status |
|------|--------|
| Devise authentication | ✅ Complete |
| Role enum (admin, qs, office_staff, buyer) | ✅ Complete |
| Test users seeded | ✅ Complete |
| Login/logout workflow | ✅ Complete |
| Role-based permissions | 🟡 Partial (roles exist, not fully enforced) |

### C. Tender Management
| Task | Status |
|------|--------|
| Tender model with E-number | ✅ Complete |
| Client model | ✅ Complete |
| Tender CRUD views | ✅ Complete |
| Tender status workflow | ✅ Complete |
| Inclusions/exclusions model | ✅ Complete |

### D. Tender Builder (SPA)
| Task | Status |
|------|--------|
| Builder hub page | ✅ Complete |
| Line items CRUD | ✅ Complete |
| Rate build-up UI (11 components) | ✅ Complete |
| Material breakdown UI | ✅ Complete |
| Add/remove materials | ✅ Complete |
| Inline editing | ✅ Complete |
| Real-time subtotal calculation | ✅ Complete |
| Material rate auto-fill | 🔴 Pending |
| Processing rate auto-fill | 🔴 Pending |
| Rounding logic (R50/R20/R10) | 🔴 Pending |
| CFLC fabrication auto-zero | 🔴 Pending |

### E. BOQ Upload & Parsing
| Task | Status |
|------|--------|
| CSV upload with ActiveStorage | ✅ Complete |
| CSV preview with header detection | ✅ Complete |
| AI parsing via LlamaBot | ✅ Complete |
| BOQ review grid | ✅ Complete |
| Category editing | ✅ Complete |
| Transfer to Builder | ✅ Complete |
| Item count display fix | 🔴 Bug |
| Large BOQ handling (>25 items) | 🔴 Pending |

### F. Crane Breakdown
| Task | Status |
|------|--------|
| On-site breakdown model | ✅ Complete |
| Breakdown UI with inline edit | ✅ Complete |
| Crane rates table display | ✅ Complete |
| Crane selection CRUD | ✅ Complete |
| Program duration auto-calc | 🔴 Pending |
| Crane complement auto-lookup | 🔴 Pending |
| Wet rate auto-fill | 🔴 Pending |
| Total cost calculation | 🔴 Pending |
| Crainage rate per tonne | 🔴 Pending |

---

## Known Issues & Bugs

| Issue | Severity | Status | Scope Doc |
|-------|----------|--------|-----------|
| Page refresh on Add Material | High | Open | [UX_FIXES_SCOPE.md](../../scopes/UX_FIXES_SCOPE.md) |
| Page refresh on Save Changes | High | Open | [UX_FIXES_SCOPE.md](../../scopes/UX_FIXES_SCOPE.md) |
| BOQ count shows wrong number | Medium | Open | [BOQ_PARSING_SCOPE.md](../../scopes/BOQ_PARSING_SCOPE.md) |
| "Qty" should be "Proportion" | Medium | Open | [UX_FIXES_SCOPE.md](../../scopes/UX_FIXES_SCOPE.md) |
| "Rsb owned" capitalization | Low | Open | [UX_FIXES_SCOPE.md](../../scopes/UX_FIXES_SCOPE.md) |

---

## Acceptance Criteria

### Week 1a ✅
- [x] All master data tables created with correct schema
- [x] Seed data loaded successfully
- [x] Tender Builder SPA functional
- [x] Line items can be added/edited/deleted
- [x] Rate build-up UI displays all 11 components

### Week 1b ✅
- [x] User model with Devise authentication working
- [x] Test users created with different roles
- [x] Users can log in with email/password
- [x] Tenders CRUD working
- [x] BOQ file upload working
- [x] CSV preview displays correctly

### Week 1c 🟡
- [x] AI parsing extracts line items from BOQ
- [x] Parsed items display in editable grid
- [x] Transfer to Builder creates line items
- [x] Crane breakdown UI functional
- [ ] Material rates auto-populate from lookup
- [ ] Processing rates auto-populate
- [ ] Crane costs calculate correctly
- [ ] Rounding rules apply correctly

---

## Rollover to Sprint 2

**Moving to Sprint 2:**
- P&G (Preliminaries & General) configuration
- Equipment selection (non-crane: booms, scissors, telehandlers)
- Tender PDF output
- Approval workflows

**Carrying into Sprint 2 if not completed this week:**
- Rate auto-population (if not done by Dec 12)
- Crane cost calculations (if not done by Dec 12)
- Large BOQ handling

---

## Key Files & Controllers

### Controllers
- `TendersController` - Tender CRUD, builder
- `TenderLineItemsController` - Line item CRUD
- `BoqsController` - BOQ upload, parsing, transfer
- `OnSiteMobileCraneBreakdownsController` - Crane breakdown
- `TenderCraneSelectionsController` - Crane selection CRUD
- `MaterialSuppliesController` - Material CRUD

### Stimulus Controllers
- `nested_form_controller.js` - Add/remove nested records
- `rate_calculator_controller.js` - Real-time rate calculation
- `line_item_rate_build_up_controller.js` - Rate build-up calculations
- `collapsible_controller.js` - Toggle sections
- `dirty_form_controller.js` - Track unsaved changes

### Key Views
- `app/views/tenders/builder.html.erb` - Main builder hub
- `app/views/tender_line_items/_form.html.erb` - Line item form
- `app/views/line_item_rate_build_ups/_fields.html.erb` - Rate grid
- `app/views/line_item_materials/_fields.html.erb` - Material row
- `app/views/boqs/show.html.erb` - BOQ review
- `app/views/on_site_mobile_crane_breakdowns/builder.html.erb` - Crane UI

---

## Stakeholder Feedback (Dec 8)

**From Richard Spencer:**
- Goal: Replace Elmarie on tendering with AI categorization
- Ready to provide real BOQs for testing
- Can supply historical tender data for AI training
- Next meeting: Monday Dec 15 at 8pm SAST

**From Demo Session:**
- UX issues with page refresh need fixing
- BOQ parsing works but count display is wrong
- Crane UI looks good, needs calculation logic
- Material breakdown label "Qty" is confusing

---

**Sprint Status:** In Progress (Week 3 of 3)
**Last Updated:** December 8, 2025
