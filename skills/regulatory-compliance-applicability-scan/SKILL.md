---
name: regulatory-compliance-applicability-scan
description: Maps which regulatory regimes may apply to a project (privacy and related domains) and which obligation themes look met, partial, or missing in the repo — grounded in primary legal sources via a hybrid registry/snapshots model. Use when assessing GDPR/DPDP applicability, privacy compliance readiness, or regulatory gap orientation — not for certification or legal advice.
---

# Regulatory compliance applicability scan

Produce an **applicability and gap-orientation** report for selected regulatory
packs. This is **not** a certification, **not** legal advice, and **not** a
declaration that the project is compliant.

Ask questions one at a time in plain text.

## Phase 0 — Intake and pack selection

1. Confirm target path.
2. Collect jurisdictions, role (controller/processor/etc.), data classes, sector.
3. Scan the repo for signals (privacy policy, SDKs, payment/health terms,
   region config). **Suggest** packs; do not auto-run unconfirmed packs.
4. User confirms pack list (v0 focus: `privacy-eu`; `privacy-in` when cards exist).
5. Ask whether to write/update `docs/compliance-baseline.md` after the scan.

If the user declines all packs, stop.

## Phase 1 — Evidence pass

Gather repo evidence only: docs, configs, data-flow hints, vendor SDKs,
auth/session, logging/retention mentions, DPA templates, subprocessors lists.

**Evidence rule:** every gap needs a path or an explicit “not found in tree.”
Do not invent processing activities.

## Phase 2 — Obligation map

For each confirmed pack, use
[references/packs/](references/packs/) obligation cards. Map themes to
**primary cites** from the card/registry. Consult
`compliance-sources/registry.yaml` and snapshot `meta.json` for URLs and
freshness; prefer live official text when reachable.

## Phase 3 — Report

Follow [assets/report-template.md](assets/report-template.md):

1. Mandatory disclaimer
2. Applicability table
3. Obligation themes + evidence labels
4. Findings Critical → Important → Minor → Not assessed
5. Remediation with **article/section cite** + evidence
6. Source appendix (registry ids, URLs, snapshot ages)

## Phase 4 — Baseline (optional)

If requested, write [assets/baseline-template.md](assets/baseline-template.md)
style content to `docs/compliance-baseline.md`.

## Boundaries

- Never claim the project is compliant or certified.
- Never invent article numbers; only use pack cards / registry.
- Secondary sources (EDPB, blogs) are interpretation aids only.
- Suggest policies and control directions; do not file with regulators.
- Hand off security-control depth to other skills where appropriate;
  CI/CD to `ci-cd-plumber`; general product scaffolding to `project-incubation`.
