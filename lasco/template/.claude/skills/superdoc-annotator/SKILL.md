---
name: superdoc-annotator
description: Annotate, edit, and create DOCX files using the SuperDoc VS Code extension. Use when the user asks to "annotate this document", "add comments to this docx", "highlight text in this document", "add citations to this file", "link to sources in this document", "create a structured docx", "generate a legal document", "build a chronology docx", "add hyperlinks to this word file", or any request to manipulate or create DOCX files with annotations, comments, highlights, links, or structured content. Also triggers on "superdoc", "word document editing", or "docx manipulation".
tools: Read, Write, Edit, Glob, Grep, Bash, Task
allowed-tools: Bash(node scripts/superdoc-bridge.js:*), Bash(code --list-extensions:*)
---

# SuperDoc Annotator

Annotate, edit, and create DOCX files visible in the SuperDoc VS Code extension. All mutations use `scripts/superdoc-bridge.js` — a headless DOCX manipulation tool that writes directly to the `.docx` XML. Changes appear automatically in the SuperDoc editor without reload.

## Prerequisites

Check if SuperDoc is installed:
```bash
code --list-extensions 2>/dev/null | grep -i superdoc
```

If not installed, the commands still work — the DOCX files are valid and openable in any Word processor. SuperDoc just provides live preview.

## Core Commands

### 1. getDocument — Extract text from DOCX

```bash
node scripts/superdoc-bridge.js getDocument --file "<path>" --format text
```
- `--format text` returns plain text
- `--format json` returns structured JSON with paragraph metadata

**Use when:** You need to read a DOCX file's content before annotating it.

### 2. addComment — Add sidebar annotations

```bash
node scripts/superdoc-bridge.js addComment --file "<path>" \
  --find "<text to anchor on>" \
  --author "<author name>" \
  --text "<comment text>" \
  --no-refresh
```

**Use when:** Adding reviewer notes, verdict explanations, descriptive annotations. Appears in the SuperDoc sidebar.

### 3. addLink — Insert clickable hyperlinks

```bash
node scripts/superdoc-bridge.js addLink --file "<path>" \
  --find "<text to anchor after>" \
  --url "<url>" \
  --no-refresh
```

Inserts `(URL)` as clickable blue/underlined text **after** the target text. Does NOT modify existing text — only appends.

**Use when:** Adding source citations, cross-references to PDF viewer, or external links.

### 4. addHighlight — Highlight text with color

```bash
node scripts/superdoc-bridge.js addHighlight --file "<path>" \
  --find "<text to highlight>" \
  --color "<hex color>" \
  --no-refresh
```

**Common colors:**
| Purpose | Color |
|---------|-------|
| Error / Inaccurate | `#FFE0E0` (light red) |
| Warning / Misleading | `#FFF3CD` (light yellow) |
| Unverifiable | `#E2E3E5` (light gray) |
| Important / Positive | `#D4EDDA` (light green) |
| Info / Note | `#CCE5FF` (light blue) |

### 5. suggestEdit — Add tracked changes (redlines)

```bash
node scripts/superdoc-bridge.js suggestEdit --file "<path>" \
  --find "<original text>" \
  --replace "<corrected text>" \
  --author "<author name>" \
  --no-refresh
```

**Use when:** Suggesting corrections. Appears as a tracked change the user can accept or reject.

### 6. insertText — Add text at start or end

```bash
node scripts/superdoc-bridge.js insertText --file "<path>" \
  --at start|end \
  --text "<text to insert>" \
  --no-refresh
```

**Use when:** Adding summaries, headers, or appendices to existing documents.

### 7. createDocument — Build DOCX from JSON schema

```bash
echo '<json>' | node scripts/superdoc-bridge.js createDocument --file "<output_path>"
```

Builds a new `.docx` from a JSON content schema piped via stdin. See [JSON Schema Reference](#json-schema-reference-for-createdocument) below.

**Use when:** Creating new structured documents — chronologies, overviews, reports, tables.

### 8. refresh — Trigger SuperDoc reload

```bash
node scripts/superdoc-bridge.js refresh --file "<path>"
```

Touches the file timestamp to trigger VS Code file watcher. Call once after a batch of `--no-refresh` mutations.

## Text Search Gotcha

The `--find` argument matches against raw XML inside `<w:t>` tags. Word often splits text across XML runs at formatting boundaries (colons, style changes, font changes).

**Always use short, unique substrings:**
- BAD: `"Company: Anthropic PBC"` — colon splits runs
- BAD: `"Revenue Growth Rate: 45%"` — colon and percent may split
- GOOD: `"Anthropic PBC"`
- GOOD: `"Revenue Growth Rate"`

If `--find` doesn't match, try a shorter or different substring from the same passage.

## Batch Refresh Strategy

Every mutation command supports `--no-refresh` to suppress the 200ms auto-refresh. **Always use `--no-refresh` on every mutation command**, then call `refresh` once at the end:

```bash
# All mutations — no refresh
node scripts/superdoc-bridge.js addComment   --file "doc.docx" --find "..." --text "..." --no-refresh
node scripts/superdoc-bridge.js addHighlight --file "doc.docx" --find "..." --color "#FFE0E0" --no-refresh
node scripts/superdoc-bridge.js addLink      --file "doc.docx" --find "..." --url "..." --no-refresh

# Single refresh at the end
node scripts/superdoc-bridge.js refresh --file "doc.docx"
```

This prevents the SuperDoc editor from flashing once per command (e.g., 50 mutations = 50 refreshes → 1 refresh).

## Box ID Integration

When working with OCR-converted documents in `.lasco/md/`, you can create clickable links to specific locations in the PDF viewer.

**Box ID format:** `{safe_name}__p{page}__b{index}`
- Example: `Full_Hearing_Bundle_for_Advocacy_Exercise__p5__b2`

**URL format:** `http://localhost:8017?box={box_id}` (note: `?box=` not `/?box=`)

**Finding box IDs:**
1. Box JSON files are at: `.lasco/md/<safe_name>/boxes/page_X_boxes.json`
2. Each box has: `box_id`, `label`, `coordinate`, `block_content`
3. Use Grep to search: `Grep pattern="block_content.*keyword" path=".lasco/md/<safe_name>/boxes/"`
4. Read the matching file to extract the `box_id`

**Using box IDs with addLink:**
```bash
node scripts/superdoc-bridge.js addLink --file "doc.docx" \
  --find "Certificate of Incorporation" \
  --url "http://localhost:8017?box=Bundle-Sinfield_certificate-AOA__p1__b0" \
  --no-refresh
```

**Using box IDs in createDocument JSON:**
```json
{ "type": "link", "text": "Certificate of Incorporation", "url": "http://localhost:8017?box=Bundle-Sinfield_certificate-AOA__p1__b0" }
```

For detailed box ID documentation, see [references/box-id-system.md](references/box-id-system.md).

## Common Workflows

### A. Adding Source Citations to an Existing DOCX

```
1. Read the DOCX:
   node scripts/superdoc-bridge.js getDocument --file "doc.docx" --format text

2. Identify passages that need source citations

3. Find the box_id for each source:
   Grep: pattern="block_content.*relevant keyword" path=".lasco/md/<safe_name>/boxes/"
   Read the matching JSON file to extract box_id

4. Add links with --no-refresh:
   node scripts/superdoc-bridge.js addLink --file "doc.docx" \
     --find "passage text" --url "http://localhost:8017?box=<box_id>" --no-refresh

5. Repeat for all citations

6. Single refresh at end:
   node scripts/superdoc-bridge.js refresh --file "doc.docx"
```

### B. Creating a Structured Legal Document

```
1. Build JSON content schema with headings, paragraphs, tables
2. Include inline link elements for citations:
   {"type": "link", "text": "...", "url": "http://localhost:8017?box=<box_id>"}
3. Pipe JSON to createDocument:
   echo '<json>' | node scripts/superdoc-bridge.js createDocument --file "output.docx"
4. Document auto-appears in SuperDoc extension
```

### C. Highlighting Issues in a Document

```
1. Read document to identify problematic text
2. Highlight with color:
   node scripts/superdoc-bridge.js addHighlight --file "doc.docx" \
     --find "problematic claim" --color "#FFE0E0" --no-refresh
3. Add explanation comment:
   node scripts/superdoc-bridge.js addComment --file "doc.docx" \
     --find "problematic claim" --author "Reviewer" \
     --text "This claim contradicts the evidence at para 12." --no-refresh
4. Batch refresh:
   node scripts/superdoc-bridge.js refresh --file "doc.docx"
```

### D. Adding Reviewer Comments to a Draft

```
1. Read the document
2. For each annotation:
   node scripts/superdoc-bridge.js addComment --file "doc.docx" \
     --find "text to comment on" --author "Reviewer Name" \
     --text "Review comment here" --no-refresh
3. Single refresh at end
```

### E. Building a Document Overview with Hyperlinks

```
1. Build createDocument JSON with numbered paragraphs
2. Each document entry is an inline link element:
   {"type": "link", "text": "Document title dated DD.MM.YYYY", "url": "http://localhost:8017?box=<box_id>"}
3. Generate the DOCX:
   echo '<json>' | node scripts/superdoc-bridge.js createDocument --file "document_overview.docx"
```

## JSON Schema Reference for createDocument

### Top-Level Structure

```json
{
  "content": [
    { "type": "heading", ... },
    { "type": "paragraph", ... },
    { "type": "rule" },
    { "type": "table", ... }
  ]
}
```

### Block Types

| Type | Required Fields | Optional Fields |
|------|----------------|-----------------|
| `heading` | `level` (1-6), `text` or `children` | `alignment`, `spacing` |
| `paragraph` | `text` or `children` | `bullet` (level number), `alignment`, `spacing` |
| `rule` | (none) | — |
| `table` | `rows` | `columnWidths` (array of twips) |

### Inline Element Types (in `children` arrays)

| Type | Required Fields | Optional Fields |
|------|----------------|-----------------|
| `text` | `text` | `bold`, `italics`, `underline`, `color`, `size` |
| `link` | `text`, `url` | `bold`, `italics` |

### Table Structure

- `rows`: array of `{ isHeader?: boolean, cells: [] }`
- Each cell: `{ paragraphs: [{ children: [...] }], shading?: "#hex", text?: "shorthand" }`
- `columnWidths`: array of numbers in twips (1440 twips = 1 inch)
  - Values are proportional hints — auto-scaled to fit page width (9026 twips for A4)
  - Values summing to ≤ 9026 are used as-is; larger sums are proportionally scaled down

### Complete Example

```json
{
  "content": [
    { "type": "heading", "level": 1, "text": "Report Title" },
    { "type": "paragraph", "children": [
      { "type": "text", "text": "Normal text. " },
      { "type": "text", "text": "Bold text", "bold": true },
      { "type": "text", "text": " and a " },
      { "type": "link", "text": "hyperlink", "url": "http://localhost:8017?box=doc__p1__b0" },
      { "type": "text", "text": "." }
    ]},
    { "type": "paragraph", "bullet": 0, "text": "Top-level bullet" },
    { "type": "paragraph", "bullet": 1, "text": "Nested bullet" },
    { "type": "rule" },
    { "type": "table",
      "columnWidths": [2000, 4000, 3000],
      "rows": [
        { "isHeader": true, "cells": [
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Date", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Event", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Source", "bold": true }] }] }
        ]},
        { "cells": [
          { "text": "01.01.2024" },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Company incorporated" }] }] },
          { "paragraphs": [{ "children": [
            { "type": "link", "text": "Certificate of Incorporation", "url": "http://localhost:8017?box=doc__p5__b2" }
          ] }] }
        ]}
      ]
    }
  ]
}
```
