# Domain: Biotech & Pharma

This domain file contains specialized verification knowledge for biotechnology, pharmaceutical, and life sciences documents. Load this file when the document under review covers drug development, clinical trials, FDA submissions, therapeutic areas, medical devices, or biotech/pharma IPOs.

---

## Source Directory

### FDA (U.S. Food and Drug Administration)
- **What they publish:** Drug approvals, clinical trial registrations, 510(k) clearances, warning letters, Orange Book (patent/exclusivity data)
- **Where to verify:**
  - Drugs@FDA: `accessdata.fda.gov/scripts/cder/daf/`
  - 510(k) database: `accessdata.fda.gov/scripts/cdrh/cfdocs/cfpmn/pmn.cfm`
  - Clinical trial search: `clinicaltrials.gov`
  - Orange Book: `accessdata.fda.gov/scripts/cder/ob/`
  - Warning letters: `fda.gov/inspections-compliance-enforcement-and-criminal-investigations/compliance-actions-and-activities/warning-letters`
- **Critical distinction:** "FDA-approved" vs "FDA-cleared" vs "FDA-registered" — these are very different regulatory statuses (see Pitfalls below)

### ClinicalTrials.gov
- **What they publish:** Registry of all clinical studies conducted in the US and many worldwide
- **Where to verify:** `clinicaltrials.gov`
- **Use for:** Verifying trial phase, enrollment numbers, primary endpoints, status (recruiting, completed, terminated), sponsor identity, and results
- **Gotcha:** Registration is required for most trials but results posting has variable compliance

### NIH / PubMed
- **What they publish:** Peer-reviewed biomedical literature, NIH-funded research
- **Where to verify:** `pubmed.ncbi.nlm.nih.gov`
- **Use for:** Verifying scientific claims, checking if cited studies exist, finding contradictory evidence

### EMA (European Medicines Agency)
- **What they publish:** European drug approvals, EPARs (European Public Assessment Reports)
- **Where to verify:** `ema.europa.eu/en/medicines`
- **Use for:** Cross-checking approval claims for European markets

### WHO
- **What they publish:** Disease burden data, Essential Medicines List, prequalification of medicines
- **Where to verify:** `who.int/data`, `who.int/medicines`

### SEC EDGAR
- **Where to verify:** `sec.gov/cgi-bin/browse-edgar`
- **Use for:** S-1 filings, 10-K/10-Q for public biotechs, checking financial claims against audited filings

---

## Industry Benchmarks

### Clinical Trial Success Rates (by Phase)

| Phase | Historical Success Rate | Notes |
|---|---|---|
| Phase I → Phase II | ~65% | Primarily safety; most compounds pass |
| Phase II → Phase III | ~30% | The biggest drop — efficacy often fails here |
| Phase III → NDA/BLA | ~58% | Large, expensive trials; regulatory bar is high |
| NDA/BLA → Approval | ~85% | Most well-run Phase III successes get approved |
| Overall (Phase I → Approval) | ~10% | Only ~1 in 10 drugs entering trials reaches market |

**Source:** BIO/QLS Advisors/Informa clinical development success rates study

### Development Timeline
- **Average drug development:** 10-15 years from discovery to approval
- **Fast track / breakthrough therapy:** Can reduce by 2-4 years
- **Accelerated approval:** Based on surrogate endpoints, but post-marketing studies required
- **Red flag:** Any pre-revenue biotech projecting FDA approval within 2-3 years from Phase I

### Typical Pre-Revenue Biotech Burn Rates
- **Pre-clinical:** $5-15M/year
- **Phase I:** $10-30M/year
- **Phase II:** $20-50M/year
- **Phase III:** $50-200M+/year
- **Red flag:** Cash runway <18 months without funding plan is a going concern risk

---

## Domain-Specific Pitfalls

### "FDA-Approved" vs "FDA-Cleared" vs "FDA-Registered"
These terms have very different regulatory meanings:
- **FDA-Approved** — Full premarket review (NDA/BLA for drugs, PMA for high-risk devices). The gold standard.
- **FDA-Cleared** — 510(k) clearance for devices shown to be substantially equivalent to a predicate. Less rigorous than approval.
- **FDA-Registered** — Simply means the facility is registered with FDA. Does NOT mean the product has been reviewed or approved. Any company can register.
If a prospectus says "FDA-approved" for a product that only has 510(k) clearance or mere facility registration, flag as INACCURATE.

### Preclinical Results Presented as Clinical Evidence
Preclinical studies (in vitro, animal models) are not clinical evidence. If a prospectus presents animal study results as evidence of efficacy in humans, or uses language like "proven effective" based on preclinical data, flag as MISLEADING. The leap from animal to human is where most drugs fail.

### Phase I Safety Data Cited as Efficacy
Phase I trials are designed to assess safety and dosing, not efficacy. They typically use very small sample sizes (20-80 patients). If a prospectus extrapolates efficacy conclusions from Phase I data, flag as MISLEADING.

### Patent Life vs Market Exclusivity
- **Patent life:** 20 years from filing date (not approval date)
- **Regulatory exclusivity:** Varies (5 years NCE, 7 years orphan drug, 12 years biologic)
- These are different clocks. A prospectus claiming "20 years of market protection" may be conflating patent life with exclusivity, or ignoring that the patent was filed years before approval.

### Orphan Drug Designation Overstated
Orphan drug designation means the FDA has acknowledged the disease affects <200,000 people in the US. It provides certain incentives (tax credits, 7-year exclusivity) but:
- It does NOT mean the drug is approved or likely to be approved
- It does NOT guarantee market exclusivity (can be broken if a competitor shows clinical superiority)
- Multiple companies can receive orphan designation for the same indication

### Endpoint Selection Bias
Watch for trials that switched their primary endpoint after the study began (post-hoc analysis), or that report secondary endpoints as if they were the primary result. Check ClinicalTrials.gov for the pre-registered primary endpoint.

---

## Financial Red Flags

- **Revenue from licensing/milestones only** — one-time payments can create misleading revenue peaks
- **R&D expense declining while in active trials** — suggests underfunding of clinical programs
- **Going concern language** — if the auditor includes going concern qualification, the company has <12 months of cash
- **Multiple failed trials with "pivots"** — serial pivot from one indication to another after failure is a red flag
- **Pipeline value claims** — "our pipeline is worth $X billion" based on peak sales estimates of unapproved drugs is highly speculative

---

## Paywalled Source Workarounds (Biotech)

| Source | Free access points |
|---|---|
| FDA | All databases freely accessible |
| ClinicalTrials.gov | Fully free |
| PubMed | Abstracts free; full text often via PMC |
| EMA | EPARs freely available |
| BIO success rate data | Press releases and summary reports |

**Trade publications for secondary verification:**
- STAT News (`statnews.com`) — authoritative biotech/pharma reporting
- BioPharma Dive (`biopharmadive.com`)
- Endpoints News (`endpointsnews.com`)
- FiercePharma (`fiercepharma.com`)
- Evaluate Pharma — industry benchmarking data (some paywalled)
