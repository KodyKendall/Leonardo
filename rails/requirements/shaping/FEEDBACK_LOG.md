# Feedback Log

User feedback, pain points, bugs, and UX issues.

---

## 2025-12-01 - Bug: Missing Route for Crane Selection

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

## 2025-12-08 - Bug: BOQ Completion Message Inaccurate

**Feedback:** Message displayed "17 line items ready to be transferred" but the actual BOQ contained 25 line items

**Context:** After parsing BOQ in tender E2025001, the "Next Step" card showed:
- Message: "17 line items ready to be transferred to the tender builder"
- Actual count: 25 line items (visible in the card details and builder)

**Desired outcome:** Completion message should accurately reflect the true number of parsed line items from the BOQ

**Category:** Bug - Data Count Mismatch

---

## 2025-12-08 - Pain Point: BOQ Category Allocation Unclear

**Feedback:** Elmarie does not always understand how to allocate the correct category for each line item during BOQ parsing

**Context:** During BOQ setup in tender E2025001, categorizing line items is a critical step that Elmarie struggles with. Category choice affects rate calculations downstream.

**Pain Points:**
- Category selection rules are not intuitive or documented
- No guidance on how to distinguish between similar categories (e.g., when is something "Steel Sections" vs another type)
- Elmarie often needs to ask Demi for help or second-guessing happens after submission

**Desired outcome:** Clear, accessible guidance for Elmarie to confidently assign categories during BOQ parsing without requiring QS review or assistance

**Category:** UX/Pain Point - User Guidance Missing

---

## 2025-12-08 - UX Issue: Material Split Column Header "Qty" is Confusing

**Feedback:** Column header "Qty" for the material split/breakdown is misleading and unclear

**Context:** In the tender builder, the material split column shows percentage breakdowns (e.g., 85% UB/UC, 15% Plate), but the header says "Qty" which normally means quantity/number, not percentage or proportion

**Desired outcome:** Rename header to something clearer like "Proportion", "%" or "Material %"

**Category:** UX - Confusing Label

---

## 2025-12-08 - Feature Request: Category-Based Rounding Rules

**Feedback:** Need ability to use finer rounding increments (R10 or R20) for specific line item categories, not just the default R50

**Context:** Current system rounds all rates to nearest R50. However, for certain categories like:
- Corrosion Protection line items
- Chemical anchor line items  
- Mechanical anchor line items

...a smaller rounding increment (R10 or R20) would be more appropriate for competitive pricing.

**Proposed Solution:** Add rounding option selection during initial BOQ setup (after parsing). Allow per-category rounding rules:
- Default: R50 (Steel Sections, Bolts, Gutters, etc.)
- Optional: R20 or R10 (for Corrosion Protection, anchors, etc.)

**Desired outcome:** Flexible rounding that reflects business requirements without manual override of every line item

**Category:** Feature Request - Business Rules

---
