# Ticket Planning Skill

## Purpose

Generate incremental, actionable tickets for VA and coding agents to execute. This skill turns scoped requirements into thin full-stack slices that can be built and demoed independently.

**Critical Principle:** Only create 1-2 days worth of tickets at a time. Complete current tickets before generating more. This prevents scope creep and maintains focus.

---

## When to Use This Skill

Invoke this skill when:
- Starting work on a new week's scope
- Breaking down a vertical slice into executable tickets
- Creating the next batch of tickets after completing current work
- VA or coding agent needs clear instructions for implementation

---

## Standard Operating Procedure

### Phase 1: Analyze the Scope

**1.1 Read the Week Scope Document**
```
File: /rails/requirements/user_feedback/cycles/phase-1-tendering/sprints/sprint-X/week-N.md
```

Identify:
- Tables mentioned (with columns, types, constraints)
- Business rules and calculations
- UI components needed
- Parent-child relationships

**1.2 List All Tables**

For each table, note:
- Table name
- All columns with types
- Foreign keys (if any)
- Business rules / calculations

---

### Phase 2: Classify Tables

Before generating tickets, classify EVERY table.

**MASTER TABLE** criteria (all must be true):
- Has NO foreign keys
- Represents global configuration data
- Is reused across tenders/transactions
- Is updated rarely (e.g., annually)

**DEPENDENT TABLE** criteria (any is true):
- Has one or more foreign keys
- Depends on a parent table
- Belongs to a tender, breakdown, or transaction
- Is updated frequently

**Output the classification explicitly before generating tickets.**

---

### Phase 3: Apply the Correct Protocol

#### Master Table Protocol (3 Tickets)

For each MASTER table, generate exactly 3 tickets:

**Ticket 1 — Scaffold**
```markdown
### Ticket: Scaffold <table_name> master table

**Type:** Scaffolding
**Est:** 0.5 day

**Table:** <table_name>

**Columns:**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| [column] | [type] | [constraints] | [description] |

**Instructions:**
1. Run: `rails generate scaffold <TableName> [columns]`
2. Run migration: `rails db:migrate`
3. Verify routes exist: `rails routes | grep <table_name>`

**Acceptance:** Model, migration, controller, routes, and views exist.
```

**Ticket 2 — Seed**
```markdown
### Ticket: Seed <table_name> with default values

**Type:** Seeding
**Est:** 0.5 day

**Seed Data:**
| [column1] | [column2] | [column3] |
|-----------|-----------|-----------|
| [value] | [value] | [value] |

**Instructions:**
1. Add seed data to `db/seeds.rb`
2. Run: `rails db:seed`
3. Verify in console: `<TableName>.count`

**Acceptance:** All rows exist in database with correct values.
```

**Ticket 3 — UI Iteration (Index)**
```markdown
### Ticket: Iterate UI for <table_name> index page

**Type:** UI Iteration
**Route:** /<table_name> (index page)
**Est:** 1 day

**UI Requirements:**
- Table renders all rows
- "Add Row" button adds new row at bottom
- Each row has:
  - Pencil icon → edit mode
  - Checkmark icon → saves changes
  - Dirty-form indicator when unsaved
- Changes persist to database without page refresh

**Instructions:**
1. Update `app/views/<table_name>/index.html.erb`
2. Add Stimulus controller if needed
3. Implement inline editing with Turbo Frames

**Acceptance:** User can add, edit, and save rows inline on the index page.
```

---

#### Dependent Table Protocol (5 Tickets)

For each DEPENDENT table, generate exactly 5 tickets:

**Ticket 1 — Scaffold**
```markdown
### Ticket: Scaffold <table_name> dependent table

**Type:** Scaffolding
**Est:** 0.5 day

**Table:** <table_name>

**Columns:**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| <parent>_id | bigint | FK to <parent>, CASCADE | Reference to parent |
| [column] | [type] | [constraints] | [description] |

**Foreign Keys:**
- `<parent>_id` references `<parent_table>`

**Instructions:**
1. Run: `rails generate scaffold <TableName> [columns]`
2. Add `belongs_to :<parent>` to model
3. Add `has_many :<children>` to parent model
4. Run migration: `rails db:migrate`

**Acceptance:** Model with associations, migration, controller, routes exist.
```

**Ticket 2 — Seed**
```markdown
### Ticket: Seed <table_name> with representative rows

**Type:** Seeding
**Est:** 0.5 day

**Seed Data:**
| <parent>_id | [column1] | [column2] |
|-------------|-----------|-----------|
| 1 | [value] | [value] |

**Instructions:**
1. Add seed data to `db/seeds.rb` (after parent seeds)
2. Use valid parent IDs
3. Run: `rails db:seed`
4. Verify: `<TableName>.count` and `<TableName>.first.<parent>`

**Acceptance:** Rows exist with valid parent associations.
```

**Ticket 3 — UI for Show Page**
```markdown
### Ticket: Iterate UI for <table_name> show page

**Type:** UI Iteration
**Route:** /<table_name>/:id (show page)
**Est:** 1 day

**File Structure:**
```
app/views/<table_name>/
  show.html.erb              # just: <%= render @<model> %>
  _<model_name>.html.erb     # the editable Turbo Frame component
```

**UI Requirements:**
- Partial wrapped in `turbo_frame_tag dom_id(record)`
- Form always editable (no view/edit toggle)
- Uses `form_with model: record`
- Save button per row
- Dirty form indicator for unsaved changes
- Pencil → edit, Checkmark → save pattern

**Instructions:**
1. Create `_<model_name>.html.erb` partial
2. Wrap in Turbo Frame
3. Add dirty-form Stimulus controller
4. Update show.html.erb to render partial

**Acceptance:** Can view and edit record at /<table_name>/:id with inline saving.
```

**Ticket 4 — Scoped Index Page**
```markdown
### Ticket: Create scoped index for <table_name> under <parent>

**Type:** UI Iteration
**Route:** /<parent>/:id/<table_name> (scoped index)
**Est:** 0.5 day

**Instructions:**
1. Add nested route in `config/routes.rb`
2. Create index action scoped to parent
3. Render collection of `_<model_name>.html.erb` partials
4. Add "Add Row" button that POSTs to create

**Controller:**
```ruby
def index
  @<parent> = <Parent>.find(params[:<parent>_id])
  @<children> = @<parent>.<children>
end
```

**Acceptance:** Can view all child records grouped under parent at scoped route.
```

**Ticket 5 — Integrate into Builder**
```markdown
### Ticket: Add <table_name> to <parent> builder page

**Type:** UI Integration
**Route:** /<parent>/:id/builder
**Est:** 0.5 day

**Instructions:**
1. Add section to builder view for <table_name>
2. Render scoped collection inside Turbo Frame
3. Include "Add" button
4. Ensure inline editing works within builder context

**Acceptance:** <table_name> section appears in builder, can add/edit/save inline.
```

---

### Phase 4: Other Ticket Types

#### Bug Ticket Template
```markdown
### Ticket: Fix [bug description]

**Type:** Bug Fix
**Severity:** High/Medium/Low
**Est:** 0.5-1 day

**Problem:**
[Describe what's broken]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What currently happens]

**Debugging Steps:**
See "Debugging Guide" section below for full instructions.

1. **Isolate JavaScript logs:**
   - Open the app in an external browser tab (not embedded preview)
   - Open DevTools (F12 or Cmd+Shift+I)
   - Go to Console tab
   - Add `console.log()` statements to relevant JS files

2. **Check Network requests:**
   - Open DevTools → Network tab
   - Look for failed requests (red)
   - Check request/response payloads

3. **View Rails logs in real-time:**
   - Open VSCode terminal
   - Run: `ssh leonardo`
   - Run: `cd Leonardo`
   - Run: `./bin/rails_logs`
   - Clear terminal before reproducing bug
   - Add `Rails.logger.info "DEBUG: #{variable.inspect}"` to Ruby code

4. **Report findings:**
   - Copy JavaScript console output back to Leonardo
   - Copy relevant Rails log output back to Leonardo
   - Include error messages and stack traces

5. **CLEANUP (REQUIRED):**
   - Remove ALL `console.log()` statements after fix
   - Remove ALL `Rails.logger.info "DEBUG:..."` statements after fix
   - Keep logging space clean for production

**Files to Check:**
- `app/controllers/[controller].rb`
- `app/javascript/controllers/[controller].js`
- `app/views/[view].html.erb`

**Acceptance:**
- [ ] [Bug description] no longer occurs
- [ ] All debugging statements have been removed
```

#### UX Iteration Ticket Template
```markdown
### Ticket: [UX improvement description]

**Type:** UX Iteration
**Est:** 0.5-1 day

**Current State:**
[What exists now]

**Desired State:**
[What should change]

**Changes Required:**
- [ ] [Specific change 1]
- [ ] [Specific change 2]

**Files to Modify:**
- `app/views/[path].html.erb`
- `app/javascript/controllers/[controller].js`

**If Issues Occur:**
See "Debugging Guide" section for full instructions on:
- Opening app in external browser tab for isolated JS console
- Using DevTools Console and Network tabs
- Viewing Rails logs via `ssh leonardo → cd Leonardo → ./bin/rails_logs`
- Copying log output back to Leonardo for analysis
- **Remember:** Remove all debug statements after fixing

**Acceptance:**
- [ ] [Specific UI behavior to verify]
- [ ] No debugging statements left in code
```

#### Business Rules Ticket Template
```markdown
### Ticket: Implement [calculation/rule] for <model>

**Type:** Business Rules
**Est:** 1-2 days

**Rule:**
[Describe the business rule or calculation]

**Formula:**
```
[field] = [calculation]
```

**Implementation:**
1. Add callback to model:
```ruby
after_save :calculate_[field]

def calculate_[field]
  self.[field] = [formula]
  save if [field]_changed?
end
```

2. Add Stimulus controller for real-time calculation (if needed)

**Test Cases:**
| Input | Expected Output |
|-------|-----------------|
| [value] | [result] |

**If Calculation Not Working:**
See "Debugging Guide" section for full instructions. Quick reference:
1. Add `Rails.logger.info "DEBUG: #{variable.inspect}"` to callbacks
2. User: `ssh leonardo → cd Leonardo → ./bin/rails_logs`
3. User: Reproduce the calculation, copy logs back to Leonardo
4. **Remember:** Remove all debug statements after fixing

**Acceptance:**
- [ ] Calculation runs correctly on save and displays in UI
- [ ] Test cases pass
- [ ] No debugging statements left in code
```

---

### Phase 5: Sequencing & Build Order

**Principle: Build leaf nodes first, then work up to parents.**

**Day 1: Quick Wins + Scaffolding**
- Scaffold all tables (master first, then dependent)
- Seed all tables
- Quick bug fixes

**Day 2-3: Core UI Components**
- Show page UI for leaf/child tables
- Inline editing working
- Dirty form indicators

**Day 3-4: Grouping & Integration**
- Scoped index pages
- Parent builder integration
- Collection rendering

**Day 4-5: Business Rules & Polish**
- Calculations and callbacks
- UX iterations
- Testing and fixes

---

## UI Rules Reference

**ABSOLUTE RULES (DO NOT BREAK)**

1. **NO MODALS** - Never use modals for editing or creating records

2. **Inline Editing Pattern:**
   - Pencil icon → enters edit mode
   - All fields editable simultaneously
   - Dirty indicator shows unsaved changes
   - Checkmark icon → saves via Turbo (no page refresh)

3. **Independent Routes:**
   - Every model viewable at `/<model_name>/:id`
   - Allows iterating on components independently

4. **Turbo Frame Convention:**
   ```erb
   <%= turbo_frame_tag dom_id(record) do %>
     <%= form_with model: record, data: { controller: "dirty-form" } do |f| %>
       <!-- fields -->
     <% end %>
   <% end %>
   ```

5. **Add Button = Instant Creation:**
   - POST immediately creates record with defaults
   - New record appears via Turbo Stream append
   - User edits the now-existing record inline
   - NO empty forms, NO modals

6. **Dirty Form Controller:**
   - Tracks unsaved changes
   - Yellow highlight on save button when dirty
   - "Unsaved changes" text indicator
   - Resets after successful save

---

## Route Decision Rules

| Table Type | Primary UI Route |
|------------|------------------|
| Master table | `/<table_name>` (index) |
| Dependent table (show) | `/<table_name>/:id` |
| Dependent table (grouped) | `/<parent>/:id/<children>` |
| Dependent table (builder) | `/<parent>/:id/builder` |

**Never put master table UI on a parent show page.**
**Never use index routes for dependent table primary editing.**

---

## VA Testing Checklist

Use this checklist for EACH component after implementation:

```markdown
## Component: /<model_name>/:id

**Page Load**
- [ ] Page loads without error
- [ ] Turbo Frame wraps component (inspect for `<turbo-frame id="model_1">`)
- [ ] Existing data displays in form fields

**Dirty Form Indicator**
- [ ] No indicator visible on page load
- [ ] Save button is neutral color
- [ ] Edit any field → indicator appears
- [ ] Save button changes to yellow
- [ ] Click Save → indicator disappears
- [ ] Form stays on page (no full reload)

**Save Functionality**
- [ ] Can edit and save
- [ ] Only component refreshes
- [ ] Value persists (check console: `ModelName.find(1)`)

**Children (if applicable)**
- [ ] Child components render inside Turbo Frame
- [ ] "+ Add" creates new row immediately (no modal)
- [ ] New row appears via Turbo Stream
- [ ] New row can be edited and saved
- [ ] Check console: `ModelName.last.parent_id`
```

**Rails Console Verification:**
```ruby
# Check record exists
ModelName.find(1)

# Check saved value
ModelName.find(1).field_name

# Check associations
Parent.find(1).children

# After adding
ModelName.last
ModelName.last.parent_id
```

---

## Checklist: Before Creating Tickets

```markdown
- [ ] Read the week's scope document
- [ ] List all tables mentioned
- [ ] Classify each table (Master vs Dependent)
- [ ] Identify parent-child relationships
- [ ] Note any business rules/calculations
- [ ] Only create tickets for next 1-2 days of work
- [ ] Sequence: scaffolds → seeds → UI → integration → rules
```

---

## Anti-patterns to Avoid

- **Creating all tickets at once** - Only 1-2 days at a time
- **Horizontal slices** - Don't do all models, then all controllers, then all views
- **Modal workflows** - Inline editing only
- **Separate CRUD pages for dependents** - UI goes on parent show/builder
- **Missing foreign keys** - Always specify for dependent tables
- **Generic content** - Use concrete columns, types, seed data
- **Skipping classification** - Always classify before generating tickets
- **Leaving debug statements** - Always remove console.log and Rails.logger debug statements

---

## Debugging Guide

This section provides detailed instructions for debugging issues. Reference this guide in any ticket that may require troubleshooting.

### Setup: Viewing Rails Logs in Real-Time

**Step-by-step instructions for the user:**

1. Open a new terminal in VSCode
2. SSH into the Leonardo container:
   ```bash
   ssh leonardo
   ```
3. Navigate to the project directory:
   ```bash
   cd Leonardo
   ```
4. Start the Rails log viewer:
   ```bash
   ./bin/rails_logs
   ```
5. Clear the terminal (Cmd+K or Ctrl+L) before reproducing the bug
6. Reproduce the bug in the browser
7. Copy relevant log output and paste back to Leonardo

### Client-Side Debugging (JavaScript)

**Why use an external browser tab:**
- Embedded previews may not show all console output
- External tab gives full access to DevTools
- Isolated environment for cleaner debugging

**Step-by-step instructions:**

1. Open the app URL in a new browser tab (not embedded preview)
2. Open DevTools:
   - Mac: `Cmd + Option + I`
   - Windows/Linux: `F12` or `Ctrl + Shift + I`
3. Go to the **Console** tab
4. Clear existing logs (click the 🚫 icon)

**Adding JavaScript debug statements:**

```javascript
// In Stimulus controllers or other JS files
console.log("DEBUG: Controller connected", this.element);
console.log("DEBUG: Form data", Object.fromEntries(new FormData(this.element)));
console.log("DEBUG: Variable value", variableName);

// For Turbo events
document.addEventListener("turbo:submit-start", (e) => {
  console.log("DEBUG: Turbo submit started", e.detail);
});

document.addEventListener("turbo:frame-render", (e) => {
  console.log("DEBUG: Frame rendered", e.target.id);
});
```

**Checking the Network tab:**

1. Go to DevTools → **Network** tab
2. Filter by "Fetch/XHR" to see AJAX requests
3. Look for:
   - Red entries (failed requests)
   - Status codes (200 = success, 4xx = client error, 5xx = server error)
   - Click a request to see Headers, Payload, Response

**Reporting JavaScript findings to Leonardo:**

Copy and paste:
- Error messages from Console
- Failed request details from Network tab
- Any unexpected behavior logged

### Server-Side Debugging (Ruby/Rails)

**Adding Rails debug statements:**

```ruby
# In controllers
def create
  Rails.logger.info "DEBUG: Params received: #{params.inspect}"
  Rails.logger.info "DEBUG: Current user: #{current_user.inspect}"

  @record = Model.new(permitted_params)
  Rails.logger.info "DEBUG: Record before save: #{@record.attributes}"

  if @record.save
    Rails.logger.info "DEBUG: Record saved successfully, ID: #{@record.id}"
  else
    Rails.logger.info "DEBUG: Save failed, errors: #{@record.errors.full_messages}"
  end
end

# In models
before_save :debug_callback
def debug_callback
  Rails.logger.info "DEBUG: Before save - #{self.changes}"
end

# In views (use sparingly)
<% Rails.logger.info "DEBUG: Rendering partial for #{record.id}" %>
```

**Common things to log:**

| What to Check | Code |
|---------------|------|
| Incoming params | `Rails.logger.info "DEBUG: #{params.inspect}"` |
| Record attributes | `Rails.logger.info "DEBUG: #{@record.attributes}"` |
| Validation errors | `Rails.logger.info "DEBUG: #{@record.errors.full_messages}"` |
| Association data | `Rails.logger.info "DEBUG: #{@parent.children.count} children"` |
| Current user | `Rails.logger.info "DEBUG: User: #{current_user&.id}"` |
| SQL queries | Check Rails logs - queries are logged automatically |

**Reporting Rails findings to Leonardo:**

Copy from the `./bin/rails_logs` terminal:
- Error messages and stack traces
- Your DEBUG log output
- Any unexpected SQL queries
- ActionController or ActiveRecord errors

### Debugging Workflow Summary

```
┌─────────────────────────────────────────────────────────┐
│                    BUG REPORTED                         │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  1. SETUP LOGGING                                       │
│     • User: ssh leonardo → cd Leonardo → ./bin/rails_logs│
│     • User: Open app in external browser tab            │
│     • User: Open DevTools Console + Network tabs        │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  2. ADD DEBUG STATEMENTS                                │
│     • Leonardo: Add console.log() to JS files           │
│     • Leonardo: Add Rails.logger.info to Ruby files     │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  3. REPRODUCE BUG                                       │
│     • User: Clear terminal and console                  │
│     • User: Perform the action that triggers the bug    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  4. GATHER EVIDENCE                                     │
│     • User: Copy JS console output → paste to Leonardo  │
│     • User: Copy Rails logs output → paste to Leonardo  │
│     • User: Screenshot Network tab if relevant          │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  5. FIX THE BUG                                         │
│     • Leonardo: Analyze logs, identify root cause       │
│     • Leonardo: Implement fix                           │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  6. CLEANUP (REQUIRED!)                                 │
│     • Leonardo: Remove ALL console.log() statements     │
│     • Leonardo: Remove ALL Rails.logger.info DEBUG      │
│     • Keep logs clean for production                    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  7. VERIFY FIX                                          │
│     • User: Reproduce original steps                    │
│     • User: Confirm bug no longer occurs                │
└─────────────────────────────────────────────────────────┘
```

### Cleanup Checklist

**IMPORTANT:** Always remove debugging statements after fixing the bug.

```markdown
## Post-Fix Cleanup Checklist

- [ ] Search for `console.log` in JS files and remove debug statements
- [ ] Search for `Rails.logger.info "DEBUG` in Ruby files and remove
- [ ] Search for `debugger` or `binding.pry` and remove
- [ ] Verify no debug output appears in browser console
- [ ] Verify no DEBUG entries in Rails logs during normal operation
- [ ] Commit the fix WITHOUT any debugging code
```

**Why cleanup matters:**
- Debug logs clutter production logs
- console.log statements slow down the browser
- Professional code should be clean
- Makes future debugging easier (no noise)

### Quick Reference: Debug Statement Patterns

**JavaScript (add then remove):**
```javascript
console.log("DEBUG: [description]", variable);
console.log("DEBUG: Event fired", event.type);
console.log("DEBUG: Form submitted", formData);
```

**Ruby (add then remove):**
```ruby
Rails.logger.info "DEBUG: [description] #{variable.inspect}"
Rails.logger.info "DEBUG: Params: #{params.inspect}"
Rails.logger.info "DEBUG: Errors: #{@record.errors.full_messages}"
```

**Search patterns for cleanup:**
```bash
# Find JS debug statements
grep -r "console.log" app/javascript/

# Find Ruby debug statements
grep -r "Rails.logger.info.*DEBUG" app/
```
