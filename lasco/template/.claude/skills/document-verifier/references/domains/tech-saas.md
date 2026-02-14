# Domain: Technology & SaaS

This domain file contains specialized verification knowledge for technology, software, and SaaS company documents. Load this file when the document under review covers software platforms, cloud services, SaaS metrics, APIs, developer tools, or technology IPOs.

---

## Source Directory

### Gartner
- **What they publish:** Magic Quadrants, market forecasts, IT spending outlooks, Hype Cycles
- **Where to verify:** `gartner.com/en/newsroom/press-releases`, `gartner.com/en/research/methodologies/magic-quadrants-research`
- **Access:** Most reports paywalled; headline figures in press releases
- **Gotcha:** Gartner forecasts IT spending in aggregate categories — prospectuses often cite a Gartner figure for a narrow sub-segment that Gartner doesn't separately track

### IDC
- **What they publish:** Worldwide Quarterly Cloud IT Infrastructure Tracker, software market sizing, digital transformation spending forecasts
- **Where to verify:** `idc.com/promo/pressrelease`
- **Access:** Press releases free; full reports paywalled

### Forrester
- **What they publish:** Total Economic Impact (TEI) studies, Wave reports, technology adoption forecasts
- **Where to verify:** `forrester.com/press-newsroom`
- **Gotcha:** TEI studies are commissioned by the vendor — they are vendor-funded, not independent research. Flag any TEI-based claim as vendor-funded.

### Synergy Research Group
- **What they publish:** Cloud infrastructure market share (AWS, Azure, GCP), enterprise SaaS market data
- **Where to verify:** `srgresearch.com/articles`
- **Key data:** Quarterly cloud market share rankings — the authoritative source for cloud infrastructure market share

### Canalys
- **What they publish:** Cloud infrastructure spend, PC/device shipments, cybersecurity market data
- **Where to verify:** `canalys.com/newsroom`

### data.ai (formerly App Annie)
- **What they publish:** Mobile app downloads, revenue, usage rankings
- **Where to verify:** `data.ai/en/insights/`
- **Use for:** Verifying mobile app download counts, app store revenue claims, engagement metrics

### Sensor Tower
- **What they publish:** App store analytics, mobile market data
- **Where to verify:** `sensortower.com/blog`

### SimilarWeb
- **What they publish:** Website traffic estimates, digital market intelligence
- **Where to verify:** `similarweb.com` (free tier available for basic traffic data)
- **Gotcha:** SimilarWeb estimates can vary significantly from actual analytics — treat as directional, not exact

---

## Industry Benchmarks

### Net Revenue Retention (NRR / NDR)
- **Good:** >110%
- **Best-in-class:** >120%
- **Elite:** >130% (Snowflake, Twilio at peak were >130%)
- **Median public SaaS:** ~110-115%
- **Source:** Bessemer Cloud Index, public company filings

### Gross Margins
- **SaaS norm:** >70% gross margin
- **Best-in-class:** >80%
- **Below 60%:** Likely not a pure SaaS business — may include services, hardware, or heavy infrastructure costs
- **Source:** Public company 10-K filings

### Rule of 40
- **Formula:** Revenue growth rate (%) + operating margin (%)
- **Good:** >40%
- **Elite:** >60%
- **Red flag:** Claiming "Rule of 40 compliance" while burning cash and growing slowly
- **Source:** Bessemer Cloud Index

### CAC Payback Period
- **Good:** <18 months
- **Best-in-class:** <12 months
- **Red flag:** >24 months without explicit plan to improve
- **Source:** Company filings, Bessemer benchmarks

### Magic Number (Sales Efficiency)
- **Formula:** Net new ARR / sales & marketing spend in prior quarter
- **Good:** >0.75
- **Best-in-class:** >1.0
- **Below 0.5:** Inefficient go-to-market
- **Source:** Public company filings

---

## Domain-Specific Pitfalls

### ARR vs. Recognized Revenue
Annual Recurring Revenue (ARR) is a forward-looking metric (current MRR × 12), not GAAP revenue. Prospectuses sometimes present ARR as if it were recognized revenue, inflating the apparent size of the business. Always check which metric is being used and whether it's annualized or actually recognized.

### "Enterprise-Grade" Without Certifications
Claims of "enterprise-grade security" or "enterprise-ready" are meaningless without specific certifications. Look for:
- **SOC 2 Type II** — the baseline for enterprise SaaS
- **ISO 27001** — international information security standard
- **HIPAA compliance** — if handling health data
- **FedRAMP** — if claiming government readiness
If none are mentioned, flag the "enterprise-grade" claim as UNVERIFIABLE.

### DAU/MAU Inflation
"Active users" can be defined very loosely. Check whether the company defines "active" as:
- Logged in (weakest — includes accidental visits)
- Performed a core action (meaningful)
- 7-day or 30-day active (standard for mobile)
If "registered users" or "accounts created" is presented as "users," flag as MISLEADING.

### TAM Inflation via Top-Down Sizing
Many prospectuses claim a Total Addressable Market (TAM) using top-down analysis: "The global [broad category] market is $X billion (Gartner/IDC), and we address it all." This overstates TAM when the company serves a narrow sub-segment. Look for bottoms-up validation (number of potential customers × average deal size).

### "AI-Powered" Without Model Disclosure
Claims of being "AI-powered" or using "proprietary AI" without disclosing:
- What type of model (ML, deep learning, LLM, rule-based)
- Whether it's proprietary or fine-tuned from open-source/third-party
- What data it was trained on
Flag as UNVERIFIABLE if no technical details are provided.

### Cohort Metrics Cherry-Picking
Companies may present their best cohort's retention or expansion metrics as representative. Check whether metrics are:
- Across all cohorts (reliable)
- From the most recent cohort only (too early to judge)
- From a single best-performing cohort (cherry-picked)

---

## Financial Red Flags

- **Non-GAAP metrics without GAAP reconciliation** — "Adjusted EBITDA" or "Non-GAAP operating income" without showing the GAAP equivalent and reconciliation
- **Revenue recognition timing** — ASC 606 allows flexibility; check if multi-year deals are recognized upfront
- **Stock-based compensation excluded** — SBC is a real cost; excluding it from profitability metrics is misleading for high-SBC companies
- **Deferred revenue trends** — declining deferred revenue with growing ARR can signal booking issues
- **Customer concentration** — if top 5 customers account for >30% of revenue, this is a material risk

---

## Paywalled Source Workarounds (Tech)

| Source | Free access points |
|---|---|
| Gartner | Press releases at `gartner.com/en/newsroom` |
| IDC | Press releases at `idc.com/promo/pressrelease` |
| Forrester | Press newsroom at `forrester.com/press-newsroom` |
| Synergy Research | Articles at `srgresearch.com/articles` |
| Bessemer Cloud Index | Free at `cloudindex.bvp.com` |

**Trade publications for secondary verification:**
- TechCrunch (`techcrunch.com`)
- The Information (`theinformation.com`) — paywalled, but headlines useful
- Bessemer Cloud Index (`cloudindex.bvp.com`) — free SaaS benchmarking
- SaaStr (`saastr.com/blog`) — SaaS metrics commentary
- Meritech Capital SaaS Index — public SaaS company benchmarks
