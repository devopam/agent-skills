<!--
Template for docs/project-incubation-baseline.md — the record project-incubation
writes at the end of inception mode and reads at the start of every audit-mode
invocation. Copy this file to <repo-root>/docs/project-incubation-baseline.md
and fill in every field. Remove this comment block once filled in.

Field-filling notes:
- Dates are ISO 8601 (YYYY-MM-DD).
- "Repo shape" (single project vs. monorepo) determines which of the two
  mutually exclusive sections below you fill in: "Stack category +
  Architecture template + Preferred libraries snapshot" for a single
  project, or "Package category map" for a monorepo — never both. See
  SKILL.md's own "Monorepos: category selection per package" section for
  the bar distinguishing a real monorepo (coequal, independently-
  deployable packages) from a single app with an internal `packages/`
  split that all builds into one deployable (still a single project).
- "Primary category" and "Architecture template" are software-path-only —
  leave both as "N/A (non-software project)" on the non-software path.
- "Secondary categories" is almost always empty — leave it blank unless
  the project genuinely has a distinct, separately-architected subsystem
  that warrants its own category coverage (see SKILL.md Phase 2's own
  bar for this). Most projects have one category and nothing here. This
  same mechanic also applies per-row inside a monorepo's own package
  category map — one package can have its own secondary category.
- "LLM/agent component" gets re-asked (or re-inferred) on every audit-mode
  invocation, not just at inception — update this section in place each time,
  and add a dated line to the Drift Log below if the answer changed. For a
  monorepo, note per-package if the answer genuinely varies.
- "Architecture template" supports a compositional answer (a primary pattern
  plus named overlays) — see references/architecture-templates.md. Don't
  force a single pure-pattern answer if the project's own reasoning named
  more than one element. For a monorepo, each package gets its own
  compositional answer — don't force one shared topology across packages
  that don't share one.
-->

# Project Incubation Baseline

**Project:** <name>
**Baseline created:** <YYYY-MM-DD>
**Last audited:** <YYYY-MM-DD, or "never" if this is the freshly-created record>
**project-incubation skill version:** <version from .claude-plugin/plugin.json at the time this baseline was written>

## Project shape

- **Path:** software | non-software (documentation / research / knowledge-base / dataset)
- **Repo shape:** single project | monorepo — see the field-filling note above for the bar
- **Purpose:** <one or two sentences, in the project's own words from the inception Q&A>
- **Team size at incubation:** <qualitative — solo / small team / multiple teams — not used for a numeric threshold, see references/project-structure.md>
- **Expected scale / lifespan:** <qualitative — prototype / production, short-lived / long-lived>
- **Compliance / regulatory constraints:** <none, or named regimes (e.g. PCI, HIPAA, GDPR) — feeds architecture-templates.md's compliance-signal table>

## Stack category *(software path, single-project repos only — skip if "Repo shape" above is "monorepo," use Package category map instead)*

- **Primary category:** <one of: Data & Analytics Platforms | Business Applications | Integration & Event-Driven Systems | Backend & API Services | Agentic & MCP Platforms | Developer Tooling & Libraries | Infrastructure & Platform Engineering | ML / AI Model Development | MLOps / ML Platform Engineering | Frontend / Client Applications | N/A (non-software project)>
- **Reasoning:** <why this category, from the inception Q&A>
- **Secondary categories:** <none, or one entry per genuinely distinct subsystem — "<category name> (<which subsystem this applies to>)". Leave "none" unless a real, separately-architected component justifies it; see SKILL.md Phase 2>
- **Secondary-category reasoning:** <why each named secondary category is a real subsystem, not just a passing dependency on a concept from that category — leave blank if no secondary categories>

## Architecture template *(software path, single-project repos only — skip if a monorepo, use Package category map instead)*

- **Primary pattern:** <e.g. modular monolith, hexagonal, layered — see references/architecture-templates.md>
- **Overlays / composed elements:** <e.g. "event-driven overlay for the ingestion subdomain" — leave blank if none>
- **Reasoning:** <the decision-framework signals that led here — team size, scale, compliance, deployment constraints>
- **ADR:** <link to the ADR recording this decision, if one was written — see assets/adr-template.md>

## Package category map *(software path, monorepo repos only — skip entirely for a single-project repo; use Stack category + Architecture template + Preferred libraries snapshot above instead)*

<!-- One row per significant, independently-deployable package. Skip
     trivial directories (a one-off scripts/ folder isn't a package).
     Only name a repo-wide "Primary package" if one package is genuinely
     the dominant one and the rest are minor satellites — leave it "N/A
     (coequal packages)" when the packages are truly coequal, which is
     the common case per SKILL.md's own monorepo framing. -->

- **Primary package:** <package path, or "N/A (coequal packages)">

| Package path | Category | Secondary categories | Architecture pattern (+ overlays) | Preferred-libraries snapshot date | Key library choices |
|---|---|---|---|---|---|
| <e.g. `apps/web`> | <category> | <none, or per SKILL.md Phase 2's bar> | <primary pattern + overlays> | <date> | <load-bearing picks> |

- **Cross-cutting reference used (repo-wide, not per package):** references/cross-cutting-utility-libraries.md
- **Snapshot date at incubation:** <date>
- **Key library choices:** <load-bearing cross-cutting picks actually made, across the whole repo — e.g. "smart_open for cloud-agnostic file I/O, pydantic-settings for config/secrets">

## Common architecture principles applied

- **Principles doc version referenced:** <commit hash or date of references/architecture-principles.md used>
- **LLM/agent component:** yes | no
  - **Basis:** asked directly | inferred from repo contents (state which)
  - **If yes:** the conditional LLM-specific principles section (harness, model-switching, provenance, relevance+confidence) applies — see references/architecture-principles.md.
- **Notable deviations from the standard principle set:** <none, or list with reasoning — e.g. "no SLO stated yet, prototype stage">

## Preferred libraries snapshot *(software path, single-project repos only — skip if a monorepo, this is folded into the Package category map's own table + its cross-cutting block instead)*

<!-- One block per category actually used (primary, plus each secondary
     if any), plus always the cross-cutting doc. Copy the block for each. -->

- **Category reference used:** references/preferred-libraries/<category>.md
- **Snapshot date at incubation:** <date>
- **Key library choices:** <list the load-bearing picks actually made, not the full reference doc's contents — e.g. "FastAPI, Pydantic v2, Envoy Gateway">

- **Cross-cutting reference used:** references/cross-cutting-utility-libraries.md
- **Snapshot date at incubation:** <date>
- **Key library choices:** <load-bearing cross-cutting picks actually made — e.g. "smart_open for cloud-agnostic file I/O, pydantic-settings for config/secrets">

## License

- **Chosen license:** <e.g. MIT>
- **Reasoning:** <from assets/license-guide.md's chooser table>

## Drift log

<!-- Append one line per audit-mode invocation where something changed since
     the last baseline. Leave empty until the first audit finds drift. -->

- <YYYY-MM-DD>: <what changed, e.g. "LLM/agent component flipped from no to yes — project added an AI-assisted summarization feature">
