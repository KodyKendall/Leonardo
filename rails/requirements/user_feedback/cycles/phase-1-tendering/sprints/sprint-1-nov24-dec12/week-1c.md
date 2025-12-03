# Sprint 1, Week 1c: BOQ Upload, Parsing & Line Item Management (Dec 8-12)

**Duration:** 1 week  
**Focus:** BOQ file upload, AI parsing, line item review & finalization  
**Deliverable:** Complete BOQ upload → parse → review → finalize workflow

---

## Week Overview

Week 1c completes Sprint 1 by implementing the full BOQ workflow. Users can upload CSV files, see AI-parsed results, edit them in a preview grid, and finalize into line items. This is the capstone of Sprint 1's core foundations work.

---

## Scope: BOQ Upload Interface

### BOQ Model
**Create:** Model to track uploaded BOQ files

**File:** `app/models/boq.rb`

**Tasks:**
1. Generate model: `rails generate model Boq tender_id:bigint file_path:string original_filename:string file_size:integer upload_date:datetime status:string parsed_data:json`
2. Add associations:
   ```ruby
   belongs_to :tender
   has_one_attached :csv_file
   ```
3. Add validations:
   ```ruby
   validates :tender_id, presence: true
   validates :original_filename, presence: true
   validates :status, inclusion: { in: ['uploaded', 'parsing', 'parsed', 'failed', 'finalized'] }
   ```
4. Add enum for status:
   ```ruby
   enum status: { uploaded: 'uploaded', parsing: 'parsing', parsed: 'parsed', failed: 'failed', finalized: 'finalized' }
   ```
5. Add associations to Tender:
   ```ruby
   # In tender.rb
   has_many :boqs, dependent: :destroy
   ```
6. Run migration

### BOQ Upload View
**File:** `app/views/tenders/boq_upload.html.erb`

**Tasks:**
1. Create view with:
   - Page title: "Upload BOQ"
   - File upload form with:
     - File input (accept: .csv)
     - "Upload & Parse" button
     - Help text: "Upload a CSV file with columns: Page, Item, Description, Unit, Quantity"
   - Progress indicator (hidden initially, shows during parsing)
   - Error message area
2. Style with Tailwind/Daisy UI
3. Add JavaScript for file size validation:
   - Max 10MB
   - Show error if exceeded

### BOQ Upload Controller
**Create:** Controller to handle BOQ file uploads

**File:** `app/controllers/boqs_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller Boqs`
2. Add actions: upload, create, show, destroy
3. Implement upload action:
   ```ruby
   def upload
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :update?
   end
   ```
4. Implement create action:
   ```ruby
   def create
     @tender = Tender.find(params[:tender_id])
     authorize @tender, :update?
     
     if params[:csv_file].present?
       @boq = @tender.boqs.build(original_filename: params[:csv_file].original_filename)
       @boq.csv_file.attach(params[:csv_file])
       
       if @boq.save
         BoqParsingJob.perform_later(@boq.id)
         redirect_to boq_preview_path(@boq), notice: 'BOQ uploaded. Parsing in progress...'
       else
         redirect_to boq_upload_path(@tender), alert: 'Failed to upload BOQ'
       end
     else
       redirect_to boq_upload_path(@tender), alert: 'No file selected'
     end
   end
   ```

### ActiveStorage Setup
**Tasks:**
1. Ensure ActiveStorage configured in `config/storage.yml` for local storage (development)
2. Run ActiveStorage migration if not already done: `rails active_storage:install && rails db:migrate`
3. Add to `config/environments/development.rb`:
   ```ruby
   config.active_storage.service = :local
   ```

### Route Setup
**Tasks:**
1. Add routes to `config/routes.rb`:
   ```ruby
   resources :tenders do
     get 'boq/upload', to: 'boqs#upload', as: 'boq_upload'
     post 'boq/create', to: 'boqs#create', as: 'boq_create'
     get 'boq/preview/:boq_id', to: 'boqs#preview', as: 'boq_preview'
   end
   ```

---

## Scope: BOQ Parsing with Leonardo AI

### Leonardo AI Client Wrapper
**Create:** Library wrapper for Leonardo API calls

**File:** `lib/leonardo_client.rb`

**Tasks:**
1. Create client class:
   ```ruby
   class LeonardoClient
     def initialize(api_key = ENV['LEONARDO_API_KEY'])
       @api_key = api_key
       @client = OpenAI::Client.new(api_key: api_key)
     end
     
     def parse_boq(csv_content)
       prompt = build_parse_prompt(csv_content)
       response = @client.chat(
         model: 'gpt-4',
         messages: [{ role: 'user', content: prompt }]
       )
       
       JSON.parse(response.dig('choices', 0, 'message', 'content'))
     rescue JSON::ParserError => e
       Rails.logger.error("BOQ parsing JSON error: #{e.message}")
       { error: 'Invalid response format from AI' }
     rescue StandardError => e
       Rails.logger.error("BOQ parsing error: #{e.message}")
       { error: e.message }
     end
     
     private
     
     def build_parse_prompt(csv_content)
       <<~PROMPT
         Parse this CSV content and extract BOQ line items.
         Return valid JSON with array "items" containing objects with these fields:
         - page (integer)
         - item_number (integer)
         - description (string)
         - unit (string, e.g., 't', 'no', 'm')
         - quantity (decimal)
         - suggested_category (string, e.g., 'Steel Sections', 'Bolts', 'Gutters')
         
         Skip header rows if present. Return only valid items.
         
         CSV Content:
         #{csv_content}
         
         Response format:
         { "items": [ { "page": 1, "item_number": 1, ... }, ... ] }
       PROMPT
     end
   end
   ```
2. Add `gem 'ruby-openai'` to Gemfile
3. Run `bundle install`
4. Add LEONARDO_API_KEY to `.env` file (development)

### BOQ Parsing Service
**Create:** Service class to orchestrate parsing

**File:** `app/services/boq_parsing_service.rb`

**Tasks:**
1. Create service class:
   ```ruby
   class BoqParsingService
     def self.parse(boq_record)
       new(boq_record).parse
     end
     
     def initialize(boq_record)
       @boq = boq_record
     end
     
     def parse
       begin
         csv_content = read_csv_file
         @boq.update(status: 'parsing')
         
         client = LeonardoClient.new
         parsed_data = client.parse_boq(csv_content)
         
         if parsed_data['error'].present?
           @boq.update(status: 'failed', parsed_data: parsed_data)
           return false
         end
         
         @boq.update(
           status: 'parsed',
           parsed_data: parsed_data
         )
         true
       rescue StandardError => e
         Rails.logger.error("Parsing failed: #{e.message}")
         @boq.update(status: 'failed', parsed_data: { error: e.message })
         false
       end
     end
     
     private
     
     def read_csv_file
       @boq.csv_file.download
     end
   end
   ```

### BOQ Parsing Job
**Create:** Async job to handle parsing (avoid blocking requests)

**File:** `app/jobs/boq_parsing_job.rb`

**Tasks:**
1. Generate job: `rails generate job BoqParsing`
2. Implement:
   ```ruby
   class BoqParsingJob < ApplicationJob
     queue_as :default
     
     def perform(boq_id)
       boq = Boq.find(boq_id)
       BoqParsingService.parse(boq)
     end
   end
   ```
3. Ensure ActiveJob configured for inline queue (development):
   ```ruby
   # config/environments/development.rb
   config.active_job.queue_adapter = :inline
   ```

### Error Handling
**Tasks:**
1. Add error handling for:
   - File too large (>10MB)
   - Invalid CSV format
   - Leonardo API timeout
   - Leonardo API error response
2. Display user-friendly error messages in views

---

## Scope: Line Item Review & Editing

### BOQ Preview View
**File:** `app/views/boqs/preview.html.erb`

**Tasks:**
1. Create view that displays:
   - BOQ metadata: filename, upload date, status
   - Refresh button (if parsing in progress)
   - Editable grid table with columns:
     - Page
     - Item #
     - Description
     - Unit
     - Qty
     - Category (AI-suggested, editable)
     - Actions (edit, delete)
   - "Add Line Item" button to add rows manually
   - "Confirm & Finalize" button
   - "Cancel" button (discard BOQ)
2. Style with Tailwind/Daisy UI
3. Add JavaScript for:
   - Inline editing in grid
   - Real-time row addition/deletion
   - Validation before finalize (no empty descriptions or quantities)

### BOQ Items JavaScript Component
**File:** `app/javascript/controllers/boq_items_controller.js`

**Tasks:**
1. Create Stimulus controller for BOQ grid management:
   ```javascript
   import { Controller } from "@hotwired/stimulus"
   
   export default class extends Controller {
     static targets = ["grid", "rowTemplate"]
     
     addRow() {
       const template = this.rowTemplateTarget.innerHTML
       const newRow = document.createElement('tr')
       newRow.innerHTML = template
       this.gridTarget.appendChild(newRow)
     }
     
     removeRow(event) {
       event.target.closest('tr').remove()
     }
     
     validateBeforeFinalize() {
       const rows = this.gridTarget.querySelectorAll('tbody tr')
       for (let row of rows) {
         const description = row.querySelector('[data-field="description"]').value
         const quantity = row.querySelector('[data-field="quantity"]').value
         
         if (!description || !quantity) {
           alert('All rows must have description and quantity')
           return false
         }
       }
       return true
     }
   }
   ```
2. Wire up to view with Stimulus data attributes

### BOQ Preview Controller Action
**File:** `app/controllers/boqs_controller.rb` (add preview action)

**Tasks:**
1. Add preview action:
   ```ruby
   def preview
     @boq = Boq.find(params[:boq_id])
     @tender = @boq.tender
     authorize @tender, :update?
     
     # Reload if parsing in progress
     if @boq.parsing? && @boq.updated_at < 2.minutes.ago
       @boq.reload
     end
     
     @parsed_items = @boq.parsed_data&.dig('items') || []
   end
   ```

### Finalization Service
**Create:** Service to convert parsed BOQ into actual line items

**File:** `app/services/boq_finalization_service.rb`

**Tasks:**
1. Create service:
   ```ruby
   class BoqFinalizationService
     def self.finalize(boq_record, items_data)
       new(boq_record, items_data).finalize
     end
     
     def initialize(boq_record, items_data)
       @boq = boq_record
       @items_data = items_data
       @tender = boq_record.tender
     end
     
     def finalize
       ApplicationRecord.transaction do
         @items_data.each_with_index do |item_data, index|
           create_line_item(item_data, index + 1)
         end
         
         @boq.update(status: 'finalized')
         @tender.update(status: 'in_progress') if @tender.draft?
         
         true
       rescue StandardError => e
         Rails.logger.error("Finalization failed: #{e.message}")
         false
       end
     end
     
     private
     
     def create_line_item(item_data, sort_order)
       line_item = @tender.line_items.create!(
         page_number: item_data['page'].to_i,
         item_number: item_data['item_number'].to_i,
         description: item_data['description'],
         unit: item_data['unit'],
         quantity: item_data['quantity'].to_d,
         category: item_data['suggested_category'],
         line_type: 'standard',
         sort_order: sort_order
       )
       
       # Create default line item materials
       create_default_material(line_item, item_data['suggested_category'])
       
       # Create rate build-up placeholder
       line_item.create_rate_build_up!
     end
     
     def create_default_material(line_item, category)
       material = default_material_for_category(category)
       line_item.materials.create!(
         material_supply_id: material.id,
         proportion: 1.0
       )
     end
     
     def default_material_for_category(category)
       case category
       when 'Steel Sections'
         MaterialSupply.find_by(code: 'UB_UC_LOCAL')
       when 'Plate'
         MaterialSupply.find_by(code: 'SHEETS_PLATE')
       when 'Bolts'
         MaterialSupply.find_by(code: 'ROUND_BAR')
       when 'Gutters'
         MaterialSupply.find_by(code: 'GUTTERS')
       else
         MaterialSupply.find_by(code: 'UB_UC_LOCAL')
       end
     end
   end
   ```

### BOQ Finalize Controller Action
**File:** `app/controllers/boqs_controller.rb` (add finalize action)

**Tasks:**
1. Add finalize action:
   ```ruby
   def finalize
     @boq = Boq.find(params[:boq_id])
     @tender = @boq.tender
     authorize @tender, :update?
     
     items_data = params[:items] || @boq.parsed_data['items']
     
     if BoqFinalizationService.finalize(@boq, items_data)
       redirect_to tender_line_items_path(@tender), 
         notice: 'BOQ finalized! Review and edit line items below.'
     else
       redirect_to boq_preview_path(@boq), 
         alert: 'Failed to finalize BOQ'
     end
   end
   ```
2. Add route:
   ```ruby
   post 'boq/finalize/:boq_id', to: 'boqs#finalize', as: 'boq_finalize'
   ```

---

## Scope: Line Item Management Views

### Tender Line Items Index View
**File:** `app/views/tender_line_items/index.html.erb`

**Tasks:**
1. Create view with:
   - Page title: "Line Items"
   - Summary: Total quantity, total tonnage (once calculations added)
   - "Add Line Item" button
   - "Upload BOQ" button
   - Table with columns:
     - Page
     - Item #
     - Description
     - Unit
     - Qty
     - Category
     - Actions (Expand, Edit, Delete)
   - Expandable detail rows (collapsed by default) showing:
     - Rate build-up summary (once calculations added)
   - Sorting by page/item number
2. Style with Tailwind/Daisy UI
3. Add conditional rendering:
   - Show "Upload BOQ" if no line items yet
   - Show summary only if line items exist

### Line Item Row Expansion
**File:** `app/javascript/controllers/line_item_controller.js`

**Tasks:**
1. Create Stimulus controller for expanding/collapsing line item details:
   ```javascript
   import { Controller } from "@hotwired/stimulus"
   
   export default class extends Controller {
     static targets = ["detail"]
     
     toggleDetail(event) {
       event.preventDefault()
       this.detailTarget.classList.toggle('hidden')
     }
   }
   ```

### Line Item Edit Form
**File:** `app/views/tender_line_items/_form.html.erb`

**Tasks:**
1. Create form with fields:
   - Page number (number input)
   - Item number (number input)
   - Description (textarea)
   - Unit (text input with suggestions: t, no, m, m2)
   - Quantity (decimal input)
   - Category (select dropdown)
   - Section Header (text input, optional)
   - Material Composition (will be in Part 2)
2. Add validation error messages
3. Add "Save" / "Cancel" buttons

### Tender Line Items Controller
**File:** `app/controllers/tender_line_items_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller TenderLineItems`
2. Add actions: index, show, new, create, edit, update, destroy
3. Implement index:
   ```ruby
   def index
     @tender = Tender.find(params[:tender_id])
     @line_items = @tender.line_items.by_sort_order
   end
   ```
4. Implement create:
   ```ruby
   def create
     @tender = Tender.find(params[:tender_id])
     @line_item = @tender.line_items.build(line_item_params)
     
     if @line_item.save
       @line_item.materials.create!(
         material_supply_id: MaterialSupply.find_by(code: 'UB_UC_LOCAL').id,
         proportion: 1.0
       )
       @line_item.create_rate_build_up!
       redirect_to tender_line_items_path(@tender), notice: 'Line item created'
     else
       render :new
     end
   end
   ```
5. Implement update, destroy similarly

### Line Item Deletion Confirmation
**Tasks:**
1. Add confirmation dialog before delete:
   ```erb
   <%= link_to 'Delete', line_item_path, method: :delete, 
       data: { confirm: 'Delete this line item?' }, class: 'btn btn-sm btn-error' %>
   ```

---

## Scope: Tender Status & Workflow

### Status Transitions
**File:** `app/models/tender.rb` (add state machine logic)

**Tasks:**
1. Add method to track status:
   ```ruby
   def can_transition_to?(new_status)
     case status
     when 'draft'
       new_status.in?(['in_progress', 'ready_for_review'])
     when 'in_progress'
       new_status.in?(['ready_for_review', 'draft'])
     when 'ready_for_review'
       new_status.in?(['approved', 'in_progress'])
     when 'approved'
       new_status.in?(['submitted', 'ready_for_review'])
     when 'submitted'
       new_status.in?(['won', 'lost'])
     else
       false
     end
   end
   ```
2. Add status update action to TendersController:
   ```ruby
   def update_status
     @tender = Tender.find(params[:id])
     authorize @tender, :update?
     
     new_status = params[:status]
     if @tender.can_transition_to?(new_status) && @tender.update(status: new_status)
       redirect_to @tender, notice: "Tender status updated to #{new_status}"
     else
       redirect_to @tender, alert: 'Invalid status transition'
     end
   end
   ```

### Status Badge Helper
**File:** `app/helpers/tender_helper.rb`

**Tasks:**
1. Create helper:
   ```ruby
   def status_badge(tender)
     classes = case tender.status
               when 'draft' then 'badge badge-secondary'
               when 'in_progress' then 'badge badge-info'
               when 'ready_for_review' then 'badge badge-warning'
               when 'approved' then 'badge badge-success'
               when 'submitted' then 'badge badge-primary'
               when 'won' then 'badge badge-success'
               when 'lost' then 'badge badge-error'
               end
     content_tag :span, tender.status.titleize, class: classes
   end
   ```
2. Use in views:
   ```erb
   <%= status_badge(@tender) %>
   ```

### Audit Logging
**Create:** Model to track status changes

**File:** `app/models/tender_status_log.rb`

**Tasks:**
1. Generate model: `rails generate model TenderStatusLog tender_id:bigint user_id:bigint old_status:string new_status:string timestamp:datetime`
2. Add associations:
   ```ruby
   belongs_to :tender
   belongs_to :user
   ```
3. Add callback to Tender to log status changes:
   ```ruby
   after_update :log_status_change
   
   private
   
   def log_status_change
     if status_changed?
       TenderStatusLog.create!(
         tender_id: id,
         user_id: Current.user.id,
         old_status: status_was,
         new_status: status,
         timestamp: Time.current
       )
     end
   end
   ```
4. Add to Tender views to show history

---

## Scope: Testing & Validation

### BOQ Parsing Test Cases
**Tasks:**
1. Test with sample BOQs:
   - Simple 5-item BOQ (Steel Sections)
   - Mixed items BOQ (Sections + Plate + Bolts)
   - Large 50-item BOQ (near Leonardo limit)
   - BOQ with special characters and formatting
2. Verify:
   - Parsing completes without errors
   - All fields extracted correctly
   - Categories suggested correctly
   - No data loss

### Line Item Creation Test Cases
**Tasks:**
1. Test workflow:
   - Upload BOQ → Parse → Preview → Finalize → Line items created
2. Verify:
   - Line items appear in table
   - All columns populated correctly
   - Sort order correct
   - Default materials assigned
   - Tender status changed to in_progress
3. Test editing:
   - Edit line item fields
   - Delete line item
   - Add manual line item

### Permission Testing
**Tasks:**
1. Test access by role:
   - Office staff: can upload BOQ, create line items
   - QS: can upload BOQ, edit, finalize
   - Buyer: cannot upload BOQ
   - Admin: can do all

---

## Route Setup Summary

**Add to `config/routes.rb`:**
```ruby
resources :tenders do
  resources :tender_line_items, path: 'line_items'
  get 'boq/upload', to: 'boqs#upload', as: 'boq_upload'
  post 'boq/create', to: 'boqs#create', as: 'boq_create'
  get 'boq/preview/:boq_id', to: 'boqs#preview', as: 'boq_preview'
  post 'boq/finalize/:boq_id', to: 'boqs#finalize', as: 'boq_finalize'
  patch 'status/:status', to: 'tenders#update_status', as: 'update_status'
end
```

---

## Acceptance Criteria

- [ ] BOQ model created with file attachment
- [ ] CSV files can be uploaded to tender
- [ ] Leonardo AI parsing works: returns JSON with page, item, description, unit, qty, category
- [ ] Parsed items display in preview grid
- [ ] Can add/remove items in preview before finalizing
- [ ] Can edit category suggestions inline
- [ ] Clicking "Finalize" creates TenderLineItem records
- [ ] Line items appear in tenders/line_items table
- [ ] Each line item has default material assigned
- [ ] Line items can be edited inline
- [ ] Line items can be deleted
- [ ] Line items can be added manually
- [ ] Tender status transitions: draft → in_progress → ready_for_review → approved → submitted
- [ ] Tender status changes logged in audit table
- [ ] Status badges displayed correctly in views
- [ ] Permissions enforced: only authorized users can upload/edit
- [ ] Error handling works: displays user-friendly messages
- [ ] Tested with 5-item, 30-item, 50-item BOQs

---

## Rollover Items (if not completed)

If any tasks not completed by end of Week 1c, they roll into Sprint 2:
- [ ] BOQ import from clipboard
- [ ] Bulk edit of line items
- [ ] BOQ export to CSV/Excel
- [ ] Line item category mapping improvements
- [ ] Support for BOQs >50 items

---

**Sprint 1 Completion:** Week 1c completes Sprint 1. By end of this week:
- Database is fully seeded with master data
- Users can authenticate with role-based access
- Tenders can be created and managed
- BOQ upload → parse → review → finalize workflow is complete
- Line items can be edited and managed
- Tender status workflow functional

**Next:** Sprint 2 begins Dec 15 with Rate Management, Calculations, and Tender Output.

---

**Week 1c Status:** Ready for Development  
**Last Updated:** Current Date
