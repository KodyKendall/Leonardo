# Sprint 2, Week 2a: Rate Management & Tender Configuration (Dec 15-19)

**Duration:** 1 week  
**Focus:** Rate model associations, inclusions/exclusions UI, equipment & crane selection  
**Deliverable:** Users can configure tenders with inclusions, on-site parameters, equipment, and cranes

---

## Week Overview

Week 2a implements the tender configuration interface. Users can now toggle cost components, set on-site parameters, select equipment and cranes, and see real-time cost calculations. This is the bridge between line item creation and final tender output.

---

## Scope: Rate Model Associations

### Current Rate Lookups
**Add methods to rate models for current pricing**

**File:** `app/models/material_supply.rb`

**Tasks:**
1. Add method to fetch current rate:
   ```ruby
   def current_rate
     MaterialSupplyRate.where('effective_from <= ?', Date.today)
       .where(is_active: true)
       .order(effective_from: :desc)
       .limit(1)
       .first
   end
   ```
2. Add method to calculate weighted rate with waste:
   ```ruby
   def rate_with_waste
     return 0 unless current_rate
     current_rate.rate_per_tonne * (1 + waste_percentage)
   end
   ```
3. Add method to get second-cheapest supplier (for default selection):
   ```ruby
   def self.second_cheapest_supplier(material_id)
     MaterialSupplyRate.where(material_supply_id: material_id, is_active: true)
       .where('effective_from <= ?', Date.today)
       .order(rate_per_tonne: :asc)
       .limit(2)
       .last&.supplier_id
   end
   ```

**File:** `app/models/processing_rate.rb`

**Tasks:**
1. Add method to fetch current rate:
   ```ruby
   def self.current_rate(code, work_type = nil)
     where(code: code, work_type: work_type, is_active: true)
       .where('effective_from <= ?', Date.today)
       .order(effective_from: :desc)
       .first&.base_rate_per_tonne || 0
   end
   ```

**File:** `app/models/equipment_type.rb`

**Tasks:**
1. Add method to calculate monthly cost:
   ```ruby
   def monthly_cost
     base_rate_monthly * (1 + damage_waiver_pct) + diesel_allowance_monthly
   end
   ```

**File:** `app/models/crane_rate.rb`

**Tasks:**
1. Add method to calculate daily rate:
   ```ruby
   def daily_rate
     dry_rate_per_day + (diesel_per_day || 0)
   end
   ```

### Line Item Material Association Defaults
**File:** `app/models/tender_line_item.rb`

**Tasks:**
1. Add after_create callback to set default materials:
   ```ruby
   after_create :set_default_materials
   
   def set_default_materials
     # If no materials exist, create default based on category
     if materials.empty?
       default_material = find_default_material_for_category(category)
       materials.create!(
         material_supply_id: default_material.id,
         proportion: 1.0
       ) if default_material
     end
   end
   
   private
   
   def find_default_material_for_category(category)
     case category
     when 'Steel Sections', 'Columns', 'Beams'
       MaterialSupply.find_by(code: 'UB_UC_LOCAL')
     when 'Plate', 'Plates'
       MaterialSupply.find_by(code: 'SHEETS_PLATE')
     when 'Bolts', 'Fasteners'
       MaterialSupply.find_by(code: 'ROUND_BAR')
     when 'Gutters'
       MaterialSupply.find_by(code: 'GUTTERS')
     when 'CFLC', 'Cold-Rolled'
       MaterialSupply.find_by(code: 'CFLC_1_6MM')
     else
       MaterialSupply.find_by(code: 'UB_UC_LOCAL')
     end
   end
   ```

---

## Scope: Inclusions/Exclusions Configuration

### Tender Configuration View Layout
**File:** `app/views/tenders/configuration/index.html.erb`

**Tasks:**
1. Create view structure with sections:
   ```erb
   <div class="container mx-auto p-6">
     <h1 class="text-3xl font-bold mb-6">Tender Configuration</h1>
     
     <form method="post" action="<%= tender_configuration_path(@tender) %>">
       <!-- Inclusions/Exclusions Section -->
       <div class="card mb-6">
         <div class="card-body">
           <h2 class="card-title">Cost Components</h2>
           <div class="divider"></div>
           
           <% @inclusions.attributes.each do |key, value| %>
             <% next if key.in?(['id', 'tender_id', 'created_at', 'updated_at']) %>
             <label class="label cursor-pointer">
               <span class="label-text"><%= key.humanize %></span>
               <input type="checkbox" 
                      name="tender_inclusions_exclusions[<%= key %>]"
                      <%= 'checked' if value %>
                      class="checkbox">
             </label>
           <% end %>
         </div>
       </div>
       
       <!-- On-Site Parameters Section -->
       <div class="card mb-6">
         <div class="card-body">
           <h2 class="card-title">On-Site Parameters</h2>
           <div class="divider"></div>
           
           <div class="grid grid-cols-2 gap-4">
             <div class="form-control">
               <label class="label">
                 <span class="label-text">Total Roof Area (m²)</span>
               </label>
               <input type="number" 
                      step="0.01"
                      name="tender_on_site_breakdown[total_roof_area_sqm]"
                      value="<%= @on_site.total_roof_area_sqm %>"
                      class="input input-bordered">
             </div>
             
             <div class="form-control">
               <label class="label">
                 <span class="label-text">Area Erected Per Day (m/day)</span>
               </label>
               <input type="number" 
                      step="0.01"
                      name="tender_on_site_breakdown[erection_rate_sqm_per_day]"
                      value="<%= @on_site.erection_rate_sqm_per_day %>"
                      class="input input-bordered">
             </div>
           </div>
           
           <!-- Splicing Crane -->
           <div class="mt-6">
             <h3 class="font-semibold mb-3">Splicing Crane</h3>
             <label class="label cursor-pointer mb-3">
               <span class="label-text">Required?</span>
               <input type="checkbox" 
                      name="tender_on_site_breakdown[splicing_crane_required]"
                      <%= 'checked' if @on_site.splicing_crane_required %>
                      data-target="splicing-crane"
                      class="checkbox toggle-splicing">
             </label>
             
             <div id="splicing-crane" class="<%= 'hidden' unless @on_site.splicing_crane_required %>">
               <div class="grid grid-cols-2 gap-4">
                 <div class="form-control">
                   <label class="label">
                     <span class="label-text">Crane Size</span>
                   </label>
                   <select name="tender_on_site_breakdown[splicing_crane_size]" 
                           class="select select-bordered">
                     <option value="">Select size...</option>
                     <% %w[10t 20t 25t 30t 35t 50t 90t].each do |size| %>
                       <option <%= 'selected' if @on_site.splicing_crane_size == size %>>
                         <%= size %>
                       </option>
                     <% end %>
                   </select>
                 </div>
                 
                 <div class="form-control">
                   <label class="label">
                     <span class="label-text">Duration (days)</span>
                   </label>
                   <input type="number"
                          name="tender_on_site_breakdown[splicing_crane_days]"
                          value="<%= @on_site.splicing_crane_days %>"
                          class="input input-bordered">
                 </div>
               </div>
             </div>
           </div>
           
           <!-- Misc Crane (similar structure) -->
           <!-- [Similar HTML for misc crane] -->
         </div>
       </div>
       
       <!-- Margin Section -->
       <div class="card mb-6">
         <div class="card-body">
           <h2 class="card-title">Margin</h2>
           <div class="divider"></div>
           
           <div class="form-control">
             <label class="label">
               <span class="label-text">Tender-Level Margin (%)</span>
             </label>
             <input type="number" 
                    step="0.1"
                    min="0"
                    max="100"
                    name="tender[margin_pct]"
                    value="<%= @tender.margin_pct * 100 %>"
                    class="input input-bordered">
             <label class="label">
               <span class="label-text-alt">Applied to all line items before rounding</span>
             </label>
           </div>
         </div>
       </div>
       
       <!-- Actions -->
       <div class="flex gap-3">
         <button type="submit" class="btn btn-primary">Save Configuration</button>
         <a href="<%= tender_path(@tender) %>" class="btn btn-ghost">Cancel</a>
       </div>
     </form>
   </div>
   ```

2. Style with Tailwind/Daisy UI

### Tender Configuration Routes
**File:** `config/routes.rb`

**Tasks:**
1. Add routes:
   ```ruby
   resources :tenders do
     get 'configuration', to: 'tender_configurations#show', as: 'configuration'
     patch 'configuration', to: 'tender_configurations#update'
   end
   ```

### Tender Configurations Controller
**File:** `app/controllers/tender_configurations_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller TenderConfigurations`
2. Implement show action:
   ```ruby
   def show
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :update?
     @inclusions = @tender.inclusions_exclusions || 
                   @tender.create_inclusions_exclusions!
     @on_site = @tender.on_site_breakdown || 
                @tender.create_on_site_breakdown!
   end
   ```
3. Implement update action:
   ```ruby
   def update
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :update?
     
     # Update inclusions/exclusions
     if params[:tender_inclusions_exclusions].present?
       @tender.inclusions_exclusions.update(inclusions_params)
     end
     
     # Update on-site breakdown
     if params[:tender_on_site_breakdown].present?
       @tender.on_site_breakdown.update(on_site_params)
     end
     
     # Update tender margin
     if params[:tender].present?
       margin_pct = (params[:tender][:margin_pct].to_f / 100.0)
       @tender.update(margin_pct: margin_pct)
     end
     
     # Trigger recalculation
     TenderCalculator.calculate(@tender)
     
     redirect_to tender_configuration_path(@tender), 
       notice: 'Configuration updated successfully'
   rescue => e
     redirect_to tender_configuration_path(@tender), 
       alert: "Error: #{e.message}"
   end
   
   private
   
   def inclusions_params
     params.require(:tender_inclusions_exclusions).permit(
       :include_fabrication, :include_overheads, :include_shop_priming,
       :include_onsite_painting, :include_delivery, :include_bolts,
       :include_erection, :include_crainage, :include_cherry_picker,
       :include_galvanizing
     )
   end
   
   def on_site_params
     params.require(:tender_on_site_breakdown).permit(
       :total_roof_area_sqm, :erection_rate_sqm_per_day,
       :splicing_crane_required, :splicing_crane_size, :splicing_crane_days,
       :misc_crane_required, :misc_crane_size, :misc_crane_days
     )
   end
   ```

### Show/Hide Dependent Fields
**File:** `app/javascript/controllers/configuration_controller.js`

**Tasks:**
1. Create Stimulus controller:
   ```javascript
   import { Controller } from "@hotwired/stimulus"
   
   export default class extends Controller {
     static targets = ["splicingCrane", "miscCrane", "splicingToggle", "miscToggle"]
     
     connect() {
       this.toggleSplicingFields()
       this.toggleMiscFields()
     }
     
     toggleSplicingFields() {
       if (this.splicingToggleTarget.checked) {
         this.splicingCraneTarget.classList.remove('hidden')
       } else {
         this.splicingCraneTarget.classList.add('hidden')
       }
     }
     
     toggleMiscFields() {
       if (this.miscToggleTarget.checked) {
         this.miscCraneTarget.classList.remove('hidden')
       } else {
         this.miscCraneTarget.classList.add('hidden')
       }
     }
   }
   ```

---

## Scope: Equipment Selection Interface

### Equipment Catalog View
**File:** `app/views/tenders/equipment_selection.html.erb`

**Tasks:**
1. Create modal or slide-out panel:
   ```erb
   <div class="modal" id="equipment-modal">
     <div class="modal-box w-11/12 max-w-4xl">
       <h3 class="font-bold text-lg mb-4">Select Equipment</h3>
       
       <!-- Equipment Catalog Table -->
       <div class="overflow-x-auto mb-6">
         <table class="table table-compact">
           <thead>
             <tr>
               <th>Category</th>
               <th>Model</th>
               <th>Height (m)</th>
               <th>Monthly Rate</th>
               <th>Units</th>
               <th>Months</th>
               <th>Purpose</th>
               <th></th>
             </tr>
           </thead>
           <tbody>
             <% @equipment_types.each do |equipment| %>
               <tr>
                 <td><%= equipment.category.humanize %></td>
                 <td><%= equipment.model %></td>
                 <td><%= equipment.working_height_m %></td>
                 <td><%= number_to_currency equipment.monthly_cost %></td>
                 <td>
                   <input type="number" 
                          min="1"
                          value="1"
                          id="units_<%= equipment.id %>"
                          class="input input-sm input-bordered w-16">
                 </td>
                 <td>
                   <input type="number" 
                          min="1"
                          value="1"
                          id="months_<%= equipment.id %>"
                          class="input input-sm input-bordered w-16">
                 </td>
                 <td>
                   <input type="text" 
                          placeholder="Purpose"
                          id="purpose_<%= equipment.id %>"
                          class="input input-sm input-bordered">
                 </td>
                 <td>
                   <button type="button"
                           class="btn btn-sm btn-primary"
                           onclick="addEquipment(<%= equipment.id %>, '<%= equipment.model %>')">
                     Add
                   </button>
                 </td>
               </tr>
             <% end %>
           </tbody>
         </table>
       </div>
       
       <!-- Selected Equipment List -->
       <h4 class="font-semibold mb-3">Selected Equipment</h4>
       <div id="selected-equipment-list" class="overflow-x-auto mb-6">
         <table class="table table-compact">
           <thead>
             <tr>
               <th>Model</th>
               <th>Units</th>
               <th>Months</th>
               <th>Monthly Cost</th>
               <th>Total Cost</th>
               <th></th>
             </tr>
           </thead>
           <tbody>
             <% @selections.each do |selection| %>
               <tr data-equipment-id="<%= selection.id %>">
                 <td><%= selection.equipment_type.model %></td>
                 <td><%= selection.units_required %></td>
                 <td><%= selection.period_months %></td>
                 <td><%= number_to_currency selection.equipment_type.monthly_cost %></td>
                 <td><%= number_to_currency selection.total_cost %></td>
                 <td>
                   <button type="button" 
                           class="btn btn-sm btn-error"
                           onclick="removeEquipment(<%= selection.id %>)">
                     Remove
                   </button>
                 </td>
               </tr>
             <% end %>
           </tbody>
         </table>
       </div>
       
       <!-- Total Equipment Cost -->
       <div class="alert mb-6">
         <div class="font-semibold">
           Total Equipment Allowance: 
           <span class="text-lg"><%= number_to_currency @selections.sum(&:total_cost) %></span>
         </div>
       </div>
       
       <!-- Actions -->
       <div class="modal-action">
         <button type="button" class="btn btn-ghost" onclick="document.getElementById('equipment-modal').close()">
           Close
         </button>
         <form method="post" action="<%= tender_path(@tender) %>">
           <button type="submit" class="btn btn-primary">Save Equipment</button>
         </form>
       </div>
     </div>
   </div>
   ```

### Equipment Selection JavaScript
**File:** `app/javascript/controllers/equipment_selection_controller.js`

**Tasks:**
1. Create Stimulus controller:
   ```javascript
   import { Controller } from "@hotwired/stimulus"
   
   export default class extends Controller {
     addEquipment(equipmentId, model) {
       const units = document.getElementById(`units_${equipmentId}`).value
       const months = document.getElementById(`months_${equipmentId}`).value
       const purpose = document.getElementById(`purpose_${equipmentId}`).value
       
       // Send AJAX request to add equipment
       fetch(`<%= tender_equipment_selections_path(@tender) %>`, {
         method: 'POST',
         headers: {
           'Content-Type': 'application/json',
           'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
         },
         body: JSON.stringify({
           equipment_type_id: equipmentId,
           units_required: units,
           period_months: months,
           purpose: purpose
         })
       })
       .then(response => response.json())
       .then(data => {
         if (data.success) {
           this.refreshSelectedList()
           this.resetInputs(equipmentId)
         }
       })
     }
     
     removeEquipment(selectionId) {
       fetch(`<%= tender_equipment_selection_path(@tender, '') %>${selectionId}`, {
         method: 'DELETE',
         headers: {
           'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
         }
       })
       .then(() => this.refreshSelectedList())
     }
     
     refreshSelectedList() {
       // Reload equipment selection list via Turbo
       location.reload()
     }
     
     resetInputs(equipmentId) {
       document.getElementById(`units_${equipmentId}`).value = 1
       document.getElementById(`months_${equipmentId}`).value = 1
       document.getElementById(`purpose_${equipmentId}`).value = ''
     }
   }
   ```

### Equipment Selection Routes
**File:** `config/routes.rb`

**Tasks:**
1. Add routes:
   ```ruby
   resources :tenders do
     resources :equipment_selections, path: 'equipment' do
       get 'modal', on: :collection
     end
   end
   ```

### Equipment Selections Controller
**File:** `app/controllers/equipment_selections_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller EquipmentSelections`
2. Implement create action:
   ```ruby
   def create
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :update?
     
     @selection = @tender.equipment_selections.build(equipment_params)
     
     if @selection.save
       @selection.calculate_cost!
       
       if request.format.json?
         render json: { success: true, selection: @selection }
       else
         redirect_to tender_equipment_modal_path(@tender), notice: 'Equipment added'
       end
     else
       render json: { success: false, errors: @selection.errors }, status: :unprocessable_entity
     end
   end
   
   def destroy
     @selection = TenderEquipmentSelection.find(params[:id])
     @tender = @selection.tender
     authorize @tender, :update?
     
     @selection.destroy
     
     if request.format.json?
       render json: { success: true }
     else
       redirect_to tender_equipment_modal_path(@tender), notice: 'Equipment removed'
     end
   end
   
   private
   
   def equipment_params
     params.require(:equipment_selection).permit(
       :equipment_type_id, :units_required, :period_months, :purpose
     )
   end
   ```

---

## Scope: Crane Selection Interface

### Crane Complement Lookup
**Create:** Service to suggest crane complement

**File:** `app/services/crane_complement_suggester.rb`

**Tasks:**
1. Create service:
   ```ruby
   class CraneComplementSuggester
     def self.suggest(erection_rate)
       new(erection_rate).suggest
     end
     
     def initialize(erection_rate)
       @erection_rate = erection_rate
     end
     
     def suggest
       CraneComplement.where(
         'area_min_sqm <= ? AND area_max_sqm >= ?',
         @erection_rate,
         @erection_rate
       ).first
     end
   end
   ```

### Crane Selection View
**File:** `app/views/tenders/crane_selection.html.erb`

**Tasks:**
1. Create view with:
   ```erb
   <div class="card mb-6">
     <div class="card-body">
       <h2 class="card-title">Crane Selection</h2>
       <div class="divider"></div>
       
       <!-- Suggested Crane Complement -->
       <div class="alert alert-info mb-6">
         <div>
           <strong>Suggested Crane Complement:</strong>
           <% if @suggested_complement %>
             <%= @suggested_complement.complement_description %>
             (R<%= number_with_delimiter @suggested_complement.default_wet_rate_per_day %>/day)
           <% else %>
             Enter roof area and erection rate above to see suggestion
           <% end %>
         </div>
       </div>
       
       <!-- Manual Crane Entry -->
       <h3 class="font-semibold mb-3">Add Crane</h3>
       <div class="grid grid-cols-5 gap-3 mb-6">
         <select id="crane-size" class="select select-bordered">
           <option value="">Size</option>
           <% %w[10t 20t 25t 30t 35t 50t 90t].each do |size| %>
             <option value="<%= size %>"><%= size %></option>
           <% end %>
         </select>
         
         <select id="crane-type" class="select select-bordered">
           <option value="rental">Rental</option>
           <option value="owned">RSB-Owned</option>
         </select>
         
         <input type="number" 
                id="crane-quantity"
                min="1"
                value="1"
                placeholder="Qty"
                class="input input-bordered">
         
         <input type="number" 
                id="crane-days"
                min="1"
                value="1"
                placeholder="Days"
                class="input input-bordered">
         
         <select id="crane-purpose" class="select select-bordered">
           <option value="main">Main</option>
           <option value="splicing">Splicing</option>
           <option value="miscellaneous">Misc</option>
         </select>
         
         <button type="button" 
                 class="btn btn-sm btn-primary"
                 onclick="addCrane()">
           Add
         </button>
       </div>
       
       <!-- Selected Cranes Table -->
       <h3 class="font-semibold mb-3">Selected Cranes</h3>
       <div id="selected-cranes-list" class="overflow-x-auto mb-6">
         <table class="table table-compact">
           <thead>
             <tr>
               <th>Size</th>
               <th>Type</th>
               <th>Qty</th>
               <th>Days</th>
               <th>Daily Rate</th>
               <th>Total Cost</th>
               <th></th>
             </tr>
           </thead>
           <tbody>
             <% @crane_selections.each do |selection| %>
               <tr>
                 <td><%= selection.crane_rate.size %></td>
                 <td><%= selection.crane_rate.ownership_type %></td>
                 <td><%= selection.quantity %></td>
                 <td><%= selection.duration_days %></td>
                 <td><%= number_to_currency selection.crane_rate.daily_rate %></td>
                 <td><%= number_to_currency selection.total_cost %></td>
                 <td>
                   <button type="button"
                           class="btn btn-sm btn-error"
                           onclick="removeCrane(<%= selection.id %>)">
                     Remove
                   </button>
                 </td>
               </tr>
             <% end %>
           </tbody>
         </table>
       </div>
       
       <!-- Total Crane Cost -->
       <div class="alert mb-6">
         <div class="font-semibold">
           Total Crane Cost: 
           <span class="text-lg"><%= number_to_currency @crane_selections.sum(&:total_cost) %></span>
         </div>
       </div>
     </div>
   </div>
   ```

### Crane Selections Controller
**File:** `app/controllers/crane_selections_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller CraneSelections`
2. Implement create action (similar to equipment):
   ```ruby
   def create
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :update?
     
     crane_rate = CraneRate.find_by(
       size: params[:crane_size],
       ownership_type: params[:crane_type]
     )
     
     @selection = @tender.crane_selections.build(
       crane_rate_id: crane_rate.id,
       quantity: params[:quantity],
       duration_days: params[:duration_days],
       purpose: params[:purpose]
     )
     
     if @selection.save
       @selection.calculate_cost!
       render json: { success: true }
     else
       render json: { success: false, errors: @selection.errors }, status: :unprocessable_entity
     end
   end
   ```

### Crane JavaScript Handler
**File:** `app/javascript/controllers/crane_selection_controller.js`

**Tasks:**
1. Create similar to equipment selection controller with:
   - addCrane() method
   - removeCrane() method
   - refreshSelectedList() method

---

## Route Summary

**Add to `config/routes.rb`:**
```ruby
resources :tenders do
  get 'configuration', to: 'tender_configurations#show', as: 'configuration'
  patch 'configuration', to: 'tender_configurations#update'
  
  resources :equipment_selections, path: 'equipment'
  resources :crane_selections, path: 'cranes'
end
```

---

## Acceptance Criteria

- [ ] Tender configuration view displays all inclusions/exclusions
- [ ] All toggles work and update database on save
- [ ] On-site parameters captured correctly
- [ ] Splicing/misc crane fields show/hide based on checkboxes
- [ ] Margin field works and value stored
- [ ] Equipment catalog displays all available equipment
- [ ] Can add equipment to selection with units, months, purpose
- [ ] Equipment costs calculated correctly
- [ ] Can remove equipment from selection
- [ ] Crane complement lookup works (returns suggestion)
- [ ] Can add cranes with size, type, quantity, days, purpose
- [ ] Crane costs calculated correctly
- [ ] Can remove cranes from selection
- [ ] Total equipment cost displayed
- [ ] Total crane cost displayed
- [ ] All calculations trigger recalculation when updated
- [ ] Permissions enforced: only QS/Admin can configure

---

**Week 2a Status:** Ready for Development  
**Last Updated:** Current Date
