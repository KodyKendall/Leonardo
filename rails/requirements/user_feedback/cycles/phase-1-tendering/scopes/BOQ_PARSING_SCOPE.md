# BOQ Parsing Improvements - Vertical Slice Scope

> **VERTICAL SLICE**: Fix BOQ parsing reliability and improve count display accuracy. Thin slice focused on parsing stability.

**Timeline:** 2-3 days
**Status:** IN PROGRESS
**Priority:** High
**Document Version:** 1.0
**Last Updated:** December 8, 2025

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| CSV Upload | ✅ Complete | File validation, storage working |
| CSV Preview | ✅ Complete | Row display with header detection |
| AI Parsing Chat | ✅ Complete | LlamaBot integration, boq_parser agent |
| Line Item Creation | ✅ Complete | Creates TenderLineItem records |
| Category Suggestion | ✅ Complete | AI suggests categories |
| Item Count Display | 🔴 Bug | Shows wrong count (17 vs 25 actual) |
| Large BOQ Handling | 🔴 Pending | >25 items needs testing |
| Parsing Progress | ✅ Complete | Step-by-step feedback working |
| Transfer to Builder | ✅ Complete | Workflow from BOQ to Builder |

---

## 1. Problem Statement

BOQ parsing currently has reliability issues identified in Dec 8 demo:
1. **Count Discrepancy**: System showed "17 items ready to transfer" but actual BOQ had 25 items
2. **Large BOQ Handling**: Untested with BOQs >25 items
3. **Category Allocation**: Elmarie needs guidance on correct categories

---

## 2. User Stories

| ID | Story | AC | Priority |
|----|-------|-----|----------|
| US-BOQ-01 | As Elmarie, I want to see the correct item count after parsing | Count matches actual parsed items | High |
| US-BOQ-02 | As Elmarie, I want BOQs with 50+ items to parse successfully | Large BOQ parses without timeout/error | High |
| US-BOQ-03 | As Elmarie, I want guidance on which category to select | Tooltip or help text per category | Medium |

---

## 3. Tasks

### 3.1 Fix Item Count Display (Bug)
**Priority:** High | **Est:** 0.5 days

**Root Cause:** Likely caching issue or stale count in view

**Files to Check:**
- `app/views/boqs/show.html.erb` - Count display
- `app/controllers/boqs_controller.rb` - Count calculation
- `app/models/boq.rb` - Item associations

**Fix:**
1. Ensure count is calculated from `boq.boq_items.count` not cached value
2. Add Turbo Stream to update count after parsing completes
3. Add refresh button to manually re-fetch count

**Acceptance Criteria:**
- [ ] Upload 25-item BOQ
- [ ] Parse completes
- [ ] Count shows "25 items ready to transfer"
- [ ] Refresh updates count if stale

### 3.2 Test Large BOQ Handling
**Priority:** High | **Est:** 1 day

**Test Cases:**
1. 25-item BOQ (current working size)
2. 50-item BOQ
3. 100-item BOQ
4. 200-item BOQ (stress test)

**Potential Issues:**
- API timeout
- Memory limits
- Token limits in AI response

**Files to Check:**
- `langgraph/agents/boq_parser/nodes.py` - Parsing logic
- `app/services/boq_parsing_service.rb` (if exists)
- `config/initializers/llama_bot.rb` - Timeout settings

**Fix Options:**
1. Batch parsing (parse in chunks of 25)
2. Increase timeout limits
3. Streaming response handling
4. Background job processing with progress updates

### 3.3 Category Allocation Guidance
**Priority:** Medium | **Est:** 0.5 days

**Categories Available:**
- Steel Sections
- Paintwork
- Bolts
- Anchors (Chemical)
- Anchors (Mechanical)
- HD Bolts
- Gutters
- CFLC
- Plate
- Provisional Sums

**Implementation:**
1. Add tooltip/info icon next to category dropdown
2. Show description on hover: "Steel Sections: UB, UC, PFC, I-beams, angles"
3. Consider AI auto-categorization improvement

---

## 4. Demo Success Criteria

1. Upload real RSB BOQ with 25+ items
2. Parsing completes without error
3. Count displays "25 items ready to transfer" (matches actual)
4. Click Transfer to Builder
5. All 25 items appear in tender builder
6. Categories are reasonably suggested

---

## 5. Files to Modify

| File | Change |
|------|--------|
| `app/views/boqs/show.html.erb` | Fix count display, add refresh |
| `app/controllers/boqs_controller.rb` | Ensure accurate count calculation |
| `langgraph/agents/boq_parser/nodes.py` | Test/fix large BOQ handling |
| `app/views/boq_items/_form.html.erb` | Add category tooltips |

---

## 6. Rollover Risk

If large BOQ handling requires significant rework:
- Scope down to fix count bug only (0.5 days)
- Log large BOQ as known limitation
- Plan batch parsing for Sprint 2
