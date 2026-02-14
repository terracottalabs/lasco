# Domain: Fintech & Payments

This domain file contains specialized verification knowledge for fintech, payments, banking, and financial services technology documents. Load this file when the document under review covers payment processing, digital banking, lending platforms, cryptocurrency/blockchain, insurance tech, or fintech IPOs.

---

## Source Directory

### CFPB (Consumer Financial Protection Bureau)
- **What they publish:** Consumer complaint data, enforcement actions, regulatory guidance on lending, payments, credit reporting
- **Where to verify:** `consumerfinance.gov`, complaint database at `consumerfinance.gov/data-research/consumer-complaints/`
- **Use for:** Checking for enforcement actions against the company, verifying regulatory compliance claims

### OCC (Office of the Comptroller of the Currency)
- **What they publish:** Bank charter information, enforcement actions, fintech charter guidance
- **Where to verify:** `occ.treas.gov`
- **Use for:** Verifying bank charter status, checking if a fintech actually holds a bank charter vs. using a bank partner

### FINRA BrokerCheck
- **What they publish:** Broker-dealer registration, investment adviser registrations, disciplinary history
- **Where to verify:** `brokercheck.finra.org`
- **Use for:** Verifying broker-dealer registrations, checking for disciplinary actions against leadership

### FDIC
- **What they publish:** Bank insurance status, failed bank list, financial institution data
- **Where to verify:** `fdic.gov`, BankFind at `research.fdic.gov/bankfind/`
- **Use for:** Verifying FDIC insurance claims, checking if deposits are actually FDIC-insured (many fintech "bank accounts" are not directly insured)

### Federal Reserve
- **What they publish:** Payments system data, FedNow information, money supply, regulatory guidance
- **Where to verify:** `federalreserve.gov`
- **Key reports:** Federal Reserve Payments Study, FedNow service directory

### State Banking Regulators (NMLS)
- **What they publish:** Money transmitter licenses, lending licenses, state-by-state regulatory status
- **Where to verify:** NMLS Consumer Access at `nmlsconsumeraccess.org`
- **Use for:** Verifying money transmitter license claims — critical for payments companies

### SEC EDGAR
- **Where to verify:** `sec.gov/cgi-bin/browse-edgar`
- **Use for:** S-1 filings, checking if a company offering securities is properly registered

### Nilson Report
- **What they publish:** Payment industry statistics (card volumes, market share)
- **Where to verify:** `nilsonreport.com` (mostly paywalled; key figures cited in press coverage)

---

## Industry Benchmarks

### Payment Processing Take Rates

| Processor/Model | Typical Take Rate | Notes |
|---|---|---|
| Stripe (SMB) | ~2.9% + $0.30/txn | Standard US online pricing |
| Adyen (Enterprise) | ~0.2-0.6% | Volume-based; much lower for large merchants |
| Square (in-person) | ~2.6% + $0.10/txn | Standard in-person rate |
| PayPal (online) | ~2.9% + $0.49/txn | Standard US online |
| Interchange (Visa/MC) | ~1.5-3.0% | Set by networks; non-negotiable |
| Wholesale model | ~0.1-0.3% markup | Above interchange; for large-volume processors |

**Red flag:** A payments company claiming >3% net take rate in a mature market is likely including interchange in their "revenue" figure or serving a high-risk vertical.

### Net Interest Margins (Lending)
- **Traditional banks:** 2.5-3.5%
- **Neobanks/digital banks:** 3.0-5.0% (often higher-risk borrowers)
- **BNPL:** Varies widely; merchant discount fees (3-6%) plus late fees
- **Red flag:** NIM >6% without disclosing risk tier of borrowers

### Card Interchange Rates
- **Debit:** ~0.5-1.0% (regulated by Durbin Amendment for large banks)
- **Credit:** ~1.5-3.0% (varies by card type, merchant category)
- **Premium/rewards cards:** ~2.0-3.0%+
- **Red flag:** Claiming interchange revenue without disclosing network costs and scheme fees

### Loan Loss Provisions
- **Prime consumer:** 1-3% annualized charge-off rate
- **Subprime consumer:** 5-15%+ annualized
- **Red flag:** Growing loan portfolio with flat or declining loss provisions

---

## Domain-Specific Pitfalls

### TPV/GMV Cited as Revenue
Total Payment Volume (TPV) or Gross Merchandise Value (GMV) is the total value of transactions processed — NOT revenue. A company processing $10B in TPV at a 2.5% take rate has ~$250M in revenue, not $10B. If a prospectus prominently features TPV/GMV without clearly distinguishing it from revenue, flag as MISLEADING.

### "Bank" Without a Bank Charter
Many fintechs say they are a "digital bank" or "neobank" but do not hold a bank charter. They typically partner with a chartered bank (the "sponsor bank" or "bank partner" model):
- Customer deposits are held by the partner bank, not the fintech
- FDIC insurance applies to the partner bank's obligations, not the fintech's
- If the partner bank relationship ends, customer accounts are at risk
If a prospectus calls the company a "bank" without disclosing the bank-partner model, flag as MISLEADING.

### Money Transmitter License Coverage
Money transmitter licenses are state-by-state in the US. Claiming "licensed in all 50 states" needs verification:
- Check NMLS Consumer Access for the actual license list
- Some states have exemptions (e.g., for banks, agents of banks)
- Montana doesn't require a money transmitter license
- State licenses don't cover international operations

### "Regulated" Without Specifying Regulator
Claiming to be "fully regulated" or "compliant with all applicable regulations" without naming the specific regulator or license type is a red flag. Specific claims to check:
- Broker-dealer → should be FINRA-registered
- Money transmission → state licenses (check NMLS)
- Banking → OCC charter or state bank charter
- Securities → SEC registration
- Lending → state lending licenses

### FDIC Insurance Misrepresentation
"FDIC-insured deposits" on a fintech product requires that:
1. The funds are actually held at an FDIC-insured bank (not the fintech itself)
2. The pass-through deposit insurance rules are properly followed
3. Coverage is per depositor per bank — if the fintech uses one partner bank, the $250K limit applies across all customers at that bank
Flag any FDIC claim that doesn't identify the specific partner bank(s).

### Unit Economics on Blended Metrics
Watch for fintechs blending high-margin and low-margin products:
- "Average revenue per user" that combines premium and free users
- "Net revenue retention" that includes pricing changes, not just organic expansion
- "Customer lifetime value" calculated on insufficient cohort data (<2 years)

---

## Financial Red Flags

- **Regulatory capital requirements not discussed** — banks and lending companies have capital adequacy requirements
- **Partner bank concentration** — dependence on a single bank partner is a business continuity risk
- **Crypto/digital asset exposure** — check if balance sheet includes volatile crypto holdings
- **Loan portfolio aging** — new lending portfolios haven't been tested through a credit cycle
- **"Adjusted revenue"** — fintech-specific non-GAAP metric that may exclude transaction costs, chargebacks, or refunds

---

## Paywalled Source Workarounds (Fintech)

| Source | Free access points |
|---|---|
| CFPB | All data and enforcement actions freely available |
| FINRA BrokerCheck | Fully free |
| FDIC BankFind | Fully free |
| NMLS Consumer Access | Fully free |
| Federal Reserve Payments Study | Freely available |
| Nilson Report | Key figures cited in American Banker, PaymentsSource |

**Trade publications for secondary verification:**
- American Banker (`americanbanker.com`)
- Finextra (`finextra.com`)
- PaymentsSource (`paymentssource.com`)
- Lex Newsletter (Financial Times) — fintech commentary
- The Fintech Times (`thefintechtimes.com`)
- Tearsheet (`tearsheet.co`) — fintech analysis
