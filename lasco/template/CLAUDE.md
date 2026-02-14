# Lasco Demo - Project Context

## Case Overview

askUserQuestion

-   User name:
    
-   Representing:
    

## Platform Notes

-   **Path separators**: All scripts use `path.resolve()` (Node.js) — forward slashes work on both platforms

-   **Document conversion**: Handled automatically by the lasco-file-watcher extension — no manual invocation needed
    

## Document Conversion Pipeline

This project contains legal case documents that have been OCR-converted to Markdown using a custom pipeline in `.lasco/`.

### Structure

```
.lasco/
  tracker.json              # Conversion state tracker - CHECK THIS FIRST
  md/
    <doc_name>/             # One folder per converted document
      <doc_name>_1.md       # Per-page markdown
      <doc_name>_2.md
      combined.md           # All pages merged
      imgs/                 # Extracted images
```

### How Conversion Works

The **lasco-file-watcher** extension handles all document conversion automatically when the project is opened — no manual script invocation is required.

-   **PDFs & images** -> The file watcher uploads to PaddleOCR async API, polls for results, downloads JSONL, extracts bounding boxes, and saves per-page markdown + images

-   **Word docs (.docx/.doc)** -> `markitdown` CLI tool (outputs markdown directly)

-   All conversions tracked in `.lasco/tracker.json` with status, page count, timestamps, and errors
    

### Tracker (`tracker.json`)

The tracker is the source of truth for what has been converted. Each entry has:

-   `status`: `success` | `failed` | `processing` | `pending`
    
-   `source_file`: original filename
    
-   `output_dir`: path to the markdown output folder
    
-   `page_count`: number of pages extracted
    
-   `converter`: `paddleocr` or `markitdown`
    

**On session start, check** `tracker.json` **to see which documents are available as markdown and which still need conversion.**

### Reading Converted Documents

To read a converted document, look up its `safe_name` in the tracker and read:

```
.lasco/md/<safe_name>/combined.md
```

### Box IDs and Document Citations

**CRITICAL RULE: All document references MUST include hyperlinks using box\_ids.**

Every time you reference a specific part of a document (a page, paragraph, section, or exhibit), you MUST:

1.  Find the exact box\_id from the `.lasco/md/<safe_name>/boxes/page_X_boxes.json` files

2.  Create a clickable hyperlink using the appropriate format:
    -   **In DOCX output** (via `createDocument`): Use an inline link element: `{ "type": "link", "text": "Document description", "url": "http://localhost:8017?box=<box_id>" }`
    -   **In chat responses**: Use markdown link syntax: `[Document description](http://localhost:8017?box=<box_id>)`

3.  Never reference a document location without providing its box\_id hyperlink
    

**How to find box\_ids:**

-   Box JSON files are located at: `.lasco/md/<safe_name>/boxes/page_X_boxes.json`
    
-   Each box has a `box_id` field in format: `{safe_name}__p{page}__b{index}`
    
-   Each box contains `label`, `coordinate`, `block_content`, and `box_id`
    
-   Search through the boxes to find the one matching your target content
    

**Box ID Format:** `{safe_name}__p{page}__b{index}`

-   Example: `2024-2025_CA_SG2_Hearing_Bundle_-_Item_6_A_copy__p1__b1`
    

**URL Format:** `http://localhost:8017?box={box_id}` (note: use `?box=` not `/?box=`)

This clickable link system allows users to instantly navigate to the exact location in the PDF viewer with the relevant box highlighted.

* * *

## SuperDoc Bridge — DOCX Annotation Tool

The script `scripts/superdoc-bridge.js` provides headless DOCX manipulation visible in the SuperDoc VS Code extension. Changes appear automatically without window reload.

### Available Commands

<table style="min-width: 75px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th colspan="1" rowspan="1"><p>Command</p></th><th colspan="1" rowspan="1"><p>Purpose</p></th><th colspan="1" rowspan="1"><p>Key Args</p></th></tr><tr><td colspan="1" rowspan="1"><p><code>getDocument</code></p></td><td colspan="1" rowspan="1"><p>Extract plain text</p></td><td colspan="1" rowspan="1"><p><code>--file</code>, <code>--format text|json</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>addComment</code></p></td><td colspan="1" rowspan="1"><p>Add sidebar comment anchored to text</p></td><td colspan="1" rowspan="1"><p><code>--file</code>, <code>--find</code>, <code>--text</code>, <code>[--author]</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>addLink</code></p></td><td colspan="1" rowspan="1"><p>Insert clickable URL in parentheses after text</p></td><td colspan="1" rowspan="1"><p><code>--file</code>, <code>--find</code>, <code>--url</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>addHighlight</code></p></td><td colspan="1" rowspan="1"><p>Highlight text with color</p></td><td colspan="1" rowspan="1"><p><code>--file</code>, <code>--find</code>, <code>[--color]</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>suggestEdit</code></p></td><td colspan="1" rowspan="1"><p>Add tracked change (redline)</p></td><td colspan="1" rowspan="1"><p><code>--file</code>, <code>--find</code>, <code>--replace</code>, <code>[--author]</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>insertText</code></p></td><td colspan="1" rowspan="1"><p>Add text at start/end of document</p></td><td colspan="1" rowspan="1"><p><code>--file</code>, <code>--at start|end</code>, <code>--text</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>createDocument</code></p></td><td colspan="1" rowspan="1"><p>Create a new DOCX from JSON schema (stdin)</p></td><td colspan="1" rowspan="1"><p><code>--file</code></p></td></tr></tbody></table>

### Comments vs Hyperlinks

-   **Comments** (`addComment`): For descriptive annotations, reviewer notes, explanations. Appears in the SuperDoc sidebar. Use for analysis, verdicts, and detailed notes.
    
-   **Hyperlinks** (`addLink`): For source URLs and citations that should be visible inline. Inserts `(URL)` as clickable blue/underlined text after the target. **Does NOT modify existing text** — only appends.
    

### Text Search Gotcha

The `--find` argument matches against raw XML inside `<w:t>` tags. Word often splits text across XML runs at formatting boundaries (colons, style changes). **Use short, unique substrings**:

-   BAD: `"Company: Anthropic PBC"` (colon splits runs)
    
-   GOOD: `"Anthropic PBC"`
    

### Example Usage

```bash
# Add a source citation as inline hyperlink
node scripts/superdoc-bridge.js addLink --file "doc.docx" \
  --find "Anthropic PBC" --url "http://localhost:8017?box=doc__p3__b0"

# Add a reviewer comment
node scripts/superdoc-bridge.js addComment --file "doc.docx" \
  --find "revenue growth" --author "Reviewer" --text "Verify against Q4 filing"

# Highlight a problematic claim
node scripts/superdoc-bridge.js addHighlight --file "doc.docx" \
  --find "material risk" --color "#FFE0E0"
```

### Technical Notes

-   Uses JSZip for XML manipulation (NOT the SuperDoc Editor API — that was tested and comments were not visible)
    
-   Atomic writes (`.tmp` → rename) prevent SuperDoc from reading half-written files
    
-   Auto-refresh touches file timestamp after write to trigger VS Code file watcher
    
-   Pass `--no-refresh` to any mutation command to suppress the 200ms refresh; then call `node scripts/superdoc-bridge.js refresh --file <path>` once after a batch of commands to trigger a single reload
    

### Creating Documents (`createDocument`)

The `createDocument` command builds a new `.docx` file from a JSON content schema piped via stdin. The generated file is viewable in the SuperDoc VS Code extension.

**Usage:**

```bash
echo '<json>' | node scripts/superdoc-bridge.js createDocument --file "output.docx"
```

**JSON Schema:**

The input JSON must have a top-level `content` array. Each element is a block:

```json
{
  "content": [
    { "type": "heading", "level": 1, "text": "Title" },
    { "type": "heading", "level": 2, "children": [
      { "type": "text", "text": "Styled heading", "bold": true }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "Normal text. " },
      { "type": "text", "text": "Bold text", "bold": true },
      { "type": "link", "text": "Click here", "url": "http://example.com" }
    ]},
    { "type": "paragraph", "bullet": 0, "text": "Top-level bullet" },
    { "type": "paragraph", "bullet": 1, "text": "Nested bullet" },
    { "type": "rule" },
    { "type": "table",
      "columnWidths": [1400, 3026, 1800, 1800, 1000],
      "rows": [
        { "isHeader": true, "cells": [
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Date", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Event", "bold": true }] }] }
        ]},
        { "cells": [
          { "paragraphs": [{ "children": [{ "type": "text", "text": "01.01.2024" }] }] },
          { "paragraphs": [
            { "children": [{ "type": "text", "text": "Something happened" }] },
            { "children": [{ "type": "link", "text": "Source", "url": "http://localhost:8017?box=doc__p1__b0" }] }
          ]}
        ]}
      ]
    }
  ]
}
```

**Block types:**

<table style="min-width: 75px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th colspan="1" rowspan="1"><p>Type</p></th><th colspan="1" rowspan="1"><p>Required Fields</p></th><th colspan="1" rowspan="1"><p>Optional Fields</p></th></tr><tr><td colspan="1" rowspan="1"><p><code>heading</code></p></td><td colspan="1" rowspan="1"><p><code>level</code> (1-6), <code>text</code> or <code>children</code></p></td><td colspan="1" rowspan="1"><p><code>alignment</code>, <code>spacing</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>paragraph</code></p></td><td colspan="1" rowspan="1"><p><code>text</code> or <code>children</code></p></td><td colspan="1" rowspan="1"><p><code>bullet</code> (level number), <code>alignment</code>, <code>spacing</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>rule</code></p></td><td colspan="1" rowspan="1"><p>(none)</p></td><td colspan="1" rowspan="1"><p>—</p></td></tr><tr><td colspan="1" rowspan="1"><p><code>table</code></p></td><td colspan="1" rowspan="1"><p><code>rows</code></p></td><td colspan="1" rowspan="1"><p><code>columnWidths</code> (array of twips)</p></td></tr></tbody></table>

**Inline element types** (used in `children` arrays):

<table style="min-width: 75px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th colspan="1" rowspan="1"><p>Type</p></th><th colspan="1" rowspan="1"><p>Required Fields</p></th><th colspan="1" rowspan="1"><p>Optional Fields</p></th></tr><tr><td colspan="1" rowspan="1"><p><code>text</code></p></td><td colspan="1" rowspan="1"><p><code>text</code></p></td><td colspan="1" rowspan="1"><p><code>bold</code>, <code>italics</code>, <code>underline</code>, <code>color</code>, <code>size</code></p></td></tr><tr><td colspan="1" rowspan="1"><p><code>link</code></p></td><td colspan="1" rowspan="1"><p><code>text</code>, <code>url</code></p></td><td colspan="1" rowspan="1"><p><code>bold</code>, <code>italics</code></p></td></tr></tbody></table>

**Table structure:**

-   `rows`: array of `{ isHeader?: boolean, cells: [] }`
    
-   Each cell: `{ paragraphs: [{ children: [...] }], shading?: "#hex", text?: "shorthand" }`
    
-   `columnWidths`: array of numbers in twips (1440 twips = 1 inch). Values are treated as proportional hints — the script uses fixed table layout and auto-scales column widths to fit the available page width (9026 twips for A4 with 1-inch margins). Each cell automatically receives an explicit width matching its column. Values that already sum to ≤ 9026 are used as-is; values exceeding 9026 are proportionally scaled down
    

**Example: Generating a chronology DOCX**

```bash
cat <<'ENDJSON' | node scripts/superdoc-bridge.js createDocument --file "chronology.docx"
{
  "content": [
    { "type": "heading", "level": 1, "text": "Chronology" },
    { "type": "paragraph", "bullet": 0, "children": [
      { "type": "text", "text": "Sinefield Limited", "bold": true }
    ]},
    { "type": "table",
      "columnWidths": [1400, 3026, 1800, 1800, 1000],
      "rows": [
        { "isHeader": true, "cells": [
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Date", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Event", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Reference", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Supporting Document", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Provided By", "bold": true }] }] }
        ]},
        { "cells": [
          { "text": "20.09.2013" },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Company incorporated" }] }] },
          { "paragraphs": [{ "children": [
            { "type": "link", "text": "Statement of Claim, para 1", "url": "http://localhost:8017?box=doc__p1__b0" }
          ] }] },
          { "paragraphs": [{ "children": [
            { "type": "link", "text": "Certificate of Incorporation", "url": "http://localhost:8017?box=doc__p5__b2" }
          ] }] },
          { "text": "Plaintiff" }
        ]}
      ]
    }
  ]
}
ENDJSON
```

* * *

## Task: Document Overview / List of Documents

**Trigger:** User asks for "list of documents", "what documents are there", "overview of files", "summary of documents", "what's in the bundle", "index of documents", or similar.

**Output File:** Save the document overview as a DOCX file named `document_overview_[case_name].docx` (e.g., `document_overview_sung_v_wan.docx`) using the `createDocument` command. Save in the project root directory.

### Output Format

Use the `createDocument` command to produce a DOCX file. The JSON content should follow this structure — a heading followed by numbered paragraphs with inline link elements for each document:

```json
{
  "content": [
    { "type": "heading", "level": 1, "text": "Document Overview" },
    { "type": "paragraph", "children": [
      { "type": "text", "text": "1. " },
      { "type": "link", "text": "Document description dated [date]", "url": "http://localhost:8017?box=<box_id>" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "2. " },
      { "type": "link", "text": "Document description dated [date]", "url": "http://localhost:8017?box=<box_id>" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "3. " },
      { "type": "link", "text": "Document description dated [date]", "url": "http://localhost:8017?box=<box_id>" },
      { "type": "text", "text": " together with:" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (a) " },
      { "type": "link", "text": "sub-document", "url": "http://localhost:8017?box=<box_id>" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (b) " },
      { "type": "link", "text": "sub-document", "url": "http://localhost:8017?box=<box_id>" },
      { "type": "text", "text": "; and" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (c) " },
      { "type": "link", "text": "sub-document", "url": "http://localhost:8017?box=<box_id>" },
      { "type": "text", "text": "." }
    ]}
  ]
}
```

### Formatting Rules

**Document Descriptions** - Use formal legal descriptions:

-   "Certificate of Incorporation" not "COI"
    
-   "Memorandum and Articles of Association" not "M&A" or "MOA/AOA"
    
-   "Minutes of \[meeting type\] held on \[date\]" not just "minutes"
    
-   "Notice of Change of Company Secretary and Director" not "Form ND2A"
    
-   Always include dates where available
    

**Hyperlinks** - MANDATORY for every document:

-   Every document in the list MUST have a clickable hyperlink using its box\_id

-   Format: Use an inline link element in the `createDocument` JSON:
    ```json
    { "type": "link", "text": "Document description dated [date]", "url": "http://localhost:8017?box=<box_id>" }
    ```
    where `<box_id>` is the box\_id from the first page or most relevant page of that document

-   Find box\_ids in `.lasco/md/<safe_name>/boxes/page_X_boxes.json` files

-   For multi-page documents, use the box\_id from the title page or first substantive page

-   Sub-documents (a), (b), (c) should also have individual hyperlinks if they appear on different pages or sections

-   Example:
    ```json
    { "type": "link", "text": "Certificate of Incorporation dated 20 September 2013", "url": "http://localhost:8017?box=2024-2025_CA_SG2_Hearing_Bundle_-_Item_6_A_copy__p5__b2" }
    ```
    

**Grouping:**

-   Related documents → group with sub-items (a), (b), (c)
    
-   Correspondence with enclosures → main item + sub-items for attachments
    
-   Use "together with:" before sub-items
    

**Order:**

1.  Constitutional documents first (Certificate of Incorporation, M&A, AOA)
    
2.  Then chronological by event/document date
    
3.  Attendance notes typically last
    

**Cross-References:** Define abbreviations on first use: `Sinefield (Guangdong) Limited (the "PRC Company")`

### Example

```json
{
  "content": [
    { "type": "heading", "level": 1, "text": "Document Overview" },
    { "type": "paragraph", "children": [
      { "type": "text", "text": "1. " },
      { "type": "link", "text": "Certificate of Incorporation, the Memorandum of Association, and Extracts of the Articles of Association of the Company dated 20 September 2013", "url": "http://localhost:8017?box=Bundle-Sinfield_certificate-AOA__p1__b0" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "2. " },
      { "type": "link", "text": "English translations of the extracts of the Memorandum and Articles of Association of Sinefield (Guangdong) Limited (the \"PRC Company\") dated 5 August 2014", "url": "http://localhost:8017?box=Sinfield_MOA_-_2013_and_2014__p7__b1" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "3. " },
      { "type": "link", "text": "Annual Return of the Company dated 20 September 2023", "url": "http://localhost:8017?box=Bundle-AR_Sinfield__p1__b0" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "4. " },
      { "type": "link", "text": "Fax from Larry David & Sons Limited to lay client dated 15 September 2024", "url": "http://localhost:8017?box=20240915_notice_of_board_meeting_minute__p1__b0" },
      { "type": "text", "text": " together with a " },
      { "type": "link", "text": "purported notice of board meeting of the Company", "url": "http://localhost:8017?box=20240915_notice_of_board_meeting_minute__p2__b0" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "5. Correspondence dated 17 September 2024 together with:" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (a) " },
      { "type": "link", "text": "letter dated 17 September 2024 from the Company to lay client dismissing him as a director", "url": "http://localhost:8017?box=20240826_removal_of_director_ND2A_Atte_Note__p1__b0" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (b) " },
      { "type": "link", "text": "purported minutes of an extraordinary general meeting of all members of the Company held on 26 August 2024 at 11:00 a.m.", "url": "http://localhost:8017?box=20240826_removal_of_director_ND2A_Atte_Note__p3__b2" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (c) " },
      { "type": "link", "text": "purported minutes of a meeting of the board of directors of the PRC Company held on 26 August 2024 at 11:45 a.m.", "url": "http://localhost:8017?box=20240826_removal_of_director_ND2A_Atte_Note__p5__b1" },
      { "type": "text", "text": ";" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (d) " },
      { "type": "link", "text": "purported minutes of a meeting of the board of directors of the Company held on 16 September 2024", "url": "http://localhost:8017?box=20240915_notice_of_board_meeting_minute__p3__b0" },
      { "type": "text", "text": "; and" }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "   (e) " },
      { "type": "link", "text": "Notice of Change of Company Secretary and Director dated 17 September 2024", "url": "http://localhost:8017?box=20240826_removal_of_director_ND2A_Atte_Note__p8__b0" },
      { "type": "text", "text": "." }
    ]},
    { "type": "paragraph", "children": [
      { "type": "text", "text": "6. " },
      { "type": "link", "text": "Attendance note of meeting with Mr. Jerry Sung on 23 September 2024", "url": "http://localhost:8017?box=20240923_attendence_note_Jerry_side__p1__b0" },
      { "type": "text", "text": "." }
    ]}
  ]
}
```

Note: The box\_ids in this example are illustrative. In actual use, you must search the relevant box JSON files to find the correct box\_ids for each document.

### Process

1.  Check `tracker.json` for all converted documents

2.  Read each `combined.md` to understand contents and extract dates

3.  For each document, identify the appropriate page and search the corresponding `boxes/page_X_boxes.json` file to find the box\_id for the title or first substantive content

4.  Categorize: constitutional, filings, correspondence, minutes, attendance notes

5.  Build the `createDocument` JSON with numbered paragraphs, inline link elements, and appropriate grouping for every document reference

6.  **Save the output** as a DOCX file using the `createDocument` command:

    -   Filename format: `document_overview_[case_name].docx`

    -   Example: `document_overview_sung_v_wan.docx`

    -   Save in the project root directory

7.  Inform the user that the document overview has been saved to the file
    

* * *

## Task: Chronology

**Trigger:** User requests a "chronology", "timeline", "sequence of events", or similar.

**Output File:** Save the completed chronology in a separate document file named `chronology_[party]_[case_name].docx` (e.g., `chronology_plaintiff_homer_v_monty.docx`)

### Output Format

**1\. Header** - Before the table, summarize key entities and persons using bullet paragraphs in the `createDocument` JSON:

```json
[
  { "type": "paragraph", "bullet": 0, "children": [
    { "type": "text", "text": "Sinefield Limited", "bold": true }
  ]},
  { "type": "paragraph", "bullet": 1, "text": "Jerry Sung (45%); Elaine Wan (45%); George Lau (10%)" },
  { "type": "paragraph", "bullet": 1, "text": "Directors: JS, EW, GL" },
  { "type": "paragraph", "bullet": 0, "children": [
    { "type": "text", "text": "Sinefield (Guangdong) Limited", "bold": true },
    { "type": "text", "text": " – wholly owned subsidiary of Sinefield Limited" }
  ]}
]
```

**2\. Table Structure:**

<table style="min-width: 125px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th colspan="1" rowspan="1"><p>Date</p></th><th colspan="1" rowspan="1"><p>Event</p></th><th colspan="1" rowspan="1"><p>Reference</p></th><th colspan="1" rowspan="1"><p>Supporting Document</p></th><th colspan="1" rowspan="1"><p>Provided By</p></th></tr></tbody></table>

-   **Date**: DD.MM.YYYY format. For imprecise dates: "August 2013", "Shortly after incorporation"
    
-   **Event**: Concise bullet points describing what happened
    
-   **Reference**: Court document name + paragraph/page (e.g., "Statement of Claim, para 3, p.4" or "Defence and Counterclaim, para 9, p.12"). Make the citation a clickable link using an inline link element in the `createDocument` JSON:
    ```json
    { "type": "link", "text": "Statement of Claim, para 3, p.4", "url": "http://localhost:8017?box=<box_id>" }
    ```
    Find the box\_id in the `.lasco/md/<safe_name>/boxes/page_X_boxes.json` files. Search page by page to find the exact box matching your referenced content.

-   **Supporting Document**: Actual evidence document + page number (e.g., "Purchase Order No. MU 7338, p.25" or "Repayment Agreement, pp.44-46"). If no supporting document exists, state "None". Make the citation a clickable link using an inline link element in the `createDocument` JSON:
    ```json
    { "type": "link", "text": "Purchase Order No. MU 7338, p.25 (Exhibit HSS-1)", "url": "http://localhost:8017?box=<box_id>" }
    ```
    Find the box\_id in the `.lasco/md/<safe_name>/boxes/page_X_boxes.json` files. Search page by page to find the exact box matching your referenced content.
    
-   **Provided By**: Who produced the document - "Plaintiff", "Defendant", or "Court"
    

### Writing Style

**Abbreviations:** On first mention, use full name with abbreviation: `Jerry Sung ("JS")`, `Sinefield Limited (the "Company")`. Use abbreviation thereafter.

**Events:**

-   Bullet points, not prose
    
-   Facts only - no interpretation
    
-   Include: names, percentages, amounts, positions, dates
    
-   For meetings/resolutions: type, attendees, what was resolved, effective date
    
-   **Summarize, don't list**: When describing multiple similar items (e.g., multiple purchase orders, payments, defective goods), summarize rather than listing each individual item with detailed specifications
    
    -   **Good**: "Defendant issued 4 Purchase Orders (MU 7338-7341) totaling USD 251,895.00"
        
    -   **Bad**: "Defendant issued Purchase Orders: MU 7338 (MBF 140SS, 1,200 units) - USD 86,436.00; MU 7339 (MBF 140SS, 60 units) - USD 4,336.50; MU 7340 (MURF 110RH, 2,000 units) - USD 151,977.50; MU 7341 (MURF 110RH, 120 units) - USD 9,145.00"
        
    -   Exception: List individually only when specific items are legally significant or disputed
        

**Distinguishing Court Documents from Evidence:**

-   **Reference column**: List court documents (Statement of Claim, Defence and Counterclaim, Writ of Summons, Affirmation of \[Name\], Order, etc.) with paragraph and page numbers
    
-   **Supporting Document column**: List actual evidence documents (Purchase Orders, Invoices, Agreements, Debit Notes, Cheques, etc.) with page numbers. These are the underlying documents submitted as exhibits. Include exhibit codes where available (e.g., "Exhibit HSS-1")
    
-   **Provided By column**: Indicate which party produced/submitted the document:
    
    -   "Plaintiff" - for documents submitted by plaintiff or evidence favorable to plaintiff
        
    -   "Defendant" - for documents submitted by defendant or evidence favorable to defendant
        
    -   "Court" - for court orders, judgments, and court-generated documents
        
-   Example:
    
    -   Reference: "Statement of Claim, para 3, p.4"
        
    -   Supporting Document: "Purchase Order No. MU 7338, p.25 (Exhibit HSS-1)"
        
    -   Provided By: "Plaintiff"
        

**Procedural Annotations:** Add notes in **square brackets** to flag legal requirements or discrepancies:

-   `[Art 51 requires 14 days notice in writing]`
    
-   `[Resolution says JS was present]` (when contradicted elsewhere)
    

### What to Extract

1.  **Incorporations** - formations, registrations
    
2.  **Appointments/Removals** - directors, officers, representatives
    
3.  **Meetings** - board meetings, EGMs, AGMs (date, time, location, attendees)
    
4.  **Resolutions** - what was resolved, by whom, effective when
    
5.  **Communications** - letters, notices, faxes
    
6.  **Filings** - registry forms (ND2A, Annual Returns)
    
7.  **Agreements** - contracts, understandings
    
8.  **Key incidents** - confrontations, discoveries
    
9.  **Financial milestones** - profitability, transactions
    

**Grouping:**

-   Same date, multiple events → one row with bullet points
    
-   Same date, different times → separate rows with time noted
    

### Important Notes

**Document Sourcing:**

-   Always cite BOTH the court document (where the allegation/fact is pleaded) AND the supporting evidence document (the actual exhibit proving the fact)
    
-   Court documents tell you WHAT is alleged; supporting documents provide the PROOF
    
-   If a fact is alleged in pleadings but no supporting document is provided, note "None" in Supporting Document column
    
-   Example of proper citation:
    
    -   Event: "Defendant issues Purchase Order for USD 86,436.00"
        
    -   Reference: "Statement of Claim, para 3, p.4" (where plaintiff alleges this)
        
    -   Supporting Document: "Purchase Order No. MU 7338, p.25 (Exhibit HSS-1)" (the actual PO)
        
    -   Provided By: "Plaintiff" (who submitted this evidence)
        

### Template

Use the `createDocument` JSON schema to produce the chronology DOCX. The full structure:

```json
{
  "content": [
    { "type": "heading", "level": 1, "text": "Chronology" },

    { "type": "paragraph", "bullet": 0, "children": [
      { "type": "text", "text": "[Entity 1]", "bold": true }
    ]},
    { "type": "paragraph", "bullet": 1, "text": "[Person 1] ([%]); [Person 2] ([%])" },
    { "type": "paragraph", "bullet": 1, "text": "Directors: [Abbrevs]" },
    { "type": "paragraph", "bullet": 0, "children": [
      { "type": "text", "text": "[Entity 2]", "bold": true },
      { "type": "text", "text": " – [relationship]" }
    ]},

    { "type": "table",
      "columnWidths": [1400, 3026, 1800, 1800, 1000],
      "rows": [
        { "isHeader": true, "cells": [
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Date", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Event", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Reference", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Supporting Document", "bold": true }] }] },
          { "paragraphs": [{ "children": [{ "type": "text", "text": "Provided By", "bold": true }] }] }
        ]},
        { "cells": [
          { "text": "[YYYY]" },
          { "paragraphs": [{ "children": [
            { "type": "text", "text": "[Full Name] (\"[ABBREV]\") met [Full Name] (\"[ABBREV]\")" }
          ] }] },
          { "paragraphs": [{ "children": [
            { "type": "link", "text": "[Court Document], para [X], p.[Y]", "url": "http://localhost:8017?box=<box_id>" }
          ] }] },
          { "text": "None" },
          { "text": "Plaintiff" }
        ]},
        { "cells": [
          { "text": "DD.MM.YYYY" },
          { "paragraphs": [
            { "children": [{ "type": "text", "text": "• [Event 1]" }] },
            { "children": [{ "type": "text", "text": "• [Event 2]" }] },
            { "children": [{ "type": "text", "text": "[Procedural note if relevant]", "italics": true }] }
          ] },
          { "paragraphs": [
            { "children": [
              { "type": "link", "text": "Statement of Claim, para [X], p.[Y]", "url": "http://localhost:8017?box=<box_id>" }
            ] },
            { "children": [
              { "type": "link", "text": "Affirmation of [Name], para [Z], p.[W]", "url": "http://localhost:8017?box=<box_id>" }
            ] }
          ] },
          { "paragraphs": [
            { "children": [
              { "type": "link", "text": "Purchase Order No. [XXX], p.[A]", "url": "http://localhost:8017?box=<box_id>" }
            ] },
            { "children": [{ "type": "text", "text": "(Exhibit [Code])" }] }
          ] },
          { "text": "Plaintiff" }
        ]},
        { "cells": [
          { "text": "DD.MM.YYYY" },
          { "paragraphs": [{ "children": [
            { "type": "text", "text": "[Agreement] signed", "bold": true },
            { "type": "text", "text": " by [Party]" }
          ] }] },
          { "paragraphs": [{ "children": [
            { "type": "link", "text": "Defence and Counterclaim, para [X], p.[Y]", "url": "http://localhost:8017?box=<box_id>" }
          ] }] },
          { "paragraphs": [
            { "children": [
              { "type": "link", "text": "[Agreement name], pp.[A]-[B]", "url": "http://localhost:8017?box=<box_id>" }
            ] },
            { "children": [{ "type": "text", "text": "(Exhibit [Code])" }] }
          ] },
          { "text": "Defendant" }
        ]}
      ]
    }
  ]
}
```

### Process

1.  Check `tracker.json` to identify all converted documents available
    
2.  Read the converted documents systematically to extract all chronological events
    
3.  Organize events chronologically with complete citations to both court documents and supporting evidence
    
4.  Generate the chronology following the format above
    
5.  **Save the output** as a DOCX file using the `createDocument` command:
    
    -   Filename format: `chronology_[party]_[case_name].docx`
        
    -   Example: `chronology_plaintiff_homer_v_monty.docx`
        
    -   Save in the project root directory
        
6.  Inform the user that the chronology has been saved to the file