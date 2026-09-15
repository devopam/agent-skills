---
name: regulatory-compliance-applicability-scan
description: Maps which researched regulatory regimes may apply to a project (data privacy by region; healthcare/pharma and fintech domain overlays) and which obligation themes look met, partial, or missing — grounded in primary sources. Clearly states when a region or domain is not covered yet (e.g. Japan). Not certification or legal advice.
---

# Regulatory compliance applicability scan

Produce an **applicability and gap-orientation** report for **packs that this
skill actually covers**. This is **not** certification, **not** legal advice,
and **not** a claim that the project is compliant.

Ask questions one at a time in plain text.

## Coverage (what we do and do not scan)

Authoritative detail:
`research/regulatory-compliance-applicability-scan/07-coverage-matrix.md`
and pack files under [references/packs/](references/packs/).

### In scope (roadmap — only run packs that exist as cards + registry)

**Data privacy governance — regions**

| Region | Pack direction |
|--------|----------------|
| Europe | `privacy-eu` (GDPR); later UK as separate pack |
| India | `privacy-in` (DPDP) |
| Americas | Country packs (e.g. US / Canada / Brazil) — not a single “Americas” blob |
| Middle East | Country packs (e.g. UAE / KSA) as researched |

**Product domains (first two verticals)**

| Domain | Pack direction |
|--------|----------------|
| Healthcare / pharma | `domain-healthcare-pharma` |
| Fintech | `domain-fintech` |

### Not covered (examples)

- **Japan** (and other countries/regions without a pack)
- Domains other than healthcare/pharma and fintech
- “Scan the whole world” / inventing obligations for unresearched law

**Required behaviour:** If the user asks for an uncovered region or domain,
state **Not covered** plainly, list **available** packs, and **do not invent**
requirements. Offer to continue only with available packs, or stop.

A pack is runnable only if an obligation card exists under `references/packs/`
and primary sources are listed in `compliance-sources/registry.yaml`.

## Phase 0 — Intake and pack selection

1. Confirm target path.
2. Collect jurisdictions, role, data classes, sector (healthcare/pharma,
   fintech, other).
3. Scan repo for signals; **suggest** only packs that are covered.
4. If user requests Japan (or any gap): deliver the **Not covered** message.
5. User confirms runnable pack list.
6. Optional: write/update `docs/compliance-baseline.md` after the scan.

If no runnable packs remain, stop.

## Phase 1 — Evidence pass

Repo evidence only. Every gap needs a path or explicit “not found.”

## Phase 2 — Obligation map

Use confirmed pack cards only. Primary cites from cards/registry. Prefer live
official URLs; note snapshot age when offline.

## Phase 3 — Report

Follow [assets/report-template.md](assets/report-template.md):

1. Disclaimer
2. **Coverage note** — what was requested vs what was scanned; explicit
   not-covered list for this run
3. Applicability table
4. Obligation themes + evidence
5. Findings by severity
6. Remediation with primary cites
7. Source appendix

## Phase 4 — Baseline (optional)

[assets/baseline-template.md](assets/baseline-template.md) →
`docs/compliance-baseline.md`.

## Boundaries

- Never claim compliant / certified.
- Never invent articles or unresearched country rules.
- Secondary sources = interpretation aids only.
- Hand off deep CI/security scaffolding to other skills where appropriate.
