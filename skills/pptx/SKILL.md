---
name: pptx
description: "PowerPoint (.pptx) operations - create, read, edit slide decks and presentations. Trigger on any .pptx task: pitch decks, reports, templates, speaker notes, charts, slide layouts. Uses python-pptx for all operations. Not for PDF, DOCX, or Keynote."
license: MIT
---

# PPTX Skill - Presentation Operations

## Workflow Overview

| Task | Guide |
|------|-------|
| Read/analyze content | `python -m markitdown presentation.pptx` |
| Edit existing presentation | python-pptx `Presentation()` load - see Editing below |
| Create from scratch | python-pptx - see Creating from Scratch below |

---

## Reading Content

### Einlesen - Drei Methoden

| Method | Use case |
|--------|----------|
| **markitdown Python API** | Fastest: agent reads/analyzes full deck content as Markdown |
| **markitdown CLI** | Quick shell-level check, grep-friendly |
| **python-pptx** | Structured access: shapes, layout, notes, formatting, per-slide |

#### 1. markitdown Python API (Empfohlen fur Agent-Analyse)

```python
from markitdown import MarkItDown

result = MarkItDown().convert("presentation.pptx")
print(result.text_content)  # All slides as Markdown: slide text + speaker notes
```

Use this before editing to understand the full content. Every slide's text and notes are included.

#### 2. markitdown CLI

```bash
python -m markitdown presentation.pptx
```

#### 3. python-pptx (Strukturierter Vollzugriff)

```python
from pptx import Presentation

prs = Presentation("presentation.pptx")
print(f"{len(prs.slides)} slides, {prs.slide_width.inches:.1f} x {prs.slide_height.inches:.1f} in")

for i, slide in enumerate(prs.slides):
    print(f"--- Slide {i+1}: layout={slide.slide_layout.name} ---")
    for shape in slide.shapes:
        if shape.has_text_frame:
            for para in shape.text_frame.paragraphs:
                if para.text.strip():
                    print(f"  [{shape.name}] {para.text}")
    # Speaker notes
    if slide.has_notes_slide:
        notes = slide.notes_slide.notes_text_frame.text
        if notes.strip():
            print(f"  NOTES: {notes[:120]}")
```

---

## Editing Existing Presentations

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

prs = Presentation("existing.pptx")

# Find and replace text across all slides
for slide in prs.slides:
    for shape in slide.shapes:
        if not shape.has_text_frame:
            continue
        for para in shape.text_frame.paragraphs:
            for run in para.runs:
                if "old text" in run.text:
                    run.text = run.text.replace("old text", "new text")

# Modify a specific shape's formatting
slide = prs.slides[0]
for shape in slide.shapes:
    if shape.name == "Title 1":
        tf = shape.text_frame
        tf.paragraphs[0].runs[0].font.bold = True
        tf.paragraphs[0].runs[0].font.color.rgb = RGBColor(0x2E, 0x74, 0xB5)

# Reposition and resize any shape
for shape in slide.shapes:
    if shape.name == "Rectangle 1":
        shape.left = Inches(1)      # distance from left slide edge
        shape.top = Inches(2)       # distance from top slide edge
        shape.width = Inches(4)     # shape width
        shape.height = Inches(1.5)  # shape height

prs.save("modified.pptx")
```

---

## Creating from Scratch

```python
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# Create presentation with 16:9 aspect ratio
prs = Presentation()
prs.slide_width = Inches(13.33)
prs.slide_height = Inches(7.5)

# Slide layouts (built-in): 0=title, 1=title+content, 5=title only, 6=blank
slide = prs.slides.add_slide(prs.slide_layouts[6])  # blank

# Add text box
txBox = slide.shapes.add_textbox(Inches(1), Inches(0.5), Inches(11), Inches(1.2))
tf = txBox.text_frame
tf.word_wrap = True
p = tf.paragraphs[0]
p.text = "Slide Title"
p.alignment = PP_ALIGN.LEFT
run = p.runs[0]
run.font.bold = True
run.font.size = Pt(40)
run.font.color.rgb = RGBColor(0x1E, 0x27, 0x61)

# Add body text box
body = slide.shapes.add_textbox(Inches(1), Inches(2), Inches(7), Inches(4))
tf = body.text_frame
tf.word_wrap = True
p = tf.paragraphs[0]
p.text = "Key point one"
p.runs[0].font.size = Pt(18)

# Add filled rectangle (background banner, icon circle, etc.)
shape = slide.shapes.add_shape(
    1,  # MSO_SHAPE_TYPE.RECTANGLE
    Inches(0), Inches(0), Inches(13.33), Inches(1.0)
)
shape.fill.solid()
shape.fill.fore_color.rgb = RGBColor(0x1E, 0x27, 0x61)
shape.line.fill.background()  # no border

# Add image
pic = slide.shapes.add_picture("image.png", Inches(8.5), Inches(1.5), Inches(4))

# Add table
from pptx.util import Inches
tbl = slide.shapes.add_table(3, 3, Inches(1), Inches(2), Inches(8), Inches(3)).table
tbl.cell(0, 0).text = "Header"
tbl.columns[0].width = Inches(3)

# Speaker notes
slide.notes_slide.notes_text_frame.text = "Speaker notes go here."

prs.save("presentation.pptx")
```

### Common python-pptx Units

| Concept | Unit | Example |
|---------|------|---------|
| Position / size | Inches() or Emu | `Inches(2.5)` |
| Font size | Pt() | `Pt(18)` |
| Color | RGBColor(r, g, b) | `RGBColor(0x2E, 0x74, 0xB5)` |
| Raw EMU | 1 inch = 914400 EMU | `Emu(914400)` |

### Text Frames - Multi-Paragraph and Formatting

```python
from pptx.util import Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_AUTO_SIZE

txBox = slide.shapes.add_textbox(Inches(1), Inches(1.5), Inches(10), Inches(4))
tf = txBox.text_frame
tf.word_wrap = True

# Prevent text overflow: auto-shrink font to fit
tf.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE

# Internal margins
tf.margin_left = Inches(0.1)
tf.margin_right = Inches(0.1)
tf.margin_top = Inches(0.05)
tf.margin_bottom = Inches(0.05)

# First paragraph (already exists in new text frame)
p = tf.paragraphs[0]
p.alignment = PP_ALIGN.LEFT
run = p.add_run()
run.text = "Main point"
run.font.size = Pt(20)
run.font.bold = True
run.font.color.rgb = RGBColor(0x1E, 0x27, 0x61)

# Add more paragraphs
p2 = tf.add_paragraph()
p2.alignment = PP_ALIGN.LEFT
p2.space_before = Pt(6)     # space above paragraph
p2.space_after = Pt(0)
p2.line_spacing = Pt(22)
run2 = p2.add_run()
run2.text = "Supporting detail"
run2.font.size = Pt(14)
run2.font.color.rgb = RGBColor(0x44, 0x44, 0x44)

# Mixed formatting in one paragraph
p3 = tf.add_paragraph()
r_normal = p3.add_run()
r_normal.text = "Normal text and "
r_normal.font.size = Pt(14)
r_bold = p3.add_run()
r_bold.text = "bold emphasis"
r_bold.font.bold = True
r_bold.font.color.rgb = RGBColor(0x2E, 0x74, 0xB5)
```

### Slide Placeholders (Template-Based Workflow)

```python
from pptx import Presentation

prs = Presentation("template.pptx")

# List available layouts and their placeholders
for i, layout in enumerate(prs.slide_layouts):
    print(f"Layout {i}: {layout.name}")
    for ph in layout.placeholders:
        print(f"  ph idx={ph.placeholder_format.idx}, type={ph.placeholder_format.type}, name={ph.name}")

# Use a layout with predefined placeholders
slide = prs.slides.add_slide(prs.slide_layouts[1])  # "Title and Content"

# Access by placeholder index
title_ph = slide.placeholders[0]     # idx=0 is always title
content_ph = slide.placeholders[1]   # idx=1 is body content

title_ph.text = "Slide Title"
content_ph.text = "Body text here"

# Add bullet points to content placeholder
tf = content_ph.text_frame
tf.text = "First bullet"
p = tf.add_paragraph()
p.text = "Second bullet"
p.level = 0
p2 = tf.add_paragraph()
p2.text = "  Sub-bullet"
p2.level = 1

# Check if shape is a placeholder
for shape in slide.shapes:
    if shape.is_placeholder:
        print(f"ph {shape.placeholder_format.idx}: {shape.name}")

# Title shortcut
slide.shapes.title.text = "Quick Title Access"
```

### Slide Background Color

```python
from pptx.dml.color import RGBColor
from pptx.oxml.ns import qn
from lxml import etree

def set_slide_background(slide, hex_color: str):
    """Set solid background color on a slide."""
    background = slide.background
    fill = background.fill
    fill.solid()
    fill.fore_color.rgb = RGBColor.from_string(hex_color)

set_slide_background(slide, "1E2761")  # dark navy
set_slide_background(slide, "F5F5F5")  # off-white
```

### Charts

```python
from pptx.util import Inches
from pptx.chart.data import ChartData
from pptx.enum.chart import XL_CHART_TYPE

# Bar chart
chart_data = ChartData()
chart_data.categories = ["Q1", "Q2", "Q3", "Q4"]
chart_data.add_series("Revenue", (1.2, 1.4, 1.5, 1.8))
chart_data.add_series("Cost",    (0.8, 0.9, 1.0, 1.1))

chart = slide.shapes.add_chart(
    XL_CHART_TYPE.COLUMN_CLUSTERED,
    Inches(1), Inches(2), Inches(8), Inches(4),
    chart_data,
).chart

chart.has_title = True
chart.chart_title.text_frame.text = "Quarterly Performance"
chart.has_legend = True

# Line chart
line_data = ChartData()
line_data.categories = ["Jan", "Feb", "Mar", "Apr", "May"]
line_data.add_series("Growth %", (0.05, 0.08, 0.12, 0.10, 0.15))

slide.shapes.add_chart(
    XL_CHART_TYPE.LINE,
    Inches(1), Inches(2), Inches(8), Inches(4),
    line_data,
)

# Common chart types:
# XL_CHART_TYPE.COLUMN_CLUSTERED, COLUMN_STACKED, COLUMN_STACKED_100
# XL_CHART_TYPE.BAR_CLUSTERED, BAR_STACKED
# XL_CHART_TYPE.LINE, LINE_MARKERS
# XL_CHART_TYPE.PIE, DOUGHNUT
# XL_CHART_TYPE.AREA, AREA_STACKED
# XL_CHART_TYPE.XY_SCATTER
```

### Slide Copy and Deletion

```python
import copy
from lxml import etree

# Duplicate a slide (copy within same presentation)
def duplicate_slide(prs, slide_index):
    template = prs.slides[slide_index]
    blank_layout = prs.slide_layouts[6]
    new_slide = prs.slides.add_slide(blank_layout)
    new_slide.element.spTree.clear()
    for el in template.element.spTree:
        new_slide.element.spTree.append(copy.deepcopy(el))
    return new_slide

# Remove a slide
def remove_slide(prs, slide_index):
    xml_slides = prs.slides._sldIdLst
    slide = prs.slides[slide_index]
    xml_slides.remove(xml_slides[slide_index])

duplicate_slide(prs, 0)  # duplicate first slide
remove_slide(prs, 3)     # remove 4th slide (0-indexed)
```

---

## Design Ideas

**Don't create boring slides.** Plain bullets on a white background won't impress anyone. Consider ideas from this list for each slide.

### Before Starting

- **Pick a bold, content-informed color palette**: The palette should feel designed for THIS topic. If swapping your colors into a completely different presentation would still "work," you haven't made specific enough choices.
- **Dominance over equality**: One color should dominate (60-70% visual weight), with 1-2 supporting tones and one sharp accent. Never give all colors equal weight.
- **Dark/light contrast**: Dark backgrounds for title + conclusion slides, light for content ("sandwich" structure). Or commit to dark throughout for a premium feel.
- **Commit to a visual motif**: Pick ONE distinctive element and repeat it — rounded image frames, icons in colored circles, thick single-side borders. Carry it across every slide.

### Color Palettes

Choose colors that match your topic — don't default to generic blue. Use these palettes as inspiration:

| Theme | Primary | Secondary | Accent |
|-------|---------|-----------|--------|
| **Midnight Executive** | `1E2761` (navy) | `CADCFC` (ice blue) | `FFFFFF` (white) |
| **Forest & Moss** | `2C5F2D` (forest) | `97BC62` (moss) | `F5F5F5` (cream) |
| **Coral Energy** | `F96167` (coral) | `F9E795` (gold) | `2F3C7E` (navy) |
| **Warm Terracotta** | `B85042` (terracotta) | `E7E8D1` (sand) | `A7BEAE` (sage) |
| **Ocean Gradient** | `065A82` (deep blue) | `1C7293` (teal) | `21295C` (midnight) |
| **Charcoal Minimal** | `36454F` (charcoal) | `F2F2F2` (off-white) | `212121` (black) |
| **Teal Trust** | `028090` (teal) | `00A896` (seafoam) | `02C39A` (mint) |
| **Berry & Cream** | `6D2E46` (berry) | `A26769` (dusty rose) | `ECE2D0` (cream) |
| **Sage Calm** | `84B59F` (sage) | `69A297` (eucalyptus) | `50808E` (slate) |
| **Cherry Bold** | `990011` (cherry) | `FCF6F5` (off-white) | `2F3C7E` (navy) |

### For Each Slide

**Every slide needs a visual element** — image, chart, icon, or shape. Text-only slides are forgettable.

**Layout options:**
- Two-column (text left, illustration on right)
- Icon + text rows (icon in colored circle, bold header, description below)
- 2x2 or 2x3 grid (image on one side, grid of content blocks on other)
- Half-bleed image (full left or right side) with content overlay

**Data display:**
- Large stat callouts (big numbers 60-72pt with small labels below)
- Comparison columns (before/after, pros/cons, side-by-side options)
- Timeline or process flow (numbered steps, arrows)

**Visual polish:**
- Icons in small colored circles next to section headers
- Italic accent text for key stats or taglines

### Typography

**Choose an interesting font pairing** — don't default to Arial. Pick a header font with personality and pair it with a clean body font.

| Header Font | Body Font |
|-------------|-----------|
| Georgia | Calibri |
| Arial Black | Arial |
| Calibri | Calibri Light |
| Cambria | Calibri |
| Trebuchet MS | Calibri |
| Impact | Arial |
| Palatino | Garamond |
| Consolas | Calibri |

| Element | Size |
|---------|------|
| Slide title | 36-44pt bold |
| Section header | 20-24pt bold |
| Body text | 14-16pt |
| Captions | 10-12pt muted |

### Spacing

- 0.5" minimum margins
- 0.3-0.5" between content blocks
- Leave breathing room—don't fill every inch

### Avoid (Common Mistakes)

- **Don't repeat the same layout** — vary columns, cards, and callouts across slides
- **Don't center body text** — left-align paragraphs and lists; center only titles
- **Don't skimp on size contrast** — titles need 36pt+ to stand out from 14-16pt body
- **Don't default to blue** — pick colors that reflect the specific topic
- **Don't mix spacing randomly** — choose 0.3" or 0.5" gaps and use consistently
- **Don't style one slide and leave the rest plain** — commit fully or keep it simple throughout
- **Don't create text-only slides** — add images, icons, charts, or visual elements; avoid plain title + bullets
- **Don't forget text box padding** — when aligning lines or shapes with text edges, set `margin: 0` on the text box or offset the shape to account for padding
- **Don't use low-contrast elements** — icons AND text need strong contrast against the background; avoid light text on light backgrounds or dark text on dark backgrounds
- **NEVER use accent lines under titles** — these are a hallmark of AI-generated slides; use whitespace or background color instead

---

## QA (Required)

**Assume there are problems. Your job is to find them.**

Your first render is almost never correct. Approach QA as a bug hunt, not a confirmation step. If you found zero issues on first inspection, you weren't looking hard enough.

### Content QA

```bash
python -m markitdown output.pptx
```

Check for missing content, typos, wrong order.

**When using templates, check for leftover placeholder text:**

```bash
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|this.*(page|slide).*layout"
```

If grep returns results, fix them before declaring success.

### Visual QA

PPTX -> image rendering is not available (no LibreOffice). Use content QA only:

```bash
# Full text extraction
python -m markitdown output.pptx

# Check for leftover placeholder text
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|click to edit|placeholder"

# Check speaker notes
python -c "
from pptx import Presentation
prs = Presentation('output.pptx')
for i, slide in enumerate(prs.slides):
    notes = slide.notes_slide.notes_text_frame.text.strip()
    if notes:
        print(f'Slide {i+1} notes: {notes[:80]}')
"
```

**Content checklist before declaring done:**
- All placeholder text replaced
- No missing sections (slide count matches outline)
- No typos in titles
- Data/numbers match source
- Speaker notes present where needed

### Verification Loop

1. Generate slides with python-pptx
2. Run markitdown extraction and grep checks above
3. Fix any issues found
4. Re-run extraction to confirm
5. Declare done only after clean grep pass

**Do not declare success until content QA passes.**

---

## Text Hyperlinks

```python
from pptx.util import Pt
from pptx.dml.color import RGBColor
from pptx.opc.constants import RELATIONSHIP_TYPE as RT

# Add hyperlink to a run
p = tf.add_paragraph()
run = p.add_run()
run.text = "Visit our website"
run.font.color.rgb = RGBColor(0x2E, 0x74, 0xB5)
run.font.underline = True

# Create hyperlink relationship
hlink = run._r.get_or_add_rPr()
from pptx.oxml.ns import qn
from lxml import etree
hlinkClick = etree.SubElement(hlink, qn('a:hlinkClick'))
rId = slide.part.relate_to("https://example.com", RT.HYPERLINK, is_external=True)
hlinkClick.set(qn('r:id'), rId)
```

---

## Limitations

| Feature | Status |
|---------|--------|
| PPTX -> PDF | NOT available (no LibreOffice) |
| PPTX -> images | NOT available (no LibreOffice) |
| Animations / transitions | Read-only via XML; python-pptx cannot create them |
| SmartArt | Cannot create; can read/replace text in existing SmartArt via XML |
| 3D effects | Not supported by python-pptx |
| Connectors (arrows between shapes) | Basic support via `add_connector()` |
| Embedded video/audio | Not supported by python-pptx |

When a user requests PPTX -> PDF or image rendering, inform them explicitly: **"PPTX-zu-PDF-Konvertierung ist nicht verfugbar (kein LibreOffice installiert)."**

---

## Converting to Images

PPTX -> image rendering requires LibreOffice, which is not installed. Inform user explicitly when requested.

---

## Dependencies

- **python-pptx 1.0.2**: `from pptx import Presentation` - all creation and editing
- **markitdown 0.1.5** (Python API): `from markitdown import MarkItDown; MarkItDown().convert("file.pptx")` - full content as Markdown
- **markitdown 0.1.5** (CLI): `python -m markitdown presentation.pptx` - shell-level text extraction
- **PPTX -> PDF / images**: NOT available (no LibreOffice). Inform user explicitly when requested.
- **Python binary**: Always run as `/opt/homebrew/bin/python3 script.py`
