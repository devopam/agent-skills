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
2. **Is this a single project/service, or a monorepo containing multiple
   independently-deployable packages or apps?** This is a structural fork
   distinct from the software/non-software one below, and it changes how
   Phase 2 onward applies. A monorepo here means genuinely separate
   deployables sharing one repo — e.g. `apps/web`, `apps/api`, `infra/` —
   not a single app with an internal `packages/` split that all builds
   into one deployable. When in doubt, ask "do these get deployed
   separately, on separate schedules, by potentially different parts of
   the team?" — if yes, it's a monorepo for this skill's purposes. See
   [Monorepos: category selection per
   package](#monorepos-category-selection-per-package) below for how this
   changes Phase 2 through Phase 7 — every phase from here still applies,
   just once per significant package instead of once for the whole repo.
3. **Is this primarily a software project, or documentation/research/
   knowledge-base/dataset?** This is a hard fork, not a formality — a
   non-software project skips category selection and architecture-template
   selection entirely (there's no code architecture to select for) and
   gets a lighter path through the rest of this skill. For a monorepo,
   ask this once per package if packages genuinely differ (rare — most
   monorepos are all-software), otherwise once for the whole repo.
4. *(software path only)* Team size — solo, small team, or multiple teams.
   Qualitative only; never convert this to a numeric threshold anywhere
   downstream (no reference doc in this skill uses one, on purpose — the
   research behind them found no defensible number, only warning signs).
5. Expected scale/lifespan — prototype or production, short-lived or
   long-lived.
6. Compliance/regulatory constraints, if any (e.g. PCI, HIPAA, GDPR) — this
   feeds the compliance-signal table in
   [`references/architecture-templates.md`](references/architecture-templates.md).
7. **Does this project include, or will it include, an LLM or agent
   component?** This determines whether the conditional LLM-specific
   principles apply (harness, model-switching, provenance, relevance +
   confidence — see
   [`references/architecture-principles.md`](references/architecture-principles.md)).
   **Re-ask this on every future audit, not just now** — a project's LLM
   status can change after incubation, and treating the inception answer
   as permanent would silently stop applying (or wrongly keep applying)
   an entire principle family. For a monorepo, ask once per package if it
   genuinely varies (a monorepo with one package calling an LLM and
   another that's plain CRUD is common), otherwise once for the whole
   repo.

### Phase 2: Category selection *(software path only — skip on non-software)*

**If Phase 1 established this is a monorepo, skip to [Monorepos: category
selection per package](#monorepos-category-selection-per-package) below
instead of following this section as written** — the single-project flow
below assumes one deployable, which a monorepo's whole point is to not
be.

Ask which of these ten fits best as the **primary** category, offering a
one-line description of each and reading the linked doc once a category
is chosen. Most projects have exactly one category and stop here.

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
- **Developer Tooling & Libraries** — SDKs, CLI tools, and publishable
  packages/libraries consumed by other developers, not an end-user-facing
  application. →
  [`references/stacks/developer-tooling-libraries.md`](references/stacks/developer-tooling-libraries.md)
- **Infrastructure & Platform Engineering** — the deployment target itself
  is what's being built: IaC provisioning, Kubernetes/container
  orchestration, CI/CD at the platform layer, internal developer
  platforms. →
  [`references/stacks/infrastructure-platform-engineering.md`](references/stacks/infrastructure-platform-engineering.md)
- **ML / AI Model Development** — training, fine-tuning, experiment
  tracking, model evaluation: the model-*building* side, producing a
  trained artifact — not serving one (Agentic & MCP Platforms) or
  operating it in production (MLOps). →
  [`references/stacks/ml-model-development.md`](references/stacks/ml-model-development.md)
- **MLOps / ML Platform Engineering** — the operational discipline once a
  trained model exists: production model-registry promotion, feature
  stores, model serving, drift monitoring, retraining triggers, and
  model-quality-driven canary rollouts. →
  [`references/stacks/mlops-platform-engineering.md`](references/stacks/mlops-platform-engineering.md)
- **Frontend / Client Applications** — a pure client (web SPA, mobile, or
  desktop app) with no owned backend of its own, calling only a
  third-party API or BaaS. The test is backend ownership, not tech-stack
  shape: a frontend whose own team also owns and deploys its backend is
  Business Applications instead, even if the frontend code looks
  identical. →
  [`references/stacks/frontend-client-applications.md`](references/stacks/frontend-client-applications.md)

If nothing fits cleanly, say so plainly, pick the closest match as
primary, and record that caveat in the baseline. `research/taxonomy-
roadmap.md`'s original backlog is now fully shipped as of 2026-08-31 —
this skill covers all 10 categories that roadmap named.

**After the primary category is set, ask one more question: does any
genuinely distinct subsystem of this project warrant its own secondary
category?** This is not "does another category also sound relevant" —
most projects touch concepts from several categories in passing without
needing separate coverage. The bar is a **real, separately-architected
component** with its own meaningful surface: a SaaS dashboard (Business
Applications, primary) that also ships an MCP server for third-party
agents to call (Agentic & MCP Platforms, secondary) is a real case: the
MCP server has its own tool-schema/protocol concerns the dashboard's own
category doesn't cover. A project that merely *uses* an LLM API inside an
otherwise-ordinary backend service does not need a secondary category —
that's a dependency choice, not a distinct architected subsystem, and
[Backend & API Services](references/stacks/backend-api-services.md)
alone already covers it. When genuinely warranted, name each secondary
category and which subsystem it applies to; there is no fixed limit, but
in practice more than two total categories is rare and worth double-
checking against the "real subsystem" bar above before accepting a third.
Read each secondary category's own stack doc the same way the primary
one was read. This replaces the old single-category-only design — a
project that doesn't fit cleanly into one category no longer just gets a
caveat noted against a forced single choice; it gets the actual
combination of categories its architecture calls for.

### Monorepos: category selection per package

A monorepo (per Phase 1's own structural fork) commonly has **no single
primary category at all** — this is the case the user flagged as common
in practice, distinct from the single-project-with-an-embedded-subsystem
case above. `apps/web`, `apps/api`, and `infra/` in one repo aren't a
primary category with two minor secondary subsystems; they're three
**coequal** packages, each with its own real architecture, each
deserving its own full category treatment. Forcing one of them to be
"primary" and the others to "secondary" would misrepresent the repo's
actual shape and bias Phase 3's architecture-template decision toward
whichever package happened to get called primary.

**The mechanic**: identify every significant, independently-deployable
package in the repo (skip trivial ones — a `scripts/` folder of one-off
maintenance scripts isn't a package). For **each** package, run Phase 2's
own category-selection question independently — including, if that one
package itself has a genuinely distinct embedded subsystem, the
primary-plus-secondary mechanic above applies *within* that package's own
entry. The two mechanisms compose: a monorepo package map can have one
entry that's itself "Business Applications (primary) + Agentic & MCP
Platforms (secondary)" if that specific package earns it. Record the
result as a **package category map** — package path → category
(+ secondary categories if any) — rather than a single primary/secondary
pair. There is no repo-wide "primary" to name unless one package is
genuinely the dominant, most-actively-developed one and the others are
minor satellites (a real, occasional case — state it if true, don't
manufacture one when the packages are truly coequal).

**Everything downstream applies per package, not once for the whole
repo**: Phase 3's architecture-template decision runs once per package
(a monorepo very often has genuinely different topologies per package —
`infra/` has no request/response topology to choose at all, per
Infrastructure & Platform Engineering's own framing); Phase 6 reads the
preferred-libraries doc for each package's own category; Phase 7's
baseline record captures the full package map, not a single category
pair — see `assets/baseline-template.md`'s own monorepo section for the
exact fields. Phase 4 (scaffolding) and Phase 5 (architecture principles)
mostly still apply once at the repo root (governance files, root
`.gitignore`, and so on) with per-package specifics layered in per
package's own subdirectory, following whatever the repo's own package
manager/build-tool convention for a monorepo already establishes (a
`turbo.json`/`pnpm-workspace.yaml`/`nx.json`-style root config, if one
exists, is itself real signal for how this repo already expects
per-package structure to work — don't fight it).

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

*(if a secondary category was named in Phase 2)* The primary category
still drives this phase's own pattern decision — there is one overall
deployment topology, not one per category. A secondary category's own
stack doc may name architectural concerns specific to that subsystem
(e.g. the Agentic & MCP Platforms doc's tool-schema/protocol guidance for
an embedded MCP server) — apply those as subsystem-level notes alongside
the primary pattern, not as a second, competing topology decision.

*(monorepo path)* Run this phase once per package from the package
category map, not once for the whole repo — each package gets its own
primary pattern (plus overlays, plus a secondary-category's own notes if
that package has one). Don't force one shared topology answer across
packages that don't share one; a monorepo containing a modular-monolith
API and an event-driven ingestion worker as separate packages should
record two different primary patterns, not one compromise answer.

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
section only if Phase 1's LLM/agent-component question was answered yes.

### Phase 6: Preferred libraries *(software path only)*

Read [`references/preferred-libraries/<category>.md`](references/preferred-libraries/)
for the primary category **and every secondary category named in Phase
2**. Recommend each doc's named defaults for the subsystem it applies to;
if two categories' docs both weigh in on the same library-selection
question (rare, since each doc scopes itself against its named siblings,
but possible), say so explicitly and reconcile rather than presenting two
silently conflicting recommendations. Note every snapshot date used —
they all go into the baseline record and are what audit mode's staleness
check compares against later, one per category.

Also read
[`references/cross-cutting-utility-libraries.md`](references/cross-cutting-utility-libraries.md)
regardless of category — it covers application-level utility concerns
(cloud-agnostic file I/O, config/secrets loading, retry/resilience,
structured logging, and similar) that recur across every category rather
than belonging to any one of them, and is additive to, not a replacement
for, the category-specific doc(s) above.

*(monorepo path)* Read the preferred-libraries doc for each package's own
category (plus any secondary category that package has). The
cross-cutting utility-libraries doc still applies repo-wide, read once —
its own concerns (file I/O, config/secrets, retry, logging) recur inside
every package, not just one, so there's no reason to re-derive it per
package.

### Phase 7: Write the baseline record

Copy [`assets/baseline-template.md`](assets/baseline-template.md) to
`docs/project-incubation-baseline.md` and fill in every field from the
answers gathered in Phases 1–6 — including the package category map
instead of a single primary/secondary pair if Phase 1 established this is
a monorepo. This file is what every future audit-mode invocation reads
first — get it complete now rather than leaving fields for "later."

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
depends on it. **If the baseline records a package category map (a
monorepo) rather than a single primary/secondary pair, every step below
runs once per package**, scoped to that package's own subdirectory — a
structure/principles/library gap in `apps/api` doesn't mean `apps/web`
has the same gap, and reporting it as if it did would be misleading.

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

For each dependency matching an entry in the baseline's recorded
preferred-libraries doc(s) — the primary category's, every secondary
category's (if any, or every package's own category and secondaries for
a monorepo), and
[`references/cross-cutting-utility-libraries.md`](references/cross-cutting-utility-libraries.md) —
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
| `references/stacks/<category>.md` | Architecture patterns specific to each of the 10 stack categories |
| `references/preferred-libraries/<category>.md` | Curated, dated library recommendations per category |
| [`references/cross-cutting-utility-libraries.md`](references/cross-cutting-utility-libraries.md) | Application-level utility libraries (cloud-agnostic I/O, config/secrets, retry/resilience, and similar) that recur across every category, read at Phase 6 in addition to the category-specific doc(s) |
| [`assets/baseline-template.md`](assets/baseline-template.md) | The record structure for `docs/project-incubation-baseline.md` |
| [`assets/adr-template.md`](assets/adr-template.md) | Fillable ADR template, mirrors a real production project's shape |
| [`assets/license-guide.md`](assets/license-guide.md) | License chooser table + canonical-text links |

`research/taxonomy-roadmap.md`'s original 5-category backlog is now fully
shipped (2026-08-31); any category beyond this skill's current ten would
be a new roadmap decision, not a continuation of the existing one.
