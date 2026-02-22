# Claim Types — Priority Order for Research

When extracting claims from a document, categorize each one and research them in this order. Higher priority claims are researched first because they are more impactful and often easier to definitively prove or disprove.

For domain-specific examples and pitfalls, see `domains/`.

## Priority 0: Legal Procedural Claims

**Pattern:** Meetings/resolutions held "in accordance with" articles, regulations, or statutory requirements; proper notice given; quorum satisfied; filings made within time.

**Examples:**
- "An extraordinary general meeting of all members of the Company was duly convened and held on 26 August 2024"
- "14 days' written notice was given to all directors in accordance with Article 51"
- "The resolution was passed by a majority of the shareholders present and voting"
- "A Form ND2A was filed with the Companies Registry on 17 September 2024"

**How to verify:**
1. Find the relevant Articles of Association or constitutional document — check what notice period, quorum, and voting threshold is actually required
2. Find the notice itself — check the date it was sent, whether it was in writing, and whether the required notice period elapsed before the meeting
3. Check attendance records against quorum requirements
4. Cross-reference filed forms (ND2A, annual returns) against what was actually resolved in meetings

**Common pitfalls:**
- **Notice period miscalculation** — Articles require 14 days but notice was sent only 10 days before meeting; or "days" means clear days (excluding the day of sending and the day of meeting)
- **Wrong resolution type** — Matter requires a special resolution (75%) but was passed as ordinary resolution (simple majority)
- **Quorum not met** — Meeting proceeded with insufficient members present
- **Improper authority** — Meeting called by someone not authorized under the Articles to do so
- **Filed forms contradicting minutes** — ND2A filed showing director removal on a different date than what minutes record
- **Backdated documents** — Minutes or notices created after the fact to justify actions already taken (check for anachronistic references or formatting inconsistencies)
- **Self-serving resolutions** — Majority shareholders passing resolutions to benefit themselves at the expense of minority shareholders

## Priority 1: Source-Attributed Statistics

**Pattern:** "According to [Named Source], [specific number/fact]..."

**Examples:**
- "According to Gartner, the cybersecurity market will reach $314 billion by 2028"
- "The WHO reports that 1 in 4 adults are insufficiently physically active"
- "McKinsey estimates that AI could deliver $13 trillion in global economic activity by 2030"

**How to verify:** Find the actual publication from the named source. Navigate to their website, find the specific report, and check if the exact figure matches. These are the highest priority because a misattributed citation is a material misstatement.

**Common pitfalls found in practice:**
- Attributing a figure to the wrong source (e.g., citing an international body for a figure from a private consulting firm)
- Citing a combined figure as if it applies to one component (e.g., "Product X 50%" when the source says "X + Y combined 48%")
- Using outdated figures from a source that has since revised its projections
- Rounding or inflating the actual figure

## Priority 2: Market Size & Growth Claims

**Pattern:** "$X billion by year Y", "CAGR of Z% from year A to year B"

**Examples:**
- "The global AI market is expected to grow from $196 billion in 2023 to $1.8 trillion by 2030"
- "The SaaS market is projected to grow at a CAGR of 18.7%"

**How to verify:** Search for the exact dollar figures + year on GlobeNewsWire, PRNewswire, and the major market research firms (MarketsandMarkets, Grand View Research, Allied Market Research, Fortune Business Insights, Mordor Intelligence). Market size claims vary enormously depending on market definition — always check what's included (software-only vs. services, revenue vs. units, global vs. regional).

**Common pitfalls:**
- Citing a figure without specifying the source report
- Mixing up revenue-based and unit-volume-based CAGRs
- Using a market definition that doesn't match the cited source's scope
- Cherry-picking the most favorable projection from any source

## Priority 3: Company/Entity Identity Claims

**Pattern:** Founded [year], by [person], headquarters at [address], holds [N] patents

**Examples:**
- "Founded in 2020 by CEO Jane Park and CTO Michael Torres"
- "The company holds 12 patents in natural language processing"

**How to verify:**
- SEC EDGAR (sec.gov) for filings
- State corporate registries for incorporation records
- USPTO (patft.uspto.gov) for patent searches
- LinkedIn for leadership verification
- Google/web search for press coverage
- Address verification via Google Maps

**Red flags:**
- (555) phone numbers (fictional prefix)
- Addresses with round/sequential numbers (e.g., "123 Main Street")
- ZIP codes that don't match the city
- Leadership names with no public digital footprint
- Revenue reported for years before the stated founding date

## Priority 4: Technical/Product Performance Claims

**Pattern:** "[Product] achieves [number] [unit]" or "[specification] of [value]"

**Examples:**
- "Our model achieves 95% accuracy on the benchmark"
- "Response latency of under 50ms at the 99th percentile"
- "Battery life of 48 hours under normal usage"

**How to verify:** Find the authoritative benchmark or standard for the domain. Check if the claimed performance is (a) physically plausible, (b) actually exceptional or just average, and (c) achievable under normal conditions or only ideal ones. For domain-specific benchmarks, see `domains/`.

**Common pitfalls:**
- Calling average performance "industry-leading"
- Omitting qualifying conditions (e.g., benchmark dataset, hardware specs, temperature range, load conditions)
- Comparing against outdated benchmarks

## Priority 5: Financial Performance Claims

**Pattern:** "Revenue of $X in year Y", "Net Income of $X", "Gross Margin of X%"

**Examples:**
- "2023: Revenue – $25 million, Net Income – $2 million"
- "Gross Profit Margin of 45%"

**How to verify:** These REQUIRE audited financial statements from a recognized accounting firm. If the document doesn't reference audited financials, flag immediately. You cannot verify financial claims through web search — you can only check if audited reports exist and if the numbers in the document match them.

**Red flags:**
- No mention of an auditor or accounting firm
- Financial figures that predate the company's stated founding year
- Implausibly smooth revenue growth curves
- No balance sheet or cash flow statement

## Priority 6: Competitive Positioning Claims

**Pattern:** "Industry-leading", "unique selling proposition", "above the global average"

**How to verify:** Search for actual competitors and their offerings. Check if the claimed differentiation is real. For "industry-leading" claims, find who actually leads the industry.

## Priority 7: Regulatory/Legal Claims

**Pattern:** "Compliant with [regulation]", "Certified by [body]", "Approved by [agency]"

**How to verify:** Check the relevant regulatory database (e.g., UL product listings, IEC certification records, FDA approvals, EPA registrations, FCC filings).

## Priority 8: Forward-Looking Projections

**Pattern:** "We aim to achieve $X by year Y"

**How to handle:** Cannot be verified as true/false. Instead, check if the underlying assumptions are stated, reasonable, and consistent with market data. Flag as UNVERIFIABLE but comment on reasonableness.

## Priority 9: Subjective/Aspirational Claims

**Pattern:** Mission statements, vision statements, core values

**How to handle:** Skip. These do not require verification.
