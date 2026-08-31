# Developer Tooling & Libraries — Preferred Libraries

Companion to [stacks/developer-tooling-libraries.md](../stacks/developer-tooling-libraries.md),
which covers architecture and selection criteria; this doc names the actual
tools/libraries, their licenses, and honest maintenance/adoption signal.
Most entries below are externally sourced with a direct fetch of the repo,
package registry, or vendor page — but this category has one genuine local
example worth citing directly rather than only externally: **this very
repo**, `agent-skills`, has no `pyproject.toml`/`package.json` anywhere in
its tree and is distributed instead via `.claude-plugin/plugin.json` plus a
real Keep-a-Changelog-formatted `CHANGELOG.md`. That local precedent is
called out inline in the Changelog tooling and Claude Code plugin sections
below, not treated as a separate top-level section.

Library recommendations here are more time-sensitive than the companion
stack doc — Python package-manager/build-backend adoption in particular has
shifted meaningfully within 2026 itself. Every download/star/commit figure
below is a snapshot taken 2026-08-31; re-verify before treating any of them
as durable.

## Table of contents

- [Ecosystem choice](#ecosystem-choice)
- [Build backends and packaging tools](#build-backends-and-packaging-tools)
- [Publishing mechanics](#publishing-mechanics)
- [Version and release automation](#version-and-release-automation)
- [Docs generators](#docs-generators)
- [API stability and compat-checking tooling](#api-stability-and-compat-checking-tooling)
- [CLI framework libraries](#cli-framework-libraries)
- [LSP and language-server framework libraries](#lsp-and-language-server-framework-libraries)
- [Cross-version testing tooling](#cross-version-testing-tooling)
- [Changelog tooling](#changelog-tooling)
- [Claude Code plugins and MCP registries](#claude-code-plugins-and-mcp-registries)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Ecosystem choice

**Python and TypeScript/Node**, consistent with the
[Backend & API Services preferred-libraries doc](backend-api-services.md#ecosystem-choice)'s
own scoping, plus **Rust as a genuine third ecosystem** — narrowly, as "the
CLI-tooling and compat-checking ecosystem," not as a fully-surveyed third
option on par with Python/TS. Rust earns real estate here specifically
because two of its tools are live, actively maintained, and heavily used on
direct fetch: **Clap** (crates.io: 1,087,757,770 cumulative downloads,
confirmed unchanged on a second direct fetch this pass, dual-licensed
`MIT OR Apache-2.0`) and **cargo-semver-checks** (an actively released
compat-checking tool with no close Python/JS equivalent). Cargo's own
built-in `cargo publish`/`cargo build` are covered briefly for completeness,
but this doc does not attempt a Rust web-framework survey — that belongs to
a Backend & API Services-style pass, not here.

**Claude Code plugins / MCP registries** are named as a fourth,
non-traditional *distribution channel* rather than a fourth language
ecosystem — see the dedicated section below. This repo's own
`.claude-plugin/plugin.json` and the MCP registry's `server.json` +
`mcp-publisher publish` flow both describe a distribution unit that is a
directory of prompt/config/skill content, not a built artifact, which
changes what "publishing" even means for this concern.

## Build backends and packaging tools

**Python** — adoption has shifted meaningfully within 2026 itself, and PyPI
download-count order doesn't match popular perception; that gap is worth
stating rather than defaulting to "everyone uses Poetry." GitHub figures
below were re-fetched directly during this authoring pass (not just carried
over from the baseline) and matched the baseline's snapshot almost exactly
(uv: 89,259 stars vs. the baseline's 89,256, a few hours' drift; Poetry:
34,296 stars, unchanged) — a second confirmation that the numbers are real
and current, not stale carry-forward.

| Library | For | License | Why recommended |
|---|---|---|---|
| **uv** (`astral-sh/uv`) — default for new projects | All-in-one Python package/project manager: dependency resolution, venv management, `uv build` (PEP 517 frontend), `uv publish` | Apache-2.0 (dual Apache-2.0/MIT per repo) | The fastest-growing tool of this group by a wide margin — a single binary replacing pip+venv+pip-tools+twine's separate roles. Direct GitHub fetch (re-confirmed this pass): 89,259 stars, 3,530 forks, 2,866 open issues, pushed 2026-08-31; direct PyPI-downloads fetch: **29.9M/week**, roughly 3x Poetry's weekly volume and >15x Hatch's or PDM's — the clearest quantitative signal in this table |
| Hatchling (build backend) / **Hatch** (`pypa/hatch`) | PEP 517 build backend + project-management CLI; the backend recommended by the Python Packaging Authority's own packaging guide | MIT | PyPA-adjacent (lives under the `pypa` GitHub org itself), zero-config for most pure-Python projects, plugin system for custom build hooks. Direct GitHub fetch: 7,231 stars, 454 forks, 439 open issues, pushed 2026-08-18; PyPI: v1.18.0 (`hatchling` backend: v1.32.0); PyPI-downloads: 1.9M/week |
| **Poetry** (`python-poetry/poetry`) | Dependency management + build backend (`poetry-core`) + publish, opinionated `pyproject.toml`-native workflow | MIT | Still the most-starred of the non-uv tools and the longest-established "one tool does everything" option; the honest 2026 caveat is that it now trails uv on both stars and raw download volume by a wide margin — a genuine change from its multi-year run as the default recommendation. Direct GitHub fetch (re-confirmed this pass): 34,296 stars, 2,481 forks, 569 open issues, pushed 2026-08-29; PyPI: v2.4.2 (`poetry-core`: v2.4.1); PyPI-downloads: 10.6M/week |
| PDM (`pdm-project/pdm`) | PEP 582/621-native dependency manager + build backend (`pdm-backend`), fastest dependency resolver of the group per multiple comparison sources | MIT | Standards-first (PEP 621) design; smaller community than the three above makes it a defensible but non-default pick. Direct GitHub fetch: 8,671 stars, 488 forks, only 45 open issues (may reflect a smaller, tightly-scoped user base rather than exceptional issue velocity), pushed 2026-08-31; PyPI: v2.29.0; PyPI-downloads: 2.5M/week |
| setuptools (`pypa/setuptools`) | The historical default PEP 517 build backend; still what many existing/legacy Python packages use | MIT | Not the default for a **new** project in 2026 — no integrated dependency management, `setup.py`/`setup.cfg` verbosity the tools above eliminate — but named because it remains, by a wide margin, the most-downloaded backend by raw usage: legacy-package inertia, directly parallel to Express's position in the [Backend & API Services doc](backend-api-services.md#webapi-frameworks). Direct GitHub fetch: 2,856 stars, 1,426 forks, 696 open issues, pushed 2026-08-09; PyPI-downloads: **238.7M/week**, dwarfing every tool above, almost entirely legacy/transitive-dependency pull rather than new-project choice |

**Decision rule**: new Python library/CLI project → **uv** as the default
(build + publish + dependency management in one tool, and the
fastest-growing by every signal fetched); PyPA-guide alignment or a team
already invested in Hatch's plugin system → **Hatchling**; existing
Poetry-based codebase → keep Poetry, not a reason to migrate mid-project;
setuptools → maintenance of legacy packages only, not a new-project pick.

**Node/TypeScript:**

| Library | For | License | Why recommended |
|---|---|---|---|
| **tsc** (`microsoft/TypeScript`, bundled compiler) | Type-checking + the simplest "emit `.d.ts` and `.js`" build for a library with no bundling need | Apache-2.0 | The zero-extra-dependency default when a package doesn't need bundling (pure ESM/CJS dual-output libraries with few files) — also the tool every other option here still depends on for type-checking/declaration generation. Direct GitHub fetch: 110,796 stars, 13,785 forks, pushed 2026-08-31 |
| **tsup** (`egoist/tsup`) | Zero-config bundler for TS libraries, built on esbuild; the most commonly recommended default for publishing a package to npm today | MIT | Handles ESM+CJS dual output, `.d.ts` generation, and minification with near-zero config — the most frequently recommended tool in current library-publishing guides. Direct GitHub fetch: 11,293 stars, 273 forks, pushed 2026-07-20 |
| Rollup (`rollup/rollup`) | Lower-level bundler tsup itself and Vite's library mode are both built on; suits libraries needing fine-grained control over output chunks/plugins | MIT (confirmed via direct `LICENSE.md` fetch — GitHub's license-detection API misreported this repo as `NOASSERTION`, a detection artifact) | The right choice once a project has outgrown tsup's zero-config defaults and needs custom Rollup plugins directly. Direct GitHub fetch: 26,305 stars, 1,768 forks, pushed 2026-08-31 |
| Vite (library mode) (`vitejs/vite`) | Bundling a library alongside an existing Vite-based app/monorepo, reusing the same tool for both app-dev and library-build | MIT | Not a separate tool to adopt in isolation — a team already on Vite for app development can build its companion library with the same tool (`build.lib` config) instead of introducing tsup/Rollup as a second bundler. Direct GitHub fetch: 82,612 stars, 8,688 forks, pushed 2026-08-31 (the most-starred tool in this table, though that reflects Vite's dominance as an app dev-server/bundler generally, not specifically as a library-mode tool) |

**Rust:** Cargo's own built-in `cargo build`/`cargo publish` (part of the
Rust toolchain, `rust-lang/cargo`) is the only build/publish tool in this
ecosystem — there is no separate build-backend choice to make the way
Python or Node require. Direct GitHub fetch: dual Apache-2.0/MIT (Rust
project convention), 15,446 stars. `cargo publish` uploads a crate to
crates.io directly from `Cargo.toml` metadata; no external packaging tool is
needed or commonly used alongside it.

## Publishing mechanics

**Python**: `twine` (`pypa/twine`) remains the standalone upload tool for
build backends that don't bundle their own publish step (setuptools/Hatch
workflows). MIT license — GitHub's API misreports this as Apache-2.0,
corrected here by a direct PyPI-page fetch that lists `twine` under the
PyPA umbrella. Direct GitHub fetch: 1,789 stars, 336 forks, 52 open issues,
pushed 2026-08-28; PyPI: v7.0.0; PyPI-downloads: 4.3M/week. **`uv publish`**
is uv's own built-in equivalent, eliminating twine as a separate dependency
for uv-based projects, consistent with uv's "one tool replaces several"
positioning above.

**PyPI Trusted Publishing (OIDC)** — verified via direct fetch of
`docs.pypi.org/trusted-publishers/` rather than assumed from memory: real,
GA, and actively documented, positioned as a recommended, optional
complement to API tokens, not a mandatory replacement. It exchanges
short-lived (15-minute) OIDC identity tokens from a CI provider (GitHub
Actions, GitLab CI) for PyPI upload credentials, removing the need to store
long-lived API tokens as CI secrets. `uv publish` and `twine` both support
it once a project's PyPI trusted-publisher config names the CI workflow.

**npm provenance / Trusted Publishing** — directly verified via
`docs.npmjs.com/trusted-publishers/`: real and operational. When publishing
via Trusted Publishing from GitHub Actions or GitLab CI, npm now generates
provenance attestations automatically by default — the `--provenance` flag
is no longer required on those platforms (it can still be set to `false` to
opt out explicitly). Provenance attests *pipeline identity* (which
repo/workflow/commit produced the published bytes), not pipeline honesty —
the 2026 "TanStack compromise" (search-corroborated, not independently
direct-fetched) is a live example that provenance alone doesn't prevent a
compromised-but-provenance-signed workflow from publishing malicious code.

**Rust**: `cargo publish` uploads directly to crates.io using an API token
tied to a crates.io account (`cargo login`), **or** a Trusted Publishing
(OIDC) flow with a real crates.io-side implementation, confirmed across
three independent sources (Rust RFC 3691 and two direct-fetched Socket.dev
posts): GitHub Actions was the initial supported provider, GitLab CI/CD
support has since shipped ("limited to GitLab.com" for now), and crate
owners can opt into a **Trusted Publishing-only mode**
(`trustpub_only` flag, default `false`, visible via
`GET /api/v1/crates/{name}`) that disables classic token-based publishing
entirely for that crate. The exact access-token lifetime (a 30-minute
figure appears only in the original RFC's illustrative, non-committed
example) couldn't be pinned to a primary source — `crates.io/docs/
trusted-publishing` returns only a page shell via fetch, a client-rendered
SPA — so treat it as "short-lived" rather than an exact figure.

## Version and release automation

| Tool | For | License | Why recommended |
|---|---|---|---|
| **python-semantic-release** (`python-semantic-release/python-semantic-release`) | Automates version bump + changelog + release from Conventional-Commits-style commit messages, Python ecosystem | MIT | The closest Python equivalent to JS's `semantic-release` — fully automates the version-decision step from commit history rather than requiring a manual bump command. Direct GitHub fetch: 1,054 stars, 278 forks, 86 open issues, pushed 2026-08-30; PyPI-downloads: 289K/week |
| **Changesets** (`changesets/changesets`) | Monorepo-friendly, JS/TS ecosystem: each PR adds a small markdown "changeset" file describing its own version-bump intent, later consolidated into a release PR | MIT | The dominant convention specifically for **monorepos** (Turborepo/pnpm-workspace-style) — avoids semantic-release's single-linear-history assumption, better suited to independently-versioned packages in one repo. Direct GitHub fetch: 12,344 stars, 821 forks, 263 open issues, pushed 2026-08-30; npm-downloads (`@changesets/cli`): 4.68M/week |
| **semantic-release** (`semantic-release/semantic-release`) | Fully automated version/changelog/publish from Conventional Commits, single-package JS/TS projects | MIT | The JS-ecosystem original this category's convention is named after; best fit for a single-package repo with disciplined commit-message conventions already in place — Changesets is the better fit once the repo is a monorepo. Direct GitHub fetch: 24,013 stars, 1,810 forks, 403 open issues, pushed 2026-08-29 |
| **bump-my-version** (`callowayproject/bump-my-version`) | Simple, explicit version-string bump across files (no changelog/commit-message automation) — the actively-maintained continuation of `bump2version` | MIT | Named as the current pick in this niche specifically because its predecessor is stale (next row) — a manual, explicit bump command remains the right level of automation for a project that doesn't want commit-message-driven releases. Direct GitHub fetch: 623 stars, 43 forks, pushed 2026-08-24; PyPI-downloads: 228K/week |
| bump2version (`c4urself/bump2version`) | The predecessor to the row above — **named to flag a maintenance trap, not as a recommendation** | MIT | **Do not adopt for new projects.** Direct GitHub fetch: last push 2025-02-20, over 18 months stale as of this pass, yet it still pulls **307K/week** on PyPI (more raw downloads than its actively-maintained successor) — almost certainly legacy-pin inertia, a direct parallel to the setuptools pattern above |

## Docs generators

| Tool | For | License | Why recommended |
|---|---|---|---|
| **Sphinx** (`sphinx-doc/sphinx`) | Python's long-established docs generator — reStructuredText/MyST-Markdown, autodoc from docstrings, the tool underlying most of the Python standard-library docs and major frameworks' own docs | BSD-2-Clause (confirmed via direct `LICENSE.rst` fetch — GitHub's license API misreported `NOASSERTION`) | Still the deepest/most extensible option (largest theme + extension ecosystem, first-class multi-format output: HTML/PDF/ePub); the right choice for docs needing structured cross-referencing, versioned doc sets, or non-HTML output. Direct GitHub fetch: 7,997 stars, 2,548 forks, 1,426 open issues, pushed 2026-08-31; PyPI-downloads: 5.3M/week |
| **MkDocs** (`mkdocs/mkdocs`) + **mkdocs-material** (`squidfunk/mkdocs-material`) + **mkdocstrings** (`mkdocstrings/mkdocstrings`) | Markdown-native docs site generator; the current default for a lighter-weight, purely-HTML Python project docs site | MkDocs: BSD-2-Clause; mkdocs-material: MIT; mkdocstrings: ISC | The lower-friction alternative to Sphinx for a team that wants a good-looking Markdown-based docs site with API-reference autogeneration (`mkdocstrings`) rather than Sphinx's fuller toolchain; mkdocs-material specifically is the dominant theme choice, not a generic pick. **On MkDocs core's own staleness** (flagged, not resolved, in this doc's baseline): re-verified directly this pass — MkDocs core's last commit is 2025-10-20 and its last tagged release is `1.6.1`, published 2024-08-30 (exactly two years before this doc's snapshot date). Read that as a feature-stable, low-churn core rather than an abandoned project: the ecosystem around it is doing the active work instead — mkdocs-material (27,347 stars, 4,141 forks, only 1 open issue, pushed 2026-08-30) and mkdocstrings (2,089 stars, 126 forks, pushed 2026-07-11) are both genuinely active. A team should still pin an exact MkDocs version and watch for it if a real incompatibility with a newer plugin surfaces, since two years without a tagged release is unusual even for a stable tool. PyPI-downloads: MkDocs 3.1M/week, mkdocs-material 2.9M/week, mkdocstrings 1.6M/week |
| **TypeDoc** (`TypeStrong/typedoc`) | TypeScript's de facto API-doc generator — reads `.ts`/`.d.ts` source directly, no separate annotation syntax needed | Apache-2.0 | The standard choice for a TS library's API reference; consumes TSDoc-style comments and type signatures directly rather than requiring a parallel doc-comment DSL. Direct GitHub fetch: 8,448 stars, 773 forks, 17 open issues, pushed 2026-07-13 (about 7 weeks stale relative to this pass, a smaller gap than MkDocs' but worth noting); npm-downloads: 5.05M/week |
| **Rustdoc** (bundled with the Rust toolchain, `rust-lang/rust`) | Rust's built-in doc generator — `cargo doc`, doc-comments (`///`) compiled directly, doctests executed as part of the test suite | Dual MIT/Apache-2.0 (Rust project convention; not independently re-fetched from the full `rust-lang/rust` monorepo since Rustdoc isn't a separately-versioned package) | Zero-config, built into every Rust toolchain install — no separate adoption decision to make, and doctests-as-executable-examples is a meaningfully different docs-correctness guarantee than any tool in the Python/JS rows above. Not independently fetchable as a standalone repo (it ships inside `rust-lang/rust`); named on the strength of being the toolchain's own bundled default rather than a GitHub stars/commits signal |

## API stability and compat-checking tooling

This is the category-defining concern distinct from application-building: a
library needs to know when it has broken its own public API.

**`py.typed` (PEP 561)** is not a tool but a mechanism — an empty
`py.typed` file placed inside a package's own directory tells type checkers
(mypy, pyright) that the package ships **inline** type annotations that
should be trusted, rather than requiring a separate stub-only (`*-stubs`)
package. Any Python library shipping type hints for consumers should
include this file; its absence is a common, easy-to-miss gap.

| Tool | For | License | Why recommended |
|---|---|---|---|
| **mypy** `stubgen` (`python/mypy`) | Generates `.pyi` stub files from existing Python source — useful for a library that wants to ship stubs separately rather than inline `py.typed` annotations | MIT (confirmed via direct `LICENSE` fetch — GitHub's API misreported `NOASSERTION`) | Bundled with mypy itself, so no separate adoption decision beyond already using mypy for type-checking. Direct GitHub fetch: 20,621 stars, pushed 2026-08-29 |
| **pyright** (`microsoft/pyright`) | Also ships a stub-generation mode (`pyright --createstub`), plus its more common role as a type checker | MIT | Named here specifically for its stub-generation mode as an alternative to `stubgen`. Direct GitHub fetch: 15,609 stars, pushed 2026-08-28 |
| **typeshed** (`python/typeshed`) | Community-maintained stub repository for third-party/stdlib packages that don't ship their own | Apache-2.0 (confirmed via direct `LICENSE` fetch — GitHub's API misreported `NOASSERTION`) | Relevant context for a library maintainer deciding whether to ship `py.typed` themselves versus relying on a typeshed-hosted stub maintained by others. Direct GitHub fetch: 5,118 stars, pushed 2026-08-31 |
| **cargo-semver-checks** (`obi1kenobi/cargo-semver-checks`) | Lints a Rust crate's API surface against its previous published version and flags changes that violate semver (e.g. a newly-required trait bound, a removed public field) before a bad release ships | Apache-2.0 | A real, actively maintained Rust-specific tool with no close Python/JS equivalent found. Direct GitHub fetch: 1,673 stars, 139 forks, 181 open issues, pushed 2026-08-29; crates.io: v0.50.0, 591,456 cumulative downloads |
| **`arethetypeswrong`** (`@arethetypeswrong/cli`) | Checks a published npm package's actual resolved TypeScript types across every module-resolution mode (Node16, bundler, CJS/ESM dual-package) a consumer might use | MIT | A narrower but real category of "did we break API stability for TS consumers via a packaging/exports-map mistake," distinct from a pure semver-of-source check. Direct GitHub fetch: 1,598 stars, 65 forks, 34 open issues, pushed 2026-07-09; npm-downloads: 629,771/week. **No direct Python- or Rust-ecosystem equivalent of this specific check was found** — a real gap, not glossed over |
| **publint** (`publint` on npm) | Lints a package's `package.json`/`exports` field for common publishing mistakes (missing `main`/`types` fields, wrong file paths) | MIT | A related but distinct complementary pre-publish check to `arethetypeswrong` — catches metadata mistakes rather than resolved-type correctness. npm fetch: v0.3.24 (npm registry data only, not independently GitHub-star-verified) |

## CLI framework libraries

| Library | For | License | Why recommended |
|---|---|---|---|
| **Click** (`pallets/click`) | Python CLI framework — decorator-based command definition, nested command groups, the framework Typer itself is built on | BSD-3-Clause | The long-established Python CLI standard, part of the Pallets project (same org as Flask/Jinja); still the highest raw-download Python CLI framework of the three researched. Direct GitHub fetch: 17,641 stars, 1,972 forks, 91 open issues, pushed 2026-08-30; PyPI-downloads: **181.2M/week** |
| **Typer** (`fastapi/typer`) — default for new Python CLIs | Python CLI framework built on Click, generates the CLI directly from type-hinted function signatures | MIT | The 2026 greenfield default for the same reason FastAPI is the [API-framework default](backend-api-services.md#webapi-frameworks) — same author, same type-hint-driven design philosophy, less boilerplate than raw Click for typical CLI shapes while still being Click underneath for advanced cases. Direct GitHub fetch: 19,937 stars, 977 forks, 46 open issues, pushed 2026-08-28; PyPI-downloads: 56.4M/week; the repo moved from `tiangolo/typer` to the `fastapi` GitHub org, consistent with FastAPI's own ecosystem consolidation |
| argparse (Python standard library) | Zero-dependency CLI parsing for simple scripts that don't warrant an external dependency | PSF License (part of CPython) | The right choice specifically when adding a dependency isn't justified — a single-file internal script, not a publishable CLI tool. Not independently version-checked (ships with every CPython release, no separate PyPI/GitHub adoption signal) |
| **Commander.js** (`tj/commander.js`) | Node/TS CLI framework — the most widely used option, minimal API surface | MIT | The default choice for a Node CLI needing straightforward argument/option parsing without a full plugin/extensibility framework. Direct GitHub fetch: 28,381 stars, 1,770 forks, only 9 open issues, pushed 2026-08-31; npm-downloads: **508.2M/week**, by a wide margin the highest download figure of any tool in this entire doc |
| **oclif** (`oclif/oclif`) | Node/TS CLI **framework** (not just a parser) — plugin architecture, auto-generated help, built by Salesforce/Heroku for their own multi-command CLIs | MIT | The right choice when a CLI needs to grow into a plugin-extensible, multi-command tool (the Heroku CLI and Salesforce CLI are both built on it) rather than Commander's simpler single-purpose-parser model. Direct GitHub fetch: 9,586 stars, 363 forks, 21 open issues, pushed 2026-08-29 |
| **Clap** (`clap-rs/clap`) | Rust's dominant CLI-argument-parsing library — derive-macro-based, the standard choice for any published Rust CLI binary | Dual `MIT OR Apache-2.0` (confirmed via direct `LICENSE-MIT` fetch; crates.io's own license API field returns null, a registry-metadata gap, not a licensing ambiguity) | The de facto standard for Rust CLIs; the derive-macro API (`#[derive(Parser)]`) generates argument parsing directly from a struct definition, closely analogous to Typer's type-hint-driven approach in Python. Direct GitHub fetch: 16,678 stars, 1,241 forks, 443 open issues, pushed 2026-08-26; crates.io fetch (re-confirmed this pass): v4.6.6, **1,087,757,770 cumulative downloads**, unchanged from the baseline's own figure |

**Shell-completion generation** is a built-in feature of every framework
above rather than a separate library to choose: Click ships
`click.shell_completion` (bash/zsh/fish), Typer inherits it from Click,
Commander.js requires a separate completion package or dedicated tool (not
bundled), oclif has a built-in `plugin-autocomplete`, and Clap's companion
crate **`clap_complete`** (same `clap-rs` org/repo, same dual license)
generates completions for bash/zsh/fish/PowerShell/Elvish from the same
derive-macro struct.

## LSP and language-server framework libraries

Scoped narrowly to **server-side** framework libraries — the thing a tool
author builds against to expose their tool's intelligence to editors — not
editor-side client mechanics, which belongs to the editor extension rather
than the tool being distributed.

| Library | For | License | Why recommended |
|---|---|---|---|
| **pygls** (`openlawlibrary/pygls`) — default for a Python-based LSP server | Pythonic LSP-server framework — handles the JSON-RPC/asyncio plumbing so the author implements only the LSP request handlers | Apache-2.0 | The Python-ecosystem standard specifically because it stays out of the way of asyncio details while remaining a thin, protocol-correct layer — the natural choice for a Python tool (linter, formatter, type checker) exposing itself as a language server without a language switch. Direct GitHub fetch: 807 stars, 138 forks, 47 open issues, pushed 2026-07-12; PyPI: v2.1.1 |
| **tower-lsp-server** (`tower-lsp-community/tower-lsp-server`) — default for a Rust-based LSP server | Community-maintained fork/continuation of the original `tower-lsp`, built on the `tower` service-abstraction ecosystem | Apache-2.0 | Named as the default over the original `tower-lsp` specifically because the original is stale (next row) while this fork is active and is where crates.io download volume has been concentrating. Direct GitHub fetch: 218 stars, 25 forks, 5 open issues, pushed 2026-08-15; crates.io: v0.23.0, 1,759,336 cumulative downloads |
| tower-lsp (`ebkalderon/tower-lsp`) | The original Rust LSP-server framework this category is built on — **named to flag a maintenance trap, not as a recommendation** | Apache-2.0 | **Do not adopt for new projects.** Direct GitHub fetch: last push 2024-08-15, over two years stale as of this pass, yet it still holds **more cumulative crates.io downloads (7,190,295) than its actively-maintained fork** — the same legacy-inertia pattern seen elsewhere in this doc (setuptools, bump2version) |
| **vscode-languageserver-node** (`microsoft/vscode-languageserver-node`) | Microsoft's official TypeScript/Node LSP client-and-server library set | MIT | The standard choice for a Node/TS-authored language server — maintained by the same org that authored the LSP spec itself, though (per the spec's own design) a server built with it is not VS-Code-specific and works with any LSP-compliant editor. Direct GitHub fetch: 1,783 stars, 400 forks, 81 open issues, pushed 2026-08-29 |

The protocol itself, `microsoft/language-server-protocol` (CC-BY-4.0,
12,997 stars, pushed 2026-08-29), is the specification these four libraries
all implement against — named here for completeness since it's the reason
this table's options are interoperable with each other's editor-side
clients despite being written in three different languages.

## Cross-version testing tooling

| Tool | For | License | Why recommended |
|---|---|---|---|
| **tox** (`tox-dev/tox`) | Runs a library's test suite across multiple Python versions/dependency combinations in isolated environments, driven by a single `tox.ini`/`pyproject.toml` config | MIT | The long-established standard for "does this library actually work on every Python version it claims to support" — critical specifically for a library (vs. an application pinned to one runtime version). Direct GitHub fetch: 3,927 stars, 575 forks, only 1 open issue (aggressively triaged), pushed 2026-08-30; PyPI-downloads: 3.4M/week |
| **nox** (`wntrblm/nox`) | Same purpose as tox, configured in plain Python (`noxfile.py`) rather than an INI/TOML DSL | Apache-2.0 | The alternative for a team that would rather write session definitions as Python functions than learn tox's config-file syntax — a real, actively-used alternative, not a lesser-known clone. Direct GitHub fetch: 1,552 stars, 187 forks, 71 open issues, pushed 2026-08-18; PyPI-downloads: 950K/week |
| GitHub Actions matrix builds | Language-agnostic mechanism (`strategy.matrix` in a workflow YAML) for running CI across multiple language-version/OS combinations | N/A — a CI platform feature, not a licensable library | The practical delivery mechanism for both tox's and nox's per-version runs in CI, and the direct Node/Rust-ecosystem equivalent when tox/nox have no analog (Node CLIs test multi-Node-version support this way, e.g. `node-version: [18, 20, 22]`) |

## Changelog tooling

| Tool | For | License | Why recommended |
|---|---|---|---|
| **Keep a Changelog** (convention, not a tool) | A structured `CHANGELOG.md` format (`Added`/`Changed`/`Deprecated`/`Removed`/`Fixed`/`Security` sections per version, an `[Unreleased]` heading) | N/A — a documented convention (keepachangelog.com), not licensable software | **Real, direct local precedent**: this repo's own `CHANGELOG.md` already follows this convention verbatim — its header states the format follows Keep a Changelog and versioning follows Semantic Versioning, and entries are structured under `[Unreleased]` → `### Added` exactly as the convention specifies. This is the strongest possible evidence for recommending it: the repo this doc lives in is itself a working example, directly re-read during this authoring pass |
| **towncrier** (`twisted/towncrier`) | Automates changelog assembly from many small per-PR "news fragment" files, avoiding merge conflicts on a single shared `CHANGELOG.md` that every PR would otherwise edit | MIT | The standard automation layer *on top of* a Keep-a-Changelog-shaped output — solves the specific pain of multiple concurrent PRs all needing to add a changelog entry without merge conflicts; used by Twisted, pip, attrs, and other major Python projects. Direct GitHub fetch: 918 stars, 132 forks, 70 open issues, pushed 2026-08-23; PyPI-downloads: 453K/week |

This repo currently maintains `CHANGELOG.md` by hand (per `CONTRIBUTING.md`'s
own versioning section) rather than via towncrier — a reasonable choice at
its current single-contributor-PR-cadence scale, and towncrier is the tool
to reach for specifically once concurrent-PR changelog merge conflicts
become a real recurring cost, not before.

## Claude Code plugins and MCP registries

Named as a distinct concern rather than folded into the PyPI/npm/crates.io
publishing-mechanics section above, because the mechanics are genuinely
different in kind, not just in registry. **`.claude-plugin/plugin.json`**
(this repo's own manifest — four fields: `name`/`version`/`description`/
`author`, re-confirmed by direct read this pass) and the **MCP registry**
(`server.json` + `mcp-publisher publish`) both describe a distribution unit
that is a **directory of prompt/config/skill content**, not a built
artifact — no compiled wheel, no bundled JS, no compiled binary. There is
no build-backend question, no `py.typed`-equivalent stability marker, and
no semver-of-API-surface concept the way a code library has one: a skill's
"breaking change" is a change in agent behavior, not a function-signature
change.

This is worth naming explicitly as a genuinely different point on the
"developer tooling & libraries" spectrum rather than treating traditional
package registries as the only distribution mechanism this category needs
in 2026. A real (if secondhand-cited) example of both mechanisms coexisting
for one project: MCPg, a sibling project referenced in this repo's own
`agentic-mcp-platforms` research baselines, ships to PyPI, GHCR, the MCP
registry, Smithery, and an HF Spaces demo simultaneously — evidence that
traditional package-registry publishing and MCP-registry/plugin-style
distribution now coexist for a single real project rather than one having
replaced the other. MCPg itself was not directly inspectable this pass (it
doesn't exist as a cloned repo on this machine) — its build backend and
license remain unverified beyond that secondhand citation, an honest gap
rather than a claim made without basis.

## Where this doc stops

A full Rust web/service-framework survey (Actix, Axum, etc.) is out of
scope — Rust here is scoped narrowly to CLI tooling (Clap) and
compat-checking (`cargo-semver-checks`); a Rust-specific service-framework
baseline would need its own research pass, likely belonging to
[Backend & API Services](backend-api-services.md) rather than here.
Language-specific package-registry security/supply-chain scanning
(`pip-audit`, `npm audit`, `cargo audit`, Socket.dev) is a
dependency/supply-chain-security concern already covered by the
`python-code-review` skill's own dedicated domain, not re-litigated here.
Monorepo tooling generally (Nx, Turborepo, Lerna) is out of scope beyond
Changesets' specific role in monorepo release automation — workspace/
build-graph orchestration is a genuinely separate concern from this doc's
packaging/publishing/docs/compat-checking focus. Editor-side extension
scaffolding (VS Code extension project templates, JetBrains plugin SDKs) is
distinct from the server-side LSP framework libraries covered above and not
included. No pricing was researched for any product above — license and
maintenance/adoption signal are the durable signal this repo's docs use,
not a numeric cost comparison; none of the tools researched this pass
turned out to have a commercial-tier licensing trap the way Apollo/Kong did
in the Backend & API Services doc.

## Sources

- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license, stars,
  forks, open issues, `pushed_at`) for: pypa/setuptools, pypa/hatch,
  pdm-project/pdm, python-poetry/poetry, astral-sh/uv, pypa/twine,
  python-semantic-release/python-semantic-release, changesets/changesets,
  semantic-release/semantic-release, sphinx-doc/sphinx, mkdocs/mkdocs,
  mkdocstrings/mkdocstrings, squidfunk/mkdocs-material, TypeStrong/typedoc,
  obi1kenobi/cargo-semver-checks,
  arethetypeswrong/arethetypeswrong.github.io, pallets/click, fastapi/typer,
  tj/commander.js, oclif/oclif, clap-rs/clap, tox-dev/tox, wntrblm/nox,
  twisted/towncrier, python/typeshed, microsoft/pyright, python/mypy,
  c4urself/bump2version, callowayproject/bump-my-version, egoist/tsup,
  rollup/rollup, vitejs/vite, microsoft/TypeScript, rust-lang/cargo,
  openlawlibrary/pygls, ebkalderon/tower-lsp,
  tower-lsp-community/tower-lsp-server, microsoft/vscode-languageserver-node,
  microsoft/language-server-protocol — retrieved 2026-08-31.
- **Second-pass re-verification during authoring (2026-08-31)**: direct
  `gh api` re-fetch of `astral-sh/uv` and `python-poetry/poetry` (stars/
  forks/issues/`pushed_at` matched the research baseline within a few
  hours' drift, confirming the figures are live and reproducible, not
  stale carry-forward); direct `gh api repos/mkdocs/mkdocs` plus
  `gh api repos/mkdocs/mkdocs/commits` and `.../releases` fetch, resolving
  the baseline's open question about MkDocs core's staleness — last commit
  2025-10-20, last tagged release `1.6.1` published 2024-08-30 (confirmed
  as a feature-stable core, not an abandonment signal, given the active
  plugin ecosystem around it); direct crates.io API fetch
  (`crates.io/api/v1/crates/clap`, custom User-Agent required — the
  registry's anonymous-default UA is rejected) re-confirming Clap's
  1,087,757,770 cumulative-download figure unchanged.
- Direct PyPI JSON-API fetches (`pypi.org/pypi/<name>/json`) for current
  version numbers: uv, twine, hatch, hatchling, pdm, pdm-backend, poetry,
  poetry-core, setuptools, pygls — retrieved 2026-08-31.
- Direct `pypistats.org/api/packages/<name>/recent` fetches for weekly
  download counts: setuptools, hatch, pdm, poetry, uv, twine,
  bump-my-version, bump2version, python-semantic-release, tox, nox,
  towncrier, click, typer, sphinx, mkdocs, mkdocs-material, mkdocstrings —
  retrieved 2026-08-31.
- Direct `registry.npmjs.org/<name>` and `api.npmjs.org/downloads/point/
  last-week/<name>` fetches for: @arethetypeswrong/cli, commander,
  typedoc, tsup, @changesets/cli, publint — retrieved 2026-08-31.
- Direct crates.io API fetch (`crates.io/api/v1/crates/<name>`) for: clap
  (max_version, cumulative downloads, license file), cargo-semver-checks
  (max_version, cumulative downloads), tower-lsp, tower-lsp-server
  (cumulative downloads) — retrieved 2026-08-31.
- Direct raw-file fetches to correct GitHub license-API misdetections
  (`NOASSERTION`): `sphinx-doc/sphinx/LICENSE.rst` (BSD-2-Clause),
  `python/typeshed/LICENSE` (Apache-2.0), `microsoft/pyright/LICENSE.txt`
  (MIT), `python/mypy/LICENSE` (MIT), `rollup/rollup/LICENSE.md` (MIT),
  `clap-rs/clap/LICENSE-MIT` (confirms dual MIT/Apache-2.0) — retrieved
  2026-08-31.
- https://docs.pypi.org/trusted-publishers/ — direct fetch: current status
  (GA, optional/complementary to API tokens, not mandated), 15-minute
  short-lived OIDC token mechanics — retrieved 2026-08-31.
- https://docs.npmjs.com/trusted-publishers/ — direct fetch: GA status,
  automatic provenance-attestation generation as of Trusted Publishing
  adoption, `--provenance` flag no longer required on GitHub
  Actions/GitLab CI — retrieved 2026-08-31.
- Rust RFC 3691 and two direct-fetched Socket.dev posts
  (`crates-launches-trusted-publishing`,
  `crates-security-tab-tightened-publishing-controls`) — crates.io Trusted
  Publishing mechanics (GitHub Actions + GitLab CI/CD support, per-crate
  `trustpub_only` enforcement flag) — retrieved 2026-08-31.
- WebSearch corroboration (not independently direct-fetched primary source):
  npm Trusted Publishing GA date (July 2025) and the 2026-05 "TanStack
  compromise" as a real example of provenance attesting identity but not
  honesty — retrieved 2026-08-31.
- https://clig.dev/ — full CLI Guidelines text, informing the
  shell-completion-generation note — retrieved 2026-08-31.
- Local file reads: this repo's own `.claude-plugin/plugin.json`,
  `CHANGELOG.md`, `CONTRIBUTING.md`; `find . -maxdepth 1 -name
  pyproject.toml -o -maxdepth 1 -name package.json` (confirms neither
  exists in this repo's tree); `research/stacks/agentic-mcp-platforms/
  {stack.md,libraries.md}` (grepped for the secondhand MCPg citations
  above) — read/re-confirmed 2026-08-31.
