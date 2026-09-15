# Packs roadmap

See also **[07-coverage-matrix.md](07-coverage-matrix.md)** (authoritative
available vs not-covered).

## Domains (vertical) — first two

| Pack id | Priority | Depends on |
|---------|----------|------------|
| `domain-healthcare-pharma` | 1 | Regional privacy packs in scope + health-specific primary sources |
| `domain-fintech` | 1 | Regional privacy packs + payments/financial primary sources (e.g. PCI where applicable) |

## Data privacy governance — regions

| Pack id | Region | Priority | Primary orientation |
|---------|--------|----------|---------------------|
| `privacy-eu` | Europe | **Current** | GDPR Reg. (EU) 2016/679 |
| `privacy-in` | India | Next | DPDP Act 2023 + rules / Gazette commencement |
| `privacy-us` | Americas (US) | Next wave | Official US code / state statutes in scope — no fake “US GDPR” |
| `privacy-ca` | Americas (Canada) | Next wave | PIPEDA / relevant federal text |
| `privacy-br` | Americas (Brazil) | Next wave | LGPD official text |
| `privacy-ae` | Middle East (UAE) | Next wave | UAE PDPL official text when locked in registry |
| `privacy-sa` | Middle East (KSA) | Next wave | KSA PDPL official text when locked in registry |
| `privacy-uk` | Europe (UK) | Later | UK GDPR / DPA path on legislation.gov.uk |

## Explicitly out of roadmap until researched

Japan, Korea, Australia, Singapore, Africa, “global one-pack,” and any domain
other than healthcare/pharma and fintech — **not covered**; skill must say so.

## Implementation order (practical)

1. Finish `privacy-eu` cards + evals + not-covered eval  
2. `privacy-in`  
3. Americas split (`privacy-us` first if US-heavy signals)  
4. Middle East country packs  
5. `domain-fintech` / `domain-healthcare-pharma` overlays with primary sources  
