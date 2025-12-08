# Sprint 1, Week 1a: Database & Infrastructure (Nov 24-28)

**Duration:** 1 week  
**Focus:** Database schema, migrations, seed data setup  
**Deliverable:** Complete master data schema with populated seed data

---

## Week Overview

Week 1a establishes the foundational database infrastructure. All master data tables are created, migrations run successfully, and realistic RSB rates are seeded. By end of week, the database is ready for model development in Week 1b.

---

## Scope: Tender Builder (SPA Implementation)

### Main Scope: Tender Builder
**Status:** ✅ **COMPLETED**

Single-page application (SPA) experience for managing tenders using Rails 7 Hotwire (Turbo + Stimulus). The Builder page (`/tenders/:id/builder`) is the primary workspace where users manage all line items and nested cost breakdowns with zero full-page reloads.

**Deliverables:**
- ✅ Builder hub page with 3-column layout
- ✅ Real-time header and summary updates via Turbo Streams
- ✅ Hotwire Turbo + Stimulus integration
- ✅ All interactions use Turbo Frames for seamless SPA experience

---

### Sub-Scope 1: Tender Line Item
**Status:** ✅ **COMPLETED**

CRUD operations for line items within the Tender Builder, with inline forms and Turbo-driven updates.

**Deliverables:**
- ✅ Add Line Item form appears inline below button (Turbo Frame)
- ✅ Form includes nested Rate Build Up and Material Breakdown sections
- ✅ Line item cards display with Edit and Delete buttons
- ✅ Create/Update/Delete actions respond with Turbo Streams
- ✅ No page reloads for any line item operation
- ✅ Comprehensive validation on model and display errors gracefully

---

### Sub-Scope 2: Line Item Rate Buildup
**Status:** ✅ **COMPLETED**

Rate component management within each line item, including 11 rate categories with checkboxes, margin calculation, and auto-totaling.

**Deliverables:**
- ✅ Rate fields for: material supply, fabrication, overheads, shop priming, delivery, bolts, erection, crainage, cherry picker, galvanizing, and safety file
- ✅ "Include" checkboxes for each rate component
- ✅ Margin input field
- ✅ Auto-calculated subtotal (sum of included rates)
- ✅ Auto-calculated total (subtotal + margin)
- ✅ Auto-rounded rate to nearest 5
- ✅ Live calculation via Stimulus rate_calculator_controller
- ✅ Collapsible Rate Build Up section with toggle icon

---

### Sub-Scope 3: Line Item Material Breakdown
**Status:** ✅ **COMPLETED**

Material composition management within each line item, allowing multiple materials with proportion allocation.

**Deliverables:**
- ✅ Material list with add/remove functionality
- ✅ "+ Add Material" button clones new material row dynamically
- ✅ Collapsible Material Breakdown section
- ✅ Full integration with nested form handling
- ✅ Delete button per material row
- ✅ Supports multiple materials per line item

---

### Sub-Scope 4: Line Item Materials
**Status:** ✅ **COMPLETED**

Individual material rows within the Material Breakdown, with material selection and proportion input.

**Deliverables:**
- ✅ Material dropdown (populated from MaterialSupply reference table)
- ✅ Proportion input field (0-1 decimal for material mix)
- ✅ Delete button (marks for destruction if persisted, removes from DOM if new)
- ✅ Dynamic nested form handling via Stimulus nested_form_controller
- ✅ Material rows render inline without page reload

---

## Tender Builder Implementation Summary

**Controllers & Routes:**
- ✅ `TendersController#builder` — Main SPA hub with eager-loaded line items
- ✅ `TenderLineItemsController#new, #create, #edit, #update, #destroy` — All with Turbo Stream responses
- ✅ Nested routes under Tender resource

**Key Views & Turbo Frames:**
- ✅ `app/views/tenders/builder.html.erb` — Main SPA hub
- ✅ `app/views/tenders/_builder_header.html.erb` — Tender info + totals
- ✅ `app/views/tenders/_builder_summary.html.erb` — Summary stats
- ✅ `app/views/tender_line_items/_line_item.html.erb` — Line item card
- ✅ `app/views/tender_line_items/_form.html.erb` — Unified add/edit form
- ✅ `app/views/tender_line_items/{create,update,destroy}.turbo_stream.erb` — Turbo Stream responses
- ✅ `app/views/line_item_rate_build_ups/_fields.html.erb` — Rate buildup grid
- ✅ `app/views/line_item_material_breakdowns/_fields.html.erb` — Material container
- ✅ `app/views/line_item_materials/_fields.html.erb` — Material row

**Stimulus Controllers:**
- ✅ `nested_form_controller.js` — Add/remove nested records dynamically
- ✅ `rate_calculator_controller.js` — Live rate calculation
- ✅ `collapsible_controller.js` — Toggle nested sections

**Data Model:**
- ✅ Tender (aggregate root) with `has_many :tender_line_items`
- ✅ TenderLineItem with `accepts_nested_attributes_for` for rate buildup and material breakdown
- ✅ LineItemRateBuildUp (has_one) with all rate components
- ✅ LineItemMaterialBreakdown (has_one) with `has_many :line_item_materials`
- ✅ LineItemMaterial (has_many) with material_supply reference

---

**Week 1a Status:** Database & Infrastructure Complete + Tender Builder SPA Implemented  
**Last Updated:** Current Date
