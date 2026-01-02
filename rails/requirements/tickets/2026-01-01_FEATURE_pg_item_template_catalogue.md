## 2026-01-01 - FEATURE: Preliminaries & General (P&G) Item Template Catalogue

---

### Original User Story (Agreed Upon) — THE CONTRACT

> **URL:** /tenders/43/p_and_g
>
> **User Story:** As a tender builder, I want to apply a P&G item template to an item row via a dropdown so that I can quickly populate its details from a catalogue while still being able to override them.
>
> **Current Behavior:** P&G items must be added manually; no template catalogue or application mechanism exists.
>
> **Desired Behavior:** A template system (catalogue) exists where users can define standard P&G items. Each P&G item row in the tender builder includes a "Template" dropdown. Selecting a template from this dropdown instantly populates/updates that item's attributes (description, category, rate, flags) to match the template.
>
> **Verification Criteria (UI/UX):**
> - [ ] Given a P&G item row, When I select a template from the "Template" dropdown, Then the item's attributes are updated to match the template values.
> - [ ] Given an item updated from a template, When I override its values, Then the original template remains unchanged.
> - [ ] Given a P&G item or template, When I view its properties, Then I can see if it is flagged as a crane or access equipment.
>
> **Business Rules:**
> - [ ] Templates and Items must both support `is_crane` and `is_access_equipment` flags. — Source: User said "...track if a specific item is_crane, or is_access_equipment..."
> - [ ] Applied templates update the local item attributes as a copy; the item remains independently editable. — Source: User said "...but can be overridden..."
> - [ ] The template selection is a dropdown (select field) on the item row. — Source: User said "Yes, apply template dropdown, not a button. And it's just a select field..."

---

### Metadata

- **Category:** Feature - New Workflow / Data Structure
- **Severity:** Medium
- **Environment:** P&G Items (/tenders/:id/p_and_g)
- **Reported by:** Domain Expert

---

### Demo Path (Step-by-Step Verification)

1. **Given** I am on the new P&G Template Catalogue page (`/p_and_g_templates`), **When** I create a template with description "Site Supervision", category "Duration Based", and check "Is Crane", **Then** the template is saved.
2. **Given** I am on a Tender's P&G page (`/tenders/43/p_and_g`), **When** I add a new P&G item and select "Site Supervision" from its Template dropdown, **Then** the item's fields (description, category, rate) and "Is Crane" flag are automatically updated to match the template.
3. **Given** the updated item, **When** I change its description to "Project Manager Supervision", **Then** the item updates locally, but the original template at `/p_and_g_templates` remains "Site Supervision".
4. **Given** I am viewing an item or template, **When** I look at its details, **Then** the `is_crane` and `is_access_equipment` status is clearly visible.

---

### Scope

**In Scope (This Ticket):**
- Creation of `PreliminariesGeneralItemTemplate` model and table.
- Migration to add `is_crane` and `is_access_equipment` to both `PreliminariesGeneralItem` and `PreliminariesGeneralItemTemplate`.
- CRUD interface for P&G Templates (`/p_and_g_templates`).
- Template dropdown on each `PreliminariesGeneralItem` row in the tender builder.
- Logic to update an item's attributes when a template is selected from the dropdown.

**Non-Goals / Out of Scope:**
- The "special calculation/rule" for cranes/access equipment (reserved for a future ticket).
- Synchronizing changes back from an item to its source template.

---

### User-Facing Summary

As a tender builder, I want to quickly fill out P&G item details using a predefined catalogue. This feature adds a central Template Catalogue where I can save standard items. In the tender builder, I can simply select one of these templates from a dropdown on any item row to instantly pull in the correct description, category, and flags (like Crane or Access Equipment), while still being able to customize them as needed.

---

### Current Behavior

- Users must manually type descriptions, select categories, and enter rates for every P&G item.
- No way to track `is_crane` or `is_access_equipment` status.
- No central repository for standard P&G items.

---

### Desired Behavior

- A global template library for P&G items.
- Items and Templates both have `is_crane` and `is_access_equipment` boolean flags.
- Selecting a template from a dropdown on an item row copies all template data into that specific item.

---

### Verification Criteria (UI/UX) — VERBATIM FROM CONTRACT

- [ ] Given a P&G item row, When I select a template from the "Template" dropdown, Then the item's attributes are updated to match the template values.
- [ ] Given an item updated from a template, When I override its values, Then the original template remains unchanged.
- [ ] Given a P&G item or template, When I view its properties, Then I can see if it is flagged as a crane or access equipment.

---

### Business Rules (Domain Logic)

| Rule | Source |
|------|--------|
| Templates and Items must both support `is_crane` and `is_access_equipment` flags. | User said: "...track if a specific item is_crane, or is_access_equipment..." |
| Applied templates update the local item attributes as a copy; the item remains independently editable. | User said: "...but can be overridden..." |
| The template selection is a dropdown (select field) on the item row. | User said: "Yes, apply template dropdown, not a button. And it's just a select field..." |
| Template application copies Category, Description, Quantity, Rate, and Flags. | Domain Logic (Consistency) |

---

### Implementation Notes (for Leonardo Engineer)

**Root Cause/Layer:** DB & Model (New Data structure) + View (Row-level interaction).

**1. Database Changes:**
- Scaffold `PreliminariesGeneralItemTemplate`:
  `bundle exec rails generate scaffold PreliminariesGeneralItemTemplate category:string description:text quantity:decimal{10,3} rate:decimal{12,2} sort_order:integer is_crane:boolean is_access_equipment:boolean`
- Migration to update existing items:
  `bundle exec rails generate migration AddFlagsToPreliminariesGeneralItems is_crane:boolean is_access_equipment:boolean`
- Ensure boolean defaults are `false`.

**2. Models:**
- `PreliminariesGeneralItemTemplate`:
  - Use same `enum :category` as `PreliminariesGeneralItem`.
- `PreliminariesGeneralItem`:
  - Add `is_crane` and `is_access_equipment` boolean columns.
  - Add `belongs_to :preliminaries_general_item_template, optional: true` (optional, to track source if helpful for the dropdown).

**3. Routes:**
- `resources :preliminaries_general_item_templates, path: 'p_and_g_templates'`
- Ensure P&G items have an `update` action (standard Rails).

**4. UI (Partials & Turbo Frames):**
- In `app/views/preliminaries_general_items/_preliminaries_general_item.html.erb`:
  - Add a `<select>` field containing all `PreliminariesGeneralItemTemplate` options.
  - When a template is selected, it should trigger an update to the item.
  - This can be handled by a Stimulus controller that submits the form/update when the dropdown changes.
  - The controller update should return a Turbo Stream to refresh the row with the new template values.

**5. Stimulus:**
- Update or add a controller to handle the `change` event on the template dropdown.
- It should fetch the template data (or just send the template ID to the server update action).

---

### Data Integrity Assessment

- **Primary layer:** DB | Model
- **Is this a DATA problem or DISPLAY problem?** DATA (Adding new entity and fields)

---

### Code Health Observations

| Severity | Category | Location | Description |
|----------|----------|----------|-------------|
| MEDIUM | missing-pattern | app/javascript/controllers/pg_quick_add_controller.js | Manual HTML row building. |

---

### Constraints / Guardrails

- `is_crane` and `is_access_equipment` must be `false` by default.
- Template application is a one-time copy, not a live reference.
- Use `path: 'p_and_g_templates'` for the catalogue.

---

### Split Check

**Proposed Split:**
1. **Ticket A: P&G Template Data & Catalogue:** CRUD for `/p_and_g_templates` and DB migrations.
2. **Ticket B: Row-Level Template Application:** The dropdown on the item row and the auto-populate logic.