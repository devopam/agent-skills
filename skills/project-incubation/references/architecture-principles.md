# Common Architecture Principles

This is the principles reference `project-incubation` applies when a project
is set up (inception) and re-checked against later (audit). It does not
recommend a tech stack or a specific architecture pattern — those live in
`stacks/<category>.md` and `architecture-templates.md`. This file answers a
narrower question: regardless of what a project builds, what structural
properties should its design have, and why.

Two filters decide which parts of this document apply to a given project:

1. **Software or non-software.** A project can be a software/code
   repository, or it can be documentation, research, a knowledge base, or a
   dataset with no code driving it. This is asked as a first inception
   question, before stack-category selection. Most principle families here
   apply to both; five are software-specific and must be marked
   **explicitly skipped** for a non-software project rather than silently
   dropped — a documentation repo should never later get flagged in an
   audit for "missing tests."
2. **Does the project have an LLM or agent component.** Asked directly
   ("does this project include an LLM or agent component?") at inception,
   and asked again on **every audit-mode invocation**, not answered once
   and forgotten. If the answer has changed since the last baseline record
   — either direction — the audit flags the drift, updates the baseline
   record, and applies or retires the LLM-specific principles section
   accordingly. This is independent of the software/non-software fork: a
   non-software research pipeline that calls an LLM to synthesize findings
   still owes itself a harness, provenance, and the rest of Part III.

Every section below opens with an **Applies to:** line stating where it
lands on both filters. Read that line before the section, not after —
it tells you whether to keep reading or skip to the next one.

---

## Table of Contents

- [How to Read the Applicability Tags](#how-to-read-the-applicability-tags)
- [Applicability Quick-Reference Table](#applicability-quick-reference-table)
- [Part I — Foundational Principles (Software and Non-Software)](#part-i--foundational-principles-software-and-non-software)
  - [1. Interoperability & Pluggability](#1-interoperability--pluggability)
  - [2. Zero Hardcoding / Config-Driven (Twelve-Factor Config)](#2-zero-hardcoding--config-driven-twelve-factor-config)
  - [3. Security-by-Design](#3-security-by-design)
  - [4. Maintainability & Simplicity (KISS, YAGNI, DRY)](#4-maintainability--simplicity-kiss-yagni-dry)
- [Part II — Software-Specific Engineering Practices](#part-ii--software-specific-engineering-practices)
  - [5. Scalability & Reliability](#5-scalability--reliability)
  - [6. Observability](#6-observability)
  - [7. Testability](#7-testability)
  - [8. Test-Driven Development (TDD)](#8-test-driven-development-tdd)
  - [9. Spec-Driven Development (SDD)](#9-spec-driven-development-sdd)
- [Part III — LLM/Agent-Conditional Principles](#part-iii--llmagent-conditional-principles)
  - [10. Determinism-First](#10-determinism-first)
  - [11. LLM/Agent-Specific Principles](#11-llmagent-specific-principles)
    - [11.1 Needs a Harness](#111-needs-a-harness)
    - [11.2 Model-Switching Capability](#112-model-switching-capability)
    - [11.3 Provenance Is Mandatory](#113-provenance-is-mandatory)
    - [11.4 Relevance Score Alongside Provenance](#114-relevance-score-alongside-provenance)
- [What This Document Does Not Cover](#what-this-document-does-not-cover)
- [Sources](#sources)

---

## How to Read the Applicability Tags

Each section's **Applies to:** line combines the two filters above into one
of these shapes:

- **"every project"** — universal regardless of either filter.
- **"software projects"** — skip for non-software; mark it explicitly
  skipped in the baseline record, don't omit it silently.
- **"projects with an LLM/agent component"** — independent of the
  software/non-software fork; applies to a code repository or a
  documentation/research project alike, whenever the answer to the LLM
  question is yes. Re-evaluated every audit.

Within a section, some sub-claims are themselves universal and others are
conditional on project scale or maturity — those distinctions are called
out inline (for example, scalability's *target* is universal but its
*mechanism* is scale-conditional).

---

## Applicability Quick-Reference Table

| # | Principle family | Software projects | Non-software projects | LLM-conditional |
|---|---|---|---|---|
| 1 | Interoperability & Pluggability | Applies | Applies (thinner: decoupled tooling/seams, not plugin/DIP code patterns) | No |
| 2 | Zero Hardcoding / Config-Driven | Applies | Applies in spirit (no hardcoded credentials in scripts/tooling folders) | No |
| 3 | Security-by-Design | Applies | Applies (access control, data handling, credential hygiene) | No |
| 4 | Maintainability & Simplicity | Applies | Applies | No |
| 5 | Scalability & Reliability | Applies | Explicitly skipped | No |
| 6 | Observability | Applies | Explicitly skipped | No |
| 7 | Testability | Applies | Explicitly skipped | No |
| 8 | TDD | Applies | Explicitly skipped | No |
| 9 | SDD | Applies (conditionally, once AI agents build the code) | Explicitly skipped | No |
| 10 | Determinism-First | Applies **if** LLM component present | Applies **if** LLM component present | Yes — gated entirely on the LLM question |
| 11 | LLM/Agent-Specific (harness, model-switching, provenance, relevance) | Applies **if** LLM component present | Applies **if** LLM component present | Yes — gated entirely on the LLM question |

Rows 5–9 are marked "explicitly skipped" rather than blank because the
audit record must show the question was asked and answered "not
applicable," not that it was never asked.

---

## Part I — Foundational Principles (Software and Non-Software)

### 1. Interoperability & Pluggability

**Applies to: every project** (in code, this means plugin architecture and
interface boundaries; in a non-software project it means decoupled seams
between tooling — e.g. the script that ingests source documents is not
entangled with the script that renders them — rather than a formal
plugin/DIP pattern, which doesn't have a non-code analogue).

**Claim:** a system's core should depend on abstractions, not on the
concrete things that plug into it. New capabilities should be addable
without editing the core.

- **Plugin architecture pattern**: a core system manages orchestration and
  exposes stable extension points; plugins implement use-case-specific
  behavior and are agnostic of each other and of the core's internals.
  Three properties are load-bearing: loose coupling (the core knows only
  the plugin's *interface*, never its implementation), single
  responsibility per plugin, and a well-defined, versioned API at the
  extension point.
- **Dependency Inversion Principle (the "D" in SOLID)**: high-level
  modules must not depend on low-level modules — both depend on
  abstractions. This is *why* plugin architectures are swappable: because
  the core is written against an interface, a new implementation can be
  substituted without touching the core or triggering regressions
  elsewhere in the system.
- **What this is not**: it is not "use microservices" and it is not
  "expose everything as a REST API." Interoperability is about seams —
  clean interface boundaries — existing at all. They can be in-process (an
  injected interface, a strategy object) or over-the-wire (an HTTP/gRPC
  API); the right seam location is a project-specific decision driven by
  where independent evolution is actually needed, not a mandate to network
  every component.
- **Checklist for inception and audit**: Does the project define its
  extension points explicitly (interfaces/contracts) before the first
  concrete plugin is implemented? Can a second implementation of any given
  interface be added without modifying that interface's consumers? Is
  there anywhere in the codebase where a "core" module reaches into a
  specific plugin's internals rather than going through the declared
  interface — if so, that's a violation to flag, not a style nitpick.

### 2. Zero Hardcoding / Config-Driven (Twelve-Factor Config)

**Applies to: every project** (a documentation/research repo still has
credentials, API keys for fetching sources, or per-environment paths in its
tooling scripts, even if it has no "deploys" in the traditional sense).

**Claim:** anything that varies between environments (dev/staging/prod) or
deployments must live outside the code — never as a literal in source.

- **Twelve-Factor App, Factor III (Config)**: "config varies substantially
  across deploys, code does not." Config means credentials, hostnames,
  ports, feature flags, per-deploy resource handles — anything that would
  need to differ if the *same* code (or the same script) ran somewhere
  else.
- **Why environment variables specifically**: they are language- and
  OS-agnostic (not tied to a config-file format a particular framework
  invented), trivially changed without a code change or redeploy, and
  structurally resistant to being accidentally committed to version
  control the way a checked-in config file is.
- **The litmus test** (12factor.net's own phrasing): "the codebase could
  be made open source at any moment, without compromising any
  credentials." If publishing the repo would leak a secret, config/code
  separation has already failed. This test applies just as cleanly to a
  private research repo as to a production service.
- **Modern refinement**: don't just move hardcoded values into one giant
  `config.py` / `settings.js` and call it done — twelve-factor explicitly
  warns against grouping variables into named "environments," because that
  reintroduces coupling (a new deploy target needs its own named
  environment block, hand-maintained). Treat each variable as
  independently settable.
- **What this is not**: it is not an argument against constants that are
  genuinely invariant — a mathematical constant, an internal enum value, a
  fixed schema version number. "Zero hardcoding" targets things that vary
  by environment or deployment, not every literal in the codebase.
- **Non-software application**: no hardcoded API keys or absolute
  filesystem paths in a dataset-ingestion script; a `.env.example` or
  equivalent documenting what a fresh contributor needs to set, even if
  the "deploy" in question is just "run this script on another machine."

### 3. Security-by-Design

**Applies to: every project** — as universally applicable as reliability
or config hygiene, and a standard member of any architecture-principles
treatment.

**Claim:** security is a design-time architectural concern, not a
pre-launch checklist or a post-incident patch.

- **OWASP Secure-by-Design Framework** (draft v0.5.0, August 2025):
  structured, design-time guidance for embedding security into
  architecture *before* code is written. It's organized around an
  operational process, principles and recommendations spanning six domains
  (core principles, architecture, data management, resilience, access
  control, monitoring), a condensed review checklist (roughly 40
  actionable items), a catalog of reference architectures, and explicit
  integration points with ASVS and formal threat modeling.
- **Core design principles** (OWASP): minimize attack surface, secure
  defaults, least privilege, defense in depth, fail securely, don't trust
  other services blindly, separation of duties, no security through
  obscurity, keep security mechanisms simple, and fix issues at the root
  cause rather than patching symptoms downstream.
- **2025–2026 framing shift**: OWASP's own Top 10 revision calls out
  "insecure design" as a category distinct from insecure *implementation*.
  The push is to move threat modeling and secure design patterns earlier
  than "shift-left" (which was already about coding-time) — into
  requirements-writing and architecture time, before the first line of
  code exists.
- **Practical shape at incubation stage**: least-privilege access on any
  credential or service account created during setup; secrets never
  entering version control (ties directly to the config-driven principle
  above); an explicit note of what the project trusts (which external
  services, which upstream data) and what it doesn't; a fail-secure
  default (an auth check that errs closed, not open, if it can't
  determine an answer).
- **What this is not**: it is not a full STRIDE/PASTA threat-modeling
  walkthrough — that's a deeper, separate exercise this document doesn't
  attempt to replace. It's the minimum architectural posture: don't design
  yourself into a position where security has to be retrofitted.
- **Non-software application**: access control on a shared research
  document or dataset, no credentials embedded in a shared notebook, and a
  data-handling note if the dataset contains anything sensitive.

### 4. Maintainability & Simplicity (KISS, YAGNI, DRY)

**Applies to: every project.**

**Claim:** default to the simplest design that satisfies current, known
requirements; add complexity only when a real, present need demands it.

- **KISS** ("Keep It Simple"): unnecessary complexity is a direct cost to
  debuggability and extensibility, not just an aesthetic preference. This
  is the same claim SRE literature makes about complexity being "the
  enemy of reliability" (see Scalability & Reliability below) — which is
  why this family sits conceptually next to that one even though it
  applies more broadly.
- **YAGNI** ("You Aren't Gonna Need It"): don't build for imagined future
  requirements. Speculative generality is itself a maintainability
  liability — more surface area, more that has to stay consistent, more
  that can silently rot unexercised because nothing actually uses it yet.
- **DRY** (avoid unnecessary duplication): the third commonly paired
  principle, lower-stakes than the other two for an incubation-stage
  baseline but included for completeness — duplicated logic is duplicated
  places to introduce (and forget to fix) a bug.
- **The caution that keeps this from becoming an excuse**: these
  principles "alone cannot guarantee production robustness — they only
  deliver value when integrated into a modular architecture, automated
  testing, clear technical governance, and shared engineering culture."
  KISS/YAGNI/DRY are a complement to the other principles in this
  document, not a substitute for them. "We kept it simple" is not a
  defense for skipping tests, config hygiene, or interface boundaries.
- **Non-software application**: a documentation repo's structure should
  resist growing speculative categories nobody has content for yet, and
  should avoid three near-duplicate explanations of the same concept
  living in three different files.

---

## Part II — Software-Specific Engineering Practices

The five principle families in this part apply to software/code projects.
For a non-software project, mark each of these **explicitly skipped** in
the baseline record — an audit should show the question was asked and
answered "not applicable to this project shape," never that it was
silently omitted. A documentation, research, or dataset-only repository
should never be flagged in a later audit for "missing tests" or "no SLO."

### 5. Scalability & Reliability

**Applies to: software projects** (the *target* is universal across
software projects; the *mechanism* used to hit it is conditional on the
project's actual scale and stakes).

**Claim:** every software project should state, even briefly, what
load/availability it is designed for — not necessarily build for
hyperscale by default (that's over-engineering; see Maintainability &
Simplicity above), but *know* its target so the answer isn't accidental.

- **SRE framing**: reliability is not "100% uptime" — it's a managed
  trade-off. SLIs (measured signals, e.g. request latency or error rate)
  roll up into SLOs (targets, e.g. "99.5% of requests succeed"), and the
  gap between the SLO and 100% is the **error budget** — the thing that
  licenses risk-taking (deploys, experiments) versus demanding a stability
  freeze. A project with no SLO has no principled way to tell "acceptable
  degradation" from "incident"; every blip becomes a fire drill because
  there's no pre-agreed threshold.
- **Complexity is a reliability property, not just an aesthetic one**:
  SRE literature treats complexity as *the* enemy of reliability —
  unnecessary features and over-engineered APIs are reliability
  liabilities, not merely maintainability ones. This is the direct link
  between this family and Maintainability & Simplicity above; they are not
  independent concerns.
- **Scalability**: the property that a system keeps acceptable
  performance/availability as load grows. At incubation stage the
  relevant question is narrower than "can this scale to millions of
  users" — it's "does the architecture have an obvious, known bottleneck
  the team has consciously accepted for now," versus one nobody noticed
  and nobody chose.
- **What's conditional**: *how* you achieve reliability — redundancy,
  autoscaling, chaos testing, multi-region failover — scales with the
  project's actual stakes. A weekend prototype does not need an
  error-budget policy or a paging rotation; a project handling money or
  health data does. The principle ("know and state your target") is
  universal across software projects; the mechanism used to reach it is
  not.
- **Minimum viable statement at incubation**: one sentence in the
  project's baseline record — expected scale (rough order of magnitude),
  an availability expectation if one is known, and the single biggest
  known-and-accepted bottleneck, if any.

### 6. Observability

**Applies to: software projects.**

**Claim:** a system should be debuggable from its own output, without
attaching a debugger or guessing.

- **The three established pillars**: **traces** (a single
  request/operation's path across components), **metrics** (aggregated
  numeric time series: rates, counts, latencies), and **logs** (discrete
  timestamped events). OpenTelemetry — now the de facto vendor-neutral
  instrumentation standard — also defines **baggage**, a
  context-propagation mechanism that carries metadata alongside a request
  so the three pillars above can be correlated with each other; baggage is
  a correlation tool, not a fourth pillar in its own right. A genuine
  fourth pillar, continuous **profiling**, is under active development
  and still at the proposal stage in OpenTelemetry's specification process
  as of 2026 — real and moving, but not yet an established signal.
- **Current tooling reality (verified 2026-08-19)**: OpenTelemetry
  graduated to CNCF's top maturity tier on **May 11, 2026** (accepted to
  CNCF May 7, 2019; moved to Incubating August 26, 2021). Every major
  observability vendor — Datadog, New Relic, Grafana, Honeycomb, Dynatrace,
  Splunk — ingests OTel natively. The practical implication for a new
  project: instrument with OTel conventions from day one rather than a
  vendor-specific SDK, so the backend can be swapped later without
  re-instrumenting the codebase. This is itself an application of the
  interoperability/pluggability principle above — the observability
  backend is a plugin behind a stable instrumentation interface.
- **The goal is not "having data"**: observability exists to reduce
  mean-time-to-recovery and increase reliability through good signals,
  consistent naming/tagging conventions, correlation (linking a trace to
  the logs and metrics for the same request), and automated workflows
  (alerting) — not dashboards built for their own sake that nobody looks
  at until something is already broken.
- **Minimum viable observability at incubation**: structured logging (not
  ad hoc print statements — actual key-value or JSON structured output), a
  small number of health/error-rate metrics, and — once there is more than
  one service or component — request-level tracing so a failure can be
  pinned to the component that caused it rather than triggering a search
  across every log file in the system.
- **What this is not**: it is not "buy an observability SaaS on day one."
  Structured logs plus a handful of metrics is enough for an
  incubation-stage single-service project; tracing and a dedicated backend
  become necessary once there's more than one component to correlate
  across.

### 7. Testability

**Applies to: software projects** — distinct from TDD.

**Claim:** the architecture must have seams — points where a real
dependency can be substituted for a fake, mock, or stub — or verification
of any kind, TDD or otherwise, is structurally blocked.

Testability is the structural precondition TDD depends on (see TDD below),
and it's also what makes the Dependency Inversion Principle and the
pluggability section above load-bearing for testing, not only for
extension. It's called out as its own line item, separate from TDD,
because it's possible to violate testability without violating TDD
practice narrowly — hardcoded singletons, hidden global state, and
constructors that reach out to real network calls with no injection point
all block testing regardless of whether anyone intended to write tests
red-first. Check for testability independently of whether tests exist yet:
can every external dependency (network, filesystem, clock, randomness) be
substituted at the boundary where a unit under test uses it?

### 8. Test-Driven Development (TDD)

**Applies to: software projects.**

**Claim:** tests are written before (or immediately alongside, in a tight
loop with) the implementation, and the loop is red → green → refactor.

- **Core cycle**: write a failing test, write the minimal code to pass it,
  refactor while keeping it green. The discipline is in the ordering, not
  merely in having a test suite.
- **2025 best-practice refinements**: descriptive test names,
  Arrange-Act-Assert structure, atomic and isolated tests (no test depends
  on another test's side effects), edge cases covered before happy paths,
  and CI configured to fail the build on any red test — not to warn and
  continue. Coverage-percentage-chasing is explicitly discouraged in
  current practice in favor of "meaningful coverage plus mutation
  testing" as the actual quality signal — a suite that passes but doesn't
  fail when a mutant is introduced into the code isn't proving much.
- **Why this is an architecture principle and not just a QA practice**:
  TDD forces you to design the *interface* to a unit before its
  implementation exists, which pushes toward decoupled, modular design as
  a side effect — the same outcome the Dependency Inversion Principle
  targets from a different direction. AI-assisted development in
  2025–2026 doesn't change this underlying discipline: AI is increasingly
  used to scaffold starter tests and suggest edge cases, but "tests define
  the contract" and the red-green-refactor loop are unchanged by who or
  what is typing the code.
- **Relationship to testability**: TDD is a practice; testability (above)
  is the structural property TDD depends on. Untestable code makes TDD
  impossible regardless of team intent — fix the seams first if TDD isn't
  happening.

### 9. Spec-Driven Development (SDD)

**Applies to: software projects, conditionally** — applies once AI coding
agents are part of the build process; still an emerging practice as of
2025–2026, not yet a universal norm the way TDD is. Present this to a
project team with more judgment and less rigidity than TDD — it's real and
actively tooled, not speculative, but it hasn't earned equal footing yet.

**Claim:** a versioned, structured specification — not the code — is the
source of truth that both humans and AI coding agents build and generate
against; code is checked for drift against the spec rather than being the
sole record of intent.

- **Definition** (Thoughtworks, 2025): "a development paradigm that uses
  well-crafted software requirement specifications as prompts, aided by AI
  coding agents, to generate executable code."
- **Why it emerged specifically in 2025**: as a direct response to "vibe
  coding" failure modes — AI agents producing plausible-looking code that
  drifts from actual intent, hallucinates APIs that don't exist, and
  decays as a project scales past what fits in a single context window.
  SDD gives both the agent and the human reviewer a stable artifact to
  check generated output against, instead of the code itself being the
  only record of what was intended.
- **Relationship to TDD**: parallel, not identical. In TDD, the spec
  drives *test* creation, and the tests are the executable check. In SDD,
  the spec drives *code generation* directly — and per Thoughtworks,
  "executable code remains the source of truth you need to maintain,"
  meaning SDD does not replace the need for deterministic CI and tests.
  Specs are a catalyst for generation and review, not a replacement for
  verification. A project doing SDD without TDD underneath it still has a
  verification gap.
- **Effective spec structure**: external behavior (inputs/outputs),
  preconditions, postconditions, invariants, and interface contracts,
  written in domain language rather than implementation detail. Planning
  and implementation are kept as separate phases — the spec is reviewed by
  a human before an agent generates code against it, not written and
  consumed in the same breath.
- **Tooling landscape (2026)**: every major AI coding tool has shipped a
  flavor of this — GitHub Spec Kit, AWS Kiro, Claude Code, Cursor,
  OpenSpec, BMAD, Tessl, Google Antigravity — so a project adopting
  AI-assisted development today will likely touch some SDD-shaped workflow
  whether or not the team calls it that by name.
- **Why conditional, not universal**: a project with no AI-agent
  involvement in its build process has no particular need for
  machine-readable specs-as-prompts — a lightweight, human-written design
  doc or README still does the job. The *rigor* SDD calls for (explicit
  pre/postconditions, invariants) is good practice generally, but the
  specific SDD workflow is a response to a specific failure mode — agents
  drifting from intent — that only exists once agents are the ones writing
  the code.

---

## Part III — LLM/Agent-Conditional Principles

Both families in this part are gated on a single question, asked at
inception and **re-checked on every audit invocation**: does this project
have an LLM or agent component? This is independent of the
software/non-software fork — a documentation project that uses an LLM to
synthesize research findings owes itself this section just as much as a
production agent product does. If the answer flips in either direction
since the last baseline record, the audit flags the drift, updates the
record, and applies or retires this entire part accordingly. Applying
"provenance" or "model-switching" to a project with no model in the loop
is a category error this document guards against as deliberately as it
guards against skipping these principles when they do apply.

### 10. Determinism-First

**Applies to: projects with an LLM/agent component.**

**Claim:** when a task can be solved with deterministic code — parsing,
validation, arithmetic, lookups, well-specified transformations — prefer
that over routing it through a model call. Reserve the LLM for tasks that
genuinely require reasoning over ambiguous or unstructured input.

- This generalizes a principle from VSIP's architectural addendum
  ("deterministic tasks should remain deterministic"), extended beyond
  that project's specific domain — it's the same reasoning behind "don't
  use regex when a real parser exists," scaled up to "don't use an LLM
  when a function will do."
- **Stated payoff**: reproducibility, auditability, explainability, lower
  operational cost, and easier debugging — all properties that get
  strictly harder to guarantee once a probabilistic model call sits in
  the path of a task that didn't need one.
- **Why this is conditional, not universal**: this is only a live design
  *choice* — something a project must actively decide — when the project
  has an LLM/agent component in the first place and a decision point
  exists over whether to route a given task through it. For a project with
  no model in the loop, the principle collapses to the unremarkable "write
  code, don't invent an LLM dependency where none is needed" and isn't
  worth calling out as a separate line item.
- **Kept standalone, not folded into the LLM-specific section below**:
  determinism-first is cross-referenced from that section rather than
  merged into it, because it's a design orientation that shapes *whether*
  a task goes through the model at all, distinct from harness,
  model-switching, provenance, and relevance-scoring, which all concern
  *how* to architect the parts that do go through a model.

### 11. LLM/Agent-Specific Principles

**Applies to: projects with an LLM/agent component.** This entire family
must be flagged **inapplicable** for any project that doesn't call a model
or run an agent loop — forcing "provenance" or "model-switching" onto a
plain CRUD app is exactly the category error this document exists to
prevent.

#### 11.1 Needs a Harness

**Claim:** the model itself is not the architecture. The engineered layer
around a bare model call — the harness — is.

- An **agent harness** is what turns a bare model call into bounded,
  stateful, tool-mediated task execution: the loop, tool interfaces,
  context/memory management, permissions, observability, and governance
  constraints. It is not the model, and it's not optional scaffolding
  around the "real" work — it *is* the architectural work.
- Almost every agent framework claims to be model-agnostic, but
  model-agnostic is not a list of supported provider strings — it's
  whether switching one costs you a restart. The harness is the thing
  doing the architectural work; the model behind it is a replaceable
  component.
- The term itself is recent: usage jumped after Anthropic's engineering
  post "Effective harnesses for long-running agents" (published November
  26, 2025), followed shortly by OpenAI's "Harness engineering: leveraging
  Codex," with the discipline subsequently getting treated as its own
  named practice in broader engineering commentary. Anthropic's framing is
  a useful design lens on its own: "every component in a harness encodes
  an assumption about what the model can't do on its own" — build the
  harness around the model's actual gaps, not hypothetical ones you
  imagine it might have.
- **Practical shape for a long-running agent task**, per Anthropic's
  writeup: an initializer step sets up environment, feature-list, and
  progress-tracking state; then repeated coding-agent steps make
  incremental, checkpointed progress. The harness — not the raw model —
  carries continuity across context-window boundaries, because the model
  itself has no memory of a session once that session's context is gone.
- **Checklist**: can you point to the specific code that constitutes "the
  harness" separately from "the prompt"? If the only artifact governing
  agent behavior is a system prompt, there is no harness yet — that's a
  gap to close before this principle is satisfied.

#### 11.2 Model-Switching Capability

**Claim:** a well-built harness lets the underlying model be changed — or
changed mid-session — without restructuring the surrounding system.

- This follows directly from 11.1: if the harness is the architectural
  unit and the model is a swappable component behind it, the harness
  should actually make that swap cheap. Cited industry reasoning: teams
  with model-agnostic architectures could reroute to an alternative
  provider and keep running during a provider outage — this is an
  availability/reliability argument as much as a cost or quality one, and
  ties directly back to the Scalability & Reliability family in Part II
  when this project also has software-path status.
- **The practical test**: it's not "can this codebase point at multiple
  provider strings in a config file." It's "does switching the model
  require a restart or redeploy, or can it happen live, mid-session,
  without the harness's state (context, tool permissions, progress
  tracking) being lost."
- **Checklist**: is the model identifier itself config-driven (see Zero
  Hardcoding above) rather than hardcoded into a client-construction call
  buried in application logic? Does anything besides the model call site
  itself need to change to switch providers?

#### 11.3 Provenance Is Mandatory

**Claim:** the system must record what evidence a claim or action actually
came from — structurally, at generation time — not optionally, and not
only as an end-user-facing footnote.

- **Definition in current practice**: provenance is the ability to trace a
  generated claim or action back to the specific evidence — a retrieved
  document, a tool-call result, a prior agent step — that produced it.
  This is distinct from *citation*, which is displaying a source to a
  user; provenance is the underlying evidence chain, which may or may not
  ever be surfaced.
- **The failure mode this guards against**: "post-rationalized" citations
  — the model answers from its own parametric memory first, then attaches
  a citation to a superficially matching retrieved document after the
  fact, so the citation looks grounded without actually reflecting what
  produced the answer. This is a documented, named failure pattern in
  current RAG literature, not a hypothetical risk.
- **Current research directions** (survey literature, 2025–2026): evidence
  tracing via linked memory structures (systems like A-MEM), post-hoc
  citation-link approaches (ALCE), source-support verification
  (SourceCheckup), atomic claim-to-evidence pairing (FActScore-style
  verification), and provenance graphs that track tool-call parameters at
  runtime for agent auditing. Vision-RAG work (VISA) extends provenance
  further — pointing at a bounding box inside a source document image,
  not just naming a document ID.
- **Practical implication**: "provenance is mandatory" means the system
  records, structurally, what evidence backed a claim or action at the
  moment it was generated. Surfacing that evidence to an end user is a UX
  decision, made per product; recording it in the first place is the
  architectural one, not optional.
- **Checklist**: for any generated claim or automated action, can you
  trace, after the fact, exactly which retrieved document, tool result, or
  prior step produced it? If the answer is "no, we'd have to guess," this
  principle isn't satisfied yet regardless of whether citations are shown
  in the UI.

#### 11.4 Relevance Score Alongside Provenance

**Claim:** every piece of evidence a system uses should carry not just
where it came from, but how good the match was — provenance says *where*,
relevance/confidence says *how much to trust it*.

- **Why this is paired with provenance rather than a separate concern**: a
  source citation with no relevance or confidence signal doesn't tell the
  consumer — human or downstream system — how much weight to put on it.
  Provenance without a confidence signal is an unranked evidence dump.
- **Concrete retrieval-relevance methods in current practice**: ground-truth
  ranking metrics — Precision@k, Recall@k, NDCG@k, Hit Rate — when labeled
  query-to-document pairs exist; LLM-as-judge per-chunk relevance scoring
  (binary or 0–1) when they don't. Cited research (Microsoft) claims
  GPT-4-class judges approach human-level agreement on chunk-relevance
  judgments — but independent evaluation literature also reports automated
  relevance-judgment agreement with human assessors as low as 0.30–0.34
  depending on task and domain. Treat LLM-judge relevance scores as noisy
  signals, not ground truth, until validated against a labeled set for
  your specific domain.
- **No universal confidence threshold exists.** The evaluation literature
  explicitly declines to name a single cutoff (e.g. "reject anything below
  0.7") and instead recommends building a domain-specific labeled
  evaluation set — roughly 100–200 queries with gold chunks/answers — and
  calibrating thresholds to that domain. As a starting-point anchor for a
  project too early-stage to have built a calibration set yet, the
  research surfaces roughly **0.7+ precision@k for narrow, specialized
  domains** and **0.5+ for broad, open domains** — offered explicitly as
  an illustrative starting point to unblock an incubating project, not as
  a validated universal standard. Replace it with a domain-calibrated
  threshold as soon as the project has enough real query traffic to build
  one.
- **Practical implication**: "relevance score alongside provenance" means
  every retrieved or used piece of evidence carries (a) its source
  identity, (b) a relevance/confidence value, and (c) an honest sense of
  that scoring method's known reliability limits — so a downstream
  consumer can make an informed trust decision instead of treating every
  returned piece of evidence as equally certain.
- **Checklist**: does retrieved evidence in this system carry a score at
  all? Is there a documented (even rough) threshold below which evidence
  is treated as low-confidence rather than presented at equal weight to
  everything else?

---

## What This Document Does Not Cover

Deliberately out of scope, and left to more specific references or a
future baseline rather than folded in here:

- **Specific vendor or tool recommendations** — which observability
  backend, which plugin framework, which RAG evaluation SaaS. This is a
  principles document, not a buy/build guide; tool choice is downstream of
  a project's actual constraints and dates quickly. Tool-specific guidance
  lives in `stacks/<category>.md` and `preferred-libraries/*.md`.
- **Detailed threat-modeling methodology** (STRIDE, PASTA, and similar) —
  security-by-design is covered as a principle family above, but a full
  threat-modeling walkthrough is its own discipline, not an architecture
  principle at this altitude.
- **Deep RAG-system design** — chunking strategy, embedding model choice,
  hybrid search tuning. Only the provenance and relevance-confidence
  *principles* are in scope here; RAG implementation mechanics belong in a
  stack-specific reference.
- **SRE operational practice** — on-call rotations, incident response
  runbooks, postmortem templates. Reliability as an architecture principle
  (state your SLO, treat complexity as a reliability cost) is in scope;
  the operational playbook around it is not.
- **CI/CD pipeline design specifics** — referenced above as a dependency
  of TDD/SDD ("tests gate the build") but not elaborated as its own
  principle family here.
- **License, legal, and compliance architecture** (data residency,
  GDPR-by-design, and similar) — adjacent to security-by-design but a
  distinct, large topic, flagged as a candidate for a future baseline
  rather than folded in here.

---

## Sources

- [12factor.net — Config](https://12factor.net/config) — the Config
  factor: strict separation of environment-varying config from code via
  environment variables, and the "could open-source the codebase without
  leaking credentials" litmus test. Retrieved 2026-08-19.
- [OWASP Secure-by-Design Framework](https://owasp.org/www-project-secure-by-design-framework/)
  (draft v0.5.0, August 2025) — design-time security guidance structure:
  process, principles across six domains, review checklist, best-practice
  catalog. Retrieved 2026-08-19.
- [OWASP Top 10:2025 — A06, Insecure Design](https://owasp.org/Top10/2025/A06_2025-Insecure_Design/)
  — establishes design/architecture-level security flaws as a category
  distinct from implementation bugs. Retrieved 2026-08-19.
- [Evidently AI — RAG Evaluation Guide](https://www.evidentlyai.com/llm-guide/rag-evaluation)
  — retrieval-relevance scoring methods (Precision@k, Recall@k, NDCG@k,
  Hit Rate, LLM-judge per-chunk scoring) and the explicit statement that no
  universal confidence threshold exists. Retrieved 2026-08-19.
- [Thoughtworks — Spec-Driven Development](https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)
  — definition of spec-driven development, its relationship to TDD,
  effective spec structure, and why it emerged in 2025 as a response to
  vibe-coding drift. Retrieved 2026-08-19.
- Anthropic engineering blog, "Effective harnesses for long-running
  agents" (published November 26, 2025) — establishes the
  harness-as-architectural-unit framing, the initializer/coding-agent
  pattern for long-running tasks, and "every component in a harness
  encodes an assumption about what the model can't do on its own."
  Retrieved via search-indexed mirror/summary 2026-08-19; original at
  Anthropic's engineering blog.
- arXiv 2606.04990, "From Agent Traces to Trust: A Survey of Evidence
  Tracing and Execution Provenance in LLM Agents" — survey establishing
  the current taxonomy of provenance approaches in LLM agents (A-MEM,
  ALCE, SourceCheckup, FActScore-style verification, provenance graphs for
  tool-call auditing). Retrieved 2026-08-19 (summarized from
  search-result abstracts; the full PDF exceeded available fetch size).
- arXiv 2412.14457, "VISA: Retrieval Augmented Generation with Visual
  Source Attribution" — establishes vision-based provenance (bounding-box
  source attribution in document images) as a current research direction.
  Retrieved 2026-08-19.
- [CNCF — OpenTelemetry project page](https://www.cncf.io/projects/opentelemetry/)
  — OpenTelemetry was accepted to CNCF May 7, 2019, reached Incubating
  maturity August 26, 2021, and reached **Graduated** maturity **May 11,
  2026**. Retrieved 2026-08-19.
- [OpenTelemetry — Signals](https://opentelemetry.io/docs/concepts/signals/)
  — OpenTelemetry's currently established signals are traces, metrics,
  logs, and baggage (a correlation mechanism, not an observability
  pillar); continuous profiling is in active development at the proposal
  stage, not yet a formally established signal. Retrieved 2026-08-19.
- Search-result synthesis on SRE principles (error budgets, SLI/SLO,
  complexity as a reliability risk), consistent with the framing in
  Google's public SRE book. Retrieved 2026-08-19.
- Search-result synthesis on plugin architecture and the Dependency
  Inversion Principle as the SOLID basis for pluggability. Retrieved
  2026-08-19.
- Search-result synthesis on 2025 TDD best practices (red-green-refactor,
  Arrange-Act-Assert structure, mutation-score-over-coverage-percentage as
  the quality signal). Retrieved 2026-08-19.
- Search-result synthesis on KISS/YAGNI/DRY as maintainability principles,
  including the caution that they require surrounding architecture,
  testing, and governance to actually deliver value. Retrieved 2026-08-19.
- `VSIP_Architectural_Addendum.md` (local file, read in full) — used as
  both a structural style reference (crisp claim → why → concrete bullets
  → explicit "what this is not") and as the origin of the generalized
  Determinism-First principle (its own principle #5). Not treated as
  authoritative content otherwise — VSIP is an unimplemented, shelved
  strategy document, cited here only for phrasing and for the one
  generalized principle. Read 2026-08-19.

**A note on sourcing discipline.** During research, some web searches
returned auto-generated summary paragraphs with specific-sounding
statistics — a claimed "83% of enterprise RAG deployments include citation
functionality," a named industry body ("RAG Citation Consortium"), and an
"EU AI Act... effective February 2026" citation mandate — that could not
be traced to any of the actual source URLs returned alongside them. None
of that appears anywhere in this document. Every number and dated claim
above is sourced either to a URL fetched and read directly, or flagged
explicitly as a search-result synthesis rather than a primary source.
