---
name: regulatory-compliance-applicability-scan
description: >
  Scan a project for likely applicability of domain and privacy regulations.
  Suggests requirements grounded in primary legal instruments; does not certify compliance.
  Global privacy jurisdiction packs (near-exhaustive practical inventory) plus fintech and healthcare domain packs.
---

# Regulatory compliance applicability scan

## Purpose

Help teams understand **which** regulatory regimes may apply to a codebase or product, with findings tied to **primary legal citations**. Output is **applicability and gap orientation**, never a compliance certificate.

## Boundaries

- **Suggest, do not certify.** Never claim "compliant" or "certified".
- **Primary sources preferred.** Use pack primary citations; secondary materials are orientation only.
- **Not covered rule.** If a jurisdiction or domain has no runnable pack (or is marked NOT COVERED / not in force), say so clearly. Do not invent obligations from draft bills.
- **Portable install.** Only skill-local paths under `references/` and `assets/` (IDE-safe). Monorepo research/registry is maintainer-only.

## Coverage

Full runnable inventory and gates: [`references/packs/README.md`](references/packs/README.md).

- **Privacy:** Near-exhaustive practical global set (EU/EEA + national overlays, UK, CH, broad Americas/US states, Asia-Pacific, MEA, Caribbean, microstates, Crown dependencies). Explicit **Not covered** packs where no general PDP statute exists.
- **Domains (v0):** `domain-fintech` (PCI DSS orientation), `domain-healthcare-pharma` (HIPAA gate when PHI in scope).

## Intake

Prompt for: jurisdictions/markets, data types (incl. PHI/card data), controller vs processor role, and any user-selected domains. Suggest packs from repo signals when user is unsure.

## Method

1. Select packs from intake + repo signals.
2. Apply **not-covered** and **force/commencement gates** before obligation themes.
3. Map themes → primary article/section orientation → repo evidence → gap suggestions.
4. Report with severity-ordered observations; tabular scoring optional for human review.

## Safety language

Always frame output as **possible requirements to discuss with qualified counsel**, not legal advice.
