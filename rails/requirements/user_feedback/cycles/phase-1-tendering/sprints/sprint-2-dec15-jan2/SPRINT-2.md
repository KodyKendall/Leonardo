# Sprint 2: Rate & Calculation Engine (Dec 15 - Jan 2)

**Duration:** 3 weeks  
**Focus:** Rate management, calculations, tender configuration, output generation  
**Goal:** End-to-end tender can be configured, calculated, and output as PDF

---

## Sprint Overview

Sprint 2 completes the RSB Tendering System MVP by implementing the rate management system, complex calculation engine, tender configuration interface, and PDF output generation. Users can now configure tenders with inclusions/exclusions, select equipment and cranes, apply margins, and generate client-facing tender documents.

**Key Outcome:** A tender with BOQ can be fully configured with rates, margins, and equipment selections, calculated automatically, and output as a professional PDF for client submission.

---

## Week Breakdown

- **Week 2a (Dec 15-19):** Rate models, inclusions/exclusions UI, equipment & crane selection  
- **Week 2b (Dec 22-26):** Calculation engine, rate build-ups, rounding logic  
- **Week 2c (Dec 29 - Jan 2):** P&G configuration, tender output page, PDF generation

---

## Detailed Tasks by Scope

### Week 2a: Rate Management & Tender Configuration UI

#### Rate Models & Associations
**Scope:** Link rate master data to tender line items

**Tasks:**
1. Add associations to TenderLineItem:
   ```ruby
   has_many :material_supplies, through: :materials
   has_one :rate_build_up, dependent: :destroy
   has_many :extra_overs, dependent: :destroy
   ```
2. Add method to get current rates for line item:
   ```ruby
   def current_material_rate
     materials.sum do |material|
       rate = material.material_supply.current_rate(material.proportion)
       rate * material.proportion
     end
   end
   ```
3. Create scope on MaterialSupply to get current rate:
   ```ruby
   scope :current_rate, -> {
     where('effective_from <= ?', Date.today)
       .order(effective_from: :desc)
       .limit(1)
   }
   ```

#### Inclusions/Exclusions Configuration View
**File:** `app/views/tenders/configuration.html.erb`

**Tasks:**
1. Create view with sections:
   - **Tender-Level Toggles** (apply to all line items unless overridden):
     - Fabrication (checkbox)
     - Overheads (checkbox)
     - Shop Priming (checkbox)
     - On-Site Painting (checkbox)
     - Delivery (checkbox)
     - Bolts (checkbox)
     - Erection (checkbox)
     - Crainage in Rates (checkbox, mutual with P&G)
     - Cherry Picker in Rates (checkbox, mutual with P&G)
     - Galvanizing (checkbox)
   - **On-Site Parameters** section:
     - Total Roof Area (m²) - number input
     - Area Erected Per Day (m/day) - number input
     - Splicing Crane Required (yes/no radio)
     - Splicing Crane Size (select: 10t, 20t, 25t, etc.)
     - Splicing Crane Duration (days) - number input
     - Misc Crane Required (yes/no radio)
     - Misc Crane Size (select)
     - Misc Crane Duration (days) - number input
   - **Margin** section:
     - Tender-Level Margin % (0-100) - number input
   - "Save Configuration" button

2. Style with Tailwind/Daisy UI
3. Use Stimulus controllers for:
   - Toggle mutual exclusion (if crainage in rates checked, uncheck P&G)
   - Show/hide dependent fields (if splicing crane required = no, hide crane size/days)

#### Inclusions/Exclusions Controller
**File:** `app/controllers/tender_inclusions_exclusions_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller TenderInclusionsExclusions`
2. Add actions: edit, update
3. Implement edit:
   ```ruby
   def edit
     @tender = Tender.find(params[:tender_id])
     @inclusions = @tender.inclusions_exclusions || @tender.create_inclusions_exclusions!
     authorize @tender, :update?
   end
   ```
4. Implement update:
   ```ruby
   def update
     @tender = Tender.find(params[:tender_id])
     @inclusions = @tender.inclusions_exclusions
     authorize @tender, :update?
     
     if @inclusions.update(inclusions_params)
       @tender.update(on_site_breakdown_attributes: on_site_params) if on_site_params.present?
       redirect_to tender_configuration_path(@tender), notice: 'Configuration updated'
     else
       render :edit
     end
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

#### Equipment Selection Interface
**File:** `app/views/tenders/equipment_selection.html.erb`

**Tasks:**
1. Create modal/slide-out panel for equipment selection with:
   - Equipment catalog table:
     - Category
     - Model
     - Working Height (m)
     - Base Rate (monthly)
     - Damage Waiver (6%)
     - Diesel Allowance
   - For each equipment, input fields:
     - Number of Units (spinner)
     - Period (months) (spinner)
     - Purpose (text input)
     - Add button
   - Selected equipment list showing:
     - Model, Units, Months, Purpose
     - Monthly Cost (calculated)
     - Total Cost (calculated)
     - Delete button per item
   - "Save Equipment Selections" button

2. Style with Daisy UI modal/offcanvas
3. Show calculated total equipment allowance at bottom

#### Tender Equipment Selections Controller
**File:** `app/controllers/tender_equipment_selections_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller TenderEquipmentSelections`
2. Add actions: new, create, destroy
3. Implement new (return modal via turbo):
   ```ruby
   def new
     @tender = Tender.find(params[:tender_id])
     @equipment_types = EquipmentType.active
     @selections = @tender.equipment_selections
   end
   ```
4. Implement create:
   ```ruby
   def create
     @tender = Tender.find(params[:tender_id])
     @selection = @tender.equipment_selections.build(equipment_params)
     
     if @selection.save
       @selection.calculate_cost!
       redirect_to tender_path(@tender), notice: 'Equipment added'
     else
       render :new
     end
   end
   ```
5. Implement destroy:
   ```ruby
   def destroy
     @selection = TenderEquipmentSelection.find(params[:id])
     @tender = @selection.tender
     @selection.destroy
     redirect_to tender_path(@tender), notice: 'Equipment removed'
   end
   ```

#### Equipment Selection Model Enhancement
**File:** `app/models/tender_equipment_selection.rb`

**Tasks:**
1. Add method to calculate monthly cost:
   ```ruby
   def calculate_cost!
     equipment = equipment_type
     monthly_cost = equipment.base_rate_monthly * (1 + equipment.damage_waiver_pct) + equipment.diesel_allowance_monthly
     self.monthly_cost_override ||= monthly_cost
     self.total_cost = monthly_cost * units_required * period_months
     save!
   end
   ```
2. Add validations:
   ```ruby
   validates :units_required, numericality: { greater_than: 0 }
   validates :period_months, numericality: { greater_than: 0 }
   ```

#### Crane Selection Interface
**File:** `app/views/tenders/crane_selection.html.erb`

**Tasks:**
1. Create interface to display:
   - Suggested crane complement based on erection area (lookup from crane_complements table)
   - Manual override options:
     - Crane size selector (10t, 20t, 25t, etc.)
     - Ownership type selector (RSB-owned, Rental)
     - Quantity (number input)
     - Duration (days) - number input
     - Purpose selector (main, splicing, miscellaneous)
     - "Add Crane" button
   - Selected cranes list:
     - Size, Type, Quantity, Days, Purpose
     - Daily Cost (calculated)
     - Total Cost (calculated)
     - Delete button
   - Total crane cost summary

2. Add JavaScript to:
   - Lookup crane complement when roof area/erection rate filled
   - Pre-populate with suggested complement
   - Allow manual override
   - Calculate costs in real-time

#### Crane Selection Model
**File:** `app/models/tender_crane_selection.rb`

**Tasks:**
1. Generate model if not exists
2. Add method to calculate cost:
   ```ruby
   def calculate_cost!
     crane = crane_rate
     daily_rate = crane.dry_rate_per_day + crane.diesel_per_day
     self.total_cost = daily_rate * duration_days * quantity
     save!
   end
   ```
3. Add validations:
   ```ruby
   validates :quantity, numericality: { greater_than: 0 }
   validates :duration_days, numericality: { greater_than: 0 }
   ```

---

### Week 2b: Calculation Engine & Rate Build-ups

#### Line Item Rate Build-up Calculator
**Create:** Service to calculate all rates for a line item

**File:** `app/services/line_item_calculator.rb`

**Tasks:**
1. Create service class:
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
       
       # Calculate each component rate
       build_up.material_supply_rate = calculate_material_rate
       build_up.fabrication_rate = fetch_rate('FABRICATION')
       build_up.fabrication_factor = calculate_fabrication_factor
       build_up.fabrication_included = @inclusions.include_fabrication
       
       build_up.overheads_rate = fetch_rate('OVERHEADS')
       build_up.overheads_included = @inclusions.include_overheads
       
       # Continue for all other components...
       build_up.shop_priming_rate = fetch_rate('SHOP_PRIMING')
       build_up.shop_priming_included = @inclusions.include_shop_priming
       
       # ... (all other rates)
       
       # Calculate totals
       build_up.subtotal = calculate_subtotal(build_up)
       build_up.margin_amount = build_up.subtotal * @tender.margin_pct
       build_up.total_before_rounding = build_up.subtotal + build_up.margin_amount
       build_up.rounded_rate = round_rate(build_up.total_before_rounding)
       
       build_up.save!
       @line_item.update(
         rate_per_unit: build_up.rounded_rate,
         line_amount: build_up.rounded_rate * @line_item.quantity,
         margin_amount: build_up.margin_amount
       )
       
       build_up
     end
     
     private
     
     def calculate_material_rate
       # Blended material rate calculation
       total = 0
       @line_item.materials.each do |material|
         base_rate = material.material_supply.current_rate
         with_waste = base_rate * (1 + material.material_supply.waste_percentage)
         total += with_waste * material.proportion
       end
       total
     end
     
     def calculate_fabrication_factor
       case @line_item.category
       when 'Platework'
         1.75
       when 'Piping'
         3.0
       else # Structural, default
         1.0
       end
     end
     
     def fetch_rate(code)
       ProcessingRate.find_by(code: code, effective_from: <= Date.today)&.base_rate_per_tonne || 0
     end
     
     def calculate_subtotal(build_up)
       subtotal = build_up.material_supply_rate
       subtotal += build_up.fabrication_rate * build_up.fabrication_factor if build_up.fabrication_included
       subtotal += build_up.overheads_rate if build_up.overheads_included
       # ... add all other included rates
       subtotal
     end
     
     def round_rate(rate)
       # Determine rounding interval based on rate type
       (rate.ceil / 50.0).ceil * 50
     end
   end
   ```

#### Equipment Rate Calculation
**Create:** Service to calculate equipment costs per tonne

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
       total_equipment_cost = @tender.equipment_selections.sum(&:total_cost)
       total_tonnage = @tender.total_tonnage
       
       return 0 if total_tonnage.zero?
       
       equipment_rate_per_tonne = total_equipment_cost / total_tonnage
       round_rate(equipment_rate_per_tonne, 10) # Round to nearest R10
     end
     
     private
     
     def round_rate(rate, interval)
       (rate.ceil / interval.to_f).ceil * interval
     end
   end
   ```

#### Crane Rate Calculation
**Create:** Service to calculate crainage costs

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
       # Step 1: Lookup default crane complement
       complement = CraneComplement.where(
         'area_min_sqm <= ? AND area_max_sqm >= ?',
         @on_site.erection_rate_sqm_per_day,
         @on_site.erection_rate_sqm_per_day
       ).first
       
       # Step 2: Calculate program duration
       program_duration = (@on_site.total_roof_area_sqm / @on_site.erection_rate_sqm_per_day).ceil
       
       # Step 3: Calculate main crane cost
       main_crane_cost = complement.default_wet_rate_per_day * program_duration
       
       # Step 4: Add splicing crane if required
       splicing_cost = 0
       if @on_site.splicing_crane_required
         splicing_rate = CraneRate.find_by(
           size: @on_site.splicing_crane_size,
           ownership_type: 'rental'
         )
         splicing_cost = (splicing_rate.dry_rate_per_day + splicing_rate.diesel_per_day) * @on_site.splicing_crane_days
       end
       
       # Step 5: Add misc crane if required
       misc_cost = 0
       if @on_site.misc_crane_required
         misc_rate = CraneRate.find_by(
           size: @on_site.misc_crane_size,
           ownership_type: 'rental'
         )
         misc_cost = (misc_rate.dry_rate_per_day + misc_rate.diesel_per_day) * @on_site.misc_crane_days
       end
       
       # Step 6: Total crane cost
       total_crane_cost = main_crane_cost + splicing_cost + misc_cost
       
       # Step 7: Rate per tonne
       total_tonnage = @tender.total_tonnage
       return 0 if total_tonnage.zero?
       
       crainage_rate = total_crane_cost / total_tonnage
       round_rate(crainage_rate, 20) # Round to nearest R20
     end
     
     private
     
     def round_rate(rate, interval)
       (rate.ceil / interval.to_f).ceil * interval
     end
   end
   ```

#### Tender Calculation Orchestrator
**Create:** Service to orchestrate all calculations

**File:** `app/services/tender_calculator.rb`

**Tasks:**
1. Create service:
   ```ruby
   class TenderCalculator
     def self.calculate(tender)
       new(tender).calculate
     end
     
     def initialize(tender)
       @tender = tender
     end
     
     def calculate
       # Recalculate all line item rates
       @tender.line_items.each do |line_item|
         LineItemCalculator.calculate(line_item)
       end
       
       # Update tender totals
       @tender.total_tonnage = @tender.line_items.sum(:quantity)
       @tender.subtotal_amount = @tender.line_items.sum(:line_amount)
       
       # Add P&G once implemented
       @tender.grand_total = @tender.subtotal_amount
       
       @tender.save!
     end
   end
   ```

#### Rounding Logic Implementation
**Tasks:**
1. Create RoundingService:
   ```ruby
   class RoundingService
     ROUNDING_RULES = {
       standard: 50,      # Most line items
       crainage: 20,      # Crainage rate
       cherry_picker: 10, # Cherry picker rate
       pg: 50             # P&G rate
     }.freeze
     
     def self.round(amount, rule_type = :standard)
       interval = ROUNDING_RULES[rule_type]
       (amount.ceil / interval.to_f).ceil * interval
     end
   end
   ```

#### Calculation Trigger Points
**Tasks:**
1. Add to TenderInclusionsExclusions model after_update:
   ```ruby
   after_update :trigger_recalculation
   
   def trigger_recalculation
     TenderCalculator.calculate(tender)
   end
   ```
2. Add to TenderOnSiteBreakdown model after_update similar trigger
3. Add to Tender model after margin_pct updated:
   ```ruby
   before_save :trigger_recalculation, if: :margin_pct_changed?
   ```

#### Calculation View & Display
**File:** `app/views/tender_line_items/_rate_detail.html.erb`

**Tasks:**
1. Create partial to display rate build-up for expandable row:
   ```erb
   <tr class="detail-row hidden">
     <td colspan="7">
       <div class="rate-build-up">
         <table>
           <tr>
             <td>Material Supply</td>
             <td><%= number_to_currency @line_item.rate_build_up.material_supply_rate %></td>
           </tr>
           <tr>
             <td>Fabrication (×<%= @line_item.rate_build_up.fabrication_factor %>)</td>
             <td><%= @line_item.rate_build_up.fabrication_included ? number_to_currency(@line_item.rate_build_up.fabrication_rate * @line_item.rate_build_up.fabrication_factor) : '-' %></td>
           </tr>
           <!-- ... all other components ... -->
           <tr class="total-row">
             <td>Total (before rounding)</td>
             <td><%= number_to_currency @line_item.rate_build_up.total_before_rounding %></td>
           </tr>
           <tr class="rounded-row">
             <td>Rounded Rate</td>
             <td><strong><%= number_to_currency @line_item.rate_build_up.rounded_rate %></strong></td>
           </tr>
         </table>
       </div>
     </td>
   </tr>
   ```

---

### Week 2c: P&G Configuration & Tender Output

#### P&G (Preliminaries & General) Model
**Create:** Model for preliminary items

**File:** `app/models/tender_preliminary_item.rb`

**Tasks:**
1. Generate model: `rails generate model TenderPreliminaryItem tender_id:bigint item_code:string description:string calculation_notes:text lump_sum_amount:decimal rate_per_tonne:decimal is_included:boolean sort_order:integer`
2. Run migration
3. Add associations:
   ```ruby
   belongs_to :tender
   ```
4. Add to Tender:
   ```ruby
   has_many :preliminary_items, dependent: :destroy
   ```

#### P&G Configuration View
**File:** `app/views/tenders/preliminary_items.html.erb`

**Tasks:**
1. Create view with:
   - Page title: "P&G Items"
   - Standard items (auto-created):
     - Safety File & Audits (R30,000 lump sum)
     - Crainage (if not in line items) - checkbox to include
     - Cherry Picker (if not in line items) - checkbox to include
   - Custom items section:
     - Add button to add new row
     - Table with columns:
       - Description
       - Calculation Notes
       - Lump Sum Amount
       - Rate per Tonne (calculated)
       - Include? (checkbox)
       - Delete button
   - "Save P&G Items" button

2. Add JavaScript to:
   - Calculate rate per tonne: lump_sum / total_tonnage
   - Show/hide crainage and cherry picker based on inclusions
   - Add/remove rows dynamically

#### P&G Controller
**File:** `app/controllers/tender_preliminary_items_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller TenderPreliminaryItems`
2. Add actions: index, create, update, destroy
3. Implement index:
   ```ruby
   def index
     @tender = Tender.find(params[:tender_id])
     @pg_items = @tender.preliminary_items.order(:sort_order)
     @standard_items = build_standard_items
   end
   ```
4. Implement create:
   ```ruby
   def create
     @tender = Tender.find(params[:tender_id])
     @item = @tender.preliminary_items.build(pg_params)
     
     if @item.save
       redirect_to tender_preliminary_items_path(@tender), notice: 'P&G item added'
     else
       render :index
     end
   end
   ```

#### Standard Items Auto-Creation
**Tasks:**
1. Add after_create callback to Tender:
   ```ruby
   after_create :create_standard_pg_items
   
   private
   
   def create_standard_pg_items
     preliminary_items.create!(
       item_code: 'SAFETY_FILE',
       description: 'Safety File & Audits',
       lump_sum_amount: 30000,
       is_included: true,
       sort_order: 1
     )
   end
   ```

#### P&G Calculation Service
**Create:** Service to calculate P&G rates

**File:** `app/services/pg_calculator.rb`

**Tasks:**
1. Create service:
   ```ruby
   class PgCalculator
     def self.calculate(tender)
       new(tender).calculate
     end
     
     def initialize(tender)
       @tender = tender
     end
     
     def calculate
       total_tonnage = @tender.total_tonnage
       return if total_tonnage.zero?
       
       @tender.preliminary_items.each do |item|
         rate_per_tonne = item.lump_sum_amount / total_tonnage
         item.update(rate_per_tonne: RoundingService.round(rate_per_tonne, :pg))
       end
     end
   end
   ```

#### Tender Output Page
**File:** `app/views/tenders/output.html.erb`

**Tasks:**
1. Create comprehensive output view showing:
   - **Tender Header:**
     - Tender Number
     - Project Name
     - Client Name
     - Tender Date
     - Validity Period
   - **Line Items by Section:**
     - Section header (e.g., "STEEL COLUMNS AND BEAMS")
     - Table with columns: Page, Item, Description, Unit, Qty, Rate, Amount
     - Section Subtotal
   - **P&G Section:**
     - P&G items with amounts
     - P&G Total
   - **Summary:**
     - Shop Drawings Total
     - Steel Work Total
     - P&G Total
     - Subtotal
     - Margin (if applicable)
     - Grand Total
   - **Actions:**
     - "Generate PDF" button
     - "Submit Tender" button
     - Back button

2. Style professionally with:
   - Clear typography
   - Proper spacing
   - Professional layout

#### Tender Output Controller
**Tasks:**
1. Add action to TendersController:
   ```ruby
   def output
     @tender = Tender.find(params[:id])
     authorize @tender, :show?
     @line_items = @tender.line_items.by_sort_order
     @pg_items = @tender.preliminary_items.where(is_included: true)
   end
   ```
2. Add route: `get 'tenders/:id/output', to: 'tenders#output', as: 'tender_output'`

#### PDF Generation
**Create:** Service to generate tender PDF

**File:** `app/services/tender_pdf_generator.rb`

**Tasks:**
1. Add gem to Gemfile: `gem 'prawn'` (PDF generation)
2. Create service:
   ```ruby
   class TenderPdfGenerator
     def self.generate(tender)
       new(tender).generate
     end
     
     def initialize(tender)
       @tender = tender
     end
     
     def generate
       Prawn::Document.new do |pdf|
         # Add header
         add_header(pdf)
         
         # Add tender info
         add_tender_info(pdf)
         
         # Add line items by section
         add_line_items(pdf)
         
         # Add P&G
         add_pg(pdf)
         
         # Add summary
         add_summary(pdf)
         
         # Add footer
         add_footer(pdf)
       end.render
     end
     
     private
     
     def add_header(pdf)
       pdf.font_size 20
       pdf.text 'RSB CONTRACTS', align: :center, style: :bold
       pdf.move_down 5
       pdf.font_size 10
       pdf.text '40 Years of Excellence in Structural Steel', align: :center
       pdf.move_down 15
     end
     
     def add_tender_info(pdf)
       pdf.text "Tender Number: #{@tender.tender_number}"
       pdf.text "Project: #{@tender.project_name}"
       pdf.text "Client: #{@tender.client.name}"
       pdf.text "Date: #{@tender.tender_date.strftime('%d %B %Y')}"
       pdf.text "Valid until: #{@tender.expiry_date.strftime('%d %B %Y')}"
       pdf.move_down 10
     end
     
     def add_line_items(pdf)
       # Table with line items grouped by section
       # [Implementation continues...]
     end
     
     def add_pg(pdf)
       # P&G items table
       # [Implementation continues...]
     end
     
     def add_summary(pdf)
       # Summary table with totals
       # [Implementation continues...]
     end
     
     def add_footer(pdf)
       pdf.move_down 20
       pdf.font_size 8
       pdf.text 'RSB Contracts | Contact: info@rsb.co.za | Phone: +27 (0)11 555 1234', 
         align: :center, 
         color: '999999'
     end
   end
   ```

#### PDF Download Action
**Tasks:**
1. Add to TendersController:
   ```ruby
   def download_pdf
     @tender = Tender.find(params[:id])
     authorize @tender, :show?
     
     pdf_content = TenderPdfGenerator.generate(@tender)
     filename = "Tender_#{@tender.tender_number}_#{Date.today}.pdf"
     
     send_data pdf_content, 
       filename: filename, 
       type: 'application/pdf', 
       disposition: 'attachment'
   end
   ```
2. Add route: `get 'tenders/:id/pdf', to: 'tenders#download_pdf', as: 'tender_pdf'`

#### Submit Tender Workflow
**Tasks:**
1. Add to TendersController:
   ```ruby
   def submit
     @tender = Tender.find(params[:id])
     authorize @tender, :submit?
     
     if @tender.update(status: 'submitted')
       # Create snapshot of all rates/calculations for audit
       TenderSnapshot.create!(tender: @tender)
       redirect_to @tender, notice: 'Tender submitted!'
     else
       redirect_to @tender, alert: 'Failed to submit tender'
     end
   end
   ```

---

## Integration & Testing Points

### Calculation Integration Testing
**Tasks:**
1. Create sample tender with known rates
2. Verify calculations match Excel templates
3. Test with multiple line items and different categories
4. Verify margin application
5. Verify rounding rules applied correctly

### PDF Output Verification
**Tasks:**
1. Generate PDF for sample tender
2. Verify all line items appear
3. Verify calculations match tender output page
4. Verify formatting and layout
5. Test with different page breaks for long tenders

### End-to-End Workflow Testing
**Tasks:**
1. Test complete flow:
   - Create tender → Upload BOQ → Configure → Calculate → Output → PDF → Submit
2. Test permissions at each step
3. Test error scenarios (missing data, invalid inputs, etc.)

---

## Acceptance Criteria

- [ ] Rate models properly linked to tender line items
- [ ] Inclusions/exclusions toggles work correctly
- [ ] On-site parameters captured and stored
- [ ] Equipment selection interface functional
- [ ] Equipment costs calculated correctly
- [ ] Crane selections stored and tracked
- [ ] All line item rates calculated per formula
- [ ] Rounding rules applied correctly (R50, R20, R10)
- [ ] Fabrication multipliers applied (1.0x, 1.75x, 3.0x)
- [ ] Margin calculation applied and visible
- [ ] P&G items auto-created
- [ ] P&G items calculated per tonne correctly
- [ ] Tender output page displays all calculations
- [ ] PDF generated with proper formatting
- [ ] PDF download works correctly
- [ ] Submit tender workflow functional
- [ ] Tender snapshots created on submit
- [ ] End-to-end test passes: create → configure → calculate → output → PDF

---

## Rollover Items (if not completed)

If any tasks not completed by end of Sprint 2:
- [ ] Advanced PDF formatting (multi-page, headers/footers)
- [ ] Email tender to client
- [ ] Tender approval workflow refinement
- [ ] Advanced reporting
- [ ] Export to Excel

---

**Sprint 2 Completion:** Week 2c completes Sprint 2 and the Phase 1 MVP. By end of Sprint 2:
- Complete BOQ → tender workflow functional
- All calculations implemented and tested
- Tender configuration fully flexible
- Professional PDF output generated
- Tenders can be submitted and tracked

**Phase 1 MVP is Complete:**
- Users can upload BOQs
- Parse and finalize line items
- Configure tenders with rates and equipment
- Generate professional client-facing quotes
- Track tender status

**Next Phase:** Phase 2 will add budget tracking, claims, and project lifecycle management.

---

**Sprint 2 Status:** Ready for Development  
**Last Updated:** Current Date
