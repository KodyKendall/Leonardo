# Sprint 1, Week 1b: Authentication & Core Models (Dec 1-5)

**Duration:** 1 week  
**Focus:** User authentication, roles, core Tender/Client/LineItem models  
**Deliverable:** Users can log in, tenders can be created/edited with proper permissions, basic tender CRUD views

---

## Week Overview

Week 1b implements user authentication with role-based access control and creates the core domain models (Tender, Client, TenderLineItem). By end of week, the permission system is in place and basic tender management views work.

---

## Scope: User Authentication & Roles

### User Model with Devise
**Create:** User model with email/password authentication via Devise gem

**Tasks:**
1. Add `gem 'devise'` to Gemfile
2. Run `bundle install`
3. Generate Devise user model: `rails generate devise:user`
4. This creates User model with migrations for:
   - email
   - encrypted_password
   - reset_password_token
   - reset_password_sent_at
   - remember_created_at
   - created_at
   - updated_at
5. Run migration: `rails db:migrate`
6. Verify User table created in schema.rb

### User Roles Enum
**Add:** Role-based access control to User model

**Tasks:**
1. Create migration: `add_role_to_users`
2. Add column: `role` (string, DEFAULT 'office_staff')
3. Add enum to User model:
   ```ruby
   enum role: { office_staff: 'office_staff', qs: 'qs', buyer: 'buyer', admin: 'admin' }
   ```
4. Create constants for roles:
   ```ruby
   ROLE_ADMIN = 'admin'
   ROLE_QS = 'qs'
   ROLE_BUYER = 'buyer'
   ROLE_OFFICE_STAFF = 'office_staff'
   ```
5. Run migration
6. Add validations:
   ```ruby
   validates :email, presence: true, uniqueness: true
   validates :role, presence: true, inclusion: { in: roles.keys }
   ```

### Authorization Helpers
**Create:** Helper methods for checking user roles

**File:** `app/helpers/authorization_helper.rb`

**Tasks:**
1. Create helper with methods:
   ```ruby
   def current_user_admin?
     current_user&.admin?
   end
   
   def current_user_qs?
     current_user&.qs?
   end
   
   def current_user_buyer?
     current_user&.buyer?
   end
   
   def current_user_office_staff?
     current_user&.office_staff?
   end
   
   def authorize_admin!
     redirect_to root_path unless current_user_admin?
   end
   
   def authorize_qs!
     redirect_to root_path unless current_user_qs? || current_user_admin?
   end
   ```
2. Include helper in ApplicationController
3. Make available in views

### Pundit Policy Framework
**Create:** Authorization policies using Pundit gem

**Tasks:**
1. Add `gem 'pundit'` to Gemfile
2. Run `bundle install`
3. Generate Pundit: `rails generate pundit:install`
4. This creates `app/policies/application_policy.rb`
5. Include Pundit in ApplicationController:
   ```ruby
   include Pundit::Authorization
   rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
   ```
6. Create tender policy: `app/policies/tender_policy.rb`
   ```ruby
   class TenderPolicy < ApplicationPolicy
     def index?
       user.present?
     end
     
     def show?
       user.present?
     end
     
     def create?
       user.qs? || user.admin? || user.office_staff?
     end
     
     def update?
       user.qs? || user.admin?
     end
     
     def destroy?
       user.admin?
     end
     
     def submit?
       user.qs? || user.admin?
     end
   end
   ```
7. Use policies in controller: `authorize @tender` before actions

### Test Users Seed
**File:** `db/seeds/users_seed.rb`

**Tasks:**
1. Create 4 test users:
   ```ruby
   User.create!(
     email: 'admin@rsb.test',
     password: 'password123',
     password_confirmation: 'password123',
     role: 'admin'
   )
   
   User.create!(
     email: 'demi@rsb.test',
     password: 'password123',
     password_confirmation: 'password123',
     role: 'qs'
   )
   
   User.create!(
     email: 'maria@rsb.test',
     password: 'password123',
     password_confirmation: 'password123',
     role: 'buyer'
   )
   
   User.create!(
     email: 'elmarie@rsb.test',
     password: 'password123',
     password_confirmation: 'password123',
     role: 'office_staff'
   )
   ```
2. Run `rails db:seed`
3. Verify users created in console

### Login/Logout Views
**Create:** Devise views for authentication

**Tasks:**
1. Generate Devise views: `rails generate devise:views`
2. Customize `app/views/devise/sessions/new.html.erb`:
   - Add email/password form fields
   - Add "Sign In" button
   - Style with Tailwind/Daisy UI
3. Customize `app/views/devise/registrations/new.html.erb` (sign up):
   - Create basic sign up form (can disable later)
4. Create app layout with:
   - Sign in/out links
   - Current user display
   - Logout button
5. Create `app/views/layouts/_navbar.html.erb` with user menu

### Authentication Testing
**Tasks:**
1. Test user login workflow:
   - Visit /users/sign_in
   - Enter valid email/password
   - Verify redirect to home page
   - Verify current_user is set
2. Test user logout:
   - Click logout button
   - Verify redirect to home page
   - Verify current_user is nil
3. Test role assignment:
   ```ruby
   user = User.find_by(email: 'demi@rsb.test')
   user.qs? # => true
   user.admin? # => false
   ```

---

## Scope: Core Tender & Client Models

### Client Model
**Create:** Client master data model

**File:** `app/models/client.rb`

**Tasks:**
1. Generate model: `rails generate model Client name:string contact_person:string email:string phone:string address:string is_active:boolean`
2. Add validations:
   ```ruby
   validates :name, presence: true, uniqueness: true
   validates :email, email: true, if: :email?
   validates :phone, phone: true, if: :phone?
   ```
3. Add association:
   ```ruby
   has_many :tenders, dependent: :restrict_with_error
   ```
4. Add scopes:
   ```ruby
   scope :active, -> { where(is_active: true) }
   scope :by_name, ->(name) { where('name ILIKE ?', "%#{name}%") }
   ```
5. Run migration: `rails db:migrate`
6. Create seed data:
   ```ruby
   Client.create!(
     name: 'RPP DEVELOPMENTS',
     contact_person: 'Jane Doe',
     email: 'jane@rpp.co.za',
     phone: '+27 11 555 5678',
     address: '123 Main Street, Johannesburg',
     is_active: true
   )
   ```

### Tender Model - Part 1
**Create:** Main Tender model with basic attributes

**File:** `app/models/tender.rb`

**Tasks:**
1. Generate model: `rails generate model Tender tender_number:string:uniq project_name:string client_id:bigint created_by_id:bigint assigned_to_id:bigint tender_date:date expiry_date:date project_type:string margin_pct:decimal status:string notes:text total_tonnage:decimal subtotal_amount:decimal grand_total:decimal`
2. Add additional field: `add_column :tenders, :project_type, :string, default: 'commercial'`
3. Run migrations
4. Add validations:
   ```ruby
   validates :tender_number, presence: true, uniqueness: true
   validates :project_name, presence: true
   validates :client_id, presence: true
   validates :created_by_id, presence: true
   validates :tender_date, presence: true
   validates :project_type, inclusion: { in: ['commercial', 'mining'] }
   validates :status, inclusion: { in: ['draft', 'in_progress', 'ready_for_review', 'approved', 'submitted', 'won', 'lost'] }
   validates :margin_pct, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
   ```
5. Add enum for status and project_type:
   ```ruby
   enum status: { draft: 'draft', in_progress: 'in_progress', ready_for_review: 'ready_for_review', approved: 'approved', submitted: 'submitted', won: 'won', lost: 'lost' }
   enum project_type: { commercial: 'commercial', mining: 'mining' }
   ```

### Tender Model - Associations
**Add:** Associations to Tender model

**Tasks:**
1. Add associations:
   ```ruby
   belongs_to :client
   belongs_to :created_by, class_name: 'User'
   belongs_to :assigned_to, class_name: 'User', optional: true
   has_one :inclusions_exclusions, dependent: :destroy
   has_one :on_site_breakdown, dependent: :destroy
   has_many :line_items, dependent: :destroy
   ```
2. Add after_create callback to auto-generate tender_number:
   ```ruby
   before_create :generate_tender_number
   
   private
   
   def generate_tender_number
     self.tender_number = "E#{Date.today.strftime('%d%m')}#{format('%03d', Tender.count + 1)}"
   end
   ```
3. Add default values in migration:
   ```ruby
   add_column :tenders, :status, :string, default: 'draft'
   add_column :tenders, :margin_pct, :decimal, default: 0.0
   ```

### Tender Model - Scopes
**Add:** Query scopes to Tender model

**Tasks:**
1. Add scopes:
   ```ruby
   scope :recent, -> { order(created_at: :desc) }
   scope :by_status, ->(status) { where(status: status) }
   scope :by_client, ->(client_id) { where(client_id: client_id) }
   scope :draft, -> { where(status: 'draft') }
   scope :active, -> { where(status: ['draft', 'in_progress', 'ready_for_review', 'approved']) }
   scope :submitted, -> { where(status: 'submitted') }
   scope :for_user, ->(user_id) { where('created_by_id = ? OR assigned_to_id = ?', user_id, user_id) }
   ```

### Tender Inclusions/Exclusions Model
**Create:** Toggle switches for cost components

**File:** `app/models/tender_inclusions_exclusions.rb`

**Tasks:**
1. Generate model: `rails generate model TenderInclusionsExclusions tender_id:bigint include_fabrication:boolean include_overheads:boolean include_shop_priming:boolean include_onsite_painting:boolean include_delivery:boolean include_bolts:boolean include_erection:boolean include_crainage:boolean include_cherry_picker:boolean include_galvanizing:boolean`
2. Add validations:
   ```ruby
   validates :tender_id, presence: true, uniqueness: true
   validates :include_fabrication, inclusion: { in: [true, false] }
   # ... repeat for all inclusion fields
   ```
3. Set default values in migration:
   ```ruby
   change_table :tender_inclusions_exclusions do |t|
     t.boolean :include_fabrication, default: true
     t.boolean :include_overheads, default: true
     t.boolean :include_shop_priming, default: false
     t.boolean :include_onsite_painting, default: false
     t.boolean :include_delivery, default: true
     t.boolean :include_bolts, default: true
     t.boolean :include_erection, default: true
     t.boolean :include_crainage, default: false
     t.boolean :include_cherry_picker, default: false
     t.boolean :include_galvanizing, default: false
   end
   ```
4. Add association:
   ```ruby
   belongs_to :tender
   ```
5. Run migration

### Tender On-Site Breakdown Model
**Create:** On-site parameters for crane & equipment calculations

**File:** `app/models/tender_on_site_breakdown.rb`

**Tasks:**
1. Generate model: `rails generate model TenderOnSiteBreakdown tender_id:bigint total_roof_area_sqm:decimal erection_rate_sqm_per_day:decimal splicing_crane_required:boolean splicing_crane_size:string splicing_crane_days:integer misc_crane_required:boolean misc_crane_size:string misc_crane_days:integer program_duration_days:integer`
2. Add validations:
   ```ruby
   validates :tender_id, presence: true, uniqueness: true
   validates :total_roof_area_sqm, numericality: { greater_than: 0 }, allow_nil: true
   validates :erection_rate_sqm_per_day, numericality: { greater_than: 0 }, allow_nil: true
   validates :splicing_crane_days, numericality: { greater_than_or_equal_to: 0 }, if: :splicing_crane_required?
   validates :misc_crane_days, numericality: { greater_than_or_equal_to: 0 }, if: :misc_crane_required?
   ```
3. Add association:
   ```ruby
   belongs_to :tender
   ```
4. Run migration

### Tender After-Create Callbacks
**Tasks:**
1. Add to Tender model:
   ```ruby
   after_create :create_associated_records
   
   private
   
   def create_associated_records
     create_inclusions_exclusions!
     create_on_site_breakdown!
   end
   ```
2. This auto-creates the related records when a Tender is created

### TenderLineItem Model
**Create:** Bill of quantities line items

**File:** `app/models/tender_line_item.rb`

**Tasks:**
1. Generate model: `rails generate model TenderLineItem tender_id:bigint page_number:integer item_number:integer description:string unit:string quantity:decimal category:string line_type:string section_header:string rate_per_unit:decimal line_amount:decimal margin_amount:decimal sort_order:integer`
2. Add validations:
   ```ruby
   validates :tender_id, presence: true
   validates :description, presence: true
   validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
   validates :unit, presence: true
   validates :category, presence: true
   validates :line_type, inclusion: { in: ['standard', 'bolt', 'anchor', 'gutter', 'pg', 'shop_drawings', 'provisional'] }
   ```
3. Add associations:
   ```ruby
   belongs_to :tender
   has_one :rate_build_up, class_name: 'LineItemRateBuildUp', dependent: :destroy
   has_many :materials, class_name: 'LineItemMaterial', dependent: :destroy
   has_many :extra_overs, class_name: 'LineItemExtraOver', dependent: :destroy
   ```
4. Add scopes:
   ```ruby
   scope :by_sort_order, -> { order(:sort_order) }
   scope :by_section, ->(section) { where(section_header: section) }
   ```
5. Run migration

### TenderLineItem Model - Supporting Models
**Create:** Supporting models for line item details

**Tasks:**
1. Generate LineItemRateBuildUp: `rails generate model LineItemRateBuildUp tender_line_item_id:bigint material_supply_rate:decimal fabrication_rate:decimal fabrication_factor:decimal fabrication_included:boolean ... rounded_rate:decimal`
   - Include all rate fields from Phase 1 scope
2. Add validation:
   ```ruby
   validates :tender_line_item_id, presence: true, uniqueness: true
   belongs_to :tender_line_item
   ```
3. Generate LineItemMaterial: `rails generate model LineItemMaterial tender_line_item_id:bigint material_supply_id:bigint proportion:decimal`
   - This is for blended material rates
4. Add validation:
   ```ruby
   validates :proportion, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
   belongs_to :tender_line_item
   belongs_to :material_supply
   ```
5. Generate LineItemExtraOver: `rails generate model LineItemExtraOver tender_line_item_id:bigint extra_over_type_id:bigint is_included:boolean rate_override:decimal factor_override:decimal`
6. Add associations:
   ```ruby
   belongs_to :tender_line_item
   belongs_to :extra_over_type
   ```
7. Run all migrations

---

## Scope: Tender Views & CRUD

### TendersController
**Create:** Main controller for tender management

**File:** `app/controllers/tenders_controller.rb`

**Tasks:**
1. Generate controller: `rails generate controller Tenders`
2. Add actions: index, show, new, create, edit, update, destroy
3. Add before_action filters:
   ```ruby
   before_action :authenticate_user!
   before_action :set_tender, only: [:show, :edit, :update, :destroy]
   before_action :authorize_action, only: [:edit, :update, :destroy]
   ```
4. Add action implementations:

   **index action:**
   ```ruby
   def index
     @tenders = Tender.recent
     @tenders = @tenders.by_status(params[:status]) if params[:status].present?
     @tenders = @tenders.by_client(params[:client_id]) if params[:client_id].present?
     @tenders = @tenders.paginate(page: params[:page], per_page: 25)
   end
   ```

   **show action:**
   ```ruby
   def show
     # set_tender before_action handles this
   end
   ```

   **new action:**
   ```ruby
   def new
     @tender = Tender.new
     @clients = Client.active
   end
   ```

   **create action:**
   ```ruby
   def create
     @tender = current_user.tenders.build(tender_params)
     if @tender.save
       redirect_to tender_line_items_path(@tender), notice: 'Tender created'
     else
       @clients = Client.active
       render :new
     end
   end
   ```

   **edit action:**
   ```ruby
   def edit
     @clients = Client.active
   end
   ```

   **update action:**
   ```ruby
   def update
     if @tender.update(tender_params)
       redirect_to @tender, notice: 'Tender updated'
     else
       @clients = Client.active
       render :edit
     end
   end
   ```

   **destroy action:**
   ```ruby
   def destroy
     @tender.destroy
     redirect_to tenders_url, notice: 'Tender deleted'
   end
   ```

5. Add private methods:
   ```ruby
   private
   
   def set_tender
     @tender = Tender.find(params[:id])
   end
   
   def tender_params
     params.require(:tender).permit(:project_name, :client_id, :tender_date, :expiry_date, :project_type, :margin_pct, :notes)
   end
   
   def authorize_action
     authorize @tender, :update? if action_name.in?(%w[edit update])
     authorize @tender, :destroy? if action_name == 'destroy'
   end
   ```

### Tenders Index View
**File:** `app/views/tenders/index.html.erb`

**Tasks:**
1. Create layout with:
   - Page title: "Tenders"
   - "Create New Tender" button
   - Filter section: by status, by client, by date (optional)
   - Table with columns:
     - Tender #
     - Project Name
     - Client
     - Status (with badge styling)
     - Total Amount
     - Created At
     - Actions (View, Edit, Delete)
   - Pagination at bottom
2. Style with Tailwind/Daisy UI
3. Add conditional rendering:
   - Hide delete button if user not admin
   - Show/hide edit button based on permission

### Tenders Show View
**File:** `app/views/tenders/show.html.erb`

**Tasks:**
1. Create layout with:
   - Tender header: number, project name, client, status
   - Navigation tabs:
     - Overview
     - Line Items
     - Configuration
     - P&G
     - Output
   - Status badge
   - Summary panel showing totals (tonnage, subtotal, grand_total)
   - Back button to index

### Tenders New/Edit Forms
**File:** `app/views/tenders/_form.html.erb`

**Tasks:**
1. Create shared form partial with fields:
   - Project Name (text input, required)
   - Client (select dropdown from Client.active)
   - Tender Date (date picker)
   - Project Type (radio buttons: Commercial / Mining)
   - Margin % (number input, 0-100)
   - Notes (textarea)
2. Create new.html.erb that renders form
3. Create edit.html.erb that renders form
4. Add "Create" / "Update" submit button
5. Add validation error messages

### Test Tender Creation
**Tasks:**
1. Test workflow:
   - Log in as office_staff user
   - Navigate to /tenders
   - Click "Create New Tender"
   - Fill in form with valid data
   - Click "Create"
   - Verify redirect to tender show page
   - Verify tender created in database
2. Test permission:
   - Log in as buyer user
   - Try to access /tenders/new
   - Verify redirect or error (no access)
3. Test edit permission:
   - Log in as QS user
   - Edit tender created by office staff
   - Verify update works
   - Log in as admin
   - Verify admin can edit any tender

---

## Acceptance Criteria

- [ ] User model created with Devise authentication
- [ ] 4 test users created with different roles
- [ ] Users can log in with email/password
- [ ] Users can log out
- [ ] Authorization policies work: admin/qs/buyer/office_staff have correct permissions
- [ ] Client model created with validations
- [ ] Tender model created with all fields and validations
- [ ] Tender inclusions/exclusions auto-created on tender creation
- [ ] Tender on-site breakdown auto-created on tender creation
- [ ] TenderLineItem model with supporting models created
- [ ] Tenders index view displays all tenders with filters
- [ ] Can create new tender via form
- [ ] Can edit tender (QS & Admin only)
- [ ] Can delete tender (Admin only)
- [ ] Can view tender details
- [ ] Tender number auto-generated on creation
- [ ] Status workflow functional (draft → in_progress → etc.)
- [ ] All validations working

---

**Week 1b Status:** Ready for Development  
**Last Updated:** Current Date
