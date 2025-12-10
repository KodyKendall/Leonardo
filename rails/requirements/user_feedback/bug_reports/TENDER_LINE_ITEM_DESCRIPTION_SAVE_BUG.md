# Bug Report: Tender Line Item Description Not Saving

**Reporter:** Demi (Quantity Surveyor)  
**Date:** 2025-12-09  
**Severity:** High  
**Status:** Diagnosed - Ready for Engineer Mode  

---

## Problem Statement

When editing the "Description" field (item_description) on a tender line item in the builder and clicking the blue Save button, **the changes do not persist**. The form appears to submit, but upon page refresh, the description reverts to its original value.

### Current Behavior
1. User navigates to Tender #93, Line Item #122
2. Changes "Fabrication" description to something else (e.g., "Custom Fabrication")
3. Clicks the blue "Save" button
4. Form appears to process (no error displayed)
5. Page refreshes manually → description has NOT been saved
6. Description still shows original value "Fabrication"

### Expected Behavior
1. User types new description value
2. Clicks Save button
3. Changes persist to database
4. Page updates to reflect new value
5. Unsaved indicator disappears

---

## Investigation Summary

### Code Review Findings

#### ✅ Database Schema
- `tender_line_items` table HAS `item_description` TEXT column (line 399 of schema.rb)
- Field properly typed as TEXT
- No constraints blocking updates

#### ✅ Model Layer (tender_line_item.rb)
- Model accepts `:item_description` through strong parameters
- No validations preventing empty/null descriptions
- Model properly associated with tender
- after_create callbacks handle line_item_rate_build_up & line_item_material_breakdown
- **NO ISSUE FOUND HERE**

#### ✅ Controller Layer (tender_line_items_controller.rb:117-138)
- `tender_line_item_params` method permits `:item_description` on line 119
- Update action (line 74-87) calls `.update(tender_line_item_params)`
- Responds with turbo_stream on success
- **NO ISSUE FOUND HERE**

#### ✅ View Layer (_tender_line_item.html.erb:39)
- Form properly renders with `form_with model: [tender_line_item.tender, tender_line_item]`
- Form correctly includes `dirty-form` controller on line 8
- Description input field uses `f.text_field :item_description` on line 39
- Save button on line 71 properly configured with `data: { dirty_form_target: "submit" }`
- **NO ISSUE FOUND HERE**

#### ✅ Turbo Stream Response (update.turbo_stream.erb)
- Replaces the line item component on lines 1-3
- Re-renders builder header and summary
- Should properly update the DOM
- **NO ISSUE FOUND HERE**

#### ✅ JavaScript Controller (dirty_form_controller.js)
- Does NOT prevent form submission
- Only tracks "dirty" state for visual indicator
- Does NOT call `preventDefault()` on submit
- Properly handles `turbo:submit-end` events
- **NO ISSUE FOUND HERE**

---

## Root Cause Analysis

**Status: UNKNOWN - REQUIRES RUNTIME DEBUGGING**

All code layers appear structurally correct:
- Field is in the database ✓
- Model permits the parameter ✓
- Controller handles the update ✓
- Form includes the field ✓
- Response renders the updated component ✓
- JavaScript doesn't block submission ✓

**Possible causes requiring investigation:**

1. **Form submission not reaching the controller**
   - Check if form action URL is correct for the PATCH route
   - Verify Turbo is intercepting the form properly
   - Check browser network tab to see actual request

2. **Update action not receiving the parameter**
   - Check Rails logs to see what params are being sent
   - Verify `authenticity_token` is present in form
   - Check for any middleware filtering params

3. **Update silently failing**
   - Model validation silently rejecting the value
   - Database constraint preventing write
   - Association (belongs_to :tender) issue
   - Transaction rollback without error

4. **Response not being rendered**
   - Turbo Stream response not being sent (wrong content-type header)
   - Response body malformed
   - Partial view `_tender_line_item.html.erb` failing to render

5. **DOM not being updated despite response**
   - Turbo frame ID mismatch in `turbo_frame_tag` vs `turbo_stream.replace`
   - JavaScript error preventing re-render
   - Caching issue preventing view update

---

## Required Next Steps (for Engineer Mode)

### 1. Check Rails Logs
```
When user clicks Save, look for:
- POST /tenders/93/tender_line_items/122 request
- Check if tender_line_item_params includes item_description
- Check if update() call succeeded or failed
- Check response content-type (should be text/vnd.turbo-stream.html)
```

### 2. Check Browser Network Tab
```
- Verify POST request contains the new description value
- Check response status code (should be 200)
- Check response body contains updated description
```

### 3. Check Database
```
SELECT item_description FROM tender_line_items WHERE id = 122;
```

### 4. Test Isolated Update
```
From Rails console:
item = TenderLineItem.find(122)
item.update(item_description: "Test")
# Check if it persists
```

### 5. Check for Validations
```
Look for any hidden validations in:
- TenderLineItem model
- Tender model (parent)
- Any callbacks that might reject the update
```

---

## Context from User Observation

The selected HTML element shows:
- Form action: `/tenders/93/tender_line_items/122`
- Form method: POST with `_method=patch` (correct for PATCH)
- Form controller: `dirty-form`
- Input name: `tender_line_item[item_description]`
- Save button type: submit
- Current value in DOM: "Fabrication"

This all appears syntactically correct but updates are not persisting.

---

## Related Elements
- Tender ID: 93
- Line Item ID: 122
- Field: `tender_line_items.item_description`
- Page location: `/tenders/93/builder`
- View file: `app/views/tender_line_items/_tender_line_item.html.erb`
- Controller: `app/controllers/tender_line_items_controller.rb`

---

## Acceptance Criteria for Fix

- [ ] User can edit the Description field without errors
- [ ] Clicking Save button submits the form successfully
- [ ] Changes persist to database on page refresh
- [ ] Turbo Stream updates the line item on page without full refresh
- [ ] Unsaved changes indicator works correctly
- [ ] Works for all text fields (page, item, description, unit, notes)
