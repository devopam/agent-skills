# Baseline: Common Architecture Principles
Status: user-approved      Date: 2026-08-19

## Note on sourcing
WebSearch's auto-generated summaries occasionally invented unverifiable specifics (e.g. a claimed "RAG Citation Consortium" formed Jan 2025 with named members, and precise adoption percentages tied to it). That claim could not be traced to any real source and is deliberately **excluded** below. Everything cited was either fetched and read directly (primary source) or is a well-established, independently-checkable concept. Treat any number not attributed to a fetched URL as unverified.

## Style reference used
Read in full: `C:\Users\devop\GitHub\VSIP\VSIP_Architectural_Addendum.md`. Its useful formal traits, carried into the structure below: each principle stated as one crisp imperative or claim, immediately followed by a short "why," then concrete examples as bullet lists, and — where relevant — an explicit statement of what the principle does *not* mean. VSIP's specific content (its domain, its 13 principles) is not reused as substance, only imitated as form.

---

## In scope

- **Interoperability & pluggability** — impact: high — depth: section — universal
- **Scalability & reliability** — impact: high — depth: section — universal (the *mechanisms* used are conditional on scale, but the *principle* that a project should state its scale/reliability targets is universal)
- **Observability** — impact: high — depth: section — universal
- **Zero hardcoding / config-driven (12-factor config)** — impact: high — depth: section — universal
- **TDD** — impact: high — depth: section — universal
- **SDD (spec-driven development)** — impact: med — depth: section — conditional (applies once AI coding agents are part of the build process; still emerging as of 2025-2026, not yet a universal norm the way TDD is)
- **LLM/agent-specific principles** (harness, model-switching, provenance, relevance+confidence) — impact: high *when applicable* — depth: section — **conditional on the project having an LLM/agent component**
- **Security-by-design** *(user's list did not name this; added)* — impact: high — depth: section — universal
- **Testability** *(added; distinct from TDD — TDD is a practice, testability is a structural property TDD depends on)* — impact: high — depth: paragraph — universal
- **Maintainability / simplicity (KISS, YAGNI, DRY)** *(added)* — impact: high — depth: paragraph — universal
- **Determinism-first / "don't use an LLM where deterministic code will do"** *(added — this is VSIP's principle #5, generalized beyond VSIP; it's the connective tissue between the LLM-specific section and the rest)* — impact: med — depth: paragraph — conditional (only meaningfully distinct from "use the right tool" when a project *has* an LLM component and the temptation exists)

---

### Interoperability & pluggability — UNIVERSAL

**Claim:** a system's core should depend on abstractions, not on the concrete things that plug into it. New capabilities should be addable without editing the core.

- **Plugin architecture pattern**: a core system manages orchestration and exposes stable extension points; plugins implement use-case-specific behavior and are agnostic of each other and of the core's internals. Loose coupling (core knows only the plugin *interface*), single responsibility per plugin, and a well-defined API are the three load-bearing properties.
- **Dependency Inversion Principle (the "D" in SOLID)**: high-level modules must not depend on low-level modules — both depend on abstractions. This is *why* plugin architectures are swappable: because the core is written against an interface, a new implementation can be substituted without touching the core or triggering regressions elsewhere.
- **What this is not**: it is not "use microservices" or "expose everything as a REST API." Interoperability is about seams (clean interface boundaries) existing at all — they can be in-process (an injected interface) or over-the-wire (an API), and the right seam location is a project-specific decision, not a mandate.
- **Practical checklist form for the eventual skill**: does the project define its extension points explicitly (interfaces/contracts) before implementing the first concrete plugin? Can a second implementation of any given interface be added without modifying the interface's consumers?

### Scalability & reliability — UNIVERSAL (targets); mechanisms are scale-conditional

**Claim:** every project should state, even briefly, what load/availability it is designed for — not necessarily build for hyperscale by default (that's over-engineering, see Maintainability/Simplicity below), but *know* its target so the answer isn't accidental.

- **SRE framing**: reliability is not "100% uptime," it's a managed trade-off. SLIs (measured signals) roll up into SLOs (targets), and an **error budget** (the gap between the SLO and 100%) is what licenses risk-taking (deploys, experiments) versus demanding a stability freeze. A project that has no SLO has no way to tell "acceptable degradation" from "incident."
- **Simplicity as a reliability property, not just an aesthetic one**: complexity is treated in SRE literature as *the* enemy of reliability — unnecessary features and over-engineered APIs are reliability liabilities, not just maintainability ones. This is a direct link between this principle family and Maintainability below.
- **Scalability**: the property that a system keeps acceptable performance/availability as load grows. For an incubation-stage project the relevant question is narrower than "can this scale to millions" — it's "does the architecture have an obvious, known bottleneck the team has consciously accepted for now" (vs. one nobody noticed).
- **Conditional part**: *how* you achieve reliability (redundancy, autoscaling, chaos testing, multi-region) scales with the project's actual stakes. A weekend prototype does not need an error-budget policy; a project handling money or health data does. The principle ("know and state your target") is universal; the mechanism is not.

### Observability — UNIVERSAL

**Claim:** a system should be debuggable from its own output, without attaching a debugger or guessing.

- **The three pillars** (now trending toward four): **logs** (discrete timestamped events), **metrics** (aggregated numeric time series — rates, counts, latencies), and **traces** (a single request/operation's path across components/services). A fourth pillar, **continuous profiling**, is being formally folded into OpenTelemetry's model as of 2026.
- **Current tooling reality (2025-2026)**: OpenTelemetry (OTel) graduated as a CNCF project in May 2026 and is now the de facto instrumentation standard — every major observability vendor (Datadog, New Relic, Grafana, Honeycomb, Dynatrace, Splunk) ingests it natively. Practical implication for a new project: instrument with OTel conventions from day one rather than a vendor-specific SDK, so the backend can be swapped later without re-instrumenting (this is itself an application of the interoperability/pluggability principle above).
- **The goal is not "having data"**: the stated 2026 framing is that observability exists to reduce mean-time-to-recovery and increase reliability through good signals, consistent semantics (naming/tagging conventions), correlation (linking a trace to the logs and metrics for the same request), and automated workflows (alerting) — not dashboards for their own sake.
- **Minimum viable observability for an incubating project**: structured logging (not print statements), a small number of health/error-rate metrics, and — once there's more than one service/component — request-level tracing so a failure can be pinned to a component.

### Zero hardcoding / config-driven (12-Factor config) — UNIVERSAL

**Claim:** anything that varies between environments (dev/staging/prod) or deployments must live outside the code — never as a literal in source.

- **Twelve-Factor App, Factor III (Config)**: "config varies substantially across deploys, code does not." Config = credentials, hostnames, ports, feature flags, per-deploy resource handles — anything that would need to differ if the *same* code ran somewhere else.
- **Why environment variables specifically**: language- and OS-agnostic (not tied to a config-file format your framework invented), trivially changed without a code change or redeploy of code, and structurally resistant to being accidentally committed to version control the way a checked-in config file is.
- **The litmus test** (12factor.net's own phrasing): "the codebase could be made open source at any moment, without compromising any credentials." If publishing the repo would leak a secret, config/code separation has already failed.
- **Modern refinement**: don't just move hardcoded values into one giant `config.py`/`settings.js` — twelve-factor explicitly warns against grouping variables into named "environments," because that reintroduces coupling (a new deploy target needs its own named environment block). Treat each variable as independently settable.
- **Scope note for the skill**: this principle is about *runtime* configuration. It is not an argument against constants that are genuinely invariant (e.g., a mathematical constant, an internal enum) — "zero hardcoding" targets things that vary by environment or deployment, not all literals everywhere.

### TDD — UNIVERSAL

**Claim:** tests are written before (or immediately alongside, in a tight loop with) the implementation, and the loop is red → green → refactor.

- **Core cycle**: write a failing test, write the minimal code to pass it, refactor while keeping it green.
- **2025 best-practice refinements**: descriptive test names, Arrange-Act-Assert structure, atomic/isolated tests, edge cases covered before happy paths, CI fails the build on any red test. Coverage-chasing is explicitly discouraged in favor of "meaningful coverage plus mutation testing" as the quality signal.
- **Why it's an architecture principle and not just a QA practice**: TDD forces you to design the *interface* to a unit before its implementation exists, which pushes toward decoupled, modular design as a side effect — the same outcome the Dependency Inversion Principle targets. AI-assisted development in 2025-2026 doesn't change this: AI is increasingly used to scaffold starter tests and suggest edge cases, but the red-green-refactor discipline and the "tests define the contract" idea are unchanged.
- **Relationship to testability (see below)**: TDD is a practice; testability is the structural precondition that makes the practice possible at all (untestable code — hidden global state, no seams for a fake/mock — makes TDD impossible regardless of intent).

### SDD (spec-driven development) — CONDITIONAL (applies once AI coding agents are in the build loop; not yet a universal default)

**Claim:** a versioned, structured specification — not the code — is the source of truth that both humans and AI coding agents build/generate against; code is checked for drift against the spec rather than being the sole record of intent.

- **Definition** (Thoughtworks, 2025): "a development paradigm that uses well-crafted software requirement specifications as prompts, aided by AI coding agents, to generate executable code."
- **Why it emerged specifically in 2025**: as a direct response to "vibe coding" failure modes — AI agents producing plausible code that drifts from actual intent, hallucinates APIs, and decays as a project scales past what fits in context. SDD gives the agent (and the human reviewer) a stable artifact to check output against.
- **Relationship to TDD**: parallel but not identical. In TDD, the spec drives *test* creation, and tests are the executable check. In SDD, the spec drives *code generation* directly, and — per Thoughtworks — "executable code remains the source of truth you need to maintain," meaning SDD does not replace the need for deterministic CI/tests; specs are a catalyst, not a replacement for verification.
- **Effective spec structure**: external behavior (inputs/outputs), preconditions, postconditions, invariants, interface contracts — domain language, not implementation detail. Planning and implementation are kept as separate phases (spec reviewed by a human before an agent generates code against it).
- **Tooling landscape (2026)**: every major AI coding tool has shipped a flavor of this — GitHub Spec Kit, AWS Kiro, Claude Code, Cursor, OpenSpec, BMAD, Tessl, Google Antigravity — so a project adopting AI-assisted development today will likely touch some SDD-shaped workflow whether or not it's named that.
- **Why conditional, not universal**: a project with no AI-agent involvement in its build process has no particular need for machine-readable specs-as-prompts; a lightweight human-written design doc / README still does the job. The *rigor* SDD calls for (explicit pre/postconditions, invariants) is good practice generally, but the specific SDD workflow is a response to a specific failure mode (agents drifting from intent) that only exists when agents are writing the code.

### LLM/agent-specific principles — CONDITIONAL: apply only when the project has an LLM/agent component

This entire family should be flagged as **inapplicable** by the eventual skill for any project that doesn't call a model or run an agent loop. Forcing "provenance" or "model-switching" onto a plain CRUD app is a category error the skill must guard against.

**1. Needs a harness**
- An **agent harness** is the engineered layer around a bare model call that turns it into bounded, stateful, tool-mediated task execution: the loop, tool interfaces, context/memory management, permissions, observability, and governance constraints. It is not the model.
- "Almost every agent framework claims to be model-agnostic... but model-agnostic is not a list of supported providers, it is whether switching one costs you a restart." — i.e. the harness is the thing doing the architectural work; the model is a replaceable component behind it.
- The term itself is recent: usage jumped after Anthropic's Nov 2025 post "Effective harnesses for long-running agents" (published 26 Nov 2025), followed by OpenAI's "Harness engineering: leveraging Codex," with Martin Fowler subsequently treating it as its own discipline. Anthropic's framing: "every component in a harness encodes an assumption about what the model can't do on its own" — a useful design lens (build the harness around the model's actual gaps, not hypothetical ones).
- Practical shape for a long-running agent task per Anthropic's writeup: an initializer step sets up environment/feature-list/progress-tracking state, then coding-agent steps make incremental, checkpointed progress — because the harness, not the raw model, carries continuity across context-window boundaries.

**2. Model-switching capability**
- Follows directly from "harness is the architectural unit, model is swappable": a well-built harness lets the underlying model be changed (or changed *mid-session*) without restructuring the surrounding system. Cited industry reasoning: teams with model-agnostic architectures could reroute to an alternative provider and keep running during a provider outage — an availability/reliability argument, not just a cost/quality one.
- Practical test proposed in the research: it's not "can point at multiple provider strings in config," it's "does switching require a restart / redeploy, or can it happen live."

**3. Provenance is mandatory**
- **Definition in current practice**: the ability to trace a generated claim/action back to the specific evidence (retrieved document, tool call result, prior agent step) that produced it — as distinct from citation, which is *displaying* a source, versus provenance, which is the underlying evidence chain that may or may not be surfaced to the end user.
- **Known failure mode this guards against**: "post-rationalized" citations — the model answers from its own parametric memory first, then attaches a citation to a superficially matching retrieved document after the fact, rather than the citation reflecting what actually grounded the answer. This is a documented, named failure pattern in current RAG literature, not a hypothetical.
- **Current research directions** (as of 2025-2026, per the survey literature): evidence tracing via linked memory structures (e.g., systems like A-MEM), post-hoc citation-link approaches (ALCE), source-support verification (SourceCheckup), atomic claim-to-evidence pairing (FActScore-style verification), and provenance graphs that track tool-call parameters at runtime for agent auditing. Vision-RAG work (VISA) extends provenance to pointing at a bounding box in a source document image, not just a document ID.
- **Practical implication for the skill**: "provenance is mandatory" should mean the system records *what evidence a claim/action came from*, structurally, at generation time — not that every answer must show a footnote to the end user. Surfacing is a UX decision; recording is the architectural one.

**4. Relevance score alongside provenance, for confidence**
- **Why paired with provenance, not a separate concern**: a source citation without a relevance/confidence signal doesn't tell the consumer (human or downstream system) how much to trust it — provenance says *where it came from*, relevance/confidence says *how good the match was*.
- **Concrete retrieval-relevance methods in current practice**: ground-truth ranking metrics (Precision@k, Recall@k, NDCG@k, Hit Rate) when labeled query→document pairs exist; LLM-as-judge per-chunk relevance scoring (binary or 0-1) when they don't, with cited research (Microsoft) claiming GPT-4-class judges approach human-level agreement on chunk relevance judgments — though independent evaluation literature also notes automated relevance judgment agreement with human assessors can be as low as 0.30-0.34 depending on task/domain, so this is not a solved problem and scores should be treated as noisy signals, not ground truth.
- **No universal confidence threshold exists**: the evaluation literature explicitly declines to name a single cutoff (e.g., "reject below 0.7") and instead recommends building a domain-specific labeled evaluation set (~100-200 queries with gold chunks/answers) and picking thresholds calibrated to that domain. A rough rule of thumb surfaced in the research: Precision@k targets of roughly 0.7+ for narrow/specialized domains vs. 0.5+ for broad/open domains — offered as an illustrative anchor, not a hard standard.
- **Practical implication for the skill**: "relevance score alongside provenance" should be operationalized as: every retrieved/used piece of evidence carries (a) its source identity, (b) a relevance/confidence value, and (c) the scoring method's known reliability limits — so downstream consumers can make an informed trust decision rather than treating any returned evidence as equally certain.

### Security-by-design — UNIVERSAL *(added — not on the user's original list)*

**Claim:** security is a design-time architectural concern, not a pre-launch checklist or a post-incident patch.

- **OWASP Secure-by-Design Framework** (draft v0.5.0, August 2025): structured, design-time guidance for embedding security into architecture *before* code is written, organized around process (an operational playbook), principles/recommendations across six domains (core principles, architecture, data management, resilience, access control, monitoring), a condensed review checklist (~40 actionable items), a best-practice catalog of reference architectures, and integration points with ASVS/threat modeling.
- **Core design principles** (OWASP): minimize attack surface, secure defaults, least privilege, defense in depth, fail securely, don't trust other services blindly, separation of duties, no security-by-obscurity, keep security mechanisms simple, fix issues at the root cause rather than patching symptoms.
- **2025-2026 framing shift**: OWASP's own Top 10 revision explicitly calls out "insecure design" as a category distinct from insecure *implementation* — the push is to move threat modeling and secure design patterns earlier than "shift-left" (which was already about coding-time), into requirements-writing and architecture time.
- **Why added**: the user's list covers reliability, observability, and config hygiene as cross-cutting concerns, but has no explicit security principle; security-by-design is as universally applicable as those and is a standard member of any "common architecture principles" treatment.

### Testability — UNIVERSAL *(added, distinct from TDD)*

**Claim:** the architecture must have seams — points where a real dependency can be substituted for a fake/mock/stub — or verification of any kind (TDD or otherwise) is structurally blocked.

- This is the structural precondition TDD depends on (see TDD section) and is also what makes the Dependency Inversion Principle and pluggability sections above load-bearing for testing, not just for extension. Kept as a short, separate line item because it is possible to violate testability without violating TDD practice narrowly (e.g., hardcoded singletons, hidden global state, no dependency injection) — worth calling out on its own so the eventual skill can check for it independently.

### Maintainability / simplicity (KISS, YAGNI, DRY) — UNIVERSAL *(added)*

**Claim:** default to the simplest design that satisfies current, known requirements; add complexity only when a real, present need demands it.

- **KISS** ("Keep It Simple"): unnecessary complexity is a direct cost to debuggability and extensibility, not just an aesthetic preference — this is the same claim SRE literature makes about complexity being "the enemy of reliability" (see Scalability & Reliability above), which is why this family is placed adjacent to that one.
- **YAGNI** ("You Aren't Gonna Need It"): don't build for imagined future requirements; speculative generality is itself a maintainability liability (more surface area, more to keep consistent, more that can silently rot unexercised).
- **DRY** (avoid unnecessary duplication) is the third commonly paired principle but is lower-stakes for an incubation-stage baseline; included for completeness.
- **Caution surfaced in current sources**: these principles "alone cannot guarantee production robustness — they only deliver value when integrated into a modular architecture, automated testing, clear technical governance, and shared engineering culture," i.e. this family is a complement to the other principles above, not a substitute for them.

### Determinism-first ("don't use an LLM where deterministic code will do") — CONDITIONAL *(added, generalized from VSIP's principle #5)*

**Claim:** when a task can be solved with deterministic code (parsing, validation, arithmetic, lookups, well-specified transformations), prefer that over routing it through a model call — reserve the LLM for tasks that genuinely require reasoning over ambiguous/unstructured input.

- This is a generalization of VSIP's own principle ("deterministic tasks should remain deterministic") — cited here explicitly as a style/content borrow beyond just structure, because it's a genuinely well-established idea beyond VSIP (it's the same reasoning behind "don't use regex when a real parser exists" scaled up to "don't use an LLM when a function will do").
- **Stated payoff** (VSIP's own phrasing, consistent with general engineering practice): reproducibility, auditability, explainability, lower operational cost, easier debugging — all properties that are harder to get once a probabilistic model call is in the path.
- **Why conditional, not universal**: this principle is only a live design *choice* — something a project must actively decide — when the project has an LLM/agent component in the first place and a design decision-point exists over whether to route a given task through it. For a project with no model in the loop, the principle collapses to the unremarkable "write code, don't invent an LLM dependency" and isn't worth calling out separately.

---

## Explicitly out of scope

- **Specific vendor/tool recommendations** (which observability backend, which plugin framework, which RAG evaluation SaaS) — this is a principles baseline, not a buy/build guide; tool choice is downstream of the project's actual constraints and would date quickly.
- **Detailed threat-modeling methodology (STRIDE, PASTA, etc.)** — security-by-design is included as a principle family, but a full threat-modeling walkthrough is its own topic, not an "architecture principle" at this altitude.
- **Deep RAG-system design (chunking strategy, embedding model choice, hybrid search tuning)** — only the provenance/relevance-confidence *principle* is in scope; RAG implementation mechanics belong in a stack-specific reference, not this cross-cutting one.
- **SRE operational practice (on-call, incident response runbooks, postmortem templates)** — reliability *as an architecture principle* (state your SLO, treat complexity as a reliability cost) is in scope; the operational playbook around it is not.
- **CI/CD pipeline design specifics** — referenced as a dependency of TDD/SDD ("tests gate the build") but not elaborated as its own principle family here.
- **License/legal/compliance architecture** (data residency, GDPR-by-design, etc.) — adjacent to security-by-design but a distinct, large topic; flagging as a candidate for a future baseline rather than folding in here.

---

## Sources

- https://12factor.net/config — establishes the Config factor: strict separation of environment-varying config from code, via environment variables, with the "could open-source the codebase without leaking credentials" litmus test — retrieved 2026-08-19
- https://owasp.org/www-project-secure-by-design-framework/ — OWASP Secure-by-Design Framework (draft v0.5.0, Aug 2025): design-time security guidance structure (process, principles across 6 domains, review checklist, best-practice catalog) — retrieved 2026-08-19
- https://owasp.org/Top10/2025/A06_2025-Insecure_Design/ — OWASP Top 10:2025 category on insecure design, establishing design/architecture-level security flaws as a distinct risk category from implementation bugs — retrieved 2026-08-19
- https://www.evidentlyai.com/llm-guide/rag-evaluation — concrete retrieval-relevance scoring methods (Precision@k, Recall@k, NDCG@k, Hit Rate, LLM-judge per-chunk scoring) and explicit statement that no universal confidence threshold exists — retrieved 2026-08-19
- https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices — Thoughtworks' definition of spec-driven development, its relationship to TDD, effective spec structure, and why it emerged in 2025 as a response to vibe-coding drift — retrieved 2026-08-19
- Anthropic engineering blog, "Effective harnesses for long-running agents" (published 26 Nov 2025) — establishes the harness-as-architectural-unit framing, the initializer/coding-agent pattern for long-running tasks, and "every component in a harness encodes an assumption about what the model can't do on its own" — located via web search (businessdatasolutions.github.io mirror + daily.dev summary), original at anthropic.com engineering blog — retrieved 2026-08-19
- arXiv 2606.04990, "From Agent Traces to Trust: A Survey of Evidence Tracing and Execution Provenance in LLM Agents" — survey establishing current taxonomy of provenance approaches in LLM agents (A-MEM, ALCE, SourceCheckup, FActScore-style verification, provenance graphs for tool-call auditing) — retrieved 2026-08-19 (fetch of full PDF exceeded tool size limit; summarized from search-result abstracts/titles)
- arXiv 2412.14457, "VISA: Retrieval Augmented Generation with Visual Source Attribution" — establishes vision-based provenance (bounding-box source attribution in document images) as a current research direction — retrieved 2026-08-19
- Search-result synthesis on OpenTelemetry (CNCF graduation May 2026; three-to-four-pillars model; vendor-neutral adoption across Datadog/New Relic/Grafana/Honeycomb/Dynatrace/Splunk) — retrieved 2026-08-19 (aggregated from multiple 2025-2026 observability-vendor blog posts; treat vendor-list specifics as illustrative, the OTel-graduation/four-pillar claims as the load-bearing facts)
- Search-result synthesis on SRE principles (error budgets, SLI/SLO, complexity as reliability risk) consistent with Google's public SRE book framing — retrieved 2026-08-19
- Search-result synthesis on plugin architecture / Dependency Inversion Principle as the SOLID basis for pluggability — retrieved 2026-08-19
- Search-result synthesis on TDD 2025 best practices (red-green-refactor, AAA structure, mutation-score-over-coverage-percentage) — retrieved 2026-08-19
- Search-result synthesis on KISS/YAGNI/DRY as maintainability principles, including the caution that they require surrounding architecture/testing/governance to deliver value — retrieved 2026-08-19
- `C:\Users\devop\GitHub\VSIP\VSIP_Architectural_Addendum.md` (local file, read in full) — used only as a *style* reference for principle phrasing/structure, and as the origin of the generalized "determinism-first" principle (its #5), explicitly not treated as authoritative content since VSIP is an unimplemented, shelved strategy doc — read 2026-08-19

**Caution on WebSearch-tool summaries**: several queries returned auto-generated summary paragraphs containing specific-sounding statistics (e.g., "83% of enterprise RAG deployments include citation functionality," a named "RAG Citation Consortium," an "EU AI Act... effective February 2026" citation mandate) that could not be traced to any of the actual URLs returned alongside them. These were treated as unverified and excluded from the baseline above. Any number in this document is sourced to a URL that was directly fetched and read, not to a search-summary claim.

---

## Open questions for the user

1. **Depth calibration**: the "depth" column above guesses section-level treatment for most families and paragraph-level for the three added structural principles (testability, maintainability, determinism-first). Does that match what the eventual skill needs, or should some be compressed to checklist items only?
2. **LLM-conditional gating mechanism**: how should the eventual skill *detect* whether a project has an LLM/agent component, to decide whether to apply the harness/model-switching/provenance/relevance-confidence section at all? (e.g., ask the user directly during incubation vs. infer from stated project description vs. always ask-then-skip)
3. **SDD's maturity**: SDD is real and actively tooled (GitHub Spec Kit, AWS Kiro, etc.) but is genuinely newer and less settled than TDD — is it meant to be presented in the final skill with the same authority as TDD, or flagged as "emerging practice, apply with more judgment"?
4. **Security-by-design and the two other added families (testability, maintainability) and determinism-first**: confirmed as worth adding, or should any be cut/merged before the human-authored skill stage? In particular, determinism-first overlaps somewhat with the LLM-specific section — keep as a standalone principle or fold into it?
5. **Scope boundary on reliability**: the baseline draws a line between "state your SLO" (in scope, architecture-level) and "on-call/incident-runbook practice" (out of scope, operational). Does that boundary match where the project-incubation skill should stop?
6. **Relevance/confidence numeric guidance**: current sources explicitly refuse to name a universal threshold (recommending a domain-specific calibration set instead). Should the eventual skill still offer a rough starting-point number (e.g., the 0.7/0.5 precision@k anchor found above) for projects too early-stage to build a calibration set, or leave it fully open-ended per the sources?

## Resolutions (Checkpoint A review, 2026-08-19)

- **LLM-component detection**: ask explicitly during inception ("does this
  project include an LLM or agent component?"), captured in the baseline
  record. **Re-checked on every audit-mode invocation too** — not a
  one-time answer. If the project's LLM status has changed since the last
  baseline (either direction), the skill flags the drift, updates the
  baseline record, and applies/retires the conditional LLM-specific
  principles section accordingly. This is a SKILL.md flow requirement, not
  just a content note — carry it into Phase 2 authoring.
- **Depth calibration**: keep as drafted (section-depth for the 11 named
  families, paragraph-depth for the 3 added structural ones).
- **SDD authority**: present as emerging/actively-tooled practice, applied
  with more judgment than TDD — not equal footing. Keep the "conditional,
  not yet universal" framing already in the draft.
- **Added families** (security-by-design, testability, maintainability/
  simplicity, determinism-first): confirmed as-is. Determinism-first stays
  a standalone principle (cross-referenced from, not folded into, the
  LLM-specific section) since it applies whenever a project has an LLM
  component, independent of whether provenance/relevance-scoring apply.
- **Reliability scope boundary**: confirmed — SLO/target-setting in scope,
  on-call/incident-runbook operational practice out of scope.
- **Relevance/confidence numeric anchor**: offer the researched anchor
  (~0.7+ precision@k for narrow domains, ~0.5+ for broad domains) as an
  explicit starting point for projects too early to build a calibration
  set — clearly caveated as illustrative, not a validated universal
  threshold, per the sources' own refusal to name one.

## Target file(s) + estimated length

- `skills/project-incubation/references/architecture-principles.md` — est. 450-550 lines (11 principle families at section/paragraph depth, each with definition + why + concrete practice notes + universal/conditional tag; roughly 2-3x the length of this baseline once examples/checklists are fleshed out for skill consumption)
