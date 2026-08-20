<!--
Template for docs/project-incubation-baseline.md — the record project-incubation
writes at the end of inception mode and reads at the start of every audit-mode
invocation. Copy this file to <repo-root>/docs/project-incubation-baseline.md
and fill in every field. Remove this comment block once filled in.

Field-filling notes:
- Dates are ISO 8601 (YYYY-MM-DD).
- "Primary category" and "Architecture template" are software-path-only —
  leave both as "N/A (non-software project)" on the non-software path.
- "LLM/agent component" gets re-asked (or re-inferred) on every audit-mode
  invocation, not just at inception — update this section in place each time,
  and add a dated line to the Drift Log below if the answer changed.
- "Architecture template" supports a compositional answer (a primary pattern
  plus named overlays) — see references/architecture-templates.md. Don't
  force a single pure-pattern answer if the project's own reasoning named
  more than one element.
-->

# Project Incubation Baseline

**Project:** <name>
**Baseline created:** <YYYY-MM-DD>
**Last audited:** <YYYY-MM-DD, or "never" if this is the freshly-created record>
**project-incubation skill version:** <version from .claude-plugin/plugin.json at the time this baseline was written>

## Project shape

- **Path:** software | non-software (documentation / research / knowledge-base / dataset)
- **Purpose:** <one or two sentences, in the project's own words from the inception Q&A>
- **Team size at incubation:** <qualitative — solo / small team / multiple teams — not used for a numeric threshold, see references/project-structure.md>
- **Expected scale / lifespan:** <qualitative — prototype / production, short-lived / long-lived>
- **Compliance / regulatory constraints:** <none, or named regimes (e.g. PCI, HIPAA, GDPR) — feeds architecture-templates.md's compliance-signal table>

## Stack category (software path only)

- **Primary category:** <one of: Data & Analytics Platforms | Business Applications | Integration & Event-Driven Systems | Backend & API Services | Agentic & MCP Platforms | N/A (non-software project)>
- **Reasoning:** <why this category, from the inception Q&A>

## Architecture template (software path only)

- **Primary pattern:** <e.g. modular monolith, hexagonal, layered — see references/architecture-templates.md>
- **Overlays / composed elements:** <e.g. "event-driven overlay for the ingestion subdomain" — leave blank if none>
- **Reasoning:** <the decision-framework signals that led here — team size, scale, compliance, deployment constraints>
- **ADR:** <link to the ADR recording this decision, if one was written — see assets/adr-template.md>

## Common architecture principles applied

- **Principles doc version referenced:** <commit hash or date of references/architecture-principles.md used>
- **LLM/agent component:** yes | no
  - **Basis:** asked directly | inferred from repo contents (state which)
  - **If yes:** the conditional LLM-specific principles section (harness, model-switching, provenance, relevance+confidence) applies — see references/architecture-principles.md.
- **Notable deviations from the standard principle set:** <none, or list with reasoning — e.g. "no SLO stated yet, prototype stage">

## Preferred libraries snapshot (software path only)

- **Category reference used:** references/preferred-libraries/<category>.md
- **Snapshot date at incubation:** <date>
- **Key library choices:** <list the load-bearing picks actually made, not the full reference doc's contents — e.g. "FastAPI, Pydantic v2, Envoy Gateway">

## License

- **Chosen license:** <e.g. MIT>
- **Reasoning:** <from assets/license-guide.md's chooser table>

## Drift log

<!-- Append one line per audit-mode invocation where something changed since
     the last baseline. Leave empty until the first audit finds drift. -->

- <YYYY-MM-DD>: <what changed, e.g. "LLM/agent component flipped from no to yes — project added an AI-assisted summarization feature">
