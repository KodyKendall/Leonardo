# Phase 1: RSB Tendering System Scope

**Timeline:** ~6 weeks  
**Status:** Ready for Stakeholder Comments  
**Document Version:** Draft

---

## 1. Purpose

RSB's tendering process currently relies on multiple Excel spreadsheets that require extensive manual work, cause version inconsistencies, and create training bottlenecks.

Phase 1 focuses on replacing the tendering workflow with one unified, reliable system that eliminates human error, standardizes calculations, and reduces preparation time.

---

## 2. Phase 1 Goals

**Primary Outcomes:**
- Centralize all tender data into one system
- Eliminate manual calculations and spreadsheet errors
- Reduce tender preparation time by 50%
- Standardize rates, rules, and configurations
- Create the foundation for budget tracking and claims in future phases

---

## 3. What We Are Building in Phase 1

### A. BOQ Import & Setup
- Upload BOQ (CSV)
- AI-assisted parsing of line items (page, item, description, unit, qty)
- Editable review screen before finalizing

### B. Rate Management
- Material supply rate updates (monthly)
- Processing rate updates (annually)
- Automatic versioning of all rate changes
- Default "second cheapest" supplier selection, with override

### C. Tender Configuration
- Inclusions/exclusions toggles (fabrication, erection, bolts, delivery, etc.)
- On-site parameters: roof area, erection rate, crane requirements
- Equipment selection (booms, scissors, telehandlers)
- Tender-level margin setting

### D. Line Item Rate Build-Up
- Automatic calculation of full rate per tonne
- Material breakdown (UB/UC, plate %, CFLC rules, etc.)
- Extra overs (castellating, curving, MPI, weld testing)
- Per-line overrides where needed
- Correct rounding rules (R50, R20, R10) applied automatically

### E. P&G (Preliminaries & General)
- Add custom P&G items (site establishment, accommodation, etc.)
- Automatic rate-per-tonne distribution
- Logic preventing double-counting with crainage/cherry pickers

### F. Tender Output
- Final tender summary page
- Section headers, subtotals, tonnage totals
- Generate client-facing PDF with RSB branding
- Submit tender + status tracking

---

## 4. What's NOT Included in Phase 1

**These are planned for later and not in the current sprint:**

- Budget tracking
- Claims processing
- Project execution tracking
- Supplier integrations / EDI
- Mobile application
- Multi-company support
- Automatic bolt threshold logic
- AI-assisted material type classification
- Accounting system integrations

This helps keep Phase 1 focused and ensures the core tender workflow is solid.

---

## 5. Success Metrics

| Metric | Target |
|--------|--------|
| Tender preparation time | 30-60 minutes per tender (vs 2-3 hours) |
| Calculation errors | Zero |
| Rate update time | Single update propagates automatically |
| Training time | 2-3 days (vs 2-4 weeks) |
| Tender throughput | 4+ BOQs per day |

---

## 6. Feedback & Ideas

We'd love your input on anything related to:
- Workflow clarity
- Pain points you want solved
- Ideas for future phases
- Improvements to the tender review process

---

## Next Steps

Once Phase 1 is validated and stable, we will expand into:
- Budget management
- Claims module
- Full project lifecycle tracking
- Reporting dashboards
- Supplier integrations

Each of these will build on the centralized tender data system created in Phase 1.

---

**Document Status:** Ready for Stakeholder Review  
**Last Updated:** [Current Date]
