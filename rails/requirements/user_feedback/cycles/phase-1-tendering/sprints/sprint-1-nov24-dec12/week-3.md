# Sprint 1, Week 3: BOQ Upload, Parsing & Crane Calculations (Dec 8-12)

**Duration:** 1 week
**Focus:** BOQ upload, AI parsing, crane breakdown, rate calculations foundation
**Deliverable:** BOQ can be uploaded and parsed, crane calculations functional

---

## Week Overview

Week 1c implements the BOQ upload and AI parsing workflow, along with the on-site mobile crane breakdown calculations. This week bridges data entry (Week 1b) with the calculation engine (Sprint 2).

---

## Vertical Slice Breakdown

Work is organized into thin, full-stack vertical slices. Each slice has its own scope document and can be built/demoed independently.

| Slice | Scope Doc | Priority | Est. Days | Status |
|-------|-----------|----------|-----------|--------|
| UX/Turbo Fixes | [UX_FIXES_SCOPE.md](../../scopes/UX_FIXES_SCOPE.md) | High | 1-2 | Not Started |
| BOQ Parsing Fixes | [BOQ_PARSING_SCOPE.md](../../scopes/BOQ_PARSING_SCOPE.md) | High | 1-2 | Not Started |
| Rate Auto-Population | [RATE_AUTOPOPULATION_SCOPE.md](../../scopes/RATE_AUTOPOPULATION_SCOPE.md) | High | 2-3 | Not Started |
| Crane Cost Calculations | [CRANE_CALC_SCOPE.md](../../scopes/CRANE_CALC_SCOPE.md) | High | 2-3 | In Progress |

### Recommended Build Order (Thinnest First)

**Day 1: UX Fixes (Quick Wins)**
- Fix page refresh on Add Material
- Fix page refresh on Save Changes
- Rename "Qty" to "Proportion"
- Fix "RSB Owned" capitalization

**Day 1-2: BOQ Parsing Fixes**
- Fix item count display bug
- Test with larger BOQs (25+ items)
- Add category tooltips

**Day 2-4: Rate Auto-Population (Core Engine)**
- Material rate auto-fill on select
- Waste percentage application
- Processing rates pre-fill
- Blended material calculation
- Rounding rules (R50/R20/R10)

**Day 3-5: Crane Calculations**
- Program duration auto-calculate
- Crane complement auto-lookup
- Wet rate auto-fill
- Total cost calculation
- Crainage rate per tonne with R20 rounding

---

## Scope: BOQ Upload & Parsing

### BOQ Upload Interface
**Status:** COMPLETED

- CSV file upload to tender
- File preview with header row selection
- Original file stored for reference
- Row numbers displayed for easy identification

### AI-Powered BOQ Parsing
**Status:** IN PROGRESS - Refinement Needed

**Working:**
- AI parses BOQ content and extracts line items
- Creates TenderLineItem records with: page, item_number, description, unit, quantity
- Category suggestion for each line item
- Step-by-step feedback showing parsing progress (pencil icon with "Create BOQ" messages)
- Successfully parsed 25-item BOQ in Dec 8 demo

**Known Issues:**
- [ ] Large BOQs (>25 items) need testing/fixes
- [ ] Item count display discrepancy (showed 17, actual 25) - caching issue
- [ ] Category allocation guidance needed for Elmarie

### BOQ Review & Finalization
**Status:** COMPLETED

- Editable grid for reviewing parsed items
- Add/remove line items capability
- Category editing per line item
- "Transfer to Builder" workflow
- Refresh button to update counts

---

## Scope: Mobile Crane Breakdown

### On-Site Parameters UI
**Status:** COMPLETED

Input fields for:
- Total Roof Area (m²)
- Erection Rate (m/day)
- Program Duration (auto-calculated)
- Splicing Crane toggle (Yes/No)
- Miscellaneous Crane toggle (Yes/No)

### Crane Complement Lookup
**Status:** IN PROGRESS

- Crane rates table displayed for reference (10t through 90t)
- Crane size selection dropdown
- RSB Owned vs Rental distinction
- Edit pencil for modifying parameters

**Pending:**
- [ ] Auto-populate wet rate from lookup table when crane selected
- [ ] Calculate total cost (duration x wet rate)
- [ ] Feed crane costs into rate build-up calculations

### Selected Cranes Interface
**Status:** IN PROGRESS

- Add Row functionality working
- Crane type dropdown (populated from crane_rates table)
- Fields for: quantity, duration_days, rate_per_day, total_cost
- Main Crane vs Splicing Crane designation

---

## Scope: Rate Build-up Foundation

### Material Breakdown Section
**Status:** IN PROGRESS

- Add/remove materials functionality
- Material type dropdown (from MaterialSupply table)
- Proportion input field (currently labeled "Qty")
- Rate and waste percentage display

**Issues to Fix:**
- [ ] Rename "Qty" column to "Material Ratio" or "Proportion"
- [ ] Fix page refresh when clicking Add Material (Turbo Stream issue)
- [ ] Fix page refresh when clicking Save Changes (Turbo Stream issue)

### Rate Calculations
**Status:** IN PROGRESS

- Basic calculation framework in place
- Material supply x proportion working
- Waste percentage application

**Pending:**
- [ ] Auto-populate material supply rate from lookup tables
- [ ] Apply rounding rules (R50 default)
- [ ] Implement per-category rounding (R20 crainage, R10 cherry picker)
- [ ] Add rounding for: Corrosion Protection, Chemical Anchors (R10/R20)

---

## Bug Fixes This Week

| Issue | Status | Priority |
|-------|--------|----------|
| Page refresh on Add Material | Pending | High |
| Page refresh on Save Changes | Pending | High |
| BOQ count discrepancy display | Pending | Medium |
| "Qty" -> "Material Ratio" label | Pending | Medium |
| "Rsb" -> "RSB" capitalization | Pending | Low |

---

## Stretch Goals

- [ ] Start P&G (Preliminaries & General) foundation
- [ ] Start non-crane equipment (Telehandlers, scissors, booms)
- [ ] Implement flexible rounding rules per category
- [ ] Image/screenshot upload to Leonardo

---

## Week 3 Priorities (from Dec 8 Stakeholder Meeting)

### High Priority
1. **BOQ Parsing Stability** - Handle larger BOQs without errors
2. **Crane Calculations** - Auto-fill from lookup, calculate totals
3. **Rate Build-up** - Complete material supply auto-population
4. **UX Fixes** - Eliminate page refreshes, fix labels

### Medium Priority
5. **Live Data Testing** - Start processing real BOQs (1-2/week from RSB)
6. **Maria's Buyer Role** - Create account for material price updates

### Future Considerations
- Leonardo AI making direct small changes (currently disabled)
- Replace Elmarie on tendering categorization with AI
- Historical BOQ data for AI training

---

## Stakeholder Meetings

| Date | Attendees | Purpose | Notes |
|------|-----------|---------|-------|
| Mon Dec 8 | Richard, Darren, Kody | Demo session | Completed - feedback captured |
| Thu Dec 12 | Demi, Kody | Review session | Scheduled 6pm SAST |
| Mon Dec 15 | Richard, Kody | Weekly check-in | Moved to 8pm SAST (2 hrs later) |

---

## Key Insights from Dec 8 Demo

### Richard's Goals
- **Replace Elmarie on tendering** - AI should handle BOQ categorization
- **Live BOQs** - Ready to provide real BOQs for testing
- **Historical data** - Can supply completed tenders for AI training

### Demi's Workflow
- Wants simplified dashboard: import BOQ, choose markup %, generate tender
- Training Elmarie is a burden she'd like to eliminate

### Technical Feedback
- Screen size in Leonardo mode is limiting - need full-screen option
- iPad support requested for mobile meetings
- Screenshot upload to Leonardo would be helpful

---

## Implementation Notes

### Files Modified
- `app/views/on_site_mobile_crane_breakdowns/` - Crane UI
- `app/views/tender_crane_selections/` - Selected cranes
- `app/views/tender_line_items/_form.html.erb` - Material breakdown
- `app/controllers/boqs_controller.rb` - BOQ parsing

### Stimulus Controllers
- `nested_form_controller.js` - Material add/remove (needs Turbo fix)
- `rate_calculator_controller.js` - Live calculations

---

**Week 1c Status:** IN PROGRESS
**Last Updated:** December 8, 2025
