---
name: project-incubation
description: Sets up a new project (software, or documentation/research) with a best-practice repo structure, common architecture principles, and — for software — a tech-stack-appropriate architecture template, then re-audits an existing repo against that baseline over its lifecycle. Use when starting a new repository, scaffolding a new project, or checking an existing repository's structure, architecture, or dependencies against the conventions it was set up with.
---

# Project Incubation

Guides a project through best-practice setup at inception, and re-audits an
existing repo against the baseline it was set up with, throughout its
lifecycle. Two modes, detected automatically at the start of every
invocation: **Inception** (new/near-empty repo) and **Audit** (existing
repo with a baseline record already in place).

Ask questions one at a time, in plain text. Do not assume any specific
interactive tool exists — this skill must behave identically on any
agentskills.io-compliant client.

## Detecting which mode applies

Check the repo root for `docs/project-incubation-baseline.md`.

- **Exists** → go to [Audit mode](#audit-mode).
- **Missing, repo looks new or near-empty** (no substantial existing code
  or docs beyond scaffold defaults) → go to [Inception mode](#inception-mode).
- **Missing, but the repo has real existing content** → infer the likely
  category and software/non-software path from what's actually there
  (language/framework signals, existing structure), **confirm the
  inference with the user in plain text rather than assuming it's
  right**, then write the baseline record (Inception mode's
  [Phase 7](#phase-7-write-the-baseline-record)) and proceed straight to
  Audit mode using it.

## Inception mode

### Phase 1: Basic project shape

Ask, one at a time:

1. Project name and a one- or two-sentence purpose.
2. **Is this primarily a software project, or documentation/research/
   knowledge-base/dataset?** This is a hard fork, not a formality — a
   non-software project skips category selection and architecture-template
   selection entirely (there's no code architecture to select for) and
   gets a lighter path through the rest of this skill.
3. *(software path only)* Team size — solo, small team, or multiple teams.
   Qualitative only; never convert this to a numeric threshold anywhere
   downstream (no reference doc in this skill uses one, on purpose — the
   research behind them found no defensible number, only warning signs).
4. Expected scale/lifespan — prototype or production, short-lived or
   long-lived.
5. Compliance/regulatory constraints, if any (e.g. PCI, HIPAA, GDPR) — this
   feeds the compliance-signal table in
   [`references/architecture-templates.md`](references/architecture-templates.md).
6. **Does this project include, or will it include, an LLM or agent
   component?** This determines whether the conditional LLM-specific
   principles apply (harness, model-switching, provenance, relevance +
   confidence — see
   [`references/architecture-principles.md`](references/architecture-principles.md)).
   **Re-ask this on every future audit, not just now** — a project's LLM
   status can change after incubation, and treating the inception answer
   as permanent would silently stop applying (or wrongly keep applying)
   an entire principle family.

### Phase 2: Category selection *(software path only — skip on non-software)*

Ask which of these five fits best, offering a one-line description of
each and reading the linked doc once a category is chosen:

- **Data & Analytics Platforms** — data pipelines, BI/analytics, the
  data-engineering side of data science. →
  [`references/stacks/data-analytics-platforms.md`](references/stacks/data-analytics-platforms.md)
- **Business Applications** — SaaS/enterprise CRUD apps, admin/back-office
  tools, anything owning both a backend and a UI end-users interact with
  directly. →
  [`references/stacks/business-applications.md`](references/stacks/business-applications.md)
- **Integration & Event-Driven Systems** — middleware, message brokers,
  ETL/integration platforms, workflow orchestration between systems. →
  [`references/stacks/integration-event-driven-systems.md`](references/stacks/integration-event-driven-systems.md)
- **Backend & API Services** — a service other systems/clients call
  (REST/GraphQL/gRPC), not owning a UI. →
  [`references/stacks/backend-api-services.md`](references/stacks/backend-api-services.md)
- **Agentic & MCP Platforms** — LLM agent backends and MCP servers. →
  [`references/stacks/agentic-mcp-platforms.md`](references/stacks/agentic-mcp-platforms.md)

If nothing fits cleanly, say so plainly, pick the closest match, and
record that caveat in the baseline. `research/taxonomy-roadmap.md` in this
repo tracks categories confirmed for future addition (Infrastructure &
Platform Engineering, ML/AI Model Development, MLOps, Developer Tooling &
Libraries, Frontend/Client Applications) — a project that clearly belongs
to one of those doesn't have a home in this skill's v1 yet.

### Phase 3: Architecture template selection *(software path only)*

Read [`references/architecture-templates.md`](references/architecture-templates.md)
and apply its decision framework using the answers gathered so far (team
size, scale, compliance, deployment constraints). The output is
**compositional**: name one primary pattern plus any genuinely warranted
overlays (e.g. "modular monolith, with an event-driven overlay for the
ingestion subdomain") — don't force a single pure-pattern answer when the
project's own signals point to more than one element. State the
reasoning; it goes into the baseline record and, if the user wants one,
an ADR (see [Phase 8](#phase-8-offer-an-adr-software-path-only)).

### Phase 4: Scaffold the structure

Read [`references/project-structure.md`](references/project-structure.md)
and create: `README.md`, `LICENSE` (ask which license fits, using
[`assets/license-guide.md`](assets/license-guide.md)'s chooser table —
recommend MIT if the user has no preference), `CONTRIBUTING.md`,
`CHANGELOG.md`, `docs/`, `.gitignore`, `.gitattributes`, `.editorconfig`.

*(software path)* Also `src/` (per the language-appropriate layout named
in the reference doc), `scripts/` (strictly for executables — not a
dumping ground for anything else), `tests/`, and a CI stub with the
block-vs-warn gate split the reference doc describes.

*(non-software path)* Skip `src/`/`scripts/`/`tests/` — use the reference
doc's `validation/`-equivalent framing instead if the project has anything
resembling verification work (e.g. link-checking a docs site), and skip
the code-CI stub.

### Phase 5: Apply architecture principles

Read [`references/architecture-principles.md`](references/architecture-principles.md).
Apply every principle tagged as applying to "both paths" or to this
project's actual path (software or non-software). Apply the LLM-specific
section only if Phase 1's question 6 was answered yes.

### Phase 6: Preferred libraries *(software path only)*

Read [`references/preferred-libraries/<category>.md`](references/preferred-libraries/)
matching Phase 2's chosen category. Recommend the doc's named defaults;
note the snapshot date being used — it goes into the baseline record and
is what audit mode's staleness check compares against later.

### Phase 7: Write the baseline record

Copy [`assets/baseline-template.md`](assets/baseline-template.md) to
`docs/project-incubation-baseline.md` and fill in every field from the
answers gathered in Phases 1–6. This file is what every future audit-mode
invocation reads first — get it complete now rather than leaving fields
for "later."

### Phase 8: Offer an ADR *(software path only)*

If Phase 3 produced a real architecture-template decision, offer to write
an Architecture Decision Record for it using
[`assets/adr-template.md`](assets/adr-template.md). Not mandatory — some
projects are too small to want one — but always offer it; don't assume no.

### Phase 9: Wrap up

Summarize what was scaffolded, where the baseline record lives, and that
re-invoking this skill later on this repo will run an audit against it.

## Audit mode

Read `docs/project-incubation-baseline.md` first — every step below
depends on it.

### Step 1: Re-check LLM/agent-component status

Ask the user directly whether the project's LLM/agent-component status has
changed since the last baseline entry (or infer it from repo changes if a
direct question isn't practical this invocation). If it changed in either
direction, update the baseline record's LLM/agent-component field, append
a dated line to its Drift Log, and apply or retire the LLM-conditional
principles section for the rest of this audit accordingly. This is not a
one-time inception question — treat it as re-askable every time.

### Step 2: Structure check

Diff the repo against
[`references/project-structure.md`](references/project-structure.md)'s
expectations: root-level files present, directory structure matches the
project's path (software vs. non-software) and ecosystem, governance
settings where inspectable, large files tracked via Git LFS rather than
committed raw. Report gaps.

### Step 3: Principles check

Check against
[`references/architecture-principles.md`](references/architecture-principles.md),
filtered the same way Phase 5 was during inception (software/non-software,
LLM status from Step 1). Concretely checkable signals: hardcoded
secrets/config literals, environment-variable usage for anything
environment-varying, presence of tests (software path), a stated
scalability/reliability target, observability instrumentation. Report
gaps — don't fabricate a pass on something that wasn't actually checked.

### Step 4: Preferred-libraries staleness check *(software path only)*

For each dependency matching an entry in
[`references/preferred-libraries/<category>.md`](references/preferred-libraries/),
compare its "last reviewed" date against today. **Flag any entry more than
6 months old as worth re-checking** — this threshold is calibrated to real
licensing/ownership churn found while researching this skill's own
reference docs (multiple libraries changed license or ownership within a
single year), not a round-number guess. This is a flag, not an auto-fix:
surface it, don't silently swap a recommendation.

### Step 5: Report and offer fixes

Present every gap from Steps 2–4 as a single checklist. Offer to fix each
one individually, on request. **Never bulk-apply changes** — the user
decides what to act on. Once the audit is done (whether or not fixes were
applied), update `docs/project-incubation-baseline.md`'s "Last audited"
date, and append anything that changed to its Drift Log.

## Reference files

| File | Covers |
|---|---|
| [`references/project-structure.md`](references/project-structure.md) | Root-level files, directory structure, governance, Git LFS |
| [`references/architecture-principles.md`](references/architecture-principles.md) | 11 principle families — universal, software-specific, and LLM-conditional |
| [`references/architecture-templates.md`](references/architecture-templates.md) | 7-pattern catalog, decision framework, ADR recording |
| `references/stacks/<category>.md` | Architecture patterns specific to each of the 5 stack categories |
| `references/preferred-libraries/<category>.md` | Curated, dated library recommendations per category |
| [`assets/baseline-template.md`](assets/baseline-template.md) | The record structure for `docs/project-incubation-baseline.md` |
| [`assets/adr-template.md`](assets/adr-template.md) | Fillable ADR template, mirrors a real production project's shape |
| [`assets/license-guide.md`](assets/license-guide.md) | License chooser table + canonical-text links |

Additional stack categories beyond this skill's current five are tracked
in this repo's `research/taxonomy-roadmap.md` for future versions.
