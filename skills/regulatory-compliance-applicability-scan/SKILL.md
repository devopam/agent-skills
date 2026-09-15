---
name: regulatory-compliance-applicability-scan
description: Maps researched regulatory regimes (GDPR union baseline plus EU member-state overlays when available; India DPDP; planned Americas/ME privacy and healthcare/fintech domains) to repo evidence. Explicitly declines unresearched countries or nuances. Not certification or legal advice.
---

# Regulatory compliance applicability scan

Applicability and gap-orientation for **runnable packs only**. Not certification,
not legal advice, not a compliance attestation.

Ask questions one at a time.

## Coverage

- Matrix: `research/regulatory-compliance-applicability-scan/07-coverage-matrix.md`
- EU layers: `08-eu-member-state-variations.md`
- Packs: [references/packs/](references/packs/)

**Europe:** `privacy-eu` (GDPR) ± `privacy-eu-*` overlays when they exist.  
**India:** `privacy-in` (DPDP, phased commencement).  
**Else:** Americas/ME/domains only when pack README marks runnable.

**Not covered:** Japan; DE/FR/IT (etc.) national law without overlay; inventing
requirements for any gap.

## Phase 0 — Intake

1. Target path  
2. Jurisdictions (if Europe → which **member state(s)**)  
3. Role, data classes, sector (healthcare/pharma, fintech, other)  
4. Suggest runnable packs only; **Not covered** for the rest  
5. Confirm pack list; optional compliance baseline file  

## Phase 1 — Evidence

Repo only. Path or “not found.” No invented processing activities.

## Phase 2 — Obligation map

Load each confirmed pack card. Primary cites from the card/registry only.
Prefer live official URL; note snapshot age if offline.

## Phase 3 — Report

[assets/report-template.md](assets/report-template.md):

1. Disclaimer (mandatory)  
2. Coverage table (requested / scanned / not covered)  
3. Applicability  
4. Themes + evidence labels  
5. Findings by severity  
6. Remediation with **primary cites**  
7. Source appendix  

If baseline + overlay both run, separate finding groups.

## Phase 4 — Baseline (optional)

`docs/compliance-baseline.md` from [assets/baseline-template.md](assets/baseline-template.md).

## Boundaries

- Never say the project **is compliant** or certified  
- Never invent article/section numbers  
- Secondary sources = interpretation aids only  
- Member-state nuance without overlay = **Not covered**  
