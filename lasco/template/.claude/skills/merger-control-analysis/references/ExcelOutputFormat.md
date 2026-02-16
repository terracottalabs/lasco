# Excel Output Format

## Target File

The output Excel file path is specified in the project CLAUDE.md under `## Data Sources`.

## Sheet Classification Rules

Determine which sheet to insert the row based on threshold analysis:

| Sheet | Condition |
|-------|-----------|
| **Thresholds met** | Both parties exceed ALL applicable jurisdictional thresholds |
| **Thresholds not met** | Either party is clearly below thresholds |
| **To be discussed** | Edge cases: borderline thresholds, voluntary filing beneficial, data gaps, or analyst discretion needed |

## Column Mapping

| Col | Header | Point # | Max Width |
|-----|--------|---------|-----------|
| A | Jurisdiction | 1 | 15 |
| B | {Year} Turnover {Party1} (Currency) | 2 | 30 |
| C | {Year} Turnover {Party2} (Currency) | 3 | 30 |
| D | What are the jurisdictional thresholds? | 4 | 50 |
| E | Is filing voluntary or mandatory? / Is there a standstill obligation? | 5 | 40 |
| F | Are there any special rules for foreign-to-foreign transactions? If yes, please specify. | 6 | 40 |
| G | Notification deadline and filing fee | 7 | 35 |
| H | Parties responsible for making the filing (e.g. both JV parents, JVCO parents etc) | 8 | 35 |
| I | Timing of review period | 9 | 40 |
| J | Sanctions/Penalties for failure to file (in foreign-to-foreign transaction, where applicable)? | 10 | 45 |
| K | Can directors be held liable for failure to file? | 11 | 35 |
| L | Recent enforcement trends | 12 | 50 |
| M | Recent geopolitical trends | 13 | 50 |
| N | Analysis | 14 | 60 |

## Cell Formatting

- **Text wrapping:** Enable for all cells (content is multi-line)
- **Vertical alignment:** Top
- **Font:** Match existing template (typically Calibri 11pt)

## Inserting a Row

Using openpyxl:

```python
from openpyxl import load_workbook

wb = load_workbook('output.xlsx')
sheet = wb['Thresholds met']  # or appropriate sheet

# Find next empty row
next_row = sheet.max_row + 1

# Insert data from scratchpad
data = [
    jurisdiction,      # A
    party1_turnover,   # B
    party2_turnover,   # C
    thresholds,        # D
    filing_mandatory,  # E
    foreign_rules,     # F
    deadline_fee,      # G
    responsible,       # H
    review_timing,     # I
    sanctions,         # J
    director_liability,# K
    enforcement,       # L
    geopolitical,      # M
    analysis,          # N
]

for col, value in enumerate(data, start=1):
    cell = sheet.cell(row=next_row, column=col)
    cell.value = value
    cell.alignment = Alignment(wrap_text=True, vertical='top')

wb.save('output.xlsx')
```

## Sources Sheet

All source citations live on a dedicated **"Sources"** sheet — the 4th sheet in the workbook. Main analysis sheets (Thresholds met, Thresholds not met, To be discussed) contain **no hyperlinks** on data cells.

### Main Sheet Note

Each main sheet gets a subtle italic note in a merged row (row 1) above the header row:

```
See 'Sources' sheet for full source citations and hyperlinks.
```

This is merged across all 14 columns (A–N), italic, grey font, and the header row shifts to row 2.

### Sources Sheet Structure

The "Sources" sheet has 5 columns:

| Col | Header | Width | Content |
|-----|--------|-------|---------|
| A | Jurisdiction | 18 | Country name |
| B | Analysis Column | 30 | e.g. "B - Party 1 Turnover" |
| C | Source Description | 55 | Human-readable citation |
| D | Source Link | 45 | Clickable hyperlink (display text: "View in document viewer" / truncated URL / filename) |
| E | Source Type | 14 | "Document Viewer" / "Website" / "Local File" / "Text Only" |

### Source Type Mapping

| `source_type` value | Display text | When to use |
|---------------------|-------------|-------------|
| `document_viewer` | Document Viewer | URL contains `localhost:8017?box=` |
| `website` | Website | Any other http/https URL |
| `local_file` | Local File | File path (PDF, JPG, etc.) |
| `text_only` | Text Only | No linkable URL; description-only citation |

### Sources Sheet Formatting

- Auto-filter on all columns (row 1)
- Freeze panes at A2 (header row stays visible)
- Header row: bold, bottom border, light grey fill
- Text wrapping enabled on all cells
- Vertical alignment: top

### Data Structure

Each jurisdiction uses a `sources` list instead of `source_urls`:

```python
"sources": [
    {
        "column": "B",
        "column_label": "Party 1 Turnover",
        "description": "Rio Tinto Annual Report 2024, p.167",
        "url": "http://localhost:8017?box=rio_annual_report__p167__b0",
        "source_type": "document_viewer"
    },
    {
        "column": "C",
        "column_label": "Party 2 Turnover",
        "description": "Codelco Operational Report 2024, Revenue section",
        "url": "",
        "source_type": "text_only"
    },
    # ... one entry per column A-N
]
```

### Column Labels Mapping

```python
COLUMN_LABELS = {
    "A": "Jurisdiction",
    "B": "Party 1 Turnover",
    "C": "Party 2 Turnover",
    "D": "Thresholds",
    "E": "Mandatory/Standstill",
    "F": "Foreign Rules",
    "G": "Deadline/Fee",
    "H": "Responsible Parties",
    "I": "Review Timing",
    "J": "Sanctions",
    "K": "Director Liability",
    "L": "Enforcement Trends",
    "M": "Geopolitical Trends",
    "N": "Analysis",
}
```

### Source URL Resolution Helper

```python
import os

def resolve_source_url(url):
    """Resolve a source URL for use in the Excel hyperlink.
    Returns (resolved_url, display_text, source_type).
    """
    if not url:
        return ("", "", "text_only")

    if "localhost:8017?box=" in url or "localhost:8017/?box=" in url:
        return (url, "View in document viewer", "document_viewer")

    if url.startswith(("http://", "https://")):
        # Truncate long URLs for display
        display = url if len(url) <= 60 else url[:57] + "..."
        return (url, display, "website")

    # Local file path — convert to absolute file:// URL
    abs_path = os.path.abspath(url)
    file_url = f"file:///{abs_path}"
    filename = os.path.basename(abs_path)
    return (file_url, filename, "local_file")
```

### Populate Sources Sheet Function

```python
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.worksheet.hyperlink import Hyperlink
from openpyxl.utils import get_column_letter

def populate_sources_sheet(wb, jurisdictions_data):
    """Create and populate the Sources sheet.

    Args:
        wb: openpyxl Workbook
        jurisdictions_data: list of dicts, each with "jurisdiction" and "sources" keys
    """
    if "Sources" in wb.sheetnames:
        ws = wb["Sources"]
    else:
        ws = wb.create_sheet("Sources")

    # Column widths
    col_widths = {"A": 18, "B": 30, "C": 55, "D": 45, "E": 14}
    for col_letter, width in col_widths.items():
        ws.column_dimensions[col_letter].width = width

    # Header row
    headers = ["Jurisdiction", "Analysis Column", "Source Description", "Source Link", "Source Type"]
    header_fill = PatternFill(start_color="F2F2F2", end_color="F2F2F2", fill_type="solid")
    header_border = Border(bottom=Side(style="thin"))

    for col_idx, header in enumerate(headers, start=1):
        cell = ws.cell(row=1, column=col_idx, value=header)
        cell.font = Font(bold=True)
        cell.fill = header_fill
        cell.border = header_border
        cell.alignment = Alignment(wrap_text=True, vertical="top")

    # Freeze panes and auto-filter
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = f"A1:E1"

    # Populate data rows
    current_row = 2
    for jur_data in jurisdictions_data:
        jurisdiction = jur_data["jurisdiction"]
        sources = jur_data.get("sources", [])

        for src in sources:
            col_key = src.get("column", "")
            col_label = src.get("column_label", COLUMN_LABELS.get(col_key, ""))
            description = src.get("description", "")
            raw_url = src.get("url", "")

            resolved_url, display_text, source_type = resolve_source_url(raw_url)

            # Source type display mapping
            type_display = {
                "document_viewer": "Document Viewer",
                "website": "Website",
                "local_file": "Local File",
                "text_only": "Text Only",
            }.get(source_type, "Text Only")

            # A - Jurisdiction
            ws.cell(row=current_row, column=1, value=jurisdiction).alignment = Alignment(
                wrap_text=True, vertical="top"
            )
            # B - Analysis Column
            ws.cell(row=current_row, column=2, value=f"{col_key} - {col_label}").alignment = Alignment(
                wrap_text=True, vertical="top"
            )
            # C - Source Description
            ws.cell(row=current_row, column=3, value=description).alignment = Alignment(
                wrap_text=True, vertical="top"
            )
            # D - Source Link
            link_cell = ws.cell(row=current_row, column=4)
            if resolved_url:
                link_cell.value = display_text
                link_cell.hyperlink = Hyperlink(ref=f"D{current_row}", target=resolved_url)
                link_cell.font = Font(color="0563C1", underline="single")
            else:
                link_cell.value = ""
            link_cell.alignment = Alignment(wrap_text=True, vertical="top")
            # E - Source Type
            ws.cell(row=current_row, column=5, value=type_display).alignment = Alignment(
                wrap_text=True, vertical="top"
            )

            current_row += 1
```

### Main Sheet Note Insertion

When inserting data into a main sheet, add the sources note in row 1:

```python
from openpyxl.utils import get_column_letter

def add_sources_note(ws):
    """Add a 'See Sources sheet' note in row 1 of a main analysis sheet."""
    ws.merge_cells("A1:N1")
    note_cell = ws.cell(row=1, column=1, value="See 'Sources' sheet for full source citations and hyperlinks.")
    note_cell.font = Font(italic=True, color="808080", size=9)
    note_cell.alignment = Alignment(horizontal="center", vertical="center")
```

When this note is present, the header row moves to row 2 and data starts at row 3. Check `ws.max_row` accordingly.

### Integration with Main Sheet Insertion

The main sheet insertion loop should **not** add hyperlinks to data cells. Only set `cell.value` and `cell.alignment`:

```python
for col, value in enumerate(data, start=1):
    cell = sheet.cell(row=next_row, column=col)
    cell.value = value
    cell.alignment = Alignment(wrap_text=True, vertical='top')
# No hyperlink logic here — all sources go to the Sources sheet
```

## Header Row Update

If adding "Recent geopolitical trends" column to existing template:

1. Insert column M
2. Set header: "Recent geopolitical trends"
3. Shift "Analysis" to column N
4. Apply to all 3 sheets
