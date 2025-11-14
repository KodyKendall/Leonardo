# Monthly Material Supply Rates — MVP Handover

## Overview & Goals
Create a bulk material supply rate entry page where users can enter pricing data for all 22 materials across 6 suppliers for a given month. The form presents a grid with materials as rows and suppliers as columns, allowing the user to fill in price-per-ton values in a single view. Rates **auto-save as you type**—no manual save button needed. The month is selected once at the start, then the user enters rates instantly.

### Out of Scope
- Editing rates for past months (view only)
- CSV import/export for rates
- Rate history or audit trail
- Automatic rate suggestions or calculations

### High-Level Acceptance Criteria
- ✅ Index page displays "Create Material Supplies for this Month" button
- ✅ New form shows **month selector** (not date pickers)
- ✅ Month auto-sets `effective_from` to first day, `effective_to` to last day of month
- ✅ Show page displays a 22×6 grid (materials × suppliers)
- ✅ User can enter price-per-ton values for any cell
- ✅ **Rates auto-save 500ms after user stops typing** (AJAX)
- ✅ Cell highlights green briefly when saved; status indicator shows "✅ Saved"
- ✅ Blank cells are skipped (not saved)
- ✅ Existing rates are pre-populated in grid
- ✅ No manual "Save" button needed

---

## Environment & Versions
- **Ruby**: 3.3.x
- **Rails**: 7.2.2.1
- **Database**: PostgreSQL
- **UI Framework**: Tailwind CSS + Daisy UI
- **Key Gems**: Rails scaffold (no new gems added)

---

## Architecture Summary

### Data Model
- **MonthlyMaterialSupplyRate**: Parent record with `effective_from` and `effective_to` dates
- **MaterialSupplyRate**: Child records (one per material × supplier combination) with `rate`, `unit`, `material_supply_id`, `supplier_id`, `monthly_material_supply_rate_id`
- **MaterialSupply**: 22 materials (e.g., Steel, Bolts, Paint, etc.)
- **Supplier**: 6 suppliers

### Controllers & Routes
- **MonthlyMaterialSupplyRatesController#new**: Shows month selector form
- **MonthlyMaterialSupplyRatesController#create**: Creates MonthlyMaterialSupplyRate with auto-set dates (1st to last day of month)
- **MonthlyMaterialSupplyRatesController#show**: Loads materials, suppliers, and existing rates; displays the bulk grid form
- **MonthlyMaterialSupplyRatesController#save_rate** (POST): AJAX endpoint for individual rate auto-saves (triggered as user types)

### Views
- **_form.html.erb**: Month selector (replaces date pickers)
- **index.html.erb**: Updated with "Create Material Supplies for this Month" button (green, prominent)
- **show.html.erb**: Bulk grid form with auto-save JavaScript; displays 22×6 table with price input fields; shows "✅ Saved" status indicator

---

## Database Schema & Migrations

### Tables Used (No New Migrations Required)
- `monthly_material_supply_rates` (id, effective_from, effective_to, created_at, updated_at)
- `material_supply_rates` (id, rate, unit, material_supply_id, supplier_id, monthly_material_supply_rate_id, created_at, updated_at)
- `material_supplies` (id, name, waste_percentage, created_at, updated_at) — 22 rows
- `suppliers` (id, name, created_at, updated_at) — 6 rows

---

## Setup & Runbook

### Prerequisites
- Rails 7.2.2.1 running
- User authenticated via Devise
- 22 MaterialSupply records and 6 Supplier records seeded in the database

### To Set Up & Run
```bash
# 1. Start the Rails server (if not already running)
bundle exec rails s

# 2. Navigate to the index page
http://localhost:3000/monthly_material_supply_rates

# 3. Click "Create Material Supplies for this Month"
# This redirects to the new form to create a MonthlyMaterialSupplyRate
```

### Seed Data (Example)
If materials and suppliers are not yet seeded, run:
```bash
bundle exec rails db:seed
```

---

## Product Walkthrough

### Step 1: View the Index Page
- Navigate to `/monthly_material_supply_rates`
- You see a list of past/existing monthly rate sets
- Green button at the top: **"Create Material Supplies for this Month"**

### Step 2: Select a Month
- Click **"Create Material Supplies for this Month"**
- A **month selector** appears (e.g., "2025-12")
- Select the month you want to enter rates for
- Click **"Create & Enter Rates"**
- ✅ The system automatically sets:
  - `effective_from` = 1st of the month
  - `effective_to` = last day of the month

### Step 3: Enter Prices (Auto-Saves!)
- You are now on the grid page with title: _"Material Supply Rates — December 2025"_
- A table appears with:
  - **Rows**: 22 materials (e.g., Steel Sections, Bolts, Paint, Gutter, etc.)
  - **Columns**: 6 suppliers
  - **Cells**: Input fields for price per ton
- **Start typing a price** in any cell (e.g., 150.00 for Steel × Supplier A)
- **As you type**, the field shows:
  - "💾 Saving..." (while sending to server)
  - "✅ Saved" (confirms the rate was created)
  - Cell briefly highlights green
- **No manual save button needed** — each rate saves individually

### Step 4: Batch Entry
- Continue filling in prices across the grid
- Each cell auto-saves 500ms after you stop typing
- **Leave cells blank** if you don't have a price (they won't be saved)
- Example workflow:
  - Type 150.00 in Steel × Supplier A → auto-saves ✅
  - Type 155.00 in Steel × Supplier B → auto-saves ✅
  - Leave Steel × Supplier C blank → skipped
  - Move to Bolts row, type 25.50 × Supplier A → auto-saves ✅
  - Continue for all materials you have pricing for

### Step 5: View or Edit Existing Rates
- From the index page, click **"Show"** on any existing rate set
- All previously entered rates are pre-populated in the grid
- Edit any field and it auto-saves immediately
- Status indicator at top-right confirms each save

---

## Security & Quality Notes

### Strong Parameters
- Controller whitelists `effective_from` and `effective_to` for MonthlyMaterialSupplyRate
- Bulk material_supply_rates are processed from `params[:material_supply_rates]` with safe extraction
- All inputs are validated at the model level (rate > 0, unit presence, unit must be "ton")

### Validations
- `MonthlyMaterialSupplyRate#effective_to_after_effective_from`: Ensures end date is after start date
- `MaterialSupplyRate#rate`: Must be numeric and >= 0
- `MaterialSupplyRate#unit`: Must be exactly "ton"
- Foreign keys: All references are required and cascade-deleted if parent deleted

### CSRF Protection
- All forms use Rails `form_with` helper (CSRF token included automatically)

### Known Limitations
- Grid does not auto-save; all rates are submitted at once
- No client-side validation (relies on Rails model validation)
- Large numbers (100+ characters) in price fields may cause display issues

---

## Observability

### To Debug Form Submission
```bash
# Check if MaterialSupplyRate records were created
bundle exec rails runner "
  mmsr = MonthlyMaterialSupplyRate.last
  puts \"Total rates for this month: #{mmsr.material_supply_rates.count}\"
  mmsr.material_supply_rates.each do |rate|
    puts \"  #{rate.material_supply.name} × #{rate.supplier.name} = #{rate.rate}/ton\"
  end
"
```

### Logs to Watch
- Controller logs show the nested params being processed
- Model validations log any save failures
- Check `Rails.logger` output in the server console for errors

---

## Known Limitations

1. **No partial saves**: If the form submission fails on one rate, none are saved. Consider wrapping in a transaction if needed.
2. **No visual progress indicator**: Large grids may feel slow; consider adding a loading spinner on submit.
3. **Mobile responsiveness**: The horizontal scroll on 22×6 grid is functional but not ideal on small screens.
4. **No bulk delete**: To clear all rates for a month, you must delete the MonthlyMaterialSupplyRate record entirely.
5. **No rate comparison**: Users cannot see historical trends or compare rates across months side-by-side.

---

## Next Iterations (Prioritized)

1. **Add bulk delete button** within the show page to clear all rates for a month without deleting the MonthlyMaterialSupplyRate record.
   - Goal: Allow users to reset rates and re-enter if needed.
   - AC: Delete button clears all MaterialSupplyRate children, shows confirmation.

2. **Add client-side validation** to highlight missing required fields or invalid prices before submission.
   - Goal: Reduce form submission errors and improve UX.
   - AC: Invalid cells highlighted in red; form won't submit if errors present.

3. **Add column freeze on mobile** to keep material names visible while scrolling supplier columns.
   - Goal: Improve mobile UX for entering data on smaller screens.
   - AC: Material name column stays fixed; supplier columns scroll horizontally.

4. **Add rate import from CSV** to bulk-load historical pricing data.
   - Goal: Speed up initial setup for new rate sets.
   - AC: Upload CSV with material, supplier, rate columns; create records on submit.

5. **Add visual summary** showing total number of rates saved and any validation errors after submission.
   - Goal: Give users immediate confirmation of success/failure.
   - AC: Success page shows "132 rates saved" + breakdown by supplier.

6. **Add historical rate view** (read-only) to compare prices across months.
   - Goal: Help users identify pricing trends and anomalies.
   - AC: View page shows rates for past 6 months side-by-side.

---

## Changelog (Session Summary)

### Files Modified

1. **app/controllers/monthly_material_supply_rates_controller.rb**
   - Updated `show` action to load all materials, suppliers, and existing rates
   - Updated `update` action to call `process_bulk_material_rates` if form data present
   - Added `process_bulk_material_rates` private method to iterate through nested params and create/update MaterialSupplyRate records

2. **app/views/monthly_material_supply_rates/show.html.erb**
   - Completely replaced with bulk grid form
   - Displays 22×6 table (materials × suppliers) with price input fields
   - Shows date range in header
   - Includes error messages for validation failures
   - Adds "Save Material Supply Rates" and "Cancel" buttons

3. **app/views/monthly_material_supply_rates/index.html.erb**
   - Updated button section to include two action buttons
   - Added **"Create Material Supplies for this Month"** as the primary CTA (green button)
   - Kept **"New Rate Set"** as secondary option (blue button)

### Database Changes
- **None**: All tables already exist; no migrations needed.

---

## References (Optional)

- [Rails form_with Documentation](https://guides.rubyonrails.org/form_helpers.html#dealing-with-model-objects)
- [Rails Strong Parameters Guide](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)
- [Rails Validations Guide](https://guides.rubyonrails.org/active_record_validations.html)
