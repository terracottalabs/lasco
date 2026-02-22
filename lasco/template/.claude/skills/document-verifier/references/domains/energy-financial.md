# Domain: Energy & Financial Prospectuses

This domain file contains specialized verification knowledge for documents in the renewable energy, clean technology, and financial prospectus space. Load this file when the document under review covers solar, wind, battery storage, EV charging, energy markets, or related financial offerings.

---

## Energy Source Directory

### IRENA (International Renewable Energy Agency)
- **What they publish:** Renewable energy capacity data, investment needs, power generation costs, energy transition outlooks
- **Where to verify:**
  - Publications hub: `irena.org/Publications`
  - Data portal: `irena.org/Data`
  - Key reports: World Energy Transitions Outlook (annual), Renewable Power Generation Costs (annual)
  - Press releases: `irena.org/News/pressreleases`
- **What they do NOT publish:** Market size or "industry size" projections in dollar terms. IRENA publishes investment requirements and capacity targets, not revenue forecasts.
- **Gotcha:** Prospectuses often misattribute market size figures to IRENA when they actually come from private consulting firms.

### IEA (International Energy Agency)
- **What they publish:** World Energy Outlook, Global EV Outlook, energy market analyses, technology reports
- **Where to verify:**
  - Reports hub: `iea.org/reports`
  - Data explorer: `iea.org/data-and-statistics`
  - EV data: `iea.org/reports/global-ev-outlook-2024`
- **Access:** Executive summaries are free; full reports may require purchase.

### BloombergNEF (BNEF)
- **What they publish:** New Energy Outlook (NEO), battery price surveys, energy transition investment tracking
- **Where to verify:**
  - Main page: `about.bnef.com`
  - NEO series: `about.bnef.com/new-energy-outlook/`
  - Blog/press: `about.bnef.com/blog/`
  - Executive summary PDFs: `assets.bbhub.io/professional/sites/24/` (free)
- **Access:** Most reports are paywalled. Use free executive summary PDFs, press releases, and third-party coverage.
- **Gotcha:** The famous "50 by 50" projection from NEO 2019 is wind + solar combined (~48%), not solar alone. Prospectuses frequently misstate this as solar-only.
- **Third-party coverage:** Utility Dive (`utilitydive.com`), PV Tech (`pv-tech.org`), PV Magazine (`pv-magazine.com`)

### U.S. Department of Energy (DOE)
- **Where to verify:** `energy.gov`
- **Key resources:**
  - Solar Investment Tax Credit: `energy.gov/eere/solar`
  - Energy Storage Grand Challenge: `energy.gov/energy-storage-grand-challenge`
  - Inflation Reduction Act: `energy.gov/lpo/inflation-reduction-act-2022`
  - NREL reports: `nrel.gov/publications.html`

### U.S. Department of Transportation (DOT)
- **Where to verify:** `transportation.gov`
- **Key resource:** EV Charging Speeds — `transportation.gov/rural/ev/toolkit/ev-basics/charging-speeds`
- **Key fact:** DOT states Level 2 chargers take "4–10 hours" to charge a BEV from empty.

### SEC EDGAR (Securities and Exchange Commission)
- **Where to verify:** `sec.gov/cgi-bin/browse-edgar`
- **What to check:** S-1 filings (IPO prospectuses), 10-K (annual reports), 10-Q (quarterly), company filings history
- **Use for:** Verifying if a company has actually filed with the SEC, cross-referencing financial claims against audited filings

### USPTO (United States Patent and Trademark Office)
- **Where to verify:** `patft.uspto.gov` (full-text patent search)
- **Use for:** Verifying patent claims. Search by assignee name to find patents held by a company.

### EPA (Environmental Protection Agency)
- **Where to verify:** `epa.gov`
- **Use for:** Emissions data, environmental regulations, clean energy program details

### IRS
- **Where to verify:** `irs.gov/credits-and-deductions-under-the-inflation-reduction-act-of-2022`
- **Use for:** Verifying tax credit eligibility and amounts

---

## Industry Benchmarks

### Solar Panel Efficiency
- **EnergySage:** `energysage.com/solar/what-are-the-most-efficient-solar-panels-on-the-market/`
- **Clean Energy Reviews:** `cleanenergyreviews.info/blog/most-efficient-solar-panels`
- **Key benchmark (2025):** Average new monocrystalline panel: 20–22%. Industry-leading: 24–25% (Aiko, LONGi).

### Battery Energy Storage
- **Clean Energy Reviews:** `cleanenergyreviews.info/blog/lithium-battery-life-explained`
- **Renogy:** `renogy.com/blog/how-long-do-lifepo4-batteries-last-/`
- **Key benchmark:** LFP (lithium iron phosphate) batteries: 15–20 year lifespan, 6,000–10,000 cycles. NMC: 8–12 years.

### EV Charging Times
- **EnergySage:** `energysage.com/ev-charging/how-long-does-it-take-to-charge-an-ev/`
- **U.S. DOT:** `transportation.gov/rural/ev/toolkit/ev-basics/charging-speeds`
- **Key benchmark:** Level 2 (7 kW): ~8 hours for 60 kWh battery. Level 2 (12 kW): 2–5.5 hours depending on battery size. Level 3: 30 min or less.

### Battery Pack Prices
- **BloombergNEF Annual Battery Price Survey**
- **Key benchmark:** $1,100/kWh in 2010 → $108/kWh in 2025 (>90% decline)

---

## Energy-Specific Pitfalls

These are errors frequently found in energy sector prospectuses:

### IRENA Market Size Misattribution
IRENA does **not** publish market-size projections in dollar terms. They publish investment requirements and capacity targets. If a prospectus says "According to IRENA, the renewable energy market will reach $X billion," the figure almost certainly comes from a private market research firm (MarketsandMarkets, Grand View, Allied, etc.), not IRENA.

### BNEF "50 by 50" Misquote
The Bloomberg NEF New Energy Outlook 2019 projected that wind **and** solar **combined** would reach approximately 48% of global electricity generation by 2050. Prospectuses frequently cite this as "solar will account for 50% by 2050" — conflating the combined wind+solar figure with solar alone, and rounding up.

### "Industry-Leading" Solar Efficiency
A claim of "industry-leading conversion rates of over 22%" is misleading. 22% is the current market average for new monocrystalline panels, not industry-leading. True industry-leading panels achieve 24–25% (Aiko 25.0%, LONGi 24.8% as of 2025). A 22% claim should be flagged as MISLEADING.

### Battery Chemistry Omission
Claims about "lithium-ion battery lifespan of 15+ years" are only true for **LFP (lithium iron phosphate)** chemistry. NMC lithium-ion batteries last 8–12 years. If the prospectus doesn't specify chemistry, the 15-year claim needs qualification.

### EV Charging Time Ambiguity
"Fully charge most EVs in less than 4 hours" is only accurate for Level 2 chargers at 12 kW with smaller batteries (~40 kWh). At 7 kW (common residential), charging takes ~8 hours for a standard 60 kWh battery. Always check the charger power level and battery size assumptions.

---

## Financial Red Flags (Energy Sector)

- **No auditor named** — energy startups often present financial projections without audited historical financials
- **Revenue predating founding** — if the company was founded in 2020, there should be no 2019 revenue
- **Implausibly smooth growth** — real energy companies have seasonal and market-driven variance
- **Missing balance sheet** — revenue without assets/liabilities is incomplete
- **Tax credit assumptions** — check if revenue projections depend on ITC/PTC credits that may expire or phase down

---

## Paywalled Source Workarounds (Energy)

| Source | Free access points |
|---|---|
| BloombergNEF | Executive summary PDFs at `assets.bbhub.io`, blog posts at `about.bnef.com/blog/` |
| IEA | Executive summaries free at `iea.org/reports` |
| IRENA | Most reports freely available at `irena.org/Publications` |
| Wood Mackenzie | Press releases, Utility Dive coverage |
| Lazard LCOE | Annual LCOE study usually freely available |

**Energy trade publications for secondary verification:**
- Utility Dive (`utilitydive.com`)
- PV Tech (`pv-tech.org`)
- PV Magazine (`pv-magazine.com`)
- Greentech Media (now part of Wood Mackenzie)
- Renewable Energy World (`renewableenergyworld.com`)
- CleanTechnica (`cleantechnica.com`)

---

## Browser Verification Notes (Energy)

Common energy sites that block WebFetch but work with agent-browser:
- IRENA publications pages
- BloombergNEF blog posts
- Some market research firm report pages (MarketsandMarkets, Allied)
- Government PDF viewers (DOE, DOT)
- EnergySage data pages
