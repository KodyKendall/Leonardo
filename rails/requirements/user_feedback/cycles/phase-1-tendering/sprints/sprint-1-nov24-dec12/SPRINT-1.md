# Sprint 1: Core Foundations (Nov 24 - Dec 12)

**Duration:** 3 weeks  
**Focus:** Database setup, authentication, core models, BOQ import  
**Goal:** BOQ can be uploaded, parsed, reviewed, and finalized  

---

## Sprint Overview

Sprint 1 establishes the foundational infrastructure for the RSB Tendering System. We build the database schema, set up user authentication and roles, create core models for tenders and BOQ management, and implement the complete BOQ upload → parse → review → finalize workflow.

**Key Outcome:** A user can upload a CSV BOQ file, see it parsed and displayed, edit line items, and finalize it into the system.

---

## Week Breakdown

- **Week 1a (Nov 24-28):** Database schema, migrations, seed data  
- **Week 1b (Dec 1-5):** Authentication, user roles, tender & line item models  
- **Week 1c (Dec 8-12):** BOQ upload, AI parsing, line item review & finalization

---

## Detailed Tasks by Scope

### Week 1a: Database & Infrastructure

#### Database Schema & Migrations
**Scope:** Create all master data tables for rates, equipment, and crane management.

**Tasks:**
1. Create migration: `create_suppliers` table with fields: name, contact_person, email, phone, is_active
2. Create migration: `create_material_supplies` table with fields: code, name, category, base_rate_per_tonne, waste_percentage, effective_from, is_active
3. Create migration: `create_material_supply_rates` table linking suppliers to material supplies with supplier-specific pricing
4. Create migration: `create_processing_rates` table with fields: code, name, base_rate_per_tonne, work_type, factor, is_active, effective_from
5. Create migration: `create_equipment_types` table with fields: category, model, working_height_m, base_rate_monthly, damage_waiver_pct, diesel_allowance_monthly
6. Create migration: `create_crane_rates` table with fields: size, ownership_type, dry_rate_per_day, diesel_per_day
7. Create migration: `create_crane_complements` table with fields: area_min_sqm, area_max_sqm, complement_description, default_wet_rate_per_day
8. Create migration: `create_extra_over_types` table with fields: code, name, default_rate, default_factor
9. Create migration: `create_galvanizing_rates` table with fields: base_dip_rate, zinc_mass_factor, fettling_per_tonne, delivery_per_tonne, effective_from
10. Run migrations and verify schema

#### Seed Data
**Scope:** Populate master data with realistic RSB rates and equipment from current Excel sheets.

**Tasks:**
1. Create seeds for 22 material supply types (UB/UC Local, Plate, CFLC, etc.) with waste percentages
2. Create seeds for 3-4 suppliers (Macsteel, Dram, etc.) with base rates
3. Create seeds for processing rates: Shop Drawings (R350), Fabrication (R8,000), Overheads (R4,150), Shop Priming (R1,380), Onsite Painting (R1,565), Delivery (R700), Bolts (R1,500), Erection (R1,800), Galvanizing (R11,000)
4. Create seeds for crane sizes: 10t, 20t, 25t, 30t, 35t, 50t, 90t with both RSB-owned and rental rates
5. Create seeds for crane complements: 250-350 m/day with 8,300 wet rate, etc.
6. Create seeds for equipment types: Scissors (electric/diesel), Booms (450AJ, 600AJ, 800AJ), Telehandlers
7. Create seeds for extra over types: Castellating, Curving, MPI, Weld Test
8. Create seeds for galvanizing rates with base dip, fettling, delivery
9. Verify seed data loads without errors
10. Run `rails db:seed` and spot-check data in console

---

### Week 1b: Authentication & Core Models

#### User Authentication & Roles
**Scope:** Set up user authentication with role-based access control (Admin, QS, Buyer, Office Staff).

**Tasks:**
1. Generate User model with Devise for email/password authentication
2. Add role enum to User: admin, qs, buyer, office_staff
3. Create role-based authorization helper methods (current_user.admin?, current_user.qs?, etc.)
4. Create Pundit policy framework for authorization checks
5. Create base ApplicationPolicy with role-based access patterns
6. Generate admin panel for user management (create, edit, deactivate users)
7. Seed 4 test users: 1 admin, 1 QS, 1 Buyer, 1 Office Staff
8. Test login/logout workflows for each role
9. Test authorization redirects (unauthorized users see error page)

#### Core Tender & Client Models
**Scope:** Create the main Tender record and Client master data models.

**Tasks:**
1. Generate Client model with fields: name, contact_person, email, phone, address, is_active
2. Generate Tender model with associations to User (created_by, assigned_to) and Client
3. Add fields to Tender: tender_number, project_name, tender_date, expiry_date, project_type (enum: commercial, mining), margin_pct, status (enum), notes, total_tonnage, subtotal_amount, grand_total
4. Create migration: `create_tender_inclusions_exclusions` with all toggle fields
5. Create migration: `create_tender_on_site_breakdown` with roof area, erection rate, crane parameters
6. Add associations: Tender has_one :inclusions_exclusions, :on_site_breakdown
7. Generate TenderLineItem model with fields: page_number, item_number, description, unit, quantity, category, line_type, section_header, rate_per_unit, line_amount, margin_amount, sort_order
8. Add association: Tender has_many :line_items, TenderLineItem belongs_to :tender
9. Generate migration to create tender_line_items table
10. Add validations: Tender requires project_name, client_id; TenderLineItem requires description, quantity, tender_id
11. Generate scopes for common queries: Tender.recent, Tender.by_status, Tender.by_client
12. Test model relationships and validations in console

#### Tender Views & Index
**Scope:** Create basic CRUD views for tender management.

**Tasks:**
1. Generate TendersController with actions: index, show, new, create, edit, update, destroy
2. Create tenders/index.html.erb view with table: tender_number, project_name, client_name, status, total, created_at
3. Add filters to index: by status, by client, by date range (optional for Week 1)
4. Create tenders/show.html.erb with tender summary and navigation tabs
5. Create tenders/new.html.erb form: project_name, client_id, tender_date, project_type, margin_pct, notes
6. Create tenders/edit.html.erb form (same as new)
7. Add breadcrumb navigation to all tender views
8. Test CRUD operations: create tender, view, edit, update
9. Verify permissions: Office staff can create, Buyers cannot, Admins can do all

---

### Week 1c: BOQ Upload, Parsing & Line Item Management

#### BOQ Upload Interface
**Scope:** Allow users to upload CSV files and display preview before parsing.

**Tasks:**
1. Generate BOQ model to store uploaded file reference and metadata
2. Create migration: `create_boqs` with fields: tender_id, file_path, original_filename, file_size, upload_date, status (enum: uploaded, parsing, parsed, failed)
3. Create tenders/boq_upload.html.erb view with file upload form
4. Add route: POST /tenders/:id/boq (create BOQ)
5. Create BoqsController with action: create
6. Implement file upload handling with ActiveStorage (attach CSV to BOQ record)
7. Create CSV preview: read first 10 rows and display in table format
8. Add ability to skip header rows if BOQ starts with metadata
9. Test file upload: different CSV formats, file sizes, error handling

#### BOQ Parsing with Leonardo AI
**Scope:** Call Leonardo AI to parse BOQ content and extract line items.

**Tasks:**
1. Create Leonardo API client wrapper in lib/leonardo_client.rb
2. Implement parse_boq method that:
   - Reads CSV file content
   - Sends to Leonardo AI with prompt: "Extract from this BOQ: Page, Item Number, Description, Unit, Quantity"
   - Returns parsed JSON with array of line items
3. Create service class: BoqParsingService.parse(boq_record)
4. Handle parsing errors gracefully: timeout, API error, invalid format
5. Store parsed results in BOQ record (json field or new table)
6. Create tenders/boq_review.html.erb with editable grid preview:
   - Columns: Page, Item #, Description, Unit, Qty, Category (AI-suggested)
   - Inline editing capability (edit description, qty, category)
   - Add/remove line item buttons
   - "Confirm & Finalize" button to create actual line items
7. Test parsing with 3-5 sample BOQs
8. Test edge cases: empty BOQ, single item, 50+ items, malformed CSV

#### Line Item Finalization & Management
**Scope:** Convert parsed BOQ preview into actual TenderLineItem records.

**Tasks:**
1. Create BoqLineItemsService.finalize(boq_record) method that:
   - Iterates through parsed BOQ items
   - Creates TenderLineItem record for each with: page_number, item_number, description, unit, quantity, category
   - Sets default line_type: 'standard'
   - Sets sort_order based on page/item
   - Creates associated LineItemMaterial record (default material type based on category)
   - Returns created line items
2. Update BOQ status to 'finalized' after line item creation
3. Create TenderLineItem model with associations:
   - belongs_to :tender
   - has_one :rate_build_up
   - has_many :materials
   - has_many :extra_overs
4. Create migration: `create_line_item_materials` (tender_line_item_id, material_supply_id, proportion)
5. Create tenders/line_items/index.html.erb view:
   - Table with: Page, Item, Description, Unit, Qty, Category, Actions
   - Expandable detail rows (collapsed by default)
   - Edit/delete buttons per row
   - Add line item button at bottom
6. Create tenders/line_items/_form.html.erb for inline editing
7. Implement update action: TenderLineItemsController#update
8. Implement delete action: TenderLineItemsController#destroy
9. Test finalization workflow end-to-end:
   - Upload BOQ → Parse → Review → Finalize → Line items appear in table
10. Test line item editing: change quantity, category, description

#### Tender Status & Workflow
**Scope:** Implement tender status transitions and basic workflow.

**Tasks:**
1. Add tender status enum: draft → in_progress → ready_for_review → approved → submitted → won/lost
2. Create helper method for status badge styling (draft=gray, in_progress=blue, ready_for_review=orange, etc.)
3. Add status update buttons to tender/show view
4. Implement state machine transitions:
   - draft → in_progress (when first line item added)
   - in_progress → ready_for_review (manual button)
   - ready_for_review → approved (admin only)
   - approved → submitted (manual button)
5. Create audit log for status changes (basic: just timestamp, old_status, new_status, user_id)
6. Test status transitions and permissions

---

## Acceptance Criteria

### Week 1a
- [ ] All master data tables created with correct schema
- [ ] Seed data loaded successfully (run `rails db:seed`)
- [ ] Can query suppliers, material_supplies, processing_rates, etc. from console
- [ ] No migration errors

### Week 1b
- [ ] User model with Devise authentication working
- [ ] 4 test users created with different roles
- [ ] Users can log in with email/password
- [ ] Tenders index shows all tenders with status
- [ ] Can create new tender (office staff & QS only)
- [ ] Can view tender details
- [ ] Can edit tender (QS & Admin only)
- [ ] Permissions enforced: unauthorized users redirected

### Week 1c
- [ ] CSV file can be uploaded to tender
- [ ] File preview shows first 10 rows
- [ ] Leonardo AI parsing produces JSON with Page, Item, Description, Unit, Qty
- [ ] Parsed items display in editable grid
- [ ] Can add/remove items in preview before finalizing
- [ ] Clicking "Finalize" creates TenderLineItem records
- [ ] Line items appear in tenders/line_items table with all columns
- [ ] Can edit quantity, description, category inline
- [ ] Can delete line items
- [ ] Tender status transitions from draft → in_progress on first line item creation
- [ ] Audit log records status changes

---

## Rollover Items (if not completed)

If any tasks are not completed by end of Week 1c, they roll into Sprint 2:
- [ ] BOQ size limit increases (>50 items)
- [ ] Material type auto-detection from steel catalog (Phase 2 feature)
- [ ] BOQ export to Excel
- [ ] Bulk line item import from clipboard

---

## Testing Checklist

- [ ] All models have RSpec tests (associations, validations, scopes)
- [ ] All controllers have integration tests (CRUD, auth checks)
- [ ] BOQ parsing tested with 5+ sample files
- [ ] Line item creation tested end-to-end
- [ ] Permissions tested for each role
- [ ] No SQL N+1 queries on tenders index

---

**Sprint Status:** Ready for Development  
**Last Updated:** Current Date
