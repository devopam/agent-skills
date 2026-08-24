# Baseline: Standards Compliance
Status: user-approved      Date: 2026-08-24

## Resolutions (Checkpoint C review, 2026-08-24)

- **loguru/httpx identical release-date coincidence**: deferred to a
  direct-fetch re-check at authoring time, per the standing
  verify-before-publish policy.
- **CI/CD "well-formed" checklist, reasoned not single-source-quoted**:
  accepted as-is, consistent with this repo's honest-labeling convention.
- **Packaging-subsection applicability trigger**: accept the proposed
  detection heuristic (`[project].name`/`version` aimed at distribution,
  or an explicit publish workflow already in CI).
- **uv's broader role**: keep scope narrow as baselined (recognized peer
  backend, not a recommended migration target) — don't expand into
  project-manager territory in either this domain or the sibling Supply
  Chain domain for this pass.

## In scope

- **Packaging & distribution hygiene — new conditional subsection** —
  impact: high — depth: section. Per the scoping doc, this subsection
  applies **only when the reviewed project is a publishable library**
  (declares intent to distribute via PyPI/an index — has a `[project]`
  `name`/`version` aimed at distribution, not just an internal
  `pyproject.toml` used for tooling config). For a non-distributed
  application or script, skip this subsection entirely rather than
  penalizing it for missing packaging metadata it doesn't need. Grounded
  directly in PyPA's own packaging guide (`packaging.python.org`, fetched
  2026-08-24):

  - **`[build-system]` table**: "strongly recommended... should always be
    present, regardless of which build backend you use." Current backend
    options and PyPA's documented minimum-version examples: `hatchling
    >= 1.26`, `setuptools >= 77.0.3`, `flit_core >= 3.12.0, <5`,
    `pdm-backend >= 2.4.0`, and the newer `uv_build >= 0.12.5, <0.13.0`
    (uv's own build backend — see the uv note below). Review angle: flag a
    publishable project with no `[build-system]` table, or one still
    invoking `python setup.py sdist`/`bdist_wheel` directly (see setup.py
    nuance below).
  - **Namespace packages**: PyPA's current recommendation is **native
    namespace packages (PEP 420)** — omit `__init__.py` from the namespace
    directory — "recommended if packages in your namespace only ever need
    to support Python 3 and installation via pip." `pkgutil`-style
    (`pkgutil.extend_path()` in `__init__.py`) is legacy but
    largely-compatible; `pkg_resources`-style is confirmed non-functional
    at runtime (not merely deprecated-in-docs), as of
    **Setuptools 82.0.0** — re-verified with a direct second fetch
    (2026-08-24) of the exact surrounding text: "The information in this
    section is obsolete and is no longer functional (as of Setuptools
    82.0.0). It is only retained for historical reference," and
    separately, "`pkg_resources` has been deprecated and was fully
    removed in Setuptools 82.0.0." This confirms the severity call: flag
    any project still relying on `pkg_resources`-style namespace
    declarations as **broken** on any environment with Setuptools
    >=82.0.0 installed, not merely style-outdated.
  - **`py.typed` — packaging-correctness half only**: PEP 561 requires the
    marker file to be **included in the installed distribution**
    (historically via `package_data`/`MANIFEST.in`, now via the build
    backend's include rules in `pyproject.toml`), and states the
    obligation is recursive — "if a top-level package includes it, all its
    sub-packages MUST support type checking as well." **Boundary, already
    stated correctly on the Code Quality side**: Code Quality's baseline
    (`research/python-code-review/code-quality.md` line ~90) already
    scopes itself to whether the package's types are *actually correct*
    for `py.typed` to be honest; this domain's angle is narrower and
    purely mechanical — is the file present in the package directory *and*
    actually shipped in the built wheel/sdist (a common real-world bug:
    the marker exists in the repo but the build backend's include
    globs exclude non-`.py` files, so it silently never reaches the
    installed package).
  - **TestPyPI staging**: PyPA's CI/CD publishing guide documents
    publishing every push to TestPyPI as routine practice — "useful for
    providing test builds to your alpha users as well as making sure that
    your release pipeline remains healthy" — with PyPI-proper publishing
    gated to tag pushes only (`if: startsWith(github.ref, 'refs/tags/')`)
    behind a manual-approval environment. Review angle: a release pipeline
    that publishes to PyPI directly with no TestPyPI dry-run stage is a
    process gap, independent of security concerns.
  - **Trusted Publishing / OIDC vs. long-lived tokens — config-correctness
    angle only**: PyPA's guide is explicit that this is the current
    recommendation ("recommended for security reasons, since the generated
    tokens are created for each of your projects individually and expire
    automatically") and that the old pattern — `PYPI_API_TOKEN`/
    `TEST_PYPI_API_TOKEN` repo secrets — is "obsolete now and you should
    remove them." **Boundary, deliberately narrow here**: the *security
    mechanics* of Trusted Publishing (15-minute short-lived tokens, OIDC
    exchange, SLSA Provenance/PyPI Publish attestations) are already
    covered in depth by `research/python-code-review/dependency-supply-chain-security.md`
    (sourced directly from `docs.pypi.org/trusted-publishers/` and
    `/attestations/`) — this domain's angle is strictly "is the workflow
    YAML configured to use Trusted Publishing at all, and are stale
    API-token secrets still present," not the trust model itself.
  - **README rendering**: PyPI's renderer accepts plain text,
    reStructuredText (Sphinx extensions excluded), and Markdown
    (GitHub-Flavored/CommonMark); content-type must be declared
    (`long_description_content_type` historically, or the `readme` key's
    inferred/explicit content-type in `pyproject.toml`). PyPA's own
    pre-publication check is `twine check dist/*`, which validates
    rendering and prints "Passed"/failure. Review angle: a publishable
    project with a README using Sphinx-only RST directives, or no
    content-type declared, will render as raw/broken markup on PyPI — a
    concretely checkable defect, not a style nit.
  - **Wheel/sdist building correctness — general case, not just
    binary-extension projects**: for any publishable project (compiled
    extension or pure-Python), PyPA's own publishing guide invokes the
    build step as `python -m build`, producing both an sdist and a wheel
    into `dist/`, followed by `twine check dist/*` before upload — this is
    the current invocation PyPA documents, not the legacy `python setup.py
    sdist bdist_wheel`. Review angle, independent of the
    binary-extension-specific check below: does the release process (CI
    workflow or documented local steps) actually produce **both**
    artifact types rather than only one (an sdist-only release forces
    every installer through a full build from source; a wheel-only
    release breaks platforms/Python versions without a matching prebuilt
    wheel and breaks users who `pip install --no-binary`); and does
    `twine check` (or equivalent) run before upload rather than trusting
    the build to have succeeded silently correctly.
  - **Binary-extension compilation** (conditional on the project
    containing compiled extensions): PyPA names **cibuildwheel** and
    **multibuild** as the CI-oriented tools for building "highly
    redistributable binaries" across platforms/Python versions, and
    **scikit-build** for abstracting cross-platform build operations.
    For the C/C++ binding layer itself, PyPA lists Cython, pybind11,
    cffi, and SWIG as alternatives to hand-written extension code. PyPA
    also states a preference: "strongly recommended that you publish your
    binary extensions as well as the source code that was used to build
    them" (i.e., ship both wheels and an sdist, not binary-only). Review
    angle: a project with a C extension that only ships a source
    distribution (forces every installer to have a working compiler
    toolchain) or only ships wheels for one platform is a distribution gap.
  - **Licensing declaration — syntax/presence angle only**: **PEP 639**
    (Final status; "the up-to-date, canonical spec... is maintained on the
    PyPA specs page," updates Core Metadata to 2.4) introduces
    `License-Expression`, a field whose value must be a valid **SPDX
    license expression** (v2.2+) — e.g. `MIT`, `BSD-3-Clause`, `MIT AND
    (Apache-2.0 OR BSD-2-Clause)`, `GPL-3.0-only WITH
    Classpath-Exception-2.0`, or a `LicenseRef-*` identifier for
    non-SPDX/proprietary terms. `License-Expression` **replaces** the
    legacy `license` classifiers approach; tools should stop emitting
    license classifiers once `License-Expression` is present. **Boundary,
    already stated correctly on the Dependency & Supply Chain side**: that
    domain owns whether declared licenses *conflict* across the dependency
    tree (a compatibility question); this domain's angle is purely
    syntactic — is a `License-Expression` present at all, and is its value
    a syntactically valid SPDX expression (vs. free-text like `"MIT
    License"` or the deprecated classifier-only form).
  - **`uv` as an emerging factor, not yet a recommendation** — impact:
    med, noted here rather than filed as its own bullet because it cuts
    across several packaging checks above. `uv` (Astral, verified current:
    0.12.5, released 2026-08-14) describes itself as "a single tool to
    replace `pip`, `pip-tools`, `pipx`, `poetry`, `pyenv`, `twine`,
    `virtualenv`, and more," and PyPA's own `pyproject.toml` guide already
    lists `uv_build` as a supported `[build-system]` backend choice
    alongside hatchling/setuptools/flit/pdm. This is real, current signal
    that uv has reached "PyPA lists it as a peer backend option" status,
    not merely a third-party curiosity — but PyPA's guide text does not
    (as fetched) state a preference for uv over the other four backends,
    so the correct review posture is "recognize uv-based projects as valid,
    don't flag `uv_build` as nonstandard," not "recommend migrating to it."

- **pyproject.toml vs. setup.py/setup.cfg — nuance the original tool's
  binary claim** — impact: high — depth: paragraph. The existing domain
  file states the check as "`pyproject.toml` exists (not `setup.py` or
  `requirements.txt` alone)" — directionally right but imprecise. PyPA's
  own dedicated page states the real distinction squarely: **"`setup.py`
  and Setuptools are not deprecated... perfectly usable as a build backend."**
  What *is* deprecated is `setup.py` as an **executable CLI script**
  (`python setup.py install`, `python setup.py bdist_wheel`) — using it
  purely as **Setuptools' configuration file is "absolutely fine."**
  Separately, PyPA states plainly that a `pyproject.toml` at the project
  root is "**STRONGLY RECOMMENDED**" regardless of backend. Corrected
  review guidance: flag a project that invokes `setup.py` as a CLI command
  (in CI scripts, README install instructions, or Makefiles) rather than
  going through `pip`/`build`; do **not** flag a `setup.py` that exists
  solely as Setuptools config alongside a `pyproject.toml` `[build-system]`
  table — that combination is currently correct, not legacy.
  **`setup.cfg` — a distinct question from `setup.py`, verified
  separately**: Setuptools' own userguide (fetched 2026-08-24) shows
  no deprecation notice for `setup.cfg` — it documents declarative
  `setup.cfg` configuration and `pyproject.toml` configuration as
  parallel, coexisting options, not a deprecated-predecessor
  relationship. The one documented interop requirement: "if
  compatibility with legacy builds (i.e. those not using the PEP 517
  build API) is desired, a `setup.py` file containing a `setup()`
  function call is still required even if your configuration resides in
  `setup.cfg`." Corrected review guidance: do not flag a
  `setup.cfg`-configured project as using a deprecated mechanism on that
  basis alone — the actual currency question is whether `[build-system]`
  is present in `pyproject.toml` at all (the item verified above),
  independent of whether the project's own metadata lives in
  `setup.cfg`, `setup.py`, or `[project]`.

- **src-layout vs. flat-layout — correct the original tool's implicit
  mandate** — impact: med — depth: paragraph. The existing domain file's
  Project Structure section states `src/<project_name>/` layout as a flat
  "present" check with no caveat, which overstates PyPA's actual position.
  PyPA's dedicated discussion page (fetched 2026-08-24) presents **both
  layouts as valid, with different tradeoffs** — it does not mandate src
  layout. Documented differences: "the src layout requires installation of
  the project to be able to run its code, and the flat layout does not";
  src layout "helps enforce that an editable installation is only able to
  import files that were meant to be importable" (guards against Python's
  CWD-first import-path behavior accidentally shadowing an installed
  package with same-named local files in flat layout); flat layout avoids
  the extra editable-install step, which matters for quick CLI-from-source
  workflows. Corrected review guidance: prefer src-layout as the safer
  default for a **publishable library** (where import-shadowing and
  editable-install correctness matter most), but do not flag flat-layout
  as a defect for an application/script project — it's a legitimate,
  PyPA-sanctioned choice there, not merely tolerated legacy.

- **Pre-commit hooks — still current** — impact: med — depth: paragraph.
  `pre-commit` (verified current: 4.6.2, released 2026-08-10, single
  primary maintainer `asottile`, active pre-commit.ci integration,
  requires Python >=3.10) remains the standard multi-language git-hook
  framework — no displacement found in this session's fetches. Its stated
  value-add is specifically **cross-language hook orchestration** ("use
  linters written in languages not used in your project... without adding
  a Gemfile... or understanding how to get scss-lint installed") and
  environment isolation (auto-downloads/builds hook toolchains without
  root). This niche is distinct from what `uv` displaces (Python
  package/env/build-tool management) — `uv` does not currently claim to
  replace `pre-commit`'s cross-language hook-runner role, so recommending
  both together is not redundant. Review angle unchanged from the original
  domain file: `.pre-commit-config.yaml` present at web/enterprise tier.

- **CI/CD config: "well-formed," not pipeline-security — boundary and
  concrete definition** — impact: med — depth: section. Per the scoping
  doc's explicit boundary: "Standards Compliance owns... CI/CD config
  *existing and well-formed*" while `dependency-supply-chain-security.md`
  owns pipeline *security* (pinned actions/base images, credential
  hygiene, poisoned-pipeline-execution, artifact signing — already sourced
  there from OWASP's CI/CD Top 10 and GitHub's own hardening guide).
  Concretely, "well-formed" for this domain means, independent of any
  security posture:
  - A test-execution stage exists and actually runs the project's test
    suite (not just `pip install` with no invocation).
  - A lint/format-check stage exists and runs in check-only mode (e.g.
    `ruff check`, not just `ruff format` with no `--check`/CI enforcement).
  - The pipeline is configured to **fail the build on a non-zero exit**
    from either stage — i.e., a red test run or lint failure actually
    blocks merge, not just reports informationally. (This is the concrete,
    reviewable form of "CI exists" vs. "CI exists but is decorative.")
  - Triggers cover both PR/push events feeding into merge protection, not
    only a manual/scheduled trigger that nobody is required to pass.
  - For a publishable-library project, the CI-driven publish workflow
    itself is well-formed per the packaging checks above (TestPyPI stage
    present, PyPI publish gated to tags/releases, not triggered on every
    push) — sourced directly from PyPA's example workflow structure in
    the publishing guide fetched above.
  No single PyPA/canonical doc defines "well-formed CI" as a checklist the
  way packaging.python.org does for distribution — this list is reasoned
  from (a) the scoping doc's boundary statement and (b) the concrete
  structure PyPA's own publishing-workflow example demonstrates (separate
  gated jobs, tag-triggered publish, environment approval), not a single
  quoted source. Flagged as reasoned-and-boundary-derived rather than
  directly sourced, consistent with this baseline's honesty standard.

- **Capability-detection recommended libraries — currency check** —
  impact: med — depth: table. Verified directly (fetched 2026-08-24 unless
  noted); no wholesale displacement found, but formatting/linting need an
  explicit update given sibling-domain findings already in this repo.

  | Capability | Original list | Currency finding |
  |---|---|---|
  | Config management | pydantic-settings, dynaconf | Both current and actively maintained: pydantic-settings 2.15.0 (2026-08-07, Pydantic org, Sigstore/trusted-publishing attested); dynaconf 3.3.5 (2026-08-05, 2 maintainers, regular cadence). No change. |
  | Retries | tenacity | Current: 9.1.4 (2026-02-07), 2 maintainers, active. No change. |
  | Formatting | black, ruff, autopep8 | **Update, not a correction**: Ruff's own docs state its formatter is "designed as a drop-in replacement for Black... adheres to Black's (stable) code style," with ">99.9% of lines formatted identically" on large Black-formatted codebases (Django, Zulip) — verified stable/production (e.g. f-string formatting stabilized in Ruff 0.9.0). Combined with this repo's own Code Quality finding that Ruff's `I` category replaces isort, and Checkpoint B's finding of Ruff broadly displacing single-purpose tools: **a project using `ruff format` + `ruff check` alone satisfies both the formatter and linter capability checks with one dependency** — the capability-detection logic should treat Ruff as satisfying two capability slots simultaneously, not just one, and `autopep8` should be treated as legacy (superseded, not merely "an alternative") rather than a coequal option. |
  | Linting | flake8, ruff, pylint | Same finding as above — ruff satisfies this slot; flake8/pylint remain valid detections (not wrong to have) but the "no recommended library found" fallback message should list ruff first given its now-dominant, actively-converging role across format+lint+import-sort. |
  | Type-checking | mypy, pyright | No displacement found this session (out of this domain's research scope — Code Quality's baseline already covers mypy-strict-mode adoption in depth); no change recommended here. |
  | Logging | loguru, structlog | Both installable and functioning, but **maintenance-cadence gap worth flagging**: structlog is current at 26.1.0 (2026-06-06), single dedicated maintainer (Hynek Schlawack), regular multi-release-per-year cadence including recent Python 3.15 support. loguru's latest PyPI release is **0.7.3 (2024-12-06)** — no release in the ~20 months up to this research date (2026-08-24), sole maintainer (Delgan), "Production/Stable" classifier but capped at Python 3.13 support (no 3.14/3.15 listed) vs. structlog's active 3.15 support. This doesn't mean loguru is broken or unmaintained — a stable, feature-complete library can legitimately stop needing releases — but the asymmetry (structlog actively tracking new Python versions, loguru not) is a real, verifiable signal the capability-detection fallback message should weight toward structlog rather than presenting the two as interchangeable equals. |
  | HTTP | httpx, aiohttp | aiohttp is current and very actively maintained: 3.14.3 (2026-07-23), 5 listed maintainers, Python 3.10–3.14 support. httpx's latest PyPI release is **0.28.1 (2024-12-06)** — the same ~20-month gap seen with loguru, with `1.0.dev1`–`1.0.dev5` pre-releases listed on PyPI suggesting development has continued toward a 1.0 milestone without a corresponding stable release landing yet. Flag as noted-but-uncertain rather than asserted stagnation: this could reflect genuine feature-freeze-pending-1.0 (httpx is widely depended-on as a stable interface layer) or could reflect a fetch/indexing gap in this session's tooling — worth a direct confirmation before authoring treats httpx as anything other than current, since two independent PyPI fetches (loguru and httpx) landing on the identical December 2024 date is a pattern worth a human double-check rather than silent pass-through. |
  | CLI | typer, click | Both current and actively maintained: typer 0.27.1 (2026-08-03, tiangolo/FastAPI org, monthly-ish cadence, Python 3.10–3.14) though still classified "Beta" upstream; click 8.4.2 (2026-06-24, Pallets Projects, Production/Stable). No change from the original list. |

- **Tier applicability** — impact: med — depth: table. Carried forward
  from the original domain file's table (Project layout/pyproject.toml:
  all tiers; `.env.example`/pre-commit/quality scripts: web+enterprise;
  CI/CD: web-optional/enterprise-required) with one addition — the new
  packaging & distribution subsection is **conditional on
  publishable-library status**, cross-cutting the Script/Web/Enterprise
  axis rather than fitting neatly into one tier: a script-tier throwaway
  is exempt entirely; a web-tier internal service is normally exempt too
  (services aren't published to PyPI) but should still get the subsection
  applied if it declares distribution intent; an enterprise-tier project
  that *is* a publishable library (internal package index counts) gets
  the full subsection regardless of the Script/Web/Enterprise label.

## Explicitly out of scope

- **Trusted Publishing's security mechanics** (OIDC token exchange,
  15-minute token lifetime, SLSA Provenance/PyPI Publish attestations) —
  owned by `dependency-supply-chain-security.md`, already sourced from
  `docs.pypi.org`. This domain only checks whether the *workflow config*
  uses Trusted Publishing vs. stale token secrets.
- **CI/CD pipeline security** (pinned actions/base images by SHA, credential
  hygiene in logs, poisoned-pipeline-execution vectors, artifact
  signing/attestation as a trust mechanism) — owned by
  `dependency-supply-chain-security.md`, sourced from OWASP's CI/CD Top 10
  and GitHub's Actions hardening guide. This domain owns only structural
  well-formedness (test/lint stages present, fail-on-red, staged publish).
- **`py.typed` type-correctness** (are the actual type annotations sound
  enough for `py.typed` to be an honest claim) — owned by
  `code-quality.md`. This domain owns only whether the marker file is
  present and actually included in the built/installed distribution.
- **License compatibility across the dependency tree** (do declared
  licenses conflict) — owned by `dependency-supply-chain-security.md`.
  This domain owns only whether `License-Expression` is present and
  syntactically valid SPDX.
- **Dependency vulnerability scanning, lockfile discipline, SBOM
  generation** — `dependency-supply-chain-security.md`'s territory
  entirely; not touched here even though `uv`/lockfiles are mentioned
  above as packaging-adjacent context.
- **Framework-specific packaging quirks** (Django app packaging, Flask
  blueprint distribution patterns) — consistent with this research
  program's standing rejection of framework-specific overlays at the
  domain level; deferred to a future stack-specific supplement.

## Sources

- https://packaging.python.org/en/latest/guides/writing-pyproject-toml/ —
  `[build-system]` table requirement/recommendation, backend version
  examples (hatchling, setuptools, flit_core, pdm-backend, uv_build),
  setup.py-when-needed framing — retrieved 2026-08-24
- https://packaging.python.org/en/latest/guides/packaging-namespace-packages/
  — native (PEP 420) namespace packages as current recommendation,
  pkgutil-style as legacy-compatible, pkg_resources-style removed in
  Setuptools 82.0.0 — retrieved 2026-08-24
- https://packaging.python.org/en/latest/guides/publishing-package-distribution-releases-using-github-actions-ci-cd-workflows/
  — Trusted Publishing as the recommended CI/CD publish mechanism, stale
  API-token secrets called "obsolete," TestPyPI staged on every push vs.
  PyPI gated to tags with manual-approval environment — retrieved
  2026-08-24
- https://peps.python.org/pep-0561/ — `py.typed` marker requirement,
  `package_data`-based distribution example, recursive obligation on
  sub-packages, stub-only (`-stubs`) exemption — retrieved 2026-08-24
- https://peps.python.org/pep-0639/ — `License-Expression` field, SPDX
  license-expression syntax (v2.2+), Final status, Core Metadata 2.4,
  replaces classifier-based license declaration — retrieved 2026-08-24
- https://pre-commit.com/ and https://pypi.org/project/pre-commit/ —
  pre-commit framework identity, cross-language hook orchestration value
  proposition, current version 4.6.2 (2026-08-10), active maintenance —
  retrieved 2026-08-24
- https://packaging.python.org/en/latest/guides/packaging-binary-extensions/
  — cibuildwheel/multibuild for CI cross-platform wheel builds,
  scikit-build, Cython/pybind11/cffi/SWIG for bindings, "publish binaries
  and source" recommendation — retrieved 2026-08-24
- https://packaging.python.org/en/latest/guides/making-a-pypi-friendly-readme/
  — supported README formats (plain text, RST minus Sphinx extensions,
  Markdown/CommonMark), content-type declaration requirement, `twine
  check` as the pre-publication validator — retrieved 2026-08-24
- https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/
  — both layouts presented as valid with documented tradeoffs (install
  requirement, import-shadowing protection, editable-install cleanliness)
  — no mandate for src layout — retrieved 2026-08-24
- https://packaging.python.org/en/latest/discussions/setup-py-deprecated/ —
  precise nuance: `setup.py`-as-CLI-script is deprecated, `setup.py`-as-
  Setuptools-config-file is "absolutely fine"; `pyproject.toml` "STRONGLY
  RECOMMENDED" regardless — retrieved 2026-08-24
- https://docs.astral.sh/ruff/formatter/ — Ruff formatter positioned as a
  Black drop-in replacement, >99.9% identical output on Django/Zulip,
  stable/production status (f-string formatting stabilized in Ruff 0.9.0)
  — retrieved 2026-08-24
- https://pypi.org/project/pydantic-settings/ — current version 2.15.0
  (2026-08-07), active maintenance, Pydantic-org-backed — retrieved
  2026-08-24
- https://pypi.org/project/dynaconf/ — current version 3.3.5
  (2026-08-05), active maintenance — retrieved 2026-08-24
- https://pypi.org/project/tenacity/ — current version 9.1.4
  (2026-02-07), active maintenance — retrieved 2026-08-24
- https://pypi.org/project/uv/ — uv identity ("replace pip, pip-tools,
  pipx, poetry, pyenv, twine, virtualenv, and more"), current version
  0.12.5 (2026-08-14) — retrieved 2026-08-24
- https://setuptools.pypa.io/en/latest/userguide/declarative_config.html —
  `setup.cfg` shown as a currently-supported, non-deprecated declarative
  configuration option parallel to `pyproject.toml`, plus the
  legacy-build `setup.py`-still-required interop note — retrieved
  2026-08-24
- https://packaging.python.org/en/latest/guides/packaging-namespace-packages/
  (second, targeted fetch) — re-verified `pkg_resources`-style namespace
  packages are non-functional at runtime as of Setuptools 82.0.0, not
  merely documentation-obsolete — retrieved 2026-08-24
- https://pypi.org/project/loguru/ — current version 0.7.3 (2024-12-06),
  Python 3.5–3.13 support, sole maintainer — retrieved 2026-08-24
- https://pypi.org/project/structlog/ — current version 26.1.0
  (2026-06-06), active multi-release cadence, Python 3.15 support —
  retrieved 2026-08-24
- https://pypi.org/project/httpx/ — current version 0.28.1 (2024-12-06),
  `1.0.dev1`–`1.0.dev5` pre-releases listed — retrieved 2026-08-24
- https://pypi.org/project/aiohttp/ — current version 3.14.3
  (2026-07-23), 5 maintainers, Python 3.10–3.14 support — retrieved
  2026-08-24
- https://pypi.org/project/typer/ — current version 0.27.1 (2026-08-03),
  Beta classifier upstream despite active cadence — retrieved 2026-08-24
- https://pypi.org/project/click/ — current version 8.4.2 (2026-06-24),
  Pallets Projects, Production/Stable — retrieved 2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — the exact
  required-expansion text for Standards Compliance's packaging &
  distribution subsection, and the domain boundary statements against
  Dependency & Supply Chain Security — read 2026-08-24
- `research/python-code-review/code-quality.md` (this repo) — confirms the
  `py.typed` type-correctness vs. packaging-correctness split is already
  stated consistently on that side; Ruff `I`-category-replaces-isort
  finding reused here for the formatting/linting capability-table update
  — read 2026-08-24
- `research/python-code-review/dependency-supply-chain-security.md` (this
  repo) — confirms Trusted Publishing security mechanics and CI/CD
  pipeline security are already covered there in depth, sourced from
  `docs.pypi.org` and OWASP's CI/CD Top 10 — cross-referenced rather than
  duplicated here — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/standards-compliance.md`
  (this repo) — the existing 66-line domain baseline this research
  verifies and expands; specific corrections applied to its pyproject.toml
  and src-layout claims above — read 2026-08-24

## Open questions for the user

- **loguru and httpx both show a PyPI latest-release date of exactly
  2024-12-06 — verify this isn't a fetch artifact.** All other libraries
  checked in this research (structlog, aiohttp, typer, click,
  pydantic-settings, dynaconf, tenacity, pre-commit) show release dates
  through mid-to-late 2026, consistent with the current research date.
  Two unrelated, independently-fetched libraries landing on the identical
  stale date is unlikely to be coincidence but could plausibly be a
  caching/indexing quirk of the fetch tool rather than genuine
  ~20-month release inactivity. Recommend a direct human check of
  https://pypi.org/project/loguru/#history and
  https://pypi.org/project/httpx/#history before authoring treats either
  finding as settled — if the gap is real, downgrade both from
  "equal alternative" to "legacy-leaning, verify still wanted" in the
  authored skill; if it's a fetch artifact, both should be restored to
  "current, no change" status.
- **CI/CD "well-formed" concrete checklist is reasoned, not
  single-source-quoted.** Unlike the packaging subsection (dense with
  direct PyPA quotes), the well-formedness checklist above (test stage +
  lint stage + fail-on-red + trigger coverage) is derived from the
  scoping doc's boundary statement plus the structural shape of PyPA's
  own example publish workflow, not from one canonical "what makes CI
  well-formed" source. Flagging this so authoring doesn't present it with
  more authority than it has; if a stronger canonical source exists
  (e.g. GitHub's own Actions best-practices doc, fetched already by the
  Supply Chain baseline for security angles but not for this
  well-formedness angle), a follow-up fetch of that same doc for the
  structural (non-security) guidance would strengthen this section.
- **Packaging subsection's applicability trigger** — the scoping doc says
  "conditional on the reviewed project being a publishable library" but
  doesn't define the detection heuristic precisely. This baseline suggests
  "has `[project].name`/`version` intended for index distribution, or an
  explicit publish workflow already in CI" as the detection signal —
  confirm this is the right operationalization before authoring, since a
  wrong heuristic either over-applies the subsection to internal services
  or under-applies it to internal package-index libraries.
- **uv's role**: this baseline deliberately stopped at "PyPA lists
  `uv_build` as a peer backend, don't flag it as nonstandard" rather than
  recommending uv-adoption more broadly (env/dependency management, lockfiles,
  `uv publish` as a `twine` replacement). That broader uv-as-project-manager
  territory arguably belongs partly to this domain (project tooling) and
  partly to Dependency & Supply Chain (lockfile discipline) — confirm
  whether a fuller uv treatment belongs here, there, or is out of scope for
  both at this pass.

## Target file(s) + estimated length

- skills/python-code-review/references/standards-compliance.md — est.
  260–300 lines (packaging & distribution subsection at full section
  depth given the scoping doc's explicit priority on it — now including
  the general wheel/sdist-building item alongside the binary-extension
  case — plus the corrected pyproject.toml/setup.py/setup.cfg claims,
  src-layout nuance, pre-commit currency note, CI/CD well-formedness
  definition, full eight-row capability-detection table, and tier table —
  scoring-guide and required-evidence sections mirroring the original
  tool's structure are not part of this baseline itself).
