# Feature Requests & Feedback

## Material Rate Month Selection (Backdate Pricing)

**Date:** 2025-01-XX  
**Category:** Feature Request  
**Priority:** Medium  
**User:** Demi (QS)  

### Request
When building a tender, allow users to select which month's material rates to use, rather than always defaulting to the current month. This enables:
- Backdating tender prices to a previous month
- Re-doing tenders with historical rate sets
- Comparing pricing across different rate snapshots

### Current Behavior
System pulls material rates from the current/latest month automatically. No option to select historical rate sets.

### Desired Behavior
- Add a **Rate Month Selector** at the tender level (or at material composition level)
- Show dropdown of available months with rate versions
- Allow user to pick a specific month (e.g., "November 2024 rates") 
- All material costs for that tender recalculate using the selected month's rates
- Display which month's rates are active on the tender

### Use Cases
1. **Backdate a Price**: Client wants a quote based on last month's pricing
2. **Re-do a Tender**: Need to re-quote using older rates for comparison or re-submission
3. **Rate Version Tracking**: See how pricing would have looked at different points in time

### Acceptance Criteria
- [ ] User can select rate month when creating/editing a tender
- [ ] Material rates pull from the selected month, not just current month
- [ ] UI shows which month's rates are in use
- [ ] All calculations recalculate when month changes
- [ ] Rate version is recorded in tender audit trail

---
