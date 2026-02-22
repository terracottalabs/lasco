# Verification Strategies — Generic Research Methodology

This reference describes the general-purpose research strategies used to verify factual claims in any document. For domain-specific source directories and benchmarks, see `domains/`.

## Source Hierarchy

When multiple sources exist, prioritize them in this order:

1. **Primary sources** — the original data, report, or publication being cited
2. **Government databases** — SEC EDGAR, USPTO, state corporate registries, census data
3. **International organizations** — UN agencies, World Bank, WHO, OECD
4. **Established research firms** — Gartner, McKinsey, Deloitte, PwC, BCG
5. **Peer-reviewed publications** — academic journals, conference proceedings
6. **Trade publications** — industry-specific outlets with editorial standards
7. **Press releases** — GlobeNewsWire, PRNewswire, BusinessWire (often the primary record for market research data)
8. **News coverage** — major outlets reporting on the data
9. **Blogs and opinion pieces** — lowest priority, use only to corroborate

Always go to the **named source first**. If a claim says "According to WHO," go to WHO's website before checking secondary coverage.

## Verifying Market Research Data

Market size and CAGR claims almost always originate from one of a handful of market research firms. Their full reports are paywalled, but key figures are published in press releases.

**How to trace a market claim:**
1. Search the exact dollar figure + year + market name on GlobeNewsWire (`globenewswire.com`) and PRNewswire (`prnewswire.com`)
2. If found, check which firm published it and whether the document attributes the correct source
3. If not found, the figure may be fabricated, outdated, or from an obscure source

**Major market research firms:**

| Firm | Press releases typically on | URL |
|---|---|---|
| MarketsandMarkets | PRNewswire | `marketsandmarkets.com/Market-Reports/` |
| Grand View Research | GlobeNewsWire, PRNewswire | `grandviewresearch.com/industry-analysis/` |
| Allied Market Research | PRNewswire | `alliedmarketresearch.com` |
| Fortune Business Insights | GlobeNewsWire | `fortunebusinessinsights.com` |
| Mordor Intelligence | Direct | `mordorintelligence.com` |
| Market Research Future | GlobeNewsWire | `marketresearchfuture.com` |
| Next Move Strategy Consulting | GlobeNewsWire | `nextmsc.com` |
| Precedence Research | GlobeNewsWire | `precedenceresearch.com` |

## Verifying Source-Attributed Claims

When a claim says "According to [Source]...":

1. **Go directly to the named source's website** — search for the specific report or data point
2. **Verify the exact figure**, not just that the source covers the topic
3. **Check the date** — the source may have updated its projections since the cited version
4. **Check the scope** — the source may define the market, metric, or population differently than the claim implies

Common misattribution patterns:
- Citing an international body for data that actually comes from a private consulting firm
- Citing a combined figure as if it applies to a single component
- Citing a forecast range's high end as if it were the central estimate

## Paywalled Source Workarounds

When the authoritative source is behind a paywall:

1. **Executive summary PDFs** — many firms release free summaries with headline figures
2. **Press releases** — GlobeNewsWire/PRNewswire often contain the key data points
3. **Trade publication coverage** — industry outlets frequently report on major releases
4. **Cached/archived versions** — check if the page was previously accessible
5. **Author/firm blog posts** — researchers sometimes discuss findings on their blog

If you cannot access the source at all, mark the claim as UNVERIFIABLE and note the paywall.

## Browser Verification

When WebFetch fails (403, paywall, JS-rendered pages), use agent-browser:

```bash
# Clean up any previous session
agent-browser close 2>/dev/null || true
pkill -f "agent-browser" 2>/dev/null || true
sleep 1

# Navigate to the source
AGENT_BROWSER_STREAM_PORT=9223 agent-browser open "<url>"

# Get page content
agent-browser snapshot -i
agent-browser get text body
```

**Common sites that block WebFetch but work with agent-browser:**
- Government publication pages
- International organization report pages
- Market research firm report pages
- Academic publisher pages
- JS-rendered data dashboards

## Entity Identity Verification

Verifying that a company, organization, or person exists as described:

| What to check | Where to check |
|---|---|
| Corporate existence | State secretary of state / corporate registry |
| SEC filings | SEC EDGAR (`sec.gov/cgi-bin/browse-edgar`) |
| Patents | USPTO (`patft.uspto.gov`) — search by assignee name |
| Trademarks | USPTO TESS (`tmsearch.uspto.gov`) |
| Leadership | LinkedIn, company press releases, news coverage |
| Physical address | Google Maps, USPS address verification |
| Domain ownership | WHOIS lookup (`whois <domain>`) |

## Domain Detection

Identify the document's industry from its content and load the matching domain file:
- Solar, wind, battery, EV, energy → `domains/energy-financial.md`
- Software, SaaS, cloud, API, platform → `domains/tech-saas.md`
- Drug, clinical trial, FDA, therapeutic → `domains/biotech-pharma.md`
- Payments, lending, banking, fintech → `domains/fintech.md`
- No clear match → use generic strategies only (this file)

Domain files add specialized sources, benchmarks, and pitfalls on top of the generic strategies. To add a new domain, copy `domains/_template.md` and fill in the sections.

## Domain-Independent Red Flags

These warning signs apply regardless of document type:

- **(555) phone numbers** — fictional prefix used in entertainment
- **Sequential or round addresses** — "123 Main Street", "1000 Innovation Drive"
- **ZIP codes that don't match the city** — check with USPS
- **Leadership with zero digital footprint** — no LinkedIn, no news, no publications
- **Revenue predating the stated founding year** — internal contradiction
- **Implausibly smooth growth curves** — real businesses have variance
- **No auditor or accounting firm named** — financial claims without audit trail
- **Generic stock photos** — reverse image search reveals stock photo libraries
- **Domain registered very recently** — WHOIS shows recent registration for supposedly established entity
- **Circular citations** — claim cites a source that itself cites the claimant

## Legal Document Verification

When verifying legal documents (pleadings, affidavits, witness statements, meeting minutes, corporate filings), apply these specialized strategies in addition to the generic methods above.

### Source Hierarchy for Legal Claims

1. **Official registry filings** — Companies Registry records, Land Registry, court filings (most authoritative — contemporaneous public records)
2. **Constitutional documents** — Certificate of Incorporation, Memorandum & Articles of Association (define what is legally permissible)
3. **Board/meeting minutes** — contemporaneous records of decisions (but verify they comply with constitutional requirements)
4. **Correspondence** — letters, faxes, emails between parties (check dates, recipients, and whether actually sent)
5. **Witness statements/affidavits** — sworn accounts of events (subjective — compare across witnesses)
6. **Attendance notes** — solicitor notes of client meetings (useful for establishing instructions and timeline)
7. **Third-party records** — bank statements, invoices, delivery records (independent corroboration)

### Internal Consistency Checks

Legal documents frequently contain internal contradictions. Cross-check these systematically:

| Check | What to compare | Red flag |
|-------|----------------|----------|
| **Dates** | Meeting dates in minutes vs. notices vs. filed forms | Date on minutes doesn't match notice period |
| **Attendance** | Who was present per minutes vs. who claims to have been absent | Witness says they weren't at meeting that minutes record them attending |
| **Financials** | Revenue/profit figures across different documents | Annual return figures don't match management accounts |
| **Signatures** | Signing parties across related documents | Person signs as director after removal date |
| **Shareholding** | Percentage splits across filings and agreements | Share percentages don't add to 100% or change without documented transfer |

### Procedural Compliance Checks

For corporate disputes, verify that procedural requirements were actually met:

- **Notice periods** — Check Articles of Association for required notice period for board meetings and EGMs, then verify actual notice given
- **Quorum** — Check Articles for quorum requirements, then verify attendance at the relevant meeting
- **Voting thresholds** — Ordinary resolution (simple majority) vs. special resolution (75%) vs. unanimous consent
- **Proper authority** — Was the person who called the meeting authorized to do so?
- **Correct forms** — Were the right statutory forms filed (e.g., ND2A for director changes)?
- **Filing deadlines** — Were forms filed within the statutory time limits?

### Verification Approach for Common Legal Document Types

| Document type | Key verification points |
|---------------|----------------------|
| **Meeting minutes** | Was proper notice given? Was quorum met? Were resolutions within the meeting's authority? |
| **Witness statements** | Do factual claims match documentary evidence? Are there inconsistencies between witnesses? |
| **Affirmations/affidavits** | Are exhibited documents authentic? Do paragraph references match? |
| **Corporate filings** | Do filed details match what was actually resolved? Were filing deadlines met? |
| **Correspondence** | Was it actually sent/received? Does the date make sense in the timeline? |
