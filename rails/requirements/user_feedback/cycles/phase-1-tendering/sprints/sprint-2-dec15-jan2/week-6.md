# Sprint 2, Week 6: Output & Integration (Dec 30 - Jan 5)

**Duration:** 1 week
**Focus:** Tender summary page, PDF generation, permission refinements
**Deliverable:** Client-facing tender PDF with RSB branding, final integration
**Status:** 🔴 PENDING
**Last Updated:** December 15, 2025

---

## Week Overview

Week 6 completes Phase 1 by implementing the tender summary page (matching Excel "Page 1"), PDF generation with RSB branding, and permission refinements. This week delivers the final output that clients will receive.

**Note:** New Year period - availability may be limited. Testing period begins Jan 5.

---

## Vertical Slice Breakdown

| Slice | Scope Doc | Priority | Est. Days | Status | Assigned |
|-------|-----------|----------|-----------|--------|----------|
| Tender Summary Page | New | High | 1-2 | 🔴 Pending | - |
| PDF Generation | New | High | 2-3 | 🔴 Pending | - |
| Permission Refinements | Part of REQUIREMENTS.md | High | 1 | 🔴 Pending | - |

---

## Capability G: Tender Summary Page

### Use Case UC-601: Tender Summary View

**Description:** Final tender overview matching the current Excel "Page 1" output

**Acceptance Criteria:**
- [ ] AC-601.1: Summary page shows all line items grouped by section
- [ ] AC-601.2: Each line shows: description, unit, qty, rate, amount
- [ ] AC-601.3: Page accessible from tender show page
- [ ] AC-601.4: Summary updates automatically when line items change

**Layout Structure:**
```
┌────────────────────────────────────────────────────────────────┐
│                    RSB TENDER SUMMARY                           │
│                    E3801 - RPP Transformers                     │
├────────────────────────────────────────────────────────────────┤
│ Client: ABC Construction                                        │
│ Date: December 15, 2025                                         │
│ Valid For: 30 days                                              │
├────────────────────────────────────────────────────────────────┤
│ SECTION: STEELWORK                                              │
├──────────────────────────────────┬─────┬───────┬───────┬───────┤
│ Description                      │Unit │  Qty  │ Rate  │Amount │
├──────────────────────────────────┼─────┼───────┼───────┼───────┤
│ Primary steel - columns          │ t   │ 45.20 │R15,300│R691,560│
│ Primary steel - beams            │ t   │ 82.50 │R14,850│R1,225,125│
│ Secondary steelwork - purlins    │ t   │ 35.00 │R16,200│R567,000│
├──────────────────────────────────┼─────┼───────┼───────┼───────┤
│                    Section Total │     │162.70 │       │R2,483,685│
├────────────────────────────────────────────────────────────────┤
│ SECTION: BOLTS                                                  │
├──────────────────────────────────┬─────┬───────┬───────┬───────┤
│ HD bolts M20                     │ t   │  2.50 │R 8,500│R21,250│
├──────────────────────────────────┼─────┼───────┼───────┼───────┤
│                    Section Total │     │  2.50 │       │R21,250│
├────────────────────────────────────────────────────────────────┤
│ SECTION: P&G                                                    │
├──────────────────────────────────┬─────┬───────┬───────┬───────┤
│ Site establishment               │LS   │  1.00 │R100,000│R100,000│
│ Safety file & audits             │LS   │  1.00 │R30,000│R30,000│
├──────────────────────────────────┼─────┼───────┼───────┼───────┤
│                    Section Total │     │       │       │R130,000│
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│ TOTAL TONNAGE:           165.20 tonnes                         │
│ GRAND TOTAL:             R2,634,935 (excl. VAT)                │
│                                                                 │
│ Prices valid for 30 days from date of tender                   │
└────────────────────────────────────────────────────────────────┘
```

### Use Case UC-602: Section Headers and Subtotals

**Description:** Line items grouped by section with section subtotals

**Acceptance Criteria:**
- [ ] AC-602.1: Section headers display (e.g., "STEELWORK", "BOLTS", "P&G")
- [ ] AC-602.2: Section subtotals calculate correctly (sum of amounts in section)
- [ ] AC-602.3: Sections ordered consistently (Steelwork → Bolts → P&G → Shop Drawings)
- [ ] AC-602.4: Empty sections hidden from display

**Section Mapping:**
| Category | Display Section |
|----------|-----------------|
| Steel Sections | STEELWORK |
| CFLC | STEELWORK |
| Plate Work | STEELWORK |
| Hollow Sections | STEELWORK |
| Bolts | BOLTS |
| HD Bolts | BOLTS |
| Chemical Anchors | BOLTS |
| P&G Items | PRELIMINARIES & GENERAL |
| Shop Drawings | SHOP DRAWINGS |

### Use Case UC-603: Grand Total and Tonnage

**Description:** Final totals display at bottom of summary

**Acceptance Criteria:**
- [ ] AC-603.1: Grand total = sum of all section totals
- [ ] AC-603.2: Total tonnage = sum of all line item quantities (where unit = t)
- [ ] AC-603.3: VAT exclusion note displayed
- [ ] AC-603.4: Price validity period displayed

---

## Capability H: PDF Generation

### Use Case UC-604: Generate Tender PDF

**Description:** Create downloadable PDF from tender summary

**Acceptance Criteria:**
- [ ] AC-604.1: "Generate PDF" button creates downloadable PDF
- [ ] AC-604.2: PDF includes all line items with rates and amounts
- [ ] AC-604.3: PDF format matches current Excel output layout
- [ ] AC-604.4: PDF filename format: `RSB_Tender_E3801_YYYYMMDD.pdf`

**Technical Approach:**
```ruby
# Option 1: wicked_pdf (HTML to PDF via wkhtmltopdf)
# Pros: Uses existing HTML/CSS, familiar Rails views
# Cons: Requires wkhtmltopdf binary, styling can be tricky

# Option 2: Prawn (native Ruby PDF)
# Pros: Pure Ruby, precise control, no external dependencies
# Cons: More code, layout built programmatically

# Recommended: wicked_pdf for faster initial implementation
# with option to switch to Prawn later if needed
```

### Use Case UC-605: RSB Branding and Formatting

**Description:** PDF includes RSB branding and professional formatting

**Acceptance Criteria:**
- [ ] AC-605.1: RSB logo displayed in header
- [ ] AC-605.2: Company contact details in header/footer
- [ ] AC-605.3: Professional formatting (fonts, spacing, borders)
- [ ] AC-605.4: Consistent with RSB brand guidelines

**Header Content:**
```
┌────────────────────────────────────────────────────────────────┐
│ [RSB LOGO]                                                      │
│                                                                 │
│ RSB Contracts (Pty) Ltd                                         │
│ Address Line 1                                                  │
│ Address Line 2                                                  │
│ Tel: +27 XX XXX XXXX                                            │
│ Email: tenders@rsb.co.za                                        │
└────────────────────────────────────────────────────────────────┘
```

### Use Case UC-606: Validity Period Display

**Description:** Tender validity information displayed clearly

**Acceptance Criteria:**
- [ ] AC-606.1: "Prices valid for 30 days" disclaimer shows
- [ ] AC-606.2: Tender date displayed prominently
- [ ] AC-606.3: Reference number (E-number) displayed
- [ ] AC-606.4: Validity period configurable (default 30 days)

---

## Capability I: Permission Refinements

### Use Case UC-607: Material Supply Rate Editing Restricted

**Description:** Only authorized users can edit master material rates

**Acceptance Criteria:**
- [ ] AC-607.1: Only Richard, Ruan, Maria can edit material_supply_rates
- [ ] AC-607.2: Edit button hidden for unauthorized users
- [ ] AC-607.3: Controller authorization prevents direct access
- [ ] AC-607.4: Audit log records rate changes

**Role-Based Access:**
| Role | View Rates | Edit Rates | Select Supplier |
|------|------------|------------|-----------------|
| Admin (Richard, Ruan) | ✅ | ✅ | ✅ |
| Buyer (Maria) | ✅ | ✅ | ✅ |
| QS (Demi) | ✅ | ❌ | ❌ |
| Office Staff (Elmarie) | ✅ | ❌ | ❌ |

### Use Case UC-608: Supplier Selection Restricted

**Description:** Only authorized users can change which supplier is selected as default

**Acceptance Criteria:**
- [ ] AC-608.1: Only Richard, Ruan, Maria can change supplier checkbox
- [ ] AC-608.2: Demi can view but not modify supplier selection
- [ ] AC-608.3: Demi can override rates at tender level only
- [ ] AC-608.4: Supplier selection changes logged

**Implementation:**
```ruby
# app/policies/material_supply_rate_policy.rb
class MaterialSupplyRatePolicy < ApplicationPolicy
  def update?
    user.admin? || user.buyer?
  end

  def select_supplier?
    user.admin? || user.buyer?
  end
end
```

---

## Implementation Details

### PDF Generation with wicked_pdf

**Gemfile Addition:**
```ruby
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary' # or install wkhtmltopdf system-wide
```

**Controller:**
```ruby
# app/controllers/tender_pdfs_controller.rb
class TenderPdfsController < ApplicationController
  def show
    @tender = Tender.find(params[:tender_id])

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "RSB_Tender_#{@tender.e_number}",
               template: 'tender_pdfs/show',
               layout: 'pdf',
               page_size: 'A4',
               margin: { top: 20, bottom: 20, left: 15, right: 15 },
               header: { html: { template: 'tender_pdfs/header' } },
               footer: { html: { template: 'tender_pdfs/footer' } }
      end
    end
  end
end
```

**Routes:**
```ruby
resources :tenders do
  resource :pdf, only: [:show], controller: 'tender_pdfs'
end
```

### Summary Page View

```erb
<%# app/views/tenders/summary.html.erb %>
<div class="tender-summary">
  <header class="tender-header">
    <%= image_tag 'rsb_logo.png', class: 'logo' %>
    <h1>TENDER SUMMARY</h1>
    <h2><%= @tender.e_number %> - <%= @tender.project_name %></h2>
  </header>

  <div class="tender-info">
    <p>Client: <%= @tender.client.name %></p>
    <p>Date: <%= @tender.tender_date.strftime('%B %d, %Y') %></p>
    <p>Valid For: <%= @tender.validity_days %> days</p>
  </div>

  <% @tender.line_items.group_by(&:section).each do |section, items| %>
    <section class="tender-section">
      <h3><%= section %></h3>
      <table>
        <thead>
          <tr>
            <th>Description</th>
            <th>Unit</th>
            <th>Qty</th>
            <th>Rate</th>
            <th>Amount</th>
          </tr>
        </thead>
        <tbody>
          <% items.each do |item| %>
            <tr>
              <td><%= item.description %></td>
              <td><%= item.unit %></td>
              <td><%= number_with_precision(item.quantity, precision: 2) %></td>
              <td><%= number_to_currency(item.rate, unit: 'R', precision: 0) %></td>
              <td><%= number_to_currency(item.amount, unit: 'R', precision: 0) %></td>
            </tr>
          <% end %>
        </tbody>
        <tfoot>
          <tr>
            <td colspan="4">Section Total</td>
            <td><%= number_to_currency(items.sum(&:amount), unit: 'R', precision: 0) %></td>
          </tr>
        </tfoot>
      </table>
    </section>
  <% end %>

  <footer class="tender-totals">
    <p>TOTAL TONNAGE: <%= number_with_precision(@tender.total_tonnage, precision: 2) %> tonnes</p>
    <p>GRAND TOTAL: <%= number_to_currency(@tender.grand_total, unit: 'R', precision: 0) %> (excl. VAT)</p>
    <p class="validity">Prices valid for <%= @tender.validity_days %> days from date of tender</p>
  </footer>
</div>
```

---

## Recommended Build Order

**Day 1: Tender Summary Page**
- Create summary view template
- Implement section grouping
- Calculate section subtotals
- Display grand total and tonnage

**Day 2-3: PDF Generation**
- Install and configure wicked_pdf
- Create PDF layout template
- Add RSB logo and branding
- Style PDF to match Excel output
- Test PDF generation end-to-end

**Day 4: PDF Polish**
- Header and footer templates
- Page numbers
- Proper font sizing
- Table borders and spacing
- Test with various tender sizes

**Day 5: Permissions**
- Implement Pundit policies
- Restrict material rate editing
- Restrict supplier selection
- Add role checks to views
- Test authorization scenarios

---

## Key Files to Create/Modify

### Controllers
- `app/controllers/tender_pdfs_controller.rb` - New
- `app/controllers/material_supply_rates_controller.rb` - Add authorization

### Views
- `app/views/tenders/summary.html.erb` - New
- `app/views/tender_pdfs/show.pdf.erb` - New
- `app/views/tender_pdfs/_header.html.erb` - New
- `app/views/tender_pdfs/_footer.html.erb` - New
- `app/views/layouts/pdf.html.erb` - New

### Policies
- `app/policies/material_supply_rate_policy.rb` - New or enhance

### Assets
- `app/assets/images/rsb_logo.png` - RSB branding
- `app/assets/stylesheets/pdf.css` - PDF-specific styles

### Config
- `config/initializers/wicked_pdf.rb` - PDF configuration

---

## Testing Scenarios

### Summary Page Test
1. Navigate to tender summary page
2. Verify all line items grouped by section
3. Verify section subtotals correct
4. Verify grand total = sum of subtotals
5. Verify total tonnage calculation

### PDF Generation Test
1. Click "Generate PDF" button
2. Verify PDF downloads with correct filename
3. Verify PDF contains all tender data
4. Verify RSB logo and branding present
5. Verify layout matches Excel output

### Permission Test
1. Log in as Demi (QS)
2. Navigate to material supply rates
3. Verify edit button hidden
4. Try direct URL access to edit - verify denied
5. Log in as Maria (Buyer)
6. Verify edit button visible
7. Make a rate change - verify successful

---

## Acceptance Criteria Summary

### Critical (Must Complete)
- [ ] AC-601.1-4: Tender summary view working
- [ ] AC-602.1-4: Section headers and subtotals working
- [ ] AC-603.1-4: Grand total and tonnage working
- [ ] AC-604.1-4: PDF generation working
- [ ] AC-607.1-4: Material rate edit restriction working

### High Priority
- [ ] AC-605.1-4: RSB branding in PDF
- [ ] AC-606.1-4: Validity period display
- [ ] AC-608.1-4: Supplier selection restriction

---

## Transition to Testing Period

After Week 6, the system enters a **2-week testing period (Jan 5-19)**:

### Testing Objectives
1. Recreate DeMarco and Suzuki tenders in new system
2. Compare output to Excel originals
3. Document discrepancies and bugs
4. Fix critical issues (no new features)

### Success Criteria for Go-Live (Jan 19)
- [ ] System produces identical rates to Excel for test tenders
- [ ] PDF output matches current deliverable format
- [ ] End-to-end workflow completes without errors
- [ ] Demi and Richard can use system without assistance
- [ ] All critical bugs resolved

---

## Stakeholder Meeting

| Date | Attendees | Purpose | Notes |
|------|-----------|---------|-------|
| Jan 8 (Wed) | Demi, Kody | Testing period kickoff | First meeting after holiday |

---

**Week Status:** Pending
**Last Updated:** December 15, 2025
