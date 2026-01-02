# P&G Templates Implementation Research

## Root Cause Classification
- **Primary layer:** DB + Model (existing scaffold structure is mostly in place)
- **Secondary layers:** View/UI (dropdown integration needed), Routes (already configured)
- **Is this a DATA problem or DISPLAY problem?** DATA + DISPLAY (new data structure + template selection UI)
- **Evidence:** Models exist, migrations exist, routes configured, but seed data needed

---

## Five Whys Analysis

### Hypothesis Pass (pre-research)
- **Why #1 (symptom):** Why are there no standard P&G templates available? → Hypothesis: No template items seeded into the database (Layer: DB)
- **Why #2:** Why haven't templates been seeded? → Hypothesis: No seed script populates the catalogue (Layer: DB)
- **Why #3:** Why can't users select templates? → Hypothesis: UI dropdown doesn't exist or isn't wired (Layer: View)
- **Why #4:** Why is the selection mechanism missing? → Hypothesis: Controller and view need integration (Layer: View/Controller)
- **Why #5:** Why wasn't this preventively automated? → Hypothesis: Seed script execution missing or needs documentation (Layer: Process)

**Initial layer guess:** DB (seed data missing) + View (dropdown integration)

### Evidence Pass (post-research)

**What I found:**
1. **Model layer:** ✅ `PreliminariesGeneralItemTemplate` model exists with enum for category and validations
2. **Migration layer:** ✅ `20260101172354_create_preliminaries_general_item_templates.rb` exists with all columns
3. **Schema:** ✅ Table created with `category`, `description`, `quantity`, `rate`, `sort_order`, `is_crane`, `is_access_equipment`
4. **Associations:** ✅ `PreliminariesGeneralItem` has optional `belongs_to :preliminaries_general_item_template`
5. **Routes:** ✅ `resources :preliminaries_general_item_templates, path: 'p_and_g_templates'` configured
6. **Controller:** ✅ Full CRUD controller exists at `PreliminariesGeneralItemTemplatesController`
7. **Views:** ✅ Index, new, edit, show templates exist
8. **Item UI:** ✅ P&G items index page has "Template" column header (line 31 of index)
9. **Tender view:** ✅ Link to template catalogue exists (line 13 of items index)

**What's missing:**
1. **Seed data:** 🔴 `db/seeds.rb` has NO P&G template items seeded
2. **Database:** 🟡 Migrations exist but may not be applied (need to verify)
3. **Feature:** 🔴 Three specific categories need standard items (fixed_based, duration_based, percentage_based)

---

## Database Schema

**Table: preliminaries_general_item_templates**
| Column | Type | Default | Purpose |
|--------|------|---------|---------|
| id | bigint | auto | Primary key |
| category | string | null | Enum: fixed_based, duration_based, percentage_based |
| description | text | null | Item description |
| quantity | decimal(10,3) | null | Default quantity |
| rate | decimal(12,2) | null | Default rate |
| sort_order | integer | null | Display ordering |
| is_crane | boolean | false | Crane equipment flag |
| is_access_equipment | boolean | false | Access equipment flag |
| created_at | datetime | now | Record created |
| updated_at | datetime | now | Record updated |

**Table: preliminaries_general_items**
| Column | Type | Default | Purpose |
|--------|------|---------|---------|
| id | bigint | auto | Primary key |
| tender_id | bigint | null | FK to Tender |
| preliminaries_general_item_template_id | bigint | null | FK to Template (optional) |
| category | string | null | Enum: fixed_based, duration_based, percentage_based |
| description | text | null | Item description |
| quantity | decimal(10,3) | 0.0 | Item quantity |
| rate | decimal(12,2) | 0.0 | Item rate |
| sort_order | integer | 0 | Display ordering |
| is_crane | boolean | false | Crane equipment flag |
| is_access_equipment | boolean | false | Access equipment flag |

---

## Models & Associations

**Model: PreliminariesGeneralItemTemplate**
- Location: `app/models/preliminaries_general_item_template.rb`
- Associations: none currently
- Enums: `category { fixed_based: 'fixed_based', duration_based: 'duration_based', percentage_based: 'percentage_based' }`
- Validations: presence of `category` and `description`

**Model: PreliminariesGeneralItem**
- Location: `app/models/preliminaries_general_item.rb`
- Associations: `belongs_to :tender`, `belongs_to :preliminaries_general_item_template, optional: true`
- Enums: same as above
- Validations: presence of `category` and `description`, `quantity` and `rate` >= 0

---

## Controllers & Routes

**Routes:**
```ruby
resources :preliminaries_general_item_templates, path: 'p_and_g_templates'
resources :tender_preliminaries_general_items, path: 'p_and_g' do
  collection do
    get :totals
  end
end
```

**Controller: PreliminariesGeneralItemTemplatesController**
- Location: `app/controllers/preliminaries_general_item_templates_controller.rb`
- Actions: index, show, new, create, edit, update, destroy
- Permitted params: category, description, quantity, rate, sort_order, is_crane, is_access_equipment

---

## UI Components

**Views/Partials:**
- `app/views/preliminaries_general_item_templates/index.html.erb` — catalogue list
- `app/views/preliminaries_general_item_templates/_form.html.erb` — form for new/edit
- `app/views/preliminaries_general_item_templates/_preliminaries_general_item_template.html.erb` — single template row
- `app/views/preliminaries_general_items/index.html.erb` — tender-specific items table
- `app/views/preliminaries_general_items/_preliminaries_general_item.html.erb` — single item row (needs template dropdown)

**Template dropdown location:**
- Column header exists at line 31 of `preliminaries_general_items/index.html.erb`
- Actual dropdown UI missing from `_preliminaries_general_item.html.erb` partial

**Turbo Frames:**
- Not yet implemented for P&G items — could benefit from frame wrapping

---

## Business Logic Summary

**User flow (desired):**
1. Admin/user navigates to `/p_and_g_templates` (catalogue)
2. Admin creates standard templates (e.g., "Site Supervision - Duration Based", "Crane - Fixed Based")
3. When creating/editing a tender's P&G items at `/tenders/43/p_and_g`:
   - User clicks "Quick Add P&G Item"
   - A new row appears with dropdown to select a template
   - Selecting template auto-populates: description, category, quantity, rate, is_crane, is_access_equipment
   - User can override any field after template selection
   - Changes are saved to the specific item, NOT back to the template

**Seed data needed:**
- User request specifies THREE categories with standard items
- Currently NO items seeded in `db/seeds.rb`

---

## Code Health Observations

| Severity | Category | Location | Description |
|----------|----------|----------|-------------|
| MEDIUM | missing-pattern | app/views/preliminaries_general_items/_preliminaries_general_item.html.erb | Template dropdown UI not yet implemented; needs to be wired to controller |
| LOW | naming | app/views/preliminaries_general_item_templates/ | Good alignment with model name via path: 'p_and_g_templates' |
| LOW | architecture | app/models/ | Consider adding `has_many :preliminaries_general_items` to template model for audit/tracking (optional) |

---

## Implementation Readiness

✅ **Already in place:**
- Model definitions with correct enums and validations
- Database migrations and schema
- Full CRUD controller and routes
- View templates for catalogue (index, new, edit, show)
- P&G items index page with template column header

🔴 **Not yet implemented (this ticket):**
- Seed data with standard items for three categories (fixed_based, duration_based, percentage_based)
- Template dropdown UI in the item row partial
- Stimulus controller to wire template selection → item update
- Testing to verify auto-population works

---

## Next Steps

1. **Seed Data Creation:** Add standard P&G items to `db/seeds.rb` with examples for each category
2. **UI Integration:** Implement dropdown in `_preliminaries_general_item.html.erb`
3. **Stimulus Wiring:** Create/update controller to handle template selection → item update
4. **Testing:** Verify end-to-end template selection and auto-population
