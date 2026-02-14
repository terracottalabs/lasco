# Domain: Legal Litigation

This domain file contains specialized verification knowledge for legal case documents, including pleadings, affidavits, witness statements, corporate filings, meeting minutes, and correspondence. Load this file when the document under review covers litigation, corporate disputes, shareholder disputes, director removal, unfair prejudice petitions, winding-up petitions, or any contested legal proceedings.

---

## Source Directory

### Companies Registry (Hong Kong)
- **What they publish:** Company incorporation records, annual returns, director/secretary changes (Form ND2A), charges, registered office
- **Where to verify:** `icris.cr.gov.hk` (Integrated Companies Registry Information System)
- **Use for:** Verifying incorporation dates, registered directors, shareholders, company secretary, filed forms and their dates

### HKLII (Hong Kong Legal Information Institute)
- **What they publish:** Hong Kong court judgments, legislation, subsidiary legislation
- **Where to verify:** `hklii.hk`
- **Use for:** Finding cited case authorities, checking legislation sections, reviewing precedent decisions

### Companies Ordinance (Cap. 622)
- **Key provisions frequently cited in corporate disputes:**
  - Part 12 (ss. 455-460): Unfair prejudice petition
  - Part 11 (ss. 327-372): Winding up
  - s. 724: Just and equitable winding up
  - Part 5 (ss. 138-203): Directors and company secretaries
  - Part 3 (ss. 67-100): Share capital
- **Where to verify:** `elegislation.gov.hk`

### Land Registry (Hong Kong)
- **What they publish:** Property ownership records, encumbrances, memorial registrations
- **Where to verify:** `iris.landreg.gov.hk`
- **Use for:** Verifying property ownership claims, checking for charges or encumbrances

### Court Files
- **What they publish:** Filed pleadings, orders, judgments, summonses
- **Where to verify:** High Court Registry, District Court Registry
- **Use for:** Verifying procedural history, confirming orders made, checking filing dates

---

## Industry Benchmarks

### Corporate Governance Standards

| Requirement | Typical Standard | Source |
|---|---|---|
| Board meeting notice | 14 days (or as specified in Articles) | Articles of Association |
| EGM notice for special resolution | 14 clear days | Companies Ordinance s. 571 |
| AGM notice | 21 clear days | Companies Ordinance s. 569 |
| Quorum for general meeting | 2 members (or as per Articles) | Companies Ordinance s. 578 |
| Ordinary resolution | Simple majority (>50%) | Companies Ordinance s. 563 |
| Special resolution | 75% majority | Companies Ordinance s. 564 |
| Filing ND2A after director change | Within 15 days | Companies Ordinance s. 645 |
| Filing annual return | Within 42 days of anniversary | Companies Ordinance s. 662 |

### Unfair Prejudice Petition Standards (s. 724)

| Element | What must be shown |
|---|---|
| Standing | Petitioner is a member of the company |
| Conduct | Company's affairs conducted in a manner unfairly prejudicial to members generally or to the petitioner |
| Alternative | OR an act/omission of the company (actual or proposed) is/would be prejudicial |
| Remedy | Court may make such order as it thinks fit (s. 725) — including buyout, regulation of affairs, restraining conduct |

---

## Domain-Specific Pitfalls

### Backdated Meeting Minutes
Minutes of meetings that were likely created after the fact. Red flags include:
- References to events that occurred after the purported meeting date
- Formatting inconsistent with other contemporaneous documents
- No evidence the meeting was actually convened (no notice, no venue booking, no attendance sign-in)
- Minutes appearing for the first time in litigation bundles, not in company minute books

### Notice Period Miscalculation
Articles commonly require "14 days' notice" for board meetings. Common errors:
- Counting from the date the notice was sent rather than the date of receipt
- Not allowing for clear days (excluding both the day of service and the day of meeting)
- Serving by a method not authorized under the Articles (e.g., email when Articles require writing)
- Not serving on all directors (sometimes deliberately excluding the target director)

### Quorum Irregularities
- Meeting held with interested parties counting toward quorum when Articles exclude interested directors
- Telephone/virtual attendance counted when Articles require physical presence
- Meeting continuing after a member leaves, dropping below quorum

### Resolution Scope Exceeded
A board of directors may attempt to pass resolutions that actually require shareholder approval:
- Allotment of new shares typically requires shareholder approval
- Removal of a director requires ordinary resolution of shareholders (Companies Ordinance s. 462), not board resolution
- Amendments to Articles require special resolution (75%)
- Change of company name requires special resolution

### Self-Dealing in Small Companies
In quasi-partnership companies (small companies run like partnerships), common issues:
- Majority shareholder(s) paying themselves excessive salaries/bonuses
- Diverting business opportunities to related companies
- Excluding minority shareholders from management contrary to informal understandings
- Using corporate mechanisms (share allotment, director removal) to dilute minority

### Document Provenance Issues
- Affidavits exhibiting documents without explaining their origin
- Undated documents relied upon as if their date were established
- Copies presented without originals being available
- Documents in languages other than English presented without certified translations

---

## Financial Red Flags

- **Company accounts showing related-party transactions** without proper disclosure or arm's-length pricing
- **Director loans** not properly documented or authorized by the board
- **Dividend payments** not matching profitability or not properly declared by resolution
- **Missing management accounts** for periods relevant to the dispute
- **Discrepancies** between management accounts, audited accounts, and tax filings
- **Revenue recognition** from related entities that may not be genuine arm's-length transactions

---

## Trade Publications

For secondary verification of legal matters:
- Hong Kong Lawyer (`hk-lawyer.org`)
- Asian Legal Business (`legalbusinessonline.com`)
- Hong Kong Law Journal (academic — via HKU)
- Lexis+ Hong Kong / Westlaw China
