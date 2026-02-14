---
name: document-verifier
description: Verify factual claims in any document — prospectuses, whitepapers, reports, filings, or any text containing verifiable assertions. Use when the user asks to "verify this document", "fact-check this report", "check claims in this whitepaper", "review this report", "source-check this report", "verify this prospectus", "review this prospectus", "check claims in this document", "fact-check this filing", "annotate this prospectus with sources", "underwrite this document", or any request to verify factual claims. Also triggers on mentions of "due diligence", "verify claims", "source check", or "citation check" in the context of a document review.
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, Bash, Task, TodoWrite
allowed-tools: Bash(textutil:*), Bash(agent-browser:*), Bash(pkill:*), Bash(lsof:*), Bash(AGENT_BROWSER_STREAM_PORT=9223 agent-browser open:*), Bash(node scripts/browser-viewer-server.js), Bash(node scripts/superdoc-bridge.js:*), Bash(code --list-extensions:*), Bash(curl:*)
---

# Document Claim Verifier

You are performing a systematic fact-check of a document. Your job is to verify every factual claim against public sources, then annotate the document with verdicts and hyperlinked sources. Every claim gets a verdict. No claim is left unchecked.

## Phase 1: Intake

1. **Find the document.** Use Glob to locate it in the working directory:
   ```
   Glob: **/*.{docx,md,txt,pdf}
   ```
   If the user named a specific file, use that. Otherwise, ask.

2. **Check for SuperDoc.** Detect if the SuperDoc VS Code extension is installed:
   ```bash
   code --list-extensions 2>/dev/null | grep -i superdoc
   ```
   - **If installed** and the document is a `.docx` file → use **command channel mode** (annotate via comments, highlights, and tracked changes through the SuperDoc bridge script).
   - **If not installed** or the document is not `.docx` → use **fallback mode** (convert to `.md`, annotate via Edit tool).

3. **Read the full document.**
   - **Command channel mode:** Get the document content via the SuperDoc bridge:
     ```bash
     node scripts/superdoc-bridge.js getDocument --file "<filename>" --format text
     ```
   - **Fallback mode:**
     - `.docx` — Run `textutil -convert txt -stdout "<path>"` to read content. Then convert to markdown for editing: `textutil -convert html -stdout "<path>"` and save as `.md` in the same directory. Edit the `.md` copy.
     - `.pdf` — Use the Read tool with `pages` parameter. For large PDFs (>10 pages), read in chunks of 20 pages.
     - `.md` or `.txt` — Read directly with the Read tool.

4. **Read end-to-end before researching.** Do not start researching until you have read everything. You need the full context to understand what claims depend on each other and what the document is actually about.

## Phase 2: Claim Extraction

Go through the document section by section. For every verifiable factual claim, log it. Use TodoWrite to track all claims.

**What counts as a verifiable claim:**
- Any number, statistic, or quantitative assertion
- Any attribution to a named source ("According to X...")
- Any statement about the company's or organization's identity, history, leadership, patents, or partnerships
- Any product or technical performance specification (efficiency rates, lifecycles, speeds)
- Any financial figure (revenue, profit, margins, growth rates)
- Any market size, growth rate, or industry projection
- Any competitive comparison ("industry-leading", "above average", "unique")
- Any regulatory or certification claim
- Any scientific or technical claim presented as established fact
- Any legal procedural claim (meetings held in accordance with articles, proper notice given, quorum satisfied)

**What does NOT need verification:**
- Mission statements and aspirational language
- Core values
- Subjective marketing language ("sleek design", "cutting-edge")
- Forward-looking statements clearly labeled as projections (but check if underlying assumptions are reasonable)

**Categorize each claim by type** — see [references/claim-types.md](references/claim-types.md) for the priority order. Legal procedural claims (Priority 0) are checked first for legal documents. Source-attributed statistics go next because they are the most straightforward to verify or disprove.

**Identify the document's domain.** Scan the document for industry keywords and load the matching domain file from `references/domains/`:
- Solar, wind, battery, EV, energy → `domains/energy-financial.md`
- Software, SaaS, cloud, API, platform → `domains/tech-saas.md`
- Drug, clinical trial, FDA, therapeutic → `domains/biotech-pharma.md`
- Payments, lending, banking, fintech → `domains/fintech.md`
- Litigation, petition, affidavit, witness statement, minutes, director removal → `domains/legal-litigation.md`
- No clear match → use generic strategies only (`references/verification-strategies.md`)

If a matching domain file exists, load it for specialized source directories, benchmarks, and known pitfalls.

## Phase 3: Research & Annotate (Section by Section)

This is the core of the work. Process the document **one section at a time** — research claims in parallel, then annotate each claim the moment its result is ready.

### 3a. Section-by-Section Flow

Work through the document's sections in order (top to bottom). For each section:

1. **Launch parallel subagents** (up to 5-6 Task subagents, general-purpose type) for the section's claims
2. **Annotate immediately** as each subagent returns — do not wait for the whole batch. **Always pass `--no-refresh`** on every bridge mutation command (see 3e).
3. **Browser-verify before annotating** when a claim needs it (see 3d below)
4. After all annotations for this section's subagent batch are done, **call `refresh --file` once** (see 3e)
5. **Move to the next section**

### 3b. Subagent Dispatch

Each subagent gets **one claim or a small cluster of related claims**. Every subagent prompt MUST include:
1. The exact text of the claim from the document (quoted)
2. What specific data point needs to be verified
3. Instructions to use WebSearch to find the authoritative source
4. Instructions to return structured results: **verdict** (VERIFIED/INACCURATE/MISLEADING/UNVERIFIABLE/PLAUSIBLE), **source_url**, **source_name**, **explanation**, and the **correct data** (if different from the claim)
5. Instructions to check multiple sources if the first result is ambiguous

**Example subagent prompt:**
```
Verify this claim from a document:

"According to Gartner, the global cybersecurity market is projected to reach $314 billion by 2028."

I need you to:
1. Search for what Gartner actually projects for the cybersecurity market by 2028
2. Find the specific Gartner report or publication that contains this data
3. Determine if $314 billion is the correct figure and if Gartner is the correct source
4. If wrong, find the actual source and correct figure
5. Return your result in this exact format:
   - verdict: VERIFIED | INACCURATE | MISLEADING | UNVERIFIABLE | PLAUSIBLE
   - source_name: The name of the authoritative source
   - source_url: The exact URL
   - explanation: What the source actually says (1-2 sentences)

Use WebSearch with queries like "Gartner cybersecurity market 2028 billion" and "Gartner cybersecurity forecast". Try multiple search variations.
```

### 3c. Annotate on Return

As each subagent returns its result, **immediately annotate the document**. The annotation method depends on the mode:

#### Command Channel Mode (SuperDoc Editor)

Use the SuperDoc bridge script to add comments, highlights, and tracked changes directly in the DOCX file. The SuperDoc VS Code extension auto-refreshes when the file changes.

**Add a comment on the claim text:**
```bash
node scripts/superdoc-bridge.js addComment \
  --file "<filename>" \
  --find "<exact claim text>" \
  --author "Document Verifier" \
  --text "<VERDICT>: [Source Name](URL) — explanation."
```

**Add a source hyperlink inline after the claim text:**
```bash
node scripts/superdoc-bridge.js addLink \
  --file "<filename>" \
  --find "<claim text or key phrase>" \
  --url "<source_url>"
```

This inserts the URL as visible clickable text in parentheses right after the claim, e.g.:
> ...reach $314 billion by 2028 (https://www.gartner.com/...) ...

**For INACCURATE claims, also apply a red highlight:**
```bash
node scripts/superdoc-bridge.js addHighlight \
  --file "<filename>" \
  --find "<exact claim text>" \
  --color "#FFE0E0"
```

**For MISLEADING claims, also apply a yellow highlight:**
```bash
node scripts/superdoc-bridge.js addHighlight \
  --file "<filename>" \
  --find "<exact claim text>" \
  --color "#FFF3CD"
```

**For claims requiring correction, suggest a tracked change (redline):**
```bash
node scripts/superdoc-bridge.js suggestEdit \
  --file "<filename>" \
  --find "<incorrect text>" \
  --replace "<corrected text>" \
  --author "Document Verifier"
```

**Highlight color reference:**

| Verdict | Highlight | Color |
|---|---|---|
| INACCURATE | Yes | `#FFE0E0` (light red) |
| MISLEADING | Yes | `#FFF3CD` (light yellow) |
| UNVERIFIABLE | Optional | `#E2E3E5` (light gray) |
| VERIFIED | No | — |
| PLAUSIBLE | No | — |

**Comment text format** — the comment `--text` should follow this pattern:
- **Verified**: `VERIFIED: [Source Name](URL) confirms X.`
- **Inaccurate**: `INACCURATE: [Source Name](URL) actually states Y. The document misattributes/overstates/conflates Z.`
- **Misleading**: `MISLEADING: While [partial truth], [Source Name](URL) shows [fuller picture].`
- **Unverifiable**: `UNVERIFIABLE: No public source found. Searched: [what]. Required: [documentation needed].`
- **Plausible**: `PLAUSIBLE: [Source Name](URL) supports this under [conditions]. Note: [qualification].`

#### Fallback Mode (No SuperDoc)

Use the Edit tool with the claim's exact text as `old_string`, and the claim text + inline annotation as `new_string`:
```
Edit:
  old_string: "the global cybersecurity market is projected to reach $314 billion by 2028."
  new_string: "the global cybersecurity market is projected to reach $314 billion by 2028. [*(Inaccurate: [Gartner](https://www.gartner.com/...) projects $212 billion by 2028, not $314 billion. The $314 billion figure appears to originate from [MarketsandMarkets](https://www.marketsandmarkets.com/...), not Gartner.)*]"
```

See [references/annotation-format.md](references/annotation-format.md) for full inline annotation templates.

**Annotation rules (both modes):**
- Every annotation must include **at least one hyperlink** to a source, or explicitly state why no source exists
- Keep annotations concise but precise — state what the source says, not just that it exists
- For claims with multiple issues, address them all in one annotation
- **Use `addLink` for source URLs** that should be visible inline in the document text. Use `addComment` for verdict explanations and analysis that belongs in the sidebar. **For EVERY annotated claim (all verdict types), add BOTH**: a comment with the verdict + explanation, AND an inline hyperlink via `addLink` pointing to the primary source URL. This ensures readers can click through to evidence directly from the document body, regardless of whether the claim was verified or flagged.

### 3d. Browser Verification (Inline)

For certain claims, use agent-browser **before annotating** to confirm the source. Do not annotate until you've verified.

**When to use the browser:**
- The claim will be flagged as INACCURATE (confirm you're right before accusing the document)
- The claim attributes data to a specific named source and the exact figure matters
- WebFetch returned a 403/error on the source page
- The subagent found a URL but you want to confirm the page actually says what's claimed
- The source is a JS-rendered page that WebFetch can't parse

**Browser workflow:**
```bash
# Clean up any previous session
agent-browser close 2>/dev/null || true
pkill -f "agent-browser" 2>/dev/null || true
sleep 1

# Navigate to the source
AGENT_BROWSER_STREAM_PORT=9223 agent-browser open <url>

# Get page content
agent-browser snapshot -i
agent-browser get text body
```

You don't need to browser-verify every claim. Focus on:
1. Claims that will be flagged as INACCURATE (confirm you're right before accusing the document)
2. Source-attributed statistics where the exact figure matters
3. Any URL a subagent returned that you haven't personally confirmed

### 3e. Batch Refresh (Reducing SuperDoc Flashing)

Every bridge mutation command (`addComment`, `addHighlight`, `addLink`, `suggestEdit`, `insertText`) supports `--no-refresh` to suppress the 200ms auto-refresh. **Always pass `--no-refresh` on every mutation command**, then call `refresh` once after the batch:

```bash
# All mutation commands for one claim — no refresh
node scripts/superdoc-bridge.js addComment  --file "doc.docx" --find "..." --text "..." --no-refresh
node scripts/superdoc-bridge.js addHighlight --file "doc.docx" --find "..." --color "#FFE0E0" --no-refresh
node scripts/superdoc-bridge.js addLink     --file "doc.docx" --find "..." --url "..." --no-refresh

# After all annotations for this subagent batch are done — single refresh
node scripts/superdoc-bridge.js refresh --file "doc.docx"
```

This avoids flashing the SuperDoc editor once per command (3 commands × 50 claims = 150 refreshes → 1 refresh per batch).

## Phase 4: Verification Summary

After all annotations are inserted, add a summary at the end of the document.

#### Command Channel Mode

Insert the summary table at the end of the document via the SuperDoc bridge:
```bash
node scripts/superdoc-bridge.js insertText \
  --file "<filename>" \
  --at end \
  --text "

---

VERIFICATION SUMMARY

Claims by Verdict

| Verdict | Count | Description |
|---|---|---|
| VERIFIED | X | Confirmed by reliable sources with hyperlinks |
| INACCURATE | X | Factually wrong, misattributed, or fabricated |
| MISLEADING | X | Partial truths presented in misleading ways |
| UNVERIFIABLE | X | Cannot be confirmed through public sources |
| PLAUSIBLE | X | Reasonable but requires qualification |

Critical Issues

1. [Issue 1]
2. [Issue 2]

Recommendation

[One-paragraph overall reliability assessment.]"
```

#### Fallback Mode

Append the same summary using the Edit tool at the end of the `.md` file:

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

[Numbered list of showstopper problems — adapt heading to document context (e.g., "Critical Issues for Underwriting" for financial documents, "Critical Factual Errors" for whitepapers).]

## Recommendation

[One-paragraph overall reliability assessment: what can be trusted, what must be corrected, and whether the document is suitable for its intended purpose.]
```

## Important Notes

### Universal Rules

- **Never guess a URL.** Every hyperlink must come from an actual search result or browser visit.
- **Prioritize authoritative sources.** Primary sources > government databases > international organizations > established research firms > peer-reviewed publications > trade press > press releases > news coverage > blogs.
- **Check for internal contradictions.** Look for claims in the document that contradict each other (e.g., founding date vs. financial history, stated capabilities vs. specifications).
- **Paywalled sources:** If a report is paywalled, use the free executive summary PDF, press release on GlobeNewsWire/PRNewswire, or coverage in relevant trade publications. See [references/verification-strategies.md](references/verification-strategies.md).
- **Company/entity identity is critical.** Always verify the issuer actually exists as described — check relevant registries, patent offices, regulatory filings, professional networks.
- **Financial claims without audits are red flags.** If the document presents financial figures without referencing audited financial statements from a recognized accounting firm, flag this prominently.

### Domain-Specific Guidance

Check `references/domains/` for domain-specific source directories, benchmarks, and known pitfalls. Domain files contain specialized knowledge that helps catch misattributions and misleading figures specific to that field. If no matching domain file exists, rely on the generic strategies in [references/verification-strategies.md](references/verification-strategies.md).

### Mode Selection

The skill automatically selects between command channel mode and fallback mode at startup:
- **Command channel mode** provides a richer experience — comments appear in the SuperDoc editor sidebar, problem claims get colored highlights, tracked changes show suggested corrections as redlines, and the user can accept/reject annotations normally.
- **Fallback mode** inserts inline text annotations into a `.md` copy — this works everywhere, including outside VS Code.
- If the SuperDoc bridge fails mid-verification (e.g., file locked, write error), switch to fallback mode for the remaining claims rather than failing.

### Text Search Gotcha (All Bridge Commands)

The `--find` argument for all bridge commands (`addComment`, `addLink`, `addHighlight`, `suggestEdit`) matches against raw XML. Word splits text across XML runs at formatting boundaries. **Use short, unique substrings**:
- BAD: `"Company: Anthropic PBC"` — colon likely causes a run split
- GOOD: `"Anthropic PBC"`
