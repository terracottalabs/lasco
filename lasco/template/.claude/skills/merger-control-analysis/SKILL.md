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

## Phase 3: Finalize Output

When all 14 points complete (or user requests finalization):

1. Read completed scratchpad
2. Apply classification rules from `references/ExcelOutputFormat.md`:
   - **Thresholds met** → Both parties exceed jurisdictional thresholds
   - **Thresholds not met** → Either party below thresholds
   - **To be discussed** → Edge cases, voluntary filing, unclear data
3. Use xlsx skill to insert row into appropriate sheet
4. Report: "Added {jurisdiction} to '{sheet}' sheet"

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
