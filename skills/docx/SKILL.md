---
name: docx
description: "Word document (.docx) operations - creation, reading, editing, template filling, tracked changes, comments. Trigger on any .docx task: reports, letters, memos, contracts, mail merge. Covers python-docx API and XML-level editing for tracked changes/comments. Not for PDF, XLSX, or Google Docs."
license: MIT
---

# DOCX Skill - Word Document Operations

## How It Works

A .docx is a ZIP of XML files. **python-docx** handles creation/editing. For tracked changes and comments (not covered by python-docx), unzip with `zipfile`, edit the XML, repack.

## Workflow Overview

| Task | Method |
|------|--------|
| Read content | python-docx `Document()` or markitdown |
| Create new | python-docx (see below) |
| Edit existing | Load with python-docx, modify, save |
| Tracked changes / comments | zipfile unpack, XML editing, repack |

### Reading Content

```python
from docx import Document

doc = Document("document.docx")

# All paragraph text
for para in doc.paragraphs:
    print(para.style.name, para.text)

# Table content
for table in doc.tables:
    for row in table.rows:
        print([cell.text for cell in row.cells])

# Core properties
props = doc.core_properties
print(f"Author: {props.author}, Title: {props.title}")
```

For agent-readable Markdown (analysis, summarization, RAG):
```python
from markitdown import MarkItDown
result = MarkItDown().convert("document.docx")
print(result.text_content)
```

---

## Creating New Documents

### Setup

```python
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import copy

doc = Document()
```

### Page Size and Margins

```python
section = doc.sections[0]

# US Letter (always set explicitly - defaults vary)
section.page_width = Inches(8.5)
section.page_height = Inches(11)
section.left_margin = Inches(1)
section.right_margin = Inches(1)
section.top_margin = Inches(1)
section.bottom_margin = Inches(1)

# Landscape
section.orientation = WD_ORIENT.LANDSCAPE
section.page_width = Inches(11)
section.page_height = Inches(8.5)
```

**Page sizes (1 inch = 914400 EMU = 72pt):**

| Paper | Width | Height |
|-------|-------|--------|
| US Letter | 8.5" | 11" |
| A4 | 8.27" | 11.69" |

### Paragraphs and Text Formatting

```python
# Simple paragraph
para = doc.add_paragraph("Regular text.")

# Mixed formatting in one paragraph
para = doc.add_paragraph()
run = para.add_run("Bold")
run.bold = True
para.add_run(" and ")
run = para.add_run("italic red")
run.italic = True
run.font.color.rgb = RGBColor(0xC0, 0x00, 0x00)

# Font properties
run.font.name = "Arial"
run.font.size = Pt(12)
run.font.underline = True
run.font.strike = True       # strikethrough
run.font.all_caps = True     # ALL CAPS display only
run.font.superscript = True  # superscript (exclusive with subscript)
run.font.subscript = True    # subscript

# Paragraph alignment, spacing, and indentation
para.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY  # LEFT, CENTER, RIGHT, JUSTIFY
para.paragraph_format.space_before = Pt(6)
para.paragraph_format.space_after = Pt(6)
para.paragraph_format.line_spacing = Pt(14)
para.paragraph_format.left_indent = Inches(0.5)           # left indent (whole paragraph)
para.paragraph_format.right_indent = Inches(0.5)          # right indent
para.paragraph_format.first_line_indent = Inches(0.25)    # first line indent
# para.paragraph_format.first_line_indent = Inches(-0.25) # hanging indent (negative)
```

### Headings

```python
doc.add_heading("Document Title", level=0)   # Title style
doc.add_heading("Chapter 1", level=1)         # Heading 1
doc.add_heading("Section 1.1", level=2)       # Heading 2
doc.add_heading("Subsection", level=3)        # Heading 3
```

### Styles

```python
from docx.enum.style import WD_STYLE_TYPE

# Apply a named style
para = doc.add_paragraph("Styled text", style="Intense Quote")

# Modify an existing style
style = doc.styles["Heading 1"]
style.font.name = "Arial"
style.font.size = Pt(18)
style.font.bold = True
style.font.color.rgb = RGBColor(0x2E, 0x74, 0xB5)
style.paragraph_format.space_before = Pt(12)
style.paragraph_format.space_after = Pt(6)

# Create a custom paragraph style
custom = doc.styles.add_style("MyStyle", WD_STYLE_TYPE.PARAGRAPH)
custom.base_style = doc.styles["Normal"]
custom.font.name = "Georgia"
custom.font.size = Pt(11)
custom.font.color.rgb = RGBColor(0x1A, 0x1A, 0x2E)
custom.paragraph_format.space_before = Pt(6)
custom.paragraph_format.space_after = Pt(3)
custom.paragraph_format.line_spacing = Pt(16)

# Create a character style (for inline text formatting)
char_style = doc.styles.add_style("Emphasis Red", WD_STYLE_TYPE.CHARACTER)
char_style.font.color.rgb = RGBColor(0xC0, 0x00, 0x00)
char_style.font.bold = True

# List all styles in document
for s in doc.styles:
    print(s.name, s.type)

# Common built-in style names:
# "Normal", "Body Text", "Quote", "Intense Quote"
# "Heading 1" through "Heading 9"
# "List Bullet", "List Bullet 2", "List Bullet 3"
# "List Number", "List Number 2", "List Number 3"
# "Title", "Subtitle", "Caption"
```

### Lists

**NEVER add bullet characters manually.** Use built-in list styles.

```python
# Bullet list
doc.add_paragraph("First item", style="List Bullet")
doc.add_paragraph("Second item", style="List Bullet")
doc.add_paragraph("Nested bullet", style="List Bullet 2")

# Numbered list
doc.add_paragraph("Step one", style="List Number")
doc.add_paragraph("Step two", style="List Number")
```

### Tables

```python
# Create table
table = doc.add_table(rows=3, cols=3)
table.style = "Table Grid"
table.alignment = WD_TABLE_ALIGNMENT.CENTER

# Set column widths on every cell in that column
for row in table.rows:
    row.cells[0].width = Inches(2.5)
    row.cells[1].width = Inches(2.5)
    row.cells[2].width = Inches(2.5)

# Write to cells
table.cell(0, 0).text = "Header 1"
table.cell(0, 1).text = "Header 2"
table.cell(0, 2).text = "Header 3"
table.cell(1, 0).text = "Data"

# Bold header row
for cell in table.rows[0].cells:
    for para in cell.paragraphs:
        for run in para.runs:
            run.bold = True

# Cell background shading (via XML - no native API)
def set_cell_color(cell, hex_color: str):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:fill"), hex_color)  # hex without #
    tcPr.append(shd)

set_cell_color(table.cell(0, 0), "2E74B5")

# Cell internal padding (via XML - DXA units, 1440 = 1 inch)
def set_cell_margins(cell, top=80, bottom=80, left=120, right=120):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcMar = OxmlElement("w:tcMar")
    for side, val in [("top", top), ("bottom", bottom), ("left", left), ("right", right)]:
        el = OxmlElement(f"w:{side}")
        el.set(qn("w:w"), str(val))
        el.set(qn("w:type"), "dxa")
        tcMar.append(el)
    tcPr.append(tcMar)

for row in table.rows:
    for cell in row.cells:
        set_cell_margins(cell)

# Row height (DXA: 720 = 0.5 inch)
def set_row_height(row, height_dxa: int):
    tr = row._tr
    trPr = tr.get_or_add_trPr()
    trH = OxmlElement("w:trHeight")
    trH.set(qn("w:val"), str(height_dxa))
    trPr.append(trH)

set_row_height(table.rows[0], 567)  # ~0.4 inch header

# Vertical alignment
table.cell(0, 0).vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER

# Merge cells horizontally
table.cell(1, 0).merge(table.cell(1, 1))
```

### Images

```python
# Inline image (height auto-scales to maintain aspect ratio)
doc.add_picture("image.png", width=Inches(4))

# Centered image
para = doc.add_paragraph()
para.alignment = WD_ALIGN_PARAGRAPH.CENTER
para.add_run().add_picture("image.png", width=Inches(4))
```

### Page Breaks and Section Breaks

```python
# Page break
doc.add_page_break()

# Section break (new page with independent formatting)
new_section = doc.add_section(WD_SECTION.NEW_PAGE)
new_section.page_width = Inches(11)
new_section.page_height = Inches(8.5)
# WD_SECTION values: NEW_PAGE, ODD_PAGE, EVEN_PAGE, CONTINUOUS
```

### Headers and Footers

```python
section = doc.sections[0]
section.different_first_page_header_footer = True  # Optional: unique first page

# Header
header = section.header
header.paragraphs[0].text = "Company Name"
header.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER

# Footer with PAGE field
footer = section.footer
para = footer.paragraphs[0]
para.alignment = WD_ALIGN_PARAGRAPH.CENTER
para.add_run("Page ")
run = para.add_run()
# fldChar begin
fc1 = OxmlElement("w:fldChar")
fc1.set(qn("w:fldCharType"), "begin")
run._r.append(fc1)
# field instruction
it = OxmlElement("w:instrText")
it.set(qn("xml:space"), "preserve")
it.text = " PAGE "
run._r.append(it)
# fldChar end
fc2 = OxmlElement("w:fldChar")
fc2.set(qn("w:fldCharType"), "end")
run._r.append(fc2)
```

### Tab Stops

```python
# Right-aligned tab at right margin (company name left, date right)
para = doc.add_paragraph()
para.paragraph_format.tab_stops.add_tab_stop(Inches(6.5), WD_TAB_ALIGNMENT.RIGHT)
para.add_run("Company Name\tJanuary 2025")

# Dot-leader tab (TOC style)
para = doc.add_paragraph()
para.paragraph_format.tab_stops.add_tab_stop(
    Inches(6.5), WD_TAB_ALIGNMENT.RIGHT, WD_TAB_LEADER.DOTS
)
para.add_run("Introduction\t3")
```

### Hyperlinks

python-docx has no native hyperlink API; add via XML:

```python
def add_hyperlink(paragraph, text, url):
    r_id = paragraph.part.relate_to(
        url,
        "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink",
        is_external=True,
    )
    hyperlink = OxmlElement("w:hyperlink")
    hyperlink.set(qn("r:id"), r_id)
    run = OxmlElement("w:r")
    rPr = OxmlElement("w:rPr")
    rStyle = OxmlElement("w:rStyle")
    rStyle.set(qn("w:val"), "Hyperlink")
    rPr.append(rStyle)
    run.append(rPr)
    t = OxmlElement("w:t")
    t.text = text
    run.append(t)
    hyperlink.append(run)
    paragraph._p.append(hyperlink)

para = doc.add_paragraph("Visit ")
add_hyperlink(para, "our website", "https://example.com")
```

### Table of Contents

Inserts a TOC field; Word/Numbers updates it on first open (Ctrl+A -> F9 in Word):

```python
def add_toc(document):
    para = document.add_paragraph()
    run = para.add_run()
    fldChar1 = OxmlElement("w:fldChar")
    fldChar1.set(qn("w:fldCharType"), "begin")
    instrText = OxmlElement("w:instrText")
    instrText.set(qn("xml:space"), "preserve")
    instrText.text = ' TOC \\o "1-3" \\h \\z \\u '
    fldChar2 = OxmlElement("w:fldChar")
    fldChar2.set(qn("w:fldCharType"), "separate")
    fldChar3 = OxmlElement("w:fldChar")
    fldChar3.set(qn("w:fldCharType"), "end")
    run._r.extend([fldChar1, instrText, fldChar2, fldChar3])

add_toc(doc)
```

### Saving

```python
doc.save("document.docx")
```

---

## Editing Existing Documents

```python
from docx import Document
import copy

doc = Document(“existing.docx”)

# Find and replace text (paragraphs only)
for para in doc.paragraphs:
    for run in para.runs:
        if “old text” in run.text:
            run.text = run.text.replace(“old text”, “new text”)

# Find and replace including tables
def find_replace_all(doc, old: str, new: str):
    for para in doc.paragraphs:
        for run in para.runs:
            if old in run.text:
                run.text = run.text.replace(old, new)
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                for para in cell.paragraphs:
                    for run in para.runs:
                        if old in run.text:
                            run.text = run.text.replace(old, new)

find_replace_all(doc, “2023”, “2024”)
# WARNING: finds text only within a single run. Word often splits the same visible word
# across multiple runs. For placeholder replacement use fill_template() - it joins runs first.

# Append all content from another document
source = Document(“source.docx”)
for element in source.element.body:
    doc.element.body.append(copy.deepcopy(element))

doc.save(“modified.docx”)
```

---

## XML-Level Operations (Tracked Changes and Comments)

python-docx has no API for tracked changes or comments. Unpack with `zipfile`, edit XML with the Edit tool, repack.

### Unpack / Repack

```python
import zipfile, shutil, os
from pathlib import Path

def unpack_docx(docx_path: str, out_dir: str):
    shutil.rmtree(out_dir, ignore_errors=True)
    with zipfile.ZipFile(docx_path, “r”) as z:
        z.extractall(out_dir)

def repack_docx(src_dir: str, out_path: str):
    tmp = out_path + “.tmp.zip”
    with zipfile.ZipFile(tmp, “w”, zipfile.ZIP_DEFLATED) as zf:
        for f in Path(src_dir).rglob(“*”):
            if f.is_file():
                zf.write(f, f.relative_to(src_dir))
    os.replace(tmp, out_path)

# Usage
unpack_docx(“document.docx”, “unpacked/”)
# ... edit XML in unpacked/word/ using Edit tool ...
repack_docx(“unpacked/”, “output.docx”)
shutil.rmtree(“unpacked/”)
```

### Key Files After Unpacking

| File | Purpose |
|------|---------|
| `word/document.xml` | Main body content |
| `word/styles.xml` | Paragraph and character styles |
| `word/footnotes.xml` | Footnote definitions |
| `word/comments.xml` | Comment content |
| `word/commentsExtended.xml` | Comment threading (replies) |
| `word/_rels/document.xml.rels` | Relationships (images, hyperlinks) |
| `[Content_Types].xml` | MIME types for embedded files |

### Critical XML Editing Rules

- **Author**: Use “Qwen” for all tracked changes and comments.
- **Use the Edit tool** (surgical string replacement) - not Python scripts.
- **Smart quotes** - XML entities for professional typography:

| Entity | Character |
|--------|-----------|
| `&#x2018;` | ‘ (left single) |
| `&#x2019;` | ‘ (right single / apostrophe) |
| `&#x201C;` | “ (left double) |
| `&#x201D;` | “ (right double) |

- **Whitespace**: Add `xml:space=”preserve”` to `<w:t>` with leading/trailing spaces.
- **RSIDs**: Must be 8-digit hex (e.g., `00AB1234`).
- **Element order in `<w:pPr>`**: `<w:pStyle>`, `<w:numPr>`, `<w:spacing>`, `<w:ind>`, `<w:jc>`, `<w:rPr>` last.
- **`durableId`** must be < 0x7FFFFFFF; replace any larger values with a valid smaller hex.

### Common Pitfalls

- **Replace entire `<w:r>` elements**: When adding tracked changes, replace the whole `<w:r>...</w:r>` block with `<w:del>...<w:ins>...` as siblings. Never inject tracked change tags inside a run.
- **Preserve `<w:rPr>` formatting**: Copy the original run’s `<w:rPr>` block into your tracked change runs to maintain bold, font size, etc.

---

## XML Reference

### Tracked Changes

**Insertion:**
```xml
<w:ins w:id="1" w:author="Qwen" w:date="2025-01-01T00:00:00Z">
  <w:r><w:t>inserted text</w:t></w:r>
</w:ins>
```

**Deletion:**
```xml
<w:del w:id="2" w:author="Qwen" w:date="2025-01-01T00:00:00Z">
  <w:r><w:delText>deleted text</w:delText></w:r>
</w:del>
```

**Inside `<w:del>`**: Use `<w:delText>` instead of `<w:t>`, and `<w:delInstrText>` instead of `<w:instrText>`.

**Minimal edits** - only mark what changes:
```xml
<!-- Change "30 days" to "60 days" -->
<w:r><w:t>The term is </w:t></w:r>
<w:del w:id="1" w:author="Qwen" w:date="...">
  <w:r><w:delText>30</w:delText></w:r>
</w:del>
<w:ins w:id="2" w:author="Qwen" w:date="...">
  <w:r><w:t>60</w:t></w:r>
</w:ins>
<w:r><w:t> days.</w:t></w:r>
```

**Deleting entire paragraphs/list items** - when removing ALL content from a paragraph, also mark the paragraph mark as deleted so it merges with the next paragraph. Add `<w:del/>` inside `<w:pPr><w:rPr>`:
```xml
<w:p>
  <w:pPr>
    <w:numPr>...</w:numPr>  <!-- list numbering if present -->
    <w:rPr>
      <w:del w:id="1" w:author="Qwen" w:date="2025-01-01T00:00:00Z"/>
    </w:rPr>
  </w:pPr>
  <w:del w:id="2" w:author="Qwen" w:date="2025-01-01T00:00:00Z">
    <w:r><w:delText>Entire paragraph content being deleted...</w:delText></w:r>
  </w:del>
</w:p>
```
Without the `<w:del/>` in `<w:pPr><w:rPr>`, accepting changes leaves an empty paragraph/list item.

**Rejecting another author's insertion** - nest deletion inside their insertion:
```xml
<w:ins w:author="Jane" w:id="5">
  <w:del w:author="Qwen" w:id="10">
    <w:r><w:delText>their inserted text</w:delText></w:r>
  </w:del>
</w:ins>
```

**Restoring another author's deletion** - add insertion after (don't modify their deletion):
```xml
<w:del w:author="Jane" w:id="5">
  <w:r><w:delText>deleted text</w:delText></w:r>
</w:del>
<w:ins w:author="Qwen" w:id="10">
  <w:r><w:t>deleted text</w:t></w:r>
</w:ins>
```

### Comments

Three XML files must be coordinated: `word/comments.xml` (content), `word/commentsExtended.xml` (threading), `word/document.xml` (anchors in body text).

**Step 1 - Add comment content to `word/comments.xml`:**
```xml
<w:comments xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:comment w:id="0" w:author="Qwen" w:date="2025-01-01T00:00:00Z" w:initials="Q">
    <w:p>
      <w:pPr><w:pStyle w:val="CommentText"/></w:pPr>
      <w:r>
        <w:rPr><w:rStyle w:val="CommentReference"/></w:rPr>
        <w:annotationRef/>
      </w:r>
      <w:r><w:t>Your comment text here.</w:t></w:r>
    </w:p>
  </w:comment>
  <!-- Reply to comment 0: -->
  <w:comment w:id="1" w:author="Qwen" w:date="2025-01-01T00:00:00Z" w:initials="Q">
    <w:p>
      <w:pPr><w:pStyle w:val="CommentText"/></w:pPr>
      <w:r>
        <w:rPr><w:rStyle w:val="CommentReference"/></w:rPr>
        <w:annotationRef/>
      </w:r>
      <w:r><w:t>Reply text here.</w:t></w:r>
    </w:p>
  </w:comment>
</w:comments>
```

**Step 2 - Add threading to `word/commentsExtended.xml`** (only needed for replies):
```xml
<w15:commentsEx xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml">
  <w15:commentEx w15:paraId="12345678" w15:done="0"/>
  <!-- Reply: w15:paraIdParent points to the parent comment's paraId -->
  <w15:commentEx w15:paraId="87654321" w15:paraIdParent="12345678" w15:done="0"/>
</w15:commentsEx>
```

**Step 3 - Add anchors in `word/document.xml`:**

**CRITICAL: `<w:commentRangeStart>` and `<w:commentRangeEnd>` are siblings of `<w:r>`, NEVER inside `<w:r>`.**

```xml
<!-- Single comment anchoring text -->
<w:commentRangeStart w:id="0"/>
<w:r><w:t>annotated text</w:t></w:r>
<w:commentRangeEnd w:id="0"/>
<w:r>
  <w:rPr><w:rStyle w:val="CommentReference"/></w:rPr>
  <w:commentReference w:id="0"/>
</w:r>

<!-- Comment with reply: nest reply range inside parent range -->
<w:commentRangeStart w:id="0"/>
  <w:commentRangeStart w:id="1"/>
  <w:r><w:t>annotated text</w:t></w:r>
  <w:commentRangeEnd w:id="1"/>
<w:commentRangeEnd w:id="0"/>
<w:r><w:rPr><w:rStyle w:val="CommentReference"/></w:rPr><w:commentReference w:id="0"/></w:r>
<w:r><w:rPr><w:rStyle w:val="CommentReference"/></w:rPr><w:commentReference w:id="1"/></w:r>
```

### Images (XML-level insertion)

1. Copy image to `word/media/`
2. Add to `word/_rels/document.xml.rels`:
```xml
<Relationship Id="rId5"
  Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
  Target="media/image1.png"/>
```
3. Add to `[Content_Types].xml` if extension not present:
```xml
<Default Extension="png" ContentType="image/png"/>
```
4. Insert in `word/document.xml` (cx/cy in EMU, 914400 = 1 inch):
```xml
<w:drawing>
  <wp:inline distT="0" distB="0" distL="0" distR="0"
    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
    <wp:extent cx="3657600" cy="2743200"/>
    <wp:docPr id="1" name="Picture1"/>
    <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
      <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
        <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <pic:nvPicPr>
            <pic:cNvPr id="1" name="image1.png"/>
            <pic:cNvPicPr/>
          </pic:nvPicPr>
          <pic:blipFill>
            <a:blip r:embed="rId5"
              xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
            <a:stretch><a:fillRect/></a:stretch>
          </pic:blipFill>
          <pic:spPr>
            <a:xfrm><a:off x="0" y="0"/><a:ext cx="3657600" cy="2743200"/></a:xfrm>
            <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
          </pic:spPr>
        </pic:pic>
      </a:graphicData>
    </a:graphic>
  </wp:inline>
</w:drawing>
```

---

## Template Filling / Mail Merge

When the user has a template with `{{PLACEHOLDER}}` variables to fill:

```python
from docx import Document

def fill_template(template_path: str, output_path: str, data: dict) -> None:
    """Replace {{KEY}} placeholders throughout document: paragraphs, tables, headers, footers."""
    doc = Document(template_path)

    def replace_in_para(para):
        # Placeholders can be split across runs - join, replace, restore to single run
        full_text = ''.join(r.text for r in para.runs)
        changed = False
        for key, value in data.items():
            token = f"{{{{{key}}}}}"
            if token in full_text:
                full_text = full_text.replace(token, str(value))
                changed = True
        if changed and para.runs:
            para.runs[0].text = full_text
            for run in para.runs[1:]:
                run.text = ""

    # Paragraphs
    for para in doc.paragraphs:
        replace_in_para(para)

    # Tables
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                for para in cell.paragraphs:
                    replace_in_para(para)

    # Headers and footers
    for section in doc.sections:
        for para in section.header.paragraphs:
            replace_in_para(para)
        for para in section.footer.paragraphs:
            replace_in_para(para)

    doc.save(output_path)

# Usage
fill_template(
    "template.docx",
    "output.docx",
    {
        "CLIENT_NAME": "Acme Corp",
        "DATE": "12. April 2026",
        "AMOUNT": "€ 48,500",
        "PROJECT": "Alpha Platform",
    }
)
```

**Note**: This approach works when placeholders may be split across runs (common in Word). It merges all run text, performs the replacement, then writes back to the first run and blanks the rest, preserving paragraph formatting.

### Bulk Document Generation

```python
import copy
from docx import Document
from docx.oxml.ns import qn

# Generate one file per record
records = [
    {"NAME": "Alice Smith", "ROLE": "Engineer"},
    {"NAME": "Bob Jones",   "ROLE": "Manager"},
]

for record in records:
    fill_template("template.docx", f"letter_{record['NAME'].replace(' ', '_')}.docx", record)
```

---

## Document Properties

```python
from docx import Document
import datetime

doc = Document()
props = doc.core_properties

props.author   = "Agent"
props.title    = "Q1 Report"
props.subject  = "Finance"
props.keywords = "revenue, costs, 2026"
props.description = "Quarterly financial summary"
props.created  = datetime.datetime.now()
props.modified = datetime.datetime.now()

doc.save("output.docx")
```

---

## Dependencies

- **python-docx 1.2.0**: `from docx import Document` - all creation, editing, reading
- **markitdown 0.1.5**: `from markitdown import MarkItDown` - document to Markdown for agent analysis
- **zipfile** (Python stdlib): unpack and repack .docx for XML-level operations
- **DOCX -> PDF**: NOT available (no LibreOffice/MS Office automation). Inform user explicitly when requested.
- **Python binary**: Always run as `/opt/homebrew/bin/python3 script.py`
