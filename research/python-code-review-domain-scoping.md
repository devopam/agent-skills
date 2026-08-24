# Domain Scoping: python-code-review comprehensive coverage
Status: draft      Date: 2026-08-24

## Purpose

Before per-domain research/authoring begins on the portable python-code-review
skill, this pass checks whether the 9 already-decided domains are genuinely
comprehensive, against established taxonomies (linters, security checklists,
engineering-org review guides). Goal: find real gaps, not confirm convenience.

## Confirmed gaps requiring a new dedicated domain

- **Dependency & Supply Chain Security** — impact: high. Distinct reviewer
  lens from Security (which asks "is this code's own logic exploitable") and
  from Standards Compliance (which asks "is the build/tooling config
  correct"). This domain asks "can the artifacts, dependencies, and pipeline
  that produce this code be trusted/tampered with" — provenance thinking, not
  runtime-vulnerability thinking. Grounded in: SLSA's Build Track (provenance,
  tamper-evidence, factory-stamped artifacts — explicitly scoped as
  complementary to but distinct from SBOMs and from "did developers write
  secure code"); the OWASP CI/CD Security Top 10, a mature 10-category
  taxonomy (Insufficient Flow Control, Inadequate IAM, **Dependency Chain
  Abuse**, **Poisoned Pipeline Execution**, Insufficient PBAC, Insufficient
  Credential Hygiene, Insecure System Configuration, Ungoverned 3rd-Party
  Services, **Improper Artifact Integrity Validation**, Insufficient
  Logging/Visibility) that the current "CI/CD config = one checkbox" treatment
  in Standards Compliance cannot absorb without becoming its own section
  anyway; and Bandit's own check set going beyond code-injection into
  source-integrity (B613, Unicode/trojan-source bidi attacks) and
  model-artifact supply chain (B614 unsafe PyTorch deserialization, B615
  unsafe Hugging Face model downloads) — evidence that even a
  general-purpose Python linter treats "can I trust what I'm importing/
  loading" as a category separate from "is this code logic safe."
  Subsections: SBOM generation/consumption, vulnerability-database
  integration beyond pip-audit/safety (OSV, GHSA), license-compatibility
  across the transitive dependency tree, lockfile discipline, CI/CD pipeline
  security (pinned actions/base images, credential hygiene in pipeline logs,
  poisoned-pipeline-execution vectors, artifact signing/attestation), and —
  conditionally, only when the project loads ML model artifacts — safe
  deserialization of pickled/PyTorch/HF model files.
  **Boundary with Standards Compliance**: Standards Compliance owns "is the
  build/tooling config correct" (pyproject.toml conventions, packaging
  metadata, CI/CD config *existing and well-formed*); this domain owns "are
  the dependencies, artifacts, and pipeline *trustworthy*" (vuln scanning,
  provenance, pipeline security). Recommended review order: adjacent to
  Security and Standards Compliance, not appended at the tail.

- **Concurrency & Async Correctness** — impact: high. Distinct reviewer lens
  from Performance: Performance asks "is it fast" (throughput, caching,
  connection pooling); this domain asks "is it correct under concurrent
  execution" (races, deadlocks, cancellation bugs) — the same categorical
  split that already justifies Security and Performance being separate
  domains rather than one "non-functional concerns" bucket. Grounded in: a
  dedicated Ruff category, `flake8-async (ASYNC)`, for async/await
  anti-patterns, distinct from `Perflint (PERF)`; PEP 703 (the free-threading/
  optional-GIL CPython build), which documents a real, citable class of new
  thread-safety obligations — C-extensions and code that implicitly relied on
  the GIL for correctness need explicit locking, borrowed-reference patterns
  become unsafe, destructor/weakref timing changes. Note: PEP 703 describes
  `--disable-gil` as an opt-in build variant as of the PEP text; we did not
  verify its current default/stable status post-cutoff, so the domain's
  impact rating rests primarily on asyncio's ubiquity in modern Python
  (FastAPI and most current web/service frameworks) and the existing
  `ASYNC` rule category, with free-threading correctness treated as an
  emerging additional driver rather than the load-bearing justification.
  Subsections: asyncio pitfalls (forgotten `await`, fire-and-forget tasks
  garbage-collected mid-flight, blocking calls inside async functions),
  structured concurrency (`TaskGroup`, cancellation propagation, exception
  groups), race conditions and deadlocks in threaded code, GIL-reliant code
  that breaks under free-threaded builds, and thread-safety of shared mutable
  state.
  **Boundary with Performance**: Performance keeps throughput/caching/
  connection-pooling/GIL-as-throughput-bottleneck; this domain takes
  correctness bugs under concurrency — races, deadlocks, await hygiene,
  cancellation semantics, free-threading thread-safety. State this move
  explicitly in Performance's scope note so the two domains don't duplicate
  checks. Recommended review order: immediately adjacent to Performance.

## Confirmed gaps requiring expansion within an existing domain

- **Code Quality** — static type-checking rigor — impact: medium-high.
  Current "type annotations present" framing is far short of what mature
  tooling treats as a graduated discipline: mypy strict-mode adoption
  (`disallow_untyped_defs`, `no_implicit_reexport`, per-module strictness
  ramps rather than all-or-nothing), pyright as an alternative checker,
  type-coverage tooling, and — concretely, from Ruff's `flake8-pyi (PYI)`
  category and the `py.typed` marker convention — whether a library correctly
  declares itself typed for consumers at all (this sits on the boundary with
  packaging; keep the *type-correctness* checks here and the *packaging
  declaration* checks in Standards Compliance). Also fold in Ruff's
  `flake8-annotations (ANN)` and `flake8-type-checking (TC)` categories
  (annotation presence/placement, `TYPE_CHECKING`-gated imports).

- **Security** — LLM-specific coverage beyond prompt injection — impact:
  medium (high for projects that are LLM-integrated). The domain currently
  names only prompt injection; the OWASP Top 10 for LLM Applications has ten
  categories, several of which are genuinely code-review-checkable and
  currently unlisted: **Insecure Output Handling** (treating LLM output as
  trusted input to downstream code/templates/shell), **Excessive Agency**
  (unchecked tool/function-calling permissions), **Sensitive Information
  Disclosure** (secrets/PII leaking into prompts or logs), and **Supply
  Chain Vulnerabilities** for models/plugins (overlaps the new Supply Chain
  domain's conditional model-artifact subsection — cross-reference rather
  than duplicate). Training-data poisoning, model theft, and model-DoS are
  training/infra concerns out of scope for a code-review skill — reject
  those three explicitly rather than silently dropping them.

- **Security** — configuration & secrets management as its own subsection —
  impact: medium. Currently split thinly between "hardcoded secrets"
  detection and Standards Compliance's `.env` checklist item. Real gap:
  12-factor config discipline (config from environment, not code), secret
  *rotation* patterns (not just absence of hardcoded values), and
  vault/KMS integration correctness (is the secret fetched at runtime from a
  managed store rather than baked into an image/config file). This is a
  security-lens question (trust boundary of where secrets live) so it stays
  in Security, not a new domain.

- **Architecture** — API/interface design & backward-compatibility — impact:
  medium. Current "API Design" subsection is scoped narrowly to web APIs.
  Real gap for any project with an importable public interface (which is
  most Python projects, not just web services): semver discipline,
  deprecation patterns (`DeprecationWarning` usage, migration windows),
  docstring-as-contract, and — concretely, from Ruff's
  `flake8-boolean-trap (FBT)` category — signature-design smells like
  boolean positional parameters that break call-site readability and
  silently invert behavior across versions. This is the same
  structural/interface reviewer lens Architecture already uses, so it's an
  expansion, not a new domain.

- **Standards Compliance** — packaging & distribution — impact: medium,
  conditional on the reviewed project being a publishable library. Grounded
  in the breadth of PyPA's own packaging guide topic set (pyproject.toml
  build-backend config, wheel/sdist building, binary-extension compilation,
  namespace packages, `py.typed` declaration, TestPyPI staging, trusted
  publishing/OIDC to PyPI vs. long-lived API tokens, README rendering,
  setup.py-to-pyproject.toml modernization, licensing declaration) — this is
  currently compressed into a single "pyproject.toml conventions" line and
  deserves its own subsection when (and only when) the target is a
  distributable package, not every reviewed codebase. Keep this in Standards
  Compliance (build/tooling config correctness) rather than the new Supply
  Chain domain (dependency/artifact trustworthiness) — see boundary note
  above.

- **Testing** — external corroboration that the domain (already decided,
  not yet researched) is a recognized, non-arbitrary category, not just an
  internally-added afterthought: Ruff maintains a dedicated
  `flake8-pytest-style (PT)` rule category for pytest idioms/fixture
  conventions, independent evidence the ecosystem treats test-code quality
  as its own reviewable dimension. No further scoping claim made here —
  per-domain research for Testing is explicitly out of scope for this pass.

## Considered and rejected (not a real gap, or too niche/out of scope)

- **Separate "Documentation" domain** — Google's engineering-practices guide
  lists Documentation/Comments as review dimensions, but the reviewer lens
  (readability/maintainability of what's written) is identical to Code
  Quality's existing "naming, docs" scope. Fold in, don't split out.
- **Separate "Licensing compliance" domain** — SPDX headers and dependency
  license conflicts are real (Ruff even has `flake8-copyright (CPY)`), but
  the concern is small enough to be one subsection of the new Supply Chain
  domain (license-compatibility across the dependency tree) rather than a
  domain of its own.
- **Separate "Database/Migrations" domain** — schema migration safety and
  transaction boundaries are real concerns but share Architecture's
  structural lens (and Performance's connection-pooling/N+1 coverage
  already touches the data layer). Expand within Architecture's existing
  "DB segregation" framing instead of splitting out.
- **Separate "Data Privacy / PII / GDPR" domain** — real but housed
  correctly under Security's data-handling lens already; folded into the
  Security "sensitive information disclosure" expansion above rather than
  standing alone.
- **Internationalization/localization (i18n/l10n)** — Ruff has a dedicated
  `flake8-gettext (INT)` category, so it's a recognized linter concern, but
  it's relevant only to i18n-heavy projects and is a poor fit for a
  general-purpose Python review skill's default scope. Reject as too niche.
- **Accessibility** — a first-class concern for frontend code review
  checklists, but this skill reviews Python (predominantly backend/service/
  library code); reject as largely inapplicable to the target surface.
  Revisit only if the skill's scope ever extends to Python-rendered UI.
- **ML / AI model development and training concerns** (fine-tuning,
  experiment tracking, training-data quality) — explicitly out of scope,
  consistent with this same repository's own `research/taxonomy-roadmap.md`,
  which already carves "ML / AI Model Development" and "MLOps / ML Platform
  Engineering" out as separate future *stack categories* distinct from
  general application review. Don't re-absorb that scope here; the
  conditional model-artifact-deserialization subsection under the new
  Supply Chain domain is the only ML-adjacent surface this skill should own.
- **Framework-specific rule categories** (Django, pandas, NumPy, FastAPI, Airflow
  — all present as dedicated Ruff categories) — real and mature, but belong to
  a stack-specific overlay, not the general-purpose domain list. Reject at
  this scoping level; note as a candidate for future stack-specific
  supplementary checklists, mirroring how `research/stacks/` already
  specializes other skills per project archetype.
- **Concurrency as a Performance subsection rather than a new domain** —
  considered and rejected in favor of the new-domain call above; documented
  here to record that the "fold it in" option was weighed, not overlooked.

## Sources

- https://google.github.io/eng-practices/review/reviewer/looking-for.html — Google's code-review dimension list (Design, Functionality, Complexity, Tests, Naming, Comments, Style, Consistency, Documentation) — used to confirm existing domains cover established review dimensions and that Documentation doesn't need to split out — retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/ — full Ruff rule-category list (59 categories) — primary source for identifying ASYNC, PYI, ANN, TC, FBT, PT, CPY, INT, and framework-specific categories as gap/non-gap evidence — retrieved 2026-08-24
- https://bandit.readthedocs.io/en/latest/plugins/index.html — Bandit check plugin categories (B1xx misc, B2xx framework misconfig, B5xx crypto, B6xx injection, B7xx XSS) — source for B613 (trojan source), B614/B615 (model deserialization) supply-chain evidence — retrieved 2026-08-24
- https://pylint.readthedocs.io/en/latest/user_guide/checkers/features.html — pylint's Fatal/Error/Warning/Refactor/Convention/Info category structure — confirmed no new domain signal beyond what's already in Code Quality — retrieved 2026-08-24
- https://owasp.org/www-project-top-10-for-large-language-model-applications/ — OWASP Top 10 for LLM Applications (v1.1), full 10-category list — source for Security's LLM-coverage expansion and for explicitly rejecting training-poisoning/model-theft/model-DoS as out of scope — retrieved 2026-08-24
- https://owasp.org/www-project-top-10-ci-cd-security-risks/ — OWASP Top 10 CI/CD Security Risks, full 10-category list — primary justification for folding CI/CD pipeline security into the new Supply Chain domain rather than leaving it a single Standards Compliance checkbox — retrieved 2026-08-24
- https://slsa.dev/spec/v1.0/about — SLSA Build Track scope (provenance, tamper-evidence, build-platform attestation) and explicit statement that SLSA does NOT evaluate secure coding practices or (in v1.0) transitive dependency verification — used to scope what "supply chain" means as a reviewer lens distinct from Security — retrieved 2026-08-24
- https://peps.python.org/pep-0703/ — PEP 703 (making the GIL optional / free-threading), full text — source for the new thread-safety-obligation class justifying the Concurrency domain; note in-text that we could not verify free-threading's current (post-cutoff) default/stable status, so this citation supports the *concern class*, not a claim about current CPython defaults — retrieved 2026-08-24
- https://packaging.python.org/en/latest/guides/ — PyPA packaging guide topic index (build/publish, pyproject.toml, wheels, namespace packages, TestPyPI, licensing) — source for the Standards Compliance packaging-and-distribution expansion — retrieved 2026-08-24
- https://mypy.readthedocs.io/en/stable/existing_code.html — mypy strict-mode adoption guidance (per-module strictness, `--strict` flag composition, gradual typing) — source for the Code Quality type-rigor expansion — retrieved 2026-08-24
- https://rules.sonarsource.com/python/ — **unreachable** (DNS failure, host not resolving). Retry attempted at https://docs.sonarsource.com/sonarqube-server/latest/user-guide/clean-code/introduction/ — also unreachable (404). SonarQube's Clean Code taxonomy (software qualities Security/Reliability/Maintainability crossed with attributes) was not independently verified for this pass; the domain list's cross-checking rests on the other sources above (Ruff/Bandit/pylint/OWASP/SLSA/PEP 703/PyPA/mypy), which collectively span the same ground SonarQube's taxonomy covers. Flagged here rather than silently omitted.
- `research/taxonomy-roadmap.md` (this repo) — internal precedent for scoping ML/AI model development and MLOps out of general-purpose review/stack coverage — retrieved 2026-08-24

## Recommended final domain list

1. **Standards Compliance** — project structure, tooling config, pyproject.toml
   conventions, and (new subsection, conditional on publishable libraries)
   packaging & distribution hygiene (build backend config, wheel/sdist
   correctness, `py.typed` declaration, trusted publishing).
2. **Code Quality** — types (now including static type-checking rigor: mypy
   strict-mode adoption, type-coverage discipline), complexity, naming, docs,
   dead code.
3. **Security** — OWASP-driven: injection, secrets, crypto, auth, and
   expanded LLM-specific coverage (prompt injection, insecure output
   handling, excessive agency, sensitive information disclosure), plus a
   dedicated configuration & secrets management subsection (12-factor
   discipline, rotation, vault/KMS integration).
4. **Dependency & Supply Chain Security** *(new)* — SBOM, vulnerability-
   database integration, license compatibility across the dependency tree,
   lockfile discipline, CI/CD pipeline security (pinned actions, credential
   hygiene, poisoned-pipeline-execution, artifact integrity/signing), and
   conditional model-artifact deserialization safety.
5. **Performance** — N+1 queries, connection pooling, caching, throughput —
   concurrency-as-throughput-bottleneck only; correctness-under-concurrency
   moved to domain 6.
6. **Concurrency & Async Correctness** *(new)* — asyncio pitfalls, structured
   concurrency/`TaskGroup`, race conditions, deadlocks, free-threading
   thread-safety.
7. **Idioms & Patterns** — Pythonic code, modern syntax, immutability.
8. **Architecture** — separation of concerns, DB segregation, API design
   (expanded: semver/deprecation/docstring-as-contract, not just web APIs),
   deployment.
9. **Observability** — logging, SLI/SLO, tracing, metrics.
10. **Scalability & Resilience** — HA, DR, horizontal scaling, circuit
    breakers, graceful degradation.
11. **Testing** — coverage, fixture/mock quality, test isolation (still
    unresearched in depth; scoping only confirms it as a legitimate,
    externally-recognized domain).

Net result: **9 domains plus 2 real gaps requiring new domains (11 total)**,
plus 6 confirmed expansions within existing domains, plus 8 items explicitly
considered and rejected.
