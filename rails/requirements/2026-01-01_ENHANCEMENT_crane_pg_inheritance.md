## 2026-01-01 - ENHANCEMENT: Inherit Rate and Quantity for Crane P&G Items

---

### Original User Story (Agreed Upon) — THE CONTRACT

> **URL:** /tenders/43/builder
>
> **User Story:** As an estimator, I want P&G items marked as cranes to automatically default to both the tender's crane breakdown rate and total tonnage, so that I don't have to manually sync pricing and quantities between different sections.
>
> **Current Behavior:** P&G items do not inherit rates or quantities from the mobile crane breakdown or tender totals.
>
> **Desired Behavior:** When a P&G item is added and its template has `is_crane` enabled:
> 1. **Rate** defaults to the tender's `OnSiteMobileCraneBreakdown` "Cost Per Tonne".
> 2. **Quantity** defaults to the tender's "TOTAL TONNES".
>
> **Verification Criteria (UI/UX):**
> - [ ] Given a tender with 22.00 total tonnes and a R 1,300 crane rate, When I add a P&G item with `is_crane: true`, Then the quantity defaults to 22.00 and the rate defaults to R 1,300.
> - [ ] Given defaulted values, When I edit the P&G item, Then I can still manually override both quantity and rate.
>
> **Business Rules:**
> - [ ] Inherit rate from tender's crane breakdown if `is_crane` is true — Source: User said "the rate should be inherited..."
> - [ ] Inherit quantity from tender's total tonnes if `is_crane` is true — Source: User said "the quantity should be inherited..."
> - [ ] Inherited values are defaults only (overridable) — Source: User said "The user should be able to override it"

---

### Metadata

- **Category:** Enhancement - Data Inheritance
- **Severity:** Medium
- **Environment:** /tenders/:id/builder (P&G Table)
- **Reported by:** Domain Expert

---

### Demo Path (Step-by-Step Verification)

1. **Given** I am on a Tender Builder page (`/tenders/43/builder`),
2. **And** the "TOTAL TONNES" display (bottom of page) shows "22.00",
3. **And** the "Cost Per Tonne" in the Crane Breakdown section is "R 1,300.00",
4. **When** I click "Add Item" in the P&G section and select a template where `is_crane` is checked,
5. **Then** the new P&G item row should automatically populate with **Quantity: 22.00** and **Rate: 1,300.00**.
6. **When** I manually change the Rate to "1,500.00" and click Save,
7. **Then** the P&G item should persist with the overridden value of "1,500.00".

---

### Scope

**In Scope (This Ticket):**
- Automatic population of Rate/Quantity for P&G items when `is_crane` template is selected.
- Server-side defaults in the `PreliminariesGeneralItem` model.
- Client-side (Stimulus) updates for instant feedback in the builder UI.
- Preservation of manual overrides after the initial default is set.

**Non-Goals / Out of Scope:**
- Retroactively updating existing P&G items (this is for new items/edits).
- Locking the fields permanently (they must remain overridable).
- Real-time "live" syncing if tonnage changes *after* the P&G item is already saved (unless the user re-edits).

---

### User-Facing Summary

As an estimator, I have to manually copy the "Total Tonnes" and "Cost Per Tonne" (from the Crane Breakdown) into my P&G line items when adding cranes. This is tedious and prone to error. This change will automatically pull those values as defaults when I select a crane template, while still letting me change them if needed.

---

### Current Behavior

- P&G items use generic defaults (Rate: 0, Quantity: 1) regardless of whether they are cranes or not.
- The `is_crane` flag on the `PreliminariesGeneralItemTemplate` is ignored during the item creation/population flow.
- Users must manually find the tonnage and crane rate on the page and type them into the P&G row.

---

### Desired Behavior

- When a `PreliminariesGeneralItem` is initialized or associated with a template where `is_crane == true`, it should look up the parent `Tender`'s `total_tonnage` and its `on_site_mobile_crane_breakdown.crainage_rate_per_tonne`.
- These values should be applied to the `quantity` and `rate` attributes respectively.
- The UI should reflect these values immediately upon template selection so the user can see what is being applied.

---

### Verification Criteria (UI/UX) — VERBATIM FROM CONTRACT

- [ ] Given a tender with 22.00 total tonnes and a R 1,300 crane rate, When I add a P&G item with `is_crane: true`, Then the quantity defaults to 22.00 and the rate defaults to R 1,300.
- [ ] Given defaulted values, When I edit the P&G item, Then I can still manually override both quantity and rate.

---

### Business Rules (Domain Logic)

| Rule | Source |
|------|--------|
| Inherit rate from tender's crane breakdown if `is_crane` is true | User said: "the rate should be inherited from the specific tender" |
| Inherit quantity from tender's total tonnes if `is_crane` is true | User said: "the quantity should be inherited from [TOTAL TONNES display]" |
| Inherited values are defaults only (overridable) | User said: "The user should be able to override it" |
| Crane rate should be rounded to nearest R20 | Observed in `OnSiteMobileCraneBreakdown#crainage_rate_per_tonne` |

---

### Implementation Notes (for Leonardo Engineer)

- **Root cause:** The P&G creation flow in both the controller and Stimulus lacks logic to check the `is_crane` flag and pull associated tender data.
- **Models & key columns:**
  - `PreliminariesGeneralItem`: Needs a presetter method.
  - `PreliminariesGeneralItemTemplate`: Has `is_crane: boolean`.
  - `Tender`: Has `total_tonnage` (decimal).
  - `OnSiteMobileCraneBreakdown`: Has method `crainage_rate_per_tonne`.
- **Logic:**
  - Add `set_crane_defaults` to `PreliminariesGeneralItem` that sets `rate` and `quantity` if `preliminaries_general_item_template&.is_crane?`.
  - **Controller:** Update `PreliminariesGeneralItemsController#create` to ensure these defaults are applied before the first save.
  - **Stimulus:** Update `pg_inline_edit_controller.js#applyTemplate()` to check the template's `is_crane` flag. If true, it should populate the rate/quantity inputs from data attributes on the builder page (the tonnage and crane rate are already rendered in the UI).
- **Paths:**
  - Model: `app/models/preliminaries_general_item.rb`
  - Controller: `app/controllers/preliminaries_general_items_controller.rb`
  - JS: `app/javascript/controllers/pg_inline_edit_controller.js`

---

### Code Health Observations

| Severity | Category | Location | Description |
|----------|----------|----------|-------------|
| MEDIUM | coupling | `pg_inline_edit_controller.js` | UI relies on specific HTML IDs for tonnage; consider using data-attributes for cleaner selection. |
| LOW | architecture | `PreliminariesGeneralItem` | Consider a dedicated "synced" flag if we ever want to auto-refresh these values when tonnage changes. |

---

### Constraints / Guardrails

- Manual overrides must be preserved (don't overwrite a user-entered value on every save).
- If no crane breakdown exists for the tender, rate should default to 0 gracefully.
- If tonnage is 0, quantity should default to 1 (per existing app behavior for P&G).

---

### Split Check (REQUIRED)

**Models touched:** `PreliminariesGeneralItem`
**Screens touched:** Tender Builder (`/tenders/:id/builder`)

- [x] Ticket is small enough — proceed as single ticket