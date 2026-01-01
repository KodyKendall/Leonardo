## 2026-01-01 - ENHANCEMENT: Add Quick Links to Project Rates on Tender Builder

---

### Original User Story (Agreed Upon) — THE CONTRACT

> **URL:** /tenders/43/builder
>
> **User Story:** As a user, I want quick links to Project Rates from the Builder page, so that I can easily navigate to where Shop Drawings and other rates are managed.
>
> **Current Behavior:** There are no direct links to navigate to Project Rates from the Builder view.
>
> **Desired Behavior:** The Builder page includes visible quick links to the Project Rates management page.
>
> **Verification Criteria (UI/UX):**
> - [ ] Given I am on the Tender Builder page, When I view the header or Shop Drawings section, Then I see a link to "Project Rates".
> - [ ] Given I click the link, Then I am navigated to the Project Rates page for this tender.
>
> **Business Rules:**
> (None stated - will identify the correct routing during research)

---

### Metadata

- **Category:** Enhancement - Navigation/UX
- **Severity:** Low
- **Environment:** Tender Builder (`/tenders/:id/builder`)
- **Reported by:** Domain Expert

---

### Demo Path (Step-by-Step Verification)

1. **Given** I am on a Tender Builder page (e.g., `/tenders/43/builder`), **When** I look at the top header area (next to the Tender number), **Then** I should see a "Project Rates" link.
2. **Given** I am on the same page, **When** I look at the "Shop Drawings" purple status box, **Then** I should see a "Manage Rates" link.
3. **Given** I click either link, **Then** I am navigated to the "Edit Project Rate Build Up" page for that tender.

---

### Scope

**In Scope (This Ticket):**
- Adding a "Project Rates" link to the header of `app/views/tenders/builder.html.erb`.
- Adding a "Manage Rates" link to the `app/views/tenders/_shop_drawings.html.erb` partial.
- Ensuring links use the correct `edit_tender_project_rate_build_up_path`.

**Non-Goals / Out of Scope:**
- Redesigning the Project Rates edit page.
- Adding Turbo Frame functionality to the Project Rates link (this is a standard navigation link).

---

### User-Facing Summary

As a domain expert, I often need to jump from the BOQ Builder to the Project Rates management page to adjust Shop Drawing rates or other project-level overheads. Currently, I have to navigate back through several menus. These quick links will allow me to access rates directly from where I see their impact.

---

### Current Behavior

- The Tender Builder page header displays the tender number, client, and totals, but lacks navigation to related rate management.
- The "Shop Drawings" section displays the current rate and total but provides no way to edit them.

---

### Desired Behavior

- **Header Link:** A simple "Project Rates" link using standard breadcrumb or header link styling (`link link-primary`).
- **Shop Drawings Link:** A contextual link/button inside the purple status box labeled "Manage Rates" or "Project Rates" to take the user directly to the editor.

---

### Verification Criteria (UI/UX) — VERBATIM FROM CONTRACT

- [ ] Given I am on the Tender Builder page, When I view the header or Shop Drawings section, Then I see a link to "Project Rates".
- [ ] Given I click the link, Then I am navigated to the Project Rates page for this tender.

---

### Business Rules (Domain Logic)

| Rule | Source |
|------|--------|
| Project Rates are managed via `ProjectRateBuildUp` model | Current code behavior: `app/models/tender.rb` |
| Navigation should point to the edit action of the build-up | Current code behavior: `config/routes.rb` |

---

### Implementation Notes (for Leonardo Engineer)

- **Root cause:** Missing navigation shortcuts in the UI.
- **Models & key columns:** `Tender has_one :project_rate_buildup`.
- **URL Helper:** `edit_tender_project_rate_build_up_path(@tender)`.
- **Views to edit:**
    - `app/views/tenders/builder.html.erb`: Add link in the header area (near `h1` or breadcrumbs). Use `link link-primary text-sm ml-4` or similar to stay unobtrusive.
    - `app/views/tenders/_shop_drawings.html.erb`: Add the link within the flex container of the purple box. Use `link link-primary text-sm` or a small DaisyUI button `btn btn-xs btn-outline`.

---

### Code Health Observations

| Severity | Category | Location | Description |
|----------|----------|----------|-------------|
| LOW | naming | `app/views/tenders/_shop_drawings.html.erb` | Partial name is specific to "shop drawings" but it represents a subset of "project rates". |

---

### Constraints / Guardrails

- Maintain the existing Tailwind color scheme (Purple-50/500 for the shop drawings box).
- Ensure the link is only rendered if `@tender.project_rate_buildup` exists (or just use the tender helper which handles it).

---

### Split Check (REQUIRED for complex tickets)

**Models touched:** 0
**Screens touched:** 1 (Builder page and its partial)

- [x] Ticket is small enough — proceed as single ticket
