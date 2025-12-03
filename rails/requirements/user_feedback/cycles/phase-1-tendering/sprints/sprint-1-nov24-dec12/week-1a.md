# Sprint 1, Week 1a: Database & Infrastructure (Nov 24-28)

**Duration:** 1 week  
**Focus:** Database schema, migrations, seed data setup  
**Deliverable:** Complete master data schema with populated seed data

---

## Week Overview

Week 1a establishes the foundational database infrastructure. All master data tables are created, migrations run successfully, and realistic RSB rates are seeded. By end of week, the database is ready for model development in Week 1b.

---

## Scope: Database Schema & Migrations

### Suppliers Table
**Create migration:** `create_suppliers`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- name (string, NOT NULL)
- contact_person (string)
- email (string)
- phone (string)
- is_active (boolean, DEFAULT true)
- created_at (datetime)
- updated_at (datetime)
```

**Tasks:**
1. Generate migration: `rails generate migration CreateSuppliers`
2. Add fields with correct types and constraints
3. Run migration: `rails db:migrate`
4. Verify in schema.rb

---

### Material Supplies Table
**Create migration:** `create_material_supplies`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- code (string, NOT NULL, unique)
- name (string, NOT NULL)
- category (string) # sections, plate, gutters, etc.
- base_rate_per_tonne (decimal, precision: 10, scale: 2)
- waste_percentage (decimal, precision: 5, scale: 3, DEFAULT 0.075)
- effective_from (date, NOT NULL)
- is_active (boolean, DEFAULT true)
- created_at (datetime)
- updated_at (datetime)

# Indices
- unique index on code
- index on category
- index on is_active
```

**Tasks:**
1. Generate migration: `rails generate migration CreateMaterialSupplies`
2. Add fields with correct types and constraints
3. Add unique index on code
4. Add indexes on category and is_active for query performance
5. Run migration
6. Verify in schema.rb

---

### Material Supply Rates Table
**Create migration:** `create_material_supply_rates`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- material_supply_id (bigint, FK to material_supplies, NOT NULL)
- supplier_id (bigint, FK to suppliers, NOT NULL)
- rate_per_tonne (decimal, precision: 10, scale: 2, NOT NULL)
- effective_from (date, NOT NULL)
- is_active (boolean, DEFAULT true)
- created_at (datetime)
- updated_at (datetime)

# Indices
- composite index on (material_supply_id, supplier_id, is_active)
- index on effective_from for date queries
```

**Tasks:**
1. Generate migration: `rails generate migration CreateMaterialSupplyRates`
2. Add foreign keys with dependent: :destroy
3. Add composite index for common queries
4. Run migration
5. Verify foreign key constraints

---

### Processing Rates Table
**Create migration:** `create_processing_rates`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- code (string, NOT NULL, unique) # FABRICATION, ERECTION, etc.
- name (string, NOT NULL)
- base_rate_per_tonne (decimal, precision: 10, scale: 2, NOT NULL)
- work_type (string) # structural, platework, piping
- factor (decimal, precision: 3, scale: 2, DEFAULT 1.0)
- is_active (boolean, DEFAULT true)
- effective_from (date, NOT NULL)
- created_at (datetime)
- updated_at (datetime)

# Indices
- unique index on code
- index on is_active
```

**Expected Rates (from current Excel):**
- SHOP_DRAWINGS: R350/t
- FABRICATION: R8,000/t (with factors: structural=1.0, platework=1.75, piping=3.0)
- OVERHEADS: R4,150/t
- SHOP_PRIMING: R1,380/t
- ONSITE_PAINTING: R1,565/t
- DELIVERY: R700/t
- BOLTS: R1,500/t
- ERECTION: R1,800/t
- GALVANIZING: R11,000/t
- SAFETY_FILE: R30,000 (lump sum)

**Tasks:**
1. Generate migration
2. Add all fields with correct types
3. Add unique index on code
4. Run migration
5. Verify in schema.rb

---

### Equipment Types Table
**Create migration:** `create_equipment_types`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- category (string, NOT NULL) # diesel_articulating_boom, electric_scissors, etc.
- model (string, NOT NULL)
- working_height_m (decimal, precision: 5, scale: 2)
- base_rate_monthly (decimal, precision: 10, scale: 2, NOT NULL)
- damage_waiver_pct (decimal, precision: 3, scale: 2, DEFAULT 0.06)
- diesel_allowance_monthly (decimal, precision: 10, scale: 2)
- is_active (boolean, DEFAULT true)
- created_at (datetime)
- updated_at (datetime)

# Indices
- index on category
- index on is_active
```

**Expected Equipment Types:**
- Electric Scissors: 3394RT, 4394RT
- Diesel Scissors: 530LRT
- Diesel Booms: 450AJ, 600AJ, 800AJ
- Telehandlers: TH6

**Tasks:**
1. Generate migration
2. Add all fields
3. Add indexes
4. Run migration

---

### Crane Rates Table
**Create migration:** `create_crane_rates`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- size (string, NOT NULL) # 10t, 20t, 25t, 30t, 35t, 50t, 90t
- ownership_type (string, NOT NULL) # owned, rental
- dry_rate_per_day (decimal, precision: 10, scale: 2, NOT NULL)
- diesel_per_day (decimal, precision: 10, scale: 2)
- is_active (boolean, DEFAULT true)
- created_at (datetime)
- updated_at (datetime)

# Indices
- composite index on (size, ownership_type, is_active)
```

**Tasks:**
1. Generate migration
2. Add fields with correct types
3. Add composite index
4. Run migration

---

### Crane Complements Table
**Create migration:** `create_crane_complements`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- area_min_sqm (decimal, precision: 8, scale: 2, NOT NULL)
- area_max_sqm (decimal, precision: 8, scale: 2, NOT NULL)
- complement_description (string, NOT NULL) # 1x10t + 2x25t, etc.
- default_wet_rate_per_day (decimal, precision: 10, scale: 2, NOT NULL)
- created_at (datetime)
- updated_at (datetime)

# Indices
- index on area_min_sqm for range lookups
```

**Expected Complements (from current lookup table):**
- 250-350 m/day: 1x25t + 1x10t, R8,300/day
- Other ranges as defined in Excel

**Tasks:**
1. Generate migration
2. Add fields
3. Run migration

---

### Extra Over Types Table
**Create migration:** `create_extra_over_types`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- code (string, NOT NULL, unique)
- name (string, NOT NULL)
- default_rate (decimal, precision: 10, scale: 2, NOT NULL)
- default_factor (decimal, precision: 5, scale: 2)
- is_active (boolean, DEFAULT true)
- created_at (datetime)
- updated_at (datetime)

# Indices
- unique index on code
- index on is_active
```

**Expected Extra Overs:**
- CASTELLATING: R2,500/t
- CURVING: [rate TBD]
- MPI: [rate TBD]
- WELD_TEST: [rate TBD]

**Tasks:**
1. Generate migration
2. Add fields
3. Run migration

---

### Galvanizing Rates Table
**Create migration:** `create_galvanizing_rates`

```ruby
# Fields
- id (bigint, PK, auto-increment)
- base_dip_rate (decimal, precision: 10, scale: 2, NOT NULL)
- zinc_mass_factor (decimal, precision: 3, scale: 3, DEFAULT 0.075)
- fettling_per_tonne (decimal, precision: 10, scale: 2)
- delivery_per_tonne (decimal, precision: 10, scale: 2)
- effective_from (date, NOT NULL)
- is_active (boolean, DEFAULT true)
- created_at (datetime)
- updated_at (datetime)

# Indices
- index on effective_from
- index on is_active
```

**Expected Rates:**
- Base dip: R8,400
- Zinc mass factor: 7.5%
- Fettling: R500/t
- Delivery: R850/t

**Tasks:**
1. Generate migration
2. Add fields
3. Run migration

---

## Scope: Seed Data

### Suppliers Seed
**File:** `db/seeds/suppliers_seed.rb` (or in main seeds.rb)

**Data to seed:**
```
- Macsteel (main structural steel supplier)
- DRAM Coatings (paint/priming supplier)
- Local Paint Co (alternative)
- Import Sections (overseas steel supplier)
```

**Tasks:**
1. Create seeds with at least 4 suppliers
2. Include realistic contact info (can be placeholder)
3. Set is_active = true for all

---

### Material Supplies Seed
**File:** `db/seeds/material_supplies_seed.rb`

**Data to seed (22 types from current Rates Page):**

| Code | Name | Category | Base Rate | Waste % |
|------|------|----------|-----------|---------|
| UB_UC_LOCAL | Local UB & UC Sections | sections | 15,900 | 7.5% |
| UB_UC_IMPORT | Import UB & UC Sections | sections | 18,500 | 7.5% |
| PFC_SECTIONS | PFC Sections | sections | 16,200 | 7.5% |
| IPE_SECTIONS | IPE Sections | sections | 17,100 | 7.5% |
| SHEETS_PLATE | Sheets of Plate | plate | 15,300 | 5.0% |
| CUT_PLATE | Cut to Size Plate | plate | 16,800 | 5.0% |
| HOLLOW_STD | Standard Hollow Sections | sections | 14,600 | 7.5% |
| HOLLOW_CUSTOM | Non-Standard Hollow Sections | sections | 17,200 | 7.5% |
| GUTTERS | Gutters | special | 12,400 | 5.0% |
| ROUND_BAR | Round Bar | bar | 13,800 | 5.0% |
| CFLC_1_6MM | CFLC Metsec Alternative 1.6mm | special | 11,200 | 3.0% |
| CFLC_2MM | CFLC Metsec Alternative 2mm | special | 12,100 | 3.0% |
| [Additional types] | [...] | [...] | [...] | [...] |

**Tasks:**
1. Extract all 22 material types from current Excel Rates Page (B35:C56)
2. Assign logical codes (UB_UC_LOCAL, etc.)
3. Group by category (sections, plate, special)
4. Create seeds
5. Set effective_from to today's date

---

### Material Supply Rates Seed
**File:** `db/seeds/material_supply_rates_seed.rb`

**Data to seed:**
- Link each material_supply to each supplier with supplier-specific rates
- For MVP: can use same rate for all suppliers, but structure allows for variation
- Macsteel = primary (default), second supplier at slightly lower price (to implement "second cheapest" logic)

**Example:**
```ruby
# UB_UC_LOCAL with Macsteel (primary, ~10% premium)
MaterialSupplyRate.create(
  material_supply: UB_UC_LOCAL,
  supplier: Macsteel,
  rate_per_tonne: 17500,
  effective_from: Date.today
)

# UB_UC_LOCAL with DRAM (second cheapest)
MaterialSupplyRate.create(
  material_supply: UB_UC_LOCAL,
  supplier: DRAM,
  rate_per_tonne: 15900,
  effective_from: Date.today
)
```

**Tasks:**
1. For each material_supply, create rates for at least 2 suppliers
2. Make one supplier ~10% higher (premium) and one at base rate (competitive)
3. Set effective_from to today's date
4. Set is_active = true

---

### Processing Rates Seed
**File:** `db/seeds/processing_rates_seed.rb`

**Data to seed:**
```ruby
[
  { code: 'SHOP_DRAWINGS', name: 'Shop Drawings', base_rate: 350, work_type: nil, factor: 1.0 },
  { code: 'FABRICATION', name: 'Fabrication', base_rate: 8000, work_type: 'structural', factor: 1.0 },
  { code: 'FABRICATION', name: 'Fabrication', base_rate: 8000, work_type: 'platework', factor: 1.75 },
  { code: 'FABRICATION', name: 'Fabrication', base_rate: 8000, work_type: 'piping', factor: 3.0 },
  { code: 'OVERHEADS', name: 'Overheads', base_rate: 4150, work_type: nil, factor: 1.0 },
  { code: 'SHOP_PRIMING', name: 'Shop Priming', base_rate: 1380, work_type: nil, factor: 1.0 },
  { code: 'ONSITE_PAINTING', name: 'On-Site Painting', base_rate: 1565, work_type: nil, factor: 1.0 },
  { code: 'DELIVERY', name: 'Delivery', base_rate: 700, work_type: nil, factor: 1.0 },
  { code: 'BOLTS', name: 'Bolts', base_rate: 1500, work_type: nil, factor: 1.0 },
  { code: 'ERECTION', name: 'Erection', base_rate: 1800, work_type: nil, factor: 1.0 },
  { code: 'GALVANIZING', name: 'Galvanizing', base_rate: 11000, work_type: nil, factor: 1.0 },
  { code: 'SAFETY_FILE', name: 'Safety File & Audits', base_rate: 30000, work_type: nil, factor: 1.0 }
]
```

**Tasks:**
1. Create one record per processing type
2. For FABRICATION, create 3 records (structural=1.0, platework=1.75, piping=3.0) to support different work types
3. Set effective_from to today
4. Set is_active = true

---

### Crane Rates Seed
**File:** `db/seeds/crane_rates_seed.rb`

**Data to seed (example rates):**
```ruby
# RSB-owned cranes (lower rate)
# Rental cranes (higher rate + diesel)

sizes = ['10t', '20t', '25t', '30t', '35t', '50t', '90t']

sizes.each do |size|
  # RSB-owned
  CraneRate.create(
    size: size,
    ownership_type: 'owned',
    dry_rate_per_day: calculate_owned_rate(size),
    diesel_per_day: 500 # typical diesel allowance
  )
  
  # Rental
  CraneRate.create(
    size: size,
    ownership_type: 'rental',
    dry_rate_per_day: calculate_rental_rate(size),
    diesel_per_day: 650 # higher diesel for rental
  )
end
```

**Tasks:**
1. Create crane rates for each size (10t through 90t)
2. Create both 'owned' and 'rental' entries per size
3. Rental rates should be 15-20% higher than owned
4. Add realistic diesel allowances
5. Set is_active = true

---

### Equipment Types Seed
**File:** `db/seeds/equipment_types_seed.rb`

**Data to seed (from current Access Equipment sheet):**

| Category | Model | Working Height | Base Rate Monthly | Damage Waiver | Diesel Monthly |
|----------|-------|-----------------|-------------------|---------------|----------------|
| electric_scissors | 3394RT | 13.6m | 22,000 | 6% | 0 |
| electric_scissors | 4394RT | 18.0m | 28,500 | 6% | 0 |
| diesel_scissors | 530LRT | 20.5m | 31,200 | 6% | 8,000 |
| diesel_boom | 450AJ | 14.5m | 32,100 | 6% | 16,500 |
| diesel_boom | 600AJ | 20.0m | 38,195 | 6% | 19,500 |
| diesel_boom | 800AJ | 26.0m | 45,800 | 6% | 22,500 |
| telehandler | TH6 | 6.0m | 24,600 | 6% | 12,000 |

**Tasks:**
1. Extract data from current Access Equipment sheet
2. Create seeds with all fields
3. Set damage_waiver_pct = 0.06 for all
4. Set is_active = true

---

### Crane Complements Seed
**File:** `db/seeds/crane_complements_seed.rb`

**Data to seed (from current DATA SHEET LOCKED lookup table):**

```ruby
# Example from current Excel:
# For 250-350 m/day erection rate:
# Crane complement: 1x25t + 1x10t
# Wet rate: R8,300/day
```

**Tasks:**
1. Create at least 3-4 crane complement brackets:
   - area_min: 250, area_max: 350, complement: "1x25t + 1x10t", rate: 8300
   - area_min: 350, area_max: 500, complement: "2x25t + 1x10t", rate: 10500
   - [additional brackets as defined in Excel]
2. Set is_active = true

---

### Extra Over Types Seed
**File:** `db/seeds/extra_over_types_seed.rb`

**Data to seed:**
```ruby
[
  { code: 'CASTELLATING', name: 'Castellating', default_rate: 2500, default_factor: 1.5 },
  { code: 'CURVING', name: 'Curving', default_rate: 3200, default_factor: 1.2 },
  { code: 'MPI', name: 'MPI Testing', default_rate: 1800, default_factor: 1.0 },
  { code: 'WELD_TEST', name: 'Weld Testing', default_rate: 1500, default_factor: 1.0 }
]
```

**Tasks:**
1. Create seeds for all 4 extra over types
2. Use realistic rates from current spreadsheet
3. Set is_active = true

---

### Galvanizing Rates Seed
**File:** `db/seeds/galvanizing_rates_seed.rb`

**Data to seed:**
```ruby
GalvanizingRate.create(
  base_dip_rate: 8400,
  zinc_mass_factor: 0.075, # 7.5%
  fettling_per_tonne: 500,
  delivery_per_tonne: 850,
  effective_from: Date.today,
  is_active: true
)
```

**Tasks:**
1. Create single galvanizing rate record
2. Set effective_from to today
3. Set is_active = true

---

## Verification & Testing

### Post-Migration Verification

**Tasks:**
1. Run `rails db:migrate` and verify all migrations applied
2. Check `db/schema.rb` contains all tables with correct columns
3. Run `rails db:seed` and verify no errors
4. Open Rails console and verify:
   ```ruby
   Supplier.count # Should be 4+
   MaterialSupply.count # Should be 22
   MaterialSupplyRate.count # Should be 44+ (22 materials × 2+ suppliers)
   ProcessingRate.count # Should be 12+
   CraneRate.count # Should be 14 (7 sizes × 2 ownership types)
   EquipmentType.count # Should be 7+
   ```

### Query Testing

**Tasks:**
1. Test material supply lookup:
   ```ruby
   MaterialSupply.find_by(code: 'UB_UC_LOCAL')
   # => #<MaterialSupply code="UB_UC_LOCAL", name="Local UB & UC Sections", ...>
   ```

2. Test crane rate lookup:
   ```ruby
   CraneRate.where(size: '25t', ownership_type: 'rental')
   # => [#<CraneRate size="25t", dry_rate_per_day=...>]
   ```

3. Test processing rate with factor:
   ```ruby
   ProcessingRate.find_by(code: 'FABRICATION', work_type: 'platework')
   # => #<ProcessingRate base_rate_per_tonne=8000, factor=1.75>
   ```

4. Test equipment query:
   ```ruby
   EquipmentType.find_by(model: '600AJ')
   # => #<EquipmentType category="diesel_boom", base_rate_monthly=38195, ...>
   ```

---

## Acceptance Criteria

- [ ] All 8 master data tables created successfully
- [ ] All migrations run without errors
- [ ] schema.rb updated with all tables
- [ ] Seeds file runs without errors: `rails db:seed`
- [ ] Can query each master data type from Rails console
- [ ] All foreign keys have correct constraints
- [ ] All indexes created as specified
- [ ] Seed data counts match expected totals
- [ ] No duplicate codes in unique-indexed fields
- [ ] All dates set to today (consistent)

---

**Week 1a Status:** Ready for Development  
**Last Updated:** Current Date
