# RSB Steel Fabrication Tender Costing System - Business Requirements

**Document Version:** 1.01
**Last Updated:** November 28, 2025
**Last Editor:** Darren
**Status:** Draft - Pending Stakeholder Review

---

## Table of Contents

1. [Overview & Objectives](#1-overview--objectives)
2. [Personas & User Stories](#2-personas--user-stories)
3. [Current (As-Is) Process](#3-current-as-is-process)
4. [Future (To-Be) Process](#4-future-to-be-process)
5. [Data Model](#5-data-model)
6. [Calculations & Business Rules](#6-calculations--business-rules)
7. [Outputs & Reporting](#7-outputs--reporting)
8. [Roles, Permissions, and Audit](#8-roles-permissions-and-audit)
9. [Open Questions, Risks, Assumptions](#9-open-questions-risks-assumptions)

---

## 1. Overview & Objectives

### 1.1 Problem Statement

RSB Contracts is a 40-year-old family-owned structural steel fabrication company with approximately 150 employees. The tendering processthe heart of the businesscurrently relies on a complex ecosystem of interconnected Excel spreadsheets that have evolved organically over two decades.

**Current Pain Points:**

1. **No Single Source of Truth**: Multiple Excel files exist for each tender (Tender Data, Costing Sheet, Rates Page, Access Equipment, etc.), leading to version control issues and data inconsistencies.

2. **High Manual Labor Cost**: The tendering process consumes 80-100+ man-hours per month across three role levels:
   - Elmarie (Office Staff): ~27 hours/month at ~R175/hour
   - Demi (Quantity Surveyor): ~27 hours/month at ~R495/hour
   - Richard/Ruan (Directors): ~27 hours/month at ~R1,570/hour
   - **Estimated monthly cost: R60,000-80,000** in labor for tendering alone

3. **Human Error Risk**: Manual data transfer between sheets introduces errors. As Richard stated: *"Eliminate human errorhaving so many different sheets... it would be nice if it would be one database."*

4. **Training Nightmare**: *"The training is a nightmare. That's the worst part. We put so much time into training someone."*  Richard Spencer

5. **No Downstream Tracking**: Tender data cannot flow into project budgets, claims, or financial tracking. *"Every single rand that ever gets spent, all has to be allowed for and tracked from this initial setup."*  Richard Spencer

6. **Fragmented Data**: Budget tracking exists in separate files, claims in another, leading to reconciliation challenges and no holistic project view.

### 1.2 Goals

**Primary Goals:**

| Goal | Description | Success Metric |
|------|-------------|----------------|
| G-001 | Centralize all tender data in a single database | 100% of tender data in one system |
| G-002 | Reduce manual data entry and transfer | 50% reduction in tender preparation time |
| G-003 | Eliminate human error from manual calculations | Zero calculation errors in tenders |
| G-004 | Enable downstream tracking from tender to project completion | Full traceability from quote to final claim |
| G-005 | Standardize rate management across the organization | Single source of truth for all rates |

**Secondary Goals:**

| Goal | Description | Success Metric |
|------|-------------|----------------|
| G-006 | Reduce training time for new staff | 75% reduction in onboarding time |
| G-007 | Enable management reporting and analytics | Real-time tender pipeline visibility |
| G-008 | Support competitive pricing strategies | Ability to quickly adjust margins and inclusions |

### 1.3 Scope

**In Scope (Phase 1 - Tendering Module):**

- BOQ (Bill of Quantities) import and management
- Material supply rate management (monthly updates)
- Processing rate management (annual updates)
- Equipment rate management (cranes, access equipment)
- Tender creation and configuration
- Line item cost build-up calculations
- Tender inclusions/exclusions management
- P&G (Preliminaries & General) cost allocation
- Tender document generation (PDF output)
- User roles and permissions
- Rate history and versioning

**Out of Scope (Future Phases):**

- Budget tracking and management
- Claims processing
- Project execution tracking
- Inventory management
- Supplier integration/EDI
- Mobile application
- Integration with accounting systems

### 1.4 Success Metrics

| Metric | Current State | Target State | Measurement Method |
|--------|--------------|--------------|-------------------|
| Tender preparation time | 2-3 hours per tender | 30-60 minutes per tender | Time tracking |
| Calculation errors | Unknown (discovered post-submission) | Zero | Error audit log |
| Rate update time | Manual updates across all sheets | Single update propagates automatically | System logs |
| Training time | 2-4 weeks for new QS | 2-3 days | Onboarding tracking |
| Tender throughput | ~2 BOQs per day | 4+ BOQs per day | System metrics |

---

## 2. Personas & User Stories

### 2.1 Personas

#### Richard Spencer  CEO/President
- **Role**: Final decision maker, strategic oversight
- **Goals**: Comprehensive tracking from tender through project completion; ensure every rand is accounted for
- **Pain Points**: Cannot see holistic view across all tenders and projects; relies on others to compile reports
- **Quote**: *"My huge picture for this whole thing is to go from this to generating budgets, to tracking budgets, etc."*
- **System Access Level**: Admin (full access)

#### Ruan  Business Partner (Project System)
- **Role**: Oversees project execution and operations
- **Goals**: Ensure tender data flows into project budgets seamlessly
- **Pain Points**: Manual re-entry of tender data into project tracking
- **System Access Level**: Admin (full access)

#### Demi Swanepoel  Quantity Surveyor (QS)
- **Role**: Primary tender processor; reviews and finalizes all tenders
- **Goals**: Efficient tender preparation; accurate cost calculations; minimize repetitive work
- **Pain Points**: Complex Excel formulas; manual material type selection; repetitive data entry
- **Quote**: *"CFLC and cold-rolled items should always have fabrication set to zero."*
- **System Access Level**: QS (create/edit tenders, view rates, cannot modify master rates)

#### Elmarie  Office Staff / Receptionist
- **Role**: Initial BOQ setup; data entry; administrative support
- **Goals**: Quick and accurate data capture; clear processes to follow
- **Pain Points**: Uncertainty about which fields to complete; complex spreadsheet navigation
- **Quote**: *"I do the initial setup, not the selection of the 1s and 0s [inclusions/exclusions]."*
- **System Access Level**: Data Entry (create tenders, enter BOQ data, limited editing)

#### Maria  Buyer
- **Role**: Maintains material supply rates from suppliers
- **Goals**: Keep rates current; track supplier pricing trends
- **Pain Points**: Manual rate updates across multiple spreadsheets
- **System Access Level**: Buyer (update material rates only)

### 2.2 User Stories by Process

#### BOQ Import

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-001 | As Elmarie, I want to upload a CSV file containing a BOQ so that I don't have to manually type each line item | CSV upload successful; line items parsed and displayed for review | High |
| US-002 | As Elmarie, I want the system to automatically extract client name, project name, and tender details from the BOQ so that I don't have to enter them manually | AI-assisted extraction with manual override capability | Medium |
| US-003 | As Demi, I want to review and edit parsed BOQ line items before finalizing so that I can correct any parsing errors | Editable grid view of all line items; ability to add/remove/modify | High |
| US-004 | As Demi, I want each line item automatically assigned to a category (Steel Sections, Bolts, Gutters, etc.) so that the correct rate templates are applied | AI-suggested categories with manual override | High |
| US-005 | As Elmarie, I want the original BOQ file to remain linked to the tender for reference so that I can always refer back to what was received | File download available from tender record | Medium |

#### Rate Maintenance

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-010 | As Maria, I want to update material supply rates monthly so that tenders use current pricing | Rate update UI; effective date tracking; version history | High |
| US-011 | As Richard, I want rate changes to be versioned with format `rates_YYYYMMDDxx` so that I can track when rates changed | Automatic version numbering on save | High |
| US-012 | As Demi, I want to see the second-cheapest supplier rate as the default for each material supply so that we remain competitive | Automatic supplier rate comparison and selection | Medium |
| US-013 | As Richard, I want processing rates (fabrication, erection, etc.) updated annually so that they reflect current labor costs | Admin-only rate update with effective dates | High |
| US-014 | As Demi, I want to manually override supplier rates for specific tenders so that I can use negotiated pricing | Per-tender rate override capability | High |
| US-015 | As Maria, I want to add new suppliers and their rates so that we can compare pricing across vendors | Supplier management UI | Medium |

#### Tender Build-up

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-020 | As Demi, I want to select which cost components are included at the tender level (fabrication, erection, delivery, etc.) so that I can configure the tender correctly | Toggle switches for each inclusion/exclusion | High |
| US-021 | As Demi, I want to override inclusions at the line item level so that specific items can have different configurations | Per-line-item inclusion overrides | High |
| US-022 | As Demi, I want the system to automatically calculate the rate per tonne for each line item based on material + processing costs so that I don't have to calculate manually | Automatic calculation with formula transparency | High |
| US-023 | As Demi, I want rates rounded to the nearest R50 (R20 for crainage, R10 for cherry pickers) so that final rates match our pricing conventions | Automatic rounding per business rules | High |
| US-024 | As Richard, I want to apply a margin percentage at the tender level so that we can adjust profitability | Margin input with automatic recalculation | High |
| US-025 | As Demi, I want to see the line item rate build-up (material supply, fabrication, overheads, etc.) so that I can verify each component | Expandable detail view per line item | High |
| US-026 | As Demi, I want CFLC and cold-rolled items to automatically have fabrication set to zero so that I don't have to remember this rule | Automatic rule application based on category | High |
| US-027 | As Richard, I want to apply a margin percentage for each iteam at the material rates build up level so that we can adjust profitability | Margin input with automatic recalculation | High |

#### Equipment & Crane Selection

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-030 | As Demi, I want to enter the total roof area and erection rate (m/day) so that crane requirements are calculated | Input fields with automatic crane complement lookup | High |
| US-031 | As Richard, I want to select RSB-owned cranes vs rental cranes so that we can use our own equipment when available | Crane ownership type selection per tender | High |
| US-032 | As Demi, I want to manually adjust the crane complement so that I can account for project-specific requirements | Editable crane selections with recalculation | High |
| US-033 | As Demi, I want to add multiple equipment selections (e.g., 3 booms for 1 month + 1 boom for 2 months) so that I can model complex equipment needs | Multiple equipment line items per type | High |
| US-034 | As Demi, I want the 6% damage waiver automatically applied to access equipment so that it's included in costs | Automatic damage waiver calculation | High |

#### P&G (Preliminaries & General)

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-040 | As Demi, I want to add custom P&G items (site establishment, accommodation, travel) with descriptions and lump sums so that project-specific costs are captured | Free-form P&G item entry | High |
| US-041 | As Demi, I want P&G items divided by total tonnage to get a rate per tonne so that they're distributed across line items | Automatic P&G rate calculation | High |
| US-042 | As Demi, I want crainage and cherry picker costs to either be included in line item rates OR in P&G (not both) so that there's no double-counting | Mutual exclusion logic between line items and P&G | High |

#### Approvals & Workflow

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-050 | As Elmarie, I want to assign a tender to Demi when initial setup is complete so that she can review and finalize | Workflow status and assignment | Medium |
| US-051 | As Demi, I want to mark a tender as "Ready for Review" so that Richard knows it needs his attention | Status workflow with notifications | Medium |
| US-052 | As Richard, I want to approve tenders before they're submitted so that I have oversight of major quotes | Approval workflow for tenders above threshold | Low |
| US-053 | As Richard, I want to send tenders back to Demi and Elmarie with notes when revisions are required | Approval workflow for tenders above threshold | Low |

#### Reporting

| ID | User Story | Acceptance Criteria | Priority |
|----|-----------|-------------------|----------|
| US-060 | As Richard, I want to see a list of all tenders with their status so that I can track the pipeline | Tender list view with filtering and sorting | High |
| US-061 | As Richard, I want to filter and sort tenders by status, client, and date so that I can find specific tenders | Filter and sort controls | Medium |
| US-062 | As Demi, I want to generate a tender PDF document with RSB branding so that I can send it to the client | PDF export with standard formatting | High |
| US-063 | As Richard, I want to see win/loss tracking on tenders so that I can analyze our success rate | Status tracking and reporting | Low |

---

## 3. Current (As-Is) Process

### 3.1 Process Narrative

The current tendering process at RSB Contracts follows this general flow:

**Step 1: Receive BOQ**
- RSB receives a Bill of Quantities (BOQ) from a potential client
- Format varies: Excel, CSV, or PDF
- If PDF, data must be manually entered
- Elmarie performs initial review and setup

**Step 2: Initial Setup (Elmarie)**
- Creates a copy of the tender template Excel workbook
- Enters project information (client name, project name, tender date)
- Assigns tender reference number (format: E + date, e.g., E3801)
- Copies BOQ data into the "Tender Data" sheet
- Sets prices valid for 30 days (default)
- Does NOT select inclusions/exclusions (1s and 0s)

**Step 3: Rate Updates (Maria - Monthly)**
- Updates material supply rates in the "Rates Page"
- Gets quotes from suppliers (e.g., DRAM Coatings for paint)
- Updates waste percentages as needed
- This is a separate process from individual tenders

**Step 4: Tender Configuration (Demi)**
- Reviews BOQ line items and assigns categories
- Selects inclusions/exclusions for the tender (fabrication, erection, etc.)
- Configures equipment requirements:
  - Enters total roof area (m)
  - Enters erection rate (m/day)
  - Selects crane complement (may override defaults)
  - Selects access equipment (cherry pickers, booms)
- Sets material type proportions for each line item
- Adjusts rates for special cases:
  - CFLC items: fabrication = 0
  - Galvanized items: add galvanizing rate
  - Extra overs: castellating, curving, MPI testing

**Step 5: P&G Configuration (Demi)**
- Calculates P&G items for project-specific costs:
  - Site establishment/de-establishment
  - Plant establishment/de-establishment
  - Accommodation for PM and labor
  - Travel costs
- Enters lump sum amounts
- These are divided by total tonnage

**Step 6: Review & Adjustment (Demi + Richard)**
- Reviews calculated rates and totals
- Adjusts margin if needed
- May adjust specific line items for competitive positioning
- Special rule: If bolts > 2.5% of total tonnage, include in rates for competitiveness

**Step 7: Final Output (Demi)**
- Reviews "Page 1" output (the tender summary)
- Verifies all calculations
- Prepares tender document for client
- Price valid for 30 days

### 3.2 Key Pain Points

| Pain Point | Description | Impact | Stakeholder Quote |
|------------|-------------|--------|-------------------|
| PP-001 | Multiple spreadsheet versions | Data inconsistency, wrong rates used | *"Having so many different sheets, in the budget tracking for example, we have one excel for the tender, then we have another one for the claim, then it becomes all these other spreadsheets"*  Richard |
| PP-002 | Manual material type lookup | Time-consuming, error-prone | 22-level nested IF formula in Excel |
| PP-003 | Training new staff | Long onboarding, high knowledge transfer burden | *"The training is a nightmare. That's the worst part."*  Richard |
| PP-004 | No audit trail | Cannot track who changed what | Rate changes not logged |
| PP-005 | Broken formulas | #REF! errors in spreadsheet | Rates!C12 currently shows #REF! error |
| PP-006 | Manual tender-to-project handoff | Re-entry of data for budget tracking | No integration between systems |
| PP-007 | Difficulty comparing supplier rates | Manual comparison across suppliers | No automatic "second cheapest" selection |
| PP-008 | Complex crane complement calculations | Requires expert knowledge | Lookup table logic hard to understand |

### 3.3 Inventory of Current Spreadsheets

| Sheet Name | Purpose | Key Data | Update Frequency |
|------------|---------|----------|------------------|
| **Page 1** | Final tender output | Line items, rates, amounts, totals | Per tender |
| **Rates Page** | Master rates and configuration | Processing rates (B16:B33), Material rates (B35:C56), Toggle switches (F21:F30), Crane calculations (E36:H48) | Rates: annually; Config: per tender |
| **Access Equipment** | Equipment costing | Equipment catalog, unit selections, period, costs | Catalog: annually; Selection: per tender |
| **Costing Sheet** | Line item calculations | Detailed cost build-up per item (19 rows per item) | Per tender |
| **Tender Data** | BOQ line items | Page, Item, Description, Unit, Qty, Category | Per tender |
| **DATA SHEET LOCKED** | Lookup tables | Crane rates, crane complements by area | Annually |
| **Standard Lines (Copy)** | Templates | Standard line item templates | Rarely |

### 3.4 Current Data Flow

The current Excel workbook follows this data flow:

1. **TENDER DATA** contains raw BOQ line items (Page, Item, Description, Unit, Qty, Category)

2. **RATES PAGE** serves as the configuration hub:
   - Processing rates (Shop Drawings through Galvanizing): B16:B33
   - Material supply rates with waste percentages: B35:C56
   - Toggle switches for inclusions/exclusions: F21:F30
   - On-site calculations (roof area, crane complement): E36:H48
   - Calculated rates for crainage and cherry pickers: B24:B25

3. **ACCESS EQUIPMENT** calculates equipment costs:
   - Equipment catalog with base rates and damage waiver
   - Per-tender selections (units, period)
   - Total equipment allowance  feeds B25 on Rates Page

4. **DATA SHEET LOCKED** provides lookup tables:
   - Mobile crane rates by size (10t through 90t)
   - Crane complement by erection area (m/day)

5. **COSTING SHEET** performs the main calculations:
   - Pulls line items from Tender Data
   - Applies rates from Rates Page
   - Applies toggle switches for inclusions
   - Calculates material costs using 22-level nested IF
   - Rounds rates to nearest R50
   - Outputs to Page 1

6. **PAGE 1** is the final output:
   - Client-facing tender document
   - Line items with Page, Item, Description, Unit, Qty, Rate, Amount
   - Section subtotals and grand total

---

## 4. Future (To-Be) Process

### 4.1 Step-by-Step Flows

#### Flow 1: Create New Tender

**Step 1.1: Initiate Tender**
- User navigates to /tenders
- Clicks "Create New Tender"
- System generates unique tender number (format: E + sequential ID)
- User enters: Tender name, Client name, Contact person, Submission deadline, Notes

**Step 1.2: Upload BOQ**
- User uploads CSV file (Excel must be converted to CSV first; option to enter items manually if BOQ is a PDF)
- System stores original file for reference
- System displays preview of parsed data
- User adjusts header row if needed (skip introductory rows)

**Step 1.3: Parse BOQ with AI**
- User clicks "Parse BOQ"
- AI assistant analyzes CSV content
- Extracts: Page, Item Number, Description, Unit, Quantity
- Suggests category for each line item
- Creates tender line items in database

**Step 1.4: Review & Edit Line Items**
- User reviews parsed line items in editable grid
- Can modify: Page, Item, Description, Unit, Qty, Category
- Can add or remove line items
- Can assign section headers for grouping

#### Flow 2: Configure Tender Settings

**Step 2.1: Set Inclusions/Exclusions**
- User navigates to Tender Settings
- Toggles on/off for each cost component:
  - Fabrication, Overheads, Shop Priming, On-Site Painting
  - Delivery, Bolts, Erection, Crainage, Cherry Pickers, Galvanizing
- Settings apply as defaults to all line items
- Per-line-item overrides available later

**Step 2.2: Configure On-Site Parameters**
- User enters: Total Roof Area (m)
- User enters: Area to be Erected Per Day (m)
- System looks up default crane complement
- User can override crane selections
- User indicates if splicing crane required (Yes/No)
- User selects splicing crane type
- User indicates if miscellaneous crane required (Yes/No)
- User selects miscellaneous crane type

**Step 2.3: Select Access Equipment**
- User browses equipment catalog (scissors, booms, telehandlers)
- Adds equipment line items with:
  - Equipment type (from catalog)
  - Number of units
  - Period required (months)
  - Purpose (optional description)
- Can add multiple lines for same equipment type with different periods
- System calculates: Rate  (1 + 6% damage waiver) + diesel = Monthly cost
- System calculates: Monthly cost  Units  Period = Total allowance

**Step 2.4: Set Margin**
- User enters tender-level margin percentage
- Margin applied to subtotal of each line item build up before rounding

#### Flow 3: Review Line Item Build-up

**Step 3.1: View Line Item List**
- User sees all line items with: Page, Item, Description, Unit, Qty, Rate, Line Total
- Items grouped by section headers
- Expandable/collapsible detail view per item

**Step 3.2: View/Edit Rate Build-up**
- User expands line item to see rate build-up:
  - Material Supply (with material type and waste %)
  - Fabrication (rate  inclusion toggle)
  - Overheads (rate  inclusion toggle)
  - Shop Priming, On-Site Painting, Delivery, Bolts, Erection
  - Crainage, Cherry Picker, Galvanizing
  - Extra Overs (castellating, curving, MPI, weld testing)
  - Subtotal, Margin, Total
  - Rounded Rate (to nearest R50)
- User can override individual component rates
- User can override inclusion toggles for this line item only

**Step 3.3: Edit Material Breakdown**
- User can adjust material mix (e.g., 85% UB/UC, 15% Plate)
- System recalculates weighted average rate
- Default: 15% plate allocation (configurable at tender level)
- Exception: CFLC items default to 0% plate
- Default weight percentage applied per line, editable 
- Editable margin per material breakdown item
- Rounds up material breakdown figures to the nearest R50

#### Flow 4: Configure P&G Items

**Step 4.1: View P&G Summary**
- System shows P&G line item with:
  - Safety File & Audits (standard)
  - Crainage (if not included in item rates)
  - Cherry Picker (if not included in item rates)
  - Custom items added by user

**Step 4.2: Add Custom P&G Items**
- User adds P&G items with:
  - Description (free text)
  - Lump sum amount (R)
  - Calculation notes (e.g., "20 people  6 months  R5,000")
- System calculates rate per tonne = Lump sum  Total tonnage
- P&G rate rounds to nearest R50

#### Flow 5: Generate Tender Output

**Step 5.1: Review Tender Summary**
- User views tender summary page showing:
  - All line items with rates and amounts
  - Section subtotals
  - P&G total
  - Shop drawings total
  - Grand total
  - Total tonnage

**Step 5.2: Generate PDF**
- User clicks "Generate PDF"
- System creates PDF with:
  - RSB logo and branding
  - Client name, project name, tender number
  - Date, validity period, contact information
  - Line items by section
  - Totals
  - Standard terms and qualifications

**Step 5.3: Submit Tender**
- User marks tender as "Submitted"
- System records submission date
- Tender becomes read-only (except status updates)

### 4.2 Swimlanes by Role

#### Tender Creation Swimlane

| Step | Elmarie (Office Staff) | Demi (QS) | Maria (Buyer) | Richard (Admin) |
|------|----------------------|-----------|---------------|-----------------|
| 1. Receive BOQ | Downloads/receives BOQ from client | | | |
| 2. Create Tender | Creates tender record, uploads BOQ | | | |
| 3. Parse BOQ | Initiates AI parsing, reviews results | | | |
| 4. Review Line Items | Basic review, flags issues | Detailed review, assigns categories | | |
| 5. Configure Settings | | Sets inclusions/exclusions | | May advise on strategy |
| 6. Select Equipment | | Selects cranes and access equipment | | |
| 7. Configure P&G | | Adds custom P&G items | | |
| 8. Review Build-up | | Reviews all rate build-ups | | |
| 9. Set Margin | | Recommends margin | | Approves margin |
| 10. Generate Output | | Generates PDF | | |
| 11. Submit | | Submits to client | | Final approval if required |

#### Rate Maintenance Swimlane

| Step | Maria (Buyer) | Demi (QS) | Richard (Admin) |
|------|--------------|-----------|-----------------|
| 1. Receive Supplier Quotes | Gets quotes from suppliers | | |
| 2. Update Material Rates | Updates rates in system | Reviews changes | |
| 3. Save with Version | Saves (system versions automatically) | | |
| 4. Annual Rate Review | | Reviews processing rates | Approves processing rate changes |
| 5. Update Processing Rates | | | Updates fabrication, erection, etc. |

---

## 5. Data Model

### 5.1 Master Data Tables

These tables contain reference data maintained centrally and used across all tenders.

#### 5.1.1 suppliers

Stores information about material suppliers.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| name | Supplier company name | "Macsteel" |
| contact_person | Primary contact | "John Smith" |
| email | Contact email | "john@macsteel.co.za" |
| phone | Contact phone | "+27 11 555 1234" |
| is_active | Whether supplier is active | true |

#### 5.1.2 material_supplies

Stores the catalog of material supply types with their base rates.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| code | Short code for material supply | "UB_UC_LOCAL" |
| name | Display name | "Local UB & UC Sections" |
| category | Material supply category | "sections" |
| base_rate_per_tonne | Current rate in Rand | 15900.00 |
| waste_percentage | Waste percentage (decimal) | 0.075 (7.5%) |
| effective_from | Date rate became active | 2024-01-01 |
| is_active | Whether material supply is active | true |

**Current Material Supply Types (22):**
- Unequal Angles, Equal Angles, Large Equal Angles
- Local UB & UC Sections, Import UB & UC Sections
- PFC Sections, Heavy PFC Sections, IPE Sections
- Sheets of Plate, Cut to Size Plate
- Standard Hollow Sections, Non-Standard Hollow Sections
- Gutters, Round Bar
- CFLC Metsec Alternative 1.6mm, CFLC Metsec Alternative 2mm
- And others as defined in Rates Page B35:C56

#### 5.1.3 material_supply_rates

Links material_supplies to suppliers with supplier-specific pricing.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| material_supply_id | Reference to material_supply | 1 |
| supplier_id | Reference to supplier | 2 |
| rate_per_tonne | Supplier's rate | 15750.00 |
| effective_from | Date rate became active | 2024-11-01 |
| is_active | Whether rate is active | true |

#### 5.1.4 processing_rates

Stores processing rates (fabrication, erection, etc.) maintained annually.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| code | Rate code | "FABRICATION" |
| name | Display name | "Fabrication" |
| description | Detailed description | "Structural steel fabrication" |
| base_rate_per_tonne | Base rate | 8000.00 |
| work_type | Type of work | "structural" |
| factor | Multiplier for work type | 1.0 |
| is_lump_sum | Whether this is a lump sum | false |
| effective_from | Date rate became active | 2024-01-01 |
| is_active | Whether rate is active | true |

**Processing Rate Codes:**
- SHOP_DRAWINGS (R350/t)
- FABRICATION (R8,000/t base, with factors: structural=1.0, platework=1.75, piping=3.0)
- OVERHEADS (R4,150/t)
- SHOP_PRIMING (R1,380/t)
- ONSITE_PAINTING (R1,565/t)
- DELIVERY (R700/t)
- BOLTS (R1,500/t, capped at 2% of mass)
- ERECTION (R1,800/t)
- GALVANIZING (R11,000/t)
- SAFETY_FILE (R30,000 lump sum)

#### 5.1.5 equipment_types

Catalog of access equipment (scissors, booms, telehandlers).

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| category | Equipment category | "diesel_articulating_boom" |
| model | Model identifier | "600AJ" |
| working_height_m | Working height in meters | 20.0 |
| base_rate_monthly | Monthly rental rate | 38195.00 |
| damage_waiver_pct | Damage waiver percentage | 0.06 (6%) |
| diesel_allowance_monthly | Monthly diesel allowance | 19500.00 |
| is_active | Whether equipment is active | true |

**Equipment Categories:**
- Electric Scissors (e.g., 3394RT, 4394RT)
- Diesel Scissors (e.g., 530LRT)
- Diesel Articulating Booms (e.g., 450AJ, 600AJ, 800AJ)
- Telehandlers

#### 5.1.6 crane_rates

Mobile crane rental rates.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| size | Crane capacity | "25t" |
| ownership_type | RSB-owned or rental | "rental" |
| dry_rate_per_day | 9-hour dry rate | 1660.00 |
| diesel_per_day | Daily diesel allowance | 750.00 |
| is_active | Whether rate is active | true |

**Crane Sizes:**
- 10t, 20t, 25t, 30t, 35t, 50t, 90t (current)
- 110t, 130t, 160t, 200t, 250t (to be added)

Each size has two entries: RSB-owned and rental rates.

#### 5.1.7 crane_complements

Lookup table for default crane combinations based on erection area.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| area_min_sqm | Minimum m/day | 250 |
| area_max_sqm | Maximum m/day | 350 |
| complement_description | Crane combination | "1 x 10t + 2 x 25t" |
| default_wet_rate_per_day | Combined daily rate | 8300.00 |

#### 5.1.8 extra_over_types

Additional processing types beyond standard (castellating, curving, etc.).

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| code | Type code | "CASTELLATING" |
| name | Display name | "Castellating" |
| default_rate | Default rate per tonne | 2500.00 |
| default_factor | Default multiplier | 1.5 |
| is_active | Whether type is active | true |

**Extra Over Types:**
- CASTELLATING
- CURVING
- MPI (MPI Testing)
- WELD_TEST (Weld Testing)

#### 5.1.9 galvanizing_rates

Galvanizing cost build-up.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| base_dip_rate | Base galvanizing rate | 8400.00 |
| zinc_mass_factor | Mass increase from zinc | 0.075 (7.5%) |
| fettling_per_tonne | Fettling cost | 500.00 |
| delivery_per_tonne | Delivery cost | 850.00 |
| effective_from | Date rate became active | 2024-01-01 |
| is_active | Whether rate is active | true |

### 5.2 Transactional Data Tables

These tables store data specific to each tender.

#### 5.2.1 clients

Customer master data.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| name | Company name | "RPP DEVELOPMENTS" |
| contact_person | Primary contact | "Jane Doe" |
| email | Contact email | "jane@rpp.co.za" |
| phone | Contact phone | "+27 11 555 5678" |
| address | Physical address | "123 Main Street, Johannesburg" |
| is_active | Whether client is active | true |

#### 5.2.2 tenders

Main tender/quote record.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_number | Display number | "E3801" |
| project_name | Project description | "DIMAKO TRANSFORMERS MANUFACTURING FACILITY" |
| client_id | Reference to client | 1 |
| created_by_id | User who created | 3 |
| assigned_to_id | Currently assigned user | 2 |
| tender_date | Date created | 2024-11-26 |
| expiry_date | Validity end date | 2024-12-26 |
| margin_pct | Overall margin | 0.00 |
| status | Tender status | "draft" |
| notes | Internal notes | "Client prefers itemized breakdown" |
| total_tonnage | Calculated total mass | 931.62 |
| subtotal_amount | Sum before margin | 23400066.00 |
| grand_total | Final tender value | 23400066.00 |

**Status Values:**
- draft, in_progress, ready_for_review, approved, submitted, won, lost

#### 5.2.3 tender_inclusions_exclusions

Toggle switches for cost components at tender level.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_id | Reference to tender | 1 |
| include_fabrication | Include fabrication? | true |
| include_overheads | Include overheads? | true |
| include_shop_priming | Include shop priming? | false |
| include_onsite_painting | Include on-site painting? | false |
| include_delivery | Include delivery? | true |
| include_bolts | Include bolts? | true |
| include_erection | Include erection? | true |
| include_crainage | Include crainage in rates? | false |
| include_cherry_picker | Include cherry picker in rates? | false |
| include_galvanizing | Include galvanizing? | false |

#### 5.2.4 tender_site_configs

On-site parameters for crane and equipment calculations.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_id | Reference to tender | 1 |
| total_roof_area_sqm | Total roof area | 19609.00 |
| erection_rate_sqm_per_day | Area erected per day | 300.00 |
| splicing_crane_required | Extra crane for splicing? | true |
| splicing_crane_size | Crane size for splicing | "25t" |
| splicing_crane_days | Duration in days | 70 |
| misc_crane_required | Miscellaneous crane needed? | false |
| misc_crane_size | Crane size | null |
| misc_crane_days | Duration | 0 |
| program_duration_days | Calculated program length | 100 |

#### 5.2.5 tender_line_items

Bill of quantities line items.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_id | Reference to tender | 1 |
| page_number | Page from BOQ | 1 |
| item_number | Item number | 1 |
| description | Item description | "305 x 165mm x 40kg/m I-section columns" |
| unit | Unit of measure | "t" |
| quantity | Quantity | 11.19 |
| category | Item category | "Steel Sections" |
| line_type | Calculation type | "standard" |
| section_header | Grouping header | "STEEL COLUMNS AND BEAMS" |
| rate_per_unit | Calculated rate | 34700.00 |
| line_amount | Qty  Rate | 388293.00 |
| margin_amount | Margin portion | 0.00 |
| sort_order | Display order | 1 |

**Line Types:**
- standard (normal steel items)
- bolt (bolts and fasteners)
- anchor (anchor bolts with special calc)
- gutter (gutters with special calc)
- pg (P&G line)
- shop_drawings (shop drawings)
- provisional (provisional sums)

#### 5.2.6 line_item_rate_build_ups

Detailed cost breakdown for each line item.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_line_item_id | Reference to line item | 1 |
| material_supply_rate | Material cost per tonne | 17092.50 |
| fabrication_rate | Fabrication cost | 8000.00 |
| fabrication_included | Whether included | true |
| overheads_rate | Overheads cost | 4150.00 |
| overheads_included | Whether included | true |
| shop_priming_rate | Shop priming cost | 1380.00 |
| shop_priming_included | Whether included | false |
| onsite_painting_rate | On-site painting cost | 1565.00 |
| onsite_painting_included | Whether included | false |
| delivery_rate | Delivery cost | 700.00 |
| delivery_included | Whether included | true |
| bolts_rate | Bolts cost | 1500.00 |
| bolts_included | Whether included | true |
| erection_rate | Erection cost | 1800.00 |
| erection_included | Whether included | true |
| crainage_rate | Crainage cost | 1080.00 |
| crainage_included | Whether included | false |
| cherry_picker_rate | Cherry picker cost | 1430.00 |
| cherry_picker_included | Whether included | true |
| galvanizing_rate | Galvanizing cost | 11000.00 |
| galvanizing_included | Whether included | false |
| subtotal | Sum of included costs | 34672.50 |
| margin_amount | Margin | 0.00 |
| total_before_rounding | Subtotal + margin | 34672.50 |
| rounded_rate | Final rate (nearest R50) | 34700.00 |

#### 5.2.7 line_item_materials

Material supply composition for each line item (for blended material costs).

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_line_item_id | Reference to line item | 1 |
| material_supply_id | Reference to material_supply | 4 (UB_UC_LOCAL) |
| proportion | Percentage (decimal) | 0.85 (85%) |

#### 5.2.8 line_item_extra_overs

Extra over processing for specific line items.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_line_item_id | Reference to line item | 1 |
| extra_over_type_id | Reference to extra over type | 1 (CASTELLATING) |
| is_included | Whether included | true |
| rate_override | Override rate (optional) | null |
| factor_override | Override factor (optional) | null |

#### 5.2.9 tender_crane_selections

Crane selections for the tender (editable).

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_id | Reference to tender | 1 |
| crane_rate_id | Reference to crane rate | 3 (25t rental) |
| quantity | Number of cranes | 2 |
| purpose | Usage type | "main" |
| duration_days | Duration in days | 100 |
| total_cost | Calculated cost | 490000.00 |

**Purpose Values:**
- main (main erection cranes)
- splicing (splicing crane)
- miscellaneous (misc crane)

#### 5.2.10 tender_equipment_selections

Access equipment selections for the tender.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_id | Reference to tender | 1 |
| equipment_type_id | Reference to equipment | 15 (E450AJ) |
| units_required | Number of units | 5 |
| period_months | Rental duration | 5 |
| purpose | Usage description | "Main erection" |
| monthly_cost_override | Override cost (optional) | null |
| total_cost | Calculated total | 665000.00 |

#### 5.2.11 tender_preliminary_items

P&G (Preliminaries & General) items.

| Field | Description | Example |
|-------|-------------|---------|
| id | Unique identifier | 1 |
| tender_id | Reference to tender | 1 |
| item_code | Standard code (optional) | "SAFETY_FILE" |
| description | Item description | "Safety File & Audits" |
| calculation_notes | How calculated | "Standard allowance" |
| lump_sum_amount | Total amount | 30000.00 |
| rate_per_tonne | Calculated rate | 32.20 |
| is_included | Whether included | true |
| sort_order | Display order | 1 |

### 5.3 Relationships (ERD Overview)

**Master Data Relationships:**
- suppliers has many material_supply_rates
- material_supplies has many material_supply_rates
- material_supplies has many line_item_materials
- equipment_types has many tender_equipment_selections
- crane_rates has many tender_crane_selections
- extra_over_types has many line_item_extra_overs

**Tender Relationships:**
- clients has many tenders
- users has many tenders (created_by, assigned_to)
- tenders has one tender_inclusions_exclusions
- tenders has one tender_site_configs
- tenders has many tender_line_items
- tenders has many tender_crane_selections
- tenders has many tender_equipment_selections
- tenders has many tender_preliminary_items

**Line Item Relationships:**
- tender_line_items belongs to tenders
- tender_line_items has one line_item_rate_build_ups
- tender_line_items has many line_item_materials
- tender_line_items has many line_item_extra_overs

**Rate History:**
- rate_histories tracks changes to: processing_rates, materials, equipment_types, crane_rates
- Stores: rate_type, rate_id, field_changed, old_value, new_value, changed_by, timestamp

---

## 6. Calculations & Business Rules

### 6.1 Ephemeral Calculations

#### 6.1.1 Material Supply Cost Calculation

For each line item, material supply cost is calculated based on material supply type and waste percentage:

```
material_supply_rate_with_waste = base_rate_per_tonne  (1 + waste_percentage)  proportion

Example for UB_UC_LOCAL at 100% proportion:
= 15,900  (1 + 0.075)  1.0
= 15,900  1.075
= R17,092.50 per tonne
```

For blended material supplies:
```
total_material_supply_rate =  (material_supply_rate_with_waste  proportion)

Example with 85% UB/UC and 15% Plate:
= (17,092.50  0.85) + (17,775.00  0.15)
= 14,528.63 + 2,666.25
= R17,194.88 per tonne
```

#### 6.1.2 Line Item Rate Build-up

For a standard steel section line item:
```
line_rate_per_tonne =
    material_supply_rate                           -- e.g., 17,100
  + (fabrication_rate  include_fabrication)       -- 8,000  1 = 8,000
  + (overheads_rate  include_overheads)           -- 4,150  1 = 4,150
  + (shop_priming_rate  include_shop_priming)     -- 1,380  0 = 0
  + (onsite_paint_rate  include_onsite_paint)     -- 1,565  0 = 0
  + (delivery_rate  include_delivery)             -- 700  1 = 700
  + (bolts_rate  include_bolts)                   -- 1,500  1 = 1,500
  + (erection_rate  include_erection)             -- 1,800  1 = 1,800
  + (crainage_rate  include_crainage)             -- 1,080  0 = 0
  + (cherry_picker_rate  include_cherry_picker)   -- 1,430  1 = 1,430
  + (galvanizing_rate  include_galvanizing)       -- 11,000  0 = 0

subtotal = 34,680
margin = subtotal  margin_pct = 34,680  0% = 0
total = 34,680
rounded_rate = CEILING(total, 50) = R34,700
line_amount = rounded_rate  quantity = 34,700  11.19 = R388,293
```

#### 6.1.3 Equipment Cost Calculation

For each equipment selection:
```
monthly_cost = base_rate_monthly  (1 + damage_waiver_pct) + diesel_allowance_monthly

Example for 600AJ:
= 38,195  (1 + 0.06) + 19,500
= 38,195  1.06 + 19,500
= 40,486.70 + 19,500
= R59,986.70 per month

total_equipment_cost = monthly_cost  units  months
= 59,986.70  2  5
= R599,867

equipment_rate_per_tonne = total_equipment_allowance / total_tonnage
= 1,330,738 / 931.62
= R1,428.41
rounded = CEILING(1,428.41, 10) = R1,430 per tonne
```

#### 6.1.4 Crainage Calculation

```
-- Step 1: Lookup crane complement based on erection rate
crane_complement = LOOKUP(erection_rate_sqm_day, crane_complement_lookup)
wet_rate_per_day = 8,300 (for 250-350 m/day)

-- Step 2: Calculate program duration
program_duration = CEILING(total_roof_area / erection_rate_sqm_day, 1)
= CEILING(19,609 / 300, 1)
= 66 days (rounded up)

-- Step 3: Calculate main crane cost
main_crane_cost = wet_rate_per_day  program_duration
= 8,300  100 = R830,000

-- Step 4: Add splicing crane if required
splicing_crane_rate = LOOKUP(splicing_crane_size, crane_rates)
= 2,450 (for 25t)
splicing_cost = splicing_crane_rate  splicing_crane_days
= 2,450  70 = R171,500

-- Step 5: Total crane cost
total_crane_cost = main_crane_cost + splicing_cost + misc_cost
= 830,000 + 171,500 + 0 = R1,001,500

-- Step 6: Rate per tonne
crainage_rate_per_tonne = CEILING(total_crane_cost / total_tonnage, 20)
= CEILING(1,001,500 / 931.62, 20)
= CEILING(1,075.02, 20)
= R1,080 per tonne
```

#### 6.1.5 P&G Rate Calculation

```
pg_rate_per_tonne = (lump_sum_amount / total_tonnage) for all P&G items

Example:
Safety File = 30,000 / 931.62 = R32.20
Crainage (if in P&G) = 1,001,500 / 931.62 = R1,075.02  R1,080
Cherry Picker (if in P&G) = 0
Custom items = 0

subtotal = 32.20 + 1,080 = R1,112.20
rounded_rate = CEILING(1,112.20, 50) = R1,150
pg_line_amount = rounded_rate  total_tonnage  1
= 1,150  931.62  1 = R1,071,363
```

#### 6.1.6 Galvanizing Rate Build-up

```
galvanizing_rate = base_dip_rate  (1 + zinc_mass_factor) + fettling + delivery

= 8,400  (1 + 0.075) + 500 + 850
= 8,400  1.075 + 1,350
= 9,030 + 1,350
= R10,380 per tonne (rounded to ~R11,000 in practice)
```

#### 6.1.7 Shop Drawings Calculation

```
shop_drawings_qty = total_tonnage (sum of all tonne items)
= 931.62 tonnes

shop_drawings_rate = shop_drawings_base_rate
= R350 per tonne

subtotal = 931.62  350 = R326,067
margin = subtotal  margin_pct = 0
total = R326,067
rounded_rate = CEILING(350, 50) = R350 (already on boundary)
line_amount = R326,067
```

### 6.2 Business Rules Summary

| Rule ID | Rule Name | Description | Formula/Logic |
|---------|-----------|-------------|---------------|
| BR-001 | Rate Rounding | All line item rates rounded up to nearest R50 | `CEILING(rate, 50)` |
| BR-002 | Crainage Rounding | Crainage rate rounded to nearest R20 | `CEILING(rate, 20)` |
| BR-003 | Cherry Picker Rounding | Cherry picker rate rounded to nearest R10 | `CEILING(rate, 10)` |
| BR-004 | Waste Application | Waste percentage applied to base material supply rate before aggregation | `base_rate  (1 + waste_percentage)` |
| BR-005 | Toggle Application | Boolean flags multiply rate by 0 or 1 | `rate  include_flag` |
| BR-006 | Margin Calculation | Applied to subtotal before rounding | `subtotal  (1 + margin_pct)` |
| BR-007 | Bolts Inclusion | Standard line items include bolts in rate (not priced separately) | Default behavior for steel sections |
| BR-008 | Lump Sum Distribution | Fixed costs (safety file, etc.) divided by total tonnage | `lump_sum / total_tonnage` |
| BR-009 | CFLC Fabrication | CFLC and cold-rolled items always have fabrication = 0 | Auto-set based on category |
| BR-010 | Damage Waiver | Access equipment always includes 6% damage waiver | `base_rate  1.06` |
| BR-011 | Bolt Threshold | If bolts > 2.5% of total tonnage, include in rates for competitiveness | Manual decision, system flags |
| BR-012 | Crane Mutual Exclusion | Crainage included in line items OR P&G, not both | `include_crainage` toggle |
| BR-013 | Cherry Picker Mutual Exclusion | Cherry picker included in line items OR P&G, not both | `include_cherry_picker` toggle |
| BR-014 | Version Numbering | Rate updates versioned with format `rates_YYYYMMDDxx` | Auto-generated on save |
| BR-015 | Default Supplier Selection | Default to second-cheapest supplier rate | Auto-selection with override |
| BR-016 | Plate Allocation Default | Default 15% plate allocation for steel sections | Configurable at tender level |
| BR-017 | CFLC Plate Exception | CFLC items default to 0% plate allocation | Auto-set based on category |

### 6.3 Edge Cases

| Case ID | Scenario | Expected Behavior |
|---------|----------|-------------------|
| EC-001 | Zero quantity line item | Calculate rate normally; line amount = 0 |
| EC-002 | Missing material rate | Flag error; do not calculate; require resolution |
| EC-003 | Negative quantity | Reject; quantities must be positive |
| EC-004 | Zero tonnage tender | Flag warning; P&G calculations will fail |
| EC-005 | All toggles off | Calculate material cost only; warn user |
| EC-006 | Crainage in both item and P&G | System prevents; mutual exclusion enforced |
| EC-007 | No crane complement match | Use nearest bracket; warn user |
| EC-008 | Rate effective date in future | Do not use until effective_from date reached |
| EC-009 | Multiple materials sum > 100% | Reject; proportions must sum to 100% |
| EC-010 | Bolt line items in tonnage | Exclude from shop drawings tonnage sum |
| EC-011 | Paint items in tonnage | Exclude from total tonnage to avoid double-count |

---

## 7. Outputs & Reporting

### 7.1 Output Tables

#### 7.1.1 Tender Line Output

The system calculates and stores the following for each line item:

| Field | Description | Example |
|-------|-------------|---------|
| page | Page from BOQ | 1 |
| item | Item number | 1 |
| description | Item description | "305 x 165mm x 40kg/m I-section columns" |
| unit | Unit of measure | "t" |
| quantity | Quantity | 11.19 |
| rate | Calculated rate (rounded) | 34,700.00 |
| line_total | Qty  Rate | 388,293.00 |

#### 7.1.2 Tender Summary

| Field | Description | Example Value |
|-------|-------------|---------------|
| tender_number | Tender reference | "E3801" |
| project_name | Project description | "DIMAKO TRANSFORMERS..." |
| client_name | Client | "RPP DEVELOPMENTS" |
| tender_date | Date prepared | "26 November 2024" |
| expiry_date | Valid until | "26 December 2024" |
| total_tonnage | Total steel mass | 931.62 tonnes |
| pg_total | P&G amount | R1,071,363.00 |
| shop_drawings_total | Shop drawings amount | R326,067.00 |
| steel_work_total | All steel items | R22,002,636.00 |
| tender_subtotal | Sum of all lines | R23,400,066.00 |
| margin_total | Total margin | R0.00 |
| tender_grand_total | Final tender value | R23,400,066.00 |

### 7.2 Documents & Artifacts

#### 7.2.1 Tender PDF Document

**Purpose**: Client-facing tender document for submission

**Contents**:
1. **Header**
   - RSB Contracts logo
   - Company address and contact details
   - Tender reference number
   - Date
   - Client name and address

2. **Project Information**
   - Project name
   - Site location (if applicable)
   - Tender validity period

3. **Line Items by Section**
   - Section headers (e.g., "STEEL COLUMNS AND BEAMS")
   - Line items: Page, Item, Description, Unit, Qty, Rate, Amount
   - Section subtotals

4. **Summary**
   - P&G total
   - Shop drawings total
   - Steel work total
   - Grand total (excluding VAT)
   - VAT (if applicable)
   - Grand total (including VAT)

5. **Qualifications & Terms**
   - Standard qualifications
   - Exclusions
   - Payment terms
   - Validity period

6. **Footer**
   - Page numbers
   - RSB contact information

#### 7.2.2 Internal Cost Report

**Purpose**: Internal document showing full cost breakdown

**Contents**:
- All tender PDF contents PLUS:
- Rate build-up detail for each line item
- Material breakdown with supplier rates
- Equipment cost breakdown
- Crane cost breakdown
- P&G item details
- Margin analysis

#### 7.2.3 Rate Sheet Export

**Purpose**: Export current rates for backup/audit

**Contents**:
- All processing rates with effective dates
- All material rates with waste factors
- All equipment rates
- All crane rates
- Version number and export date

### 7.3 Sample Layouts

#### 7.3.1 Tender Line Item Table Layout

```
+------+------+----------------------------------------+------+--------+------------+---------------+
| Page | Item | Description                            | Unit |   Qty  |    Rate    |   Amount      |
+------+------+----------------------------------------+------+--------+------------+---------------+
|      |      | STEEL COLUMNS AND BEAMS                |      |        |            |               |
+------+------+----------------------------------------+------+--------+------------+---------------+
|  1   |  1   | 305 x 165mm x 40kg/m I-section columns |  t   |  11.19 |  34,700.00 |    388,293.00 |
|  1   |  2   | 686 x 254mm x 125kg/m I-section beams  |  t   |   5.96 |  34,700.00 |    206,812.00 |
|  1   |  3   | 610 x 305mm x 238kg/m I-section beams  |  t   |   2.63 |  34,700.00 |     91,261.00 |
+------+------+----------------------------------------+------+--------+------------+---------------+
|      |      | Section Subtotal                       |      |  19.78 |            |    686,366.00 |
+------+------+----------------------------------------+------+--------+------------+---------------+
```

#### 7.3.2 Rate Build-up Detail Layout

```
Line Item: 305 x 165mm x 40kg/m I-section columns
Category: Steel Sections
Unit: t | Qty: 11.19

Cost Component          | Rate/t    | Include | Amount/t
------------------------|-----------|---------|----------
Material Supply         | 17,092.50 |    -    | 17,092.50
    UB/UC Local (100%) | 15,900.00 |         |
    Waste (7.5%)       |  1,192.50 |         |
Fabrication             |  8,000.00 |   Yes   |  8,000.00
Overheads               |  4,150.00 |   Yes   |  4,150.00
Shop Priming            |  1,380.00 |   No    |      0.00
On-Site Painting        |  1,565.00 |   No    |      0.00
Delivery                |    700.00 |   Yes   |    700.00
Bolts                   |  1,500.00 |   Yes   |  1,500.00
Erection                |  1,800.00 |   Yes   |  1,800.00
Crainage                |  1,080.00 |   No    |      0.00
Cherry Picker           |  1,430.00 |   Yes   |  1,430.00
Galvanizing             | 11,000.00 |   No    |      0.00
------------------------|-----------|---------|----------
Subtotal                |           |         | 34,672.50
Margin (0%)             |           |         |      0.00
Total                   |           |         | 34,672.50
Rounded Rate            |           |         | 34,700.00
------------------------|-----------|---------|----------
Line Amount (11.19  34,700) =      |         | 388,293.00
```

---

## 8. Roles, Permissions, and Audit

### 8.1 Role Matrix

| Permission | Admin | QS | Buyer | Office Staff | Viewer |
|------------|-------|-----|-------|--------------|--------|
| **Tenders** |
| Create tender | Yes | Yes | No | Yes | No |
| Edit tender | Yes | Yes | No | Limited | No |
| Delete tender | Yes | No | No | No | No |
| View tender | Yes | Yes | Yes | Yes | Yes |
| Submit tender | Yes | Yes | No | No | No |
| Approve tender | Yes | No | No | No | No |
| **Line Items** |
| Add/edit line items | Yes | Yes | No | Yes | No |
| Delete line items | Yes | Yes | No | No | No |
| Edit inclusions/exclusions | Yes | Yes | No | No | No |
| **Rates** |
| View processing rates | Yes | Yes | Yes | Yes | Yes |
| Edit processing rates | Yes | No | No | No | No |
| View material rates | Yes | Yes | Yes | Yes | Yes |
| Edit material rates | Yes | No | Yes | No | No |
| View equipment rates | Yes | Yes | Yes | Yes | Yes |
| Edit equipment rates | Yes | No | No | No | No |
| View crane rates | Yes | Yes | Yes | Yes | Yes |
| Edit crane rates | Yes | No | No | No | No |
| **Suppliers** |
| View suppliers | Yes | Yes | Yes | Yes | Yes |
| Add/edit suppliers | Yes | No | Yes | No | No |
| **Clients** |
| View clients | Yes | Yes | Yes | Yes | Yes |
| Add/edit clients | Yes | Yes | No | Yes | No |
| **Reports** |
| View tender reports | Yes | Yes | Yes | Yes | Yes |
| Export reports | Yes | Yes | No | No | No |
| **System** |
| Manage users | Yes | No | No | No | No |
| View audit logs | Yes | Yes | No | No | No |

### 8.2 What's Logged / Versioned

#### 8.2.1 Audit Log Events

| Event Type | Data Logged |
|------------|-------------|
| Tender Created | tender_id, created_by, timestamp |
| Tender Modified | tender_id, modified_by, timestamp, fields_changed |
| Tender Status Changed | tender_id, old_status, new_status, changed_by, timestamp |
| Tender Deleted | tender_id, deleted_by, timestamp, reason |
| Line Item Added | line_item_id, tender_id, added_by, timestamp |
| Line Item Modified | line_item_id, modified_by, timestamp, fields_changed |
| Line Item Deleted | line_item_id, deleted_by, timestamp |
| Inclusion Changed | tender_id, field, old_value, new_value, changed_by, timestamp |
| Rate Override Applied | tender_id, line_item_id, rate_type, override_value, applied_by, timestamp |

#### 8.2.2 Rate History

All rate changes are versioned:

| Field | Description |
|-------|-------------|
| rate_type | Table name (processing_rates, materials, etc.) |
| rate_id | Record ID |
| field_changed | Field that changed |
| old_value | Previous value |
| new_value | New value |
| changed_by | User who made change |
| version_number | Format: `rates_YYYYMMDDxx` |
| timestamp | When change occurred |

### 8.3 When Snapshots Are Taken

| Event | What's Snapshotted |
|-------|-------------------|
| Tender Submitted | All rates used in tender, all calculations, all line items |
| Rate Sheet Saved | Complete rate sheet with version number |
| Tender Won | Final tender state for budget comparison |
| Monthly Close | All active rate sheets |

---

## 9. Open Questions, Risks, Assumptions

### 9.1 Open Questions

| ID | Question | Context | Status |
|----|----------|---------|--------|
| OQ-001 | What approval threshold requires director sign-off? | Richard mentioned oversight for major quotes | Pending |
| OQ-002 | How should historical tenders be migrated? | Need to determine scope of migration | Pending |
| OQ-003 | Are there multi-currency requirements? | All examples in ZAR | Assumed ZAR only |
| OQ-004 | What is the retention period for tender records? | Compliance requirements | Pending |
| OQ-005 | Should BOQ templates be created for common project types? | "Standard Lines (Copy)" sheet exists | Pending |
| OQ-006 | How should provisional sums be handled? | Plant room/office roof examples | Partially defined |
| OQ-007 | Are there project types beyond commercial and mining? | Fabrication factors differ | Need confirmation |
| OQ-008 | What crane sizes does RSB currently own? | Affects RSB-owned vs rental selection | Pending |
| OQ-009 | How to handle BOQs received as PDF? | Current process is manual entry | Manual entry confirmed |
| OQ-010 | Should system support multiple concurrent users on same tender? | Collaboration scenario | Pending |

### 9.2 Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R-001 | Users resist change from familiar Excel | High | Medium | Phased rollout, training, keep Excel export |
| R-002 | Rate calculation discrepancies vs Excel | Medium | High | Extensive testing, parallel running period |
| R-003 | Data migration errors | Medium | High | Validation scripts, manual verification |
| R-004 | Integration gaps with future budget system | Low | Medium | Design with extensibility in mind |
| R-005 | Performance with large tenders | Low | Medium | Optimize calculations, consider caching |
| R-006 | Offline access requirements | Low | Low | Web-based MVP; offline considered later |

### 9.3 Assumptions

| ID | Assumption | Rationale |
|----|------------|-----------|
| A-001 | All users have internet access | Web-based application |
| A-002 | Currency is ZAR only | No mention of multi-currency in requirements |
| A-003 | BOQs will be provided as CSV or manual entry | Excel to CSV conversion required |
| A-004 | 6% damage waiver is constant | Richard confirmed "always 6%" |
| A-005 | Processing rates update annually | Richard confirmed annual updates |
| A-006 | Material rates update monthly | Maria's current process |
| A-007 | Tender validity is 30 days default | Elmarie confirmed |
| A-008 | One QS reviews each tender | Demi is primary reviewer |
| A-009 | No integration with external systems in Phase 1 | Scope defined |
| A-010 | Users operate in same timezone | RSB is single-location |

### 9.4 Deferred Features

Per Richard's guidance: *"I wouldn't do that in the beginning... once the whole system's working and there's no bugs"*

| ID | Feature | Reason for Deferral |
|----|---------|---------------------|
| DF-001 | Automatic bolt threshold detection (2.5%) | Complex logic, manual decision preferred initially |
| DF-002 | AI-powered material type auto-classification | Needs training data, manual override sufficient |
| DF-003 | Supplier integration/EDI | Future phase |
| DF-004 | Budget tracking module | Out of Phase 1 scope |
| DF-005 | Claims processing | Out of Phase 1 scope |
| DF-006 | Mobile application | Web-first approach |
| DF-007 | Multi-company support | Single company initially |
| DF-008 | Automated approval workflows | Manual process sufficient initially |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-27 | Draft | Initial comprehensive requirements document |

---

## References

- TECHNICAL_REQUIREMENTS.md - Detailed database schema and Rails implementation
- EXCEL_ANALYSIS.md - Analysis of current Excel workbook structure
- Conversation transcripts: Nov-11, Nov-18, Nov-24, Nov-26 2025
