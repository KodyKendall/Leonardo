# ERP System Specification: Steel Fabrication Tender Costing Module

## Overview

This specification translates the spreadsheet logic into an ERP-compatible data model with clear separation between **master data (inputs)**, **transactional data (project-specific)**, **ephemeral calculations**, and **outputs**.

---

## 1. MASTER DATA TABLES (Inputs - Maintained Centrally)

### 1.1 `rate_card_processing` - Processing Rate Master

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`rate_id`|PK|Unique identifier|`PROC_001`|
|`rate_code`|VARCHAR(20)|Code reference|`SHOP_DRAW`|
|`rate_description`|VARCHAR(100)|Rate name|`Shop Drawings`|
|`rate_per_tonne`|DECIMAL(12,2)|R/tonne|`350.00`|
|`unit`|VARCHAR(10)|Unit of measure|`P/T`|
|`effective_date`|DATE|When rate becomes active|`2024-01-01`|
|`expiry_date`|DATE|When rate expires|`NULL`|

**Source**: Rates Page B16:C33

| Rate Code      | Description                  | Current Value (R/t) |
| -------------- | ---------------------------- | ------------------- |
| `SHOP_DRAW`    | Shop Drawings                | 350                 |
| `FABRICATION`  | Fabrication                  | 8,000               |
| `OVERHEADS`    | Overheads                    | 4,150               |
| `SHOP_PRIME`   | Shop Priming incl. Transport | 1,380               |
| `ONSITE_PAINT` | On Site Painting             | 1,565               |
| `DELIVERY`     | Delivery to Site             | 700                 |
| `BOLTS`        | Bolts (capped @ 2% of mass)  | 1,500               |
| `ERECTION`     | Erection                     | 1,800               |
| `CRAINAGE`     | Crainage per tonne           | _Calculated_        |
| `CHERRY_PICK`  | Cherry Pickers per tonne     | _Calculated_        |
| `GALVANIZING`  | Galvanizing                  | 11,000              |
| `SAFETY_FILE`  | Safety File & Audits         | 30,000 (lump sum)   |

---

### 1.2 `rate_card_material` - Material Supply Rate Master

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`material_id`|PK|Unique identifier|`MAT_001`|
|`material_code`|VARCHAR(50)|Material type code|`UB_UC_LOCAL`|
|`material_description`|VARCHAR(100)|Full name|`Material Supply Local UB & UC Sections`|
|`base_rate_per_tonne`|DECIMAL(12,2)|Base price R/t|`15,900.00`|
|`waste_factor_pct`|DECIMAL(5,4)|Waste allowance %|`0.0750`|
|`effective_date`|DATE|Validity start|`2024-01-01`|

**Source**: Rates Page B35:C56

| Material Code        | Description                  | Base Rate (R/t) | Waste % |
| -------------------- | ---------------------------- | --------------- | ------- |
| `UNEQUAL_ANGLES`     | Unequal Angles               | 18,800          | 7.5%    |
| `EQUAL_ANGLES`       | Equal Angles                 | 12,850          | 7.5%    |
| `LARGE_EQUAL_ANGLES` | Large Equal Angles           | 15,900          | 7.5%    |
| `UB_UC_LOCAL`        | Local UB & UC Sections       | 15,900          | 7.5%    |
| `UB_UC_IMPORT`       | Import UB & UC Sections      | 16,170          | 7.5%    |
| `PFC_SECTIONS`       | PFC Sections                 | 18,743          | 7.5%    |
| `PFC_HEAVY`          | Heavy PFC Sections           | 17,131.67       | 7.5%    |
| `IPE_SECTIONS`       | IPE Sections                 | 18,487          | 7.5%    |
| `PLATE_SHEETS`       | Sheets of Plate              | 15,800          | 12.5%   |
| `PLATE_CUT`          | Cut to Size Plate            | 30,500          | 0%      |
| `HOLLOW_STD`         | Standard Hollow Sections     | 20,980          | 10%     |
| `HOLLOW_NONSTD`      | Non-Standard Hollow Sections | 26,000          | 10%     |
| `GUTTERS`            | Gutters                      | 35,000          | 0%      |
| `ROUND_BAR`          | Round Bar                    | 14,000          | 10%     |
| `CFLC_METSEC_1.6`    | Metsec Alternative 1.6mm     | 21,250          | 0%      |
| `CFLC_METSEC_2`      | Metsec Alternative 2mm       | 20,550          | 0%      |

---

### 1.3 `equipment_catalogue` - Access Equipment Master

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`equipment_id`|PK|Unique identifier|`EQUIP_001`|
|`category`|VARCHAR(50)|Equipment category|`DIESEL_BOOM`|
|`model`|VARCHAR(50)|Model name|`600AJ`|
|`working_height_m`|DECIMAL(5,1)|Working height|`20.0`|
|`base_rate_monthly`|DECIMAL(12,2)|Base rental rate|`38,195.00`|
|`damage_waiver_pct`|DECIMAL(5,4)|Damage waiver %|`0.0600`|
|`diesel_allowance_monthly`|DECIMAL(10,2)|Diesel cost|`19,500.00`|

**Source**: Access Equipment A1:I40

---

### 1.4 `crane_rate_card` - Mobile Crane Rates

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`crane_id`|PK|Unique identifier|`CRANE_001`|
|`crane_size`|VARCHAR(10)|Crane capacity|`25t`|
|`dry_rate_per_day`|DECIMAL(10,2)|9-hour dry rate|`1,660.00`|
|`diesel_allowance_per_day`|DECIMAL(10,2)|Daily diesel|`750.00`|
|`all_inclusive_rate`|DECIMAL(10,2)|_Calculated_|`2,450.00`|

**Source**: DATA SHEET LOCKED A4:D10

---

### 1.5 `crane_complement_lookup` - Area-Based Crane Selection

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`lookup_id`|PK|Unique identifier|`COMP_001`|
|`area_min_sqm`|INT|Minimum m²/day|`250`|
|`area_max_sqm`|INT|Maximum m²/day|`350`|
|`crane_complement`|VARCHAR(100)|Recommended cranes|`1 x 10t + 2 x 25t`|
|`wet_rate_per_day`|DECIMAL(10,2)|Combined daily rate|`8,300.00`|

**Source**: DATA SHEET LOCKED A15:C19

---

## 2. PROJECT/TRANSACTIONAL DATA (Inputs - Per Tender)

### 2.1 `tender_header` - Tender Master

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`tender_id`|PK|Unique identifier|`TND-2024-001`|
|`project_name`|VARCHAR(200)|Project description|`DIMAKO TRANSFORMERS MANUFACTURING FACILITY`|
|`client_name`|VARCHAR(100)|Client|`RPP DEVELOPMENTS`|
|`tender_date`|DATE|Date created|`2024-11-26`|
|`expiry_date`|DATE|Validity period|`2024-12-26`|
|`margin_pct`|DECIMAL(5,4)|Overall margin|`0.0000`|
|`status`|VARCHAR(20)|Tender status|`DRAFT`|

---

### 2.2 `tender_line_item` - Bill of Quantities

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`line_id`|PK|Unique identifier|`LINE_001`|
|`tender_id`|FK|Parent tender|`TND-2024-001`|
|`bill_number`|INT|Bill/section number|`1`|
|`item_number`|INT|Item within bill|`1`|
|`description`|VARCHAR(500)|Item description|`305 x 165mm x 40kg/m I-section columns`|
|`unit`|VARCHAR(10)|Unit of measure|`t`|
|`quantity`|DECIMAL(12,4)|Quantity|`11.19`|
|`item_category`|VARCHAR(50)|Category code|`STEEL_SECTIONS`|
|`line_type`|VARCHAR(20)|Calculation type|`STANDARD` / `BOLT` / `ANCHOR` / `GUTTER`|

**Source**: Tender Data A1:G50

---

### 2.3 `tender_line_material_mix` - Material Composition per Line

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`mix_id`|PK|Unique identifier|`MIX_001`|
|`line_id`|FK|Parent line item|`LINE_001`|
|`material_code`|FK|Material type|`UB_UC_LOCAL`|
|`proportion_pct`|DECIMAL(5,4)|% of line item|`1.0000`|

**Source**: Costing Sheet K39:N43 - columns K (material type), N (proportion flag)

---

### 2.4 `tender_cost_inclusions` - Toggle Flags per Tender

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`tender_id`|FK|Parent tender|`TND-2024-001`|
|`include_fabrication`|BOOLEAN|Include fabrication?|`TRUE`|
|`include_overheads`|BOOLEAN|Include overheads?|`TRUE`|
|`include_shop_priming`|BOOLEAN|Include priming?|`FALSE`|
|`include_onsite_paint`|BOOLEAN|Include painting?|`FALSE`|
|`include_delivery`|BOOLEAN|Include delivery?|`TRUE`|
|`include_bolts`|BOOLEAN|Include bolts?|`TRUE`|
|`include_erection`|BOOLEAN|Include erection?|`TRUE`|
|`include_crainage`|BOOLEAN|Include crainage?|`FALSE`|
|`include_cherry_picker`|BOOLEAN|Include cherry picker?|`TRUE`|
|`include_galvanizing`|BOOLEAN|Include galvanizing?|`FALSE`|

**Source**: Rates Page F21:F30

---

### 2.5 `tender_site_parameters` - On-Site Configuration

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`tender_id`|FK|Parent tender|`TND-2024-001`|
|`total_roof_area_sqm`|DECIMAL(12,2)|Total roof area|`19,609.00`|
|`erection_rate_sqm_day`|DECIMAL(8,2)|Area erected per day|`300.00`|
|`splicing_crane_required`|BOOLEAN|Extra crane needed?|`TRUE`|
|`splicing_crane_size`|VARCHAR(10)|Crane size|`25t`|
|`splicing_crane_days`|INT|Duration in days|`70`|
|`misc_crane_required`|BOOLEAN|Miscellaneous crane?|`TRUE`|
|`misc_crane_days`|INT|Duration in days|`0`|
|`program_duration_days`|INT|_Calculated_|`100`|

**Source**: Rates Page E36:H48

---

### 2.6 `tender_equipment_selection` - Equipment Allocation

| Field            | Data Type | Description         | Example Value        |
| ---------------- | --------- | ------------------- | -------------------- |
| `selection_id`   | PK        | Unique identifier   | `SEL_001`            |
| `tender_id`      | FK        | Parent tender       | `TND-2024-001`       |
| `equipment_id`   | FK        | Equipment reference | `EQUIP_022` (E450AJ) |
| `units_required` | INT       | Number of units     | `5`                  |
| `period_months`  | INT       | Rental duration     | `5`                  |

**Source**: Access Equipment G22:H29

---

## 3. EPHEMERAL CALCULATIONS (Computed at Runtime)

### 3.1 Material Cost Calculation

```
-- Per material line within a tender line item
material_rate_with_waste = base_rate_per_tonne × (1 + waste_factor_pct) × proportion_pct

-- Example: UB_UC_LOCAL at 100% proportion
= 15,900 × (1 + 0.075) × 1.0
= 17,092.50 R/t
```

**Source Formula**: O39 = `=SUM(M39+(M39*L39))*N39`

---

### 3.2 Line Item Rate Build-Up

```
-- For a standard steel section line item:
line_rate_per_tonne = 
    material_supply_rate                           -- From 3.1 (e.g., 17,100)
  + (fabrication_rate × include_fabrication)       -- 8,000 × 1 = 8,000
  + (overheads_rate × include_overheads)           -- 4,150 × 1 = 4,150
  + (shop_priming_rate × include_shop_priming)     -- 1,380 × 0 = 0
  + (onsite_paint_rate × include_onsite_paint)     -- 1,565 × 0 = 0
  + (delivery_rate × include_delivery)             -- 700 × 1 = 700
  + (bolts_rate × include_bolts)                   -- 1,500 × 1 = 1,500
  + (erection_rate × include_erection)             -- 1,800 × 1 = 1,800
  + (crainage_rate × include_crainage)             -- 1,080 × 0 = 0
  + (cherry_picker_rate × include_cherry_picker)   -- 1,430 × 1 = 1,430
  + (galvanizing_rate × include_galvanizing)       -- 11,000 × 0 = 0

subtotal = 34,680
margin = subtotal × margin_pct = 0
total = 34,680
rounded_rate = CEILING(total, 50) = 34,700
```

**Source Formulas**:

- F39:F49 - individual components
- F50 = `=SUM(F39:F49)` - subtotal
- F52 = `=SUM(F50:F51)` - total with margin
- F35 = `=CEILING(F52,50)` - rounded rate

---

### 3.3 Equipment Cost per Tonne

```
-- Equipment monthly cost
equipment_monthly_cost = base_rate × (1 + damage_waiver_pct) + diesel_allowance

-- Total equipment allowance
total_equipment_cost = Σ(equipment_monthly_cost × units × months) + mobilization_fee
                     = 1,315,738 + 15,000 = 1,330,738

-- Rate per tonne
equipment_rate_per_tonne = total_equipment_cost / total_project_tonnage
                         = 1,330,738 / 931.62
                         = 1,428.41 R/t (rounded to 1,430)
```

**Source Formulas**:

- I42 = `=SUM(I5:I41)+(15000)` - total allowance
- I44 = `=I42/I43` - rate per tonne

---

### 3.4 Crainage Cost per Tonne

```
-- Crane complement lookup based on erection rate
wet_rate_per_day = LOOKUP(erection_rate_sqm_day, crane_complement_lookup)
                 = 8,300 (for 250-350 m²/day)

-- Main program crane cost
main_crane_cost = wet_rate_per_day × program_duration_days
                = 8,300 × 100 = 830,000

-- Splicing crane cost (if required)
splicing_cost = LOOKUP(splicing_crane_size, crane_rate_card) × splicing_crane_days
              = 2,450 × 70 = 171,500

-- Total crane cost
total_crane_cost = main_crane_cost + splicing_cost + misc_cost
                 = 830,000 + 171,500 + 0 = 1,001,500

-- Rate per tonne
crainage_rate_per_tonne = CEILING(total_crane_cost / total_tonnage, 20)
                        = CEILING(1,001,500 / 931.62, 20)
                        = 1,080 R/t
```

**Source Formulas**:

- H37 - crane complement lookup
- H46 = `=H37 × F45` - main crane cost
- H48 = `=H42+H43+H46` - total crane cost
- B24 = `=CEILING(H48/C9, 20)` - rate per tonne

---

### 3.5 P&G (Preliminaries & General) Rate

```
-- Lump sum items distributed per tonne
pg_rate_per_tonne = (
    (safety_file_cost / total_tonnage)     -- 30,000 / 931.62 = 32.20
  + crainage_rate                           -- 1,080
  + cherry_picker_rate                      -- 0 (if excluded from P&G)
  + extra_pg_item_1 / total_tonnage         -- 0 / 931.62 = 0
  + extra_pg_item_2 / total_tonnage         -- 0
  ...
)

subtotal = 1,112.20
rounded_rate = CEILING(subtotal, 50) = 1,150
pg_total = rounded_rate × total_tonnage × quantity
         = 1,150 × 931.62 × 1 = 1,071,363
```

**Source Formulas**:

- F9 = `=SUM((D9*(E9/E5)))` - safety file per tonne
- F18 = `=SUM(F9:F17)` - subtotal
- F5 = `=CEILING(F20,50)` - rounded rate

---

### 3.6 Anchor Bolt Calculation (Non-Standard Item)

```
-- Rod mass calculation
rod_mass_kg = (kg_per_m × length_mm / 1000) × 1.15 (waste factor)
            = (0.0056 × 660 / 1000) × 1.15 = 0.00425 kg

-- Rod cost
rod_cost = rod_mass_kg × steel_price_per_kg
         = 0.00425 × 42,000 = 178.52

-- Per bolt set cost
bolt_set_cost = CEILING(rod_cost, 10)   -- 180
              + nuts_cost                 -- 100
              + fab_cost                  -- 140
              + (subtotal × overhead_pct) -- 42

subtotal = 462
rounded_rate = CEILING(subtotal, 50) = 500
```

**Source Formulas**: Costing Sheet A139:F147

---

## 4. OUTPUT DATA (Final Tender Values)

### 4.1 `tender_line_output` - Priced Line Items

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`line_id`|FK|Line item reference|`LINE_001`|
|`calculated_rate`|DECIMAL(12,2)|Rate per unit|`34,700.00`|
|`line_amount`|DECIMAL(14,2)|Qty × Rate|`388,293.00`|
|`margin_amount`|DECIMAL(12,2)|Margin portion|`0.00`|
|`rounding_amount`|DECIMAL(10,2)|Rounding adjustment|`223.80`|

---

### 4.2 `tender_summary` - Tender Totals

|Field|Data Type|Description|Example Value|
|---|---|---|---|
|`tender_id`|FK|Tender reference|`TND-2024-001`|
|`total_tonnage`|DECIMAL(12,4)|Total steel mass|`931.62`|
|`pg_total`|DECIMAL(14,2)|P&G amount|`1,071,363.00`|
|`shop_drawings_total`|DECIMAL(14,2)|Shop drawings|`326,067.00`|
|`steel_work_total`|DECIMAL(14,2)|All steel items|`22,002,636.00`|
|`tender_subtotal`|DECIMAL(14,2)|Sum of all lines|`23,400,066.00`|
|`margin_total`|DECIMAL(14,2)|Total margin|`0.00`|
|`rounding_total`|DECIMAL(14,2)|Total rounding|`72,324.47`|
|`tender_grand_total`|DECIMAL(14,2)|Final tender value|`23,400,066.00`|

---

## 5. BUSINESS RULES SUMMARY

| Rule ID    | Description            | Formula/Logic                                                     |
| ---------- | ---------------------- | ----------------------------------------------------------------- |
| **BR-001** | Rate Rounding          | All rates rounded up to nearest R50: `CEILING(rate, 50)`          |
| **BR-002** | Crainage Rounding      | Crainage rate rounded to nearest R20: `CEILING(rate, 20)`         |
| **BR-003** | Cherry Picker Rounding | Rounded to nearest R10: `CEILING(rate, 10)`                       |
| **BR-004** | Waste Application      | Applied to base material rate before aggregation                  |
| **BR-005** | Toggle Application     | Boolean flags multiply rate by 0 or 1                             |
| **BR-006** | Margin Calculation     | Applied to subtotal before rounding                               |
| **BR-007** | Bolts Inclusion        | Standard line items include bolts in rate (not priced separately) |
| **BR-008** | Lump Sum Distribution  | Fixed costs (safety file, etc.) divided by total tonnage          |

---

## 6. INTEGRATION POINTS

|System|Integration Type|Data Flow|
|---|---|---|
|**Inventory/Purchasing**|Material rates|`rate_card_material` ← Updated prices|
|**HR/Payroll**|Labor rates|`rate_card_processing` ← Fabrication/erection rates|
|**Equipment Management**|Rental rates|`equipment_catalogue` ← Updated rental costs|
|**Project Management**|Site parameters|`tender_site_parameters` ← Actual durations|
|**Finance/GL**|Tender outputs|`tender_summary` → Revenue recognition|
|**CRM**|Customer data|`tender_header` ← Client details|

---

Would you like me to elaborate on any specific calculation pattern, provide pseudocode for any of the ephemeral calculations, or create a data flow diagram showing the relationships between these entities?


What would I name my database tabkles in order to lay the foundation for the database ERD to lay the foundation to turn this into a lightweight ERP system as opposed to an actual spreadsheet, specifically using Ruby on Rails?


Great question! Let me design a Rails-convention database schema that captures this spreadsheet's logic while following Rails naming conventions and best practices.

---

# Ruby on Rails Database Schema for Steel Fabrication ERP

## Naming Conventions Applied

- **Table names**: Plural, snake_case (Rails convention)
- **Primary keys**: `id` (auto-generated)
- **Foreign keys**: `{singular_table_name}_id`
- **Timestamps**: `created_at`, `updated_at` (auto-generated)
- **Boolean fields**: Prefixed with `is_` or verb-based (e.g., `include_fabrication`)
- **Money fields**: `_cents` suffix with integer storage OR `decimal` with precision

---

## 1. MASTER DATA TABLES (Configuration/Reference Data)

### Core Rate Tables

```ruby
# Processing rates (fabrication, erection, delivery, etc.)
class CreateProcessingRates < ActiveRecord::Migration[7.1]
  def change
    create_table :processing_rates do |t|
      t.string   :code,              null: false  # 'FABRICATION', 'ERECTION', etc.
      t.string   :name,              null: false  # 'Fabrication'
      t.string   :description
      t.decimal  :rate_per_tonne,    precision: 12, scale: 2, null: false
      t.string   :unit,              default: 'R/t'
      t.boolean  :is_lump_sum,       default: false  # For safety file, etc.
      t.date     :effective_from,    null: false
      t.date     :effective_to
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :processing_rates, :code, unique: true
    add_index :processing_rates, [:is_active, :effective_from]
  end
end

# Material supply rates (steel sections, plates, etc.)
class CreateMaterials < ActiveRecord::Migration[7.1]
  def change
    create_table :materials do |t|
      t.string   :code,              null: false  # 'UB_UC_LOCAL', 'HOLLOW_STD'
      t.string   :name,              null: false  # 'Local UB & UC Sections'
      t.string   :category                        # 'sections', 'plates', 'hollow'
      t.decimal  :base_rate_per_tonne, precision: 12, scale: 2, null: false
      t.decimal  :waste_factor,      precision: 5, scale: 4, default: 0.0  # 0.075 = 7.5%
      t.date     :effective_from,    null: false
      t.date     :effective_to
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :materials, :code, unique: true
    add_index :materials, :category
  end
end
```

### Equipment Tables

```ruby
# Access equipment catalog (cherry pickers, booms, scissors)
class CreateEquipmentTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :equipment_types do |t|
      t.string   :category,          null: false  # 'electric_scissors', 'diesel_boom'
      t.string   :model,             null: false  # '600AJ', '3394RT'
      t.decimal  :working_height_m,  precision: 5, scale: 1
      t.decimal  :base_rate_monthly, precision: 12, scale: 2, null: false
      t.decimal  :damage_waiver_pct, precision: 5, scale: 4, default: 0.06
      t.decimal  :diesel_allowance_monthly, precision: 10, scale: 2, default: 0
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :equipment_types, [:category, :model], unique: true
  end
end

# Mobile crane rates
class CreateCraneRates < ActiveRecord::Migration[7.1]
  def change
    create_table :crane_rates do |t|
      t.string   :size,              null: false  # '25t', '50t', '90t'
      t.decimal  :dry_rate_per_day,  precision: 10, scale: 2, null: false
      t.decimal  :diesel_per_day,    precision: 10, scale: 2, default: 750
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :crane_rates, :size, unique: true
  end
end

# Crane complement recommendations (based on m²/day)
class CreateCraneComplements < ActiveRecord::Migration[7.1]
  def change
    create_table :crane_complements do |t|
      t.integer  :area_min_sqm,      null: false  # 250
      t.integer  :area_max_sqm,      null: false  # 350
      t.string   :complement_description          # '1 x 10t + 2 x 25t'
      t.decimal  :wet_rate_per_day,  precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :crane_complements, [:area_min_sqm, :area_max_sqm]
  end
end
```

---

## 2. TRANSACTIONAL TABLES (Project/Tender Data)

### Tender Core Tables

```ruby
# Main tender/quote record
class CreateTenders < ActiveRecord::Migration[7.1]
  def change
    create_table :tenders do |t|
      t.string     :tender_number,     null: false  # 'TND-2024-00123'
      t.string     :project_name,      null: false
      t.references :client,            foreign_key: true
      t.references :created_by,        foreign_key: { to_table: :users }
      t.date       :tender_date,       null: false
      t.date       :expiry_date
      t.decimal    :margin_pct,        precision: 5, scale: 4, default: 0
      t.string     :status,            default: 'draft'  # draft, submitted, won, lost
      t.text       :notes
      t.text       :qualifications                       # Tender qualifications text

      # Cached totals (denormalized for performance)
      t.decimal    :total_tonnage,     precision: 12, scale: 4
      t.decimal    :subtotal_amount,   precision: 14, scale: 2
      t.decimal    :margin_amount,     precision: 14, scale: 2
      t.decimal    :grand_total,       precision: 14, scale: 2

      t.timestamps
    end

    add_index :tenders, :tender_number, unique: true
    add_index :tenders, :status
    add_index :tenders, [:client_id, :created_at]
  end
end

# Tender cost inclusion toggles
class CreateTenderSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_inclusions_exclusions do |t|
      t.references :tender,                  foreign_key: true, null: false

      # Processing inclusions (maps to Rates Page F21:F30)
      t.boolean    :include_fabrication,     default: true
      t.boolean    :include_overheads,       default: true
      t.boolean    :include_shop_priming,    default: false
      t.boolean    :include_onsite_painting, default: false
      t.boolean    :include_delivery,        default: true
      t.boolean    :include_bolts,           default: true
      t.boolean    :include_erection,        default: true
      t.boolean    :include_crainage,        default: false
      t.boolean    :include_cherry_picker,   default: true
      t.boolean    :include_galvanizing,     default: false

      t.timestamps
    end

    add_index :tender_inclusions_exclusions, :tender_id, unique: true
  end
end

# Site parameters for equipment/crane calculations
class CreateTenderSiteConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_site_configs do |t|
      t.references :tender,                    foreign_key: true, null: false

      # Area and erection parameters
      t.decimal    :total_roof_area_sqm,       precision: 12, scale: 2
      t.decimal    :erection_rate_sqm_per_day, precision: 8, scale: 2, default: 300

      # Splicing crane
      t.boolean    :splicing_crane_required,   default: false
      t.string     :splicing_crane_size                              # '25t'
      t.integer    :splicing_crane_days,       default: 0

      # Miscellaneous crane
      t.boolean    :misc_crane_required,       default: false
      t.string     :misc_crane_size
      t.integer    :misc_crane_days,           default: 0

      # Calculated/override fields
      t.integer    :program_duration_days

      t.timestamps
    end

    add_index :tender_site_configs, :tender_id, unique: true
  end
end
```

### Line Item Tables

```ruby
# Bill of quantities line items
class CreateTenderLineItems < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_line_items do |t|
      t.references :tender,            foreign_key: true, null: false
      t.integer    :bill_number,       default: 1
      t.integer    :item_number,       null: false
      t.string     :description,       null: false
      t.string     :unit,              null: false, default: 't'  # t, No, m, m², Item
      t.decimal    :quantity,          precision: 12, scale: 4, null: false
      t.string     :line_type,         default: 'standard'  # standard, bolt, anchor, gutter, pg, provisional

      # Calculated outputs (cached)
      t.decimal    :rate_per_unit,     precision: 12, scale: 2
      t.decimal    :line_amount,       precision: 14, scale: 2
      t.decimal    :margin_amount,     precision: 12, scale: 2
      t.decimal    :rounding_amount,   precision: 10, scale: 2

      # Sorting/display
      t.integer    :sort_order
      t.string     :section_header                          # 'STEEL COLUMNS AND BEAMS'

      t.timestamps
    end

    add_index :tender_line_items, [:tender_id, :bill_number, :item_number], 
              unique: true, name: 'idx_line_items_unique'
    add_index :tender_line_items, [:tender_id, :sort_order]
  end
end

# Material composition per line item (for blended material costs)
class CreateLineItemMaterials < ActiveRecord::Migration[7.1]
  def change
    create_table :line_item_materials do |t|
      t.references :tender_line_item,  foreign_key: true, null: false
      t.references :material,          foreign_key: true, null: false
      t.decimal    :proportion,        precision: 5, scale: 4, default: 1.0  # 1.0 = 100%

      t.timestamps
    end

    add_index :line_item_materials, [:tender_line_item_id, :material_id], 
              unique: true, name: 'idx_line_materials_unique'
  end
end

# Equipment selections per tender
class CreateTenderEquipmentSelections < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_equipment_selections do |t|
      t.references :tender,            foreign_key: true, null: false
      t.references :equipment_type,    foreign_key: true, null: false
      t.integer    :units_required,    default: 1
      t.integer    :period_months,     default: 1
      t.string     :purpose                                 # 'Main erection', 'Crane beams'

      # Calculated
      t.decimal    :total_cost,        precision: 12, scale: 2

      t.timestamps
    end

    add_index :tender_equipment_selections, [:tender_id, :equipment_type_id]
  end
end
```

### Special Calculations Tables

```ruby
# Anchor bolt specifications (for non-standard pricing)
class CreateAnchorBoltSpecs < ActiveRecord::Migration[7.1]
  def change
    create_table :anchor_bolt_specs do |t|
      t.references :tender_line_item,  foreign_key: true, null: false
      t.integer    :diameter_mm,       null: false         # 30, 32, etc.
      t.integer    :length_mm,         null: false         # 660
      t.decimal    :kg_per_meter,      precision: 8, scale: 6
      t.integer    :nuts_per_set,      default: 5
      t.decimal    :nut_cost,          precision: 8, scale: 2
      t.decimal    :fab_cost,          precision: 8, scale: 2
      t.decimal    :overhead_pct,      precision: 5, scale: 4, default: 0.10

      t.timestamps
    end
  end
end

# P&G (Preliminaries & General) breakdown
class CreateTenderPreliminaryItems < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_preliminary_items do |t|
      t.references :tender,            foreign_key: true, null: false
      t.string     :item_code,         null: false         # 'SAFETY_FILE', 'CRAINAGE', etc.
      t.string     :description
      t.decimal    :lump_sum_amount,   precision: 12, scale: 2, default: 0
      t.decimal    :rate_per_tonne,    precision: 10, scale: 2, default: 0
      t.boolean    :is_included,       default: true

      t.timestamps
    end

    add_index :tender_preliminary_items, [:tender_id, :item_code], unique: true
  end
end
```

---

## 3. SUPPORTING TABLES

```ruby
# Clients/Customers
class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.string   :name,              null: false
      t.string   :contact_person
      t.string   :email
      t.string   :phone
      t.text     :address
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :clients, :name
  end
end

# Users (for created_by, updated_by tracking)
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string   :email,             null: false
      t.string   :name,              null: false
      t.string   :role,              default: 'estimator'  # admin, estimator, viewer
      t.string   :password_digest

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end

# Audit trail for rate changes
class CreateRateHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :rate_histories do |t|
      t.string     :rate_type,       null: false  # 'ProcessingRate', 'Material', etc.
      t.bigint     :rate_id,         null: false
      t.string     :field_changed,   null: false
      t.decimal    :old_value,       precision: 12, scale: 4
      t.decimal    :new_value,       precision: 12, scale: 4
      t.references :changed_by,      foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :rate_histories, [:rate_type, :rate_id]
  end
end
```

---

## 4. ENTITY RELATIONSHIP SUMMARY

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MASTER DATA (Reference)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐          │
│  │ processing_rates │  │    materials     │  │ equipment_types  │          │
│  ├──────────────────┤  ├──────────────────┤  ├──────────────────┤          │
│  │ id               │  │ id               │  │ id               │          │
│  │ code             │  │ code             │  │ category         │          │
│  │ rate_per_tonne   │  │ base_rate        │  │ model            │          │
│  │ is_lump_sum      │  │ waste_factor     │  │ base_rate_monthly│          │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘          │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                                │
│  │   crane_rates    │  │crane_complements │                                │
│  ├──────────────────┤  ├──────────────────┤                                │
│  │ id               │  │ id               │                                │
│  │ size             │  │ area_min_sqm     │                                │
│  │ dry_rate_per_day │  │ wet_rate_per_day │                                │
│  └──────────────────┘  └──────────────────┘                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        TRANSACTIONAL (Per Tender)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                         ┌──────────────────┐                                │
│       ┌─────────────────│     clients      │                                │
│       │                 └──────────────────┘                                │
│       │                          │                                          │
│       │                          │ has_many                                 │
│       ▼                          ▼                                          │
│  ┌──────────────────────────────────────────────────────────┐              │
│  │                        tenders                           │              │
│  ├──────────────────────────────────────────────────────────┤              │
│  │ id | tender_number | project_name | client_id | status   │              │
│  └──────────────────────────────────────────────────────────┘              │
│       │              │                    │                                 │
│       │ has_one      │ has_one            │ has_many                       │
│       ▼              ▼                    ▼                                 │
│  ┌────────────┐ ┌─────────────────┐ ┌──────────────────────┐               │
│  │  tender_   │ │ tender_site_    │ │  tender_line_items   │               │
│  │  settings  │ │ configs         │ ├──────────────────────┤               │
│  ├────────────┤ ├─────────────────┤ │ id                   │               │
│  │ include_*  │ │ roof_area_sqm   │ │ tender_id            │               │
│  │ (booleans) │ │ erection_rate   │ │ description          │               │
│  └────────────┘ │ crane configs   │ │ quantity             │               │
│                 └─────────────────┘ │ rate_per_unit        │               │
│                                     └──────────────────────┘               │
│       │ has_many                         │                                  │
│       ▼                                  │ has_many                         │
│  ┌─────────────────────────┐             ▼                                  │
│  │ tender_equipment_       │    ┌──────────────────────┐                   │
│  │ selections              │    │ line_item_materials  │                   │
│  ├─────────────────────────┤    ├──────────────────────┤                   │
│  │ equipment_type_id       │    │ material_id          │                   │
│  │ units_required          │    │ proportion           │                   │
│  │ period_months           │    └──────────────────────┘                   │
│  └─────────────────────────┘              │                                 │
│            │                              │ belongs_to                      │
│            │ belongs_to                   ▼                                 │
│            ▼                     ┌──────────────────┐                       │
│  ┌──────────────────┐            │    materials     │ (master)              │
│  │ equipment_types  │ (master)   └──────────────────┘                       │
│  └──────────────────┘                                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. RAILS MODELS (Key Associations)

```ruby
# app/models/tender.rb
class Tender < ApplicationRecord
  belongs_to :client
  belongs_to :created_by, class_name: 'User'
  
  has_one  :tender_setting, dependent: :destroy
  has_one  :tender_site_config, dependent: :destroy
  has_many :tender_line_items, dependent: :destroy
  has_many :tender_equipment_selections, dependent: :destroy
  has_many :tender_preliminary_items, dependent: :destroy
  
  accepts_nested_attributes_for :tender_setting
  accepts_nested_attributes_for :tender_site_config
  accepts_nested_attributes_for :tender_line_items, allow_destroy: true
  
  enum status: { draft: 'draft', submitted: 'submitted', won: 'won', lost: 'lost' }
  
  validates :tender_number, presence: true, uniqueness: true
  validates :project_name, presence: true
  
  before_validation :generate_tender_number, on: :create
  after_save :recalculate_totals, if: :saved_changes?
end

# app/models/tender_line_item.rb
class TenderLineItem < ApplicationRecord
  belongs_to :tender
  has_many :line_item_materials, dependent: :destroy
  has_many :materials, through: :line_item_materials
  has_one :anchor_bolt_spec, dependent: :destroy
  
  enum line_type: { 
    standard: 'standard', 
    bolt: 'bolt', 
    anchor: 'anchor', 
    gutter: 'gutter', 
    pg: 'pg', 
    provisional: 'provisional' 
  }
  
  validates :description, :quantity, :unit, presence: true
  
  after_save :calculate_rate, if: :saved_changes?
end

# app/models/material.rb
class Material < ApplicationRecord
  has_many :line_item_materials
  has_many :tender_line_items, through: :line_item_materials
  
  validates :code, presence: true, uniqueness: true
  validates :base_rate_per_tonne, presence: true, numericality: { greater_than: 0 }
  
  scope :active, -> { where(is_active: true) }
  scope :effective_on, ->(date) { 
    where('effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)', date, date) 
  }
  
  def rate_with_waste
    base_rate_per_tonne * (1 + waste_factor)
  end
end

# app/models/processing_rate.rb
class ProcessingRate < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :rate_per_tonne, presence: true
  
  scope :active, -> { where(is_active: true) }
  
  CODES = %w[
    SHOP_DRAWINGS FABRICATION OVERHEADS SHOP_PRIMING ONSITE_PAINTING
    DELIVERY BOLTS ERECTION CRAINAGE CHERRY_PICKER GALVANIZING SAFETY_FILE
  ].freeze
end
```

---

## 6. SERVICE OBJECTS FOR CALCULATIONS

```ruby
# app/services/tender_calculator.rb
class TenderCalculator
  ROUNDING_INCREMENT = 50
  CRAINAGE_ROUNDING = 20
  CHERRY_PICKER_ROUNDING = 10

  def initialize(tender)
    @tender = tender
    @settings = tender.tender_setting
    @site_config = tender.tender_site_config
  end

  def calculate_all
    calculate_equipment_rates
    calculate_crane_rates
    @tender.tender_line_items.each { |line| calculate_line_rate(line) }
    calculate_totals
  end

  private

  def calculate_line_rate(line)
    case line.line_type
    when 'standard' then StandardLineCalculator.new(line, @settings).calculate
    when 'anchor'   then AnchorBoltCalculator.new(line).calculate
    when 'gutter'   then GutterLineCalculator.new(line, @settings).calculate
    when 'pg'       then PreliminaryCalculator.new(line, @tender).calculate
    end
  end

  def round_to(value, increment)
    (value / increment).ceil * increment
  end
end

# app/services/standard_line_calculator.rb
class StandardLineCalculator
  def initialize(line_item, settings)
    @line = line_item
    @settings = settings
  end

  def calculate
    material_rate = calculate_material_rate
    processing_rate = calculate_processing_rate
    
    subtotal = material_rate + processing_rate
    margin = subtotal * (@line.tender.margin_pct || 0)
    total = subtotal + margin
    rounded_rate = round_up(total, 50)
    
    @line.update(
      rate_per_unit: rounded_rate,
      line_amount: rounded_rate * @line.quantity,
      margin_amount: margin * @line.quantity,
      rounding_amount: (rounded_rate - total) * @line.quantity
    )
  end

  private

  def calculate_material_rate
    @line.line_item_materials.sum do |lim|
      lim.material.rate_with_waste * lim.proportion
    end
  end

  def calculate_processing_rate
    rates = ProcessingRate.active.index_by(&:code)
    
    total = 0
    total += rates['FABRICATION'].rate_per_tonne    if @settings.include_fabrication
    total += rates['OVERHEADS'].rate_per_tonne      if @settings.include_overheads
    total += rates['SHOP_PRIMING'].rate_per_tonne   if @settings.include_shop_priming
    total += rates['ONSITE_PAINTING'].rate_per_tonne if @settings.include_onsite_painting
    total += rates['DELIVERY'].rate_per_tonne       if @settings.include_delivery
    total += rates['BOLTS'].rate_per_tonne          if @settings.include_bolts
    total += rates['ERECTION'].rate_per_tonne       if @settings.include_erection
    total += rates['CRAINAGE'].rate_per_tonne       if @settings.include_crainage
    total += rates['CHERRY_PICKER'].rate_per_tonne  if @settings.include_cherry_picker
    total += rates['GALVANIZING'].rate_per_tonne    if @settings.include_galvanizing
    total
  end

  def round_up(value, increment)
    (value.to_f / increment).ceil * increment
  end
end
```

---

## 7. DATABASE SEEDS EXAMPLE

```ruby
# db/seeds.rb

# Processing Rates (from Rates Page B16:B33)
ProcessingRate.create!([
  { code: 'SHOP_DRAWINGS',    name: 'Shop Drawings',              rate_per_tonne: 350,    effective_from: Date.today },
  { code: 'FABRICATION',      name: 'Fabrication',                rate_per_tonne: 8000,   effective_from: Date.today },
  { code: 'OVERHEADS',        name: 'Overheads',                  rate_per_tonne: 4150,   effective_from: Date.today },
  { code: 'SHOP_PRIMING',     name: 'Shop Priming incl Transport',rate_per_tonne: 1380,   effective_from: Date.today },
  { code: 'ONSITE_PAINTING',  name: 'On Site Painting',           rate_per_tonne: 1565,   effective_from: Date.today },
  { code: 'DELIVERY',         name: 'Delivery to Site',           rate_per_tonne: 700,    effective_from: Date.today },
  { code: 'BOLTS',            name: 'Bolts (capped @ 2%)',        rate_per_tonne: 1500,   effective_from: Date.today },
  { code: 'ERECTION',         name: 'Erection',                   rate_per_tonne: 1800,   effective_from: Date.today },
  { code: 'GALVANIZING',      name: 'Galvanizing',                rate_per_tonne: 11000,  effective_from: Date.today },
  { code: 'SAFETY_FILE',      name: 'Safety File & Audits',       rate_per_tonne: 30000,  is_lump_sum: true, effective_from: Date.today },
])

# Materials (from Rates Page B35:C56)
Material.create!([
  { code: 'UB_UC_LOCAL',    name: 'Local UB & UC Sections',         base_rate_per_tonne: 15900, waste_factor: 0.075,  category: 'sections', effective_from: Date.today },
  { code: 'UB_UC_IMPORT',   name: 'Import UB & UC Sections',        base_rate_per_tonne: 16170, waste_factor: 0.075,  category: 'sections', effective_from: Date.today },
  { code: 'PFC_SECTIONS',   name: 'PFC Sections',                   base_rate_per_tonne: 18743, waste_factor: 0.075,  category: 'sections', effective_from: Date.today },
  { code: 'HOLLOW_STD',     name: 'Standard Hollow Sections',       base_rate_per_tonne: 20980, waste_factor: 0.10,   category: 'hollow',   effective_from: Date.today },
  { code: 'PLATE_SHEETS',   name: 'Sheets of Plate',                base_rate_per_tonne: 15800, waste_factor: 0.125,  category: 'plates',   effective_from: Date.today },
  { code: 'CFLC_METSEC_16', name: 'CFLC Metsec Alternative 1.6mm',  base_rate_per_tonne: 21250, waste_factor: 0.0,    category: 'cflc',     effective_from: Date.today },
])

# Crane Rates (from DATA SHEET LOCKED)
CraneRate.create!([
  { size: '10t',  dry_rate_per_day: 2650,  diesel_per_day: 750 },
  { size: '20t',  dry_rate_per_day: 3150,  diesel_per_day: 750 },
  { size: '25t',  dry_rate_per_day: 1660,  diesel_per_day: 750 },
  { size: '30t',  dry_rate_per_day: 3650,  diesel_per_day: 750 },
  { size: '35t',  dry_rate_per_day: 3850,  diesel_per_day: 750 },
  { size: '50t',  dry_rate_per_day: 8500,  diesel_per_day: 850 },
  { size: '90t',  dry_rate_per_day: 12500, diesel_per_day: 1000 },
])
```

---

## 8. QUICK REFERENCE: TABLE NAMING

| Spreadsheet Source          | Rails Table Name               | Purpose                           |
| --------------------------- | ------------------------------ | --------------------------------- |
| Rates Page B16:B33          | `processing_rates`             | Fabrication, erection, etc. rates |
| Rates Page B35:C56          | `materials`                    | Steel material supply rates       |
| Rates Page F21:F30          | `tender_inclusions_exclusions` | Include/exclude toggles           |
| Rates Page E36:H48          | `tender_site_configs`          | Site parameters                   |
| Access Equipment            | `equipment_types`              | Cherry picker/boom catalog        |
| Access Equipment selections | `tender_equipment_selections`  | Equipment per tender              |
| DATA SHEET LOCKED A4:D10    | `crane_rates`                  | Mobile crane rates                |
| DATA SHEET LOCKED A15:C19   | `crane_complements`            | Crane selection lookup            |
| Tender Data                 | `tender_line_items`            | Bill of quantities                |
| Costing Sheet K39:N43       | `line_item_materials`          | Material mix per line             |
| Costing Sheet A139:E141     | `anchor_bolt_specs`            | Anchor bolt calculations          |
| Page 1 header               | `tenders` + `clients`          | Tender master data                |

---

This schema gives you a solid foundation for migrating the spreadsheet logic into a proper Rails application. Would you like me to elaborate on any specific area, such as the calculation service objects, API endpoints, or the front-end form structure?

______

What clarifying questions might be important to ask for the people who are running this spreadsheet, in order to make sure we are fully understanding it?


Excellent question! Before building an ERP system from this spreadsheet, it's critical to validate assumptions and uncover hidden business logic. Here are the key clarifying questions organized by category:

---

## 1. BUSINESS PROCESS & WORKFLOW QUESTIONS

### Tender Lifecycle

- **Who creates tenders?** Is it one estimator, or do multiple people collaborate on a single tender?
- **What is the approval workflow?** Does a tender need sign-off before being sent to the client? By whom?
- **How often do tenders get revised?** Do you need to track version history (Rev A, Rev B, etc.)?
- **What happens after a tender is won?** Does it convert into a project/job? How does that handoff work?
- **How long is a typical tender valid?** I see 30 days in G5 — is this standard or project-specific?

### Data Entry Process

- **Who maintains the rates on the Rates Page?** How often do they change?
- **How does the Tender Data get populated?** Is it manually typed, imported from a BOQ document, or pulled from another system?
- **Are there standard "templates" for common project types?** I see Standard Lines ( Copy ) — is this used as a starting template?

---

## 2. RATE & PRICING LOGIC QUESTIONS

### Processing Rates

- **The margin in B5 is currently 0% — is this intentional?** When would you apply a margin, and how is it decided?
- **Crainage rate (B24) is calculated dynamically from equipment costs — should this always be automatic, or do estimators sometimes override it?**
- **Cherry picker rate (B25) pulls from Access Equipment — what triggers the equipment selection? Is it always based on roof area?**
- **The P&G extra items (B27:B32) are all zero — what types of costs go here? Can you give examples?**

### Material Rates

- **How frequently do steel prices change?** Daily? Weekly? Monthly?
- **Who is responsible for updating material rates in C35:C56?**
- **Do you ever negotiate different rates with suppliers per project, or are these always standard rates?**
- **The waste factors (B35:B56) vary by material type — how were these percentages determined? Do they ever change?**

### Rounding Rules

- **I see rates are rounded to the nearest R50 (F35 uses `CEILING(...,50)`). Is this a company policy or industry standard?**
- **Crainage rounds to R20, cherry picker to R10 — why the different increments?**
- **The rounding creates small variances tracked in column I — does finance need to reconcile these?**

---

## 3. COSTING SHEET LOGIC QUESTIONS

### Line Item Calculations

- **Each line item has 19 rows of calculation. Are there ever items that need MORE cost components than the standard template?**
- **The include/exclude toggles (F21:F30) apply globally — do you ever need different inclusions for DIFFERENT line items within the same tender?**
    - For example: Include erection for structural steel but exclude it for supply-only items?
- **How do you handle line items that are "supply only" vs "supply and erect"?**

### Material Mix

- **In columns K-O, I see material breakdowns (e.g., K39:N43). How do you determine the material mix proportions?**
- **Is the material mix typically 100% one type, or do you often have blended items?**
- **Who decides which material type applies to each line item?**

### Special Item Types

- **Anchor bolts (A139:F147) have a unique calculation. Are there other "special" item types with custom pricing logic?**
- **How are gutters priced differently from standard steel sections?**
- **Provisional sums (like C49:C50 for plant room/office roofs) — how are these amounts determined? Are they just placeholders?**

---

## 4. EQUIPMENT & CRANE QUESTIONS

### Access Equipment

- **How do you decide which equipment to include for a project?** Is it based on:
    - Building height?
    - Roof area?
    - Steel complexity?
    - Site access constraints?
- **The equipment selections in G22:H29 show specific units and periods — who makes these decisions?**
- **Is the R15,000 mobilization fee in I42 always the same, or does it vary?**

### Crane Selection

- **The crane complement lookup in DATA SHEET LOCKED is based on m²/day erection rate. How accurate is this in practice?**
- **Do you ever need cranes NOT covered in the standard list (larger than 90t)?**
- **The "splicing crane" concept (F38:H42) — can you explain when this is needed?**

---

## 5. DATA INTEGRITY & EDGE CASES

### Error Handling

- **I noticed a #REF! error in C12 on the Rates Page. Are there known issues with the spreadsheet that need fixing?**
- **What happens if someone enters a quantity of zero? Or a negative number?**
- **Are there validation rules that should prevent certain entries?**

### Edge Cases

- **What's the smallest tender you've done (in tonnage)? The largest?**
- **Have you ever had a tender with NO steel erection (supply-only)?**
- **Do you ever tender in currencies other than Rand?**
- **Are there projects where galvanizing applies to SOME items but not others?**

---

## 6. REPORTING & OUTPUT QUESTIONS

### Tender Document

- **The Page 1 output — is this the actual document sent to clients, or is there additional formatting/export?**
- **Do clients ever request different formats (e.g., grouped by building, by trade, by phase)?**
- **Are there additional documents generated (cover letter, qualifications, terms & conditions)?**

### Internal Reporting

- **Do you track win/loss rates on tenders?**
- **Do you compare estimated vs actual costs after project completion?**
- **What management reports are generated from tender data?**
- **Do you need to see profitability analysis by:**
    - Client?
    - Project type?
    - Estimator?
    - Time period?

---

## 7. INTEGRATION & SYSTEM QUESTIONS

### Current Systems

- **What other systems does this spreadsheet interact with?**
    - Accounting/ERP?
    - Project management?
    - Inventory?
    - CRM?
- **How do you currently store/archive completed tenders?**
- **Is there any data that comes FROM other systems into this spreadsheet?**

### Future Needs

- **How many people need access to this system simultaneously?**
- **Do you need mobile/tablet access for site-based estimating?**
- **Are there approval workflows that should be enforced (not just tracked)?**
- **Do you need integration with supplier price feeds for automatic rate updates?**

---

## 8. HISTORICAL DATA QUESTIONS

- **How many tenders do you create per month/year?**
- **Do you need to migrate historical tenders into the new system?**
- **How far back does your tender history go?**
- **Are there "template" tenders that get copied and modified frequently?**

---

## 9. COMPLIANCE & AUDIT QUESTIONS

- **Are there industry regulations that require specific documentation or audit trails?**
- **Do you need to track WHO changed WHAT and WHEN for rate changes?**
- **Are there approval thresholds (e.g., tenders over R10M need director approval)?**
- **How long must tender records be retained?**

---

## 10. PRIORITY CLARIFICATIONS (Most Critical)

If time is limited, these are the **must-ask** questions:

|#|Question|Why It Matters|
|---|---|---|
|1|**Can inclusion toggles vary per line item, or always per tender?**|Fundamentally changes the data model|
|2|**How are material mix proportions determined?**|Currently hardcoded — needs to be configurable|
|3|**What triggers equipment selection?**|Need to understand if this is rule-based or manual|
|4|**Who updates rates and how often?**|Determines rate versioning requirements|
|5|**What happens after tender is won?**|Defines downstream system integration|
|6|**Are there other "special" item types beyond anchors?**|May need additional calculation engines|
|7|**Do you need to track tender versions/revisions?**|Affects data model significantly|
|8|**What reports do management need?**|Drives what data must be captured|

---

Would you like me to format these as a formal questionnaire document, or prioritize specific areas for a discovery workshop?


_____

**Convo Analysis:**

Here is a conversation we had with Richard, the owner of RSB, and with Darren, his brother and project consultant, and with the Software Solutions Architect, Kody.

\<CONVERSATION> ... \</CONVERSATION>
(Pasted from: https://otter.ai/u/uK2sFpF-Dg88Qp_3dWCYrcoMaFE?tab=chat&view=transcript )

There may be misspelled or inaccurate transcriptions since this was AI generated transcription from the voice. Does this change anything in our design?

This is a goldmine of clarifying information! Let me analyze the key insights from this conversation and how they impact our database design.

---

# Design Changes Based on Stakeholder Conversation

## 🔴 CRITICAL CHANGES REQUIRED

### 1. Crane Rates: RSB-Owned vs Rental Split

**What Richard said:**

> "We've got like 10 of our own cranes... On some projects we tender it as if it's a hired crane... On other projects we'll say okay, that 10 Tonner, we use RSB's 10 tons. So then we would change the dry rate... to like 1000 Rand a day, because it's just the guy's wages and a bit of maintenance."

**Design Change:**

```ruby
# BEFORE: Single crane_rates table
# AFTER: Split into ownership types

class CreateCraneRates < ActiveRecord::Migration[7.1]
  def change
    create_table :crane_rates do |t|
      t.string   :size,              null: false  # '25t', '50t', etc.
      t.string   :ownership_type,    null: false  # 'rsb_owned', 'rental'
      t.decimal  :dry_rate_per_day,  precision: 10, scale: 2, null: false
      t.decimal  :diesel_per_day,    precision: 10, scale: 2, default: 750
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :crane_rates, [:size, :ownership_type], unique: true
  end
end
```

**Seed Data Impact:**

```ruby
# Each crane size needs TWO entries
CraneRate.create!([
  { size: '10t',  ownership_type: 'rental',    dry_rate_per_day: 2650,  diesel_per_day: 750 },
  { size: '10t',  ownership_type: 'rsb_owned', dry_rate_per_day: 1000,  diesel_per_day: 750 },
  { size: '25t',  ownership_type: 'rental',    dry_rate_per_day: 1660,  diesel_per_day: 750 },
  { size: '25t',  ownership_type: 'rsb_owned', dry_rate_per_day: 800,   diesel_per_day: 750 },
  # ... etc
])
```

---

### 2. Expanded Crane Size Range

**What Richard said:**

> "We should probably increase that database to have a few more larger cranes... 110, 130, maybe 160, 200, 250"

**Design Change:** Add these sizes to the seed data:

|Size|Notes|
|---|---|
|110t|New|
|130t|New|
|160t|New|
|200t|New|
|250t|New (rarely used but "rather have it there")|

---

### 3. Crane Complement is Editable Per Tender

**What Richard said:**

> "Sometimes we play around with instead of it being one times 10 ton and two times 25, sometimes we'll say okay the building's really short, we're going to allow three times 25"

**Design Change:** The `crane_complements` table provides DEFAULTS, but tenders need their own editable crane selection:

```ruby
# Master defaults (rarely changed)
class CreateCraneComplements < ActiveRecord::Migration[7.1]
  def change
    create_table :crane_complements do |t|
      t.integer  :area_min_sqm,       null: false
      t.integer  :area_max_sqm,       null: false
      t.string   :default_complement  # '1 x 10t + 2 x 25t' - just for display/reference
      t.decimal  :default_wet_rate,   precision: 10, scale: 2

      t.timestamps
    end
  end
end

# Per-tender crane selections (EDITABLE)
class CreateTenderCraneSelections < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_crane_selections do |t|
      t.references :tender,            foreign_key: true, null: false
      t.references :crane_rate,        foreign_key: true, null: false  # Links to size + ownership
      t.integer    :quantity,          default: 1
      t.string     :purpose,           default: 'main'  # 'main', 'splicing', 'miscellaneous'
      t.integer    :duration_days

      # Calculated
      t.decimal    :total_cost,        precision: 12, scale: 2

      t.timestamps
    end

    add_index :tender_crane_selections, [:tender_id, :crane_rate_id, :purpose],
              name: 'idx_tender_crane_unique'
  end
end
```

---

### 4. Access Equipment: Multiple Selections of Same Type

**What Richard said:**

> "You might say okay we want three for one month and we want one for two months... three or four line items that are all 450AJ"

**Design Change:** Allow multiple rows of the same equipment type with different quantities/periods:

```ruby
class CreateTenderEquipmentSelections < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_equipment_selections do |t|
      t.references :tender,            foreign_key: true, null: false
      t.references :equipment_type,    foreign_key: true, null: false
      t.integer    :units_required,    default: 1
      t.integer    :period_months,     default: 1
      t.string     :purpose                              # 'Crane beams', 'Main erection', etc.

      # Allow override of monthly cost if needed
      t.decimal    :monthly_cost_override, precision: 12, scale: 2, null: true

      # Calculated
      t.decimal    :total_cost,        precision: 12, scale: 2

      t.timestamps
    end

    # NOTE: Removed unique constraint - same equipment can appear multiple times
    add_index :tender_equipment_selections, :tender_id
  end
end
```

---

### 5. Fabrication Rate Factors by Work Type

**What Richard said:**

> "Our mining tenders, you've got structural steelwork fabrication rate, you've got a platework fabrication rate, you've got a piping fabrication rate... platework would be at a 1.75 times factor... piping would be at a three times factor"

**Design Change:** Add work type factors to processing rates:

```ruby
class CreateProcessingRates < ActiveRecord::Migration[7.1]
  def change
    create_table :processing_rates do |t|
      t.string   :code,              null: false  # 'FABRICATION', 'ERECTION', etc.
      t.string   :name,              null: false
      t.string   :work_type,         default: 'structural'  # 'structural', 'platework', 'piping'
      t.decimal  :base_rate_per_tonne, precision: 12, scale: 2, null: false
      t.decimal  :factor,            precision: 5, scale: 2, default: 1.0  # 1.0, 1.75, 3.0
      t.boolean  :is_lump_sum,       default: false
      t.date     :effective_from,    null: false
      t.date     :effective_to
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :processing_rates, [:code, :work_type], unique: true
  end
end
```

**Seed Data:**

```ruby
ProcessingRate.create!([
  { code: 'FABRICATION', work_type: 'structural', base_rate_per_tonne: 8000, factor: 1.0 },
  { code: 'FABRICATION', work_type: 'platework',  base_rate_per_tonne: 8000, factor: 1.75 },
  { code: 'FABRICATION', work_type: 'piping',     base_rate_per_tonne: 8000, factor: 3.0 },
])
```

---

### 6. Galvanizing Has a Build-Up Formula

**What Richard said:**

> "Galvanizing itself, the guys will charge you 8400 a ton, but they charge you once it's already been dipped in the zinc. So it picks up 7.5% mass, and then there's a fettling additional... and a delivery added onto it"

**Design Change:** Create a galvanizing breakdown table:

```ruby
class CreateGalvanizingRates < ActiveRecord::Migration[7.1]
  def change
    create_table :galvanizing_rates do |t|
      t.decimal  :base_dip_rate,       precision: 10, scale: 2, null: false  # 8400
      t.decimal  :zinc_mass_factor,    precision: 5, scale: 4, default: 0.075  # 7.5%
      t.decimal  :fettling_per_tonne,  precision: 10, scale: 2, default: 500
      t.decimal  :delivery_per_tonne,  precision: 10, scale: 2, default: 850
      t.date     :effective_from,      null: false
      t.boolean  :is_active,           default: true

      t.timestamps
    end
  end
end

# Calculated rate = base_dip_rate * (1 + zinc_mass_factor) + fettling + delivery
# Example: 8400 * 1.075 + 500 + 850 = 10,380 (rounded to ~11,000)
```

---

### 7. Additional Processing "Extra Overs"

**What Richard said:**

> "There's a few value-add extras: curving, castellating, MPI testing, weld testing... we always have to manually change it from galvanizing... Just underneath galvanizing, say to Demi, what are these extra overs we want?"

**Design Change:** Add flexible "extra over" processing types:

```ruby
class CreateExtraOverTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :extra_over_types do |t|
      t.string   :code,              null: false  # 'CASTELLATING', 'CURVING', 'MPI', 'WELD_TEST'
      t.string   :name,              null: false
      t.decimal  :default_rate,      precision: 12, scale: 2
      t.decimal  :default_factor,    precision: 5, scale: 2, default: 1.0
      t.boolean  :is_active,         default: true

      t.timestamps
    end

    add_index :extra_over_types, :code, unique: true
  end
end

# Per line-item extra overs
class CreateLineItemExtraOvers < ActiveRecord::Migration[7.1]
  def change
    create_table :line_item_extra_overs do |t|
      t.references :tender_line_item,  foreign_key: true, null: false
      t.references :extra_over_type,   foreign_key: true, null: false
      t.boolean    :is_included,       default: false
      t.decimal    :rate_override,     precision: 12, scale: 2, null: true
      t.decimal    :factor_override,   precision: 5, scale: 2, null: true

      t.timestamps
    end
  end
end
```

**Initial Extra Over Types:**

```ruby
ExtraOverType.create!([
  { code: 'CASTELLATING', name: 'Castellating',       default_factor: 1.5 },
  { code: 'CURVING',      name: 'Curving/Cambering',  default_factor: 1.3 },
  { code: 'MPI',          name: 'MPI Testing',        default_rate: 500 },
  { code: 'WELD_TEST',    name: 'Weld Testing',       default_rate: 750 },
])
```

---

### 8. P&G Items are Fully Manual/Custom

**What Richard said:**

> "How much is it going to cost us to take all of our cranes and ship it to site... How much to fly project manager twice a month and sleep over... How much for labor teams living there for six months... Those would be the kinds of items we would put manually into P&G... That's the kind of stuff that you can't really automate because it changes all the time"

**Design Change:** P&G items need to be fully flexible with custom descriptions:

```ruby
class CreateTenderPreliminaryItems < ActiveRecord::Migration[7.1]
  def change
    create_table :tender_preliminary_items do |t|
      t.references :tender,            foreign_key: true, null: false
      t.string     :item_code                              # Optional standard code
      t.string     :description,       null: false         # Custom description
      t.text       :calculation_notes                      # "20 people x 6 months x R5000"
      t.decimal    :lump_sum_amount,   precision: 12, scale: 2, null: false
      t.boolean    :is_included,       default: true
      t.integer    :sort_order

      t.timestamps
    end
  end
end
```

---

## 🟡 NAMING CHANGES (Per Richard's Terminology)

| Original Name                     | New Name                  | Reason                                               |
| --------------------------------- | ------------------------- | ---------------------------------------------------- |
| `on_site_breakdown`               | `lifting_plant_breakdown` | Richard: "Lifting plant and access equipment"        |
| `bill_of_material`                | `material_breakdown`      | Richard: "We never use bill of material, always BOQ" |
| `tender_line_item_cost_breakdown` | `line_item_rate_build_up` | Richard: "That can be your rate build up"            |
| `access_equipment`                | ✓ Keep as is              | Richard confirmed this name                          |
|                                   |                           |                                                      |

---

## 🟢 THINGS CONFIRMED AS CORRECT

|Feature|Confirmation|
|---|---|
|Damage waiver at 6%|"6% will always remain 6%"|
|Rates updated annually|"Once a year we'll update that"|
|Include/exclude toggles|"If those are a Yes, it'll put it in your breakdown"|
|Material breakdown on right side|"That little table on the right... material breakdown"|
|Page 1 = Line items, Costing Sheet = Rate build up|Confirmed the relationship|
|Equipment selections per tender with units + months|Confirmed the structure|

---

## 🔵 DEFERRED FEATURES (Richard said "not now")

| Feature                           | Richard's Quote                                                                              |
| --------------------------------- | -------------------------------------------------------------------------------------------- |
| Auto-detect bolt threshold (2.5%) | "I wouldn't do that in the beginning... once the whole system's working and there's no bugs" |
| Complex bolt mass calculations    | "That is also pretty much like a manual thing"                                               |

---

## 📋 REVISED TABLE NAMING SUMMARY

| Table Name                     | Purpose                                 | Source Sheet                |
| ------------------------------ | --------------------------------------- | --------------------------- |
| `processing_rates`             | Fab, erection, delivery, etc.           | Rates Page B16:B33          |
| `materials`                    | Steel material supply rates             | Rates Page B35:C56          |
| `equipment_types`              | Cherry picker/boom catalog              | Access Equipment            |
| `tender_equipment_selections`  | Equipment per tender (multiple rows OK) | Access Equipment G:I        |
| `crane_rates`                  | Mobile crane rates (RSB + rental)       | DATA SHEET LOCKED           |
| `crane_complements`            | Default crane recommendations           | DATA SHEET LOCKED           |
| `tender_crane_selections`      | Editable cranes per tender              | Rates Page E36:H48          |
| `galvanizing_rates`            | Galvanizing build-up                    | Rates Page B26              |
| `extra_over_types`             | Castellating, curving, MPI, etc.        | New requirement             |
| `tenders`                      | Tender header                           | Page 1 header               |
| `tender_inclusions_exclusions` | Include/exclude toggles                 | Rates Page F21:F30          |
| `tender_site_configs`          | Site parameters                         | Rates Page E36:H48          |
| `tender_line_items`            | BOQ line items                          | Tender Data                 |
| `line_item_materials`          | Material breakdown per line             | Costing Sheet K:O           |
| `line_item_rate_build_ups`     | Rate build up calculations              | Costing Sheet C:F           |
| `line_item_extra_overs`        | Extra overs per line                    | New requirement             |
| `tender_preliminary_items`     | P&G custom items                        | Costing Sheet (P&G section) |
| `clients`                      | Customer master                         | Page 1 header               |
| `users`                        | System users                            | New                         |

---

## 🎯 KEY INSIGHTS FOR IMPLEMENTATION

1. **Three levels of configuration** (Darren articulated this well):
    
    - Company-wide defaults (rates, equipment catalog)
    - Tender-level settings (inclusions, site config)
    - Line-item level overrides (specific rates, extra overs)
2. **Richard wants comprehensive tracking**: "Every single rand that ever gets spent, all has to be allowed for and tracked from this initial setup"
    
3. **Demi wants efficiency**: Richard noted tension between his comprehensive vision and Demi's desire for simplicity
    
4. **Permission levels will matter**: Richard explicitly said "Demi mustn't be able to change a lot of the stuff"
    

---

Would you like me to generate the complete revised migration files, or focus on any specific area in more detail?
