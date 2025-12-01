Walk me through the structure of this workbook: summarize the key inputs, calculations, and outputs, any important relationships between sheets, and the overall purpose of the analysis. It is very important that we understand the following things: Key input cells and where they feed into
All formulas with their dependencies mapped
Lookup tables and their structure
Conditional logic (IF statements, toggles)
Any VBA/macros if present
Hidden sheets or columns
Named ranges

Now I have a comprehensive view of the workbook. Let me compile a complete analysis:

---

# Workbook Structure Analysis: Structural Steel Tender/Costing Model

## 📋 Overall Purpose

This is a **Structural Steel Tendering and Costing Model** for RSB Contracts, used to prepare competitive bids for steel fabrication and installation projects. The current project is **"DIMAKO TRANSFORMERS MANUFACTURING FACILITY BUILDING"** for client **RPP DEVELOPMENTS**.

The model calculates pricing for ~932 tonnes of structural steel including columns, beams, trusses, girders, purlins, gutters, and related work.

---

## 🗂️ Sheet Structure & Relationships

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          DATA FLOW DIAGRAM                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐ │
│  │   TENDER DATA    │────▶│  COSTING SHEET   │────▶│     PAGE 1       │ │
│  │  (Item Master)   │     │  (Calculations)  │     │ (Tender Output)  │ │
│  └──────────────────┘     └────────┬─────────┘     └──────────────────┘ │
│                                    │                                     │
│  ┌──────────────────┐              │                                     │
│  │   RATES PAGE     │──────────────┤                                     │
│  │ (Input Rates)    │              │                                     │
│  └──────────────────┘              │                                     │
│                                    │                                     │
│  ┌──────────────────┐              │                                     │
│  │ ACCESS EQUIPMENT │──────────────┘                                     │
│  │ (Crane/Lifts)    │                                                    │
│  └──────────────────┘                                                    │
│                                                                          │
│  ┌──────────────────┐     ┌──────────────────┐                          │
│  │ DATA SHEET LOCKED│     │ STANDARD LINES   │                          │
│  │ (Lookup Tables)  │     │ (Templates)      │                          │
│  └──────────────────┘     └──────────────────┘                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📥 KEY INPUT CELLS & WHERE THEY FEED

### **1. Rates Page (Sheet ID: 2)** - Primary Input Sheet

| Cell | Description | Value | Feeds Into |
|------|-------------|-------|------------|
| [B5](citation:2!B5) | **EST RSB Margin** | 0% | Costing Sheet margin calculations |
| [B16](citation:2!B16) | Shop Drawings Rate | R350/t | Costing Sheet E28 |
| [B17](citation:2!B17) | Fabrication Rate | R8,000/t | All line item calculations |
| [B18](citation:2!B18) | Overheads Rate | R4,150/t | All line item calculations |
| [B19](citation:2!B19) | Shop Priming Rate | R1,380/t | Line items where priming included |
| [B20](citation:2!B20) | On-Site Painting | R1,565/t | Line items where painting included |
| [B21](citation:2!B21) | Delivery (9t/load) | R700/t | All line item calculations |
| [B22](citation:2!B22) | Bolts (2% cap) | R1,500/t | Line items with bolts |
| [B23](citation:2!B23) | Erection Rate | R1,800/t | Line items with erection |
| [B24](citation:2!B24) | **Crainage/tonne** | R1,080/t | Calculated from H48/C9 |
| [B25](citation:2!B25) | **Cherry Pickers/t** | R1,430/t | Calculated from Access Equipment |
| [B26](citation:2!B26) | Galvanizing Rate | R11,000/t | Line items requiring galvanizing |
| [B33](citation:2!B33) | Safety File & Audits | R30,000 | P&G calculations |

### **Toggle Switches** (1=Include, 0=Exclude):
| Cell | Description | Current |
|------|-------------|---------|
| [F21](citation:2!F21) | Include Fabrication? | 1 (Yes) |
| [F22](citation:2!F22) | Include Overheads? | 1 (Yes) |
| [F23](citation:2!F23) | Include Primer? | 0 (No) |
| [F24](citation:2!F24) | Include Final Paint? | 0 (No) |
| [F25](citation:2!F25) | Include Delivery? | 1 (Yes) |
| [F26](citation:2!F26) | Include Bolts? | 1 (Yes) |
| [F27](citation:2!F27) | Include Erection? | 1 (Yes) |
| [F28](citation:2!F28) | Include Crainage? | 0 (No) |
| [F29](citation:2!F29) | Include Cherry Pickers? | 0 (No) |
| [F30](citation:2!F30) | Is Steel Galvanized? | 0 (No) |

### **Material Supply Rates (Lookup Table):**
| Cells | Material Type | Waste % | Rate/t |
|-------|--------------|---------|--------|
| [B35:C35](citation:2!B35:C35) | Unequal Angles | 7.5% | R18,800 |
| [B36:C36](citation:2!B36:C36) | Equal Angles | 7.5% | R12,850 |
| [B38:C38](citation:2!B38:C38) | Local UB & UC | 7.5% | R15,900 |
| [B39:C39](citation:2!B39:C39) | Import UB & UC | 7.5% | R16,170 |
| [B45:C45](citation:2!B45:C45) | Standard Hollow | 10% | R20,980 |
| [B52:C52](citation:2!B52:C52) | Metsec 1.6mm | 0% | R21,250 |

---

### **2. Access Equipment (Sheet ID: 37)** - Equipment Costing

**Key Inputs:**
| Cell | Description | Feeds Into |
|------|-------------|------------|
| [G22](citation:37!G22) | # Units Required (E450AJ) | 5 units |
| [H22](citation:37!H22) | Period Required | 5 months |
| [G29](citation:37!G29) | # Units (600AJ) | 2 units |
| [H29](citation:37!H29) | Period Required | 5 months |

**Key Outputs:**
- [I42](citation:37!I42): **Total Equipment Allowance** = R1,330,738
- [I44](citation:37!I44): **Rate/Tonne** = R1,428.41 → feeds Rates Page B25

---

### **3. Tender Data (Sheet ID: 36)** - Item Master Database

Contains 50 line items with:
- Column A: Page number
- Column B: Item number
- Column C: Description (e.g., "305 x 165mm x 40kg/m I-section columns")
- Column D: Unit (t, No, m2, Item)
- Column E: Quantity
- Column G: Category (Steel Sections, Bolts, Gutter Meter, etc.)

**Example entries:**
| Row | Description | Unit | Qty |
|-----|-------------|------|-----|
| 1 | 305x165mm I-section columns | t | 11.19 |
| 4 | Crane beam 630x16mm | t | 343.48 |
| 6 | HD Bolts M32 | No | 464 |

---

## 🔢 FORMULA DEPENDENCIES MAPPED

### **Costing Sheet (Sheet ID: 6)** - Calculation Engine

**Line Item Structure (repeating every 19 rows):**
```
Row Pattern:
+0  Page Number      =INDEX('Tender Data'!A:A, INT(ROW()/19))
+0  Item Number      =INDEX('Tender Data'!B:B, INT(ROW()/19))
+0  Description      =INDEX('Tender Data'!C:C, INT(ROW()/19))
+0  Unit             =INDEX('Tender Data'!D:D, INT(ROW()/19))
+0  Quantity         =INDEX('Tender Data'!E:E, INT(ROW()/19))
+0  Rate             =CEILING(Total,50)
+0  Amount           =Qty × Rate

Sub-calculations:
+4  Material Supply  =Rate × (1 + Waste%)
+5  Fabrication      =Toggle × Rate Page Rate
+6  Overheads        =Toggle × Rate Page Rate
...etc.
+15 SUB TOTAL        =SUM(cost components)
+16 Margin           =SubTotal × Margin%
+17 TOTAL            =SubTotal + Margin
```

### **Material Cost Calculation (Complex IF Formula):**
Located in columns L-O of Costing Sheet, uses 22-level nested IF to match material type to rate:
```excel
=IF(K39="Material Supply UnEqual Angles",'Rates Page'!$B$35,
 IF(K39="Material Supply Equal Angles",'Rates Page'!$B$36,
 IF(K39="Material Supply Large Equal Angles",'Rates Page'!$B$37,
 ...22 conditions...)))
```

### **P&G Calculation (Costing Sheet rows 3-20):**
```excel
F3 (P&G Total) = F5 × E5
F5 (Rate/t)    = CEILING(F20, 50)
F9-F17         = Individual P&G components from Rates Page
F20 (Total)    = SUM(F18:F19) where F18=SUM(F9:F17)
```

---

## 📊 LOOKUP TABLES

### **1. DATA SHEET LOCKED (Sheet ID: 35)** - Reference Tables

**Mobile Crane Rates:**
| Size | All-Inclusive/Day | Dry Rate | Diesel |
|------|-------------------|----------|--------|
| 90t | R13,500 | R12,500 | R1,000 |
| 50t | R9,350 | R8,500 | R850 |
| 25t | R2,450 | R1,660 | R750 |

**Crane Compliment by Area (used by H37 on Rates Page):**
| Area/Day | Crane Compliment | Wet Rate/Day |
|----------|-----------------|--------------|
| 0-150m² | 1 x 25t | R2,450 |
| 150-250m² | 2 x 25t | R4,900 |
| 250-350m² | 1x10t + 2x25t | R8,300 |

**Complex Lookup Formula (Rates Page H37):**
```excel
=IF(F37=0, 0, INDEX('DATA SHEET LOCKED'!$C$15:$C$19, 
  MATCH(1, ('Rates Page'!F37>=--LEFT('DATA SHEET LOCKED'!$A$15:$A$19,
  SEARCH("m²",'DATA SHEET LOCKED'!$A$15:$A$19)-1)) * 
  ('Rates Page'!F37<=--MID(...)), 0)))
```

### **2. Material Type → Rate Lookup (Rates Page B35:C56)**
22 material types with associated waste percentages and rates per tonne.

---

## ⚙️ CONDITIONAL LOGIC (IF Statements & Toggles)

### **Cost Component Toggles:**
Each line item uses toggles from Rates Page F21:F30:
```excel
F40 (Fabrication) = D40 × E40  where D40 = 'Rates Page'!$F$21 (1 or 0)
F41 (Overheads)   = D41 × E41  where D41 = 'Rates Page'!$F$22 (1 or 0)
```

### **Crane Equipment Logic (Rates Page):**
```excel
H38 = IF(F38="Yes", IF(G38<>"", XLOOKUP(G38,'DATA SHEET LOCKED'!$A$4:$A$10,
      'DATA SHEET LOCKED'!$B$4:$B$10,"Not Found"), ""), "")
```
If "Splicing Crane Required" = Yes AND crane size specified, lookup rate.

### **Error Handling:**
```excel
B24 = IFERROR(CEILING(H48/C9, 20), 0)  -- Crainage rate with error protection
```

---

## 🔒 VBA/Macros

**No VBA macros detected** in this workbook based on the sheet analysis.

---

## 👁️ Hidden Sheets/Columns

**No hidden sheets detected** - all 7 sheets are visible:
1. Page 1
2. Rates Page
3. Access Equipment
4. Costing Sheet
5. Standard Lines (Copy)
6. DATA SHEET LOCKED
7. Tender Data

**Note:** Some columns in Costing Sheet (K-O) contain parallel material breakdown calculations that aren't directly visible in the tender output but feed material costs.

---

## 📛 Named Ranges

**No explicit named ranges detected** in the data examined. The model relies on:
- Direct cell references (e.g., `'Rates Page'!$B$17`)
- INDEX/MATCH for dynamic lookups
- Row-based calculations using `INT(ROW()/19)` pattern

---

## 📊 Key Outputs

| Sheet | Cell | Description | Value |
|-------|------|-------------|-------|
| Page 1 | [G47](citation:1!G47) | Sub Total (Page 1) | R23,844,238 |
| Page 1 | [G97](citation:1!G97) | Sub Total (Page 2) | R30,441,383 |
| Rates Page | [C9](citation:2!C9) | Total Job Mass | 931.62 tonnes |
| Rates Page | [C7](citation:2!C7) | Total Margin | R54,158 |

---

## ⚠️ Issues Identified

1. **#REF! Error** in [C12](citation:2!C12) on Rates Page - formula references deleted cells
2. **One formula result shows #REF!** indicating broken references from prior row/column deletions
3. Cell [E14](citation:1!E14) on Page 1 has complex sum excluding certain bolt tonnages - verify intentional

---

## 💡 Recommendations for Use

1. **To adjust pricing**: Modify rates in [Rates Page B16:B33](citation:2!B16:B33)
2. **To include/exclude cost components**: Toggle 1/0 in [Rates Page F21:F30](citation:2!F21:F30)
3. **To add new line items**: Add to [Tender Data](citation:36) sheet - Costing Sheet auto-calculates
4. **To adjust equipment costs**: Modify units/periods in [Access Equipment G/H columns](citation:37!G22:H29)

Would you like me to dive deeper into any specific area, fix the #REF! error, or create a visual diagram of the formula dependencies?