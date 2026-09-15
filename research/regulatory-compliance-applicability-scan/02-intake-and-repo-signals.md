# Intake and repo signals

## User intake (one question at a time)

1. Target path (repo root or product package)
2. Markets / jurisdictions (map free text → coverage matrix)
3. Role: controller / fiduciary, processor, sub-processor, unclear
4. Data classes: personal data, sensitive/special category, payments, health, children
5. Sector: **healthcare/pharma**, **fintech**, general SaaS, other
6. Already claimed frameworks (SOC 2, ISO 27001, existing DPA, etc.)

## Mapping requests to packs

| User says | Skill does |
|-----------|------------|
| Europe / EU / GDPR | Suggest `privacy-eu` if card exists |
| India / DPDP | Suggest `privacy-in` if card exists |
| Americas / US / California / Canada / Brazil | Suggest **country** packs that exist; if only “Americas” and no country pack ready, say which Americas packs are not covered yet |
| Middle East / UAE / Saudi | Same — country packs only |
| Japan / Korea / … | **Not covered** — explicit decline |
| Healthcare / pharma | Suggest `domain-healthcare-pharma` if pack exists; else not covered |
| Fintech / payments / banking app | Suggest `domain-fintech` if pack exists; else not covered |

## Repo signals (suggest only)

| Signal | Possible suggestion |
|--------|---------------------|
| GDPR, EU customers | privacy-eu |
| DPDP, data fiduciary, India | privacy-in |
| HIPAA, PHI, patient | domain-healthcare-pharma + regional privacy |
| Stripe, card PAN, open banking | domain-fintech + regional privacy |
| CCPA, “do not sell”, California | privacy-us (when available) |
| LGPD, Brazil | privacy-br (when available) |

## Phase 0 output

Candidate **covered** packs → user confirms → deep scan.  
Any requested but uncovered scope → listed under **Not covered** and excluded
from obligation invention.
