# Mental Model: Material Supply Margin Sync Issue

## 🎯 Problem Statement
**User Story:** "As Demi, I want the material supply in the rate buildup to calculate the margin into the material supply."

**Current Behavior:** The margin/markup percentage entered in the **Material Breakdown** (right panel) is correctly calculated client-side and displays in the "Material Supply Total" field. However, this **margin-adjusted total is NOT being synced back** to the **Rate Buildup** (left panel) as the `material_supply_rate`.

**Impact:** The R 860.00 in the Rate Buildup's "Material Supply" line (the cell marked `data-line-item-rate-build-up-target="amountCell"`) shows only the subtotal of materials WITHOUT the margin applied.

---

## 📊 Data Model & Schema

### Key Tables
1. **tender_line_items** — Line item with quantity, rate, description
   - Has one `line_item_rate_build_up`
   - Has one `line_item_material_breakdown`

2. **line_item_material_breakdowns** — Container for materials
   - Belongs to `tender_line_item`
   - Has many `line_item_materials`
   - Fields: `id`, `tender_line_item_id`, `created_at`, `updated_at`

3. **line_item_materials** — Individual materials in breakdown
   - Belongs to `line_item_material_breakdown`
   - Fields: `rate`, `waste_percentage`, `proportion`, `quantity`, and computed `line_total`
   - Calculation: `line_total = ((rate * waste%) + rate) * proportion`

4. **line_item_rate_build_ups** — Rate breakdown with margin
   - Belongs to `tender_line_item`
   - Fields: `material_supply_rate`, `fabrication_rate`, `margin_amount`, `subtotal`, `total_before_rounding`, `rounded_rate`, etc.
   - Also tracks `material_supply_included` (boolean)

---

## 🔄 Current Data Flow

### Material Breakdown Side (RIGHT PANEL)
**File:** `app/views/line_item_material_breakdowns/_totals_section.html.erb`

```
1. User adds materials with rate, waste%, and proportion
   ↓
2. Each material calculates: line_total = ((rate * waste%) + rate) * proportion
   ↓
3. Subtotal = SUM(line_totals) [e.g., R 750.00]
   ↓
4. User enters Markup % [e.g., 15%]
   ↓
5. JavaScript calculates: Material Supply Total = subtotal + (subtotal * markup%)
   Example: 750 + (750 * 0.15) = 750 + 112.50 = R 862.50 ✅
   (This is displayed in "Material Supply Total" field)
```

**JavaScript Controller:** `app/javascript/controllers/line_item_material_breakdown_controller.js`
- Calculates: `const total = subtotal + marginAmount`
- Updates `totalDisplayTarget` with this value
- **PROBLEM:** This calculated total is ONLY stored in the DOM/UI, NOT persisted or synced to the Rate Buildup

---

### Rate Buildup Side (LEFT PANEL)
**File:** `app/views/line_item_rate_build_ups/_line_item_rate_build_up.html.erb`

```
1. Material Supply Rate = synced from material breakdown subtotal [e.g., R 750.00]
   ↓
2. Row displays: Material Supply | ✓ Included | R 750.00 | R 750.00
   ↓
3. User can also add manual margin in Rate Buildup
   Margin: [input field] = R 112.50
   ↓
4. Calculation: subtotal = 750.00 + margin = 862.50 ✅
   Final Rate = round(862.50) = R 863.00
```

**JavaScript Controller:** `app/javascript/controllers/line_item_rate_build_up_controller.js`
- Calculates: `const totalBeforeRounding = subtotal + margin`
- Rounds to nearest whole: `Math.round(totalBeforeRounding)`
- Updates display targets for subtotal, margin display, total, and rounded rate

---

## 🔌 Sync Mechanism (Active Record Callbacks)

### Current Sync Path
**File:** `app/models/line_item_material.rb` (line 31–47)
```ruby
after_save :sync_material_supply_rate_to_buildup

def sync_material_supply_rate_to_buildup
  rate_buildup = tender_line_item.line_item_rate_build_up
  total_material_cost = line_item_material_breakdown.subtotal  # ← SUBTOTAL ONLY
  rate_buildup.update(material_supply_rate: total_material_cost)
end
```

**File:** `app/models/line_item_material_breakdown.rb` (line 22–29)
```ruby
after_save :sync_material_supply_rate_to_buildup

def sync_material_supply_rate_to_buildup
  rate_buildup = tender_line_item.line_item_rate_build_up
  rate_buildup.update(material_supply_rate: subtotal)  # ← SUBTOTAL ONLY
end
```

### What's Missing
- **No field on `line_item_material_breakdowns` table** to store the markup percentage
- **No calculation method** on `LineItemMaterialBreakdown` to compute `total_with_margin`
- **Sync callback never applies margin** when updating `material_supply_rate`

---

## 💾 Database Issue: Missing Markup Storage

### Current Schema: `line_item_material_breakdowns`
```ruby
create_table "line_item_material_breakdowns", force: :cascade do |t|
  t.bigint "tender_line_item_id", null: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["tender_line_item_id"], name: "index_line_item_material_breakdowns_on_tender_line_item_id"
end
```

### Problem
- **No `markup_percentage` column** to persist the user's markup input
- Markup % is currently only in the DOM (input field value), not stored in the database
- When the page reloads or data syncs, the markup percentage is lost

---

## 🎨 UI Components & Turbo Frames

### Material Breakdown UI
**File:** `app/views/line_item_material_breakdowns/_line_item_material_breakdown.html.erb`

```erb
<%= turbo_frame_tag dom_id(line_item_material_breakdown) do %>
  <!-- Material rows rendered here -->
  <%= render 'line_item_material_breakdowns/totals_section', ... %>
<% end %>
```

**Totals Section:** `app/views/line_item_material_breakdowns/_totals_section.html.erb`
```erb
<input type="number" placeholder="0" step="0.1" class="input input-bordered input-xs w-16 text-right join-item text-xs" 
       data-line-item-material-breakdown-target="marginInput" 
       data-action="input->line-item-material-breakdown#recalculate" />

<span class="text-base font-semibold text-blue-600" 
      data-line-item-material-breakdown-target="totalDisplay">
  R<%= number_with_precision(line_item_material_breakdown.total, precision: 2, delimiter: ",") %>
</span>
```

### Rate Buildup UI
**File:** `app/views/line_item_rate_build_ups/_line_item_rate_build_up.html.erb`

```erb
<!-- Material Supply Row -->
<td class="text-right font-semibold" data-line-item-rate-build-up-target="amountCell">
  <span><%= is_included ? number_to_currency(rate_value, unit: "R ", precision: 2) : "—" %></span>
</td>

<!-- Manual Margin Input (separate from material breakdown markup) -->
<input type="number" placeholder="0" step="0.01" min="0" 
       class="input input-sm input-bordered w-28 text-right" 
       data-line-item-rate-build-up-target="marginInput" 
       data-action="input->line-item-rate-build-up#calculate" />
```

---

## 🔗 Associations & Dependencies

```
Tender
  ├── has_many :tender_line_items
       └── TenderLineItem
            ├── has_one :line_item_rate_build_up
            │    └── LineItemRateBuildUp
            │         └── has field: material_supply_rate (decimal)
            │         └── has field: margin_amount (decimal) [manual margin for rate buildup]
            │
            └── has_one :line_item_material_breakdown
                 ├── has_many :line_item_materials
                 │    └── LineItemMaterial (fields: rate, waste_percentage, proportion, quantity)
                 │
                 └── NO field for: markup_percentage ⚠️
```

---

## 🧮 Calculation Flows Compared

### EXISTING: Material Breakdown Markup (Client-Side Only)
```
Markup % = 15%
Subtotal = 750.00
Client-side JS: Total = 750 + (750 * 0.15) = 862.50 ✅ (shown in UI)
After save: Synced to rate_buildup.material_supply_rate = 750.00 ❌ (markup lost!)
```

### EXISTING: Rate Buildup Manual Margin (Persisted)
```
Material Supply Rate = 750.00 (synced, but without markup)
Manual Margin = 112.50 (user enters directly in Rate Buildup)
Server calc: subtotal = 750 + margin = 862.50 ✅ (persisted)
Final Rate = round(862.50) = 863 ✅
```

### DESIRED: Material Breakdown Markup (Persisted & Synced)
```
Markup % = 15% (NEED TO PERSIST)
Subtotal = 750.00
Material Supply Total = 750 + (750 * 0.15) = 862.50 ✅ (calculated & persisted)
Synced to rate_buildup.material_supply_rate = 862.50 ✅ (with markup)
Rate Buildup displays = R 862.50 ✅
```

---

## 📝 Form Submission & Data Persistence Flow

**Current Issue:**
1. User enters markup % in Material Breakdown totals section
2. JavaScript calculates and displays: `R 862.50`
3. **Form has no field to save the markup % to the database**
4. When "Save" is clicked on Material Breakdown or Rate Buildup, the markup % value is not persisted
5. Sync callback runs: `sync_material_supply_rate_to_buildup` uses only `subtotal` (750.00)
6. Rate Buildup receives: `material_supply_rate = 750.00` (without markup)

---

## 🚀 Required Changes (High-Level)

### 1. **Database Schema**
- Add `markup_percentage` column to `line_item_material_breakdowns` table

### 2. **Model: LineItemMaterialBreakdown**
- Add method: `def total_with_markup` that calculates `subtotal * (1 + markup_percentage / 100)`
- Update sync callback to use `total_with_markup` instead of `subtotal`

### 3. **View: Material Breakdown Totals Section**
- Bind the markup input field to a form field that saves to `line_item_material_breakdown.markup_percentage`

### 4. **JavaScript Controller: LineItemMaterialBreakdown**
- Ensure calculations account for the persisted markup when displayed

### 5. **Sync Logic**
- When `LineItemMaterial` or `LineItemMaterialBreakdown` saves, ensure the sync uses the margin-adjusted total

---

## 🔍 Key Files Summary

| File | Role | Current State |
|------|------|----------------|
| `app/models/line_item_rate_build_up.rb` | Calculates rate buildup subtotal, margin, and final rate | ✅ Works correctly |
| `app/models/line_item_material_breakdown.rb` | Syncs material cost to rate buildup | ❌ Only syncs subtotal, not with markup |
| `app/models/line_item_material.rb` | Calculates individual material line totals; triggers sync | ❌ Only syncs subtotal, not with markup |
| `app/views/line_item_material_breakdowns/_totals_section.html.erb` | Displays markup input and total | ⚠️ No form binding for markup % |
| `app/javascript/controllers/line_item_material_breakdown_controller.js` | Client-side calculation of total with markup | ✅ Calculates correctly, but value never persisted |
| `app/views/line_item_rate_build_ups/_line_item_rate_build_up.html.erb` | Displays rate buildup rows including Material Supply | ✅ Displays correctly; just receives wrong value |
| `app/javascript/controllers/line_item_rate_build_up_controller.js` | Client-side calculation of rate buildup totals | ✅ Works correctly with the data it receives |

---

## 📍 The Selected Element

```html
<td class="text-right font-semibold element-selector-highlight" 
    data-line-item-rate-build-up-target="amountCell">
  <span>R 860.00</span>
</td>
```

- **Location:** Rate Buildup "Material Supply" row, Amount column
- **Current Value:** R 860.00 (subtotal only)
- **Expected Value:** R 860.00 × (1 + markup%) — e.g., if markup is 15%, should be ≈ R 989.00
- **Controlled By:** `line_item_rate_build_up_controller.js` at line 63
- **Source Data:** `line_item_rate_build_up.material_supply_rate` (synced from material breakdown)

---

## 🎓 Summary of Root Cause

The markup percentage entered in the Material Breakdown is:
1. ✅ **Calculated correctly** in the browser (JavaScript)
2. ✅ **Displayed correctly** in the UI ("Material Supply Total: R 862.50")
3. ❌ **NOT stored anywhere** in the database
4. ❌ **Never included** when syncing to the Rate Buildup

The sync callback only looks at `line_item_material_breakdown.subtotal`, which is a computed property that never includes the markup. The solution requires:
- **Persistence:** Store the markup % in the database
- **Calculation:** Compute and sync the markup-adjusted total
- **Synchronization:** Update the sync callbacks to use the markup-adjusted total

