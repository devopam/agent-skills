# Coverage matrix (authoritative for the skill)

**Last updated:** 2026-09-15  
**Rule:** A jurisdiction, national nuance, or domain is **in scope only if** a
**runnable pack** exists (obligation card under `references/packs/` **and**
primary source in `compliance-sources/registry.yaml`). Everything else is
**Not covered** — state that clearly, do **not** invent obligations, and offer
only runnable packs (or stop).

There is **no special-case keyword list**. Examples such as Japan, Russia,
China, or Korea are **illustrative** of economies not yet packed — the same
rule applies to any missing country or regime.

## Product domains

| Domain id | Status |
|-----------|--------|
| `domain-healthcare-pharma` | Runnable (HIPAA gate + regional privacy) |
| `domain-fintech` | Runnable (PCI orientation + regional privacy) |
| Other verticals | **Not covered** until researched |

## Data privacy — current runnable wave

| Region | Packs |
|--------|--------|
| Europe (union) | `privacy-eu` |
| Europe (national overlays) | `privacy-eu-de`, `privacy-eu-fr`, `privacy-eu-it` |
| India | `privacy-in` |
| Americas | `privacy-us` (California first), `privacy-ca`, `privacy-br` |
| Middle East | `privacy-ae`, `privacy-sa` |

See [references/packs/README.md](../../skills/regulatory-compliance-applicability-scan/references/packs/README.md).

## Expansion — major economies (logical completion)

Planned **after** hardening the current wave (evals, refresh dry-run, release).
Each needs primary official sources + cards + evals before runnable:

| Target | Notes |
|--------|--------|
| **China** | PIPL and related rules — official Chinese sources; no blog-only |
| **Korea** | PIPA and related — official KR sources |
| **Russia** | Personal data law (e.g. 152-FZ lineage) — official RU sources |
| **Japan** | APPI and related — official JP sources |
| Other major markets | Same pattern (SG, AU, ZA, …) as prioritized |
| Further EU/EEA overlays | ES, NL, PL, SE, … |
| Further US states | Beyond California |
| UAE free zones | DIFC/ADGM separate from federal PDPL |

## Agent behaviour when out of coverage

> **Not covered:** There is no researched runnable pack for **[jurisdiction /
> domain X]** yet. I will not invent regulatory requirements for that scope.
> Runnable packs available: **[list from packs README]**. Proceed with one or
> more of those, or stop?

Do not maintain a hard-coded “block Japan only” list — **derive** from the
runnable inventory.
