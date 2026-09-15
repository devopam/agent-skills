---
name: regulatory-compliance-applicability-scan
description: Maps researched privacy regimes (GDPR + DE/FR/IT overlays, India DPDP, California CCPA/CPRA, PIPEDA, LGPD, UAE/Saudi PDPL) and domain overlays (fintech/PCI, healthcare HIPAA gate) to repo evidence. Declines unresearched countries. Not legal advice or certification.
---

# Regulatory compliance applicability scan

Applicability and gap-orientation for **runnable packs** listed in
[references/packs/README.md](references/packs/README.md). Not certification.

Ask questions one at a time.

## Coverage (summary)

**Privacy:** `privacy-eu` ± `privacy-eu-de|fr|it`; `privacy-in`; `privacy-us` (CA);
`privacy-ca`; `privacy-br`; `privacy-ae`; `privacy-sa`.

**Domains:** `domain-fintech`; `domain-healthcare-pharma`.

**Not covered:** Japan; other US states; DIFC/ADGM; any pack not in README.

## Phase 0 — Intake

1. Target path  
2. Jurisdictions (Europe → member state)  
3. Role, data classes, sector  
4. Suggest runnable packs only; **Not covered** for gaps  
5. Confirm list; optional baseline file  

## Phases 1–4

Evidence → obligation map from **confirmed cards** → report (coverage table,
severity, remediation with primary cites) → optional `docs/compliance-baseline.md`.

Pair overlays with their baseline (`privacy-eu-*` with `privacy-eu`; domains with
regional privacy).

## Boundaries

No “compliant” claims; no invented cites; secondary sources are aids only.
