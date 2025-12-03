# Sprint 2, Week 2c: P&G Configuration & Tender Output (Dec 29 - Jan 2)

**Duration:** 1 week  
**Focus:** P&G configuration, tender output page, PDF generation  
**Deliverable:** End-to-end tenders output as professional PDFs; tenders can be submitted

---

## Week Overview

Week 2c completes Sprint 2 by implementing the final user-facing features: P&G (Preliminaries & General) configuration, comprehensive tender output summary page, and professional PDF generation. By week's end, users can generate client-ready tender documents and submit tenders to RSB's clients.

---

## Scope: P&G (Preliminaries & General) Configuration

### P&G Model Implementation
**File:** `app/models/tender_preliminary_item.rb`

**Tasks:**
1. Generate model: `rails generate model TenderPreliminaryItem tender_id:bigint item_code:string description:string calculation_notes:text lump_sum_amount:decimal rate_per_tonne:decimal is_included:boolean sort_order:integer`
2. Add validations:
   ```ruby
   validates :tender_id, presence: true
   validates :description, presence: true
   validates :lump_sum_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
   validates :is_included, inclusion: { in: [true, false] }
   ```
3. Add associations:
   ```ruby
   belongs_to :tender
   ```
4. Add scopes:
   ```ruby
   scope :included, -> { where(is_included: true) }
   scope :by_sort_order, -> { order(:sort_order) }
   ```
5. Add to Tender model:
   ```ruby
   has_many :preliminary_items, dependent: :destroy
   ```
6. Run migration

### Standard P&G Items Auto-Creation
**File:** `app/models/tender.rb`

**Tasks:**
1. Add callback after create:
   ```ruby
   after_create :create_standard_preliminary_items
   
   private
   
   def create_standard_preliminary_items
     # Standard item: Safety File & Audits (R30,000 lump sum)
     preliminary_items.create!(
       item_code: 'SAFETY_FILE',
       description: 'Safety File & Audits',
       calculation_notes: 'Standard safety compliance allowance',
       lump_sum_amount: 30000,
       is_included: true,
       sort_order: 1
     )
     
     # Crainage (if not in line items)
     if !inclusions_exclusions.include_crainage
       preliminary_items.create!(
         item_code: 'CRAINAGE',
         description: 'Crainage',
         calculation_notes: 'Mobile crane costs for erection',
         lump_sum_amount: 0,  # Will be calculated
         is_included: true,
         sort_order: 2
       )
     end
     
     # Cherry Picker (if not in line items)
     if !inclusions_exclusions.include_cherry_picker
       preliminary_items.create!(
         item_code: 'CHERRY_PICKER',
         description: 'Cherry Picker Access Equipment',
         calculation_notes: 'Access equipment for on-site work',
         lump_sum_amount: 0,  # Will be calculated
         is_included: true,
         sort_order: 3
       )
     end
   end
   ```

### P&G Configuration View
**File:** `app/views/tenders/preliminary_items/index.html.erb`

**Tasks:**
1. Create view with sections:
   ```erb
   <div class="container mx-auto p-6">
     <h1 class="text-3xl font-bold mb-6">Preliminaries & General (P&G)</h1>
     
     <div class="alert alert-info mb-6">
       <div>
         <strong>Total Tonnage:</strong> <%= @tender.total_tonnage || 0 %> tonnes
       </div>
     </div>
     
     <form method="post" action="<%= tender_preliminary_items_path(@tender) %>">
       <div class="card mb-6">
         <div class="card-body">
           <h2 class="card-title">P&G Items</h2>
           <div class="divider"></div>
           
           <div class="overflow-x-auto">
             <table class="table table-compact">
               <thead>
                 <tr>
                   <th>Include?</th>
                   <th>Description</th>
                   <th>Lump Sum (R)</th>
                   <th>Rate/Tonne (R)</th>
                   <th>Total Amount (R)</th>
                   <th>Notes</th>
                   <th></th>
                 </tr>
               </thead>
               <tbody>
                 <% @pg_items.each_with_index do |item, index| %>
                   <tr>
                     <td>
                       <input type="checkbox"
                              name="preliminary_items[<%= index %>][is_included]"
                              <%= 'checked' if item.is_included %>
                              class="checkbox">
                     </td>
                     <td>
                       <input type="text"
                              name="preliminary_items[<%= index %>][description]"
                              value="<%= item.description %>"
                              class="input input-bordered input-sm">
                     </td>
                     <td>
                       <input type="number"
                              step="0.01"
                              name="preliminary_items[<%= index %>][lump_sum_amount]"
                              value="<%= item.lump_sum_amount %>"
                              class="input input-bordered input-sm">
                     </td>
                     <td>
                       <input type="number"
                              step="0.01"
                              name="preliminary_items[<%= index %>][rate_per_tonne]"
                              value="<%= item.rate_per_tonne %>"
                              disabled
                              class="input input-bordered input-sm bg-gray-100">
                     </td>
                     <td>
                       <strong><%= number_to_currency(item.rate_per_tonne * (@tender.total_tonnage || 0)) %></strong>
                     </td>
                     <td>
                       <input type="text"
                              name="preliminary_items[<%= index %>][calculation_notes]"
                              value="<%= item.calculation_notes %>"
                              placeholder="How calculated"
                              class="input input-bordered input-sm">
                     </td>
                     <td>
                       <% if item.item_code.blank? %>
                         <button type="button"
                                 class="btn btn-sm btn-error"
                                 onclick="removePgItem(<%= item.id %>)">
                           Delete
                         </button>
                       <% end %>
                     </td>
                   </tr>
                 <% end %>
               </tbody>
             </table>
           </div>
           
           <!-- Add Custom Item -->
           <div class="mt-6">
             <h3 class="font-semibold mb-3">Add Custom P&G Item</h3>
             <div class="grid grid-cols-4 gap-3">
               <input type="text"
                      id="new_description"
                      placeholder="Description"
                      class="input input-bordered">
               <input type="number"
                      id="new_lump_sum"
                      step="0.01"
                      placeholder="Lump Sum"
                      class="input input-bordered">
               <input type="text"
                      id="new_notes"
                      placeholder="Calculation Notes"
                      class="input input-bordered">
               <button type="button"
                       class="btn btn-primary"
                       onclick="addPgItem()">
                 Add Item
               </button>
             </div>
           </div>
         </div>
       </div>
       
       <!-- Summary -->
       <div class="card mb-6">
         <div class="card-body">
           <h2 class="card-title">P&G Summary</h2>
           <div class="divider"></div>
           
           <div class="grid grid-cols-2 gap-6">
             <div>
               <h4 class="font-semibold mb-2">By Item</h4>
               <% @pg_items.each do |item| %>
                 <% if item.is_included %>
                   <div class="flex justify-between text-sm">
                     <span><%= item.description %>:</span>
                     <span><%= number_to_currency(item.rate_per_tonne * (@tender.total_tonnage || 0)) %></span>
                   </div>
                 <% end %>
               <% end %>
             </div>
             
             <div>
               <h4 class="font-semibold mb-2">Total P&G</h4>
               <div class="text-2xl font-bold">
                 <%= number_to_currency(@pg_items.included.sum { |item| item.rate_per_tonne * (@tender.total_tonnage || 0) }) %>
               </div>
             </div>
           </div>
         </div>
       </div>
       
       <!-- Actions -->
       <div class="flex gap-3">
         <button type="submit" class="btn btn-primary">Save P&G Items</button>
         <a href="<%= tender_path(@tender) %>" class="btn btn-ghost">Back</a>
       </div>
     </form>
   </div>
   ```

2. Style with Tailwind/Daisy UI

### P&G Calculator Service
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
         # Calculate rate per tonne from lump sum
         rate_per_tonne = item.lump_sum_amount / total_tonnage
         item.update(rate_per_tonne: RoundingService.round(rate_per_tonne, :pg))
       end
     end
   end
   ```

### P&G Controller
**File:** `app/controllers/preliminary_items_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller PreliminaryItems`
2. Add actions: index, update, create, destroy
3. Implement index:
   ```ruby
   def index
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :show?
     @pg_items = @tender.preliminary_items.by_sort_order
   end
   ```
4. Implement update:
   ```ruby
   def update
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :update?
     
     params[:preliminary_items]&.each_with_index do |attrs, index|
       item = @tender.preliminary_items[index]
       item.update(attrs) if item
     end
     
     PgCalculator.calculate(@tender)
     TenderCalculator.calculate(@tender)
     
     redirect_to tender_preliminary_items_path(@tender), 
       notice: 'P&G items updated'
   end
   ```

---

## Scope: Tender Output Page

### Tender Output Summary View
**File:** `app/views/tenders/output/index.html.erb`

**Tasks:**
1. Create comprehensive output view:
   ```erb
   <div class="container mx-auto p-6">
     <!-- Header -->
     <div class="mb-8">
       <h1 class="text-4xl font-bold"><%= @tender.project_name %></h1>
       <div class="text-gray-600 mt-2">
         <p><strong>Tender Number:</strong> <%= @tender.tender_number %></p>
         <p><strong>Client:</strong> <%= @tender.client.name %></p>
         <p><strong>Tender Date:</strong> <%= @tender.tender_date.strftime('%d %B %Y') %></p>
         <p><strong>Valid Until:</strong> <%= @tender.expiry_date.strftime('%d %B %Y') %></p>
       </div>
     </div>
     
     <!-- Line Items by Section -->
     <div class="card mb-6">
       <div class="card-body">
         <h2 class="card-title mb-4">Line Items</h2>
         
         <% sections = @line_items.group_by(&:section_header) %>
         <% sections.each do |section, items| %>
           <h3 class="font-semibold text-lg mb-3 mt-6">
             <%= section || 'Unsorted Items' %>
           </h3>
           
           <div class="overflow-x-auto mb-6">
             <table class="table table-compact">
               <thead>
                 <tr>
                   <th>Page</th>
                   <th>Item</th>
                   <th>Description</th>
                   <th>Unit</th>
                   <th class="text-right">Qty</th>
                   <th class="text-right">Rate</th>
                   <th class="text-right">Amount</th>
                 </tr>
               </thead>
               <tbody>
                 <% items.each do |item| %>
                   <tr>
                     <td><%= item.page_number %></td>
                     <td><%= item.item_number %></td>
                     <td><%= item.description %></td>
                     <td><%= item.unit %></td>
                     <td class="text-right"><%= number_with_precision item.quantity, precision: 2 %></td>
                     <td class="text-right"><%= number_to_currency item.rate_per_unit %></td>
                     <td class="text-right"><strong><%= number_to_currency item.line_amount %></strong></td>
                   </tr>
                 <% end %>
               </tbody>
             </table>
           </div>
           
           <!-- Section Subtotal -->
           <div class="text-right mb-6">
             <strong>
               Section Subtotal:
               <%= number_to_currency(items.sum(&:line_amount)) %>
             </strong>
           </div>
         <% end %>
       </div>
     </div>
     
     <!-- P&G Section -->
     <% if @pg_items.any? %>
       <div class="card mb-6">
         <div class="card-body">
           <h2 class="card-title mb-4">Preliminaries & General</h2>
           
           <div class="overflow-x-auto">
             <table class="table table-compact">
               <thead>
                 <tr>
                   <th>Description</th>
                   <th class="text-right">Rate/Tonne</th>
                   <th class="text-right">Amount</th>
                 </tr>
               </thead>
               <tbody>
                 <% @pg_items.each do |item| %>
                   <tr>
                     <td>
                       <%= item.description %>
                       <% if item.calculation_notes %>
                         <div class="text-xs text-gray-500">
                           <%= item.calculation_notes %>
                         </div>
                       <% end %>
                     </td>
                     <td class="text-right"><%= number_to_currency item.rate_per_tonne %></td>
                     <td class="text-right">
                       <strong>
                         <%= number_to_currency(item.rate_per_tonne * @tender.total_tonnage) %>
                       </strong>
                     </td>
                   </tr>
                 <% end %>
               </tbody>
             </table>
           </div>
         </div>
       </div>
     <% end %>
     
     <!-- Summary -->
     <div class="card mb-6">
       <div class="card-body">
         <h2 class="card-title mb-4">Tender Summary</h2>
         <div class="divider"></div>
         
         <div class="grid grid-cols-2 gap-8">
           <div>
             <h3 class="font-semibold mb-3">Key Information</h3>
             <div class="space-y-2 text-sm">
               <div class="flex justify-between">
                 <span>Total Tonnage:</span>
                 <strong><%= number_with_precision @tender.total_tonnage, precision: 2 %> t</strong>
               </div>
               <div class="flex justify-between">
                 <span>Unit Price Range:</span>
                 <% if @line_items.any? %>
                   <strong>
                     <%= number_to_currency @line_items.min_by(&:rate_per_unit)&.rate_per_unit || 0 %>
                     -
                     <%= number_to_currency @line_items.max_by(&:rate_per_unit)&.rate_per_unit || 0 %>
                   </strong>
                 <% end %>
               </div>
               <div class="flex justify-between">
                 <span>Margin Applied:</span>
                 <strong><%= (@tender.margin_pct * 100).round(1) %>%</strong>
               </div>
             </div>
           </div>
           
           <div>
             <h3 class="font-semibold mb-3">Financial Summary</h3>
             <div class="space-y-2">
               <div class="flex justify-between">
                 <span>Line Items Total:</span>
                 <strong><%= number_to_currency @line_items.sum(&:line_amount) %></strong>
               </div>
               <% if @pg_items.any? %>
                 <div class="flex justify-between">
                   <span>P&G Total:</span>
                   <strong>
                     <%= number_to_currency(@pg_items.sum { |item| item.rate_per_tonne * @tender.total_tonnage }) %>
                   </strong>
                 </div>
               <% end %>
               <div class="divider my-2"></div>
               <div class="flex justify-between text-xl font-bold">
                 <span>Grand Total (excl VAT):</span>
                 <span class="text-primary"><%= number_to_currency @tender.grand_total %></span>
               </div>
               <% if false %>
                 <!-- VAT calculation if needed in future -->
                 <div class="flex justify-between">
                   <span>VAT (15%):</span>
                   <strong><%= number_to_currency(@tender.grand_total * 0.15) %></strong>
                 </div>
                 <div class="flex justify-between text-lg font-bold">
                   <span>Grand Total (incl VAT):</span>
                   <strong><%= number_to_currency(@tender.grand_total * 1.15) %></strong>
                 </div>
               <% end %>
             </div>
           </div>
         </div>
       </div>
     </div>
     
     <!-- Qualifications & Terms (optional) -->
     <div class="card mb-6">
       <div class="card-body">
         <h2 class="card-title">Terms & Conditions</h2>
         <div class="divider"></div>
         <ul class="list-disc list-inside space-y-2 text-sm">
           <li>Quote valid for 30 days from date above</li>
           <li>Subject to design finalization and approved BOQ</li>
           <li>Supplier rates subject to availability</li>
           <li>Payment terms: 30% deposit, 70% on delivery</li>
           <li>Prices exclude VAT</li>
         </ul>
       </div>
     </div>
     
     <!-- Actions -->
     <div class="flex gap-3 justify-end">
       <a href="<%= tender_path(@tender) %>" class="btn btn-ghost">Back</a>
       <a href="<%= tender_pdf_path(@tender) %>" 
          class="btn btn-primary"
          download="Tender_<%= @tender.tender_number %>.pdf">
         📥 Download PDF
       </a>
       <form method="post" 
             action="<%= tender_submit_path(@tender) %>"
             style="display: inline;">
         <button type="submit" class="btn btn-success">
           ✓ Submit Tender
         </button>
       </form>
     </div>
   </div>
   ```

2. Style with Tailwind/Daisy UI

### Tender Output Controller
**File:** `app/controllers/tenders_controller.rb` (add output action)

**Tasks:**
1. Add action:
   ```ruby
   def output
     @tender = Tender.find(params[:id])
     authorize @tender, :show?
     
     @line_items = @tender.line_items.where(line_type: 'standard').by_sort_order
     @pg_items = @tender.preliminary_items.where(is_included: true).by_sort_order
   end
   ```
2. Add route: `get 'tenders/:id/output', to: 'tenders#output', as: 'tender_output'`

---

## Scope: PDF Generation

### PDF Generator Service
**File:** `app/services/tender_pdf_generator.rb`

**Tasks:**
1. Add gem to Gemfile: `gem 'prawn'`
2. Create service:
   ```ruby
   class TenderPdfGenerator
     def self.generate(tender)
       new(tender).generate
     end
     
     def initialize(tender)
       @tender = tender
       @client = tender.client
     end
     
     def generate
       Prawn::Document.new(page_size: 'A4', margin: [40, 40, 40, 40]) do |pdf|
         add_header(pdf)
         add_tender_info(pdf)
         add_line_items(pdf)
         add_pg_items(pdf)
         add_summary(pdf)
         add_terms(pdf)
         add_footer(pdf)
       end.render
     end
     
     private
     
     def add_header(pdf)
       pdf.font_size 18
       pdf.text 'RSB CONTRACTS', style: :bold
       pdf.font_size 10
       pdf.text 'Structural Steel Fabrication & Erection'
       pdf.text '40 Years of Excellence'
       
       pdf.move_down 15
       pdf.line_width 2
       pdf.stroke_horizontal_line(40, 555)
       
       pdf.move_down 10
       
       # Tender info box
       pdf.font_size 11
       pdf.text "TENDER NUMBER: #{@tender.tender_number}", style: :bold
       pdf.text "DATE: #{@tender.tender_date.strftime('%d %B %Y')}"
       pdf.text "VALID UNTIL: #{@tender.expiry_date.strftime('%d %B %Y')}"
       
       pdf.move_down 10
     end
     
     def add_tender_info(pdf)
       pdf.font_size 12
       pdf.text "To: #{@client.name}", style: :bold
       pdf.text @client.contact_person if @client.contact_person
       pdf.text @client.email if @client.email
       pdf.text @client.phone if @client.phone
       
       pdf.move_down 10
       
       pdf.font_size 11
       pdf.text "Project: #{@tender.project_name}", style: :bold
       
       pdf.move_down 15
     end
     
     def add_line_items(pdf)
       pdf.font_size 11
       pdf.text 'BILL OF QUANTITIES', style: :bold
       pdf.move_down 5
       
       # Group by section
       sections = @tender.line_items.group_by(&:section_header)
       
       sections.each do |section, items|
         pdf.font_size 10
         pdf.text section || 'General Items', style: :bold
         
         # Build table data
         table_data = [
           ['Page', 'Item', 'Description', 'Unit', 'Qty', 'Rate (R)', 'Amount (R)']
         ]
         
         items.each do |item|
           table_data << [
             item.page_number.to_s,
             item.item_number.to_s,
             item.description,
             item.unit,
             number_with_precision(item.quantity, precision: 2),
             number_to_currency(item.rate_per_unit),
             number_to_currency(item.line_amount)
           ]
         end
         
         pdf.table(table_data, width: 515) do |t|
           t.header.background_color = 'CCCCCC'
           t.header.text_color = '000000'
           t.header.font_style = :bold
           
           t.column(0).width = 45
           t.column(1).width = 45
           t.column(2).width = 200
           t.column(3).width = 40
           t.column(4).width = 50
           t.column(5).width = 65
           t.column(6).width = 65
         end
         
         pdf.move_down 10
         
         # Section subtotal
         section_total = items.sum(&:line_amount)
         pdf.text "Section Subtotal: #{number_to_currency(section_total)}", align: :right, style: :bold
         pdf.move_down 10
       end
     end
     
     def add_pg_items(pdf)
       pg_items = @tender.preliminary_items.where(is_included: true)
       return if pg_items.empty?
       
       pdf.font_size 11
       pdf.text 'PRELIMINARIES & GENERAL', style: :bold
       pdf.move_down 5
       
       table_data = [
         ['Description', 'Rate/Tonne (R)', 'Amount (R)']
       ]
       
       pg_items.each do |item|
         total = item.rate_per_tonne * @tender.total_tonnage
         table_data << [
           item.description,
           number_to_currency(item.rate_per_tonne),
           number_to_currency(total)
         ]
       end
       
       pdf.table(table_data, width: 515) do |t|
         t.header.background_color = 'CCCCCC'
         t.header.text_color = '000000'
         t.header.font_style = :bold
         
         t.column(0).width = 300
         t.column(1).width = 100
         t.column(2).width = 115
       end
       
       pdf.move_down 10
     end
     
     def add_summary(pdf)
       pdf.font_size 11
       pdf.text 'TENDER SUMMARY', style: :bold
       pdf.move_down 5
       
       summary_data = [
         ['Total Tonnage', "#{number_with_precision(@tender.total_tonnage, precision: 2)} tonnes"],
         ['Line Items Total', number_to_currency(@tender.line_items.sum(:line_amount))],
       ]
       
       pg_total = @tender.preliminary_items.where(is_included: true).sum do |item|
         item.rate_per_tonne * @tender.total_tonnage
       end
       
       if pg_total > 0
         summary_data << ['P&G Total', number_to_currency(pg_total)]
       end
       
       summary_data << ['', '']
       summary_data << ['GRAND TOTAL (excl. VAT)', number_to_currency(@tender.grand_total)]
       
       pdf.table(summary_data, width: 515) do |t|
         t.row(summary_data.length - 1).background_color = 'FFFF00'
         t.row(summary_data.length - 1).font_style = :bold
         t.row(summary_data.length - 1).font_size = 12
         
         t.column(0).width = 300
         t.column(1).width = 215
       end
       
       pdf.move_down 15
     end
     
     def add_terms(pdf)
       pdf.font_size 10
       pdf.text 'TERMS & CONDITIONS', style: :bold
       pdf.move_down 5
       
       terms = [
         "• Quote valid for 30 days from date above",
         "• Subject to design finalization and approved BOQ",
         "• Supplier rates subject to availability",
         "• Payment terms: 30% deposit, 70% on delivery",
         "• Prices exclude VAT"
       ]
       
       terms.each do |term|
         pdf.text term, size: 9
       end
     end
     
     def add_footer(pdf)
       pdf.move_to_bottom
       pdf.font_size 9
       
       pdf.stroke_horizontal_line(40, 555)
       
       pdf.text 'RSB CONTRACTS | Structural Steel Fabrication', align: :center
       pdf.text 'Contact: info@rsb.co.za | Phone: +27 (0)11 555 1234', align: :center
     end
   end
   ```

### PDF Download Action
**File:** `app/controllers/tenders_controller.rb` (add download_pdf action)

**Tasks:**
1. Add action:
   ```ruby
   def download_pdf
     @tender = Tender.find(params[:id])
     authorize @tender, :show?
     
     pdf_content = TenderPdfGenerator.generate(@tender)
     filename = "Tender_#{@tender.tender_number}_#{Date.today.to_formatted_s(:number)}.pdf"
     
     send_data pdf_content,
       filename: filename,
       type: 'application/pdf',
       disposition: 'attachment'
   end
   ```
2. Add route: `get 'tenders/:id/pdf', to: 'tenders#download_pdf', as: 'tender_pdf'`

---

## Scope: Submit Tender Workflow

### Tender Snapshot Model
**Create:** Model to capture tender state at submission

**File:** `app/models/tender_snapshot.rb`

**Tasks:**
1. Generate model: `rails generate model TenderSnapshot tender_id:bigint snapshot_data:json submitted_by_id:bigint submitted_at:datetime`
2. Add associations:
   ```ruby
   belongs_to :tender
   belongs_to :submitted_by, class_name: 'User'
   ```
3. Add to Tender:
   ```ruby
   has_many :snapshots, class_name: 'TenderSnapshot', dependent: :destroy
   ```
4. Run migration

### Submit Tender Action
**File:** `app/controllers/tenders_controller.rb` (add submit action)

**Tasks:**
1. Add action:
   ```ruby
   def submit
     @tender = Tender.find(params[:id])
     authorize @tender, :update?
     
     if @tender.update(status: 'submitted')
       # Create snapshot of current state
       TenderSnapshot.create!(
         tender: @tender,
         submitted_by: current_user,
         submitted_at: Time.current,
         snapshot_data: snapshot_data(@tender)
       )
       
       redirect_to tender_path(@tender), 
         notice: "Tender #{@tender.tender_number} submitted successfully!"
     else
       redirect_to tender_path(@tender), alert: 'Failed to submit tender'
     end
   end
   
   private
   
   def snapshot_data(tender)
     {
       tender_number: tender.tender_number,
       project_name: tender.project_name,
       client_name: tender.client.name,
       total_tonnage: tender.total_tonnage,
       grand_total: tender.grand_total,
       margin_pct: tender.margin_pct,
       inclusions: tender.inclusions_exclusions.attributes,
       line_items_count: tender.line_items.count,
       submitted_at: Time.current
     }
   end
   ```
2. Add route: `post 'tenders/:id/submit', to: 'tenders#submit', as: 'tender_submit'`

### Tender Show View - Action Buttons
**File:** `app/views/tenders/show.html.erb`

**Tasks:**
1. Add navigation tabs and action buttons:
   ```erb
   <div class="tabs">
     <a href="#overview" class="tab tab-active">Overview</a>
     <a href="#line-items" class="tab">Line Items</a>
     <a href="#configuration" class="tab">Configuration</a>
     <a href="#pg" class="tab">P&G</a>
     <a href="#output" class="tab">Output</a>
   </div>
   
   <div id="overview" class="tab-content">
     <!-- Tender summary info -->
   </div>
   
   <div id="line-items" class="tab-content">
     <%= link_to 'View Line Items', tender_line_items_path(@tender), class: 'btn btn-primary' %>
   </div>
   
   <div id="configuration" class="tab-content">
     <%= link_to 'Configure Tender', tender_configuration_path(@tender), class: 'btn btn-primary' %>
   </div>
   
   <div id="pg" class="tab-content">
     <%= link_to 'Manage P&G', tender_preliminary_items_path(@tender), class: 'btn btn-primary' %>
   </div>
   
   <div id="output" class="tab-content">
     <div class="flex gap-3">
       <%= link_to 'View Output', tender_output_path(@tender), class: 'btn btn-primary' %>
       <%= link_to 'Download PDF', tender_pdf_path(@tender), class: 'btn btn-info', download: true %>
       <% if @tender.draft? || @tender.in_progress? %>
         <%= link_to 'Submit Tender', tender_submit_path(@tender), method: :post, class: 'btn btn-success' %>
       <% end %>
     </div>
   </div>
   ```

---

## Route Summary

**Add to `config/routes.rb`:**
```ruby
resources :tenders do
  resources :preliminary_items, path: 'pg'
  
  get 'output', to: 'tenders#output', as: 'output'
  get 'pdf', to: 'tenders#download_pdf', as: 'pdf'
  post 'submit', to: 'tenders#submit', as: 'submit'
end
```

---

## Acceptance Criteria

- [ ] P&G model created with auto-creation of standard items
- [ ] P&G configuration view displays all items
- [ ] Can add custom P&G items
- [ ] Can toggle P&G items on/off
- [ ] P&G rates calculated per tonne
- [ ] P&G total displayed correctly
- [ ] Tender output page shows all line items by section
- [ ] Output page shows P&G section
- [ ] Output page shows financial summary
- [ ] Output page shows terms & conditions
- [ ] PDF generated successfully
- [ ] PDF contains all line items and sections
- [ ] PDF contains P&G items
- [ ] PDF contains summary and totals
- [ ] PDF has RSB branding and header
- [ ] PDF can be downloaded from output page
- [ ] Submit tender action updates status
- [ ] Tender snapshot created on submit
- [ ] Tender becomes read-only after submit
- [ ] End-to-end workflow: create → configure → output → PDF → submit

---

## Sprint 2 Completion

By end of Week 2c, Sprint 2 is complete:
- ✅ Rate management fully implemented
- ✅ Calculation engine functional and tested
- ✅ Tender configuration interface complete
- ✅ P&G configuration working
- ✅ Professional tender output page
- ✅ PDF generation working
- ✅ Submit workflow functional

**Phase 1 MVP Complete:**
Users can now:
1. Upload BOQ files (CSV)
2. Parse and finalize line items
3. Configure tender with rates, equipment, cranes
4. Apply margins and inclusions/exclusions
5. Configure P&G items
6. View comprehensive tender output
7. Generate professional PDF
8. Submit tender to client

---

## Post-Sprint 2 - Phase 1 Validation

**Final Activities:**
1. User acceptance testing with RSB team
2. Compare calculations with Excel templates
3. Test with real RSB tenders
4. Document any adjustments needed
5. Prepare for Phase 2

**Phase 2 Planning (Future):**
- Budget tracking
- Claims processing
- Project lifecycle management
- Reporting dashboards

---

**Week 2c Status:** Ready for Development  
**Last Updated:** Current Date
