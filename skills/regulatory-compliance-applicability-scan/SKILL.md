---
name: regulatory-compliance-applicability-scan
description: Maps researched regulatory regimes (data privacy by region, including GDPR baseline plus EU member-state overlays when available; healthcare/pharma and fintech domains) to repo evidence. States clearly when a country nuance or domain is not covered. Not certification or legal advice.
---

# Regulatory compliance applicability scan

Applicability and gap-orientation for **packs that exist**. Not certification,
not legal advice, not a compliance attestation.

Ask questions one at a time.

## Coverage

See `research/regulatory-compliance-applicability-scan/07-coverage-matrix.md`
and [08-eu-member-state-variations.md](../../../research/regulatory-compliance-applicability-scan/08-eu-member-state-variations.md).

### Europe

| Layer | Pack | Role |
|-------|------|------|
| Union baseline | `privacy-eu` | GDPR only |
| National nuance | `privacy-eu-de`, `privacy-eu-fr`, `privacy-eu-it`, … | Member-state overlays when cards+registry exist |

If the user needs **Germany/France/Italy/…-specific** rules and the overlay is
missing: say **Not covered** for that national nuance; optionally still run
`privacy-eu`. **Do not invent** BDSG/CNIL/Codice requirements.

### Other privacy regions

India, Americas (per country), Middle East (per country) — as packs exist.

### Domains

Healthcare/pharma, fintech — overlay packs when they exist.

### Not covered examples

Japan; unresearched EU member states’ national law; other verticals.

## Phase 0 — Intake

1. Target path  
2. Jurisdictions (**ask member state** when Europe is selected)  
3. Role, data classes, sector  
4. Suggest only **runnable** packs; decline gaps explicitly  
5. Confirm pack list (e.g. `privacy-eu` + `privacy-eu-de` when both exist)  

## Phases 1–4

Evidence pass → obligation map from **confirmed pack cards only** → report
(with **Coverage for this run** and separate baseline vs overlay findings when
both run) → optional baseline file.

## Boundaries

- No “compliant” / certified claims  
- No invented article or national section numbers  
- Secondary sources = interpretation aids only  
