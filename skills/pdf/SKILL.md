---
name: pdf
description: "PDF operations - read, extract, create, merge, split, rotate, watermark, fill forms, encrypt, annotate. Trigger on any .pdf task. Uses PyMuPDF (primary), pdfplumber (tables), pypdf (merge/split), pikepdf (repair), reportlab (create). Not for DOCX or PPTX."
license: MIT
---

# PDF Skill - Complete PDF Toolkit

## Library Selection

| Task | Library | Import |
|------|---------|--------|
| Read / extract text / render / images | PyMuPDF | `import fitz` |
| PDF -> Markdown for agent/LLM input | pymupdf4llm | `import pymupdf4llm` |
| Extract tables (layout-aware) | pdfplumber | `import pdfplumber` |
| Merge / split / rotate / encrypt | pypdf | `from pypdf import PdfReader, PdfWriter` |
| Low-level repair / structural surgery | pikepdf | `import pikepdf` |
| Create PDFs from scratch | reportlab | `from reportlab.pdfgen import canvas` |

---

## Reading / Einlesen - Drei Methoden

```python
# 1. markitdown - schnellste Methode für Agent-lesbare Ausgabe
#    Unterstützt: PDF, DOCX, XLSX, PPTX, HTML, CSV, Bilder, Audio
from markitdown import MarkItDown
result = MarkItDown().convert("document.pdf")
print(result.text_content)  # Volltext als Markdown

# 2. pymupdf4llm - strukturierteres Markdown (Tabellen, Headings erhalten)
import pymupdf4llm
md = pymupdf4llm.to_markdown("document.pdf")

# 3. fitz - strukturierter Zugriff auf Text, Positionen, Fonts
import fitz
with fitz.open("document.pdf") as doc:
    for page in doc:
        print(page.get_text())
```

**Faustregel**: markitdown für schnelle Inhaltsanalyse, pymupdf4llm wenn Tabellenstruktur wichtig ist, fitz wenn Positionen/Fonts/präzise Kontrolle gebraucht wird.

---

## PyMuPDF (fitz) - Primary Tool

Use fitz for almost everything: text extraction, rendering, image extraction, watermarks, merging.

**Coordinate system**: Origin (0,0) is top-left. x increases right, y increases downward. 72 points = 1 inch. Standard sizes in points: US Letter = 612x792, A4 = 595x842. `page.rect` returns `fitz.Rect(0, 0, width, height)` for the full page.

### Create New Empty PDF

```python
import fitz

doc = fitz.open()                                   # new empty document (no file on disk)
page = doc.new_page(width=612, height=792)          # add US Letter page
page = doc.new_page(-1, width=595, height=842)      # append A4 page at end (-1 = append)
doc.save("new.pdf")
doc.close()
```

### Open and Read

```python
import fitz  # PyMuPDF

# Standard
doc = fitz.open("document.pdf")
print(f"Pages: {len(doc)}, Metadata: {doc.metadata}")

# Password-geschützte PDF
doc = fitz.open("encrypted.pdf")
if doc.needs_pass:
    success = doc.authenticate("password")
    if not success:
        raise ValueError("Falsches Passwort")

# Aus BytesIO / In-Memory
import io
with open("document.pdf", "rb") as f:
    data = f.read()
doc = fitz.open(stream=data, filetype="pdf")

# Plain text
for page in doc:
    print(page.get_text())

# Text with positions (blocks)
for page in doc:
    for block in page.get_text("blocks"):
        # (x0, y0, x1, y1, text, block_no, block_type)
        print(block[4])

# Fine-grained (spans with font/size info)
for page in doc:
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            for span in line["spans"]:
                print(f"[{span['font']} {span['size']}pt] {span['text']}")

# Word-level extraction (coordinates per word)
for page in doc:
    for word in page.get_text("words"):
        # (x0, y0, x1, y1, word, block_no, line_no, word_no)
        x0, y0, x1, y1, text, *_ = word
        print(f"{text!r:20s} @ ({x0:.1f},{y0:.1f})-({x1:.1f},{y1:.1f})")

doc.close()
```

### Extract Tables (PyMuPDF native, 1.23+)

```python
import fitz

with fitz.open("document.pdf") as doc:
    for page_num, page in enumerate(doc):
        for tab in page.find_tables().tables:
            df = tab.to_pandas()
            print(f"Page {page_num+1}: {df.shape}")
            print(df)
```

### Render Pages to Images

```python
import fitz

with fitz.open("document.pdf") as doc:
    for i, page in enumerate(doc):
        # zoom=2 -> 144 DPI, zoom=3 -> 216 DPI
        pix = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
        pix.save(f"page_{i+1:03d}.png")
```

### Extract Embedded Images

```python
import fitz

with fitz.open("document.pdf") as doc:
    for page_num in range(len(doc)):
        for img_info in doc.get_page_images(page_num):
            xref = img_info[0]
            base = doc.extract_image(xref)
            with open(f"img_{xref}.{base['ext']}", "wb") as f:
                f.write(base["image"])
```

### Merge PDFs

```python
import fitz

doc1 = fitz.open("file1.pdf")
doc2 = fitz.open("file2.pdf")
doc1.insert_pdf(doc2)
# Insert specific pages: doc1.insert_pdf(doc2, from_page=2, to_page=5, start_at=3)
doc1.save("merged.pdf")
doc1.close()
```

### Add Text / Watermark

```python
import fitz

with fitz.open("document.pdf") as doc:
    for page in doc:
        page.insert_text(
            (page.rect.width / 4, page.rect.height / 2),
            "CONFIDENTIAL",
            fontsize=48,
            color=(0.8, 0, 0),
            rotate=45,
            overlay=True,
        )
    doc.save("watermarked.pdf")
```

### Edit Metadata

```python
import fitz

with fitz.open("document.pdf") as doc:
    doc.set_metadata({
        "title": "Annual Report 2024",
        "author": "Acme Corp",
        "subject": "Financial Results",
        "keywords": "finance, annual, report",
    })
    doc.save("document_meta.pdf")
```

### Page Manipulation

```python
import fitz

doc = fitz.open("document.pdf")

# Delete page (0-indexed)
doc.delete_page(3)

# Delete page range
doc.delete_pages(from_page=5, to_page=9)

# Insert blank page at position (width/height in points: 595x842 = A4, 612x792 = Letter)
doc.insert_page(2, width=612, height=792)

# Move page (from index, to index)
doc.move_page(0, 5)

# Copy page (duplicate within same doc)
doc.copy_page(0, -1)  # copy page 0 to end

# Check and set page rotation (degrees: 0, 90, 180, 270)
print(page.rotation)     # read current rotation
page.set_rotation(90)    # rotate 90 clockwise

# Reorder: create new doc with specific page order
new_doc = fitz.open()
order = [2, 0, 1, 3]  # new order
for i in order:
    new_doc.insert_pdf(doc, from_page=i, to_page=i)
new_doc.save("reordered.pdf")

doc.close()
```

### Text Search and Annotations

```python
import fitz

doc = fitz.open("document.pdf")
for page in doc:
    # Find all occurrences of a string (returns list of Rect objects)
    hits = page.search_for("confidential", quads=False)
    for rect in hits:
        # Highlight found text
        annot = page.add_highlight_annot(rect)
        annot.set_colors(stroke=(1, 1, 0))  # yellow
        annot.update()

    # Underline
    for rect in page.search_for("important"):
        page.add_underline_annot(rect)

    # Sticky note (popup comment)
    note = page.add_text_annot((100, 100), "Review this section")
    note.set_info(title="Qwen", content="Please review carefully.")
    note.update()

    # Redact (permanently remove text)
    for rect in page.search_for("SECRET"):
        page.add_redact_annot(rect, fill=(0, 0, 0))  # black box
    page.apply_redactions()

doc.save("annotated.pdf")
doc.close()
```

### Vector Drawing on Pages

```python
import fitz

doc = fitz.open("document.pdf")
page = doc[0]

# Line
page.draw_line((72, 100), (540, 100), color=(0, 0, 0), width=1)

# Rectangle (border only)
page.draw_rect(fitz.Rect(72, 120, 300, 200), color=(0.18, 0.46, 0.71), width=2)

# Filled rectangle
page.draw_rect(fitz.Rect(72, 210, 300, 290), color=(0.18, 0.46, 0.71),
               fill=(0.85, 0.92, 0.98), width=1)

# Circle
page.draw_circle((150, 350), 30, color=(1, 0, 0), fill=(1, 0.8, 0.8), width=1.5)

# Bezier curve
page.draw_bezier((72, 400), (200, 350), (300, 450), (430, 400),
                 color=(0.5, 0, 0.5), width=2)

doc.save("drawing.pdf")
doc.close()
```

### Bookmarks / Table of Contents

```python
import fitz

doc = fitz.open("document.pdf")

# Read existing TOC
toc = doc.get_toc()
# Returns list of [level, title, page_number, dest]
for level, title, page, *_ in toc:
    print("  " * (level - 1) + f"{title} -> page {page}")

# Set/replace TOC
new_toc = [
    [1, "Introduction", 1],
    [1, "Chapter 1", 3],
    [2, "Section 1.1", 4],
    [1, "Chapter 2", 8],
    [1, "Conclusion", 15],
]
doc.set_toc(new_toc)
doc.save("with_toc.pdf")
doc.close()
```

### Overlay Image onto Page

```python
import fitz

doc = fitz.open("document.pdf")
page = doc[0]

# Insert image at position (rect defines position and size)
rect = fitz.Rect(400, 50, 550, 150)  # x0, y0, x1, y1 in points
page.insert_image(rect, filename="logo.png")

# Insert image from bytes
with open("logo.png", "rb") as f:
    img_bytes = f.read()
page.insert_image(rect, stream=img_bytes)

doc.save("with_image.pdf")
doc.close()
```

### Optimized Saving

```python
import fitz

doc = fitz.open("document.pdf")
# ... modifications ...
doc.save(
    "optimized.pdf",
    garbage=4,        # 0-4: remove unreferenced objects (4 = aggressive)
    deflate=True,     # compress streams
    clean=True,       # sanitize content streams
    linear=True,      # web-optimized (fast view in browser)
)
doc.close()
```

---

## pymupdf4llm - PDF -> Markdown

Best tool for feeding PDF content into an agent or LLM. Preserves headings, tables, lists.

```python
import pymupdf4llm

# Whole document
md = pymupdf4llm.to_markdown("document.pdf")
print(md)

# Specific pages (0-indexed)
md = pymupdf4llm.to_markdown("document.pdf", pages=[0, 1, 2])
```

---

## pdfplumber - Layout-Aware Table Extraction

Use when PyMuPDF's table detection isn't precise enough for complex or borderless tables.

```python
import pdfplumber
import pandas as pd

with pdfplumber.open("document.pdf") as pdf:
    for i, page in enumerate(pdf.pages):
        text = page.extract_text()

        for table in page.extract_tables():
            if table:
                df = pd.DataFrame(table[1:], columns=table[0])
                df.to_csv(f"table_p{i+1}.csv", index=False)
```

---

## pypdf - Merge / Split / Rotate / Encrypt

```python
from pypdf import PdfReader, PdfWriter

# Merge
writer = PdfWriter()
for path in ["doc1.pdf", "doc2.pdf", "doc3.pdf"]:
    for page in PdfReader(path).pages:
        writer.add_page(page)
with open("merged.pdf", "wb") as f:
    writer.write(f)

# Split: one file per page
reader = PdfReader("input.pdf")
for i, page in enumerate(reader.pages):
    w = PdfWriter()
    w.add_page(page)
    with open(f"page_{i+1}.pdf", "wb") as f:
        w.write(f)

# Rotate
reader = PdfReader("input.pdf")
writer = PdfWriter()
for page in reader.pages:
    page.rotate(90)  # clockwise; 180, 270 also valid
    writer.add_page(page)
with open("rotated.pdf", "wb") as f:
    writer.write(f)

# Encrypt
writer = PdfWriter()
for page in PdfReader("input.pdf").pages:
    writer.add_page(page)
writer.encrypt("userpassword", "ownerpassword", use_128bit=True)
with open("encrypted.pdf", "wb") as f:
    writer.write(f)

# Decrypt / remove password
reader = PdfReader("encrypted.pdf")
reader.decrypt("password")
writer = PdfWriter()
for page in reader.pages:
    writer.add_page(page)
with open("decrypted.pdf", "wb") as f:
    writer.write(f)

# Extract metadata
meta = PdfReader("document.pdf").metadata
print(f"Title: {meta.title}, Author: {meta.author}")
```

---

## pikepdf - Low-Level Repair and Surgery

```python
import pikepdf

# Re-save to repair many structural issues
with pikepdf.open("damaged.pdf") as pdf:
    pdf.save("repaired.pdf")

# Remove encryption
with pikepdf.open("encrypted.pdf", password="secret") as pdf:
    pdf.save("decrypted.pdf", encryption=False)

# Inspect raw PDF objects
with pikepdf.open("document.pdf") as pdf:
    page = pdf.pages[0]
    print(page.keys())           # PDF object keys
    print(page["/MediaBox"])     # Page size in points
```

---

## reportlab - Create PDFs from Scratch

### Canvas (pixel-precise control)

```python
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

c = canvas.Canvas("output.pdf", pagesize=letter)
width, height = letter  # 612 x 792 points

c.setFont("Helvetica-Bold", 16)
c.drawString(72, height - 72, "Report Title")
c.setFont("Helvetica", 12)
c.drawString(72, height - 100, "Generated automatically")
c.line(72, height - 110, width - 72, height - 110)
c.setFillColorRGB(0.18, 0.46, 0.71)
c.rect(72, height - 200, 200, 80, fill=1, stroke=0)
c.showPage()
c.save()
```

### Platypus (flow-based, recommended for multi-page docs)

```python
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors

doc = SimpleDocTemplate("report.pdf", pagesize=letter,
                        leftMargin=72, rightMargin=72, topMargin=72, bottomMargin=72)
styles = getSampleStyleSheet()
story = []

story.append(Paragraph("Annual Report 2024", styles["Title"]))
story.append(Spacer(1, 12))
story.append(Paragraph("This report covers fiscal year 2024 results.", styles["Normal"]))
story.append(Spacer(1, 12))

data = [["Quarter", "Revenue", "Growth"],
        ["Q1", "$1.2M", "+12%"],
        ["Q2", "$1.4M", "+17%"],
        ["Q4", "$1.8M", "+20%"]]
table = Table(data, colWidths=[120, 120, 120])
table.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2E74B5")),
    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#EBF3FB")]),
    ("ALIGN", (1, 0), (-1, -1), "CENTER"),
]))
story.append(table)
story.append(PageBreak())
story.append(Paragraph("Conclusion", styles["Heading1"]))

doc.build(story)
```

**IMPORTANT - reportlab sub/superscripts**: Never use Unicode sub/superscript characters (they render as black boxes). Use XML markup in Paragraph objects:
```python
Paragraph("H<sub>2</sub>O and E=mc<super>2</super>", styles["Normal"])
```

---

## pypdf - Form Field Inspection and Filling

```python
from pypdf import PdfReader, PdfWriter

# Read form fields
reader = PdfReader("form.pdf")
fields = reader.get_fields()
for name, field in fields.items():
    print(f"{name}: type={field.get('/FT')}, value={field.get('/V')}")

# Fill form fields
writer = PdfWriter()
writer.append(reader)
writer.update_page_form_field_values(
    writer.pages[0],
    {
        "first_name": "Max",
        "last_name": "Mustermann",
        "date": "2024-01-15",
        "checkbox_field": True,
    },
)
with open("filled_form.pdf", "wb") as f:
    writer.write(f)
```

---

## Overlay Watermark PDF

```python
from pypdf import PdfReader, PdfWriter

watermark_page = PdfReader("watermark.pdf").pages[0]
reader = PdfReader("document.pdf")
writer = PdfWriter()
for page in reader.pages:
    page.merge_page(watermark_page)
    writer.add_page(page)
with open("watermarked.pdf", "wb") as f:
    writer.write(f)
```

---

## Cheat Sheet

| Task | Library | Key call |
|------|---------|----------|
| Extract text | fitz | `page.get_text()` |
| Extract text with positions | fitz | `page.get_text("dict")` |
| Extract tables (native) | fitz | `page.find_tables()` |
| Extract tables (layout-aware) | pdfplumber | `page.extract_tables()` |
| PDF -> Markdown for LLM | pymupdf4llm | `to_markdown("file.pdf")` |
| Render page to image | fitz | `page.get_pixmap(matrix=fitz.Matrix(2,2))` |
| Extract embedded images | fitz | `doc.extract_image(xref)` |
| Add watermark / text | fitz | `page.insert_text(...)` |
| Overlay image on page | fitz | `page.insert_image(rect, filename=...)` |
| Search text in page | fitz | `page.search_for("text")` |
| Annotate (highlight, underline) | fitz | `page.add_highlight_annot(rect)` |
| Redact text permanently | fitz | `page.add_redact_annot(rect)` + `apply_redactions()` |
| Merge PDFs | fitz | `doc1.insert_pdf(doc2)` |
| Delete / move / copy pages | fitz | `doc.delete_page()` / `move_page()` / `copy_page()` |
| Bookmarks / TOC | fitz | `doc.get_toc()` / `doc.set_toc(toc)` |
| Draw shapes / lines | fitz | `page.draw_rect()` / `page.draw_line()` |
| Optimized save | fitz | `doc.save(garbage=4, deflate=True)` |
| Split / rotate / encrypt | pypdf | `PdfWriter` operations |
| Fill PDF forms | pypdf | `writer.update_page_form_field_values(...)` |
| Low-level repair | pikepdf | `pikepdf.open(...).save(...)` |
| Create from scratch | reportlab | Canvas or Platypus |

## Python Binary

Always run scripts as: `/opt/homebrew/bin/python3 script.py`
