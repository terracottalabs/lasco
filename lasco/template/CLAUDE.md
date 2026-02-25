# Lasco - Project Context

## Case Overview

askUserQuestion

-   User name:

-   Representing:


## Platform Notes

-   **Path separators**: All scripts use `path.resolve()` (Node.js) — forward slashes work on both platforms

-   **Document conversion**: Handled automatically by the lasco-file-watcher extension — no manual invocation needed


## Legal Research CLI

The `lasco` CLI is available in your PATH for searching Hong Kong case law, legislation, and practice directions.

### Search commands
```bash
lasco search cases "winding up" --json          # Case law (default 5 results)
lasco search cases "just and equitable" -n 10   # More results
lasco search ordinances "companies" --json       # Legislation
lasco search pd "case management" --json         # Practice directions
```

### Retrieve full documents
```bash
lasco get case <case_id> --json                 # Full judgment text
lasco get ordinance <ordinance_id> --json       # Full ordinance text
lasco get pd <pd_id> --json                     # Full practice direction
```

### Important
- Always use `--json` when you need to parse results programmatically
- For tool results from case law, you should include the links to the cases

### Search Results Panel

The `lasco search` commands automatically save results to `.lasco/search-results/`, which triggers the IDE's rich side panel to display case cards. No manual file writing needed.

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

2.  Create a clickable hyperlink in markdown: `[Document description](http://localhost:8017?box=<box_id>)`

3.  Never reference a document location without providing its box\_id hyperlink


**How to find box\_ids:**

-   Box JSON files are located at: `.lasco/md/<safe_name>/boxes/page_X_boxes.json`

-   Each box has a `box_id` field in format: `{safe_name}__p{page}__b{index}`

-   Each box contains `label`, `coordinate`, `block_content`, and `box_id`

-   **NEVER guess a box\_id.** You MUST read the actual boxes JSON file and find the box whose `block_content` contains the specific text you are citing.

-   **NEVER default to `__b0` or `__b1`.** These are usually page headers, form titles, or notes — NOT the substantive content. Scan ALL boxes in the file to find the right one.

-   When citing a document as a whole (e.g. a form), find the box with the most relevant substantive content (e.g. the company name or main body text), not the form title or header.

-   For tables, find the `table` label box that contains the relevant row data.


**Box ID Format:** `{safe_name}__p{page}__b{index}`

-   Example: `2024-2025_CA_SG2_Hearing_Bundle_-_Item_6_A_copy__p1__b1`


**URL Format:** `http://localhost:8017?box={box_id}` (note: use `?box=` not `/?box=`)

This clickable link system allows users to instantly navigate to the exact location in the PDF viewer with the relevant box highlighted.

## Word Document Creation

When the user asks you to create a Word document (.docx), use the `/docx` skill which handles the full build process.
