# Dependency & Supply Chain Security Review Domain

## Table of Contents

- [Scope](#scope)
- [Tier Applicability](#tier-applicability)
- [Review Criteria](#review-criteria)
  - [Critical](#critical)
  - [Important](#important)
  - [Minor](#minor)
- [Conditional: ML Model Artifact Deserialization](#conditional-ml-model-artifact-deserialization)
- [Scoring Guide](#scoring-guide)
- [Required Evidence in Findings](#required-evidence-in-findings)
- [Sources](#sources)

## Scope

This domain asks whether the artifacts, dependencies, and pipeline that
produce the reviewed code can be trusted — provenance and chain-of-custody
thinking, not runtime-vulnerability thinking. It covers SBOM generation,
vulnerability-database integration, license-compatibility signals, lockfile
discipline, CI/CD pipeline security (pinned actions, credential hygiene,
poisoned-pipeline-execution vectors, base-image pinning, artifact
signing/attestation), and — conditionally — safe deserialization of ML
model artifacts.

Two adjacent domains ask different questions about overlapping surface
area:

- [`security.md`](security.md) owns application-code exploitability: its
  Critical tier already flags `pickle.loads()`/`pickle.load()` on untrusted
  input as a general rule. This domain owns the *specific* case of
  hub-fetched or checked-in model artifacts being untrusted input in that
  same sense — see [Conditional: ML Model Artifact
  Deserialization](#conditional-ml-model-artifact-deserialization).
- [`standards-compliance.md`](standards-compliance.md) owns whether
  build/tooling config *exists and is well-formed* — pyproject.toml
  conventions, packaging metadata, whether a CI/CD config file is present at
  all. This domain owns whether that pipeline and its dependencies are
  *trustworthy* — vulnerability exposure, provenance, tamper resistance.
  "Does a CI workflow exist" is Standards Compliance's question; "can that
  workflow be hijacked to exfiltrate secrets or ship a poisoned artifact" is
  this domain's.

## Tier Applicability

| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Lockfile present and committed | Yes | Yes | Yes |
| Lockfile freshness enforced in CI | No | Yes | Yes |
| Vulnerability-database scanner wired into CI | No | Yes | Yes |
| Dependency Chain Abuse preventive controls | No | Yes | Yes |
| SBOM generated in CI | No | Optional | Yes |
| License enumeration / policy gate | No | Optional | Yes |
| Pinned GitHub Actions (full commit SHA) | No | Yes | Yes |
| Credential hygiene in pipeline logs | No | Yes | Yes |
| Poisoned-Pipeline-Execution guardrails | No | Yes | Yes |
| Base-image pinning strategy | No | Yes | Yes |
| Artifact signing / attestation (Trusted Publishing) | No | Optional | Yes |
| Source-integrity scanning (TrojanSource / bidi) | No | Yes | Yes |
| ML-artifact deserialization safety | Conditional | Conditional | Conditional |

"Optional" in this table means the check applies only when relevant to the
project — e.g., a project that never publishes a package has nothing for
Trusted Publishing to secure. It is not a discount on severity: when an
Optional-tier check does apply, its severity in [Review
Criteria](#review-criteria) still holds at full weight.

The ML-artifact row is "Conditional" at every tier rather than following
the Script/Web/Enterprise ladder: it activates on a detected-capability
signal (pickle/PyTorch/HuggingFace imports found in the codebase), the
same pattern Standards Compliance uses for its
`[standards.recommended_libraries]` gap detection. A one-file script that
loads a `.pt` checkpoint owes the same scrutiny as an enterprise service
doing the same thing; a web API that never touches ML artifacts owes none.
Tier controls maturity expectations; capability detection controls
applicability, and they're independent axes.

## Review Criteria

OWASP's Top 10 CI/CD Security Risks names ten categories: Insufficient Flow
Control (SEC-1), Inadequate IAM (SEC-2), Dependency Chain Abuse (SEC-3),
Poisoned Pipeline Execution (SEC-4), Insufficient PBAC (SEC-5),
Insufficient Credential Hygiene (SEC-6), Insecure System Configuration
(SEC-7), Ungoverned 3rd-Party Services (SEC-8), Improper Artifact
Integrity Validation (SEC-9), and Insufficient Logging/Visibility (SEC-10).
This domain draws its CI/CD content most directly from SEC-3, SEC-4,
SEC-6, and SEC-9 below; SEC-1, SEC-2, SEC-5, SEC-7, SEC-8, and SEC-10 are
either owned by Security/Standards Compliance's own access-control and
logging coverage or out of this skill's scope.

### Critical

**Long-lived publishing credentials instead of Trusted Publishing**
PyPI's Trusted Publishing mechanism uses OIDC to let a CI system (GitHub
Actions, GitLab CI/CD, Google Cloud, or ActiveState) exchange a short-lived
identity token for a 15-minute PyPI upload token, scoped to a single
publish. A manually-generated, long-lived API token stored as a repo
secret is the alternative it replaces, and its blast radius is the same
class of problem as any other hardcoded credential: if it leaks, it's
usable "until its legitimate user notices and manually revokes it." Flag
any release workflow that still uploads with `TWINE_PASSWORD`/a stored API
token when Trusted Publishing is available for that CI provider — this
only applies when the project actually publishes a package.

**GitHub Actions not pinned to a full commit SHA**
GitHub's own hardening guide (SEC-9, Improper Artifact Integrity
Validation) states that pinning to a full-length commit SHA is "the only
way to use an action as an immutable release" — forging one would require
a SHA-1 collision, which is computationally infeasible. Checklist:

- Every third-party action reference is a full commit SHA
  (`actions/checkout@<40-char-sha>`), not a tag or branch.
- Tag pinning (`@v4`) is used, if at all, only for actions published by a
  fully trusted first-party or verified-creator source.
- No action is referenced by `@main`, `@master`, or another mutable
  branch name.
- Any action that fails these checks is treated as having full access to
  the workflow's secrets, since "a compromise of a single action within a
  workflow can be very significant" per GitHub's own rationale.

**Poisoned Pipeline Execution (OWASP CICD-SEC-4)**
The checkable condition, common to all three named variants: does the
pipeline execute anything — the CI config itself, a Makefile target, a
test/lint step, a build script — that is sourced from a branch or PR the
repo owner doesn't control, without a human-approval gate first.

| Variant | Condition |
|---|---|
| Direct PPE (D-PPE) | An attacker with repo write access, or via an unreviewed PR, modifies the CI config file itself to run malicious steps. |
| Indirect PPE (I-PPE) | The CI config is protected, so the attacker instead poisons a file the pipeline *executes* — Makefile, test script, linter config, build script — to achieve the same effect without touching the workflow file. |
| Public/3rd-party PPE (3PE) | A public repo runs CI against PRs from anonymous contributors, letting an unvetted attacker trigger pipeline execution — materially worse when that CI shares runners or secrets with private/trusted projects. |

Flag `pull_request_target` (or equivalent) triggers that check out and
execute PR head content without a maintainer-approval step, and any shared
runner pool where a public-repo pipeline and a secrets-bearing pipeline
aren't isolated.

**Credential hygiene in pipeline logs (OWASP SEC-6, Insufficient Credential
Hygiene)**
Distinct from Security's Minor-tier gitleaks/trufflehog line, which catches
secrets *committed* to source — this is runtime log leakage during
execution. Checklist, from GitHub's own hardening guide:

- No sensitive value is hardcoded directly in workflow YAML.
- Non-secret but sensitive output uses `::add-mask::VALUE` to redact it
  from logs.
- Any value generated at runtime (a minted JWT, a temporary password) is
  registered as a secret so GitHub auto-redacts it from logs going
  forward.
- OIDC-issued short-lived cloud credentials are used in preference to
  long-lived stored secrets wherever the provider supports it.
- The default `GITHUB_TOKEN` permission is read-only, elevated per-job
  only as needed (least privilege), not `permissions: write-all` at the
  workflow level.

A workflow that `echo`s a token for debugging, or that grants
`permissions: write-all` by default, fails this checklist and is a
Critical finding.

### Important

**Dependency Chain Abuse (OWASP CICD-SEC-3) preventive controls**
Four named attack patterns, all defended by the same control set:

| Pattern | Condition |
|---|---|
| Dependency confusion | A malicious public package is published under the same name as an internal/private package, and the resolver prefers the public registry. |
| Dependency hijacking | An attacker compromises a legitimate maintainer's account and ships a malicious version under the trusted package name. |
| Typosquatting | A malicious package is published under a name similar to a popular one, betting on a developer's misspelling. |
| Brandjacking | A malicious package is published following a specific brand's naming convention to impersonate it. |

Checkable preventive controls: installs routed through an internal proxy or
pre-vetted internal repository rather than direct public access; checksum
or signature verification enabled on fetched packages; dependencies pinned
to stable versions (never `latest` or an unbounded range); private/internal
packages registered under an organizational namespace or scope; install
scripts isolated from secrets; internal package names not leaked in public
repos or issue trackers; some form of detection or monitoring for
anomalous package changes.

**No vulnerability-database scanner wired into CI**
`pip-audit`, GHSA (via Dependabot or `gh` alerts), OSV, and `safety` are
heavily overlapping views of the same underlying Python advisory data, not
independently stacking coverage:

- `pip-audit` defaults to the PyPI JSON API, which itself serves the
  Python Packaging Advisory Database (`pypa/advisory-database`); it can
  also query OSV directly via `-s osv` / `PIP_AUDIT_VULNERABILITY_SERVICE`.
- GHSA (GitHub Advisory Database) publishes advisories in OSV format and
  pulls from the same `pypa/advisory-database` for Python, plus
  NVD/CVE-derived entries and GitHub Security Lab-reviewed community
  submissions.
- OSV is explicitly an aggregator — its own site states it aggregates
  "vulnerability databases that have adopted the OSV schema, including
  GitHub Security Advisories," across 40+ ecosystems, so GHSA data flows
  into OSV for PyPI too.
- `safety` (pyup.io) is a separate, freemium-model scanner (MIT-licensed
  CLI, GitHub Action available at `pyupio/safety-action`) built on its own
  "Safety DB" vulnerability data; the free tier is single-user and
  explicitly "not recommended for commercial purposes," with paid tiers
  advertising "3x more tracked vulnerabilities and malicious packages"
  than the free plan. Treat its free-tier output as partial coverage, not
  equivalent to the PyPA/OSV/GHSA graph.

The checkable question is "is at least one scanner wired into CI against
this shared advisory graph," not "are all of them integrated." Running
`pip-audit` *and* GHSA alerts covers materially the same ground twice —
fine as defense-in-depth, but don't score it as broader coverage than it
is. Flag when zero scanners run in CI; note but don't require redundancy
when one already does.

**Lockfile discipline**
PEP 751 (Final, accepted 2025-03-31) standardizes `pylock.toml`, a
vendor-neutral TOML lock format that mandates hashes for every recorded
file, supports environment-marker-based cross-platform resolution and
multi-use lockfiles, and records file provenance (URL/VCS/local path). It's
explicitly designed for tool-specific "lockers" (uv, Poetry, PDM) to
*export* to for interop with installers — it does not replace those tools'
native formats, which remain mutually incompatible with each other today.
No single tool is "the" current default; uv, Poetry, and
`requirements.txt` + hashes are all live, real choices, and `pylock.toml`
is the standards-level interop answer rather than a verdict on any of them.

Per-tool state:

- **`uv.lock`** performs universal resolution by default — one lockfile
  portable across platforms and Python versions, using environment markers
  to select the right version per platform. It embeds per-package SHA256
  hashes: every `[[package]]` entry's `sdist`/`wheels` tables carry a
  `hash = "sha256:..."` field alongside the download URL. Freshness is
  checkable in CI via `uv lock --check` (equivalent to `--locked`) or
  enforced via `uv sync --locked`/`--frozen`.
- **`poetry.lock`**: Poetry's own docs recommend committing it for
  applications ("anyone who sets up the project uses the exact same
  versions") and leave it optional for libraries, since a library's lock
  file has no effect on downstream consumers. It embeds per-package SHA256
  hashes — each package's `files` array pairs a filename with a
  `hash = "sha256:..."` value.
- **`requirements.txt` + hashes**: pip's `--require-hashes` mode is the
  lockfile-adjacent mechanism with the most explicitly documented security
  contract. Once any `--hash` is present, hashes become mandatory for
  *every* requirement, including transitive ones; all requirements must be
  pinned (`==`, a URL, or a path — no loose ranges); only SHA256 or
  stronger is accepted, MD5/SHA1 are rejected. This is pip's answer to
  reproducible, tamper-evident installs without adopting a project-
  management tool.

Checklist framing: does a lockfile exist and is it committed; if
`requirements.txt`-only, is `--require-hashes` actually enforced in CI
(not just a hash-annotated file sitting unused); is lockfile freshness
checked in CI (`uv lock --check` or equivalent), not just committed once
and left to drift.

**SBOM generation**
PEP 770 (Final, accepted) is the authoritative Python-ecosystem answer to
"CycloneDX or SPDX," and it deliberately declines to pick a winner: it
reserves a `.dist-info/sboms/` directory in wheels for bundled-component
SBOMs — solving the "phantom dependency" problem of compiled/non-Python
libraries invisible to standard packaging metadata — and recommends SBOM
documents "SHOULD use a widely-accepted SBOM standard, such as CycloneDX or
SPDX" without requiring either. The one concrete tool-adoption signal:
`cyclonedx-python` is CycloneDX's own official, OSI-approved generator,
producing SBOMs "from Python (virtual) environments, requirement files,
and manifests (Poetry, PipEnv, etc.)." CycloneDX has a first-party Python
generator; SPDX has no equivalent Python-specific tool. Frame the check
format-agnostically: does an SBOM get generated in CI in a widely-accepted
format, not "is it CycloneDX specifically."

**Artifact signing and attestation (OWASP SEC-9, Improper Artifact
Integrity Validation)**
Layered on top of Trusted Publishing, PyPI's Digital Attestations let a
package be cryptographically signed at upload, with two accepted predicate
types: SLSA Provenance and PyPI Publish attestations (proof of publication
via a specific Trusted Publisher). PyPI's own docs describe attestations as
"functionally (but not structurally) compatible with Sigstore bundles," and
state that any system able to produce Sigstore bundles can be adapted to
produce them via the `sigstore-python` and `pypi-attestation` libraries,
backed by a public transparency log. This is currently **optional**, not
mandatory, and requires Trusted Publishing already configured — flag a
release pipeline that has Trusted Publishing but hasn't turned attestations
on as a gap worth closing, not a hard failure.

Scope boundary: `cosign` is an OCI/container-image signing tool, not part
of PyPI's package-attestation mechanism. It's relevant to this domain only
when the reviewed project *also* ships container images — a
deployment-artifact concern to cross-reference, not duplicate into
container-specific tooling this skill doesn't otherwise cover.

**Base-image pinning**
Docker's own best-practices doc frames this as a real trade-off, not a
one-directional "always pin harder" rule. Pinning `FROM image@sha256:...`
to a digest guarantees reproducibility and an audit trail, but opts out of
the automatic security patches a moving tag (`alpine:3.21`) would otherwise
pick up. Docker's own recommendation is automated digest-update tooling
(they cite Docker Scout) that pins for reproducibility while still
surfacing or PR-ing patch updates, rather than silently drifting either
direction. Flag a Dockerfile that pins to a digest with no update
automation (stale patches accumulate silently) *and* a Dockerfile that
floats on a mutable tag with no pin at all (no reproducibility, no audit
trail) — don't treat digest-pinning alone as sufficient.

**Source integrity: Unicode bidirectional control characters**
Bandit's B613 (`trojansource`) flags Unicode bidirectional control
characters in source files — comments and strings — that can visually
reorder code relative to its actual execution order (CVE-2021-42574);
CWE-838, High severity / Medium confidence. This is source-integrity, not
model-artifact-specific: file it as a general supply-chain/source-trust
check in this domain, not inside the conditional ML subsection below. The
Medium confidence rating means a hit deserves a look, not an automatic
fail — verify the flagged bytes are actually bidi control characters
before treating it as more than a lead.

**License-compatibility checking**
Two distinct, non-overlapping facts, not a single tool doing both:

- PEP 639 (Final) standardizes SPDX license-expression syntax in core
  metadata via a new `License-Expression` field (e.g. `"MIT AND
  (Apache-2.0 OR BSD-2-Clause)"`), explicitly deprecating both the old
  unstructured `License` field and `License ::` Trove classifiers. A
  checkable signal: does the project's `pyproject.toml` use
  `License-Expression` rather than legacy classifiers.
- `pip-licenses` (current: 5.5.5) **enumerates only** — it lists installed
  packages' licenses via metadata/Trove classifiers in many output
  formats and supports policy gates (`--fail-on`, `--allow-only`), but does
  **not** perform actual compatibility analysis (e.g. whether a GPL
  dependency conflicts with an MIT dependency in a distributed binary). No
  Python tool performs real transitive compatibility analysis; enumeration
  plus a policy gate is the available ceiling — don't invent or imply a
  compatibility-analysis tool that doesn't exist. See [Minor](#minor) for
  the enumeration-coverage check itself.

### Minor

- `pylock.toml` (PEP 751) not exported even though the project already
  uses uv or Poetry natively — an interop nicety for downstream installers,
  not a requirement.
- `License-Expression` (PEP 639) not yet adopted; project still relies on
  legacy `License ::` classifiers only.
- SBOM generated, but not in a widely-recognized format, or not published
  alongside releases where consumers could reasonably expect one.
- No `pip-licenses` (or equivalent) enumeration wired into CI even as a
  non-blocking report.
- Dependabot/`gh` alert monitoring configured but never triaged (alerts
  accumulating unreviewed is a process gap, not a missing control).

## Conditional: ML Model Artifact Deserialization

Activate this subsection only when a detected-capability scan finds
`pickle`, `torch`/`torch.load`, or Hugging Face Hub imports
(`transformers`, `huggingface_hub`, `datasets`) in the codebase — the same
detected-capability gate Standards Compliance uses for
`[standards.recommended_libraries]`. When none of those are present, skip
this subsection entirely rather than scoring it "not applicable."

Security's Critical tier already owns "`pickle.loads()`/`pickle.load()` on
untrusted data" as a general application-code pattern. This subsection
owns the specific case that hub-fetched or checked-in model artifacts
**are** untrusted input in the same sense: pin revisions, prefer
`safetensors`, and treat "loading a model file" as a deserialization trust
boundary like any other, not a special exemption.

**B614 (`pytorch_load`) — Critical when applicable**
Flags `torch.load` / `torch.serialization.load` on untrusted data; CWE-502
(Deserialization of Untrusted Data); Medium severity / High confidence;
introduced in Bandit 1.7.10. Remediation: `weights_only=True`, or use the
`safetensors` library instead of pickle-based weights.

A version-boundary correction matters here: PyTorch flipped the default of
`weights_only` between the 2.5 and 2.6 releases, confirmed directly from
both versions' own docs. In 2.5, the parameter defaults to `False`; in 2.6,
it defaults to `True`, and PyTorch's 2.6 docs now warn that
`weights_only=False` "uses the `pickle` module implicitly, which is known
to be insecure" and can "execute arbitrary code during unpickling." This
means B614's classic remediation is now the *default* behavior on current
PyTorch — the residual real risk is code that explicitly passes
`weights_only=False`, or a project still pinned to PyTorch <2.6. Word the
finding precisely: not every `torch.load` call is unsafe by default today,
but an explicit `weights_only=False` or an unpinned/legacy PyTorch version
is.

**B615 (`huggingface_unsafe_download`) — Important when applicable**
Flags Hugging Face Hub downloads (`AutoModel.from_pretrained`,
`AutoTokenizer.from_pretrained`, `load_dataset`, `hf_hub_download`,
`snapshot_download`) that omit a `revision` pin or use a mutable one
(`revision="main"`, a branch, a non-immutable tag); CWE-494 (Download of
Code Without Integrity Check); Medium severity / High confidence.
Remediation: pin `revision=` to an immutable commit hash, not a branch or
floating tag — a repo maintainer (or an attacker who compromises their
account) can otherwise change what a pinned-looking branch name resolves
to after the fact.

## Scoring Guide

Score against the checks that are tier-applicable (per [Tier
Applicability](#tier-applicability)) and, where relevant, capability-gated
(per the ML-artifact conditional) — a Script-tier project isn't penalized
for skipping checks the table marks "No" for it.

- **10**: Zero Critical or Important findings among tier-applicable
  checks; Minor items addressed too; ML-artifact section (if applicable)
  fully compliant.
- **8-9**: No Critical findings; 1-2 Important gaps among tier-applicable
  checks (e.g., SBOM missing, or base-image pinning strategy incomplete
  in one direction).
- **6-7**: No Critical findings; several Important gaps (no vulnerability
  scanner in CI, license enumeration absent, lockfile present but
  freshness unchecked).
- **4-5**: One Critical finding, or many Important gaps stacked (no
  lockfile at all, tag-pinned Actions throughout, no PPE guardrails).
- **1-3**: Multiple Critical findings (long-lived publish tokens where a
  release workflow exists, tag/branch-pinned Actions with secret access,
  active PPE exposure, credential leakage in logs, or
  `weights_only=False` on hub-fetched checkpoints).

## Required Evidence in Findings

Each finding must include:

- **Severity** (Critical / Important / Minor)
- **Category** (one of: Lockfile / SBOM / Vuln-Scan / License / CI-Pinning
  / Credential-Hygiene / PPE / Base-Image / Attestation / ML-Artifact /
  Source-Integrity)
- **Standard/tool reference** where applicable (OWASP CICD-SEC-3/4, PEP
  639/751/770, Bandit B613/B614/B615)
- **File and line number** (workflow YAML, Dockerfile, `pyproject.toml`,
  or model-loading call site)
- **Trust-boundary scenario** — one sentence describing what an attacker
  or a silent failure mode gains
- **Fix** — concrete remediation (pin to SHA, enable `--require-hashes`,
  set `weights_only=True`, enable Trusted Publishing, etc.)

## Sources

- https://owasp.org/www-project-top-10-ci-cd-security-risks/ — OWASP Top
  10 CI/CD Security Risks, currently at v1.0 (October 2022), no newer
  edition
- https://owasp.org/www-project-top-10-ci-cd-security-risks/CICD-SEC-04-Poisoned-Pipeline-Execution — the three named PPE variants (D-PPE, I-PPE, 3PE)
- https://owasp.org/www-project-top-10-ci-cd-security-risks/CICD-SEC-03-Dependency-Chain-Abuse — the four named Dependency Chain Abuse patterns and preventive controls
- https://bandit.readthedocs.io/en/latest/plugins/b613_trojansource.html — B613: CWE-838, High/Medium, CVE-2021-42574
- https://bandit.readthedocs.io/en/latest/plugins/b614_pytorch_load.html — B614: CWE-502, Medium/High, introduced Bandit 1.7.10
- https://bandit.readthedocs.io/en/latest/plugins/b615_huggingface_unsafe_download.html — B615: CWE-494, Medium/High, revision-pinning remediation
- https://docs.pytorch.org/docs/2.6/generated/torch.load.html — confirms `weights_only` defaults to `True` in PyTorch 2.6
- https://docs.pytorch.org/docs/2.5/generated/torch.load.html — confirms `weights_only` still defaulted to `False` in PyTorch 2.5
- https://docs.pypi.org/trusted-publishers/ — Trusted Publishing: OIDC mechanism, 15-minute short-lived tokens
- https://docs.pypi.org/attestations/ — Digital Attestations: in-toto framework, SLSA Provenance + PyPI Publish predicate types, optional
- https://docs.pypi.org/attestations/producing-attestations/ — Sigstore-bundle compatibility, `sigstore-python`/`pypi-attestation` tooling, and the public transparency log
- https://pypi.org/project/pip-audit/ — default PyPI-JSON-API service (backed by `pypa/advisory-database`) plus OSV service via `-s`/env var
- https://osv.dev/ — OSV's explicit aggregator role, 40+ ecosystems, GHSA data included for PyPI
- https://docs.github.com/en/code-security/security-advisories/working-with-global-security-advisories-from-the-github-advisory-database/about-the-github-advisory-database — GHSA sourcing and OSV-format publication
- https://pypi.org/project/safety/ — `safety`'s current freemium model, MIT-licensed CLI, `pyupio/safety-action` GitHub Action, free-tier limits
- https://pypi.org/project/pip-licenses/ — pip-licenses is enumeration-only (current version 5.5.5), `--fail-on`/`--allow-only` policy gates
- https://peps.python.org/pep-0639/ — SPDX license-expression standardization (`License-Expression` field), deprecates classifiers
- https://pip.pypa.io/en/stable/topics/secure-installs/ — `--require-hashes` mechanics
- https://peps.python.org/pep-0751/ — `pylock.toml` standardized lock format (Final, accepted 2025-03-31)
- https://docs.astral.sh/uv/concepts/projects/sync/ — `uv.lock` freshness verification (`uv lock --check`, `--locked`, `--frozen`)
- https://docs.astral.sh/uv/concepts/resolution/ — uv's universal/cross-platform resolution by default
- https://raw.githubusercontent.com/astral-sh/uv/main/uv.lock — a real `uv.lock` file, confirming it embeds per-package SHA256 hashes
- https://python-poetry.org/docs/basic-usage/ — recommends committing `poetry.lock` for applications, optional for libraries
- https://raw.githubusercontent.com/python-poetry/poetry/master/poetry.lock — a real `poetry.lock` file, confirming it embeds per-package SHA256 hashes
- https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions — SHA-pinning rationale, secret-masking, OIDC-over-long-lived-creds, minimal `GITHUB_TOKEN` permissions
- https://docs.docker.com/build/building/best-practices/ — digest-vs-tag pinning trade-off, Docker Scout as the recommended middle path
- https://cyclonedx.org/tool-center/ — `cyclonedx-python`, CycloneDX's own official Python SBOM generator
- https://peps.python.org/pep-0770/ — SBOM directory (`.dist-info/sboms/`) in wheels, format-neutral between CycloneDX and SPDX
