# Baseline: Dependency & Supply Chain Security
Status: user-approved      Date: 2026-08-24

## Purpose / boundary recap

This domain answers "can the artifacts, dependencies, and pipeline that
produce this code be trusted/tampered with" — provenance and chain-of-custody
thinking. It is distinct from:
- **Security** (`original-tool/review-domains/security.md`), which already
  owns a Critical-tier "don't unpickle untrusted input" rule and an
  Important-tier "Dependency Security (supply chain)" subsection (pinning,
  `pip-audit`/`safety`/`osv-scanner` in CI, no unpinned transitive deps,
  integrity hashes, no deprecated packages) plus a Minor-tier "SBOM
  generation" line. This domain absorbs and deepens all of that — Security's
  own research pass should narrow its dependency mention to a cross-reference
  rather than duplicate the depth here.
- **Standards Compliance** (`original-tool/review-domains/standards-compliance.md`),
  which — checked directly — has **no CI/CD line item in its Review Criteria
  body at all**; the only trace is a tier-applicability table row
  (`CI/CD config | No | Optional | Yes`) with zero elaboration. This domain
  owns pipeline *trustworthiness* (pinned actions, credential hygiene,
  poisoned-pipeline-execution vectors, artifact integrity); Standards
  Compliance keeps "does CI/CD config exist and is it well-formed."

## In scope

- **SBOM generation/consumption, format choice** — impact: med — depth: paragraph.
  PEP 770 (Final, accepted) is the authoritative Python-ecosystem answer to
  "CycloneDX or SPDX" and it deliberately **declines to pick a winner**: it
  reserves a `.dist-info/sboms/` directory in wheels for bundled-component
  SBOMs (solving the "phantom dependency" problem — compiled/non-Python
  libraries invisible to standard packaging metadata) and recommends SBOM
  documents "SHOULD use a widely-accepted SBOM standard, such as CycloneDX or
  SPDX" without requiring either. The one concrete tool-adoption signal found:
  `cyclonedx-python` is CycloneDX's own official, OSI-approved generator,
  explicitly generating "CycloneDX SBOMs from Python (virtual) environments,
  requirement files, and manifests (Poetry, PipEnv, etc.)" — i.e. CycloneDX
  has a first-party Python-specific tool where SPDX's own site did not surface
  an equivalent in this pass (see Open Questions). Checklist framing should be
  format-agnostic: "does an SBOM get generated in CI in a widely-accepted
  format," not "is it CycloneDX specifically."

- **Vulnerability-database integration (OSV, GHSA, pip-audit)** — impact:
  high — depth: section. `safety` (pyup.io's commercial/freemium scanner,
  named in the task and already present in `security.md`'s Important tier)
  was **not independently fetched against a primary source in this pass** —
  it's kept in scope by inheritance from the existing tool, not because this
  research verified its current DB/CLI behavior; treat any claim about it as
  unverified until a follow-up fetch of its own docs happens. The three
  sources fetched directly (OSV, GHSA, pip-audit) are heavily
  overlapping views of the same underlying Python data, not independently
  stacking coverage:
  - `pip-audit` defaults to the **PyPI JSON API**, which itself serves the
    **Python Packaging Advisory Database** (`pypa/advisory-database`); it can
    also query **OSV** directly via `-s osv` / `PIP_AUDIT_VULNERABILITY_SERVICE`.
  - **GHSA** (GitHub Advisory Database) publishes advisories in OSV format and
    pulls from the same `pypa/advisory-database` for Python, plus
    NVD/CVE-derived entries and GitHub Security Lab-reviewed community
    submissions.
  - **OSV** is explicitly an *aggregator* — its own site states it aggregates
    "vulnerability databases that have adopted the OSV schema, including
    GitHub Security Advisories," across 40+ ecosystems (PyPI: 24,507 entries
    at fetch time), so GHSA data flows into OSV for PyPI too.
  Reviewer-relevant conclusion: the checkable question is "is at least one
  scanner wired into CI against this shared advisory graph," not "are all
  three integrated" — running `pip-audit` (PyPI or OSV service) *and* GHSA
  (via Dependabot/`gh` alerts) covers materially the same ground twice, which
  is fine as defense-in-depth but shouldn't be scored as if it were broader
  coverage.

- **License-compatibility checking across the dependency tree** — impact:
  med — depth: paragraph. Two distinct, non-overlapping facts:
  - PEP 639 (Final) standardizes SPDX license-expression syntax in core
    metadata via a new `License-Expression` field (e.g.
    `"MIT AND (Apache-2.0 OR BSD-2-Clause)"`), explicitly deprecating both the
    old unstructured `License` field and `License ::` Trove classifiers. A
    checkable signal: does the project's `pyproject.toml` use
    `License-Expression` (current) vs. legacy classifiers (deprecated)?
  - `pip-licenses` (current: 5.5.5) **enumerates only** — it lists installed
    packages' licenses (via metadata/Trove classifiers) in many output
    formats and supports policy gates (`--fail-on`, `--allow-only`), but does
    **not** perform actual compatibility analysis (e.g. "does this GPL dep
    conflict with that MIT dep in a distributed binary"). No primary-sourced
    Python tool doing true transitive compatibility analysis was found in
    this pass — flag this gap rather than assert a tool exists (see Open
    Questions).

- **Lockfile discipline** — impact: high — depth: section. The landscape has
  a real 2025 inflection point: PEP 751 (Final, accepted 2025-03-31)
  standardizes **`pylock.toml`**, a vendor-neutral TOML lock format that:
  mandates hashes for every recorded file (multiple algorithms supported),
  supports environment-marker-based cross-platform resolution and multi-use
  lockfiles (extras/dependency groups), records file provenance (URL/VCS/local
  path), and is explicitly designed so tool-specific "lockers" (uv, Poetry,
  PDM) can *export* to it for interop with "installers" — it does not replace
  those tools' native lock formats, which remain mutually incompatible today.
  Per-tool state as verified:
  - **`uv.lock`**: performs **universal resolution by default** — one
    lockfile portable across platforms and Python versions, using markers to
    select the right version per platform (confirmed from uv's own resolution
    docs). Freshness is checkable in CI via `uv lock --check` (equivalent to
    `--locked`) or enforced via `uv sync --locked`/`--frozen`. Whether
    `uv.lock` itself embeds hashes was **not confirmed** from the docs pages
    fetched in this pass (see Open Questions) — do not assert it without a
    follow-up check.
  - **`poetry.lock`**: Poetry's own docs explicitly recommend committing it
    for applications ("cause anyone who sets up the project to use the exact
    same versions") and leave it optional for libraries (a library's lock
    file has no effect on downstream consumers). Hash content was **not
    confirmed** from the docs fetched (see Open Questions).
  - **`requirements.txt` + hashes**: pip's documented `--require-hashes` mode
    is the one lockfile-adjacent mechanism with a fully verified security
    mechanism: once any `--hash` is present, hashes become mandatory for
    *every* requirement including transitive ones; all requirements must be
    pinned (`==`, URL, or path — no loose ranges); SHA256+ required, MD5/SHA1
    rejected. This is pip's answer to reproducible, tamper-evident installs
    without adopting a project-management tool.
  Checklist framing: does a lockfile exist and is it committed; if
  `requirements.txt`-only, is `--require-hashes` actually enforced in CI (not
  just a hash-annotated file sitting unused); is the lockfile checked for
  staleness in CI (`uv lock --check` or equivalent), not just present at some
  point in the past.

- **CI/CD pipeline security** — impact: high (largest topic area; splits
  into four in-scope entries below by depth, all grounded in OWASP Top 10
  CI/CD Security Risks **v1.0, released October 2022** — confirmed current
  at fetch time, but a newer edition was not ruled out; see Open Questions,
  WebSearch budget was exhausted before a dedicated versioning check could
  run). Full 10-category list: Insufficient Flow Control, Inadequate IAM,
  **Dependency Chain Abuse**, **Poisoned Pipeline Execution**, Insufficient
  PBAC, Insufficient Credential Hygiene, Insecure System Configuration,
  Ungoverned 3rd-Party Services, Improper Artifact Integrity Validation,
  Insufficient Logging/Visibility.

  - **Dependency Chain Abuse + Poisoned Pipeline Execution named patterns**
    — impact: high — depth: table (pattern/condition columns, not a flat
    checklist — see the two taxonomies below).
  - **Pinned GitHub Actions** — impact: high — depth: checklist.
  - **Credential hygiene in pipeline logs** — impact: high — depth:
    checklist.
  - **Base-image pinning** — impact: med — depth: paragraph (a genuine
    trade-off, not a binary check — see below).
  - **Artifact signing/attestation (PyPI Trusted Publishing + Digital
    Attestations)** — impact: high — depth: section.

  Two named risks decompose into checkable sub-patterns, fetched directly
  from OWASP's own per-risk pages:

  **Dependency Chain Abuse (CICD-SEC-3)** — four named attack patterns:
  - *Dependency confusion* — malicious public package published under the
    same name as an internal/private package.
  - *Dependency hijacking* — attacker compromises a legitimate maintainer's
    account and ships a malicious version under the trusted name.
  - *Typosquatting* — malicious package published under a name similar to a
    popular one, betting on developer misspelling.
  - *Brandjacking* — malicious package published following a specific brand's
    naming convention to impersonate it.
  Checkable preventive controls OWASP lists: route installs through an
  internal proxy / pre-vetted internal repository rather than direct public
  access; enable checksum/signature verification on fetched packages; pin to
  stable versions (never `latest`/unpinned ranges); register private/internal
  packages under an organizational namespace/scope; isolate
  install-script execution from secrets; don't leak internal package names in
  public repos; have detection/monitoring for anomalous package changes.

  **Poisoned Pipeline Execution (CICD-SEC-4)** — three named variants:
  - *Direct PPE (D-PPE)* — attacker with repo write access (or via an
    unreviewed PR) modifies the CI config file itself to run malicious steps.
  - *Indirect PPE (I-PPE)* — CI config is protected, so the attacker instead
    poisons a file the pipeline *executes* (Makefile, test script, linter
    config, build script) to achieve the same effect.
  - *Public/3rd-party PPE (3PE)* — a public repo accepts PRs from anonymous
    contributors and runs CI against unreviewed code, letting an anonymous
    attacker trigger pipeline execution — worse when that CI shares runners/
    secrets with private projects.
  Checkable condition for all three: does the pipeline execute anything
  (config, Makefile target, test/lint step) sourced from a branch or PR the
  repo owner doesn't control, without a human-approval gate first.

  **Pinned GitHub Actions** — GitHub's own hardening guide: pinning to a
  **full-length commit SHA is "the only way to use an action as an immutable
  release"** — an attacker would need a SHA-1 collision to forge it, which is
  computationally infeasible; pin to a *tag* only when the action's creator is
  trusted, since tags/branches can be moved or deleted if the upstream repo is
  compromised. Rationale given: "a compromise of a single action within a
  workflow can be very significant, as that compromised action would have
  access to all secrets configured on your repository."

  **Credential hygiene in pipeline logs** (Security's Minor tier already has
  gitleaks/trufflehog *secret-scanning*; this is the narrower, distinct
  concern of *runtime log leakage during execution*, not source-committed
  secrets) — from GitHub's hardening guide: never hardcode sensitive values in
  workflow YAML; use `::add-mask::VALUE` to redact non-secret sensitive
  output; register any sensitive value generated at runtime (e.g. a minted
  JWT) as a secret so GitHub auto-redacts it from logs; prefer OIDC-issued
  short-lived cloud credentials over long-lived stored secrets; set the
  default `GITHUB_TOKEN` permission to read-only and elevate per-job only as
  needed (least privilege).

  **Base image pinning** — Docker's own best-practices doc frames this as a
  real trade-off, not a one-directional "always pin harder" rule: pinning
  `FROM image@sha256:...` to a digest guarantees reproducibility and an audit
  trail, but **opts out of automatic security patches** that a moving tag
  (e.g. `alpine:3.21`) would otherwise pick up; Docker's own recommendation is
  automated digest-update tooling (they cite Docker Scout) that pins for
  reproducibility while still surfacing/PR-ing patch updates rather than
  silently drifting. State both sides in the checklist rather than a flat
  "always pin to digest" rule.

  **Artifact signing/attestation** — PyPI's own mechanism (verified directly
  from `docs.pypi.org`, not a secondary source): **Trusted Publishing** uses
  OIDC to let CI systems (GitHub Actions, GitLab CI/CD, Google Cloud) exchange
  a short-lived identity token for a **15-minute PyPI upload token**, replacing
  long-lived manually-managed API tokens whose compromise is usable "until
  its legitimate user notices and manually revokes it." Layered on top,
  **Digital Attestations** let a package be cryptographically signed at
  upload using the **in-toto Attestation Framework**, with two accepted
  predicate types: **SLSA Provenance** and **PyPI Publish attestations**
  (proof of publication via a specific Trusted Publisher); this is currently
  **optional**, not mandatory, and tied to having Trusted Publishing already
  configured. Scope boundary: **cosign** is an OCI/container-image signing
  tool, not part of PyPI's package-attestation mechanism — relevant to this
  domain only when the reviewed project *also* ships container images (then
  it's a deployment-artifact concern, cross-reference rather than duplicate
  into container-specific tooling this skill doesn't otherwise cover).
  Whether Sigstore's transparency-log infrastructure specifically underlies
  PyPI's attestation feature could not be verified directly in this pass
  (sigstore.dev renders via JS and returned no content; two candidate
  blog-post URLs 404'd) — see Open Questions, do not assert the Sigstore
  connection as fact without a follow-up fetch.

- **Conditional: safe deserialization of ML model artifacts** — impact: high
  (conditional — only when the project loads pickle/PyTorch/HuggingFace model
  files) — depth: section. Verified directly from Bandit's own plugin docs,
  each with CWE, severity, and confidence as documented:
  - **B614 (`pytorch_load`)** — flags `torch.load`/`torch.serialization.load`
    on untrusted data; CWE-502 (Deserialization of Untrusted Data); Medium
    severity / High confidence; introduced Bandit 1.7.10. Remediation:
    `weights_only=True`, or the `safetensors` library instead of pickle-based
    weights. **Time-sensitive correction found in this pass**: PyTorch
    **flipped the default of `weights_only` between the 2.5 and 2.6
    releases** — confirmed by fetching both versions' own docs directly:
    2.5's parameter description defaults it to `False`, 2.6's defaults it to
    `True`. PyTorch's 2.6 docs now warn that `weights_only=False` "uses the
    `pickle` module implicitly, which is known to be insecure" and can
    "execute arbitrary code during unpickling." This
    means B614's classic remediation is now the *default* behavior on current
    PyTorch; the residual real risk is code that explicitly passes
    `weights_only=False`, or projects pinned to PyTorch <2.6. A checklist
    entry should say this precisely rather than imply every `torch.load` call
    is unsafe by default today.
  - **B615 (`huggingface_unsafe_download`)** — flags Hugging Face Hub
    downloads (`AutoModel.from_pretrained`, `AutoTokenizer.from_pretrained`,
    `load_dataset`, `hf_hub_download`, `snapshot_download`) that omit a
    `revision` pin or use a mutable one (`revision="main"`, a branch, a
    non-immutable tag); CWE-494 (Download of Code Without Integrity Check);
    Medium/High. Remediation: pin `revision=` to an immutable commit hash.
  - **B613 (`trojansource`)** — flags Unicode bidirectional control
    characters in source files (comments/strings) that can visually reorder
    code vs. its actual execution order (CVE-2021-42574); CWE-838; High
    severity / Medium confidence. **This is source-integrity, not
    model-artifact-specific** — file it as a general supply-chain/source-trust
    check in this domain, not inside the conditional ML subsection.
  **Boundary with Security**: Security's Critical tier already owns
  "`pickle.loads()`/`pickle.load()` on untrusted data" as an application-code
  pattern. This domain's conditional subsection owns the *specific* case that
  hub-fetched or checked-in model artifacts **are** untrusted-input in the
  same sense — pin revisions, prefer `safetensors`, and treat "loading a
  model file" as a deserialization trust boundary like any other, not a
  special exemption.

## Explicitly out of scope

- **cosign / OCI container image signing as a general topic** — excluded
  because it targets container images, not Python packages; PyPI's own
  in-toto/SLSA-based attestation mechanism is the on-topic equivalent for
  this skill's actual review surface (Python packages). Only becomes relevant
  if a reviewed project also builds/ships containers, and even then it's
  adjacent, not owned.
- **Comparative CycloneDX-vs-SPDX Python-ecosystem adoption statistics** —
  excluded; PEP 770 (the authoritative Python-packaging-standards source)
  deliberately declines to endorse one, and no primary source with real
  adoption numbers (not vendor marketing) was found. Asserting a winner would
  violate this baseline's own sourcing standard.
- **True transitive license-compatibility graph analysis** (a real
  SAT/graph-style conflict checker, as opposed to enumeration) — no
  primary-sourced current Python tool doing this was found; `pip-licenses`
  only enumerates + policy-gates by license string, it doesn't reason about
  compatibility between licenses.
- **Commercial/SaaS SCA tooling** (Snyk, Dependabot's paid tiers, etc.) — not
  fetched against primary docs in this pass; would need dedicated research
  before any claim about them is included, so they're absent rather than
  asserted from memory.
- **Full container/base-image supply-chain security beyond the pinning
  trade-off** (image scanning tools, registry attestation, runtime admission
  control) — out of scope for a Python-code-review skill; the one
  pipeline-security touchpoint (digest vs. tag pinning) is kept, the rest
  isn't.

## Sources

- https://owasp.org/www-project-top-10-ci-cd-security-risks/ — confirms OWASP Top 10 CI/CD Security Risks is at v1.0 (released October 2022) and lists all 10 categories — retrieved 2026-08-24
- https://owasp.org/www-project-top-10-ci-cd-security-risks/CICD-SEC-04-Poisoned-Pipeline-Execution — the three named PPE variants (D-PPE, I-PPE, 3PE) with conditions/examples — retrieved 2026-08-24
- https://owasp.org/www-project-top-10-ci-cd-security-risks/CICD-SEC-03-Dependency-Chain-Abuse — the four named DCA patterns (confusion, hijacking, typosquatting, brandjacking) and preventive controls — retrieved 2026-08-24
- https://bandit.readthedocs.io/en/latest/plugins/b613_trojansource.html — B613 full detail: CWE-838, High/Medium, TrojanSource/CVE-2021-42574 — retrieved 2026-08-24
- https://bandit.readthedocs.io/en/latest/plugins/b614_pytorch_load.html — B614 full detail: CWE-502, Medium/High, introduced in Bandit 1.7.10, weights_only/safetensors remediation — retrieved 2026-08-24
- https://bandit.readthedocs.io/en/latest/plugins/b615_huggingface_unsafe_download.html — B615 full detail: CWE-494, Medium/High, functions flagged, revision-pinning remediation — retrieved 2026-08-24
- https://docs.pytorch.org/docs/2.6/generated/torch.load.html — confirms `weights_only` defaults to `True` in PyTorch 2.6, with the pickle-arbitrary-code-execution warning in PyTorch's own words — retrieved 2026-08-24
- https://docs.pytorch.org/docs/2.5/generated/torch.load.html — confirms `weights_only` still defaulted to `False` in PyTorch 2.5, pinning the exact release boundary where the default changed — retrieved 2026-08-24
- https://docs.pypi.org/trusted-publishers/ — PyPI Trusted Publishing: OIDC mechanism, 15-minute short-lived tokens, replaces long-lived API tokens — retrieved 2026-08-24
- https://docs.pypi.org/attestations/ — PyPI Digital Attestations: in-toto framework, SLSA Provenance + PyPI Publish predicate types, tied to Trusted Publishers, optional — retrieved 2026-08-24
- https://pypi.org/project/pip-audit/ — confirms default PyPI-JSON-API service (backed by pypa/advisory-database) plus OSV service support via `-s`/env var; current version 2.10.1 — retrieved 2026-08-24
- https://osv.dev/ — OSV overview: 40+ ecosystems, OSV schema, explicit aggregator role including GHSA — retrieved 2026-08-24
- https://docs.github.com/en/code-security/security-advisories/working-with-global-security-advisories-from-the-github-advisory-database/about-the-github-advisory-database — GHSA sourcing (pypa/advisory-database, NVD/CVE, GitHub Security Lab review) and OSV-format publication — retrieved 2026-08-24
- https://pypi.org/project/pip-licenses/ — pip-licenses is enumeration-only (current version 5.5.5), output formats, `--fail-on`/`--allow-only` policy gates — retrieved 2026-08-24
- https://peps.python.org/pep-0639/ — SPDX license-expression standardization (`License-Expression` field), Final status, deprecates classifiers — retrieved 2026-08-24
- https://pip.pypa.io/en/stable/topics/secure-installs/ — `--require-hashes` mechanics: all-pinned, hashes mandatory for transitive deps too, SHA256+ only — retrieved 2026-08-24
- https://peps.python.org/pep-0751/ — `pylock.toml` standardized lock format, Final (accepted 2025-03-31), hashes mandatory, cross-platform markers, interop between lockers/installers — retrieved 2026-08-24
- https://docs.astral.sh/uv/concepts/projects/sync/ — uv.lock freshness verification (`uv lock --check`, `--locked`, `--frozen`), automatic lock/sync behavior — retrieved 2026-08-24
- https://docs.astral.sh/uv/concepts/resolution/ — uv's universal/cross-platform resolution by default, resolution strategy flags — retrieved 2026-08-24
- https://python-poetry.org/docs/basic-usage/ — recommends committing poetry.lock for applications; no hash or CI-verification detail present on this page — retrieved 2026-08-24
- https://python-poetry.org/docs/libraries/ — poetry.lock commit guidance for libraries (optional, doesn't affect downstream consumers) — retrieved 2026-08-24
- https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions — SHA-pinning rationale, secret-masking, OIDC-over-long-lived-creds, minimal GITHUB_TOKEN permissions — retrieved 2026-08-24
- https://docs.docker.com/build/building/best-practices/ — digest-vs-tag pinning trade-off (reproducibility vs. automatic patching), Docker Scout automation as the recommended middle path — retrieved 2026-08-24
- https://cyclonedx.org/tool-center/ — `cyclonedx-python` as CycloneDX's own official, OSI-approved Python SBOM generator (venvs, requirements files, Poetry/Pipenv manifests) — retrieved 2026-08-24
- https://peps.python.org/pep-0770/ — SBOM directory (`.dist-info/sboms/`) in wheels, Final status, explicitly format-neutral between CycloneDX and SPDX — retrieved 2026-08-24
- https://spdx.dev/use/ — attempted for SPDX Python-specific tooling; fetch returned only high-level "specs/license-list/tools" framing with no Python-specific detail or version number — inconclusive, not used as a positive source — retrieved 2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — task's own essential-context doc: domain boundary, subsection list, OWASP CI/CD Top 10 and Bandit B613–615 citations that this baseline verifies and deepens — retrieved 2026-08-24
- `research/python-code-review/original-tool/review-domains/security.md` (this repo) — confirmed exact existing content to avoid duplication: Critical-tier pickle rule, Important-tier "Dependency Security (supply chain)" subsection, Minor-tier SBOM line, Minor-tier gitleaks/trufflehog line — retrieved 2026-08-24
- `research/python-code-review/original-tool/review-domains/standards-compliance.md` (this repo) — confirmed the CI/CD mention is a bare tier-table row only, with zero elaboration in Review Criteria — retrieved 2026-08-24

**Fetches attempted and failed (not used as sources, listed for transparency):**
- https://www.sigstore.dev/ — page renders via JS, WebFetch received only a loading placeholder, no usable content
- https://docs.sigstore.dev/quickstart/quickstart-python/ — 404
- https://blog.pypi.org/posts/2023-11-14-pypi-now-supports-digital-attestations/ — 404
- https://blog.trailofbits.com/2024/11/14/attestations-a-new-generation-of-signing-on-pypi/ — 404

## Open questions for the user

1. **OWASP CI/CD Top 10 currency**: confirmed v1.0 (Oct 2022) is live at the
   canonical URL, but this pass's WebSearch budget was exhausted before a
   dedicated check for a possible newer edition could run. Worth one targeted
   check before authoring locks the domain structure to v1.0's 10 categories.
2. **Sigstore's exact role in PyPI attestations**: `docs.pypi.org/attestations`
   describes the in-toto/SLSA mechanism in PyPI's own terms without naming
   Sigstore in the fetched excerpt, and direct attempts to verify the
   Sigstore connection (sigstore.dev, two blog posts) all failed (JS-rendered
   page, two 404s). If the eventual skill content wants to name Sigstore
   specifically as the transparency-log backend, that claim needs one more
   successful fetch first — don't inherit it from general knowledge.
3. **uv.lock / poetry.lock hash content**: neither tool's official docs
   fetched in this pass explicitly confirmed or denied that the lockfile
   records per-package hashes (as `pylock.toml` and `requirements.txt`
   `--require-hashes` both explicitly do). This is a plausible-but-unverified
   gap — worth a direct check of a real `uv.lock`/`poetry.lock` file's
   contents, or a more specific docs page, before the skill asserts either
   tool's hash behavior.
4. **CycloneDX vs SPDX for Python**: PEP 770 stays deliberately neutral, and
   this pass found a first-party Python tool for CycloneDX
   (`cyclonedx-python`) but no equivalent first-party-Python signal for SPDX
   tooling (the spdx.dev fetch was uninformative, not negative — it may just
   need a different page, e.g. an SPDX Python library's own docs). If the
   skill wants to recommend a single default tool rather than staying
   format-agnostic, that recommendation isn't substantiated by this research
   and should be a deliberate human call, not inherited as fact.
5. **Transitive license-compatibility checking**: no current, primary-sourced
   Python tool doing real compatibility analysis (vs. enumeration) was found.
   Confirm whether this sub-topic should ship as "no tooling gap identified,
   note pip-licenses' enumeration-only nature and move on" or whether a
   follow-up search should look harder before the skill is authored.
6. **No single "current default" lockfile tool for 2025-2026**: the task
   asked which tool is the current default choice in the Python ecosystem.
   This research deliberately declines to name one (uv, Poetry, and
   requirements.txt+hashes are all real, live choices with no primary source
   ranking them) and instead surfaces PEP 751's `pylock.toml` as the
   vendor-neutral standards-level answer. If the skill wants to recommend a
   single default tool to check for, that's a human call this research
   doesn't substantiate — don't let PEP 751's existence be read as "so uv
   lost" or "so Poetry lost"; it's an interop layer, not a verdict on either.
7. **`safety` (pyup.io scanner)**: named in the task alongside pip-audit but
   not independently fetched against its own docs in this pass — its current
   DB source, CLI behavior, and free-vs-paid tier boundaries are unverified
   here and should not be assumed to match older general knowledge.
8. **Conditional-domain activation signal**: the ML-artifact subsection and
   the SBOM/attestation subsection are both conditional (ML: only when
   pickle/PyTorch/HF loading is detected in imports; SBOM/attestation:
   arguably only relevant for publishable packages, overlapping Standards
   Compliance's own "conditional on publishable library" packaging
   expansion). Worth deciding at authoring time whether this domain reuses
   the original tool's Script/Web/Enterprise tier table for these, or a
   separate detected-capability gate like Standards Compliance's
   `[standards.recommended_libraries]` pattern.

## Resolutions (Checkpoint A review, 2026-08-24)

- **OWASP CI/CD Top 10 currency, Sigstore's exact role, uv.lock/poetry.lock
  hash content, `safety`'s current behavior**: all four deferred to a
  direct-fetch check at authoring time, per the standing verify-before-
  publish policy — no decision needed now.
- **CycloneDX vs. SPDX**: stay format-agnostic, matching PEP 770's own
  neutrality — mention `cyclonedx-python` as the one first-party tool
  found without declaring an overall winner.
- **Transitive license-compatibility checking**: ship as a documented gap
  ("no current primary-sourced Python tool found, pip-licenses enumerates
  only") rather than delaying authoring to search further.
- **No single "current default" lockfile tool**: stay neutral (uv,
  Poetry, and requirements.txt+hashes are all real live choices), surface
  `pylock.toml` (PEP 751) as the standards-level interop answer rather
  than picking a winner among the tools themselves.
- **Conditional-domain activation signal**: use a detected-capability
  gate (mirroring Standards Compliance's own
  `[standards.recommended_libraries]` pattern) for the ML-artifact
  subsection specifically — activate only when pickle/PyTorch/HuggingFace
  imports are detected, since that's a "does this even apply" question,
  not a maturity-tier question. Keep the rest of this domain (SBOM,
  CI/CD, lockfiles) on the normal Script/Web/Enterprise tier table, since
  those apply to any project regardless of ML use.

## Target file(s) + estimated length

- `skills/python-code-review/references/dependency-supply-chain-security.md`
  — est. 340–380 lines (comparable to `security.md`'s 256 lines but with one
  more major subsection — CI/CD pipeline security — that is itself larger
  than any single existing security.md subsection, plus the conditional ML
  block and a tier-applicability table matching the original tool's
  Script/Web/Enterprise convention).
