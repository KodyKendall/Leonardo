# Feedback Log

User feedback, pain points, bugs, and UX issues.

---

## 2025-12-19 - Bug: Missing Route for Crane Selection

**Feedback:** NoMethodError when viewing tender crane selections builder page

**Context:** Navigated to on-site mobile crane breakdown section in tender builder. Page attempted to render "Add Row Button" but failed.

**Error Details:**
- Route: `/on_site_mobile_crane_breakdowns/builder` (tender_id: 10)
- View: `app/views/tender_crane_selections/_index.html.erb` line 18
- Missing: `new_tender_crane_selection_path` helper method
- Attempted call: `link_to new_tender_crane_selection_path(tender_id: ...)`

**Desired outcome:** Add Row button should display and allow users to add new crane selections to the tender

**Category:** Bug - Route/Helper Missing

---
