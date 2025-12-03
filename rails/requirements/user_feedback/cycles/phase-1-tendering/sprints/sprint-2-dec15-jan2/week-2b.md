# Sprint 2, Week 2b: Calculation Engine & Rate Build-ups (Dec 22-26)

**Duration:** 1 week  
**Focus:** Line item rate calculations, rounding logic, tender totals  
**Deliverable:** All rates calculated automatically; calculations match Excel templates

---

## Week Overview

Week 2b implements the core calculation engine that powers the RSB tendering system. All line item rates are calculated using the business rules from the Excel templates, rounding is applied correctly, and tender totals are aggregated automatically. By week's end, all calculations are complete and tested.

---

## Scope: Line Item Rate Build-up Calculator

### Calculation Service Foundation
**File:** `app/services/line_item_calculator.rb`

**Tasks:**
1. Create main calculator service:
   ```ruby
   class LineItemCalculator
     def self.calculate(line_item)
       new(line_item).calculate
     end
     
     def initialize(line_item)
       @line_item = line_item
       @tender = line_item.tender
       @inclusions = @tender.inclusions_exclusions
     end
     
     def calculate
       build_up = @line_item.rate_build_up || @line_item.create_rate_build_up!
       
       # Fetch all component rates
       build_up.material_supply_rate = calculate_material_rate
       build_up.fabrication_rate = fetch_processing_rate('FABRICATION')
       build_up.fabrication_factor = calculate_fabrication_factor
       build_up.fabrication_included = @inclusions.include_fabrication
       
       build_up.overheads_rate = fetch_processing_rate('OVERHEADS')
       build_up.overheads_included = @inclusions.include_overheads
       
       build_up.shop_priming_rate = fetch_processing_rate('SHOP_PRIMING')
       build_up.shop_priming_included = @inclusions.include_shop_priming
       
       build_up.onsite_painting_rate = fetch_processing_rate('ONSITE_PAINTING')
       build_up.onsite_painting_included = @inclusions.include_onsite_painting
       
       build_up.delivery_rate = fetch_processing_rate('DELIVERY')
       build_up.delivery_included = @inclusions.include_delivery
       
       build_up.bolts_rate = fetch_processing_rate('BOLTS')
       build_up.bolts_included = @inclusions.include_bolts
       
       build_up.erection_rate = fetch_processing_rate('ERECTION')
       build_up.erection_included = @inclusions.include_erection
       
       build_up.crainage_rate = 0  # Will be calculated at tender level
       build_up.crainage_included = @inclusions.include_crainage
       
       build_up.cherry_picker_rate = 0  # Will be calculated at tender level
       build_up.cherry_picker_included = @inclusions.include_cherry_picker
       
       build_up.galvanizing_rate = fetch_galvanizing_rate
       build_up.galvanizing_included = @inclusions.include_galvanizing
       
       # Calculate subtotal with inclusions
       build_up.subtotal = calculate_subtotal(build_up)
       
       # Apply margin
       build_up.margin_amount = (build_up.subtotal * @tender.margin_pct).round(2)
       build_up.total_before_rounding = build_up.subtotal + build_up.margin_amount
       
       # Apply rounding rule
       build_up.rounded_rate = RoundingService.round(build_up.total_before_rounding, :standard)
       
       build_up.save!
       
       # Update line item totals
       @line_item.update(
         rate_per_unit: build_up.rounded_rate,
         line_amount: (build_up.rounded_rate * @line_item.quantity).round(2),
         margin_amount: build_up.margin_amount
       )
       
       build_up
     end
     
     private
     
     def calculate_material_rate
       # Blended material rate with waste
       total_rate = 0.0
       
       @line_item.materials.each do |material|
         base_rate = fetch_material_rate(material.material_supply_id)
         waste_pct = material.material_supply.waste_percentage
         rate_with_waste = base_rate * (1 + waste_pct)
         total_rate += rate_with_waste * material.proportion
       end
       
       total_rate.round(2)
     end
     
     def fetch_material_rate(material_supply_id)
       material_supply = MaterialSupply.find(material_supply_id)
       rate_record = MaterialSupplyRate.where(
         material_supply_id: material_supply_id,
         is_active: true
       ).where('effective_from <= ?', Date.today)
        .order(effective_from: :desc)
        .first
       
       rate_record&.rate_per_tonne || material_supply.base_rate_per_tonne || 0
     end
     
     def fetch_processing_rate(code)
       ProcessingRate.where(
         code: code,
         is_active: true
       ).where('effective_from <= ?', Date.today)
        .order(effective_from: :desc)
        .first&.base_rate_per_tonne || 0
     end
     
     def calculate_fabrication_factor
       # Determine factor based on line item category or work type
       case @line_item.category
       when 'Platework', 'Plate'
         1.75
       when 'Piping'
         3.0
       else  # Structural sections, default
         1.0
       end
     end
     
     def fetch_galvanizing_rate
       # Galvanizing only included if checkbox set
       return 0 unless @inclusions.include_galvanizing
       
       gal_rate = GalvanizingRate.where(is_active: true)
         .where('effective_from <= ?', Date.today)
         .order(effective_from: :desc)
         .first
       
       return 0 unless gal_rate
       
       # Galvanizing rate = base_dip_rate * (1 + zinc_mass_factor) + fettling + delivery
       (gal_rate.base_dip_rate * (1 + gal_rate.zinc_mass_factor) + 
        (gal_rate.fettling_per_tonne || 0) + 
        (gal_rate.delivery_per_tonne || 0)).round(2)
     end
     
     def calculate_subtotal(build_up)
       subtotal = build_up.material_supply_rate
       
       subtotal += build_up.fabrication_rate * build_up.fabrication_factor if build_up.fabrication_included
       subtotal += build_up.overheads_rate if build_up.overheads_included
       subtotal += build_up.shop_priming_rate if build_up.shop_priming_included
       subtotal += build_up.onsite_painting_rate if build_up.onsite_painting_included
       subtotal += build_up.delivery_rate if build_up.delivery_included
       subtotal += build_up.bolts_rate if build_up.bolts_included
       subtotal += build_up.erection_rate if build_up.erection_included
       subtotal += build_up.crainage_rate if build_up.crainage_included
       subtotal += build_up.cherry_picker_rate if build_up.cherry_picker_included
       subtotal += build_up.galvanizing_rate if build_up.galvanizing_included
       
       subtotal.round(2)
     end
   end
   ```

### Rounding Service
**File:** `app/services/rounding_service.rb`

**Tasks:**
1. Create service with all rounding rules:
   ```ruby
   class RoundingService
     # Rounding intervals per business rules
     ROUNDING_RULES = {
       standard: 50,       # Most line items: round to R50
       crainage: 20,       # Crainage: round to R20
       cherry_picker: 10,  # Cherry picker: round to R10
       pg: 50,             # P&G: round to R50
       shop_drawings: 50   # Shop drawings: round to R50
     }.freeze
     
     def self.round(amount, rule_type = :standard)
       interval = ROUNDING_RULES[rule_type]
       raise ArgumentError, "Unknown rounding rule: #{rule_type}" unless interval
       
       # Round up to nearest interval
       return 0 if amount <= 0
       ((amount.ceil / interval.to_f).ceil * interval).to_i
     end
     
     # Also provide decimal-precise version
     def self.round_decimal(amount, rule_type = :standard)
       round(amount, rule_type).to_f
     end
   end
   ```

**Tests for rounding:**
1. Test cases:
   - RoundingService.round(34672.50, :standard) => 34700
   - RoundingService.round(1075.02, :crainage) => 1080
   - RoundingService.round(1428.41, :cherry_picker) => 1430
   - RoundingService.round(1112.20, :pg) => 1150

---

## Scope: Equipment & Crainage Rate Calculations

### Equipment Rate Calculator
**File:** `app/services/equipment_rate_calculator.rb`

**Tasks:**
1. Create service:
   ```ruby
   class EquipmentRateCalculator
     def self.calculate(tender)
       new(tender).calculate
     end
     
     def initialize(tender)
       @tender = tender
     end
     
     def calculate
       total_tonnage = @tender.total_tonnage
       return 0 if total_tonnage.zero?
       
       total_equipment_cost = @tender.equipment_selections.sum(&:total_cost)
       equipment_rate_per_tonne = total_equipment_cost / total_tonnage
       
       # Equipment rates round to R10
       RoundingService.round(equipment_rate_per_tonne, :cherry_picker)
     end
   end
   ```

### Crainage Rate Calculator
**File:** `app/services/crane_rate_calculator.rb`

**Tasks:**
1. Create service:
   ```ruby
   class CraneRateCalculator
     def self.calculate(tender)
       new(tender).calculate
     end
     
     def initialize(tender)
       @tender = tender
       @on_site = tender.on_site_breakdown
     end
     
     def calculate
       # If crainage not included in line items, return 0
       # (it will be in P&G instead)
       return 0 unless @tender.inclusions_exclusions.include_crainage
       
       # Calculate crane cost
       total_crane_cost = calculate_total_crane_cost
       
       total_tonnage = @tender.total_tonnage
       return 0 if total_tonnage.zero?
       
       crainage_rate = total_crane_cost / total_tonnage
       
       # Crainage rounds to R20
       RoundingService.round(crainage_rate, :crainage)
     end
     
     private
     
     def calculate_total_crane_cost
       # Step 1: Look up crane complement based on erection rate
       complement = find_crane_complement
       return 0 unless complement
       
       # Step 2: Calculate program duration
       program_duration = calculate_program_duration
       
       # Step 3: Calculate main crane cost
       main_crane_cost = complement.default_wet_rate_per_day * program_duration
       
       # Step 4: Add splicing crane if required
       splicing_cost = calculate_splicing_cost
       
       # Step 5: Add misc crane if required
       misc_cost = calculate_misc_cost
       
       # Total
       main_crane_cost + splicing_cost + misc_cost
     end
     
     def find_crane_complement
       CraneComplement.where(
         'area_min_sqm <= ? AND area_max_sqm >= ?',
         @on_site.erection_rate_sqm_per_day,
         @on_site.erection_rate_sqm_per_day
       ).first
     end
     
     def calculate_program_duration
       return 0 if @on_site.erection_rate_sqm_per_day.zero?
       (@on_site.total_roof_area_sqm / @on_site.erection_rate_sqm_per_day).ceil
     end
     
     def calculate_splicing_cost
       return 0 unless @on_site.splicing_crane_required?
       
       crane_rate = CraneRate.find_by(
         size: @on_site.splicing_crane_size,
         ownership_type: 'rental'
       )
       return 0 unless crane_rate
       
       daily_rate = crane_rate.dry_rate_per_day + (crane_rate.diesel_per_day || 0)
       daily_rate * @on_site.splicing_crane_days
     end
     
     def calculate_misc_cost
       return 0 unless @on_site.misc_crane_required?
       
       crane_rate = CraneRate.find_by(
         size: @on_site.misc_crane_size,
         ownership_type: 'rental'
       )
       return 0 unless crane_rate
       
       daily_rate = crane_rate.dry_rate_per_day + (crane_rate.diesel_per_day || 0)
       daily_rate * @on_site.misc_crane_days
     end
   end
   ```

### Shop Drawings Calculation
**Create:** Service for shop drawings line item

**File:** `app/services/shop_drawings_calculator.rb`

**Tasks:**
1. Create service:
   ```ruby
   class ShopDrawingsCalculator
     def self.calculate(tender)
       new(tender).calculate
     end
     
     def initialize(tender)
       @tender = tender
     end
     
     def calculate
       # Shop drawings rate is per tonne of steel
       total_tonnage = @tender.total_tonnage
       return 0 if total_tonnage.zero?
       
       shop_drawings_rate = fetch_shop_drawings_rate
       total_amount = shop_drawings_rate * total_tonnage
       
       # Apply margin
       with_margin = total_amount * (1 + @tender.margin_pct)
       
       # Shop drawings round to R50
       RoundingService.round(with_margin, :shop_drawings)
     end
     
     private
     
     def fetch_shop_drawings_rate
       ProcessingRate.where(code: 'SHOP_DRAWINGS', is_active: true)
         .where('effective_from <= ?', Date.today)
         .order(effective_from: :desc)
         .first&.base_rate_per_tonne || 350
     end
   end
   ```

---

## Scope: Tender Calculation Orchestrator

### Main Tender Calculator
**File:** `app/services/tender_calculator.rb`

**Tasks:**
1. Create orchestrator service:
   ```ruby
   class TenderCalculator
     def self.calculate(tender)
       new(tender).calculate
     end
     
     def initialize(tender)
       @tender = tender
     end
     
     def calculate
       # Step 1: Recalculate all line item rates
       @tender.line_items.where(line_type: 'standard').each do |line_item|
         LineItemCalculator.calculate(line_item)
       end
       
       # Step 2: Calculate tender-level costs
       equipment_rate = EquipmentRateCalculator.calculate(@tender)
       crainage_rate = CraneRateCalculator.calculate(@tender)
       cherry_picker_rate = EquipmentRateCalculator.calculate(@tender)  # For now, same as equipment
       
       # Step 3: Update equipment and crainage rates in line items
       # (if included in line items rather than P&G)
       if @tender.inclusions_exclusions.include_cherry_picker
         update_rate_for_component('cherry_picker', cherry_picker_rate)
       end
       
       if @tender.inclusions_exclusions.include_crainage
         update_rate_for_component('crainage', crainage_rate)
       end
       
       # Step 4: Recalculate P&G items
       PgCalculator.calculate(@tender)
       
       # Step 5: Update tender totals
       update_tender_totals
       
       @tender
     end
     
     private
     
     def update_rate_for_component(component, rate)
       # Update all line item build-ups with equipment/crainage rate
       @tender.line_items.each do |line_item|
         build_up = line_item.rate_build_up
         next unless build_up
         
         case component
         when 'cherry_picker'
           build_up.update(cherry_picker_rate: rate) if build_up.cherry_picker_included
         when 'crainage'
           build_up.update(crainage_rate: rate) if build_up.crainage_included
         end
       end
     end
     
     def update_tender_totals
       total_tonnage = @tender.line_items.sum(:quantity)
       subtotal = @tender.line_items.sum(:line_amount)
       
       # Add P&G items
       pg_total = @tender.preliminary_items.where(is_included: true).sum do |item|
         item.rate_per_tonne * total_tonnage
       end
       
       # Add shop drawings
       shop_drawings_total = ShopDrawingsCalculator.calculate(@tender)
       
       @tender.update(
         total_tonnage: total_tonnage,
         subtotal_amount: subtotal,
         grand_total: subtotal + pg_total + shop_drawings_total
       )
     end
   end
   ```

---

## Scope: Calculation Trigger Points

### After Inclusions/Exclusions Change
**File:** `app/models/tender_inclusions_exclusions.rb`

**Tasks:**
1. Add callback:
   ```ruby
   after_update :trigger_recalculation
   
   def trigger_recalculation
     TenderCalculator.calculate(tender)
   end
   ```

### After On-Site Breakdown Change
**File:** `app/models/tender_on_site_breakdown.rb`

**Tasks:**
1. Add callback:
   ```ruby
   after_update :trigger_recalculation
   
   def trigger_recalculation
     TenderCalculator.calculate(tender)
   end
   ```

### After Margin Change
**File:** `app/models/tender.rb`

**Tasks:**
1. Add callback:
   ```ruby
   before_save :trigger_recalculation_if_margin_changed
   
   def trigger_recalculation_if_margin_changed
     if margin_pct_changed?
       TenderCalculator.calculate(self)
     end
   end
   ```

### After Equipment Selection Change
**File:** `app/models/tender_equipment_selection.rb`

**Tasks:**
1. Add callbacks:
   ```ruby
   after_save :trigger_tender_recalculation
   after_destroy :trigger_tender_recalculation
   
   private
   
   def trigger_tender_recalculation
     TenderCalculator.calculate(tender)
   end
   ```

### After Crane Selection Change
**File:** `app/models/tender_crane_selection.rb`

**Tasks:**
1. Add callbacks:
   ```ruby
   after_save :trigger_tender_recalculation
   after_destroy :trigger_tender_recalculation
   
   private
   
   def trigger_tender_recalculation
     TenderCalculator.calculate(tender)
   end
   ```

---

## Scope: Rate Display in Views

### Line Item Rate Detail Partial
**File:** `app/views/tender_line_items/_rate_build_up.html.erb`

**Tasks:**
1. Create partial to display expandable rate detail:
   ```erb
   <% build_up = line_item.rate_build_up %>
   <% if build_up %>
     <tr class="rate-detail-row hidden" data-line-item-id="<%= line_item.id %>">
       <td colspan="7" class="bg-gray-50 p-4">
         <div class="grid grid-cols-3 gap-6">
           <!-- Material Component -->
           <div>
             <h4 class="font-semibold text-sm mb-2">Material Supply</h4>
             <div class="text-sm">
               <div class="flex justify-between">
                 <span>Base Rate:</span>
                 <span><%= number_to_currency build_up.material_supply_rate %></span>
               </div>
               <% line_item.materials.each do |material| %>
                 <div class="text-xs text-gray-600 mt-1">
                   <%= material.material_supply.name %>
                   (<%= (material.proportion * 100).to_i %>%)
                 </div>
               <% end %>
             </div>
           </div>
           
           <!-- Processing Components -->
           <div>
             <h4 class="font-semibold text-sm mb-2">Processing</h4>
             <div class="text-sm space-y-1">
               <% if build_up.fabrication_included %>
                 <div class="flex justify-between">
                   <span>Fabrication (×<%= build_up.fabrication_factor %>):</span>
                   <span><%= number_to_currency(build_up.fabrication_rate * build_up.fabrication_factor) %></span>
                 </div>
               <% end %>
               <% if build_up.overheads_included %>
                 <div class="flex justify-between">
                   <span>Overheads:</span>
                   <span><%= number_to_currency build_up.overheads_rate %></span>
                 </div>
               <% end %>
               <% if build_up.shop_priming_included %>
                 <div class="flex justify-between">
                   <span>Shop Priming:</span>
                   <span><%= number_to_currency build_up.shop_priming_rate %></span>
                 </div>
               <% end %>
               <!-- ... other components ... -->
             </div>
           </div>
           
           <!-- Totals -->
           <div>
             <h4 class="font-semibold text-sm mb-2">Calculation</h4>
             <div class="text-sm space-y-1">
               <div class="flex justify-between">
                 <span>Subtotal:</span>
                 <span><%= number_to_currency build_up.subtotal %></span>
               </div>
               <div class="flex justify-between">
                 <span>Margin (<%= (@tender.margin_pct * 100).to_i %>%):</span>
                 <span><%= number_to_currency build_up.margin_amount %></span>
               </div>
               <div class="flex justify-between font-semibold border-t pt-1">
                 <span>Before Rounding:</span>
                 <span><%= number_to_currency build_up.total_before_rounding %></span>
               </div>
               <div class="flex justify-between font-semibold text-lg">
                 <span>Rounded Rate (R50):</span>
                 <span class="text-primary"><%= number_to_currency build_up.rounded_rate %></span>
               </div>
             </div>
           </div>
         </div>
       </td>
     </tr>
   <% end %>
   ```

### Line Items Index with Expansion
**File:** `app/views/tender_line_items/index.html.erb`

**Tasks:**
1. Update to show expandable rate details:
   ```erb
   <div class="overflow-x-auto">
     <table class="table table-compact">
       <thead>
         <tr>
           <th></th>
           <th>Page</th>
           <th>Item</th>
           <th>Description</th>
           <th>Unit</th>
           <th>Qty</th>
           <th>Rate</th>
           <th>Amount</th>
           <th></th>
         </tr>
       </thead>
       <tbody>
         <% @line_items.each do |item| %>
           <tr class="hover">
             <td>
               <button class="btn btn-sm btn-ghost"
                       onclick="toggleDetail(<%= item.id %>)">
                 ▼
               </button>
             </td>
             <td><%= item.page_number %></td>
             <td><%= item.item_number %></td>
             <td><%= item.description %></td>
             <td><%= item.unit %></td>
             <td><%= number_with_precision item.quantity, precision: 2 %></td>
             <td><strong><%= number_to_currency item.rate_per_unit %></strong></td>
             <td><strong><%= number_to_currency item.line_amount %></strong></td>
             <td>
               <%= link_to 'Edit', edit_tender_line_item_path(@tender, item), 
                   class: 'btn btn-sm btn-ghost' %>
               <%= link_to 'Delete', tender_line_item_path(@tender, item), 
                   method: :delete, data: { confirm: 'Sure?' },
                   class: 'btn btn-sm btn-error' %>
             </td>
           </tr>
           
           <%= render 'rate_build_up', line_item: item, tender: @tender %>
         <% end %>
       </tbody>
     </table>
   </div>
   ```

### Toggle Detail JavaScript
**File:** `app/javascript/controllers/line_items_controller.js`

**Tasks:**
1. Create Stimulus controller:
   ```javascript
   import { Controller } from "@hotwired/stimulus"
   
   export default class extends Controller {
     toggleDetail(lineItemId) {
       const detailRow = document.querySelector(
         `tr.rate-detail-row[data-line-item-id="${lineItemId}"]`
       )
       if (detailRow) {
         detailRow.classList.toggle('hidden')
       }
     }
   }
   ```

---

## Scope: Testing & Validation

### Calculation Test Cases
**Tasks:**
1. Create test data with known rates
2. Test scenarios:
   - **Simple case:** 1 line item, steel sections, all inclusions on
   - **Margin case:** Same line item with 10% margin applied
   - **Multiple materials:** Blended material (85% UB/UC + 15% Plate)
   - **Fabrication factors:** Platework (1.75x) vs Structural (1.0x)
   - **Exclusions:** Toggle off shop priming, verify removed from calc
   - **Equipment:** Add equipment, verify crainage rate calculated
   - **Rounding:** Verify all rounding rules (R50, R20, R10) applied correctly

### Excel Template Validation
**Tasks:**
1. Compare calculations with original Excel:
   - Pick 3-5 real tenders from Excel
   - Input same data into system
   - Verify calculations match exactly
   - Document any discrepancies
   - Resolve before going live

### Edge Cases
**Tasks:**
1. Test:
   - Zero quantity line item → should calculate 0 amount
   - Missing rates → should default to 0 or show error
   - Very large quantities → ensure no overflow
   - Very small margin → verify not lost in rounding
   - All toggles off → should show only material rate

---

## Acceptance Criteria

- [ ] LineItemCalculator works: calculates all rate components
- [ ] Blended material rates calculated correctly
- [ ] Fabrication multipliers applied (1.0x, 1.75x, 3.0x)
- [ ] Margin applied before rounding
- [ ] RoundingService rounds correctly (R50, R20, R10)
- [ ] Equipment rate calculated per tonne
- [ ] Crainage rate calculated with program duration
- [ ] Splicing and misc cranes added to crainage cost
- [ ] Shop drawings rate calculated per tonne
- [ ] TenderCalculator orchestrates all calculations
- [ ] Recalculation triggered on inclusions/exclusions change
- [ ] Recalculation triggered on margin change
- [ ] Recalculation triggered on equipment/crane selection change
- [ ] Line item rate detail view shows all components
- [ ] Expandable rows work: click to show/hide detail
- [ ] All calculations verified against Excel templates
- [ ] Edge cases handled: zero qty, missing rates, etc.
- [ ] No N+1 queries when calculating

---

**Week 2b Status:** Ready for Development  
**Last Updated:** Current Date
