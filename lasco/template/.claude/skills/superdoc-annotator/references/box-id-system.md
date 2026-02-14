# Box ID System Reference

Box IDs are unique identifiers for OCR-extracted content blocks from documents processed through the `.lasco/` conversion pipeline. They enable precise, clickable links that navigate the PDF viewer to the exact location of referenced content.

## Box ID Format

```
{safe_name}__p{page}__b{index}
```

- **safe_name**: The document's sanitized name from `tracker.json` (spaces → underscores, special chars removed)
- **page**: 1-based page number
- **index**: 0-based block index within the page

**Examples:**
- `Full_Hearing_Bundle_for_Advocacy_Exercise__p1__b0` — first block on page 1
- `Bundle-Sinfield_certificate-AOA__p5__b2` — third block on page 5
- `20240826_removal_of_director_ND2A_Atte_Note__p3__b0` — first block on page 3

## URL Format

```
http://localhost:8017?box={box_id}
```

Note: Use `?box=` (no slash before the query string).

**Examples:**
- `http://localhost:8017?box=Full_Hearing_Bundle_for_Advocacy_Exercise__p1__b0`
- `http://localhost:8017?box=Bundle-Sinfield_certificate-AOA__p5__b2`

## File Locations

Box JSON files are stored at:
```
.lasco/md/<safe_name>/boxes/page_X_boxes.json
```

Each file contains an array of box objects:
```json
[
  {
    "box_id": "doc_name__p1__b0",
    "label": "text",
    "coordinate": [x1, y1, x2, y2],
    "block_content": "The actual text content of this block..."
  },
  {
    "box_id": "doc_name__p1__b1",
    "label": "text",
    "coordinate": [x1, y1, x2, y2],
    "block_content": "More text content..."
  }
]
```

## Finding Box IDs

### Method 1: Grep for content

Search for text that matches what you're looking for:
```bash
# Search all box files for a keyword
Grep: pattern="block_content.*Certificate of Incorporation" path=".lasco/md/<safe_name>/boxes/"

# Search across all documents
Grep: pattern="block_content.*keyword" path=".lasco/md/" glob="*boxes*.json"
```

Then read the matching file to extract the full `box_id`.

### Method 2: Read page boxes directly

If you know the page number:
```
Read: .lasco/md/<safe_name>/boxes/page_1_boxes.json
```

Scan the array for the block whose `block_content` matches your target.

### Method 3: Use xref.py (if available)

```bash
python3 .lasco/utils/xref.py search "<keyword>" --max 10
python3 .lasco/utils/xref.py search "<keyword>" --doc <safe_name>
python3 .lasco/utils/xref.py link <box_id> --label "Document Name, para X"
```

## Using Box IDs in SuperDoc Commands

### In addLink (existing DOCX)

```bash
node scripts/superdoc-bridge.js addLink --file "doc.docx" \
  --find "Certificate of Incorporation" \
  --url "http://localhost:8017?box=Bundle-Sinfield_certificate-AOA__p1__b0" \
  --no-refresh
```

### In addComment (sidebar annotation)

Include the URL in markdown-style links within the comment text:
```bash
node scripts/superdoc-bridge.js addComment --file "doc.docx" \
  --find "claim text" \
  --author "Reviewer" \
  --text "See [Certificate of Incorporation](http://localhost:8017?box=Bundle-Sinfield_certificate-AOA__p1__b0)" \
  --no-refresh
```

### In createDocument JSON (new DOCX)

Use inline link elements:
```json
{
  "type": "link",
  "text": "Certificate of Incorporation dated 20 September 2013",
  "url": "http://localhost:8017?box=Bundle-Sinfield_certificate-AOA__p1__b0"
}
```

## Tips

- **For multi-page documents**, use the box_id from the title page or first substantive page
- **For sub-documents** (enclosures, attachments), find the specific page where the sub-document begins
- **When box_id search fails**, try broader keywords — OCR may have slight variations from the original text
- **Page numbers are 1-based**, block indices are 0-based
- **Always verify** the box_id points to the right content by reading the box JSON file before using it
