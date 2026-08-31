# Baseline: Developer Tooling & Libraries — Architecture & Stack
Status: draft      Date: 2026-08-31

## Local precedent

This category has a genuinely local, dual precedent — unusual for a v2
roadmap category (backend-api-services found none) — but only one half was
directly inspectable this pass:

1. **This very repo, `/Users/devopammittra/GitHub/agent-skills`** — read
   directly. It is a publishable Developer Tooling & Libraries artifact
   distributed through a **plugin marketplace**, not PyPI/npm/crates.io: no
   `pyproject.toml`, no `package.json`, no crate manifest anywhere in the
   tree. Distribution identity lives entirely in
   `.claude-plugin/plugin.json` (`name: "agent-skills"`, `version: "0.2.0"`,
   `description`, `author: {name, email}`) — confirmed by direct read.
   Versioning discipline is documented in this repo's own
   `CONTRIBUTING.md` (patch/minor/major rules mapped to skill-content
   changes rather than code-API changes — e.g. "new reference file" is
   `minor`, "wording fixes" is `patch`) and recorded in `CHANGELOG.md`
   (Keep a Changelog format, an `[Unreleased]` section). This is a real,
   different-from-package-registry distribution model worth naming as its
   own case: a plugin/skill is versioned and shipped, but the "API" being
   kept stable is prose/instruction surface and file paths under
   `references/`, not a function signature — confirmed as a genuinely
   distinct current pattern by direct-fetching Claude Code's own plugin
   docs (see Sources): plugins have an optional `version` field, an
   `author` field, install via `/plugin install` from a registered
   marketplace, and Anthropic runs two public marketplaces
   (`claude-plugins-official`, curated; `claude-plugins-community`, reviewed
   submissions pinned to a commit SHA in a `marketplace.json` catalog that
   syncs nightly) — a governance model closer to a curated app-store review
   pipeline than to an open, unmoderated push-a-tag-and-it's-live registry
   like PyPI/npm/crates.io. VS Code's Extension Marketplace (see Sources)
   is a directly comparable case in a different ecosystem: extensions are
   versioned SemVer-`X.Y.Z` (the Marketplace does **not** accept SemVer
   prerelease suffixes like `-beta`, unlike a registry such as npm which
   does), packaged into a `.vsix`, and published via the `vsce` CLI — a
   second real "plugin marketplace" instance confirming this is a durable,
   current pattern-category, not unique to Claude Code.

2. **MCPg** — named in the roadmap doc and in the existing
   `agentic-mcp-platforms` baselines as this category's other local
   example (a real production MCP server shipped to PyPI). **It does not
   exist on this machine** — confirmed this pass: only `agent-skills` and
   `ubi-csr-tmf` exist under `/Users/devopammittra/GitHub/` (verified via
   direct `ls`). The prior baselines referencing it
   (`research/stacks/agentic-mcp-platforms/{stack.md,libraries.md}`) were
   authored in a different environment where MCPg was locally available;
   this pass cannot re-inspect it directly. Secondhand context only, from
   grepping those files (not independently re-verified this pass):
   `agentic-mcp-platforms/stack.md` states "MCPg ships to PyPI, GHCR, the
   MCP registry, Smithery, and an HF Spaces demo simultaneously" as an
   example of complementary distribution channels; `libraries.md` records
   MCPg's own dependency choices (official `mcp` SDK/`FastMCP`, `psycopg`
   3, `pglast`, `uv`, `pytest`, `ruff`, `mypy --strict`, per ADR-0002) but
   does not record MCPg's *own* package license or versioning policy —
   that detail simply wasn't captured in the prior baselines' scope, so
   nothing is fabricated about it here.

3. **`/Users/devopammittra/GitHub/ubi-csr-tmf`** — checked directly this
   pass (`ls`, plus a `find` for `pyproject.toml`/`package.json`): a TMF/CSR
   application repo with `charts/`, `aws/`, `postman-collection/`,
   `openwiki/`, Helm chart directories, and a `graphify-out/` knowledge-graph
   output — an application with its own deployment/infra concerns, not a
   publishable SDK/library/CLI consumed by other developers. Confirmed not
   relevant to this category.

## In scope

- **Semver discipline in practice — how ecosystems differ, not one rule**
  — impact: high — depth: table. All three primary sources agree on the
  MAJOR/MINOR/PATCH intent (confirmed by direct fetch of `semver.org`
  2.0.0: major = incompatible API changes, minor = backward-compatible
  additions, patch = backward-compatible fixes; the spec also requires a
  project to *declare* what its public API even is — "This API could be
  declared in the code itself or exist strictly in documentation... it
  SHOULD be precise and comprehensive" — before version numbers mean
  anything), but enforcement mechanics differ sharply:
  | Ecosystem | What counts as breaking, concretely | Enforcement |
  |---|---|---|
  | Python (PyPA) | No single enforced rule — PyPA's own packaging guide (direct fetch) states plainly that "most projects, especially larger ones, do not strictly adhere to semantic versioning, since many changes are technically breaking changes but affect only a small fraction of users," and names Sphinx (strict semver) and NumPy (deliberately "loose" semver, permits some backward-incompatible changes in minor releases) as two real, divergent, both-legitimate approaches | None mechanical; PEP 440 governs version *string* syntax, not semver semantics |
  | npm | Adding/removing/renaming exported symbols, changing function signatures — npm's own docs (direct fetch) frame it simply as "if you introduce a change that breaks a package dependency, we strongly recommend incrementing the version major number," leaving the actual breakage judgment to the maintainer | None built into npm itself; `npm-check-updates`/manual review only |
  | Rust (Cargo) | **Machine-checkable and unusually strict** — Cargo's own SemVer reference (direct fetch) enumerates dozens of specific rules per Rust language construct: removing/renaming any public item is major; adding a public struct field when the struct already has a public field with no private field is major (breaks struct-literal construction); adding an enum variant is major *unless* the enum is marked `#[non_exhaustive]`; adding a non-defaulted trait item, tightening a generic bound, or changing a function's arity are all major; adding a new public item, loosening a bound, or adding a `#[non_exhaustive]`-covered enum variant are minor. This granularity exists because Rust's exhaustiveness checking, trait-impl resolution, and struct-literal construction make many more code shapes semver-relevant than in Python or JS |
  | Rust tooling | **`cargo-semver-checks`** (confirmed by direct fetch of the GitHub repo) mechanically enforces a large subset of the above rules in CI by diffing `rustdoc`'s JSON output between two versions via the `trustfall` query engine — the maintainers' own README acknowledges it "doesn't yet have lints for all of them" (e.g. some type-change and generic/lifetime lints are still open), so it's a strong-but-incomplete safety net, not a complete guarantee |
  A second Rust-specific tool, **`cargo public-api`** (confirmed by direct
  fetch/search corroboration of its GitHub repo and docs.rs page), lists
  and diffs a crate's full public API surface between releases/commits
  (also rustdoc-JSON-based, needs a nightly toolchain) — usable in CI
  (`cargo public-api --diff-git-checkouts origin/main HEAD`) as a
  human-reviewable diff even where `cargo-semver-checks`'s automated
  severity classification doesn't yet cover a given change shape. The
  authored doc's practical takeaway: Python/npm treat semver as a
  maintainer-judgment convention with real, acknowledged divergence in
  practice (NumPy's own stated policy is the clearest example); Rust
  treats it as close to a build-checkable contract, and a project can
  choose to adopt that rigor via these two tools regardless of language if
  it ships a stable public API surface other code depends on.

- **API stability marking / public-vs-private surface conventions** —
  impact: high — depth: section. Python's PEP 8-documented convention
  (confirmed by search corroboration of `peps.python.org/pep-0008`, not
  independently re-fetched this pass — flagged below): a module's public
  interface is `__all__` if present, else every name not starting with
  `_`; `__all__` mainly governs `from module import *` and documentation
  tooling, and is *not* an access-control mechanism — Python still allows
  importing an underscore-prefixed name, the convention only signals
  intent. This "declaration lives apart from the definition" gap is a
  real, currently-being-fixed problem: **PEP 844** (confirmed by direct
  fetch, status **Draft**, targeting **Python 3.16**, created
  **2026-08-05** — three weeks before this baseline's date, genuinely
  fresh) proposes `@public`/`private()` builtins so a name's visibility is
  declared at its definition site and `__all__` is derived automatically,
  addressing exactly the drift PEP 8's convention leaves possible (a name
  added to a module but omitted from `__all__`, or a stale `__all__` entry
  surviving a rename) — codifying a decade-old third-party pattern
  (`atpublic`). This is worth citing as "the direction Python itself is
  moving," not yet shipped. **OpenTelemetry's stability-level model**
  (confirmed by direct fetch of `opentelemetry.io/docs/specs/otel/
  versioning-and-stability/`) is a concrete, cross-language, real-world
  instance of an "experimental/unstable API badge" convention done at
  spec level: every signal progresses **Development → Stable →
  Deprecated → Removed**; Development-stage code may have breaking
  changes and "should not be considered feature complete"; once Stable,
  "all existing API calls MUST continue to compile and function against
  all future minor versions of the same major version," and a signal
  cannot be marked Deprecated unless its replacement is already Stable.
  Each language SDK version-tracks independently of the spec version it
  implements (the spec's own example: `opentelemetry-python-api` v1.8.2
  can implement spec v1.1.1) — a useful pattern for any project splitting
  a stable core from an evolving spec/protocol layer. Rust's
  `#[non_exhaustive]` attribute (already covered above under semver) is
  itself an API-stability-marking mechanism at the language level:
  annotating a struct/enum as evolvable-without-a-major-bump.

- **Deprecation policy mechanics — with two real, differently-shaped
  examples** — impact: high — depth: section. Python's own backward-
  compatibility policy is **PEP 387** (**direct-fetched, follow-up pass
  2026-08-31** — Status **Active**, a living process PEP): the normative
  core is that "the behavior of an API must not change in an incompatible
  fashion between any two consecutive releases" outside a formal
  deprecation process, with a required minimum of **two consecutive minor
  releases'** warning (one minor release if in an older major version)
  before removal, and an explicit **preference for a 5-year deprecation
  window** for widely-used APIs — a concrete number, not just a general
  principle. PEP 387 also names a **soft-deprecation** option: an API
  marked discouraged-for-new-code in documentation only, no runtime
  warning, no scheduled removal — a real third choice between "keep" and
  "deprecate-then-remove" worth naming in the authored doc. The stdlib's
  warning taxonomy (search-corroborated via
  `docs.python.org/3/deprecations/`): `DeprecationWarning` is shown by
  default only for code running in `__main__` (hidden for library/
  third-party code by default — the rationale being that *end users*
  running a script shouldn't be silently insulated from deprecation
  notices meant for *developers* of that code) versus `FutureWarning`,
  shown by default for **all** code, intended for end-user-facing tools
  rather than library internals — a distinction worth carrying into the
  authored doc since it's easy to pick the wrong one. **PEP 702**
  (**direct-fetched, follow-up pass 2026-08-31** — Status **Final**,
  shipped in **Python 3.13**, not still pending) adds a
  `@warnings.deprecated()` decorator so static type checkers can flag
  deprecated-API use at analysis time, not just at runtime — the PEP text
  itself now carries a notice marking it historical, with current
  authoritative behavior maintained at the typing-specs site, worth citing
  that as the living reference in the authored doc rather than the PEP
  alone. **Django's concrete two-release cycle** (search-
  corroborated): an API first emits `PendingDeprecationWarning` (silent
  by default, informational), then one release later upgrades to
  `DeprecationWarning` (visible), and only after that release is the API
  actually removed — a real, named, currently-followed support-window
  pattern with an explicit minimum grace period. **NumPy's NEP 23**
  (search-corroborated, both the NEP text and a 2020-2021 mailing-list
  acceptance thread): the explicit principle is that breaking changes
  "need to benefit more than they harm users" and, because NumPy is
  foundational infrastructure, "breaking changes should be assumed by
  default to be harmful" — backward-incompatible changes require a
  deprecation warning for **at least two releases** before removal, and
  NEP 23 separately locks the `.npy`/`.npz` on-disk file format itself to
  strict backward compatibility independent of the library's own version
  — a useful example of *data-format* stability being a distinct
  commitment from *API* stability within the same project. The authored
  doc's practical default: no universal "right" grace-period number
  exists across ecosystems, but a two-releases-minimum, warn-then-remove
  cycle (Django's and NumPy's shape) is the most consistently-cited
  concrete pattern worth recommending as a default in the absence of a
  project-specific reason to diverge.

- **Packaging/publishing models per ecosystem, and the shared move toward
  short-lived OIDC-issued credentials over long-lived tokens** — impact:
  high — depth: table. This is the single most consequential *current*
  fact for this category — verified fresh, not assumed from training data:
  | Registry | Current recommended publishing auth (verified this pass) | Mechanics |
  |---|---|---|
  | PyPI | **Trusted Publishing (OIDC)**, PyPI's own stated recommendation (confirmed by direct fetch of `docs.pypi.org/trusted-publishers/`) | A CI provider (e.g. GitHub Actions) acts as an OIDC identity provider; PyPI exchanges the CI-issued OIDC token for a short-lived (**15-minute**) API token scoped to a single publish — no secret is stored in CI configuration at all, versus a long-lived API token that "remains active indefinitely" if never manually rotated |
  | npm | **Trusted Publishing (OIDC)** (confirmed by direct fetch of `docs.npmjs.com/trusted-publishers`) — supports GitHub Actions, GitLab CI/CD, and CircleCI (cloud-hosted runners only; self-hosted runners explicitly not yet supported), requiring **npm CLI ≥ 11.5.1** and **Node ≥ 22.14.0** | Same short-lived-workflow-scoped-credential shape as PyPI; explicitly positioned to eliminate long-lived npm tokens |
  | crates.io | **Trusted Publishing (OIDC)** — **re-verified, follow-up pass 2026-08-31**, now corroborated across three independent sources (the accepted RFC 3691 text, and two separate Socket.dev writeups — `crates-launches-trusted-publishing` and the later `crates-security-tab-tightened-publishing-controls`) rather than a single blog post: GitHub Actions was the initial (RFC-scoped) provider; **GitLab CI/CD support has since shipped** ("Trusted Publishing now also works with GitLab CI/CD," though "support is currently limited to GitLab.com"). **Per-crate enforcement is real and newly confirmed by name**: crate owners can enable a **Trusted Publishing–only mode** ("disables token-based publishing entirely for a crate"), exposed as a `trustpub_only` flag on the crate — **opt-in, defaulting to `false`**, and visible via `GET /api/v1/crates/{name}` for supply-chain transparency (this specific flag name/default/visibility detail is new this pass, strengthening what the first pass only characterized generically as "a crate owner can now enforce") | For GitHub, the official `rust-lang/crates-io-auth-action` exchanges the OIDC token for a short-lived access token — the specific **30-minute** figure comes from the original RFC's illustrative example only ("we will provide a long enough lifetime initially"), and this follow-up pass could not independently pin an exact current minute-value from a primary source (`crates.io/docs/trusted-publishing` itself would not render via WebFetch — likely a client-rendered SPA page — a genuine tooling limitation, not a content gap); treat "short-lived, on the order of tens of minutes" as the safe claim for the authored doc rather than asserting exactly 30. Cargo's own reference doc (direct fetch of `doc.rust-lang.org/cargo/reference/publishing.html`) still documents only the classic long-lived `cargo login` token flow — the OIDC mechanism is a crates.io registry-side feature layered on top, not yet reflected in Cargo's own core docs, worth flagging as a documentation lag rather than a functionality gap |
  | Claude Code plugin marketplace | No token-based publish step at all — a plugin is a git repository; a marketplace is a `marketplace.json` catalog (also git-hosted) listing plugin sources; publishing *to a shared marketplace* means either hosting your own marketplace repo or submitting to Anthropic's community marketplace for review (confirmed by direct fetch: approved community submissions are "pinned to a specific commit SHA... and CI bumps the pin automatically" on new pushes, syncing nightly) | Governance is curation/review-based (a safety-screening + `claude plugin validate` pass), not registry-namespace-claim-based like PyPI/npm/crates.io |
  | VS Code Marketplace (a second plugin-marketplace instance, for comparison) | Historically Azure DevOps Personal Access Tokens (PATs); **global PATs retire 2026-12-01** in favor of Microsoft Entra ID-based secure automated publishing (search-corroborated) | Same long-lived-token-to-short-lived-identity-token migration arc as PyPI/npm/crates.io, on a different timeline, in a different ecosystem |
  The cross-ecosystem pattern worth stating plainly in the authored doc:
  **every registry-style channel this pass checked has moved or is actively
  moving from a long-lived manually-managed secret to a short-lived,
  workflow-scoped, OIDC-issued credential** — this is not a
  PyPI-specific or npm-specific quirk, it's the current direction of the
  entire category, and a new project's CI/CD release setup should default
  to whichever OIDC mechanism its target registry supports rather than
  minting a long-lived token as the starting point.

- **Docs-as-product** — impact: high — depth: section. The core framing
  for this category, distinct from an application's documentation: a
  library/SDK's documentation *is* the primary integration surface most
  consumers touch before ever reading source — the README is frequently a
  new user's entire onboarding path, functioning as marketing, quickstart,
  and API reference entry point simultaneously, which is a materially
  different job than an internal application's README (which mostly serves
  its own small team). Docs-as-code tooling (search-corroborated, current
  as of 2026 sources): documentation lives in the same repo as source,
  authored in Markdown/reST, reviewed via the same PR process as code, and
  deployed by the same CI/CD — the explicit goal being that docs can't
  silently drift out of sync with a release the way an externally-hosted
  wiki can. **Versioned-docs** is the mechanism specific to a library/SDK
  (an application usually only needs "current" docs; a library's users
  may be pinned to any supported major version and need docs matching
  *their* version): **Docusaurus** ships a first-class versioning CLI
  (search-corroborated) that snapshots the current docs tree into a
  frozen version directory per release, explicitly positioned by its own
  maintainers as fitting "projects that require versioned documentation,
  such as software libraries or APIs that evolve over time." **Sphinx**
  (Python-ecosystem-standard, search-corroborated) is the more common
  choice specifically for API-reference-heavy Python libraries owing to
  `autodoc` (pulling reference docs directly from docstrings, keeping
  reference material mechanically synced to the actual code) and its
  cross-referencing depth. Practical default for the authored doc: treat
  README quality (install instructions, a working quickstart example, a
  link to full docs) as a release-blocking concern on par with passing
  tests for any publishable package, and adopt a versioned-docs tool as
  soon as more than one major version is genuinely in the wild
  simultaneously — not before, since versioning machinery is pure
  overhead for a pre-1.0/single-supported-version project.

- **Testing approaches distinct to this category** — impact: high —
  depth: section. Two things a service-oriented codebase doesn't need
  that a library does: **cross-version/cross-platform matrix testing**
  and **testing against realistic downstream consumer usage** rather than
  only the library's own internal suite. Matrix testing (search-
  corroborated, current 2026 practice): a CI matrix strategy runs the same
  test suite across every supported language/runtime version (and
  sometimes OS) in parallel jobs; in Python specifically, **tox** or
  **nox** define the per-version environment recipe and a GitHub Actions
  matrix (`actions/setup-python` per matrix cell) drives which
  interpreter each job uses — the `tox-gh` plugin (search-corroborated,
  requires tox ≥ 4.31) automatically maps GitHub Actions' matrix Python
  version to the matching tox environment, avoiding hand-duplicated
  version lists in two places. This matters specifically for this
  category because a library's contract is "works on every Python/Node/
  Rust version we claim to support," not "works in our one deployed
  environment" — the deployment-target question a service asks doesn't
  even apply. **Testing against real downstream usage** is this
  category's most distinctive testing concern and the one with the
  clearest worked example: Rust's **Crater** tool (confirmed by search
  corroboration of the official `rust-lang/crater` README) builds and
  runs the test suites of tens of thousands of real crates.io/GitHub
  crates against two compiler versions and diffs the results, specifically
  to catch regressions that no compiler-internal test suite would surface
  — network access is disabled during builds to prevent abuse, and the
  tool runs isolated in Docker. This is the sharpest available real
  example of "test against what actually consumes you, not just your own
  suite" and is a pattern any widely-depended-upon library can scale down
  (a smaller-scale version: pin a handful of real downstream consumer
  repos as an integration-test target before cutting a release with
  API-surface changes) even without Crater-scale infrastructure.

- **CI/CD for release automation — current tooling state, verified fresh**
  — impact: high — depth: table. Three tools recur across current
  (2026) comparison sources, each solving the "bump version + write
  changelog + tag + publish" problem with a different amount of human
  gating:
  | Tool | Shape | Fits |
  |---|---|---|
  | **semantic-release** | Fully automated — parses commit messages (Conventional Commits), computes the next version, writes the changelog, publishes, with zero human approval step in the loop | Trunk-based teams comfortable with commit-message discipline substituting for a review gate on the release decision itself |
  | **Release Please** (Google) | Opens and maintains a standing "release PR" (also Conventional-Commits-driven) that a human merges to actually cut the release | Teams that want automation for the mechanical parts (changelog assembly, version bump math) but a deliberate human approval point before anything ships |
  | **Changesets** | Contributor-authored changeset files (one per PR, describing the change's semver impact in the contributor's own words) accumulate and get assembled into a release — the recurring reason cited for preferring it (search-corroborated) is monorepos with interdependent packages needing per-package version bumps computed from a shared changeset pool | Multi-package repos, or any team preferring an explicit PR-level "here's what this change means for semver" statement over inferring intent from commit messages |
  **Default per the repo's own opinionated-recommendation convention (all
  other baselines in this repo name a default rather than stopping at a
  neutral trade-off table, and this section now matches that bar)**:
  **Changesets for a monorepo/multi-package repo**, **Release Please for
  a single-package repo** — a human-gated release PR is the safer default
  starting point than semantic-release's fully-automated publish, since it
  costs nothing but one merge click and catches a wrong version-bump
  inference before it ships, whereas semantic-release's zero-approval step
  only pays for itself once a team has enough Conventional-Commits
  discipline and trust in the automation to accept that risk. **Reach for
  semantic-release specifically once that trust is established and the
  team wants to remove the human-merge step entirely** — not the default
  starting point for a new project. All three are npm/JS-ecosystem-native
  tools first (search-corroborated download/adoption figures: `@changesets/cli` ~3.1M
  weekly downloads vs. semantic-release ~2.6M as of the sources checked);
  Python and Rust projects commonly adopt one of these anyway for the
  changelog/tagging mechanics even when publishing to PyPI/crates.io
  rather than npm, since the "compute next version from a structured
  record of changes" problem is language-agnostic.

- **How this category specializes the cross-cutting
  `architecture-templates.md` pattern catalog** — impact: high — depth:
  section. The cross-cutting doc's 7-pattern catalog (layered, hexagonal,
  microservices, modular monolith, event-driven, CQRS/event sourcing,
  serverless) is largely **not the relevant axis** for a library/SDK the
  way it is for a service — there is no request to route, no deployment
  topology to choose, often no running process at all. What *is*
  distinctive and specific to this category, none of it covered by the
  cross-cutting doc: **module/plugin boundary design as the primary
  internal-architecture concern**, replacing "which service talks to
  which" with "which internal module is part of the stable public
  surface vs. an implementation detail that can change freely" — this is
  exactly what the API-stability-marking conventions above exist to
  encode. **Minimal transitive dependency footprint** as an explicit,
  actively-traded-off design axis: the Rust async-runtime ecosystem is a
  concrete, verified current example — `smol` (~5 crates of transitive
  dependencies, search-corroborated) is explicitly positioned as the
  lighter-weight choice "for libraries, embedded systems, and CLI tools,
  anywhere Tokio's dependency weight feels excessive," versus `tokio`
  (~50 crates, search-corroborated) which is the ecosystem's default for
  *applications* that don't mind the weight — the same trade-off (heavier,
  more-featured vs. lighter, more embeddable) that any library author
  faces when choosing its own dependencies, since every dependency a
  library takes becomes a transitive burden imposed on every consumer of
  that library, not just a cost the library's own team bears. **Not
  forcing a runtime/framework choice onto consumers** is this category's
  sharpest architectural discipline point, with a real, dated worked
  example: `async-std` was discontinued in favor of consolidating on
  `smol` (confirmed by direct fetch of the `async-rs/async-std` GitHub
  README: "`async-std` has been discontinued; use `smol` instead" — the
  specific March-2025 discontinuation date is search-corroborated only,
  not independently confirmed by a dated primary source this pass), which
  is exactly the failure mode a runtime-agnostic library design avoids:
  a library hardcoding a dependency on a since-abandoned runtime breaks
  for every consumer, whereas a library written against a
  runtime-agnostic trait surface (Rust's `futures::io::AsyncRead`/
  `AsyncWrite`, or an explicit compatibility crate like
  `agnostic_async_executor`, search-corroborated) survives an ecosystem
  consolidation event like this one unaffected. The general, portable
  principle for the authored doc, stated once and applicable beyond Rust:
  **a library should depend on the thinnest possible abstraction its
  consumers already have to deal with (an async trait, a logging facade,
  a serialization protocol) rather than a specific concrete runtime,
  framework, or implementation** — the cost of getting this wrong is
  borne by every downstream consumer, not just the library's own
  maintainers, which is precisely the distinction the task framing draws
  between "building an application" and "building something other
  developers build on."

- **CLI-specific UX/interaction-design conventions** — impact: high —
  depth: section. Added per user request (post-Checkpoint-E review); the
  canonical primary source is **Command Line Interface Guidelines**
  (`clig.dev`, direct fetch), a widely-cited synthesis rather than a
  formal spec, but the closest thing this sub-genre has to one. Concrete,
  load-bearing conventions worth carrying into the authored doc verbatim:
  **help conventions** — `-h`/`--help` must work after any command or
  subcommand, and the help text should *lead with usage examples* rather
  than an exhaustive flag list first ("users tend to use examples over
  other forms of documentation"). **Flags over positional args** for
  anything beyond the one or two most obvious required arguments — flags
  are self-documenting at the call site, positional args require memorizing
  order; every flag gets both a short (`-v`) and long (`--verbose`) form,
  but only genuinely common flags earn a one-letter short form. **Stream
  discipline**: primary output to `stdout`, all logging/errors/progress to
  `stderr` — this is what keeps a tool composable in a Unix pipeline.
  **Exit codes**: zero for success, non-zero for failure, since that's the
  only signal a calling script can act on. **Human output first, machine
  output as an explicit opt-in**: default to human-readable formatting,
  detect non-TTY output (piped/redirected) and drop decoration
  automatically, and provide an explicit `--json` (structured,
  script-parseable) and/or `--plain` (one record per line) flag for
  callers that need to parse output programmatically — never require a
  human user to pass a flag just to get readable output. **Animations/
  color are conditional, not assumed**: disable spinners/progress
  animations whenever `stdout` isn't an interactive terminal (the
  `clig.dev` framing: this is what stops "progress bars turning into
  Christmas trees in CI log output"), and respect both a `--no-color` flag
  and the `NO_COLOR` environment variable convention. **Destructive-action
  confirmation, scaled to blast radius**: no prompt for a fully reversible
  action, a plain y/n confirmation for a moderate one, and for a genuinely
  destructive one, require the caller to type the resource's own name back
  or pass an explicit `--confirm=<name>` flag — a single `--force` flag
  bypassing all of the above is the anti-pattern this guideline is
  implicitly warning against. **Error messages rewritten for humans**, not
  raw stack traces or errno text, on the stated principle that
  signal-to-noise ratio directly determines how long a user takes to
  recover from a mistake. This entire section is a **library's CLI-shaped
  artifact's UX contract**, distinct from (and additive to) the CLI
  *framework* choice in libraries.md (Click/Typer/Commander/Clap all
  support these conventions — none of them enforce good `--help` copy or
  the right confirmation-prompt threshold by default, that's still an
  authoring discipline on top of the framework).

- **LSP / language-server and IDE-tooling development** — impact: med —
  depth: section. Added per user request (post-Checkpoint-E review); a
  real, distinct sub-genre of "developer tooling" this baseline's first
  pass had scoped out. The **Language Server Protocol** itself
  (`microsoft/language-server-protocol`, direct fetch: CC-BY-4.0, 12,997
  stars, pushed 2026-08-29 — actively maintained) is the foundational
  fact that makes this its own architecture concern rather than an
  arbitrary IDE-plugin API: one server implementation, written once in
  whatever language/runtime the tool author prefers, speaks JSON-RPC over
  stdio/sockets to *any* LSP-*client* editor (VS Code, Neovim, Zed,
  JetBrains via a bridge) — the same "write once, serve many clients"
  economics that motivate a library in the first place, just applied to
  editor integration specifically instead of to a general API surface.
  This is architecturally distinct from a **build-tool/linter plugin**
  (a Vite plugin, an ESLint rule, a Ruff plugin) — an LSP server is a
  long-running, stateful process maintaining a live document/workspace
  model and responding to incremental edit events, while a build-tool
  plugin is typically a synchronous hook invoked once per build/lint pass
  with no persistent state across invocations; the two are both
  "developer tooling that extends someone else's tool," but the
  architecture and the API contract they implement against are not the
  same thing, and an authored doc should not conflate them. **A genuinely
  distinct concern from CLI/SDK/library design covered elsewhere in this
  doc**: an LSP server's own "public API" is the protocol's fixed message
  set (initialize, textDocument/completion, textDocument/publishDiagnostics,
  etc.) — the server author has no freedom to design that surface, only
  to decide which optional capabilities to implement, which inverts this
  category's usual semver/API-stability concern (there is no versioning
  decision to make for the protocol surface itself, only for
  implementation-specific extensions a server may add on top).

## Explicitly out of scope

- Specific library/tool/SDK names, their exact license text, and
  maintenance-signal numbers (stars, download counts, contributor
  counts) — belongs entirely to the companion `libraries.md` baseline
  being produced in parallel. This doc names tools only where the tool
  itself *is* the architectural fact being described (e.g.
  `cargo-semver-checks` mechanically enforcing semver rules is itself the
  point, not a swappable library choice) — those mentions should be
  treated as illustrative anchors for the pattern, not as this doc
  encroaching on libraries.md's job of the full comparative table.
- Deep CI/CD platform mechanics (GitHub Actions YAML syntax, runner
  pricing/minutes) beyond the release-automation and matrix-testing shape
  described above — this doc covers *what* release automation and matrix
  testing need to accomplish, not a platform-specific implementation
  tutorial.
- **Build-tool/linter plugin development mechanics** (writing an ESLint
  rule, a Ruff plugin, a Vite plugin) at implementation depth — named only
  in passing above as an architectural contrast to LSP servers
  (stateless-per-invocation vs. long-running-stateful); a dedicated
  treatment of this sub-genre's own plugin-API conventions would need its
  own research pass.
- Shell-completion **generation mechanics** in implementation depth
  (writing a custom completion script by hand, completion-spec formats
  beyond what a CLI framework generates automatically) — the CLI-UX
  section above covers the UX-level expectation (a CLI should support
  shell completion) and libraries.md's existing CLI-framework table
  already covers which frameworks generate completions for which shells;
  this doc doesn't go deeper into hand-authoring a completion spec.
- Monorepo tooling/workspace mechanics in general (Nx, Turborepo, Cargo
  workspaces, npm/pnpm workspaces) beyond the Changesets-for-monorepos
  mention above — a real, adjacent concern but distinct enough from
  single-package publishing to warrant its own treatment if it turns out
  to matter enough in practice.
- Cost modeling / registry pricing (private PyPI/npm hosting, GitHub
  Packages pricing tiers) — same no-pricing convention as every other
  baseline in this repo.
- The plugin-marketplace review/safety-screening process's internal
  mechanics (what "automated safety screening" actually checks) —
  Anthropic-internal detail not documented publicly in enough depth to
  research further this pass; the authored doc should describe the
  externally-visible shape (submit → automated + review → pinned commit
  SHA → nightly sync) without speculating about the screening internals.

## Sources

- https://semver.org/ — direct fetch: SemVer 2.0.0, MAJOR/MINOR/PATCH
  definitions, requirement to declare a precise public API before
  versions are meaningful — retrieved 2026-08-31
- https://packaging.python.org/en/latest/discussions/versioning/ — direct
  fetch: PyPA's own acknowledgment that most projects don't strictly
  follow semver, explicit Sphinx (strict) vs. NumPy (loose) contrast,
  PEP 440 referenced for version-string syntax — retrieved 2026-08-31
- https://docs.npmjs.com/about-semantic-versioning — direct fetch: npm's
  own semver guidance and "strongly recommend incrementing major" framing
  for breaking changes — retrieved 2026-08-31
- https://doc.rust-lang.org/cargo/reference/semver.html — direct fetch:
  full per-construct major/minor/possibly-breaking classification table
  (items, structs, enums, traits, generics, repr/layout, Cargo features)
  — retrieved 2026-08-31
- https://github.com/obi1kenobi/cargo-semver-checks — direct fetch:
  rustdoc-JSON + `trustfall`-query mechanism, GitHub Action integration,
  explicit acknowledgment of incomplete lint coverage — retrieved
  2026-08-31
- https://github.com/cargo-public-api/cargo-public-api — search-
  corroborated (GitHub repo description, docs.rs page, libraries.io
  listing): lists/diffs a crate's public API via rustdoc JSON, CI-usable
  via `--diff-git-checkouts` — retrieved 2026-08-31
- https://peps.python.org/pep-0844/ — direct fetch: Status **Draft**,
  target **Python 3.16**, created **2026-08-05**; `@public`/`private()`
  builtins proposal, problem statement (visibility declared apart from
  definition, causing drift), builds on the third-party `atpublic`
  pattern — retrieved 2026-08-31
- https://peps.python.org/pep-0008/ — **direct fetch, follow-up pass
  2026-08-31**: confirms `__all__` is a declared, explicit public-API list
  ("modules should explicitly declare the names in their public API using
  the `__all__` attribute"; an empty `__all__` "indicates that the module
  has no public API") and that leading-underscore naming is the actual
  non-public signal layered underneath it ("even with `__all__` set
  appropriately, internal interfaces... should still be prefixed with a
  single leading underscore") — confirms neither mechanism is
  access-control, both are naming/declaration conventions only, matching
  this doc's original framing
- https://peps.python.org/pep-0387/ — **direct fetch, follow-up pass
  2026-08-31**: Status **Active** (a living process PEP, not a one-time
  proposal). Confirms the normative core: "the behavior of an API must not
  change in an incompatible fashion between any two consecutive releases"
  outside the deprecation process, and "a feature cannot be removed
  without notice between any two consecutive releases." Deprecation
  warnings must span **at least two consecutive minor releases** within a
  major version (or one minor release of an older major version) before
  removal, with a stated **preference for a 5-year deprecation window**
  for widely-used APIs — a more specific number than this doc's original
  "no universal grace-period number exists" framing anticipated, worth
  carrying into the authored doc as CPython's own concrete instance of the
  category's general "warn for N releases before removing" pattern. Also
  newly confirms a **soft-deprecation** exception: an API can be marked
  discouraged-for-new-code in documentation only, with no runtime warning
  and no scheduled removal — a real third option alongside "keep" and
  "deprecate-then-remove" worth naming in the authored doc
- https://peps.python.org/pep-0702/ — **direct fetch, follow-up pass
  2026-08-31**: Status **Final**, shipped in **Python 3.13** (not still
  pending as this doc's first pass implied by treating it as
  search-corroborated-only). The `@warnings.deprecated()` decorator takes
  a required message plus optional `category`/`stacklevel` args; type
  checkers "should produce a diagnostic whenever they encounter a usage of
  an object marked as deprecated" (imports, attribute access, indirect
  calls via operator overloads, and per-overload deprecation all count);
  the PEP itself now carries a notice that it is historical — current
  authoritative behavior lives at the typing-specs site, not the PEP text
  — worth citing the typing-specs page as the living reference rather than
  the PEP alone in the authored doc
- https://docs.python.org/3/deprecations/index.html — search-corroborated:
  `DeprecationWarning` (default-visible only in `__main__`) vs.
  `FutureWarning` (default-visible everywhere) distinction — retrieved
  2026-08-31
- Django's PendingDeprecationWarning → DeprecationWarning two-release
  cycle — search-corroborated across multiple secondary sources, not an
  official Django docs page independently direct-fetched this pass —
  retrieved 2026-08-31
- https://numpy.org/neps/nep-0023-backwards-compatibility.html — search-
  corroborated (NEP text summary plus the 2020-2021 numpy-discussion
  mailing-list acceptance thread): "benefit more than harm," ≥2-release
  deprecation-warning minimum, `.npy`/`.npz` file-format compatibility
  locked independent of library version — retrieved 2026-08-31
- https://docs.pypi.org/trusted-publishers/ — direct fetch: OIDC-based
  Trusted Publishing mechanics, 15-minute short-lived token, stated as
  PyPI's recommended mechanism over long-lived API tokens — retrieved
  2026-08-31
- https://docs.npmjs.com/trusted-publishers — direct fetch: OIDC Trusted
  Publishing, supported CI platforms (GitHub Actions/GitLab CI/CircleCI,
  cloud-hosted only), minimum npm CLI 11.5.1 / Node 22.14.0 — retrieved
  2026-08-31
- https://doc.rust-lang.org/cargo/reference/publishing.html — direct
  fetch: confirms Cargo's own reference docs still describe only the
  classic long-lived `cargo login` token flow, no OIDC mention — retrieved
  2026-08-31
- crates.io Trusted Publishing — **re-verified, follow-up pass
  2026-08-31**: `crates.io/docs/trusted-publishing` itself would not
  render via WebFetch (returns only the page shell, likely a
  client-rendered SPA — a tooling limitation, not a missing source), but
  the claim is now corroborated across three independent secondary
  sources instead of one: `rust-lang/rfcs` RFC 3691 (direct-fetched),
  https://socket.dev/blog/crates-launches-trusted-publishing (direct
  WebFetch), and https://socket.dev/blog/crates-security-tab-tightened-publishing-controls
  (direct WebFetch, confirms the `trustpub_only` per-crate enforcement
  flag by name, its `false` default, and its API visibility). GitLab
  CI/CD support and per-crate enforcement are both confirmed present;
  the exact 30-minute access-token lifetime remains sourced only to the
  RFC's own illustrative (non-committed) example — downgraded in the
  table above to "short-lived, tens of minutes" rather than an exact
  figure
- https://code.claude.com/docs/en/plugins (redirected from
  `docs.claude.com`) — direct fetch: plugin manifest schema
  (name/description/version/author), marketplace mechanics, the two
  public marketplaces (`claude-plugins-official` curated,
  `claude-plugins-community` reviewed-and-commit-SHA-pinned,
  `marketplace.json` catalog synced nightly), `claude plugin validate`
  as the pre-submission check — retrieved 2026-08-31
- VS Code Extension Marketplace publishing/versioning — search-
  corroborated (`code.visualstudio.com/api/working-with-extensions/
  publishing-extension`, `vsce` GitHub issues, dev.to guide): SemVer
  `X.Y.Z`-only (no prerelease suffixes accepted by the Marketplace even
  though SemVer permits them), global Azure DevOps PATs retiring
  **2026-12-01** in favor of Microsoft Entra ID — retrieved 2026-08-31,
  not independently direct-fetched
- Docusaurus versioning — search-corroborated (`docusaurus.io/docs/
  versioning` referenced in search results, not independently opened this
  pass): versioning CLI snapshotting docs per release, maintainers'
  own framing as fitting "software libraries or APIs that evolve over
  time" — retrieved 2026-08-31
- Sphinx as the Python-ecosystem library-documentation standard
  (`autodoc`, cross-referencing) — search-corroborated across multiple
  2026 documentation-tooling roundups, no single primary source direct-
  fetched this pass — retrieved 2026-08-31
- tox / nox / `tox-gh` matrix-testing mechanics — search-corroborated
  (`tox-dev/tox-gh` GitHub README summary, multiple 2026 practitioner
  posts): `tox-gh` requires tox ≥ 4.31, auto-maps GitHub Actions matrix
  Python version to tox environment — retrieved 2026-08-31, `tox-gh`'s own
  README not independently direct-fetched
- https://github.com/rust-lang/crater — search-corroborated (repo README
  summary): ecosystem-wide compiler-regression testing across tens of
  thousands of real crates, Docker-isolated, network-disabled builds —
  retrieved 2026-08-31
- semantic-release vs. Release Please vs. Changesets — search-
  corroborated across multiple 2026 comparison posts (no single primary
  source; adoption figures — `@changesets/cli` ~3.1M vs. semantic-release
  ~2.6M weekly downloads — trace to one comparison site, `pkgpulse.com`,
  flagged as not independently cross-verified) — retrieved 2026-08-31
- https://opentelemetry.io/docs/specs/otel/versioning-and-stability/ —
  direct fetch: full Development/Stable/Deprecated/Removed lifecycle,
  per-level allowed-change rules, spec-vs-per-language independent
  versioning — retrieved 2026-08-31
- Rust async-runtime ecosystem (Tokio vs. smol dependency-count
  comparison, runtime-agnostic library design guidance) — search-
  corroborated across `corrode.dev`, `rustify.rs`, and the async-book's
  own ecosystem chapter — retrieved 2026-08-31
- https://github.com/async-rs/async-std — direct fetch: README confirms
  "`async-std` has been discontinued; use `smol` instead" — retrieved
  2026-08-31; the specific March-2025 discontinuation date is search-
  corroborated only, not confirmed by this direct fetch
- https://clig.dev/ — direct fetch: full Command Line Interface
  Guidelines — help/example-first conventions, flags-over-positional-args,
  stdout/stderr stream discipline, exit-code convention, human-first with
  explicit `--json`/`--plain` machine-output opt-in, TTY-conditional
  color/animation with `NO_COLOR`/`--no-color`, tiered destructive-action
  confirmation, "rewrite errors for humans" principle — retrieved
  2026-08-31 (added per user request to cover CLI-UX)
- https://github.com/microsoft/language-server-protocol — direct fetch:
  CC-BY-4.0, 12,997 stars, pushed 2026-08-29 (actively maintained) —
  confirms LSP as a currently-thriving, not legacy, protocol — retrieved
  2026-08-31 (added per user request to cover LSP/IDE-tooling)
- Local precedent (not web sources, read/checked directly):
  `/Users/devopammittra/GitHub/agent-skills/.claude-plugin/plugin.json`,
  `/Users/devopammittra/GitHub/agent-skills/CHANGELOG.md`,
  `/Users/devopammittra/GitHub/agent-skills/CONTRIBUTING.md` — read
  2026-08-31; `/Users/devopammittra/GitHub/ubi-csr-tmf` directory
  structure — checked 2026-08-31; `/Users/devopammittra/GitHub/` listing
  confirming MCPg's absence — checked 2026-08-31; secondhand MCPg context
  grepped from `research/stacks/agentic-mcp-platforms/{stack.md,
  libraries.md}` (authored 2026-08-19, in a different environment) —
  grepped 2026-08-31, not independently re-verified

## Open questions for the user

**Resolved this pass (2026-08-31 follow-up):** PEP 8, PEP 387, and PEP 702
are now all direct-fetched (see Sources) — PEP 387 additionally yielded a
concrete 5-year deprecation-window preference and a soft-deprecation
option not in the first-pass draft, both folded into the Deprecation
section above. crates.io's Trusted Publishing claim is now corroborated
across three independent sources (RFC 3691 + two Socket.dev posts) with
the per-crate `trustpub_only` enforcement flag confirmed by name; the
specific 30-minute token lifetime could not be pinned to a primary source
(the crates.io docs page doesn't render via WebFetch) and has been
softened to "short-lived, tens of minutes" in the table above rather than
asserted as an exact figure — acceptable given the doc's actual claim only
needs "short-lived," not the precise number.

**Added per explicit user decision (2026-08-31):** LSP/IDE-tooling and
CLI-UX now have their own In-scope subsections above (LSP scoped at
architecture/protocol-shape depth, distinguishing an LSP server from a
build-tool/linter plugin; CLI-UX anchored on `clig.dev`'s help/flags/
streams/exit-codes/confirmation-prompt/color conventions). Release
automation now names an explicit default (Changesets for monorepos,
Release Please for single-package repos, semantic-release only once a
team already trusts full automation) rather than staying neutral, also
per explicit user decision — see the updated CI/CD release-automation
section above.

- The Claude Code plugin-marketplace section leans on this repo itself as
  the running example throughout (appropriate given the task's framing
  that this repo is self-referentially an instance of this category) —
  confirm that's the right amount of self-reference for the authored doc,
  versus treating it as one example among several equally-weighted
  marketplace models (VS Code, JetBrains Marketplace, Chrome Web Store —
  the latter two named as comparable patterns but not independently
  researched this pass beyond VS Code).
## Target file(s) + estimated length

- skills/project-incubation/references/stacks/developer-tooling-libraries.md
  — est. 480–570 lines (10 subsections per the In-scope list above, now
  including CLI-UX and LSP/IDE-tooling; the semver-discipline,
  packaging/publishing, and CLI-UX sections are the longest, roughly
  matching the density of the agentic-mcp-platforms and
  backend-api-services baselines' authored output).
