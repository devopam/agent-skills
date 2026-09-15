# Coverage matrix (authoritative for the skill)

**Last updated:** 2026-09-15  
**Rule:** If the user asks for a **region or domain not listed as available
below**, the skill must **state clearly that it is not covered yet**, must
**not** invent obligations for that gap, and may only offer to run packs that
*are* available (or stop).

## Product domains (vertical overlays)

These are the **first two** domain tracks. They layer on top of regional
privacy packs when the project is in that sector.

| Domain id | Status | Intent |
|-----------|--------|--------|
| `domain-healthcare-pharma` | **Planned (priority 1)** | Health/pharma data, clinical/consumer health apps — region-specific primary sources (e.g. HIPAA where US PHI applies; EU health-data overlays only with primary cites) |
| `domain-fintech` | **Planned (priority 1)** | Payments, lending, wallets, open banking-style processing — privacy + sector rules with primary sources (e.g. PCI DSS as security standard where card data applies; regional financial privacy/conduct only when researched) |
| Other verticals (gov, edtech, …) | **Not covered** | Say so explicitly |

Until a domain pack has obligation cards + registry rows, treat it as
**not covered** even if listed as planned.

## Data privacy governance — regions

| Region | Status | Pack ids (target) | Notes |
|--------|--------|-------------------|--------|
| **Europe** | **In progress** | `privacy-eu` (GDPR); optional later `privacy-uk` | EUR-Lex primary for GDPR |
| **India** | **Planned** | `privacy-in` (DPDP Act 2023 + rules/notifications) | Staggered commencement — cards must track in-force sections |
| **Americas** | **Planned** | Split packs, not one blob — e.g. `privacy-us` (federal sectoral + state privacy such as CCPA/CPRA where in scope), `privacy-ca` (PIPEDA), `privacy-br` (LGPD) as researched | “Americas” in intake maps to **confirmed country packs** only |
| **Middle East** | **Planned** | Country packs as researched — e.g. UAE PDPL, KSA PDPL when primary texts + cards exist | No generic “Middle East GDPR-equivalent” handwave |
| **Japan, Korea, Australia, Africa, …** | **Not covered** | — | Explicit decline; do not improvise |
| **Global / “all countries”** | **Not covered as a single pack** | — | Require the user to pick from available regions |

## Cross-cut (not a region)

| Id | Status | Notes |
|----|--------|--------|
| Security baseline supporting privacy | Optional later | Points at control themes; does not replace privacy packs |

## Agent behaviour when out of coverage

Use language equivalent to:

> **Not covered:** This skill does not yet include a researched pack for
> **[Japan / domain X / …]**. I will not invent regulatory requirements for
> that scope. Available packs today: **[list from coverage matrix / pack
> folder]**. Do you want to proceed with one of those, or stop?

Never fill the gap with blog-level “typical requirements for Japan.”

## Expansion process

1. Research primary official source → registry row  
2. Obligation cards under `references/packs/`  
3. Evals (including “refuse uncovered Japan”)  
4. Update **this matrix** and `SKILL.md` coverage section in the same change  
