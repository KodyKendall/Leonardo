# Project Manager Skill

## Purpose

Act as a Shape Up-style project manager for the RSB Tendering System. Research the codebase, audit requirements, update documentation, plan vertical slices, and ensure all stakeholders have clarity on progress and next steps.

---

## When to Use This Skill

Invoke this skill when:
- Starting a new week/sprint and need to plan work
- After a stakeholder meeting with new feedback
- Requirements seem out of sync with implementation
- Need to break down work into vertical slices
- Preparing for a demo or review session

---

## Standard Operating Procedure

### Phase 1: Research & Audit (Read-Only)

**1.1 Explore Current Implementation**
```
Launch Explore agents to understand:
- What's actually built in the Rails app (controllers, models, views)
- What Stimulus controllers exist and their functionality
- What routes are defined
- What seed data exists
```

**1.2 Read All Requirements Documents**
```
Key files to read:
- /rails/requirements/REQUIREMENTS.md (master business requirements)
- /rails/requirements/user_feedback/cycles/phase-1-tendering/scopes/*.md (all scope docs)
- /rails/requirements/user_feedback/cycles/phase-1-tendering/sprints/*/*.md (sprint/week docs)
- /rails/requirements/shaping/FEEDBACK_LOG.md (user feedback)
- /rails/requirements/conversations/*.txt (stakeholder conversations)
```

**1.3 Identify Conflicts & Gaps**
```
Look for:
- Features documented as "planned" but already built
- Features documented as "complete" but actually missing
- Business rules in REQUIREMENTS.md not reflected in scopes
- User feedback not captured in scope documents
- Inconsistent status across documents
```

---

### Phase 2: Update Documentation

**2.1 Update Master Phase Scope**
```
File: /rails/requirements/user_feedback/cycles/phase-1-tendering/scopes/PHASE-1-TENDERING_SCOPE.md

Add/Update:
- Implementation Status Summary table (🟢 Complete / 🟡 Partial / 🔴 Not Started)
- Document Version and Last Updated date
- Vertical Slice Scopes section linking to individual scope docs
- Completed Vertical Slices section
```

**2.2 Update Sprint Document**
```
File: /rails/requirements/user_feedback/cycles/phase-1-tendering/sprints/sprint-X/SPRINT-X.md

Add/Update:
- Sprint Status Summary table (week-by-week)
- Key Outcomes Achieved vs Pending
- Implementation Status by Feature (detailed checklist)
- Known Issues & Bugs section
- Rollover to Next Sprint section
- Stakeholder Feedback section
```

**2.3 Update Week Documents**
```
Files: /rails/requirements/user_feedback/cycles/phase-1-tendering/sprints/sprint-X/week-N.md

Add/Update:
- Vertical Slice Breakdown table with links to scope docs
- Recommended Build Order (thinnest first)
- Status for each scope item
- Stakeholder meeting schedule
```

**2.4 Update Feedback Log**
```
File: /rails/requirements/shaping/FEEDBACK_LOG.md

Add entries for:
- Bugs discovered during demos
- Feature requests from stakeholders
- UX issues identified
- Business rule clarifications
```

---

### Phase 3: Create Vertical Slice Scopes

**3.1 Shape Up Principles**
```
- Appetite: Fixed time, variable scope (1-2 days for small, 2-3 days for medium)
- Thin slices: Full stack (model → controller → view → stimulus)
- Independent: Can be built and demoed without other slices
- Demo-able: Clear success criteria that can be shown to stakeholders
```

**3.2 Vertical Slice Scope Template**
```markdown
# [Feature Name] - Vertical Slice Scope

> **VERTICAL SLICE**: [One sentence description]

**Timeline:** X days
**Status:** Not Started / In Progress / Complete
**Priority:** High / Medium / Low
**Document Version:** 1.0
**Last Updated:** [Date]

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| [Component 1] | ✅/🟡/🔴 | [Notes] |

---

## 1. Problem Statement
[What problem does this solve?]

---

## 2. User Stories

| ID | Story | AC | Priority |
|----|-------|-----|----------|
| US-XXX-01 | As [user], I want [feature] | [Acceptance criteria] | High |

---

## 3. Tasks

### 3.1 [Task Name]
**Priority:** High | **Est:** X days

**Files:**
- `app/path/to/file.rb`

**Implementation:**
[Code sketch or description]

---

## 4. Demo Success Criteria

1. [Step 1]
2. [Step 2]
3. [Specific outcome to verify]

---

## 5. Files to Modify

| File | Change |
|------|--------|
| `app/path/file.rb` | [Description] |

---

## 6. Testing Checklist

- [ ] [Test case 1]
- [ ] [Test case 2]
```

**3.3 Slice Sizing Guidelines**
```
Small (1-2 days):
- Bug fixes (UX issues, display bugs)
- Label/copy changes
- Single model calculation
- One Stimulus controller fix

Medium (2-3 days):
- Auto-population feature (lookup + display + save)
- New calculation engine
- CRUD for new nested resource
- Integration between two existing features

Large (3-5 days - consider breaking down):
- New major UI section
- Complex multi-step workflow
- New AI integration
```

---

### Phase 4: Prioritize & Sequence

**4.1 Build Order Principles**
```
1. Quick wins first (builds momentum, improves demo quality)
2. Unblock dependencies (if B depends on A, do A first)
3. Core engine before polish (calculations before PDF output)
4. User-facing bugs before internal improvements
```

**4.2 Recommended Sequencing**
```
Day 1: UX/Bug fixes (quick wins)
Day 1-2: Data fixes (BOQ parsing, seed data)
Day 2-4: Core calculations (rate engine, crane costs)
Day 4-5: Integration (P&G, output)
```

**4.3 Update Week Document with Build Order**
```markdown
### Recommended Build Order (Thinnest First)

**Day 1: [Category] (Quick Wins)**
- [Task 1]
- [Task 2]

**Day 2-3: [Category] (Core Engine)**
- [Task 1]
- [Task 2]
```

---

### Phase 5: Communicate Status

**5.1 Status Indicators**
```
✅ Complete - Fully implemented and tested
🟡 Partial - UI done but logic pending, or vice versa
🔴 Not Started - No implementation yet
🟡 In Progress - Currently being worked on
🔴 Bug - Known issue needs fixing
```

**5.2 Key Tables to Maintain**

**Sprint Status Summary:**
```markdown
| Week | Dates | Status | Key Deliverables |
|------|-------|--------|------------------|
| 1 | Nov 24-28 | ✅ COMPLETE | [Deliverables] |
| 2 | Dec 1-5 | ✅ COMPLETE | [Deliverables] |
| 3 | Dec 8-12 | 🟡 IN PROGRESS | [Deliverables] |
```

**Vertical Slice Table:**
```markdown
| Slice | Scope Doc | Priority | Est. Days | Status |
|-------|-----------|----------|-----------|--------|
| [Name] | [Link] | High | 1-2 | Not Started |
```

**Implementation Status:**
```markdown
| Task | Status |
|------|--------|
| [Task name] | ✅ Complete |
| [Task name] | 🔴 Pending |
```

---

## File Structure Reference

```
rails/requirements/
├── REQUIREMENTS.md                    # Master business requirements
├── TECHNICAL_REQUIREMENTS.md          # Database schema, calculations
├── shaping/
│   ├── FEEDBACK_LOG.md               # User feedback tracking
│   ├── BETS.md                       # Upcoming cycle pitches
│   └── RAW_IDEAS.md                  # Unshaped ideas
├── conversations/                     # Stakeholder conversation logs
│   └── Dec-08-25-Richard-Spencer.txt
└── user_feedback/cycles/phase-1-tendering/
    ├── scopes/
    │   ├── Phase-1-Scope.md              # Master phase scope
    │   ├── TENDER_BUILDER_SCOPE.md       # Vertical slice
    │   ├── CRANE_CALC_SCOPE.md           # Vertical slice
    │   ├── BOQ_PARSING_SCOPE.md          # Vertical slice
    │   ├── RATE_AUTOPOPULATION_SCOPE.md  # Vertical slice
    │   └── UX_FIXES_SCOPE.md             # Vertical slice
    └── sprints/
        ├── sprint-1-nov24-dec12/
        │   ├── SPRINT-1.md               # Sprint overview
        │   ├── week-1.md
        │   ├── week-2.md
        │   └── week-3.md
        └── sprint-2-dec15-jan2/
            ├── SPRINT-2.md
            ├── week-4.md
            ├── week-5.md
            └── week-6.md
```

---

## Checklist: Weekly Planning Session

```markdown
## Weekly Planning Checklist

### Research
- [ ] Read latest stakeholder conversation
- [ ] Check FEEDBACK_LOG.md for new items
- [ ] Explore codebase for recent changes
- [ ] Identify what's actually implemented vs documented

### Audit
- [ ] Compare scope docs to implementation
- [ ] Flag conflicts or outdated status
- [ ] Note missing business rules

### Update Documents
- [ ] Update Phase-1-Scope.md status table
- [ ] Update SPRINT-X.md with current status
- [ ] Update week-N.md with vertical slices
- [ ] Add new items to FEEDBACK_LOG.md
- [ ] Update REQUIREMENTS.md if business rules changed

### Plan Vertical Slices
- [ ] Identify remaining work
- [ ] Break into thin, demo-able slices
- [ ] Create scope doc for each slice (if missing)
- [ ] Estimate days per slice
- [ ] Sequence by dependencies and quick wins

### Communicate
- [ ] Update status tables with current state
- [ ] Link all scope docs from sprint/week docs
- [ ] Note stakeholder meeting schedule
- [ ] Flag any blockers or risks
```

---

## Shape Up Methodology Reference

**Key Concepts:**
- **Appetite**: How much time we're willing to spend (fixed)
- **Scope**: What gets built (variable, hammered to fit appetite)
- **Shaping**: Define the problem and solution boundaries before building
- **Betting**: Commit to shaped work for a 6 week, 2 sprint (3 weeks per sprint) cycle
- **Building**: Teams have autonomy within shaped boundaries

**Vertical Slice Benefits:**
- Reduces risk (ship something working quickly)
- Enables demo-driven development
- Provides natural checkpoints
- Allows parallel work when slices are independent

**Anti-patterns to Avoid:**
- Horizontal slices (all models, then all controllers, then all views)
- Big bang integration (build everything, integrate at end)
- Scope creep (adding "nice to haves" mid-slice)
- Status theater (updating docs without verifying implementation)
