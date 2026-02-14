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

## Header Row Update

If adding "Recent geopolitical trends" column to existing template:

1. Insert column M
2. Set header: "Recent geopolitical trends"
3. Shift "Analysis" to column N
4. Apply to all 3 sheets
