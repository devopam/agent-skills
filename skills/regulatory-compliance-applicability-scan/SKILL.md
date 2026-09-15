---
name: regulatory-compliance-applicability-scan
description: Maps researched privacy regimes and domain overlays to repo evidence. Declines any jurisdiction or domain without a runnable pack (no fixed country blocklist). Not legal advice or certification.
---

# Regulatory compliance applicability scan

Applicability and gap-orientation for packs listed as runnable in
[references/packs/README.md](references/packs/README.md). Not certification.

Ask questions one at a time.

## Coverage

**Runnable packs** are the sole source of truth. If the user names a country,
regime, or domain that is **not** in that inventory (whether Japan, China,
Korea, Russia, or any other), respond **Not covered** — do not invent law.

Current wave includes: GDPR + DE/FR/IT overlays; India DPDP; California CCPA/CPRA;
PIPEDA; LGPD; UAE/Saudi PDPL; fintech (PCI orientation); healthcare (HIPAA gate).

**Planned later:** further major economies (e.g. CN, KR, RU, JP) and more
overlays — see research coverage matrix / roadmap.

## Phase 0 — Intake

1. Target path  
2. Jurisdictions (Europe → which member state)  
3. Role, data classes, sector  
4. Map requests → **runnable** packs only; generic **Not covered** for the rest  
5. Confirm list; optional baseline file  

## Phases 1–4

Evidence → obligation map from confirmed cards → report (coverage table,
severity, primary cites) → optional baseline.

Pair `privacy-eu-*` with `privacy-eu`; pair domains with regional privacy.

## Boundaries

No compliant/certified claims; no invented cites; secondary sources are aids only.
