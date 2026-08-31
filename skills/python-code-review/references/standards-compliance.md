# Standards Compliance

This is the standards-compliance domain of the `python-code-review` skill's
11-domain reference set. It asks whether a project's structural and tooling
conventions — layout, build configuration, environment handling, dev
tooling, CI/CD well-formedness, and (conditionally) packaging &
distribution hygiene — are present and correctly formed. Nothing here is
ever a Critical finding on its own: standards compliance is about
maintainability, reproducibility, and team consistency, not correctness or
security.

Three boundaries matter enough to state up front:

- [`dependency-supply-chain-security.md`](dependency-supply-chain-security.md)
  owns whether a CI/CD pipeline and its dependencies are *trustworthy* —
  Trusted Publishing's OIDC mechanics, pinned Actions, credential hygiene,
  license *compatibility* across the dependency tree, SBOM/CVE scanning.
  This domain asks the narrower, prior question: does the pipeline *exist
  and is it well-formed at all* — a test stage, a lint stage, a publish
  workflow that's configured to use Trusted Publishing rather than stale
  API-token secrets (the *fact* of the config choice, not the trust model
  behind it), and a `License-Expression` that's syntactically valid SPDX
  (not whether it *conflicts* with a dependency's license).
- [`code-quality.md`](code-quality.md) owns whether a package's types are
  *actually correct and complete* for a `py.typed` marker to be an honest
  claim. This domain owns the mechanical half: is the marker file present
  in the package directory *and* actually shipped inside the built
  wheel/sdist.
- Neither boundary is a hard wall — a project can fail this domain's
  mechanical check (marker excluded from the wheel) while passing Code
  Quality's correctness check (the types themselves are sound), and vice
  versa. Flag whichever side is actually broken; don't conflate the two.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [Project Structure](#project-structure)
- [pyproject.toml, setup.py, and setup.cfg](#pyprojecttoml-setuppy-and-setupcfg)
- [Environment & Configuration](#environment--configuration)
- [Development Tooling](#development-tooling)
- [Capability Detection](#capability-detection)
- [CI/CD: Well-Formed, Not Secure](#cicd-well-formed-not-secure)
- [Packaging & Distribution](#packaging--distribution)
- [Minor Checks](#minor-checks)
- [Scoring Guide](#scoring-guide)
- [Sources](#sources)

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Project layout (src or flat, consistently applied) | Yes | Yes | Yes |
| `pyproject.toml` present with project metadata | Yes | Yes | Yes |
| `.gitignore` with Python-specific patterns, no `__pycache__`/`.egg-info` committed | Yes | Yes | Yes |
| `tests/` directory exists and mirrors the source structure | Yes | Yes | Yes |
| Formatter + linter configured | Yes | Yes | Yes |
| Type checker configured (at least present, not necessarily CI-gated — see [Code Quality](code-quality.md)) | Yes | Yes | Yes |
| Capability-detection gaps (logging, retries, HTTP, CLI, config) | Yes | Yes | Yes |
| Storage-I/O capability gap (cloud-SDK branching detected, no abstraction) | Conditional | Conditional | Conditional |
| `.env.example` template, no `.env` committed | No | Yes | Yes |
| Pre-commit hooks (`.pre-commit-config.yaml`) | No | Yes | Yes |
| Quality/setup automation (`scripts/`) | No | Yes | Yes |
| CI/CD config present and well-formed | No | Optional | Yes |
| Packaging & distribution subsection | Conditional | Conditional | Conditional |

"Optional" for Web-tier CI/CD means a small internal service without merge
protection isn't automatically penalized, but a CI config that does exist
still owes the well-formedness checks below at full weight — "optional" is
about whether the pipeline has to exist yet, not a discount once it does.

**The packaging & distribution row is conditional at every tier, not
Script/Web/Enterprise-gated**, the same shape
[`dependency-supply-chain-security.md`](dependency-supply-chain-security.md)
uses for its ML-artifact-deserialization row: it activates on a
detected-capability signal, not on project size. Detect it as: the
project's `pyproject.toml` declares a `[project]` `name` and `version`
aimed at index distribution (not merely present because a build backend
needs *some* metadata to run tooling against), **or** the repository
already contains an explicit publish workflow (a CI job invoking `python -m
build`, `twine upload`, or a Trusted-Publishing-configured `pypa/gh-action-pypi-publish`
step). A script-tier throwaway is exempt outright. A web-tier internal
service is normally exempt too — internal services aren't published to
PyPI — but gets the subsection applied in full the moment it declares
distribution intent (an internal package index counts the same as PyPI for
this purpose). An enterprise-tier project that happens not to publish
anything gets the subsection skipped just like a script would; tier
controls maturity expectations, capability detection controls whether
packaging applies at all, and the two axes are independent.

## Project Structure

**Layout.** PyPA's own discussion of src-layout vs. flat-layout presents
**both as valid, with different tradeoffs** — it does not mandate src
layout, and treating a flat-layout project as a defect overstates PyPA's
actual position. The documented differences: src layout "requires
installation of the project to be able to run its code," while flat layout
does not; src layout "helps enforce that an editable installation is only
able to import files that were meant to be importable," guarding against
Python's CWD-first import path accidentally shadowing an installed package
with a same-named local file — a failure mode flat layout is structurally
exposed to; flat layout avoids the extra editable-install step, which
matters for a quick CLI-run-from-source workflow. **Review angle:** prefer
src-layout as the safer default for a **publishable library**, where
import-shadowing and editable-install correctness matter most — but don't
flag flat-layout as a defect for an application or script project. It's a
legitimate, PyPA-sanctioned choice there, not tolerated legacy. What both
layouts owe regardless: a `tests/` directory that mirrors the source
structure, a `.gitignore` with Python-specific patterns
(`__pycache__/`, `*.pyc`, `*.egg-info/`, `.venv/`), and none of those
generated artifacts actually committed.

## pyproject.toml, setup.py, and setup.cfg

The real distinction here is narrower than "`pyproject.toml` exists, so
`setup.py` is legacy." PyPA's own dedicated page on the subject states it
squarely: **"`setup.py` and Setuptools are not deprecated... perfectly
usable as a build backend."** What's actually deprecated is `setup.py` used
as an **executable CLI script** — `python setup.py install`,
`python setup.py bdist_wheel` — not `setup.py` used purely as Setuptools'
configuration file, which PyPA calls "absolutely fine" alongside a
`pyproject.toml` `[build-system]` table. **Review angle:** flag a project
that invokes `setup.py` as a command — in CI scripts, README install
instructions, or a Makefile — rather than going through `pip`/`python -m
build`. Do not flag a `setup.py` that exists solely as Setuptools
configuration next to a proper `[build-system]` table; that combination is
current, not legacy.

`setup.cfg` is a distinct question from `setup.py`, and Setuptools' own
userguide shows no deprecation notice for it — declarative `setup.cfg`
configuration and `pyproject.toml` configuration are documented as
parallel, coexisting options, not a deprecated-predecessor relationship.
The one real interop requirement: "if compatibility with legacy builds
(i.e. those not using the PEP 517 build API) is desired, a `setup.py` file
containing a `setup()` function call is still required even if your
configuration resides in `setup.cfg`." **Review angle:** don't flag a
`setup.cfg`-configured project as using a deprecated mechanism on that
basis alone. The question that actually matters is whether `[build-system]`
is present in `pyproject.toml` at all — independent of whether the
project's own metadata lives in `setup.cfg`, `setup.py`, or `[project]`.
PyPA states plainly that a `pyproject.toml` at the project root is
"**STRONGLY RECOMMENDED**" regardless of which of these a project uses for
its actual metadata.

## Environment & Configuration

- `.env.example` template exists at web/enterprise tier, documenting every
  variable the application reads without embedding real values.
- No `.env` file committed — it's a secrets-bearing artifact, not
  boilerplate.
- Configuration loaded via environment variables or a config library (see
  [Capability Detection](#capability-detection)), not scattered
  `os.environ[...]` calls with no central schema.
- No hardcoded connection strings, API keys, or credentials in source —
  this overlaps with `security.md`'s hardcoded-secrets check; either domain
  catching it is sufficient, don't require both to fire.

## Development Tooling

- **Formatter** configured — `ruff format`, `black`, or (legacy) `autopep8`
  wired into `pyproject.toml` or a dedicated config file. See
  [Capability Detection](#capability-detection) for the current
  formatter/linter-consolidation finding.
- **Linter** configured — `ruff check`, `flake8`, or `pylint`.
- **Type checker** configured — `mypy` or `pyright` present in dependencies
  and configured, at minimum. Whether it's actually run in CI, and at what
  strictness, is [Code Quality](code-quality.md)'s deeper lens; this domain
  only checks that the tool is set up at all.
- **Pre-commit hooks** (`.pre-commit-config.yaml`) at web/enterprise tier.
  `pre-commit` (current: 4.6.2, released 2026-08-10, actively maintained by
  its primary maintainer with pre-commit.ci integration) remains the
  standard multi-language git-hook framework — no displacement found. Its
  value-add is specifically **cross-language hook orchestration**: running
  linters written in languages the project doesn't otherwise depend on
  "without adding a Gemfile... or understanding how to get scss-lint
  installed," plus environment isolation that auto-downloads and builds
  each hook's toolchain without requiring root. This is a distinct niche
  from what `uv` displaces (Python package/env/build-tool management) —
  `uv` doesn't claim pre-commit's cross-language hook-runner role, so
  recommending both together isn't redundant.

## Capability Detection

For each capability in a project's recommended-library configuration:
scan `pyproject.toml` dependencies and import statements; if a recommended
library is found, no comment; if an alternative serving the same
capability is found, an informational note; if nothing for the capability
is detected, flag it at the configured severity and suggest from the
recommended list (e.g. "No structured logging detected. Consider:
structlog, loguru").

| Capability | Recommended | Currency notes |
|---|---|---|
| Config management | `pydantic-settings`, `dynaconf` | Both current and actively maintained: pydantic-settings 2.15.0 (2026-08-07, Pydantic-org-backed); dynaconf 3.3.5 (2026-08-05, regular cadence). No change from either being an equal choice. |
| Retries | `tenacity` | Current: 9.1.4 (2026-02-07), actively maintained, no displacement found. |
| Formatting | `ruff format` (preferred), `black`, `autopep8` (legacy) | Ruff's formatter is documented as "designed as a drop-in replacement for Black... adheres to Black's (stable) code style," with over 99.9% of lines formatted identically on large Black-formatted codebases (Django, Zulip) — stable and production-ready. Combined with the finding below, **a project running `ruff format` + `ruff check` alone satisfies both the formatter and linter slots with one dependency** — treat that as a full pass on both rows, not a partial one. Treat `autopep8` as superseded, not a coequal alternative. |
| Linting | `ruff check` (preferred), `flake8`, `pylint` | Same consolidation as above: Ruff's `I` category also replaces `isort`-driven import sorting (see [Code Quality](code-quality.md)), so a Ruff-only setup is now the dominant, actively-converging default across format + lint + import-sort. `flake8`/`pylint` remain valid, non-wrong detections; when nothing is detected, list Ruff first in the fallback suggestion. |
| Type-checking | `mypy`, `pyright` | No displacement found; both current. [Code Quality](code-quality.md) owns the deeper strictness-adoption question — this row only checks presence. |
| Logging | `structlog` (lead), `loguru` | **Not interchangeable equals — weight the fallback toward structlog.** structlog is current at 26.1.0 (2026-06-06), on a regular multi-release-per-year cadence, with active Python 3.15 support. loguru's latest release is **0.7.3, shipped 2024-12-06** — confirmed by a direct re-fetch of its PyPI release history at authoring time: zero releases of any kind (stable or pre-release) in the ~20 months since, a single maintainer, and a "Production/Stable" classifier capped at Python 3.13 with no 3.14/3.15 support listed. This doesn't mean loguru is broken — a stable, feature-complete library can legitimately stop needing releases — but the asymmetry against structlog's active version-tracking is real and verifiable. Detection still passes on either library; the *fallback suggestion* when neither is found should name structlog first. |
| HTTP | `httpx`, `aiohttp`, `requests` | **Resolved, not stale — a closer look changes the read from the baseline.** aiohttp is unambiguously current: 3.14.3 (2026-07-23), five listed maintainers, Python 3.10–3.14 support. httpx's latest *stable* release is also 0.28.1 from 2024-12-06 — the same date pattern that flagged loguru — but a direct re-fetch of httpx's full release history shows active `1.0.dev` pre-releases continuing well past that date: `1.0.dev1` (2025-07-02) through **`1.0.dev5` (2026-08-21)**, three days before this document's authoring date. httpx isn't stagnant; it's mid-stabilization toward a 1.0 cut and shipping pre-releases on a real cadence rather than stable point releases. Treat httpx as fully current with no caveat — the loguru/httpx date coincidence was real but coincidental, not a shared signal of the same problem. **`requests` belongs in this list, not as a legacy fallback but as the correct choice for the common case**: synchronous call sites (a Script-tier CLI hitting one API, or any code with no `async def` in its call chain) should not be flagged for using `requests` over httpx/aiohttp — it remains actively maintained (pushed same-day in a direct currency check) and is the more appropriate, lower-ceremony pick when nothing in the call path is async. Reserve the "consider httpx/aiohttp" suggestion specifically for code already inside an async call chain that's reaching for `requests` anyway (a real anti-pattern: sync HTTP calls block the event loop) — don't suggest it as a blanket upgrade from a correctly-synchronous `requests` usage. |
| CLI | `typer`, `click` | Both current: typer 0.27.1 (2026-08-03, FastAPI-org-backed, Python 3.10–3.14, still "Beta" classified upstream despite the active cadence); click 8.4.2 (2026-06-24, Pallets Projects, "Production/Stable"). No change. |
| Storage I/O | `smart_open`, `fsspec` | **Only flagged when a real capability gap is detected, not on every project.** This capability activates specifically when the codebase directly imports a cloud-provider SDK (`boto3`, `azure-storage-blob`, `google-cloud-storage`) for file read/write operations across more than one path in the code, or across more than one provider — the concrete pain this row exists to catch is application code that has to know and branch on *which* cloud SDK to call for a given path, boilerplate that `smart_open` (a drop-in `open()` replacement across S3/GCS/Azure/local, streaming-scoped) or `fsspec` (a fuller filesystem abstraction — `ls`/`glob`/`cp`/`rm` — across the same backends) eliminates. A project that only ever talks to one cloud provider's SDK directly, with no cross-provider branching, isn't a real instance of this pain and shouldn't be flagged — this is a narrower, more conditional capability than logging/config/retries, closer in shape to the ML-artifact-deserialization or task-queue rows' capability-gated activation than to an always-checked row. smart_open: 3,456 stars, pushed 2026-08-04, PyPI 8.0.1. fsspec: pushed 2026-08-28, PyPI 2026.7.0 — also worth recognizing as already present transitively (pandas/dask/pyarrow/Hugging Face `datasets` all pull it in), so its mere presence in a lockfile doesn't by itself prove the project chose it deliberately for this purpose. |
| Validation | `pydantic` (lead), `marshmallow`, `attrs`, `msgspec` | **Not four interchangeable equals — weight the fallback toward pydantic, but recognize the others by what they're actually for.** pydantic (v2, Rust core) is the default for general-purpose validation of any object crossing a trust boundary — config, internal pipeline payloads, request bodies. `marshmallow`/`attrs` remain valid, non-wrong detections for codebases that adopted them before pydantic v2's rewrite. `msgspec` is a real, narrower, performance-focused alternative — not a pydantic replacement — for the specific case where raw serialization/validation throughput on a hot path is the binding constraint and pydantic's fuller validator/plugin surface isn't needed; detect it as a pass, but don't suggest it in the generic fallback message ahead of pydantic, since it solves a narrower problem most projects don't have. |

`uv` is worth recognizing but not recommending here: PyPA's own
`pyproject.toml` guide lists `uv_build` as a supported `[build-system]`
backend alongside hatchling, setuptools, flit_core, and pdm-backend — real
signal that uv has reached peer-backend status, not third-party curiosity.
But PyPA's guide doesn't state a preference for it over the other four, so
the correct posture is *recognize `uv_build`-based projects as standard,
don't flag them as nonstandard* — not *recommend migrating to uv*. Its
broader role as a `pip`/`poetry`/`twine`/`virtualenv` replacement is
env/dependency-management territory this domain and
[`dependency-supply-chain-security.md`](dependency-supply-chain-security.md)
both intentionally leave alone for now.

## CI/CD: Well-Formed, Not Secure

This domain owns whether a CI/CD config *exists and is well-formed*;
[`dependency-supply-chain-security.md`](dependency-supply-chain-security.md)
owns pipeline *security* (pinned Actions/base images by SHA, credential
hygiene in logs, poisoned-pipeline-execution vectors, artifact signing).
Concretely, "well-formed" here means, independent of any security posture:

- A test-execution stage exists and actually *runs* the project's test
  suite — not just a `pip install` step with no invocation after it.
- A lint/format-check stage exists and runs in check-only mode (`ruff
  check`, not `ruff format` with no `--check`/CI enforcement — a bare
  format run rewrites files locally but proves nothing in CI).
- The pipeline is configured to **fail the build on a non-zero exit** from
  either stage — a red test run or lint failure actually blocks merge
  rather than only reporting informationally. This is the concrete,
  reviewable form of "CI exists" vs. "CI exists but is decorative."
- Triggers cover both PR and push events feeding into branch/merge
  protection, not only a manual or scheduled trigger nobody is required to
  pass.
- For a publishable-library project, the publish workflow itself is
  well-formed per [Packaging & Distribution](#packaging--distribution)
  below: a TestPyPI stage present, PyPI publishing gated to tags/releases
  rather than triggered on every push.

No single canonical source defines "well-formed CI" as a checklist the way
`packaging.python.org` does for distribution — this list is reasoned from
the boundary against the security domain above, plus the concrete
structure PyPA's own example publishing workflow demonstrates (separate
gated jobs, tag-triggered publish, environment approval). Present it as
reasoned guidance, not a directly-quoted standard.

## Packaging & Distribution

Apply this subsection only when the detection heuristic in [Tier
Applicability](#tier-applicability) fires — a publishable library, not
every project with a `pyproject.toml`. Skip it entirely for a non-published
application or script rather than penalizing it for packaging metadata it
has no use for. Every check below is grounded directly in PyPA's own
packaging guide.

**`[build-system]` table.** PyPA calls it "strongly recommended... should
always be present, regardless of which build backend you use." Current
backend choices and PyPA's own documented minimum-version examples:
`hatchling >= 1.26`, `setuptools >= 77.0.3`, `flit_core >= 3.12.0, <5`,
`pdm-backend >= 2.4.0`, and `uv_build >= 0.12.5, <0.13.0`. Flag a
publishable project with no `[build-system]` table at all, or one still
invoking `python setup.py sdist`/`bdist_wheel` as a command instead of
going through a backend (see the [setup.py nuance](#pyprojecttoml-setuppy-and-setupcfg)
above).

**Namespace packages.** PyPA's current recommendation is **native
namespace packages (PEP 420)** — omit `__init__.py` from the namespace
directory — "recommended if packages in your namespace only ever need to
support Python 3 and installation via pip." `pkgutil`-style
(`pkgutil.extend_path()` in `__init__.py`) is legacy but largely
compatible. `pkg_resources`-style is not merely deprecated-in-docs — a
direct, second fetch of PyPA's exact text confirms it's **non-functional at
runtime as of Setuptools 82.0.0**: "The information in this section is
obsolete and is no longer functional (as of Setuptools 82.0.0). It is only
retained for historical reference," and separately, "`pkg_resources` has
been deprecated and was fully removed in Setuptools 82.0.0." Flag any
project still relying on `pkg_resources`-style namespace declarations as
**broken** on any environment with Setuptools ≥82.0.0 installed — a
correctness failure, not a style-outdated one.

**`py.typed` — packaging-correctness half only.** PEP 561 requires the
marker file to be **included in the installed distribution** (historically
via `package_data`/`MANIFEST.in`, now via the build backend's include
rules in `pyproject.toml`), and the obligation is recursive — "if a
top-level package includes it, all its sub-packages MUST support type
checking as well." This domain's angle is purely mechanical: is the file
present in the package directory *and* actually shipped in the built
wheel/sdist. A common real-world bug is the marker existing in the repo
while the build backend's include globs — often written to catch only
`*.py` — silently exclude it, so it never reaches the installed package.
Whether the package's types are *actually correct* for the marker to be an
honest claim is [Code Quality](code-quality.md)'s question, not this one —
see the boundary note at the top of this document.

**TestPyPI staging.** PyPA's CI/CD publishing guide documents publishing
every push to TestPyPI as routine practice — "useful for providing test
builds to your alpha users as well as making sure that your release
pipeline remains healthy" — with PyPI-proper publishing gated to tag
pushes only (`if: startsWith(github.ref, 'refs/tags/')`) behind a
manual-approval environment. Flag a release pipeline that publishes to
PyPI directly with no TestPyPI dry-run stage as a process gap, independent
of any security concern.

**Trusted Publishing — config-correctness angle only.** PyPA's guide
states plainly that Trusted Publishing is "recommended for security
reasons, since the generated tokens are created for each of your projects
individually and expire automatically," and that the old
`PYPI_API_TOKEN`/`TEST_PYPI_API_TOKEN` repo-secret pattern is "obsolete now
and you should remove them." This domain's check stops at whether the
workflow YAML is *configured* to use Trusted Publishing at all, and
whether stale API-token secrets are still present — the security mechanics
(15-minute short-lived tokens, OIDC exchange, SLSA Provenance/PyPI Publish
attestations) belong to
[`dependency-supply-chain-security.md`](dependency-supply-chain-security.md),
which covers them in depth sourced from `docs.pypi.org`.

**README rendering.** PyPI's renderer accepts plain text,
reStructuredText (Sphinx-only extensions excluded), and Markdown
(GitHub-Flavored/CommonMark), and the content type must be declared —
historically `long_description_content_type`, now the `readme` key's
inferred or explicit content-type in `pyproject.toml`. PyPA's own
pre-publication check is `twine check dist/*`, which validates rendering
and prints a pass/fail result. Flag a publishable project whose README
uses Sphinx-only RST directives, or declares no content-type at all — it
will render as raw or broken markup on PyPI, a concretely checkable defect
rather than a style nit.

**Wheel/sdist building — the general case, not just binary extensions.**
For any publishable project, compiled or pure-Python, PyPA's own guide
invokes the build step as `python -m build`, producing both an sdist and a
wheel into `dist/`, followed by `twine check dist/*` before upload — the
current invocation, not the legacy `python setup.py sdist bdist_wheel`.
Independent of the binary-extension check below: does the release process
actually produce **both** artifact types, and does `twine check` (or
equivalent) run before upload rather than trusting a silent build to have
succeeded. An sdist-only release forces every installer through a full
source build; a wheel-only release breaks platforms or Python versions
without a matching prebuilt wheel, and breaks any user who
`pip install --no-binary`.

**Binary-extension compilation** (conditional on the project actually
containing compiled extensions). PyPA names **cibuildwheel** and
**multibuild** as the CI-oriented tools for building "highly
redistributable binaries" across platforms and Python versions, and
**scikit-build** for abstracting cross-platform build operations. For the
C/C++ binding layer itself, PyPA lists Cython, pybind11, cffi, and SWIG as
alternatives to hand-written extension code. PyPA's stated preference is
explicit: "strongly recommended that you publish your binary extensions as
well as the source code that was used to build them" — ship both wheels
and an sdist, not binary-only. A project with a C extension that ships
only a source distribution (forces every installer to have a working
compiler toolchain) or only ships wheels for one platform is a
distribution gap.

**Licensing declaration — syntax and presence angle only.** PEP 639
(Final, updates Core Metadata to 2.4) introduces `License-Expression`, a
field whose value must be a syntactically valid **SPDX license expression**
(v2.2+) — e.g. `MIT`, `BSD-3-Clause`, `MIT AND (Apache-2.0 OR
BSD-2-Clause)`, `GPL-3.0-only WITH Classpath-Exception-2.0`, or a
`LicenseRef-*` identifier for non-SPDX/proprietary terms.
`License-Expression` **replaces** the legacy `license`-classifier
approach; tools should stop emitting license classifiers once it's
present. This domain's angle is purely syntactic: is a `License-Expression`
present at all, and is its value a valid SPDX expression, versus free text
like `"MIT License"` or a classifier-only declaration. Whether the
declared license actually *conflicts* with a dependency's license is
[`dependency-supply-chain-security.md`](dependency-supply-chain-security.md)'s
question, sourced there in depth alongside `pip-licenses` enumeration.

**`uv` as an emerging backend, not a migration target.** See the note at
the end of [Capability Detection](#capability-detection) — recognize
`uv_build`-configured projects as standard, don't recommend adopting uv
more broadly as part of this check.

## Minor Checks

- `README.md` present with an actual project description, not a
  placeholder.
- `CHANGELOG.md` present.
- `scripts/` directory with quality/setup automation, at web/enterprise
  tier.
- `docs/` directory for documentation beyond the README, where the
  project's surface area warrants it.
- A license file present at the repository root, distinct from (but
  consistent with) the `License-Expression` check above.

## Scoring Guide

Nothing in this domain is ever a Critical finding on its own — score
against Important and Minor gaps among the tier-applicable (and, for
packaging, capability-gated) checks above.

- **10** — All Important checks pass at the project's tier; all Minor
  items present; the packaging subsection (if applicable) fully compliant,
  including Trusted Publishing configured and a TestPyPI stage present.
- **8–9** — All Important checks pass; a small number of Minor items
  missing (no `CHANGELOG.md`, no `docs/`).
- **6–7** — Most Important checks pass; 1–2 gaps in capability detection or
  dev tooling (e.g. no pre-commit at web tier, one recommended-capability
  slot undetected).
- **4–5** — Missing `pyproject.toml` or no recognizable layout at all;
  multiple capability-detection gaps; for a publishable project, no
  `[build-system]` table or a broken `py.typed`/README-rendering defect.
- **1–3** — No recognizable project structure; widespread capability and
  tooling gaps; for a publishable project, still using stale API-token
  secrets with no Trusted Publishing, or shipping neither a wheel nor a
  working sdist.

## Sources

- <https://packaging.python.org/en/latest/guides/writing-pyproject-toml/>
  — `[build-system]` table requirement/recommendation, per-backend
  minimum-version examples (hatchling, setuptools, flit_core, pdm-backend,
  uv_build), `setup.py`-when-needed framing — retrieved 2026-08-24
- <https://packaging.python.org/en/latest/guides/packaging-namespace-packages/>
  — native (PEP 420) namespace packages as the current recommendation,
  `pkgutil`-style as legacy-compatible; re-fetched a second time to confirm
  `pkg_resources`-style namespace packages are non-functional at runtime as
  of Setuptools 82.0.0, not merely documentation-obsolete — retrieved
  2026-08-24
- <https://packaging.python.org/en/latest/guides/publishing-package-distribution-releases-using-github-actions-ci-cd-workflows/>
  — Trusted Publishing as the recommended CI/CD publish mechanism, stale
  API-token secrets called "obsolete," TestPyPI staged on every push vs.
  PyPI gated to tags behind a manual-approval environment — retrieved
  2026-08-24
- <https://peps.python.org/pep-0561/> — `py.typed` marker requirement,
  `package_data`-based distribution example, recursive sub-package
  obligation — retrieved 2026-08-24
- <https://peps.python.org/pep-0639/> — `License-Expression` field, SPDX
  license-expression syntax (v2.2+), Final status, Core Metadata 2.4,
  replaces classifier-based license declaration — retrieved 2026-08-24
- <https://pre-commit.com/> and <https://pypi.org/project/pre-commit/> —
  pre-commit's cross-language hook-orchestration identity, current version
  4.6.2 (2026-08-10), active maintenance — retrieved 2026-08-24
- <https://packaging.python.org/en/latest/guides/packaging-binary-extensions/>
  — cibuildwheel/multibuild for CI cross-platform wheel builds,
  scikit-build, Cython/pybind11/cffi/SWIG for bindings, "publish binaries
  and source" recommendation — retrieved 2026-08-24
- <https://packaging.python.org/en/latest/guides/making-a-pypi-friendly-readme/>
  — supported README formats, content-type declaration requirement, `twine
  check` as the pre-publication validator — retrieved 2026-08-24
- <https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/>
  — both layouts presented as valid with documented tradeoffs, no mandate
  for src layout — retrieved 2026-08-24
- <https://packaging.python.org/en/latest/discussions/setup-py-deprecated/>
  — `setup.py`-as-CLI-script deprecated, `setup.py`-as-Setuptools-config
  "absolutely fine," `pyproject.toml` "STRONGLY RECOMMENDED" regardless —
  retrieved 2026-08-24
- <https://setuptools.pypa.io/en/latest/userguide/declarative_config.html>
  — `setup.cfg` as a currently-supported, non-deprecated configuration
  option parallel to `pyproject.toml`, plus the legacy-build
  `setup.py`-still-required interop note — retrieved 2026-08-24
- <https://docs.astral.sh/ruff/formatter/> — Ruff formatter positioned as a
  Black drop-in replacement, >99.9% identical output on Django/Zulip,
  stable/production status — retrieved 2026-08-24
- <https://pypi.org/project/pydantic-settings/> — current version 2.15.0
  (2026-08-07) — retrieved 2026-08-24
- <https://pypi.org/project/dynaconf/> — current version 3.3.5
  (2026-08-05) — retrieved 2026-08-24
- <https://pypi.org/project/tenacity/> — current version 9.1.4
  (2026-02-07) — retrieved 2026-08-24
- <https://pypi.org/project/uv/> — uv's own "replace pip, pip-tools, pipx,
  poetry, pyenv, twine, virtualenv, and more" framing, current version
  0.12.5 (2026-08-14) — retrieved 2026-08-24
- <https://pypi.org/project/loguru/#history> and
  <https://pypi.org/pypi/loguru/json> — authoring-time re-check: latest
  release 0.7.3, uploaded 2024-12-06T11:20:54Z; no release of any kind
  (stable or pre-release) in the full history since — confirms the
  ~20-month staleness is real, not a fetch artifact — retrieved 2026-08-24
- <https://pypi.org/project/structlog/> — current version 26.1.0
  (2026-06-06), active multi-release cadence, Python 3.15 support —
  retrieved 2026-08-24
- <https://pypi.org/pypi/httpx/json> and
  <https://pypi.org/project/httpx/#history> — authoring-time re-check:
  latest *stable* release 0.28.1 (2024-12-06), the same date pattern seen
  with loguru, but the full history shows active `1.0.dev1` (2025-07-02)
  through `1.0.dev5` (2026-08-21) pre-releases — resolves the baseline's
  open question: httpx is actively developed toward a 1.0 milestone via
  pre-releases, not stagnant; the loguru/httpx date coincidence was real
  but not a shared signal — retrieved 2026-08-24
- <https://pypi.org/project/aiohttp/> — current version 3.14.3
  (2026-07-23), five maintainers, Python 3.10–3.14 support — retrieved
  2026-08-24
- `gh api repos/psf/requests` — 54,269 stars, pushed 2026-08-31 (same-day
  currency check); <https://pypi.org/project/requests/> — current version
  2.34.2 — retrieved 2026-08-31, cross-checked against
  `research/cross-cutting-utility-libraries/batch-a.md`'s own HTTP-client
  research pass the same day
- `gh api repos/piskvorky/smart_open` — 3,456 stars, pushed 2026-08-04;
  <https://pypi.org/project/smart_open/> — current version 8.0.1 —
  retrieved 2026-08-31
- `gh api repos/fsspec/filesystem_spec` — pushed 2026-08-28;
  <https://pypi.org/project/fsspec/> — current version 2026.7.0 —
  retrieved 2026-08-31
- <https://pypi.org/project/msgspec/> — current version 0.21.1, a
  narrower, performance-focused validation/serialization library, distinct
  in scope from pydantic rather than competing on the same feature surface
  — retrieved 2026-08-31
- <https://pypi.org/project/typer/> — current version 0.27.1 (2026-08-03),
  Beta classifier upstream despite active cadence — retrieved 2026-08-24
- <https://pypi.org/project/click/> — current version 8.4.2 (2026-06-24),
  Pallets Projects, Production/Stable — retrieved 2026-08-24
- `research/python-code-review/standards-compliance.md` (this repo) — the
  approved research baseline this reference was authored from, including
  the Checkpoint C resolutions this document implements — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/standards-compliance.md`
  (this repo) — the original 66-line domain baseline this file expands and
  corrects (src-layout mandate and the pyproject.toml/setup.py binary claim
  both nuanced above) — read 2026-08-24
- [`code-quality.md`](code-quality.md) (this repo) — confirms the
  `py.typed` type-correctness vs. packaging-correctness split is stated
  consistently on both sides — read 2026-08-24
- [`dependency-supply-chain-security.md`](dependency-supply-chain-security.md)
  (this repo) — confirms Trusted Publishing security mechanics, CI/CD
  pipeline security, and license-compatibility checking are covered there
  in depth and cross-referenced rather than duplicated here — read
  2026-08-24
