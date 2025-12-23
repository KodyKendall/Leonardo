# Unresolved Questions

Open questions that need answers before work can proceed.

---

## 2025-12-09 - BLOCKING: Grand Total Calculation Architecture

**Question:** How should the Grand Total be calculated and updated in real-time as line items are added/modified?

**Context:** 
- Current state: Grand total is calculated once server-side on initial page load, then frozen
- User expectation: Grand total should update as she adds/edits line items and rate buildups
- Current issue: Shows R 0.00 because rate buildups aren't being populated with calculated values

**Three possible approaches:**

1. **Server-side (Form submission pattern)**
   - Each line item edit triggers a form submit
   - Server recalculates grand total
   - Entire page or container rerenders
   - ❌ Slower, less responsive (Demi expects real-time updates)

2. **Client-side (JavaScript calculation)**
   - When rate buildups are edited in Turbo frames, JS extracts values from DOM
   - JS sums them all up locally
   - Updates the grand total element
   - ✓ Fast and responsive, but brittle (selector dependencies)
   - ⚠️ Current approach is broken due to selector mismatch

3. **Hybrid (Turbo Stream broadcasts)**
   - Backend calculates grand total after each line item/rate buildup change
   - Backend broadcasts updated total via Turbo Stream
   - Frontend updates grand total element
   - ✓ Accurate (DB values), responsive, maintainable
   - Requires: After-save callbacks on LineItemRateBuildUp to recalculate Tender.grand_total

**What's your preference?** Should we:
- Fix the broken JavaScript approach (approach #2)?
- Implement Turbo Stream broadcasts (approach #3)?
- Or something else?

**Status:** BLOCKING - Can't proceed with fixes until architecture is decided

---

## 2025-12-09 - BLOCKING: Rate Buildup Calculation Service

**Question:** What service/method should calculate `LineItemRateBuildUp` fields when they're needed?

**Context:**
- Currently, when a line item is created, a blank `LineItemRateBuildUp` record is created with all rates at 0.0
- No calculation happens automatically
- This is why all rounded_rates are 0, causing the grand total to be 0

**What needs to be calculated:**
- `material_supply_rate` - Based on selected materials + waste % + proportions
- `fabrication_rate`, `overheads_rate`, etc. - Based on tender inclusions/exclusions
- `subtotal` - Sum of all included components
- `margin_amount` - Applied based on tender margin %
- `total_before_rounding` - Subtotal + margin
- `rounded_rate` - Final rate rounded per business rules (e.g., nearest R50)

**Triggers for recalculation:**
1. When line item is created - calculate initial rate buildup
2. When material supplies are selected/changed - recalculate material_supply_rate
3. When tender inclusions/exclusions toggle - recalculate all included/excluded components
4. When tender margin % changes - recalculate margin_amount and rounded_rate
5. When rate overrides are applied - use override values instead of calculated ones

**Question:** 
- Should this be a separate `LineItemRateBuildUpCalculator` service?
- Or methods on `TenderLineItem` or `LineItemRateBuildUp` model?
- When should it be triggered - before_save callbacks, after_save callbacks, or explicit service call?

**Status:** BLOCKING - Grand total can't be accurate until this is built

---

## 2025-12-09 - CLARIFICATION: What's the current state of rate buildup configuration UI?

**Question:** Can Demi currently select materials and configure rate buildups in the tender builder, or does that happen elsewhere?

**Context:**
- The builder view shows line items but I need to understand:
  - Where/how are material supplies selected for each line item?
  - Where/how are tender inclusions/exclusions toggled?
  - Is there a rate buildup detail view/edit interface?

**This matters because:** The grand total can only be accurate once we know:
- Are material supplies already being selected somewhere? (If yes, we just need to trigger recalculation)
- Or is the UI for material selection still to be built?

**Status:** Open - Affects scope of fix

---

## 2025-12-09 - CLARIFICATION: Tender grand_total field

**Question:** Should we store `Tender.grand_total` in the database, or should it always be calculated from line items?

**Current schema:**
- `tenders` table doesn't have a `grand_total` column
- Grand total is currently calculated purely from line items in the view

**Observation:**
- Per REQUIREMENTS.md section 5.2.2, Tender should have: `grand_total` field (Final tender value)
- This suggests we should store it in the DB

**Question:**
- Should `Tender.grand_total` be a calculated/cached field?
- Or should it be populated only when tender is submitted/finalized?
- How often does it need to update (every line item change, or on save/submission)?

**Status:** Open - Architecture decision needed

---

## 2025-12-10 - What is the "New Rate Set" button for?

**Question:** On the Monthly Material Supply Rates page, there are two buttons that both link to `new_monthly_material_supply_rate_path`:
1. "Create Material Supplies for this Month" (green button)
2. "New Rate Set" (blue button)

What is the intended purpose/difference between these two buttons?

**Context:**
- Both buttons appear to do the same thing (route to the new form)
- This is confusing UX
- There might be a longer-term plan (Kody to clarify)

**Status:** Open - Awaiting clarification from Kody

---
