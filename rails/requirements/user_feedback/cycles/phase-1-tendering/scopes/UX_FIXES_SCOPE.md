# UX/Turbo Fixes - Vertical Slice Scope

> **VERTICAL SLICE**: Fix page refresh issues and UI polish items. Thin slice focused on user experience.

**Timeline:** 1-2 days
**Status:** IN REVIEW
**Priority:** High
**Document Version:** 1.1
**Last Updated:** December 9, 2025

---

## Implementation Status

| Issue | Status | Severity |
|-------|--------|----------|
| Page refresh on Save Changes | ✅ Complete | High |
| "Qty" column should be "Proportion" | ✅ Complete | Medium |
| "Rsb owned" should be "RSB Owned" | ✅ Complete | Low |
| BOQ count display incorrect | ✅ Complete | Medium |

---

## 1. Problem Statement

Several UX issues identified in Dec 8 demo disrupt user workflow:

1. **Page Refresh on Add Material**: Clicking "+ Add Material" causes full page reload, losing scroll position and context
2. **Page Refresh on Save Changes**: Clicking the green checkmark to save causes full page reload
3. **Confusing Column Label**: "Qty" column in material breakdown actually represents proportion/percentage
4. **Capitalization**: "Rsb owned" in dropdown should be "RSB Owned"

These issues make the system feel unpolished and break the SPA experience.

---

## 2. User Stories

| ID | Story | AC | Priority |
|----|-------|-----|----------|
| US-UX-01 | As Demi, when I click Add Material, I want the row to appear without page refresh | Row appears, scroll position maintained | High |
| US-UX-02 | As Demi, when I click Save, I want changes saved without page refresh | Save completes, stays in same context | High |
| US-UX-03 | As Demi, I want column labels to be clear and accurate | "Qty" renamed to "Proportion" or "Material Ratio" | Medium |
| US-UX-04 | As Richard, I want RSB properly capitalized | Shows "RSB Owned" not "Rsb owned" | Low |

---

## 3. Tasks

### 3.1 Fix Add Material Page Refresh
**Priority:** High | **Est:** 0.5 days

**Root Cause:** Likely form submission not using Turbo, or missing Turbo Stream response

**Current Flow:**
1. User clicks "+ Add Material"
2. Form submits (full POST?)
3. Page reloads

**Expected Flow:**
1. User clicks "+ Add Material"
2. Stimulus controller clones template row
3. Row appears via DOM manipulation (no server request)
4. Or: Turbo Stream appends new row partial

**Investigation:**
- Check `app/javascript/controllers/nested_form_controller.js`
- Check if button has `data-turbo="false"`
- Check form `data-turbo-frame` attribute

**Fix Options:**

**Option A: Pure Stimulus (Preferred)**
```javascript
// nested_form_controller.js
addItem(event) {
  event.preventDefault() // Prevent form submission
  const template = this.templateTarget.innerHTML
  const newId = new Date().getTime()
  const content = template.replace(/NEW_RECORD/g, newId)
  this.containerTarget.insertAdjacentHTML('beforeend', content)
}
```

**Option B: Turbo Stream**
```ruby
# line_item_materials_controller.rb
def new
  @material = @line_item.materials.build
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.append("materials", partial: "fields", locals: { material: @material }) }
  end
end
```

**Files:**
- `app/javascript/controllers/nested_form_controller.js`
- `app/views/line_item_materials/_fields.html.erb`
- `app/views/line_item_material_breakdowns/_fields.html.erb`

### 3.2 Fix Save Changes Page Refresh
**Priority:** High | **Est:** 0.5 days

**Root Cause:** Form not using Turbo properly, or full form submission

**Current Flow:**
1. User edits field, clicks green checkmark
2. Full form POST
3. Page reloads

**Expected Flow:**
1. User edits field, clicks green checkmark
2. PATCH via Turbo
3. Field updates in place, success indicator shows
4. No page reload

**Investigation:**
- Check form `method` and `data-turbo` attributes
- Check controller `respond_to` format handling
- Check if Turbo Stream response is configured

**Fix:**
```erb
<%# Ensure form uses Turbo %>
<%= form_with model: @line_item, data: { turbo: true, turbo_frame: "_top" } do |f| %>
```

```ruby
# tender_line_items_controller.rb
def update
  if @line_item.update(line_item_params)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@line_item) }
      format.html { redirect_to tender_builder_path(@tender) }
    end
  end
end
```

**Files:**
- `app/controllers/tender_line_items_controller.rb`
- `app/views/tender_line_items/update.turbo_stream.erb`
- `app/views/tender_line_items/_line_item.html.erb`

### 3.3 Rename "Qty" to "Proportion"
**Priority:** Medium | **Est:** 0.25 days

Simple label change in view.

**Files:**
- `app/views/line_item_materials/_fields.html.erb`
- `app/views/line_item_material_breakdowns/_fields.html.erb`

**Change:**
```erb
<%# Before %>
<th>Qty</th>

<%# After %>
<th>Proportion</th>
<%# Or %>
<th>Material Ratio</th>
```

Also update any associated help text or tooltips.

### 3.4 Fix RSB Capitalization
**Priority:** Low | **Est:** 0.25 days

**Location:** Crane ownership dropdown

**Root Cause:** Likely enum value or titleize method

**Fix Options:**

**Option A: Fix enum display**
```ruby
# crane_rate.rb or view helper
def ownership_type_display
  case ownership_type
  when 'rsb_owned' then 'RSB Owned'
  when 'rental' then 'Rental'
  end
end
```

**Option B: Fix in view**
```erb
<%# Before %>
<%= f.select :ownership_type, CraneRate.ownership_types.keys.map(&:titleize) %>

<%# After %>
<%= f.select :ownership_type, [['RSB Owned', 'rsb_owned'], ['Rental', 'rental']] %>
```

**Files:**
- `app/models/crane_rate.rb`
- `app/views/tender_crane_selections/_form.html.erb`
- `app/views/on_site_mobile_crane_breakdowns/_form.html.erb`

---

## 4. Demo Success Criteria

1. Go to tender builder with existing line items
2. Expand line item, click Add Material
3. New material row appears WITHOUT page refresh
4. Fill in material details, click Save (green checkmark)
5. Changes save WITHOUT page refresh
6. Material breakdown shows "Proportion" or "Material Ratio" column header
7. Crane selection shows "RSB Owned" (properly capitalized)

---

## 5. Files to Modify

| File | Change |
|------|--------|
| `app/javascript/controllers/nested_form_controller.js` | Prevent default form submission |
| `app/controllers/tender_line_items_controller.rb` | Add Turbo Stream response |
| `app/views/tender_line_items/update.turbo_stream.erb` | Create if missing |
| `app/views/line_item_materials/_fields.html.erb` | Rename Qty → Proportion |
| `app/views/tender_crane_selections/_form.html.erb` | Fix RSB capitalization |
| `app/models/crane_rate.rb` | Add display helper if needed |

---

## 6. Testing Checklist

- [ ] Add Material: No page refresh
- [ ] Save Changes: No page refresh
- [ ] Edit inline: Updates in place
- [ ] Cancel edit: Reverts without refresh
- [ ] Column shows "Proportion" not "Qty"
- [ ] Dropdown shows "RSB Owned" not "Rsb owned"
- [ ] All Turbo Frames working correctly
- [ ] No JavaScript console errors
