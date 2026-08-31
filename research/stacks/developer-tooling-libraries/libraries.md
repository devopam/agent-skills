# Baseline: Developer Tooling & Libraries — Preferred Libraries
Status: draft      Date: 2026-08-31      Snapshot date: 2026-08-31

**Library recommendations here are more time-sensitive than stack.md** —
package-manager/build-backend adoption in the Python ecosystem specifically
has shifted meaningfully even within 2026 (uv's download share below), so
treat every download/star figure as a snapshot of 2026-08-31, not a durable
fact.

## Local precedent

Two real local candidates exist for this category, per the task brief — one
directly inspectable, one not:

1. **This very repo**, `/Users/devopammittra/GitHub/agent-skills` — directly
   inspected this pass. It has **no `pyproject.toml` and no `package.json`
   anywhere in the tree** (confirmed: `find . -maxdepth 1 -name
   pyproject.toml -o -maxdepth 1 -name package.json` returns nothing). It is
   distributed instead via `.claude-plugin/plugin.json`:
   ```json
   {
     "name": "agent-skills",
     "version": "0.2.0",
     "description": "...",
     "author": {"name": "Devopam Mittra", "email": "devopam@gmail.com"}
   }
   ```
   Four fields only — no `dependencies`, no `build-backend`, no `scripts`,
   no entry-point declarations. Versioning is real (SemVer, per
   `CONTRIBUTING.md`'s own versioning section, currently `0.2.0`) and a real
   `CHANGELOG.md` exists following the Keep a Changelog convention — but
   there is no build step, no publish step, and no package registry
   involved at all. This is itself the load-bearing local evidence for this
   baseline's ecosystem-choice section below: a **prompt/skill-content-only
   artifact has a materially different "packaging" story than a code
   library** — its distribution unit is a git-cloned or marketplace-
   installed directory, not a built wheel/tarball/sdist.
2. **MCPg** — named in the roadmap doc and in the existing
   `agentic-mcp-platforms` baselines as this category's other local example,
   but **it does not exist on this machine** (confirmed: only
   `agent-skills` and `ubi-csr-tmf` exist under `/Users/devopammittra/
   GitHub/`, checked directly this pass via `ls`). Everything below about
   MCPg is therefore **secondhand, from grepping the already-written
   `agentic-mcp-platforms/*.md` baselines**, not from this pass's own
   inspection:
   - `agentic-mcp-platforms/libraries.md` cites `MCPg\docs\adr\
     0002-technology-stack.md` as recording MCPg's stack choice of `uv` as
     its package/dependency manager (alongside `pytest`, `ruff`,
     `mypy --strict`) — i.e. MCPg's own ADR already picked `uv` over
     Poetry/PDM/Hatch for its own packaging, which is a real (if secondhand)
     data point for this baseline's build-backend section.
   - `agentic-mcp-platforms/stack.md` states MCPg "ships to PyPI, GHCR, the
     MCP registry, Smithery, and an HF Spaces demo simultaneously" — i.e.
     MCPg is a real example of a single package needing to satisfy *both*
     a traditional PyPI packaging story *and* an MCP-registry/Claude-
     plugin-style distribution story, which directly motivates including
     "Claude Code plugins / MCP registries" as its own row below rather
     than treating PyPI/npm/crates.io as the only distribution channels
     that matter for this category in 2026.
   - Neither existing baseline names MCPg's specific build backend
     (setuptools/Hatchling/pdm-backend/etc.) or license — those details
     were out of scope for what the Agentic & MCP Platforms pass recorded,
     so this baseline does not claim them.
3. `/Users/devopammittra/GitHub/ubi-csr-tmf` — checked directly this pass
   (`ls`/`find` to two levels). **Not relevant to this category**: it's a
   TMF/CSR business-application repo (Helm charts under `charts/`,
   `ubi-csr-tmf-helm-charts/`, an `openwiki/` docs tree, a
   `postman-collection/` of API test collections, `architecture/` diagrams,
   AWS container deployment config) — a deployed application with its own
   infrastructure, not a publishable SDK/CLI/library consumed by other
   developers. No `pyproject.toml`/`package.json`/`Cargo.toml` build-backend
   or registry-publish concern was found in its top two directory levels.
   Excluded from further consideration in this baseline.

## Ecosystem choice

**Python and TypeScript/Node**, consistent with this baseline's own
`backend-api-services` precedent, plus **Rust/crates.io as a genuine third
ecosystem** — verified rather than assumed per the task's steer. Rust
earns real estate here specifically because two of the task's named Rust
tools turned out to be live, maintained, and heavily used on direct fetch:
**Clap** (crates.io: 1,087,757,770 cumulative downloads, dual-licensed
`MIT OR Apache-2.0`) and **cargo-semver-checks** (an actual, actively
released compat-checking tool with no close Python/JS equivalent — see
below). Cargo's own built-in `cargo publish`/`cargo build` mechanics are
covered briefly for completeness since the task explicitly asks for them,
but this baseline does **not** attempt a full Rust web-framework-style
survey — Rust is in scope here narrowly as "the CLI-tooling and
compat-checking ecosystem," not as a third fully-researched ecosystem on
par with Python/TS.

**Claude Code plugins / MCP registries** are named as a fourth,
non-traditional "distribution channel" row (see the dedicated section
below) rather than a fourth programming-language ecosystem — this repo's
own `.claude-plugin/plugin.json` and MCPg's multi-channel shipping
(PyPI + MCP registry + Smithery + GHCR simultaneously, per secondhand
citation above) are the two pieces of evidence that this is now a real,
distinct concern for "developer tooling" broadly, not a niche.

## In scope

### Build backends / packaging tools — impact: high — depth: table + decision rule

**Python** — adoption has shifted meaningfully within 2026 itself; PyPI
download-count order (this pass, week of 2026-08-23–29, via `pypistats.org`)
does **not** match popular perception, and that gap is worth stating
explicitly rather than defaulting to "everyone uses Poetry":

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **uv** (`astral-sh/uv`) — **default for new projects** | All-in-one Python package/project manager: dependency resolution, venv management, `uv build` (PEP 517 build frontend), `uv publish` | Apache-2.0 (dual Apache-2.0/MIT per repo) | The fastest-growing tool of this group by a wide margin and the one MCPg's own ADR-0002 already picked (secondhand, see Local precedent) over Poetry/PDM; a single binary replacing pip+venv+pip-tools+twine's separate roles | 2026-08-31 | Direct GitHub fetch: 89,256 stars, 3,531 forks, 2,866 open issues, pushed 2026-08-31 (commits same day as this pass); direct PyPI fetch: v0.12.7; direct PyPI-downloads fetch: **29.9M/week** — roughly 3× Poetry's weekly volume and >15× Hatch's or PDM's, the clearest quantitative signal in this table |
| Hatchling (build backend) / **Hatch** (project manager, `pypa/hatch`) | PEP 517 build backend + project-management CLI; the backend recommended by the Python Packaging Authority's own packaging guide | MIT | PyPA-adjacent (the `pypa` GitHub org itself), zero-config for most pure-Python projects, plugin system for custom build hooks | 2026-08-31 | Direct GitHub fetch: 7,231 stars, 454 forks, 439 open issues, pushed 2026-08-18; direct PyPI fetch: v1.18.0 (`hatchling` backend itself: v1.32.0); direct PyPI-downloads fetch: 1.9M/week |
| **Poetry** (`python-poetry/poetry`) | Dependency management + build backend (`poetry-core`) + publish, opinionated `pyproject.toml`-native workflow | MIT | Still the most-starred of the non-uv tools and the longest-established "one tool does everything" option; the honest 2026 caveat is that it now trails uv on both stars and raw download volume by a wide margin, a genuine change from its previous multi-year position as the default recommendation | 2026-08-31 | Direct GitHub fetch: 34,296 stars, 2,481 forks, 569 open issues, pushed 2026-08-29 (active); direct PyPI fetch: v2.4.2 (`poetry-core`: v2.4.1); direct PyPI-downloads fetch: 10.6M/week |
| PDM (`pdm-project/pdm`) | PEP 582/621-native dependency manager + build backend (`pdm-backend`), fastest dependency resolver of the group per multiple comparison sources | MIT | Named for completeness and its standards-first (PEP 621) design; smaller community than the three above makes it a defensible but non-default pick | 2026-08-31 | Direct GitHub fetch: 8,671 stars, 488 forks, only 45 open issues (unusually low — may reflect a smaller, tightly-scoped user base rather than exceptional issue velocity), pushed 2026-08-31; direct PyPI fetch: v2.29.0 (`pdm-backend`: v2.4.9); direct PyPI-downloads fetch: 2.5M/week |
| setuptools (`pypa/setuptools`) | The historical default PEP 517 build backend; still what many existing/legacy Python packages use | MIT | Not recommended as the default for a **new** project in 2026 — no integrated dependency management, `setup.py`/`setup.cfg` verbosity the tools above eliminate — named because it remains, by a very wide margin, the most-downloaded backend by raw usage (legacy-package inertia, directly parallel to Express's position in the backend-api-services baseline) | 2026-08-31 | Direct GitHub fetch: 2,856 stars, 1,426 forks, 696 open issues, pushed 2026-08-09; direct PyPI fetch: v84.0.0; direct PyPI-downloads fetch: **238.7M/week** — dwarfs every tool above, almost entirely legacy/transitive-dependency pull rather than new-project choice |

**Decision rule**: new Python library/CLI project → **uv** as the default
(build + publish + dependency management in one tool, and the fastest-
growing by every signal fetched this pass); PyPA-guide-alignment preference
or a team already invested in Hatch's plugin system → **Hatchling**;
existing Poetry-based codebase → keep Poetry, not a reason to migrate
mid-project; setuptools → maintenance of legacy packages only, not a new-
project recommendation.

**Node/TypeScript:**

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **tsc** (`microsoft/TypeScript`, bundled compiler) | Type-checking + the simplest "just emit `.d.ts` and `.js`" build for a library with no bundling need | Apache-2.0 | The zero-extra-dependency default when a package doesn't need bundling (pure ESM/CJS dual-output libraries with few files) — also the tool every other option here still depends on for type-checking/declaration generation | 2026-08-31 | Direct GitHub fetch: 110,796 stars, 13,785 forks, pushed 2026-08-31 |
| **tsup** (`egoist/tsup`) | Zero-config bundler for TS libraries, built on esbuild; the most commonly recommended default for publishing a package to npm today | MIT | Handles ESM+CJS dual output, `.d.ts` generation, and minification with near-zero config — the most frequently recommended tool in current library-publishing guides for exactly this reason | 2026-08-31 | Direct GitHub fetch: 11,293 stars, 273 forks, pushed 2026-07-20 |
| Rollup (`rollup/rollup`) | Lower-level bundler tsup itself and Vite's library mode are both built on; direct use suits libraries needing fine-grained control over output chunks/plugins | MIT (confirmed via direct `LICENSE.md` fetch — GitHub's license-detection API misreported this repo as `NOASSERTION`, a detection artifact, not a real licensing ambiguity) | The right choice when a project has outgrown tsup's zero-config defaults and needs custom Rollup plugins directly | 2026-08-31 | Direct GitHub fetch: 26,305 stars, 1,768 forks, pushed 2026-08-31 |
| Vite (library mode) (`vitejs/vite`) | Bundling a library alongside an existing Vite-based app/monorepo, reusing the same tool for both app-dev and library-build | MIT | Not a separate tool to adopt in isolation — named because a team already on Vite for app development can build its companion library with the same tool (`build.lib` config) instead of introducing tsup/Rollup as a second bundler | 2026-08-31 | Direct GitHub fetch: 82,612 stars, 8,688 forks, pushed 2026-08-31 (the most-starred tool in this entire table, though that reflects Vite's dominance as an app dev-server/bundler generally, not specifically as a library-mode tool) |

**Rust:**

Cargo's own built-in `cargo build`/`cargo publish` (part of the Rust
toolchain itself, `rust-lang/cargo`) is the only build/publish tool in this
ecosystem — there is no separate build-backend choice to make the way
Python or Node require one. Direct GitHub fetch: Apache-2.0 (dual-licensed
with MIT per Rust project convention), 15,446 stars. `cargo publish`
uploads a crate to crates.io directly from `Cargo.toml` metadata; no
external packaging tool is needed or commonly used alongside it.

### Publishing mechanics — impact: high — depth: paragraphs + table

**Python**: `twine` (`pypa/twine`) remains the standalone upload tool for
build backends that don't bundle their own publish step (setuptools/Hatch
workflows). MIT license — GitHub API reported `Apache-2.0`, corrected here
by direct PyPI-page fetch which lists `twine` under the PyPA umbrella;
direct GitHub fetch: 1,789 stars, 336 forks, 52 open issues, pushed
2026-08-28; direct PyPI fetch: v7.0.0; direct PyPI-downloads fetch: 4.3M/
week. **`uv publish`** is uv's own built-in equivalent, eliminating twine
as a separate dependency for uv-based projects — consistent with uv's
"one tool replaces several" positioning above.

**PyPI Trusted Publishing (OIDC)** — verified current status via direct
fetch of `docs.pypi.org/trusted-publishers/` rather than assumed from
memory: it is **real, GA, and actively documented**, but as of this pass
it is positioned as a **recommended, optional complement to API tokens**,
not a mandatory requirement — PyPI's own docs describe it as
"complementing API tokens" rather than replacing them outright. It works
by exchanging short-lived (15-minute) OIDC identity tokens from a CI
provider (GitHub Actions, GitLab CI) for PyPI upload credentials, removing
the need to store long-lived API tokens as CI secrets. `uv publish` and
`twine` both support it once a project's PyPI trusted-publisher config
names the CI workflow.

**npm provenance / Trusted Publishing** — also directly verified via
`docs.npmjs.com/trusted-publishers/`: npm's Trusted Publishing is real and
operational (the docs reference configurations "created before
2026-05-20," implying the feature was already live before this pass).
Critically, **when publishing via Trusted Publishing from GitHub Actions
or GitLab CI, npm now generates provenance attestations automatically by
default** — the `--provenance` flag is no longer required on those
platforms (it can still be explicitly set to `false` to opt out).
Provenance attests *pipeline identity* (which repo/workflow/commit produced
the published bytes) — not pipeline honesty; a cited 2026 security
incident (the "TanStack compromise," search-corroborated, not
independently direct-fetched this pass) is a live example that provenance
does not by itself prevent a compromised-but-provenance-signed workflow
from publishing malicious code.

**Rust**: `cargo publish` uploads directly to crates.io using an API token
tied to a crates.io account (`cargo login`), **or**, as of a **follow-up
verification pass (2026-08-31)**, a Trusted Publishing (OIDC) flow that
does have a real crates.io-side implementation — corrected from this
doc's first pass, which had flagged the gap as unresolved. Confirmed
across three independent sources (Rust RFC 3691, and two direct-fetched
Socket.dev posts — `crates-launches-trusted-publishing` and the later
`crates-security-tab-tightened-publishing-controls`): GitHub Actions was
the initial supported provider, GitLab CI/CD support has since shipped
("limited to GitLab.com" for now), and crate owners can opt into a
**Trusted Publishing–only mode** (`trustpub_only` flag, default `false`,
visible via `GET /api/v1/crates/{name}`) that disables classic
token-based publishing entirely for that crate. The exact access-token
lifetime (a 30-minute figure appears only in the original RFC's
illustrative, non-committed example) could not be pinned to a primary
source this pass — `crates.io/docs/trusted-publishing` itself returns
only a page shell via WebFetch, likely a client-rendered SPA — so treat
it as "short-lived" rather than an exact figure in the authored doc.

### Version/release automation — impact: high — depth: table

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **python-semantic-release** (`python-semantic-release/python-semantic-release`) | Automates version bump + changelog + release from Conventional-Commits-style commit messages, Python ecosystem | MIT | The closest Python equivalent to JS's `semantic-release` philosophy — fully automates the version-decision step from commit history rather than requiring a manual bump command | 2026-08-31 | Direct GitHub fetch: 1,054 stars, 278 forks, 86 open issues, pushed 2026-08-30 (active); direct PyPI-downloads fetch: 289K/week |
| **Changesets** (`changesets/changesets`) | Monorepo-friendly, JS/TS ecosystem: each PR adds a small markdown "changeset" file describing its own version-bump intent, later consolidated into a release PR | MIT | The dominant convention specifically for **monorepos** (Turborepo/pnpm-workspace-style) — avoids semantic-release's single-linear-history assumption, better suited to independently-versioned packages in one repo | 2026-08-31 | Direct GitHub fetch: 12,344 stars, 821 forks, 263 open issues, pushed 2026-08-30; direct npm-downloads-API fetch (`@changesets/cli`): 4.68M/week |
| **semantic-release** (`semantic-release/semantic-release`) | Fully automated version/changelog/publish from Conventional Commits, single-package JS/TS projects | MIT | The JS-ecosystem original this category's convention is named after; best fit for a single-package repo with disciplined commit-message conventions already in place — Changesets is the better fit once the repo is a monorepo | 2026-08-31 | Direct GitHub fetch: 24,013 stars, 1,810 forks, 403 open issues, pushed 2026-08-29 |
| bump-my-version (`callowayproject/bump-my-version`) | Simple, explicit version-string bump across files (no changelog/commit-message automation) — the actively-maintained continuation of `bump2version` | MIT | Named as the **current** pick in this niche specifically because its predecessor is stale (next row) — a manual, explicit bump command remains the right level of automation for a project that doesn't want commit-message-driven releases | 2026-08-31 | Direct GitHub fetch: 623 stars, 43 forks, pushed 2026-08-24 (active); direct PyPI fetch: v2.x line; direct PyPI-downloads fetch: 228K/week |
| bump2version (`c4urself/bump2version`) | The predecessor to the row above — **named to flag a maintenance trap, not as a recommendation** | MIT | **Do not adopt for new projects.** Direct GitHub fetch shows last push 2025-02-20 — over 18 months stale as of this pass — yet it still pulls **307K/week** on PyPI (more raw downloads than its actively-maintained successor), almost certainly legacy-pin inertia rather than a deliberate current choice; a direct parallel to the setuptools/Express pattern elsewhere in this baseline where raw download volume and current recommendation diverge | 2026-08-31 | Direct GitHub fetch: 1,115 stars, 131 forks, pushed 2025-02-20 (stale); direct PyPI-downloads fetch: 307K/week |

### Docs generators — impact: high — depth: table

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Sphinx** (`sphinx-doc/sphinx`) | Python's long-established docs generator — reStructuredText/MyST-Markdown, autodoc from docstrings, the tool underlying most of the Python standard-library docs and major frameworks' own docs | BSD-2-Clause (confirmed via direct `LICENSE.rst` fetch — GitHub's license API misreported `NOASSERTION`, a detection artifact) | Still the deepest/most extensible option (largest theme + extension ecosystem, first-class multi-format output: HTML/PDF/ePub); the right choice for docs needing structured cross-referencing, versioned doc sets, or non-HTML output | 2026-08-31 | Direct GitHub fetch: 7,997 stars, 2,548 forks, 1,426 open issues, pushed 2026-08-31; direct PyPI-downloads fetch: 5.3M/week |
| **MkDocs** (`mkdocs/mkdocs`) + **mkdocs-material** (`squidfunk/mkdocs-material`) + **mkdocstrings** (`mkdocstrings/mkdocstrings`) | Markdown-native docs site generator; the current default choice for a lighter-weight, purely-HTML Python project docs site | MkDocs: BSD-2-Clause; mkdocs-material: MIT; mkdocstrings: ISC | The lower-friction alternative to Sphinx for a team that just wants a good-looking Markdown-based docs site with API-reference autogeneration (`mkdocstrings`) rather than Sphinx's fuller (and more complex) toolchain; mkdocs-material specifically is the dominant theme choice, not a generic pick | 2026-08-31 | MkDocs direct GitHub fetch: 22,397 stars, 2,646 forks, but pushed **2025-10-20** — over 10 months stale relative to this pass, worth flagging even though the ecosystem around it (material theme, mkdocstrings) remains very active; mkdocs-material direct GitHub fetch: 27,347 stars, 4,141 forks, only **1 open issue** (an unusually clean issue tracker, likely reflecting aggressive triage), pushed 2026-08-30 (very active); mkdocstrings direct GitHub fetch: 2,089 stars, 126 forks, pushed 2026-07-11; direct PyPI-downloads: MkDocs 3.1M/week, mkdocs-material 2.9M/week, mkdocstrings 1.6M/week |
| **TypeDoc** (`TypeStrong/typedoc`) | TypeScript's de facto API-doc generator — reads `.ts`/`.d.ts` source directly, no separate annotation syntax needed | Apache-2.0 | The standard choice for a TS library's API reference; consumes TSDoc-style comments and type signatures directly rather than requiring a parallel doc-comment DSL | 2026-08-31 | Direct GitHub fetch: 8,448 stars, 773 forks, 17 open issues, but pushed **2026-07-13** — about 7 weeks stale relative to this pass, a smaller gap than MkDocs' but worth noting; direct npm-downloads-API fetch: 5.05M/week |
| **Rustdoc** (bundled with the Rust toolchain, `rust-lang/rust`) | Rust's built-in doc generator — `cargo doc`, doc-comments (`///`) compiled directly, doctests executed as part of the test suite | MIT/Apache-2.0 dual (Rust project convention; not independently re-fetched from the full `rust-lang/rust` monorepo this pass since Rustdoc isn't a separately-versioned package) | Zero-config, built into every Rust toolchain install — no separate adoption decision to make, and doctests-as-executable-examples is a meaningfully different docs-correctness guarantee than any tool in the Python/JS rows above provides | 2026-08-31 | Not independently direct-fetched as a standalone repo this pass (it's part of `rust-lang/rust`, not a separate crate) — named on the strength of being the Rust toolchain's own bundled default, a structurally different maintenance signal than a standalone GitHub repo's stars/commits |

### API-stability / compat-checking tooling — impact: high — depth: table + mechanics

This is the category-defining concern the task brief calls out explicitly
— distinct from application-building, a library needs to know when it has
broken its own public API.

- **`py.typed` marker (PEP 561)**: not a tool but a mechanism — an empty
  `py.typed` file placed inside a package's own directory tells type
  checkers (mypy, pyright) that the package ships **inline** type
  annotations that should be trusted, as opposed to requiring a separate
  stub-only (`*-stubs`) package. Any Python library shipping type hints for
  consumers should include this file; its absence is a common,
  easy-to-miss gap.
- **Stub generation**: `stubgen`, bundled with **mypy** (`python/mypy`,
  direct GitHub fetch: MIT license confirmed via direct `LICENSE` fetch —
  GitHub's API misreported `NOASSERTION`; 20,621 stars, pushed 2026-08-29)
  generates `.pyi` stub files from existing Python source — useful for a
  library that wants to ship stubs separately rather than inline `py.typed`
  annotations. **pyright** (`microsoft/pyright`, direct GitHub fetch: MIT,
  15,609 stars, pushed 2026-08-28) also ships a stub-generation mode
  (`pyright --createstub`). **typeshed** (`python/typeshed`, direct GitHub
  fetch: Apache-2.0 confirmed via direct `LICENSE` fetch — GitHub API
  misreported `NOASSERTION`; 5,118 stars, pushed 2026-08-31) is the
  community-maintained stub repository for third-party/stdlib packages
  that don't ship their own — relevant context for a library maintainer
  deciding whether to ship `py.typed` themselves versus relying on a
  typeshed-hosted stub package maintained by others.
- **`cargo-semver-checks`** (`obi1kenobi/cargo-semver-checks`) — a real,
  actively maintained Rust-specific tool with no close Python/JS
  equivalent found this pass: lints a crate's API surface against its
  previous published version and flags changes that violate semver (e.g. a
  newly-required trait bound, a removed public field) before a bad release
  ships. Apache-2.0. Direct GitHub fetch: 1,673 stars, 139 forks, 181 open
  issues, pushed 2026-08-29 (active); direct crates.io fetch: v0.50.0,
  591,456 cumulative downloads.
- **`arethetypeswrong` / `@arethetypeswrong/cli`**
  (`arethetypeswrong/arethetypeswrong.github.io`) — checks a published npm
  package's actual resolved TypeScript types across every module-resolution
  mode (Node16, bundler, CJS/ESM dual-package) a consumer might use, a
  narrower but real category of "did we break API stability for TS
  consumers via a packaging/exports-map mistake" distinct from a pure
  semver-of-source-code check. MIT. Direct GitHub fetch: 1,598 stars, 65
  forks, 34 open issues, pushed 2026-07-09; direct npm-downloads-API fetch:
  629,771/week for `@arethetypeswrong/cli` specifically. **No direct
  Python-ecosystem or Rust-ecosystem equivalent of this specific
  "exports-map/module-resolution correctness" check was found this pass** —
  flagged as a real gap, not glossed over.
- **`publint`** (`publint/publint` on npm) — a related but distinct npm
  tool that lints a package's `package.json`/`exports` field for common
  publishing mistakes (missing `main`/`types` fields, wrong file paths)
  rather than checking resolved-type correctness the way
  `arethetypeswrong` does; MIT, direct npm fetch: v0.3.24. Named alongside
  `arethetypeswrong` as a complementary pre-publish check, not independently
  GitHub-star-verified this pass (npm registry data only).

### CLI framework libraries — impact: high — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Click** (`pallets/click`) | Python CLI framework — decorator-based command definition, nested command groups, the framework Typer itself is built on | BSD-3-Clause | The long-established Python CLI standard, part of the Pallets project (same org as Flask/Jinja); still the highest raw-download Python CLI framework of the three researched | 2026-08-31 | Direct GitHub fetch: 17,641 stars, 1,972 forks, 91 open issues, pushed 2026-08-30; direct PyPI-downloads fetch: **181.2M/week** |
| **Typer** (`fastapi/typer`) — **default for new Python CLIs** | Python CLI framework built on Click, generates the CLI directly from type-hinted function signatures | MIT | The 2026 greenfield default for the same reason FastAPI is the API-framework default (same author, same type-hint-driven design philosophy) — less boilerplate than raw Click for typical CLI shapes, while still being Click underneath for advanced cases | 2026-08-31 | Direct GitHub fetch: 19,937 stars, 977 forks, 46 open issues, pushed 2026-08-28; direct PyPI-downloads fetch: 56.4M/week; note the repo moved from `tiangolo/typer` to the `fastapi` GitHub org, consistent with FastAPI's own ecosystem consolidation |
| argparse (Python standard library) | Zero-dependency CLI parsing for simple scripts that don't warrant an external dependency | PSF License (part of CPython) | The right choice specifically when adding a dependency isn't justified — a single-file internal script, not a publishable CLI tool — named as the explicit "when neither Click nor Typer is warranted" answer rather than omitted | 2026-08-31 | Not independently version-checked (ships with every CPython release, no separate PyPI/GitHub adoption signal to fetch) |
| **Commander.js** (`tj/commander.js`) | Node/TS CLI framework — the most widely used option, minimal API surface | MIT | The default choice for a Node CLI needing straightforward argument/option parsing without a full plugin/extensibility framework | 2026-08-31 | Direct GitHub fetch: 28,381 stars, 1,770 forks, only 9 open issues, pushed 2026-08-31 (very active); direct npm-downloads-API fetch: **508.2M/week** — by a wide margin the highest download figure of any tool in this entire baseline |
| **oclif** (`oclif/oclif`) | Node/TS CLI **framework** (not just a parser) — plugin architecture, auto-generated help, built by Salesforce/Heroku for their own multi-command CLIs | MIT | The right choice when a CLI needs to grow into a plugin-extensible, multi-command tool (the Heroku CLI and Salesforce CLI are both built on it) rather than Commander's simpler single-purpose-parser model | 2026-08-31 | Direct GitHub fetch: 9,586 stars, 363 forks, 21 open issues, pushed 2026-08-29 |
| **Clap** (`clap-rs/clap`) | Rust's dominant CLI-argument-parsing library — derive-macro-based, the standard choice for any published Rust CLI binary | Dual `MIT OR Apache-2.0` (confirmed via direct `LICENSE-MIT` fetch and crates.io API license field) | The de facto standard for Rust CLIs; the derive-macro API (`#[derive(Parser)]`) generates argument parsing directly from a struct definition, closely analogous to Typer's type-hint-driven approach in Python | 2026-08-31 | Direct GitHub fetch: 16,678 stars, 1,241 forks, 443 open issues, pushed 2026-08-26; direct crates.io fetch: v4.6.6, **1,087,757,770 cumulative downloads** |

**Shell-completion generation** (added per user request alongside the
stack.md CLI-UX section) is a built-in feature of every framework above
rather than a separate library to choose: Click ships
`click.shell_completion` (bash/zsh/fish), Typer inherits it from Click,
Commander.js requires the separate `@commander-js/extra-typings`-adjacent
completion packages or a dedicated tool (not bundled), oclif has a
built-in `plugin-autocomplete`, and Clap's companion crate
**`clap_complete`** (same `clap-rs` org/repo, same dual-license) generates
completions for bash/zsh/fish/PowerShell/Elvish from the same derive-macro
struct — no separate research needed since it's the same tool/maintainer
as Clap itself.

### LSP / language-server framework libraries — impact: med — depth: table

Added per user request, corresponding to the LSP/IDE-tooling subsection in
`stack.md`. Scoped narrowly to **server-side** framework libraries (the
thing a tool author builds against to expose their tool's intelligence to
editors) — not editor-side client mechanics, which belongs to the editor
extension, not the tool being distributed.

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **pygls** (`openlawlibrary/pygls`) — **default for a Python-based LSP server** | Pythonic LSP-server framework — handles the JSON-RPC/asyncio plumbing so the author implements only the LSP request handlers | Apache-2.0 | The Python-ecosystem standard specifically because it stays out of the way of asyncio details while remaining a thin, protocol-correct layer — the natural choice for a Python tool (linter, formatter, type checker) that wants to expose itself as a language server without a language switch | 2026-08-31 | Direct GitHub fetch: 807 stars, 138 forks, 47 open issues, pushed 2026-07-12; direct PyPI fetch: v2.1.1 |
| **tower-lsp-server** (`tower-lsp-community/tower-lsp-server`) — **default for a Rust-based LSP server** | Community-maintained fork/continuation of the original `tower-lsp`, built on the `tower` service-abstraction ecosystem | Apache-2.0 | Named as the default over the original `tower-lsp` specifically because the original is stale (next row) while this fork is active and is where the crates.io download volume has been concentrating | 2026-08-31 | Direct GitHub fetch: 218 stars, 25 forks, 5 open issues, pushed 2026-08-15 (active); direct crates.io fetch: v0.23.0, 1,759,336 cumulative downloads |
| tower-lsp (`ebkalderon/tower-lsp`) | The original Rust LSP-server framework this category is built on — **named to flag a maintenance trap, not as a recommendation** | Apache-2.0 | **Do not adopt for new projects.** Direct GitHub fetch shows last push 2024-08-15 — over two years stale as of this pass — yet it still holds **more cumulative crates.io downloads (7,190,295) than its actively-maintained fork**, the same legacy-inertia pattern seen elsewhere in this baseline (setuptools, bump2version) | 2026-08-31 | Direct GitHub fetch: 1,360 stars, 81 forks, 41 open issues, pushed 2024-08-15 (stale); direct crates.io fetch: v0.20.0, 7,190,295 cumulative downloads |
| **vscode-languageserver-node** (`microsoft/vscode-languageserver-node`) | Microsoft's official TypeScript/Node LSP client-and-server library set | MIT | The standard choice for a Node/TS-authored language server — maintained by the same org that authored the LSP spec itself, though (per the spec's own design) a server built with it is not VS-Code-specific and works with any LSP-compliant editor | 2026-08-31 | Direct GitHub fetch: 1,783 stars, 400 forks, 81 open issues, pushed 2026-08-29 (very active) |

The protocol itself, `microsoft/language-server-protocol`
(CC-BY-4.0, 12,997 stars, pushed 2026-08-29), is the specification these
four libraries all implement against — not a library choice itself, named
here for completeness since it's the reason this table's four options are
interoperable with each other's editor-side clients despite being written
in three different languages.

### Cross-version testing tooling — impact: med — depth: table

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **tox** (`tox-dev/tox`) | Runs a library's test suite across multiple Python versions/dependency combinations in isolated environments, driven by a single `tox.ini`/`pyproject.toml` config | MIT | The long-established standard for "does this library actually work on every Python version it claims to support" — critical specifically for a library (vs. an application pinned to one runtime version) | 2026-08-31 | Direct GitHub fetch: 3,927 stars, 575 forks, only 1 open issue (aggressively triaged), pushed 2026-08-30; direct PyPI-downloads fetch: 3.4M/week |
| **nox** (`wntrblm/nox`) | Same purpose as tox, configured in plain Python (`noxfile.py`) rather than an INI/TOML DSL | Apache-2.0 | The alternative for a team that would rather write session definitions as Python functions than learn tox's config-file syntax — a real, actively-used alternative, not a lesser-known clone | 2026-08-31 | Direct GitHub fetch: 1,552 stars, 187 forks, 71 open issues, pushed 2026-08-18; direct PyPI-downloads fetch: 950K/week |
| GitHub Actions matrix builds | Language-agnostic mechanism (`strategy.matrix` in a workflow YAML) for running CI across multiple language-version/OS combinations | N/A — a CI platform feature, not a licensable library | The practical delivery mechanism for both tox's and nox's per-version runs in CI, and the direct Node/Rust-ecosystem equivalent when tox/nox have no analog (Node CLIs test their own multi-Node-version support this way, e.g. `node-version: [18, 20, 22]`) | 2026-08-31 | Not a fetchable repo/package — a platform feature, named for completeness per the task's explicit ask rather than omitted |

### Changelog tooling — impact: med — depth: table + local precedent

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Keep a Changelog** (convention, not a tool) | A structured `CHANGELOG.md` format (`Added`/`Changed`/`Deprecated`/`Removed`/`Fixed`/`Security` sections per version, an `[Unreleased]` heading) | N/A — a documented convention (keepachangelog.com), not licensable software | **Real, direct local precedent**: this very repo's own `CHANGELOG.md` already follows this convention verbatim — its header states "Format follows Keep a Changelog... versioning follows Semantic Versioning" and structures entries under `[Unreleased]` → `### Added` exactly as the convention specifies. This is the strongest possible evidence for recommending it: the repo being authored *is itself* a working example | 2026-08-31 | Not a fetchable repo — verified instead by direct read of this repo's own `CHANGELOG.md`, 2026-08-31 |
| **towncrier** (`twisted/towncrier`) | Automates changelog assembly from many small per-PR "news fragment" files (avoiding merge conflicts on a single shared `CHANGELOG.md` that every PR would otherwise edit) | MIT | The standard automation layer *on top of* a Keep-a-Changelog-shaped output — solves the specific pain point of multiple concurrent PRs all needing to add a changelog entry without merge conflicts; used by Twisted, pip, attrs, and other major Python projects | 2026-08-31 | Direct GitHub fetch: 918 stars, 132 forks, 70 open issues, pushed 2026-08-23; direct PyPI-downloads fetch: 453K/week |

### Claude Code plugins / MCP registries as an emerging distribution channel — impact: med — depth: paragraph

Named as a distinct row per the task brief's explicit steer, not folded
into the PyPI/npm/crates.io publishing-mechanics section above because the
mechanics are genuinely different in kind, not just in registry:
**`.claude-plugin/plugin.json`** (this repo's own manifest, four fields:
`name`/`version`/`description`/`author`) and the **MCP registry**
(`server.json` + `mcp-publisher publish`, per the secondhand citation from
`agentic-mcp-platforms/stack.md` above) both describe a distribution unit
that is a **directory of prompt/config/skill content**, not a built
artifact — no compiled wheel, no bundled JS, no compiled binary. There is
no build-backend question, no `py.typed`-equivalent stability marker, and
no semver-of-API-surface concept the way a code library has one (a skill's
"breaking change" is a change in agent behavior, not a function-signature
change). This is worth naming explicitly as a genuinely different point on
the "developer tooling & libraries" spectrum rather than treating
traditional package registries as the only distribution mechanism this
category needs to cover in 2026 — MCPg's own multi-channel shipping
(PyPI + MCP registry + Smithery + GHCR simultaneously, secondhand-cited
above) is the concrete evidence that both mechanisms now coexist for a
single real project, not that one has replaced the other.

## Explicitly out of scope

- **Full Rust web/service-framework survey** (Actix, Axum, etc.) — Rust is
  scoped narrowly to CLI-tooling (Clap) and compat-checking
  (cargo-semver-checks) per the Ecosystem-choice section; a Rust-specific
  service-framework baseline would need its own research pass, likely
  belonging to Backend & API Services rather than here.
- **Language-specific package-registry security/supply-chain scanning**
  (e.g. `pip-audit`, `npm audit`, `cargo audit`, Socket.dev) — a
  dependency/supply-chain-security concern already covered by the
  `python-code-review` skill's own dedicated domain, not re-litigated here.
- **Monorepo tooling generally** (Nx, Turborepo, Lerna) beyond Changesets'
  specific role in monorepo release automation — a genuinely separate
  concern (workspace/build-graph orchestration) from this doc's
  packaging/publishing/docs/compat-checking focus; flagged as a plausible
  future gap rather than covered here.
- **Editor-side extension scaffolding** (VS Code extension project
  templates, JetBrains plugin SDKs) — distinct from the **server-side**
  LSP framework libraries now covered above; editor-specific extension
  packaging is a narrower sub-niche not covered by the task brief's
  explicit scope list.
- **Cost/pricing for any commercial product** — none of the tools
  researched this pass turned out to have a commercial-tier licensing trap
  the way Apollo/Kong did in the backend-api-services baseline; if one
  surfaces in a deeper authoring pass it should get the same dedicated
  callout treatment, but none warranted it this pass.
- **crates.io's own trusted-publishing/OIDC equivalent** — confirmed to
  exist (see the Publishing mechanics section above, updated in the
  2026-08-31 follow-up pass); the original scoping-out of this item is
  now superseded, not a live gap.
- **Full CI/CD platform comparison** (GitHub Actions vs. GitLab CI vs.
  CircleCI) beyond the specific "matrix builds" and "OIDC-token-issuing CI
  provider" mentions above — a platform-choice question orthogonal to the
  library/package-tooling focus of this doc.

## Sources

- Local file reads (not web sources): `/Users/devopammittra/GitHub/
  agent-skills/.claude-plugin/plugin.json`, `/Users/devopammittra/GitHub/
  agent-skills/CHANGELOG.md`, `/Users/devopammittra/GitHub/agent-skills/
  CONTRIBUTING.md`, `/Users/devopammittra/GitHub/agent-skills/research/
  stacks/agentic-mcp-platforms/{stack.md,libraries.md}` (grepped for MCPg
  references), directory listing of `/Users/devopammittra/GitHub/
  ubi-csr-tmf` — all read/searched 2026-08-31
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license,
  stars, forks, open issues, `pushed_at`) for: pypa/setuptools, pypa/hatch,
  pdm-project/pdm, python-poetry/poetry, astral-sh/uv, pypa/twine,
  python-semantic-release/python-semantic-release, changesets/changesets,
  semantic-release/semantic-release, sphinx-doc/sphinx, mkdocs/mkdocs,
  mkdocstrings/mkdocstrings, squidfunk/mkdocs-material, TypeStrong/typedoc,
  obi1kenobi/cargo-semver-checks,
  arethetypeswrong/arethetypeswrong.github.io, pallets/click, fastapi/typer,
  tj/commander.js, oclif/oclif, clap-rs/clap, tox-dev/tox, wntrblm/nox,
  twisted/towncrier, python/typeshed, microsoft/pyright, python/mypy,
  c4urself/bump2version, callowayproject/bump-my-version, egoist/tsup,
  rollup/rollup, vitejs/vite, microsoft/TypeScript, rust-lang/cargo —
  retrieved 2026-08-31
- **LSP/CLI-UX follow-up pass (2026-08-31), added per user request**:
  direct fetch of https://clig.dev/ (full CLI Guidelines text); `gh api
  repos/<owner>/<repo>` for openlawlibrary/pygls, ebkalderon/tower-lsp,
  tower-lsp-community/tower-lsp-server, microsoft/vscode-languageserver-node,
  microsoft/language-server-protocol; direct crates.io API fetch
  (`crates.io/api/v1/crates/<name>`, required a custom User-Agent header —
  the registry's anonymous-default UA is rejected) for tower-lsp and
  tower-lsp-server cumulative-download figures; direct PyPI JSON fetch for
  pygls (v2.1.1) — all retrieved 2026-08-31
- Direct raw-file fetches to correct GitHub license-API misdetections
  (`NOASSERTION`): `sphinx-doc/sphinx/LICENSE.rst` (BSD-2-Clause),
  `python/typeshed/LICENSE` (Apache-2.0), `microsoft/pyright/LICENSE.txt`
  (MIT), `python/mypy/LICENSE` (MIT), `rollup/rollup/LICENSE.md` (MIT),
  `clap-rs/clap/LICENSE-MIT` (confirms dual MIT/Apache-2.0) — retrieved
  2026-08-31
- Direct PyPI JSON-API fetches (`pypi.org/pypi/<name>/json`) for current
  version numbers: uv, twine, hatch, hatchling, pdm, pdm-backend, poetry,
  poetry-core, setuptools — retrieved 2026-08-31
- Direct `pypistats.org/api/packages/<name>/recent` fetches for weekly/
  monthly download counts: setuptools, hatch, pdm, poetry, uv, twine,
  bump-my-version, bump2version, python-semantic-release, tox, nox,
  towncrier, click, typer, sphinx, mkdocs, mkdocs-material, mkdocstrings —
  retrieved 2026-08-31
- Direct `registry.npmjs.org/<name>` and `api.npmjs.org/downloads/point/
  last-week/<name>` fetches for: @arethetypeswrong/cli, commander,
  typedoc, tsup, @changesets/cli, publint — retrieved 2026-08-31
- Direct crates.io API fetch (`crates.io/api/v1/crates/<name>`) for: clap
  (max_version, cumulative downloads, license string), cargo-semver-checks
  (max_version, cumulative downloads) — retrieved 2026-08-31
- https://docs.pypi.org/trusted-publishers/ — direct WebFetch: current
  status (GA, optional/complementary to API tokens, not mandated),
  15-minute short-lived OIDC token mechanics — retrieved 2026-08-31
- https://docs.npmjs.com/trusted-publishers/ — direct WebFetch: GA status,
  automatic provenance-attestation generation as of Trusted Publishing
  adoption, `--provenance` flag no longer required on GitHub
  Actions/GitLab CI — retrieved 2026-08-31
- WebSearch corroboration (not independently direct-fetched primary
  source this pass): npm Trusted Publishing GA date (July 2025) and the
  2026-05 "TanStack compromise" as a real example of provenance attesting
  identity but not honesty — both search-corroborated only, flagged as
  such — retrieved 2026-08-31

## Open questions for the user

**Resolved this pass (2026-08-31 follow-up):** crates.io's Trusted
Publishing equivalent is confirmed real (GitHub Actions + GitLab CI/CD,
per-crate `trustpub_only` enforcement flag) via three independent
sources — see the updated Publishing mechanics section. Only the exact
access-token lifetime (originally cited as 30 minutes) couldn't be pinned
to a primary source and has been softened to "short-lived" rather than an
exact figure.

- **Rustdoc's own maintenance signal**: unlike every other tool in this
  doc, Rustdoc isn't independently direct-fetchable as its own repo (it
  ships inside the `rust-lang/rust` monorepo). Is "bundled with the Rust
  toolchain, no separate adoption decision" an acceptable substitute
  maintenance signal for the authored doc, or should authoring instead cite
  a specific Rust-toolchain release cadence/version as the concrete signal?
- **MkDocs' own repo staleness** (`pushed_at`: 2025-10-20, over 10 months
  stale relative to this pass) sits oddly next to its very-active
  ecosystem (mkdocs-material pushed 2026-08-30, mkdocstrings pushed
  2026-07-11). Is this because MkDocs core itself is simply feature-stable
  and its plugin ecosystem does the active work, or does this warrant a
  closer look before recommending MkDocs core as a "current" pick in the
  same table row as its more active plugins? Flagged rather than resolved
  either way this pass.
- **MCPg's specific packaging details remain secondhand.** Per the Local
  precedent section, neither existing `agentic-mcp-platforms` baseline
  names MCPg's build backend, license, or exact publish mechanics — only
  that it uses `uv` (per its own ADR) and ships to multiple channels
  simultaneously. If MCPg becomes reachable in a future pass (e.g. cloned
  locally), a direct inspection would strengthen this baseline's local-
  precedent section considerably beyond the current secondhand citation.
- **Is a fuller Node monorepo-tooling section (Nx/Turborepo) warranted**
  given Changesets' own strong monorepo positioning above, or does that
  belong to a separate future doc as scoped in Explicitly-out-of-scope?
  This pass defaulted to keeping monorepo orchestration tools out, on the
  view that Changesets' *release-automation* role is the in-scope part and
  the *build-graph-orchestration* role (Nx/Turborepo's actual core
  function) is a different concern — confirm this split is the right one
  before authoring commits to it.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/developer-tooling-libraries.md
  — est. 370–450 lines (11 category tables/sections — build backends,
  publishing mechanics, version/release automation, docs generators,
  API-stability/compat tooling, CLI frameworks + shell-completion note,
  LSP/language-server frameworks, cross-version testing, changelog
  tooling, plus the Claude-Code-plugin/MCP-registry distribution-channel
  callout — matching the Backend & API Services baseline's structure and
  rough length).
