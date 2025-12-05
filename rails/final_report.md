# Tender Crane Selections Builder Integration — MVP Handover

## Overview & Goals

**Problem:** The standalone tender crane selections index page existed with inline editing capabilities, but was not integrated into the Mobile Crane Breakdown Builder page. Users had to navigate away from the builder workflow to manage crane selections.

**Target User:** Tender managers configuring crane breakdowns for projects.

**MVP Goal:** Embed the full, editable tender crane selections list (with inline editing) directly inside the Crane Breakdown Builder page, reusing the existing index page logic without any UI duplication.

**Out of Scope:**
- Modal-based editing (inline editing only, as per existing index page)
- New UI component variants
- Additional fields beyond existing selections

**Acceptance Criteria:**
- Builder page displays the full editable list of tender crane selections with inline editing
- Embedded list is fully functional (add row, inline edit, save, delete)
- All interactions occur inline within the Builder page; no navigation away
- The index page logic is reused exactly — no duplication
- Unsaved changes indicator and save confirmation work as expected

## Environment & Versions

- **Ruby:** 3.3.6
- **Rails:** 7.2.2.1
- **Database:** PostgreSQL
- **Frontend:** Tailwind CSS, Daisy UI, Font Awesome Icons
- **Key Dependencies:** Turbo Rails (for frame-based interactions), Stimulus JS (for inline editing controller)

## Architecture Summary

### Data Model
- **OnSiteMobileCraneBreakdown:** Single mobile crane breakdown per tender, contains configuration (roof area, erection rate, duration, ownership type, splicing/misc crane details)
- **TenderCraneSelection:** Individual crane selections linked to a tender (tender_id, crane_rate_id, purpose, quantity, duration_days, wet_rate_per_day, total_cost)
- **Relationship:** `OnSiteMobileCraneBreakdown` → `Tender` → `TenderCraneSelection` (via `has_many :through` association)

### Controllers & Routes
- **OnSiteMobileCraneBreakdownsController#builder:** Primary action serving the builder page
  - Sets `@on_site_mobile_crane_breakdown` via `before_action`
  - Loads `@crane_complements` and `@crane_rates` for display
  - Route: `GET /on_site_mobile_crane_breakdowns/:id/builder`
- **TenderCraneSelectionsController:** Handles CRUD operations for crane selections
  - Uses Turbo Streams for inline edit responses

### Views/UI
- **Builder Page:** `app/views/on_site_mobile_crane_breakdowns/builder.html.erb`
  - Section 1: Breakdown Configuration (uses show partial)
  - Section 2: Crane Complements (read-only table)
  - **Section 3: Tender Crane Selections (NEW — embedded index partial with inline editing)**
  - Section 4: Crane Rates (read-only table)
- **Index Partial:** `app/views/tender_crane_selections/_index.html.erb`
  - Renders the list of selections using `_tender_crane_selection.html.erb` (one per selection)
  - Includes "Add Row" button with proper tender_id scoping
  - Wrapped in `<turbo-frame id="tender_crane_selections">` for frame-based Turbo interactions
- **Selection Row Partial:** `app/views/tender_crane_selections/_tender_crane_selection.html.erb`
  - Inline-editable form for each selection
  - Stimulus JS controller for edit mode toggle
  - Edit button (pencil icon → checkmark)
  - Delete button (trash icon)
  - Unsaved changes indicator (yellow)
  - Saved confirmation indicator (green)
  - All numeric fields and dropdowns inline

## Database Schema & Migrations

### OnSiteMobileCraneBreakdown Table
```
- id (pk)
- tender_id (fk, unique)
- total_roof_area_sqm (decimal)
- erection_rate_sqm_per_day (decimal)
- program_duration_days (integer)
- ownership_type (string: 'rsb_owned' or 'rental')
- splicing_crane_required (boolean)
- splicing_crane_size (string)
- splicing_crane_days (integer)
- misc_crane_required (boolean)
- misc_crane_size (string)
- misc_crane_days (integer)
- created_at, updated_at
```

### TenderCraneSelection Table
```
- id (pk)
- tender_id (fk)
- crane_rate_id (fk)
- purpose (string)
- quantity (integer)
- duration_days (integer)
- wet_rate_per_day (decimal)
- total_cost (decimal)
- sort_order (integer)
- created_at, updated_at
```

## Setup & Runbook

### Prerequisites
- Rails 7.2.2.1 running with PostgreSQL
- Devise authentication configured
- Turbo Rails bundled
- Stimulus JS configured for inline editing

### Environment Variables
None required for this feature.

### Commands to Set Up
```bash
# No new migrations required; feature reuses existing tables
bundle exec rails db:migrate

# Optional: Seed sample data if needed
bundle exec rails db:seed
```

### Commands to Run the App
```bash
# Start Rails server
bundle exec rails server

# Navigate to the builder page (assuming breakdown ID 6 exists):
# http://localhost:3000/on_site_mobile_crane_breakdowns/6/builder
```

### Commands to Run Tests
```bash
bundle exec rails test
```

## Product Walkthrough

### Step 1: Access the Builder Page
1. Navigate to `/on_site_mobile_crane_breakdowns/6/builder` (or any valid breakdown ID)
2. You should see four sections:
   - Breakdown Configuration
   - Crane Complements
   - **Selected Cranes** (NEW)
   - Crane Rates

### Step 2: View Tender Crane Selections List
1. Scroll to the "Selected Cranes" section
2. You will see a list of crane selections, each displayed as an editable row:
   - Tender ID (read-only)
   - Crane Rate ID (read-only)
   - Purpose (editable text field)
   - Quantity (editable number field)
   - Duration Days (editable number field)
   - Wet Rate/Day (editable decimal field)
   - Total Cost (read-only)
   - Edit button (pencil icon)
   - Delete button (trash icon)

### Step 3: Edit a Crane Selection Inline
1. Click the **pencil icon** on any row
2. The row becomes editable: fields turn white and the button changes to a checkmark
3. Edit any of the editable fields (purpose, quantity, duration, wet rate)
4. A yellow "You have unsaved changes" indicator appears
5. Click the **checkmark button** to save
6. The form submits via Turbo Stream; a green "Changes saved" confirmation appears
7. The row returns to read-only mode

### Step 4: Add a New Crane Selection
1. Click the **"+ Add Row"** button at the bottom of the list
2. You will be taken to the new tender crane selection form
3. Fill in the fields (crane rate, purpose, quantity, duration, etc.)
4. Click "Create" to save
5. You will be redirected back to the builder page
6. The new selection appears in the list

### Step 5: Delete a Selection
1. Click the **trash icon** on any row
2. Confirm the deletion prompt
3. The row is removed and the list updates
4. You remain on the builder page (no navigation)

### Expected Results
- All selections appear as inline-editable rows on the builder page
- No page reloads during edit, add, or delete operations
- Unsaved changes indicator appears when fields are modified
- Saves happen via Turbo Stream (form submission in the frame)
- All interactions preserve the builder page context

## Security & Quality Notes

### Strong Parameters
- Controlled via `tender_crane_selection_params` in TenderCraneSelectionsController
- Only permitted: `purpose`, `quantity`, `duration_days`, `wet_rate_per_day`

### CSRF Protection
- Form submissions in inline edit respect Rails CSRF token
- Turbo Stream responses include proper security headers

### Validations
- `TenderCraneSelection` model validates presence of tender and crane rate
- `OnSiteMobileCraneBreakdown` validates presence and uniqueness of tender_id, numeric fields
- Numeric fields validated for non-negative values

### XSS Prevention
- All numeric values rendered via `number_with_precision` helper
- All strings escaped via ERB safe defaults
- Form fields use Rails form helpers with HTML escaping

### Known Risks
- Inline edit toggle state is client-side only; if page refreshes during edit, changes are lost
- Concurrent edits: if two users edit the same selection simultaneously, last write wins
- Delete via Turbo: users see confirmation prompt but deletion is final without undo

## Observability

### Where to Look
- **Builder Page Logs:** Check Rails server output for Turbo Stream requests to `/tender_crane_selections/:id.turbo_stream`
- **Database Logs:** Monitor queries to `tender_crane_selections` table (loaded via association)
- **Rails Console:** 
  ```ruby
  breakdown = OnSiteMobileCraneBreakdown.find(6)
  puts breakdown.tender_crane_selections.count  # Verify selections loaded
  selections = breakdown.tender_crane_selections
  selections.each { |s| puts "#{s.purpose}: #{s.total_cost}" }
  ```

## Known Limitations

- **Inline edit state not persisted:** If user refreshes page while in edit mode, changes are lost (expected behavior)
- **No optimistic locking:** Concurrent edits not detected; last write wins
- **Single breakdown per tender:** Architecture assumes one breakdown per tender (enforced by unique index)
- **No filtering/search in list:** All selections for the tender are displayed (suitable for MVP, scalable later)
- **Stimulus JS dependency:** Inline editing relies on custom Stimulus controller (`inline-edit`); ensure JavaScript loads correctly
- **No drag-to-reorder:** Sort order exists in DB but UI doesn't expose reordering in builder

## Next Iterations (Prioritized)

1. **Bulk Operations**
   - Goal: Delete or adjust multiple selections at once
   - Rationale: Time-saving for complex breakdowns
   - AC: Checkboxes per row; bulk delete action; bulk edit action

2. **Crane Suggestion Engine**
   - Goal: Auto-suggest crane selections based on erection rate and crane complements
   - Rationale: Reduces guesswork; ensures compliance with company guidelines
   - AC: "Suggest cranes" button; populates list with recommendations

3. **Drag-to-Reorder Selections**
   - Goal: Manually adjust the order of crane selections in the list
   - Rationale: Presentational; helps organize selections by importance or timeline
   - AC: Drag handles visible; sort_order persisted on drop

4. **Export / Print Builder**
   - Goal: Generate PDF or CSV of the complete builder page (all sections)
   - Rationale: Tender documents need to be shareable offline
   - AC: "Export as PDF" button; includes all sections

5. **Breakdown Cloning**
   - Goal: Duplicate a breakdown and its selections from a previous tender
   - Rationale: Reduces manual data entry for similar projects
   - AC: "Clone from" dropdown on new breakdown form; copies all selections

6. **Real-Time Validation**
   - Goal: Warn users if selections conflict (e.g., overlapping crane assignments)
   - Rationale: Prevent configuration errors early
   - AC: Validation message shown inline; visual indicator on conflicting rows

## Changelog (Session Summary)

### Files Modified

1. **app/views/on_site_mobile_crane_breakdowns/builder.html.erb**
   - Line 108–112: Changed from `render 'tender_crane_selections/index_table'` to `render 'tender_crane_selections/index'`
   - Fixed data scope: uses `@on_site_mobile_crane_breakdown.tender_crane_selections` (not `.tender.tender_crane_selections`)
   - Wrapped the index partial in `<turbo-frame id="tender_crane_selections">` for frame-based Turbo interactions
   - **Rationale:** Ensures the list displays selections scoped to the current breakdown (via the tender); enables frame-targeted form submissions without full page reloads

2. **app/models/on_site_mobile_crane_breakdown.rb**
   - Added `has_many :tender_crane_selections, through: :tender` association
   - **Rationale:** Provides a clean, scoped accessor for all crane selections belonging to this breakdown; enables `@on_site_mobile_crane_breakdown.tender_crane_selections` syntax used in the view

3. **app/views/tender_crane_selections/_index.html.erb** (NEW FILE)
   - Created reusable index partial that renders the list of selections
   - Accepts `tender_crane_selections` (array) and `on_site_mobile_crane_breakdown` (object) as parameters
   - Renders each selection using the existing `_tender_crane_selection.html.erb` partial (with inline editing)
   - Includes "Add Row" button with proper tender_id scoping
   - **Rationale:** Extracts list rendering logic for reuse in builder; allows the main `index.html.erb` page and builder to share the same list UI

### No Changes to Existing Files
- `index.html.erb` remains unchanged (still has header, "New" button, uses the index partial)
- `_tender_crane_selection.html.erb` reused as-is (inline editing, Stimulus controller, all functionality)
- `TenderCraneSelectionsController` unchanged (CRUD operations work as expected)

## References (Optional)

- [Rails Associations (has_many :through)](https://guides.rubyonrails.org/association_basics.html#the-has-many-through-association)
- [Turbo Frames](https://turbo.hotwired.dev/reference/frames)
- [Stimulus JS](https://stimulus.hotwired.dev/)
- [Strong Parameters](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)
