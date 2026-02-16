---
name: MergerControlAnalysis
description: Multi-jurisdictional merger control filing analysis with structured 14-point framework, active scratchpad note-taking, and Excel output. Use when analyzing merger control filing requirements, jurisdictional thresholds, antitrust filings, or conducting multijurisdictional M&A regulatory assessments.
---
# Merger Control Analysis

Structured workflow for analyzing merger control filing requirements across jurisdictions.

## Workflow Overview

Analysis involves three phases:

1. **Initialize** - Create scratchpad for jurisdiction from template BEFORE starting your research
2. **Research** - Go through each point of consideration one by one (or spin up multiple agents to handle one point each), updating scratchpad as you go
3. **Finalize** - Output findings to Excel, auto-classify into appropriate sheet

## Phase 1: Initialize Analysis

When user requests analysis for a jurisdiction:

1. Read project CLAUDE.md to get transaction context (parties, data sources)
2. Copy `assets/ScratchpadTemplate.md` to `./scratchpads/scratchpad-{jurisdiction}.md`
3. Inform user: "Created scratchpad for {jurisdiction}. Beginning research..."

## Phase 2: Research

For each of the 14 points in `references/PointsForConsideration.md`:

1. Research using available tools:
   - Read legislation PDFs for thresholds/rules
   - Use agent-browser for enforcement news
   - Read financial reports for turnover data
2. Update scratchpad with findings and source citations
3. Mark point complete: `[x]`

**Important:** Update scratchpad after EACH point - do not batch updates.

### Source Hyperlinking

When recording sources in each section's `**Sources:**` block, use **markdown link syntax** `[description](url)` — but **only** when the link target is useful for end users.

**Link priority (use the first available):**

1. **Box ID URL** (first priority) — links to exact location in the document viewer with highlighting
   - Find box IDs in `.lasco/md/{safe_name}/boxes/page_X_boxes.json`
   - Example: `[Codelco Revenue Chart](http://localhost:8017?box=img_in_chart_box_436_272_761_377__p1__b0)`
2. **Original file** (fallback) — direct path to the source in its original format (PDF, JPG, etc.)
   - Example: `[Rio Tinto Annual Report chart](../../company_info/rio_annual_report_2024/batch1_imgs/img_in_chart_box_436_272_760_379.jpg)`
3. **Web URL** — for external sources
   - Example: `[ACCC enforcement update](https://www.accc.gov.au/example)`

**Do NOT link to `.md` or `.json` files** — these are internal working files not useful for end users. Instead, cite the source in plain text without a link:
- Example: `Treasury Laws Amendment (Mergers and Acquisitions Reform) Act 2024 (Cth), s.51ABE`
- Example: `Rio Tinto Annual Report 2024, p.167`
- Example: `MergerFilers Australia Guide — Thresholds section`

When completing the **Export Summary** table at finalization, populate the `Source URL` column only with box ID URLs, original file paths, or web URLs. Leave blank if only `.md` sources are available.

### Primary Source Selection

After completing each section's research and Sources block, fill in the **Primary Source:** field:

1. Pick the **most authoritative** source for the key finding in that section
2. Prefer linkable: box ID URL > original file path > web URL
3. If only `.md`/`.json` sources exist, use a plain-text citation (no URL)
4. Format: `[Description](url)` for linkable, or plain text for non-linkable
5. Keep descriptions concise but specific (e.g., "Rio Tinto Annual Report 2024, p.167 - Revenue Note 6")

## Phase 3: Finalize Output

When all 14 points complete (or user requests finalization):

### Step 1: Populate Export Summary
For each column (A-N) in the Export Summary table:
- **Value:** Condensed text for the Excel data cell
- **Source Description:** From the section's **Primary Source:** field. If it used `[text](url)` syntax,
  the `text` part goes here. If no Primary Source field exists (older scratchpads), scan the
  **Sources:** block for the first/best citation.
- **Source URL:** The URL part from the Primary Source. Leave blank if no linkable source exists.

### Step 2: Classify
Apply classification rules from `references/ExcelOutputFormat.md`

### Step 3: Generate Python
Generate `create_excel.py` per `references/ExcelOutputFormat.md`. Critical:
- **Main sheets** have NO hyperlinks on data cells — text only
- **Sources sheet** is the 4th sheet with all source citations and clickable hyperlinks
- Each jurisdiction's `sources` list must be populated from the Export Summary — never empty

### Step 4: Execute and report
Run `create_excel.py`, then report: "Added {jurisdiction} to '{sheet}' sheet with sources"

## Available Resources

### Primary Sources (`assets/primary/`)
Official legislation for 30+ jurisdictions. Most authoritative but usually more verbose.

Naming: `{country}.md` or `{country}-{descriptor}.md`
Examples: `eu.md`, `uk-enterprise-act-2002.md`, `china-antimonopoly-law.md`

### Secondary Sources (`assets/secondary/`)

#### MergerFilers (`mergerfilers/`)
Practical filing guides. Takes a practitioner's view of requirements.

#### Chambers Guides (`chambers/`)
Law firm-written country guides. Practical perspective with professional insights.

#### GWashington Guides (`gwashington/`)
Academic analysis. More theoretical and comprehensive background.

### File Naming Convention

All resources use lowercase with hyphens:
- Single-word countries: `australia.md`, `japan.md`
- Multi-word countries: `new-zealand.md`, `hong-kong.md`, `south-africa.md`
- Common abbreviations: `uk`, `usa`, `eu`

### Handling Conflicts & Assumptions

Sources may contain conflicting information (e.g., outdated thresholds, superseded rules). When conflicts arise:
1. **Prefer more recent information** - legislation amendments override older versions
2. **Ask the user** if uncertain which source is current
3. **Flag in output** - if unresolved, mark the point as requiring further investigation in the final analysis

**Transaction date:** Always clarify the assumed transaction/closing date in the output. Thresholds and rules may change over time - the analysis is only valid for the assumed date. If the user hasn't specified, ask or state the assumption clearly.

## References

- **14-point framework**: See `references/PointsForConsideration.md`
- **Excel column mapping**: See `references/ExcelOutputFormat.md`
- **Scratchpad template**: See `assets/ScratchpadTemplate.md`

## Project Configuration

The project CLAUDE.md must define transaction context:

```markdown
## Transaction Context
- Party 1: [Name]
- Party 2: [Name]
- Transaction Type: [JV / Merger / Acquisition]

## Data Sources
- Party 1 Financials: [path]
- Party 2 Financials: [path]
- Legislation: [paths]
```
