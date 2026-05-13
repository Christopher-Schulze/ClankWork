---
name: xlsx
description: "Spreadsheet operations (.xlsx, .xlsm, .csv, .tsv) - read, create, edit, format, chart, clean data. Trigger when a spreadsheet is the input or output: formulas, formatting, data cleanup, financial models, CSV import. Uses openpyxl (read+write), xlsxwriter (write-heavy), pandas (analysis). Not for DOCX, HTML, or Google Sheets."
license: MIT
---

# XLSX Skill - Spreadsheet Operations

## Output Standards

### Font
- Use a consistent, professional font (e.g., Arial, Times New Roman) unless the user specifies otherwise

### Zero Formula Errors
- Every Excel model MUST be delivered with ZERO formula errors (#REF!, #DIV/0!, #VALUE!, #N/A, #NAME?)

### Preserve Existing Templates (when updating templates)
- Study and EXACTLY match existing format, style, and conventions when modifying files
- Never impose standardized formatting on files with established patterns
- Existing template conventions ALWAYS override these guidelines

## Financial models

### Color Coding Standards
Unless otherwise stated by the user or existing template

#### Industry-Standard Color Conventions
- **Blue text (RGB: 0,0,255)**: Hardcoded inputs, and numbers users will change for scenarios
- **Black text (RGB: 0,0,0)**: ALL formulas and calculations
- **Green text (RGB: 0,128,0)**: Links pulling from other worksheets within same workbook
- **Red text (RGB: 255,0,0)**: External links to other files
- **Yellow background (RGB: 255,255,0)**: Key assumptions needing attention or cells that need to be updated

### Number Formatting Standards

#### Required Format Rules
- **Years**: Format as text strings (e.g., "2024" not "2,024")
- **Currency**: Use $#,##0 format; ALWAYS specify units in headers ("Revenue ($mm)")
- **Zeros**: Use number formatting to make all zeros "-", including percentages (e.g., "$#,##0;($#,##0);-")
- **Percentages**: Default to 0.0% format (one decimal)
- **Multiples**: Format as 0.0x for valuation multiples (EV/EBITDA, P/E)
- **Negative numbers**: Use parentheses (123) not minus -123

### Formula Construction Rules

#### Assumptions Placement
- Place ALL assumptions (growth rates, margins, multiples, etc.) in separate assumption cells
- Use cell references instead of hardcoded values in formulas
- Example: Use =B5*(1+$B$6) instead of =B5*1.05

#### Formula Error Prevention
- Verify all cell references are correct
- Check for off-by-one errors in ranges
- Ensure consistent formulas across all projection periods
- Test with edge cases (zero values, negative numbers)
- Verify no unintended circular references

#### Documentation Requirements for Hardcodes
- Comment or in cells beside (if end of table). Format: "Source: [System/Document], [Date], [Specific Reference], [URL if applicable]"
- Examples:
  - "Source: Company 10-K, FY2024, Page 45, Revenue Note, [SEC EDGAR URL]"
  - "Source: Company 10-Q, Q2 2025, Exhibit 99.1, [SEC EDGAR URL]"
  - "Source: Bloomberg Terminal, 8/15/2025, AAPL US Equity"
  - "Source: FactSet, 8/20/2025, Consensus Estimates Screen"

# Working with Excel Files

## Tool Selection

Three libraries are available, each for a different purpose. Pick the right one for the task.

## Reading and Analyzing Data

### Einlesen - Drei Methoden

| Method | Use case |
|--------|----------|
| **markitdown** | Fastest: agent reads/analyzes content, every sheet as Markdown table |
| **pandas** | Data analysis, statistics, bulk manipulation, DataFrames |
| **openpyxl** | Full cell access: formulas, formatting, named ranges, structure inspection |

#### 1. markitdown (Schnellste Methode fur Agent-Analyse)

```python
from markitdown import MarkItDown

result = MarkItDown().convert("spreadsheet.xlsx")
print(result.text_content)  # All sheets as Markdown tables

# Also works with CSV, TSV, ODS
result_csv = MarkItDown().convert("data.csv")
```

Use markitdown when you need to understand the content of a file to decide what changes to make. Every sheet is rendered as a Markdown table - fast, no boilerplate, ready for agent reasoning.

#### 2. pandas (Datenanalyse & Manipulation)

```python
import pandas as pd

df = pd.read_excel('file.xlsx')                        # First sheet
all_sheets = pd.read_excel('file.xlsx', sheet_name=None)  # All sheets as dict

df.head()      # Preview
df.info()      # Column info + types
df.describe()  # Statistics

# Type control
df = pd.read_excel('file.xlsx', dtype={'id': str}, parse_dates=['date_col'])
# Large files: specific columns only
df = pd.read_excel('file.xlsx', usecols=['A', 'C', 'E'])

df.to_excel('output.xlsx', index=False)
```

#### 3. openpyxl (Vollzugriff: Formeln, Formatierung, Struktur)

```python
from openpyxl import load_workbook

wb = load_workbook('file.xlsx')           # formulas as strings (default)
wb_val = load_workbook('file.xlsx', data_only=True)  # last cached values

for name in wb.sheetnames:
    ws = wb[name]
    print(f"{name}: {ws.dimensions}, {ws.max_row} rows x {ws.max_column} cols")
    for row in ws.iter_rows(min_row=1, max_row=5, values_only=True):
        print(row)
```

**Warning**: If opened with `data_only=True` and saved, formulas are permanently replaced with values.

## Excel File Workflows

## Formulas Over Hardcoded Values

**Always use Excel formulas instead of calculating values in Python and hardcoding them.** This ensures the spreadsheet remains dynamic and updateable.

### ❌ WRONG - Hardcoding Calculated Values
```python
# Bad: Calculating in Python and hardcoding result
total = df['Sales'].sum()
sheet['B10'] = total  # Hardcodes 5000

# Bad: Computing growth rate in Python
growth = (df.iloc[-1]['Revenue'] - df.iloc[0]['Revenue']) / df.iloc[0]['Revenue']
sheet['C5'] = growth  # Hardcodes 0.15

# Bad: Python calculation for average
avg = sum(values) / len(values)
sheet['D20'] = avg  # Hardcodes 42.5
```

### ✅ CORRECT - Using Excel Formulas
```python
# Good: Let Excel calculate the sum
sheet['B10'] = '=SUM(B2:B9)'

# Good: Growth rate as Excel formula
sheet['C5'] = '=(C4-C2)/C2'

# Good: Average using Excel function
sheet['D20'] = '=AVERAGE(D2:D19)'
```

This applies to ALL calculations - totals, percentages, ratios, differences, etc. The spreadsheet should be able to recalculate when source data changes.

## Common Workflow
1. **Choose tool**: pandas for data, openpyxl for formulas/formatting, xlsxwriter for write-heavy rich formatting
2. **Create/Load**: Create new workbook or load existing file
3. **Modify**: Add/edit data, formulas, and formatting
4. **Save**: Write to file
5. **Formula recalculation**: Formulas written as strings by openpyxl are recalculated automatically when the user opens the file in Excel or Numbers. No separate recalculation step needed.
6. **Verify formula correctness**: Review cell references manually before saving:
   - `#REF!`: Invalid cell references
   - `#DIV/0!`: Division by zero - add IF guard
   - `#VALUE!`: Wrong data type
   - `#NAME?`: Unrecognized function name

### Creating new Excel files

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side, numbers
from openpyxl.utils import get_column_letter, column_index_from_string
from openpyxl.utils.dataframe import dataframe_to_rows

wb = Workbook()
sheet = wb.active
sheet.title = "Report"

# Write data
sheet['A1'] = 'Header'
sheet.append(['Row', 'of', 'data'])

# Formula
sheet['B2'] = '=SUM(A1:A10)'

# Font, fill, alignment
sheet['A1'].font = Font(bold=True, name="Arial", size=11, color="FFFFFF")
sheet['A1'].fill = PatternFill("solid", start_color="2E74B5")
sheet['A1'].alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

# Number formats
sheet['B2'].number_format = '$#,##0.00'
sheet['C2'].number_format = '0.0%'
sheet['D2'].number_format = '#,##0;(#,##0);-'   # parentheses for negatives, dash for zero

# Borders
thin = Side(style="thin", color="CCCCCC")
thick = Side(style="medium", color="2E74B5")
sheet['A1'].border = Border(bottom=thick, right=thin)
# All-sides thin border:
all_thin = Border(left=thin, right=thin, top=thin, bottom=thin)
for row in sheet.iter_rows(min_row=2, max_row=10, min_col=1, max_col=4):
    for cell in row:
        cell.border = all_thin

# Column widths and row heights
sheet.column_dimensions['A'].width = 25
sheet.column_dimensions['B'].width = 14
sheet.row_dimensions[1].height = 30

# Freeze panes (freeze rows above and columns left of the specified cell)
sheet.freeze_panes = 'B2'  # freeze row 1 and column A

# Auto-filter
sheet.auto_filter.ref = sheet.dimensions  # or "A1:D100"

# Column letter utilities (critical for dynamic column mapping)
col_letter = get_column_letter(5)   # -> "E"
col_index = column_index_from_string("BL")  # -> 64

# pandas DataFrame -> openpyxl sheet
import pandas as pd
df = pd.DataFrame({"Name": ["Alice", "Bob"], "Score": [95, 82]})
for r_idx, row in enumerate(dataframe_to_rows(df, index=False, header=True), start=1):
    for c_idx, value in enumerate(row, start=1):
        sheet.cell(row=r_idx, column=c_idx, value=value)

# Multi-sheet pandas output
with pd.ExcelWriter("multi.xlsx", engine="openpyxl") as writer:
    df.to_excel(writer, sheet_name="Summary", index=False)
    df.to_excel(writer, sheet_name="Detail", index=False)

wb.save('output.xlsx')
```

### Editing existing Excel files

```python
from openpyxl import load_workbook
from openpyxl.styles import PatternFill
from openpyxl.formatting.rule import CellIsRule, ColorScaleRule

# Load existing file (keep_vba=True for .xlsm)
wb = load_workbook('existing.xlsx')
sheet = wb.active  # or wb['SheetName']

# Iterate sheets
for sheet_name in wb.sheetnames:
    ws = wb[sheet_name]
    print(f"Sheet: {sheet_name}, dims: {ws.dimensions}")

# Modify cells
sheet['A1'] = 'New Value'
sheet.insert_rows(2)     # Insert row at position 2
sheet.delete_cols(3)     # Delete column 3 (C)

# Read calculated values (WARNING: saving data_only=True destroys formulas permanently)
wb_values = load_workbook('existing.xlsx', data_only=True)
val = wb_values.active['B5'].value  # gets last cached value

# Conditional formatting
red_fill = PatternFill(start_color="FFC7CE", end_color="FFC7CE", fill_type="solid")
green_fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
sheet.conditional_formatting.add(
    "C2:C100",
    CellIsRule(operator="lessThan", formula=["0"], fill=red_fill)
)
sheet.conditional_formatting.add(
    "C2:C100",
    CellIsRule(operator="greaterThan", formula=["0"], fill=green_fill)
)

# Add new sheet
new_sheet = wb.create_sheet('NewSheet', 0)  # 0 = insert at beginning
new_sheet['A1'] = 'Data'

# Delete a sheet
wb.remove(wb['SheetToDelete'])

# Hide/show rows and columns
sheet.column_dimensions['D'].hidden = True
sheet.row_dimensions[5].hidden = True

# Sheet protection
sheet.protection.sheet = True
sheet.protection.password = "secret"
sheet.protection.enable()

wb.save('modified.xlsx')
```

## xlsxwriter - Write-Heavy Rich Formatting

Use xlsxwriter when creating new files with many formats, charts, or conditional formatting. It cannot read or modify existing files.

```python
import xlsxwriter

wb = xlsxwriter.Workbook("output.xlsx")
ws = wb.add_worksheet("Report")

# Define formats upfront
header_fmt = wb.add_format({
    "bold": True, "bg_color": "#2E74B5", "font_color": "white",
    "border": 1, "align": "center"
})
money_fmt = wb.add_format({"num_format": '$#,##0', "border": 1})
pct_fmt = wb.add_format({"num_format": "0.0%", "border": 1})
input_fmt = wb.add_format({"font_color": "#0000FF"})   # Blue = hardcoded input

# Set column widths
ws.set_column("A:A", 20)
ws.set_column("B:D", 14)

# Write headers
for col, header in enumerate(["Quarter", "Revenue", "Growth"]):
    ws.write(0, col, header, header_fmt)

# Write data
ws.write(1, 0, "Q1")
ws.write(1, 1, 1200000, money_fmt)
ws.write(1, 2, 0.12, pct_fmt)

# Write formula
ws.write_formula(4, 1, "=SUM(B2:B4)", money_fmt)

# Conditional formatting
ws.conditional_format("C2:C10", {
    "type": "3_color_scale",
    "min_color": "#FF6B6B",
    "mid_color": "#FFD93D",
    "max_color": "#6BCB77",
})

# Chart
chart = wb.add_chart({"type": "column"})
chart.add_series({"values": "=Report!$B$2:$B$4", "name": "Revenue"})
chart.set_title({"name": "Quarterly Revenue"})
ws.insert_chart("F2", chart)

wb.close()
```

**xlsxwriter vs openpyxl:**
- **openpyxl**: Read + write existing files, preserve formatting, load_workbook
- **xlsxwriter**: Write-only, richer chart/format API, faster for large files

## Advanced openpyxl Features

### Merged Cells

```python
from openpyxl import load_workbook

wb = load_workbook('file.xlsx')
ws = wb.active

# Merge cells (write value to top-left cell only)
ws.merge_cells('A1:D1')
ws['A1'] = 'Section Header'
ws['A1'].alignment = Alignment(horizontal='center', vertical='center')

# Merge by row/col indices
ws.merge_cells(start_row=3, start_column=1, end_row=3, end_column=4)

# Unmerge
ws.unmerge_cells('A1:D1')

# List all merged ranges
for merged in ws.merged_cells.ranges:
    print(str(merged))  # e.g. "A1:D1"
```

### Images

```python
from openpyxl import Workbook
from openpyxl.drawing.image import Image

wb = Workbook()
ws = wb.active

img = Image('logo.png')
img.width = 200    # pixels
img.height = 100
ws.add_image(img, 'B2')   # anchor to cell B2

wb.save('output.xlsx')
```

### Named Ranges

```python
from openpyxl import load_workbook
from openpyxl.workbook.defined_name import DefinedName

wb = load_workbook('file.xlsx')

# Create a named range pointing to Sheet1!$A$1:$A$10
ref = "'Sheet1'!$A$1:$A$10"
dn = DefinedName("SalesData", attr_text=ref)
wb.defined_names.add(dn)

# Sheet-scoped named range (localSheetId = sheet index)
dn_local = DefinedName("LocalRange", attr_text="'Sheet1'!$B$1:$B$5", localSheetId=0)
wb.defined_names.add(dn_local)

# Read existing named ranges
for name, defn in wb.defined_names.items():
    print(name, defn.attr_text)

# Use in formula
ws['C1'] = '=SUM(SalesData)'

wb.save('output.xlsx')
```

### Data Validation (Dropdowns & Rules)

```python
from openpyxl import load_workbook
from openpyxl.worksheet.datavalidation import DataValidation

wb = load_workbook('file.xlsx')
ws = wb.active

# Dropdown from list
dv_list = DataValidation(
    type="list",
    formula1='"Alpha,Beta,Gamma"',   # comma-separated, quoted
    showDropDown=False,              # False = show arrow
    showErrorMessage=True,
    errorTitle="Invalid",
    error="Choose from the list"
)
ws.add_data_validation(dv_list)
dv_list.sqref = "C2:C100"   # apply to range

# Dropdown from cell range
dv_range = DataValidation(type="list", formula1="$F$1:$F$10")
ws.add_data_validation(dv_range)
dv_range.sqref = "D2:D100"

# Whole number rule
dv_int = DataValidation(
    type="whole", operator="between",
    formula1=1, formula2=100,
    showErrorMessage=True,
    errorTitle="Out of range",
    error="Enter a number between 1 and 100"
)
ws.add_data_validation(dv_int)
dv_int.sqref = "E2:E100"

# Date rule
dv_date = DataValidation(
    type="date", operator="greaterThan",
    formula1="2024-01-01"
)
ws.add_data_validation(dv_date)
dv_date.sqref = "F2:F100"

wb.save('output.xlsx')
```

### Cell Comments / Notes

```python
from openpyxl.comments import Comment

ws['A1'].comment = Comment("Source: Bloomberg, 2025-04-12", "Agent")
```

### Cell Hyperlinks

```python
ws['A1'].hyperlink = "https://example.com"
ws['A1'].value = "Click here"          # display text
ws['A1'].style = "Hyperlink"           # built-in blue underline style

# Internal link (same workbook, different sheet)
ws['B1'].hyperlink = "#Sheet2!A1"
ws['B1'].value = "Go to Sheet2"
ws['B1'].style = "Hyperlink"
```

**Sparklines**: NOT supported by openpyxl or xlsxwriter. Existing sparklines are preserved when loading/saving but cannot be created or modified via Python. Inform user explicitly when requested.

### CSV / TSV Import to XLSX

```python
import csv
from openpyxl import Workbook

wb = Workbook()
ws = wb.active
ws.title = "Data"

with open("data.csv", newline='', encoding='utf-8') as f:
    for row in csv.reader(f):
        ws.append(row)

wb.save("data.xlsx")

# Via pandas (handles encoding, quoting, type inference automatically)
import pandas as pd
df = pd.read_csv("data.csv")
df.to_excel("data.xlsx", index=False, engine="openpyxl")
```

### Tab Colors & Sheet Visibility

```python
ws.sheet_properties.tabColor = "FF0000"   # red tab
ws.sheet_state = 'hidden'                  # or 'veryHidden', 'visible'
```

### Print Setup

```python
from openpyxl.worksheet.page import PageMargins

ws.page_setup.orientation = 'landscape'
ws.page_setup.fitToWidth = 1
ws.page_setup.fitToHeight = 0
ws.page_margins = PageMargins(left=0.5, right=0.5, top=0.75, bottom=0.75)
ws.print_title_rows = '1:1'   # repeat row 1 on every printed page
ws.oddHeader.center.text = "&B&A"   # bold sheet name in header
```

## Formula Verification Checklist

Quick checks to ensure formulas work correctly:

### Essential Verification
- [ ] **Test 2-3 sample references**: Verify they pull correct values before building full model
- [ ] **Column mapping**: Confirm Excel columns match (e.g., column 64 = BL, not BK)
- [ ] **Row offset**: Remember Excel rows are 1-indexed (DataFrame row 5 = Excel row 6)

### Common Pitfalls
- [ ] **NaN handling**: Check for null values with `pd.notna()`
- [ ] **Far-right columns**: FY data often in columns 50+ 
- [ ] **Multiple matches**: Search all occurrences, not just first
- [ ] **Division by zero**: Check denominators before using `/` in formulas (#DIV/0!)
- [ ] **Wrong references**: Verify all cell references point to intended cells (#REF!)
- [ ] **Cross-sheet references**: Use correct format (Sheet1!A1) for linking sheets

### Formula Testing Strategy
- [ ] **Start small**: Test formulas on 2-3 cells before applying broadly
- [ ] **Verify dependencies**: Check all cells referenced in formulas exist
- [ ] **Test edge cases**: Include zero, negative, and very large values

## Guidelines

### Library Selection
- **pandas**: Best for data analysis, bulk operations, and simple data export
- **openpyxl**: Best for read+write of existing files, complex formatting, formulas, Excel-specific features
- **xlsxwriter**: Best for write-only creation with rich charts, conditional formatting, large datasets

### Working with openpyxl
- Cell indices are 1-based (row=1, column=1 refers to cell A1)
- Use `data_only=True` to read calculated values: `load_workbook('file.xlsx', data_only=True)`
- **Warning**: If opened with `data_only=True` and saved, formulas are replaced with values and permanently lost
- For large files: Use `read_only=True` for reading or `write_only=True` for writing
- Formulas are preserved as strings; they recalculate when the user opens the file in Excel or Numbers

### Working with pandas
- Specify data types to avoid inference issues: `pd.read_excel('file.xlsx', dtype={'id': str})`
- For large files, read specific columns: `pd.read_excel('file.xlsx', usecols=['A', 'C', 'E'])`
- Handle dates properly: `pd.read_excel('file.xlsx', parse_dates=['date_column'])`

## Code Style
When writing Python for Excel operations:
- Write minimal, concise Python code without unnecessary comments
- Avoid verbose variable names and redundant operations
- Avoid unnecessary print statements

**For Excel files themselves**:
- Add comments to cells with complex formulas or important assumptions
- Document data sources for hardcoded values
- Include notes for key calculations and model sections

## Python Binary

Always run scripts as: `/opt/homebrew/bin/python3 script.py`