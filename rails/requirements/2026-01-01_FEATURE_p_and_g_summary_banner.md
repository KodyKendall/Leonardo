## 2026-01-01 - FEATURE: Add P&Gs Summary Banner to Tender Builder

---

### Original User Story (Agreed Upon) — THE CONTRACT

> **URL:** `/tenders/43/builder`
>
> **User Story:** As a user, I want to be able to view the P&Gs summary/banner, similar to how Shop Drawings currently works. Where it will show the Total from all the P&Gs items, with a link to the P&Gs as well for this tender.
>
> **Current Behavior:** The P&Gs summary is missing from the tender builder header. P&Gs totals are not currently reflected in the Grand Total calculation on this page.
>
> **Desired Behavior:** A P&Gs summary banner appears in the header (styled like Shop Drawings). It displays the total for all P&G items and links to the P&Gs management page. The Grand Total should also include the P&Gs total.
>
> **Verification Criteria (UI/UX):**
> - [ ] Given I am on the tender builder page, When I view the header, Then I see a "P&Gs" summary banner below or next to Shop Drawings.
> - [ ] Given the P&Gs banner is visible, When I check the content, Then I see the calculated total for all P&G items.
> - [ ] Given the P&Gs banner is visible, When I click the action link (e.g., "Manage P&Gs"), Then I am taken to the P&Gs management page for that tender.
>
> **Business Rules:**
> - [ ] P&Gs banner should match the "Shop Drawings" styling — Source: User said "similar to how Shop Drawings currently works"
> - [ ] Total must reflect the sum of all P&G items for the current tender — Source: User said "show the Total from all the P&Gs items"

---

### Metadata

- **Category:** Feature - UI/UX
- **Severity:** Medium
- **Environment:** Tender Builder (`/tenders/:id/builder`)
- **Reported by:** Domain Expert

---

### Demo Path (Step-by-Step Verification)

1. **Given** I have a tender with P&G items (e.g., Fixed/Duration based costs), **When** I navigate to the Tender Builder page, **Then** I should see a green/teal banner for "P&Gs" (similar to the purple Shop Drawings banner).
2. **Given** the P&Gs banner is visible, **When** I compare the "Total" in the banner to the sum of items on the P&Gs management page, **Then** they should match.
3. **Given** I am on the Builder page, **When** I click "Manage P&Gs" in the banner, **Then** I should be redirected to `/tenders/:id/p_and_g`.
4. **Given** I add or update a P&G item on the P&G page and return to the Builder, **When** I view the Grand Total, **Then** it should include the P&Gs total in its sum.

---

### Scope

**In Scope (This Ticket):**
- Create `_p_and_g_summary.html.erb` partial.
- Integrate the summary banner into `app/views/tenders/builder.html.erb`.
- Update `Tender#recalculate_grand_total!` to include P&Gs items.
- Add real-time broadcasts to `PreliminariesGeneralItem` to update the builder page when items change.

**Non-Goals / Out of Scope:**
- Editing P&G items directly on the Builder page (link to management page is sufficient).
- Changes to the P&Gs management page UI itself.

---

### User-Facing Summary

As a domain expert, I need to see the P&Gs total directly on the Tender Builder page so I don't have to navigate away to check the progress of Preliminaries. This banner provides an at-a-glance summary and a quick link to manage those costs, keeping the builder as the "source of truth" for the whole tender.

---

### Current Behavior

- The `app/views/tenders/builder.html.erb` page renders the "Shop Drawings" summary but has no placeholder for P&Gs.
- `Tender#recalculate_grand_total!` only sums line items and shop drawings.
- `PreliminariesGeneralItem` does not trigger any broadcasts to the builder stream.

---

### Desired Behavior

- A self-contained partial `tenders/_p_and_g_summary.html.erb` handles the display.
- The banner uses a distinct color (e.g., `bg-teal-50` or `bg-green-50`) to differentiate from Shop Drawings.
- Any change to P&G items triggers a recalculation of the Tender's grand total and a broadcast update to the builder page.

---

### Verification Criteria (UI/UX) — VERBATIM FROM CONTRACT

- [ ] Given I am on the tender builder page, When I view the header, Then I see a "P&Gs" summary banner below or next to Shop Drawings.
- [ ] Given the P&Gs banner is visible, When I check the content, Then I see the calculated total for all P&G items.
- [ ] Given the P&Gs banner is visible, When I click the action link (e.g., "Manage P&Gs"), Then I am taken to the P&Gs management page for that tender.

---

### Business Rules (Domain Logic)

| Rule | Source |
|------|--------|
| P&Gs banner should match the "Shop Drawings" styling | User said: "similar to how Shop Drawings currently works" |
| Total must reflect the sum of all P&G items for the current tender | User said: "show the Total from all the P&Gs items" |
| Grand Total must include P&Gs | **ASSUMPTION:** Required for data integrity (Grand Total should represent the full tender value) |

---

### Implementation Notes (for Leonardo Engineer)

- **Root cause:** Missing UI component and broadcast logic for P&Gs in the builder flow.
- **Models & key columns:**
  - `PreliminariesGeneralItem`: `quantity`, `rate`, `tender_id`.
  - `Tender`: `grand_total`.
- **Important callbacks & associations:**
  - Add `after_commit :broadcast_builder_update` to `PreliminariesGeneralItem`.
  - This callback should call `tender.recalculate_grand_total!` and broadcast the `p_and_g_summary` partial.
- **Key views/partials, Turbo frames:**
  - Create `app/views/tenders/_p_and_g_summary.html.erb` with ID `tender_#{tender.id}_p_and_g_summary`.
  - Wrap the banner in the partial with the turbo frame.
  - Render it in `builder.html.erb` near `render "tenders/shop_drawings"`.
- **Routes:**
  - Use `tender_preliminaries_general_items_path(tender)` for the "Manage P&Gs" link.

---

### Code Health Observations

| Severity | Category | Location | Description | Suggested Action |
|----------|----------|----------|-------------|------------------|
| MEDIUM | architecture | `Tender#recalculate_grand_total!` | Calculation is becoming brittle as more cost components are added. | Consider a more modular calculation strategy (quick fix) |
| LOW | missing-pattern | `PreliminariesGeneralItem` | Lacks standard broadcast pattern used by other builder components. | Add broadcast callbacks (quick fix) |

---

### Constraints / Guardrails

- The P&Gs total should be calculated on the server, not in JavaScript.
- Use the existing `tender_#{id}_builder` turbo stream channel.

---

### Unresolved Questions

| # | Risk | Question | Recommended Default |
|---|------|----------|---------------------|
| 1 | Low | Preferred color for the P&Gs banner? | Teal/Green (different from purple Shop Drawings) — proceed with this |

---

### Split Check

**Models touched:** `Tender`, `PreliminariesGeneralItem`
**Screens touched:** `Tender Builder`

- [x] Ticket is small enough — proceed as single ticket
