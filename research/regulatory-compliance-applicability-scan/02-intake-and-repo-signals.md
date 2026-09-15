# Intake and repo signals

## User intake (one question at a time)

1. Target path (repo root or product package)
2. Markets / jurisdictions where users or processing occur
3. Role: controller / fiduciary, processor, sub-processor, unclear
4. Data classes: personal data, sensitive/special category, payments, health, children
5. Sector: general SaaS, health, finance, education, government, other
6. Already claimed frameworks (SOC 2, ISO 27001, existing DPA, etc.)

## Repo signals (suggest only; never auto-select packs)

| Signal | Possible suggestion |
|--------|---------------------|
| README / marketing: GDPR, privacy, EU customers | privacy-eu |
| India users, DPDP, MeitY, “data fiduciary” | privacy-in |
| Stripe / payment forms / card fields | payments-pci (later pack) |
| PHI, HL7, “patient”, HIPAA | health-us-hipaa (later; high bar) |
| Analytics / ad SDKs, tracking pixels | privacy packs + subprocessors theme |
| `privacy.md`, DPA templates, ROPA stubs | governance evidence |
| Multi-region cloud config | transfers / residency themes |

## Phase 0 output

Candidate pack list → **user confirms** → Phase 1 evidence pass.
