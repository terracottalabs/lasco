# Annotation Format — How to Mark Up Claims In-Place

When editing the document, insert an annotation **immediately after** each verified claim. Every annotation follows a consistent structure so reviewers can scan the document quickly.

## Verdict Types

| Verdict | When to use |
|---|---|
| **VERIFIED** | The claim is confirmed by a reliable source. The source URL is provided. |
| **INACCURATE** | The claim is factually wrong — wrong number, wrong source, wrong attribution. |
| **MISLEADING** | The claim is technically partially true but presented in a way that creates a false impression. |
| **UNVERIFIABLE** | No public source could be found to confirm or deny the claim. |
| **PLAUSIBLE** | The claim is reasonable and directionally supported but needs qualification. |

## Inline Annotation Templates

### VERIFIED
Insert immediately after the claim sentence/paragraph:

```
[*(Verified: [Source Name](https://exact-url-to-source) confirms [what specifically it confirms].)*]
```

**Example:**
> Global smartphone shipments totaled 1.17 billion units in 2023. [*(Verified: [IDC Worldwide Quarterly Mobile Phone Tracker](https://www.idc.com/getdoc.jsp?containerId=prUS51763424) confirms 1.17 billion smartphone shipments in 2023, a 3.2% decline year-over-year.)*]

### INACCURATE
```
[*(Inaccurate: [Source Name](https://exact-url-to-source) actually states [correct figure/fact]. The document [misattributes/overstates/conflates/fabricates] [specific error].)*]
```

**Example:**
> According to Gartner, global cybersecurity spending will reach $314 billion by 2028. [*(Inaccurate: [Gartner](https://www.gartner.com/en/newsroom/press-releases/...) projects $212 billion in information security spending by 2025, not $314 billion by 2028. The $314 billion figure appears to originate from [MarketsandMarkets](https://www.marketsandmarkets.com/...), not Gartner. The document misattributes the source.)*]

### MISLEADING
```
[*(Misleading: While [the partial truth], [Source Name](https://exact-url-to-source) shows [the fuller picture]. Recommended correction: [what should be changed].)*]
```

**Example:**
> Our platform processes 10 million requests per day — far exceeding typical industry capacity. [*(Misleading: While 10M requests/day is substantial for a startup, [Cloudflare Radar](https://radar.cloudflare.com/) shows major CDNs handle billions of requests per second. The comparison baseline is undefined. Recommended correction: specify the peer group being compared against.)*]

### UNVERIFIABLE
```
[*(Unverifiable: No public source found to confirm this claim. Searched: [what you searched for]. Required: [what documentation would be needed].)*]
```

**Example:**
> The company holds 8 patents in distributed machine learning systems. [*(Unverifiable: No patents found assigned to "Acme AI Inc." via USPTO full-text patent search. Searched: USPTO assignee search for "Acme AI" in machine learning classifications. Required: specific patent numbers and filing details.)*]

### PLAUSIBLE
```
[*(Plausible: [Source Name](https://exact-url-to-source) supports this under [conditions/caveats]. Note: [what qualification is needed].)*]
```

**Example:**
> Our LFP battery systems achieve a lifespan of over 15 years. [*(Plausible: [Clean Energy Reviews](https://www.cleanenergyreviews.info/blog/lithium-battery-life-explained) confirms LFP batteries achieve 15-20 year lifespans with 6,000-10,000 cycles. Note: only true for LFP chemistry under optimal conditions; NMC lithium-ion lasts 8-12 years. Document should specify battery chemistry and operating conditions.)*]

## Rules

1. **Every hyperlink must be to a real URL** that you found via WebSearch or visited via agent-browser. Never fabricate URLs.
2. **Be specific about what the source says.** Don't just link — quote or paraphrase the relevant data point from the source.
3. **Use multiple sources when available.** For important claims, provide 2-3 supporting links.
4. **Work top-to-bottom** when inserting annotations to avoid line number conflicts with the Edit tool.
5. **Keep annotations concise.** 1-3 sentences. The reviewer needs to scan quickly.
6. **For claims with multiple issues**, combine them into one annotation rather than inserting multiple.

## Verification Summary Table

Append this at the end of the document after all annotations are inserted:

```markdown
---

# VERIFICATION SUMMARY

## Claims by Verdict

| Verdict | Count | Description |
|---|---|---|
| VERIFIED | X | Confirmed by reliable sources with hyperlinks |
| INACCURATE | X | Factually wrong, misattributed, or fabricated |
| MISLEADING | X | Partial truths presented in misleading ways |
| UNVERIFIABLE | X | Cannot be confirmed through public sources |
| PLAUSIBLE | X | Reasonable but requires qualification |

## Critical Issues

[Numbered list of the most serious problems, e.g.:]
1. Company identity cannot be verified — no SEC filings, no corporate registry match
2. Source-attributed citation is fabricated — named source never published this figure
3. No audited financial statements provided or referenced
[etc.]

## Recommendation

[One paragraph: Can this document be relied upon? What must be corrected first?]
```

## Comment Thread Format (SuperDoc Editor)

When the document is open in the SuperDoc editor (VS Code extension), annotations are inserted as
comments and highlights via the SuperDoc bridge script (`scripts/superdoc-bridge.js`) instead of inline text edits.

Each verdict becomes a comment on the exact claim text:
- **author**: `"Document Verifier"`
- **text**: `"<VERDICT>: [Source Name](URL) — explanation."`

Example command:
```bash
scripts/lasco-node scripts/superdoc-bridge.js addComment \
  --file "Prospectus.docx" \
  --find "the renewable energy market will reach $1.5 trillion by 2030" \
  --author "Document Verifier" \
  --text "INACCURATE: [IRENA](https://irena.org/Publications) does not publish market-size projections in dollar terms. This figure originates from MarketsandMarkets, not IRENA."
```

Highlight colors for problem claims:

| Verdict | Highlight | Color |
|---|---|---|
| INACCURATE | Yes | `#FFE0E0` (light red) |
| MISLEADING | Yes | `#FFF3CD` (light yellow) |
| UNVERIFIABLE | Optional | `#E2E3E5` (light gray) |
| VERIFIED | No | — |
| PLAUSIBLE | No | — |

Apply highlights via:
```bash
scripts/lasco-node scripts/superdoc-bridge.js addHighlight \
  --file "Prospectus.docx" \
  --find "the renewable energy market will reach $1.5 trillion by 2030" \
  --color "#FFE0E0"
```

The inline text annotation format (sections above) is used as the **fallback** when SuperDoc is not available.

## Hyperlink Citation Format (SuperDoc Editor)

When the document is open in SuperDoc, source URLs should be inserted as **visible inline hyperlinks** using `addLink`, in addition to the sidebar comment with the verdict.

**Command:**
```bash
scripts/lasco-node scripts/superdoc-bridge.js addLink \
  --file "Prospectus.docx" \
  --find "the renewable energy market will reach $1.5 trillion by 2030" \
  --url "https://irena.org/Publications"
```

**What it produces in the document:**
> ...the renewable energy market will reach $1.5 trillion by 2030 (https://irena.org/Publications) ...

**When to add inline hyperlinks:**
- VERIFIED claims — link to the confirming source
- INACCURATE claims — link to the source showing the correct information
- MISLEADING claims — link to the source providing the fuller picture
- PLAUSIBLE claims — link to the supporting source

**Typical annotation workflow for a claim:**
1. `addComment` — verdict + explanation in the sidebar
2. `addLink` — source URL visible inline after the claim text
3. `addHighlight` — color highlight if INACCURATE or MISLEADING

**Example — full annotation of an inaccurate claim:**
```bash
# 1. Comment with verdict
scripts/lasco-node scripts/superdoc-bridge.js addComment \
  --file "Prospectus.docx" \
  --find "revenue of $50 million in 2023" \
  --author "Document Verifier" \
  --text "INACCURATE: SEC 10-K filing shows $35M revenue for FY2023."

# 2. Inline source hyperlink
scripts/lasco-node scripts/superdoc-bridge.js addLink \
  --file "Prospectus.docx" \
  --find "revenue of $50 million in 2023" \
  --url "https://sec.gov/cgi-bin/browse-edgar?action=getcompany..."

# 3. Red highlight for inaccurate claim
scripts/lasco-node scripts/superdoc-bridge.js addHighlight \
  --file "Prospectus.docx" \
  --find "revenue of $50 million in 2023" \
  --color "#FFE0E0"
```

## Tracked Change Format (SuperDoc Editor)

For claims where the document text itself needs correction, use tracked changes (redlines) to suggest specific edits. These appear as Word revision marks that the user can accept or reject.

**When to use tracked changes:**
- INACCURATE claims where the correct text is known (e.g., wrong figure, wrong source attribution)
- MISLEADING claims where rephrasing would fix the issue
- Legal documents where specific wording needs correction for accuracy

**Command:**
```bash
scripts/lasco-node scripts/superdoc-bridge.js suggestEdit \
  --file "Prospectus.docx" \
  --find "revenue of $50 million in 2023" \
  --replace "revenue of $35 million in 2023" \
  --author "Document Verifier"
```

**Guidelines for tracked changes:**
- Always add a comment explaining WHY the edit is suggested before or alongside the tracked change
- Only suggest edits for factual corrections — do not rephrase marketing language or style
- Keep corrections minimal — change only what is factually wrong
- For legal documents, ensure suggested corrections use proper legal terminology

