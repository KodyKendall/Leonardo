# Tender Builder — MVP Handover

## Overview & Goals

You now have a fully functional **Tender Builder** interface that allows users to view, edit, and manage tender line items with their associated rate build-ups and material breakdowns. The builder displays rate components (fabrication, materials, delivery, etc.) and material costs side-by-side with automatic totals calculation.

**Target user:** Project managers building and pricing tenders with detailed cost breakdowns.

### Out of Scope (MVP)
- Add/create new line items (routes exist but UI not built)
- Margin % calculations with automatic total updates
- Export to PDF/Excel
- Approval workflows
- Revision history/change tracking

### High-level Acceptance Criteria
- ✅ Navigate to `/tenders/:id/builder` and see all tender line items
- ✅ Expand each line item to view Rate Build-Up (left) and Material Breakdown (right)
- ✅ View editable rows for each material with thickness, rate, quantity, and calculated line total
- ✅ View 11 rate components (Material Supply, Fabrication, Overheads, etc.) with included/excluded checkboxes
- ✅ Grand total calculates from all line item totals
- ✅ Sample data pre-seeded for immediate testing

---

## Environment & Versions

- **Ruby:** 3.3.x
- **Rails:** 7.2.2.1
- **Database:** PostgreSQL
- **CSS:** Tailwind CSS + Daisy UI components
- **Icons:** Font Awesome
- **Key gems (no new additions):** Devise, Turbo Rails, Action Text

---

## Architecture Summary

### Data Model
- **Tender** (parent) → has_many :tender_line_items
- **TenderLineItem** (line item) → has_one :line_item_rate_build_up, has_one :line_item_material_breakdown
- **LineItemRateBuildUp** (rate components) → belongs_to :tender_line_item, stores 11 rate fields + toggles
- **LineItemMaterialBreakdown** (materials) → has_many :line_item_materials, belongs_to :tender_line_item
- **LineItemMaterial** (material row) → belongs_to :line_item_material_breakdown, material_supply; stores thickness, rate, quantity

### Controllers & Routes
- **TendersController#builder** — Load tender with line items, rate build-ups, and material breakdowns
- Routes already exist:
  - `GET /tenders/:id/builder` — renders builder page
  - Nested resources for line items, materials, breakdowns

### Views/UI (Created for MVP)
1. **app/views/tenders/builder.html.erb** — Main builder page with header (tender name, grand total) and line item list
2. **app/views/tender_line_items/_show.html.erb** — Line item card (expandable) with details + collapsible breakdown section
3. **app/views/line_item_rate_build_ups/_show.html.erb** — Rate build-up container showing all 11 components with toggles
4. **app/views/line_item_material_breakdowns/_show.html.erb** — Material breakdown container with rows of materials
5. **app/views/line_item_materials/_show.html.erb** — Editable material row (material dropdown, thickness, rate, qty, line total)

### Background Jobs/Services
None (MVP scope).

---

## Database Schema & Migrations

### New Migration Applied
**File:** `db/migrate/20251129173321_add_columns_to_line_item_materials.rb`

Added three columns to `line_item_materials`:
- `thickness` (decimal) — thickness of material
- `rate` (decimal) — unit rate for material
- `quantity` (decimal) — quantity ordered

### Key Tables (Relevant to Builder)

| Table | Core Columns | Purpose |
|-------|--------------|---------|
| `tenders` | e_number, tender_name, client_name, status | Tender header info |
| `tender_line_items` | item_number, item_description, quantity, rate, unit_of_measure, section_category | Line item details |
| `line_item_rate_build_ups` | material_supply_rate, fabrication_rate, overheads_rate, ... (11 components), subtotal, rounded_rate | Rate component costs |
| `line_item_material_breakdowns` | tender_line_item_id | Container for materials |
| `line_item_materials` | material_supply_id, thickness, rate, quantity, proportion | Individual material items |

---

## Setup & Runbook

### Prerequisites
- Rails app running with PostgreSQL
- Devise authentication configured (already done)
- Turbo Rails + Tailwind CSS (already present)

### Environment Variables
None required for MVP.

### Commands to Set Up & Run

```bash
# Migrate the database (add new columns to line_item_materials)
bundle exec rails db:migrate

# Seed sample data (tender, line items, materials, rate build-ups)
bundle exec rails db:seed

# Start Rails server
bin/rails server

# Access the builder at:
# http://localhost:3000/tenders/3/builder
# (Tender ID 3 = "Smart City Developers" with 3 seeded line items)
```

### Running Tests
No automated tests in MVP. Manual testing recommended via browser.

---

## Product Walkthrough

### Step 1: Log In
- Email: `john.smith@company.com` (or any seeded user)
- Password: `123456`

### Step 2: Navigate to Tender Builder
- Go to: `http://localhost:3000/tenders/3/builder`
- You'll see: **"Smart City Developers"** tender with **E-2024-003** and **GRAND TOTAL**

### Step 3: View Line Items
- Three line items appear:
  1. **LI-001** — Light Structural Steel (45.5 tonne @ R15,500 each = **R705,250**)
  2. **LI-002** — Heavy Structural Steel (28.3 tonne @ R16,800 each = **R475,440**)
  3. **LI-003** — Bolts and Fasteners (500 kg @ R85 each = **R42,500**)
- **GRAND TOTAL:** R1,223,190

### Step 4: Expand a Line Item (Collapse/Expand Toggle)
- Click **"Breakdown Details"** chevron on any line item
- Two-column layout appears:
  - **LEFT:** Rate Build-Up (all 11 components)
  - **RIGHT:** Material Breakdown (materials used)

### Step 5: View Rate Build-Up (Left Column)
- Shows table of rate components:
  - Material Supply, Fabrication, Overheads, Shop Priming, Onsite Painting, Delivery, Bolts, Erection, Crainage, Cherry Picker, Galvanizing
- Each row has:
  - Component name
  - Rate input field (editable, R currency)
  - Included? checkbox (toggle on/off)
  - Amount (calculated, grayed if not included)
- **SUBTOTAL** sums all included components
- **TOTAL** shows final rate (example: R15,500 for LI-001)

### Step 6: View Material Breakdown (Right Column)
- Shows table of materials:
  - Material Supply (dropdown of available materials)
  - Thickness (e.g., 12.5mm)
  - Rate (e.g., R8,200)
  - Quantity (e.g., 30 units)
  - Line Total (calculated: qty × rate)
- Example for LI-001:
  - Local UB & UC Sections | 12.5mm | R8,200 | 30 | **R246,000**
  - Import UB & UC Sections | 15.0mm | R8,800 | 15.5 | **R136,400**
- **SUBTOTAL:** R382,400
- **TOTAL:** R382,400

### Expected Results at Each Step
- ✅ Page loads without errors
- ✅ Three line items render correctly
- ✅ Grand total displays (R1,223,190)
- ✅ Expanding a line item shows both breakdowns
- ✅ Rate components display with editable fields
- ✅ Materials display with editable fields
- ✅ Calculations are correct (qty × rate = line total)

---

## Security & Quality Notes

### Strong Parameters
- Line item materials accept: `material_supply_id`, `thickness`, `rate`, `quantity`, `proportion`
- Rate build-ups accept all 11 rate fields + inclusion toggles
- Tender updates whitelisted in controller

### Validations
- **LineItemMaterial:**
  - `material_supply_id` presence validated
  - `thickness`, `rate`, `quantity` are numeric (allow negative: false)
- **LineItemMaterialBreakdown:** no validations (container only)
- **LineItemRateBuildUp:** before_save hook calculates subtotal and rounded_rate

### CSRF & XSS Protection
- All forms use Rails form helpers (CSRF tokens auto-included)
- Views use ERB escaping by default
- Turbo Frame handling built-in for safe turbo redirects

### Known Risks / Intentionally Deferred
1. **No margin % calculations yet** — margin fields in totals section are UI placeholders
2. **No add/delete material rows** — "+ Add Material" link exists but handler not implemented
3. **No grand total real-time sync** — updates on page reload only; JavaScript Grand Total calculator is basic
4. **No inline form submission** — material/rate updates use separate form submits (not auto-save)
5. **Tender inclusions/exclusions** — model exists but not wired into builder UI

---

## Observability

### Where to Check Logs
- **Rails console:** `bundle exec rails console`
  - Query line items: `Tender.find(3).tender_line_items`
  - Check materials: `TenderLineItem.find(91).line_item_material_breakdown.line_item_materials`
  - Verify rate build-up: `TenderLineItem.find(91).line_item_rate_build_up.subtotal`

- **Browser console (F12):** Check for JavaScript errors when expanding line items

### Simple Diagnostics
```ruby
# In Rails console, verify data integrity:
tender = Tender.find(3)
puts "Tender: #{tender.tender_name}, E#: #{tender.e_number}"
tender.tender_line_items.each do |li|
  puts "  - #{li.item_description}: Qty #{li.quantity} @ R#{li.rate} = R#{li.total_amount}"
  puts "    Materials: #{li.line_item_material_breakdown.line_item_materials.count}"
  puts "    Rate subtotal: R#{li.line_item_rate_build_up.subtotal}"
end
```

---

## Known Limitations

1. **Material dropdown not searchable** — Daisy `select` doesn't support search; upgrade needed for larger material lists
2. **No batch edit** — each material/rate field requires individual save
3. **Margin % field non-functional** — placeholder only, does not recalculate totals
4. **No optimistic UI** — form submissions refresh page (Turbo Frame full replacement)
5. **Rate build-up calculations manual** — `before_save` hook only; no real-time JS calculations
6. **Material line totals display-only** — calculated server-side, not dynamic on client
7. **No line item reordering** — drag-drop not implemented
8. **Grand total uses basic JS regex** — fragile for non-standard currency formats

---

## Next Iterations (Prioritized)

### Iteration 1: Add/Remove Material Rows (High Value)
**Goal:** Let users dynamically add and remove materials from a breakdown.
**Rationale:** Essential for complete tender building workflow.
**Acceptance Criteria:**
- "+ Add Material" button triggers Turbo request to create blank material row
- Delete icon on each material row removes it (with confirmation)
- Material list refreshes without full page reload

### Iteration 2: Searchable Material Dropdown (Medium Value)
**Goal:** Replace Daisy `select` with Stimulus + autocomplete for large material catalogs.
**Rationale:** Material supply list grows; plain select becomes unusable.
**Acceptance Criteria:**
- Type in material field filters dropdown by name
- Keyboard navigation (arrow keys, enter) works smoothly
- Integrates with existing Turbo Frame submission

### Iteration 3: Real-time Totals with Stimulus (Medium Value)
**Goal:** Update line total / breakdown totals as user types rate/quantity.
**Rationale:** Improves UX (no need to save to see updated totals).
**Acceptance Criteria:**
- Change quantity or rate → line total updates instantly
- Change any rate component → rate build-up subtotal updates
- Grand total on page recalculates without refresh

### Iteration 4: Margin % Integration (Medium Value)
**Goal:** Allow margin entry; auto-calculate total with markup.
**Rationale:** Standard tendering workflow includes margin/profit markup.
**Acceptance Criteria:**
- Enter margin % in breakdown container
- Total = Subtotal × (1 + margin %)
- Grand total reflects margin on all line items

### Iteration 5: Inline Material Add/Edit (Low Value, UX Polish)
**Goal:** Add/edit materials without leaving expanded breakdown.
**Rationale:** Smoother workflow for rapid tender building.
**Acceptance Criteria:**
- "+ Add Material" expands inline form (not modal)
- Save button replaces newly added row inline
- Cancel collapses form without saving

### Iteration 6: Export to Excel/PDF (Low Value, Nice-to-Have)
**Goal:** Download tender as structured spreadsheet or PDF.
**Rationale:** Users expect export functionality.
**Acceptance Criteria:**
- "Export" button generates `.xlsx` or `.pdf` with all line items and totals
- File includes rate build-ups and material breakdowns
- Downloads to user machine

### Iteration 7: Tender Inclusions/Exclusions Toggle (Low Value)
**Goal:** Let users control which services are included at tender level.
**Rationale:** Some tenders exclude fabrication, galvanizing, etc.
**Acceptance Criteria:**
- Tender-level toggle for each of 10+ services
- Toggles cascade to all line item rate build-ups
- UI shows which services are included globally

### Iteration 8: Revision History & Comparisons (Future)
**Goal:** Track changes to tender, compare versions side-by-side.
**Rationale:** Audit trail + client communication (e.g., "what changed from v1 to v2?").
**Acceptance Criteria:**
- Tender stores historical snapshots (or uses gem like `paper_trail`)
- UI shows "Last modified by [user] on [date]"
- Compare two versions shows line-by-line diffs

---

## Changelog (Session Summary)

### Files Created
1. **db/migrate/20251129173321_add_columns_to_line_item_materials.rb** — Added thickness, rate, quantity columns
2. **app/views/tenders/builder.html.erb** — Main tender builder page
3. **app/views/tender_line_items/_show.html.erb** — Expandable line item container
4. **app/views/line_item_material_breakdowns/_show.html.erb** — Material breakdown card
5. **app/views/line_item_rate_build_ups/_show.html.erb** — Rate build-up card with 11 components
6. **app/views/line_item_materials/_show.html.erb** — Editable material row

### Files Modified
1. **app/models/line_item_material.rb** — Added validations + line_total() helper method
2. **app/models/line_item_material_breakdown.rb** — Added subtotal() and total() helper methods
3. **db/seeds.rb** — Added 3 seeded tender line items with materials and rate build-ups (tender E-2024-003)

### Database Changes
- Migration `20251129173321` applied: Added thickness, rate, quantity to line_item_materials table

### No Changes Required
- Controller already had `builder` action ✅
- Routes already had nested tender_line_items ✅
- Models (Tender, TenderLineItem, etc.) already had associations ✅

---

## References (Optional)

- **Rails Turbo Frames Guide:** https://turbo.hotwired.dev/handbook/frames
- **Daisy UI Components:** https://daisyui.com/ (cards, collapse, buttons, inputs used)
- **Tailwind CSS Grid:** https://tailwindcss.com/docs/grid (grid-cols-12 for responsive layout)
- **Font Awesome Icons:** https://fontawesome.com/icons (chevron, trash, edit icons used)

---

## How to Test the MVP

1. **Log in** at `http://localhost:3000` with `john.smith@company.com` / `123456`
2. **Navigate** to `http://localhost:3000/tenders/3/builder`
3. **Verify:**
   - Tender name appears ("Smart City Developers")
   - Three line items listed
   - Grand total shows R1,223,190
4. **Click** "Breakdown Details" on first line item
5. **Observe:**
   - Left: 11 rate components with toggles
   - Right: 2 materials (Local UB, Import UB)
   - Calculations correct (qty × rate = line total)
6. **Try editing** a material's rate/quantity field and save
7. **Refresh page** and verify changes persisted

---

**MVP Status:** ✅ Ready for testing and feedback!
