# Developer Tooling & Libraries — Architecture & Stack

This category covers SDKs, CLI tools, language-server/IDE integrations, and
publishable packages or libraries whose primary consumer is another
developer's code, build, or terminal session — not an end-user-facing
application (see [Business Applications](business-applications.md)), not a
request/response API surface serving conventional clients (see
[Backend & API Services](backend-api-services.md)), and not a tool surface
primarily called by an LLM agent (see
[Agentic & MCP Platforms](agentic-mcp-platforms.md)). The line between
"library" and "service" isn't always clean — a CLI that wraps a hosted API,
or an SDK that's mostly a typed client for a backend service, sits partly in
this category and partly in one of those — but the defining question this
doc answers is: once you ship it, does someone else's code or shell import,
link, or invoke it directly? If yes, everything below applies.

This category has real local precedent, unusually for a stack-specific doc
in this repo: this very repository, `agent-skills`, is itself a publishable
developer-tooling artifact. It's distributed through a Claude Code plugin
marketplace rather than PyPI/npm/crates.io — there's no `pyproject.toml`,
`package.json`, or crate manifest anywhere in the tree. Its distribution
identity lives entirely in `.claude-plugin/plugin.json`
(`name`/`version`/`description`/`author`), its versioning discipline is
documented in its own `CONTRIBUTING.md`, and its changes are recorded in
`CHANGELOG.md`. That example recurs throughout this doc, particularly in the
packaging/publishing section, as a real instance of a category member whose
"API" being kept stable is prose and file paths under `references/`, not a
function signature.

One convention carried through every section: numeric claims (adoption
percentages, dependency counts, download figures, exact token lifetimes) are
omitted, or explicitly downgraded to a qualitative/order-of-magnitude claim,
wherever the only source traced back to an SEO-aggregator, a single
comparison site, or an illustrative (non-committed) example rather than a
primary, verifiable figure. Where that downgrade happens, the section says so
rather than quietly repeating the more precise-sounding number.

## Table of contents

- [Semver discipline across ecosystems](#semver-discipline-across-ecosystems)
- [Marking API stability and the public surface](#marking-api-stability-and-the-public-surface)
- [Deprecation policy mechanics](#deprecation-policy-mechanics)
- [Packaging and publishing: the shift to OIDC trusted publishing](#packaging-and-publishing-the-shift-to-oidc-trusted-publishing)
- [Docs as the product](#docs-as-the-product)
- [Testing this category needs that a service doesn't](#testing-this-category-needs-that-a-service-doesnt)
- [Release automation](#release-automation)
- [Module boundaries and dependency minimalism](#module-boundaries-and-dependency-minimalism)
- [CLI-specific UX and interaction design](#cli-specific-ux-and-interaction-design)
- [LSP and IDE-tooling development](#lsp-and-ide-tooling-development)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Semver discipline across ecosystems

All three ecosystems checked here agree on what MAJOR/MINOR/PATCH are
*supposed* to mean — SemVer 2.0.0 itself (confirmed by direct fetch) defines
major as incompatible API changes, minor as backward-compatible additions,
patch as backward-compatible fixes, and requires a project to *declare* what
its public API even is before version numbers mean anything ("This API could
be declared in the code itself or exist strictly in documentation... it
SHOULD be precise and comprehensive"). Where they diverge sharply is
enforcement:

| Ecosystem | What counts as breaking, in practice | Enforcement |
|---|---|---|
| Python (PyPA) | No single enforced rule. PyPA's own packaging guide states plainly that "most projects, especially larger ones, do not strictly adhere to semantic versioning, since many changes are technically breaking changes but affect only a small fraction of users," and names Sphinx (strict semver) and NumPy (deliberately "loose" semver, permitting some backward-incompatible changes in minor releases) as two real, divergent, both-legitimate approaches | None mechanical — PEP 440 governs version-*string* syntax, not semver semantics |
| npm | Adding/removing/renaming exported symbols, changing function signatures — left to maintainer judgment. npm's own docs frame it simply: "if you introduce a change that breaks a package dependency, we strongly recommend incrementing the version major number" | None built into npm itself |
| Rust (Cargo) | Machine-checkable and unusually strict. Cargo's own SemVer reference enumerates dozens of per-construct rules: removing or renaming any public item is major; adding a public struct field is major *if* the struct already has another public field and no private field (it breaks struct-literal construction); adding an enum variant is major *unless* the enum is `#[non_exhaustive]`; adding a non-defaulted trait item, tightening a generic bound, or changing a function's arity are all major. This granularity exists because Rust's exhaustiveness checking, trait-impl resolution, and struct-literal construction make far more code shapes semver-relevant than in Python or JS | **`cargo-semver-checks`** mechanically enforces a large subset of these rules in CI by diffing `rustdoc`'s JSON output between two versions — its own README acknowledges it "doesn't yet have lints for all of them," so it's a strong-but-incomplete safety net, not a complete guarantee. **`cargo public-api`** is a second, complementary tool: it lists and diffs a crate's full public API surface between releases (also rustdoc-JSON-based, needs a nightly toolchain), usable in CI as a human-reviewable diff even where `cargo-semver-checks`'s automated severity classification doesn't yet cover a given change shape |

The practical takeaway: Python and npm treat semver as a maintainer-judgment
convention with real, acknowledged divergence in practice — NumPy's own
stated policy is the clearest example of a large, serious project choosing
*not* to follow strict semver and saying so openly. Rust treats it as close
to a build-checkable contract. A project in any language can choose to adopt
that rigor — a documented public-API surface plus a mechanical diff-on-CI
step — once it ships a stable surface other code genuinely depends on; it
isn't a Rust-only option, just a Rust-only *default*.

## Marking API stability and the public surface

Python's convention for what's public lives in PEP 8: a module's public
interface is `__all__` if the module declares one, else every name not
starting with `_`. Confirmed by direct fetch of PEP 8 itself: "modules
should explicitly declare the names in their public API using the `__all__`
attribute," and even with `__all__` set, "internal interfaces... should still
be prefixed with a single leading underscore." Neither mechanism is access
control — Python still lets you import an underscore-prefixed name — both
are naming and declaration conventions layered on top of each other, and
`__all__` mainly governs `from module import *` and documentation tooling.

The real gap this leaves is that the declaration (`__all__`) lives apart
from the definition (the `def`/`class` itself), which drifts: a name added to
a module but never added to `__all__`, or a stale `__all__` entry surviving a
rename. **PEP 844** (Draft, targeting Python 3.16, created 2026-08-05 — a
genuinely fresh proposal at the time of this doc) proposes `@public`/
`private()` builtins so a name's visibility is declared once, at its
definition site, and `__all__` is derived automatically from those
decorations. This isn't a new idea PEP 844 invented: it codifies a pattern
the third-party `atpublic` package (originally authored by Barry Warsaw) has
implemented the same way since 2016 — a `@public` decorator populating
`__all__` at the point of definition rather than in a separate list
elsewhere in the file. PEP 844 cites that package's design directly as its
model. Treat PEP 844 as "the direction Python itself is moving," not yet
shipped language; the pattern it formalizes is already field-tested through
that decade-old library.

**OpenTelemetry's stability-level model** is a concrete, cross-language,
already-shipped instance of the same underlying idea — marking API surfaces
as stable-or-not — done at the level of an entire spec rather than a single
language's naming convention. Every signal progresses **Development → Stable
→ Deprecated → Removed** (confirmed by direct fetch of OpenTelemetry's own
versioning-and-stability spec page): Development-stage code may have
breaking changes and "should not be considered feature complete"; once
Stable, "all existing API calls MUST continue to compile and function
against all future minor versions of the same major version"; and a signal
cannot be marked Deprecated unless its replacement is already Stable. Each
language SDK version-tracks independently of the spec version it implements
— the spec's own example is that `opentelemetry-python-api` v1.8.2 can
implement spec v1.1.1 — a useful pattern for any project that wants to split
a stable core from an evolving spec/protocol layer underneath it.

Rust's `#[non_exhaustive]` attribute, already introduced above under semver,
is itself an API-stability-marking mechanism at the language level: it lets
a maintainer add enum variants or struct fields later without that counting
as a breaking change, at the cost of consumers being forced to handle an
`_ => {}` catch-all arm they might otherwise consider unnecessary.

## Deprecation policy mechanics

CPython's own policy, **PEP 387** (Status: Active, a living process PEP, not
a one-time proposal), is the most concrete deprecation-mechanics source
checked here. Its normative core: "the behavior of an API must not change in
an incompatible fashion between any two consecutive releases" outside a
formal deprecation process, and "a feature cannot be removed without notice
between any two consecutive releases." The required minimum is **two
consecutive minor releases'** warning within a major version (one minor
release if in an older major version) before removal — and PEP 387 states an
explicit **preference for a 5-year deprecation window** for widely-used
APIs, a concrete number rather than a vague "give people time." It also
names a **soft-deprecation** option distinct from either "keep" or
"deprecate-then-remove": an API marked discouraged-for-new-code in
documentation only, with no runtime warning and no scheduled removal — worth
knowing as a real third choice, not just those two.

The stdlib's warning taxonomy matters for getting this right in your own
project: `DeprecationWarning` is shown by default only for code running in
`__main__`, hidden for library/third-party code by default — the rationale
being that *end users* running a script shouldn't be silently insulated from
deprecation notices meant for the *developers* of that code. `FutureWarning`
is shown by default for **all** code and is intended for end-user-facing
tools rather than library internals. Picking the wrong one of the two is an
easy, common mistake: a library warning its own downstream library authors
should use `DeprecationWarning`; a CLI tool warning its end users about a
flag going away should use `FutureWarning`.

**PEP 702** (Status: Final, shipped in Python 3.13) adds a
`@warnings.deprecated()` decorator so static type checkers, not just runtime
code paths, can flag deprecated-API use — a type checker "should produce a
diagnostic whenever they encounter a usage of an object marked as
deprecated," covering imports, attribute access, indirect calls via operator
overloads, and per-overload deprecation. The PEP text itself now carries a
notice marking it historical; current authoritative behavior is maintained
at the typing-specs site, which is the better link to carry forward than the
PEP alone.

Two real, differently-shaped examples outside the stdlib are worth naming
because they show the same underlying pattern converging independently.
**Django's two-release cycle**: an API first emits
`PendingDeprecationWarning` (silent by default, informational), then one
release later upgrades to `DeprecationWarning` (visible), and only after
*that* release is the API actually removed. **NumPy's NEP 23**: the explicit
principle is that breaking changes "need to benefit more than they harm
users," and because NumPy is foundational infrastructure, "breaking changes
should be assumed by default to be harmful" — backward-incompatible changes
require a deprecation warning for at least two releases before removal. NEP
23 separately locks the `.npy`/`.npz` on-disk file format to strict backward
compatibility independent of the library's own version — a useful example of
*data-format* stability being a distinct commitment from *API* stability
within the same project; a library can break its Python API on a major
version while still guaranteeing it can read every file it, or an older
version of itself, ever wrote.

No single grace-period number is universal across ecosystems, but a
two-releases-minimum, warn-then-remove cycle — Django's and NumPy's shape —
is the most consistently-cited concrete pattern, and a reasonable default
recommendation absent a project-specific reason (a security fix, a
regulatory constraint) to diverge from it.

## Packaging and publishing: the shift to OIDC trusted publishing

This is the single most consequential *current* fact for this category. Every
major registry checked here has moved, or is actively moving, from a
long-lived manually-managed publish token to a short-lived, workflow-scoped
credential issued via OIDC:

| Registry | Current recommended publishing auth | Mechanics |
|---|---|---|
| PyPI | Trusted Publishing (OIDC) — PyPI's own stated recommendation | A CI provider (e.g. GitHub Actions) acts as an OIDC identity provider; PyPI exchanges the CI-issued OIDC token for a short-lived (**15-minute**) API token scoped to a single publish — no secret stored in CI configuration at all, versus a long-lived API token that remains active indefinitely if never manually rotated |
| npm | Trusted Publishing (OIDC) — supports GitHub Actions, GitLab CI/CD, and CircleCI (cloud-hosted runners only; self-hosted runners explicitly not yet supported), requiring npm CLI ≥ 11.5.1 and Node ≥ 22.14.0 | Same short-lived-workflow-scoped-credential shape as PyPI, explicitly positioned to eliminate long-lived npm tokens |
| crates.io | Trusted Publishing (OIDC) — GitHub Actions was the initial provider; GitLab CI/CD support has since shipped (currently limited to GitLab.com) | For GitHub, `rust-lang/crates-io-auth-action` exchanges the OIDC token for a short-lived access token — "short-lived, tens of minutes" is the honest claim here; the specific 30-minute figure circulating for this comes only from an RFC's illustrative example, not a committed primary source, and `crates.io`'s own docs page is a client-rendered SPA that doesn't yield its content to a plain fetch. A crate owner can additionally flip a `trustpub_only` flag (default `false`, visible via the crates.io API) that disables token-based publishing for that crate entirely — real, named, per-crate enforcement, not just an ecosystem-wide recommendation. Cargo's own reference docs still describe only the classic long-lived `cargo login` token flow — the OIDC mechanism is a crates.io registry-side feature layered on top, not yet reflected in Cargo's own core docs |
| Claude Code plugin marketplace | No token-based publish step at all | A plugin is a git repository; a marketplace is a `marketplace.json` catalog, itself git-hosted, listing plugin sources. Publishing to a *shared* marketplace means either hosting your own marketplace repo or submitting to Anthropic's community marketplace, where approved submissions are pinned to a specific commit SHA and a CI process bumps that pin automatically on new pushes, syncing nightly. Governance here is curation/review-based (a safety screening plus a `claude plugin validate` pass), not registry-namespace-claim-based the way PyPI/npm/crates.io are |
| VS Code Marketplace (a second plugin-marketplace instance, for comparison) | Historically Azure DevOps Personal Access Tokens; global PATs retire **2026-12-01** in favor of Microsoft Entra ID-based automated publishing | Same long-lived-token-to-short-lived-identity-token migration arc as PyPI/npm/crates.io, on its own timeline, in a different ecosystem. VS Code's Marketplace is also stricter than SemVer itself in one respect worth flagging: it accepts only plain `X.Y.Z` versions, and — unlike npm, which does — rejects SemVer prerelease suffixes like `-beta` |

The cross-ecosystem pattern worth stating plainly: this is not a
PyPI-specific or npm-specific quirk, it's the current direction of the
*entire* category, and a new project's CI/CD release setup should default to
whichever OIDC mechanism its target registry supports, rather than minting a
long-lived token as the starting point and migrating later. For a project
distributed through a plugin marketplace instead of a package registry, the
equivalent discipline isn't a credential at all — it's treating the pinned
commit SHA and the marketplace's review/sync cadence as the trust boundary
that a token would otherwise represent.

## Docs as the product

A library or SDK's documentation *is* the primary integration surface most
consumers touch before ever reading source — the README is frequently a new
user's entire onboarding path, doing the job of marketing, quickstart, and
API reference entry point simultaneously. That's a materially different job
than an internal application's README, which mostly only serves its own
small team and rarely needs to sell anyone on adopting it.

Docs-as-code is the baseline discipline this category should default to:
documentation lives in the same repository as source, authored in Markdown
or reST, reviewed through the same PR process as code, and deployed by the
same CI/CD — the explicit goal being that docs can't silently drift out of
sync with a release the way an externally-hosted wiki can.

**Versioned docs** is the mechanism specific to this category: an
application usually only needs "current" docs for its one deployed version,
but a library's users may be pinned to any supported major version and need
docs matching *their* version, not the newest one. Two tools recur as the
current default per ecosystem: **Docusaurus** ships a first-class versioning
CLI that snapshots the current docs tree into a frozen version directory per
release, explicitly positioned by its own maintainers as fitting "software
libraries or APIs that evolve over time." **Sphinx** is the more common
choice specifically for API-reference-heavy Python libraries, owing to
`autodoc` — pulling reference docs directly from docstrings, keeping
reference material mechanically synced to the actual code — and its
cross-referencing depth.

Practical default: treat README quality (install instructions, a working
quickstart example, a link to full docs) as a release-blocking concern on
par with passing tests for any publishable package. Adopt a versioned-docs
tool as soon as more than one major version is genuinely in the wild
simultaneously — not before, since versioning machinery is pure overhead for
a pre-1.0 or single-supported-version project.

## Testing this category needs that a service doesn't

Two things a service-oriented codebase doesn't need that a library does:
**cross-version/cross-platform matrix testing**, and **testing against
realistic downstream consumer usage** rather than only the library's own
internal suite.

Matrix testing runs the same test suite across every supported language or
runtime version — and sometimes OS — in parallel CI jobs. In Python
specifically, **tox** or **nox** define the per-version environment recipe,
and a GitHub Actions matrix (one `actions/setup-python` step per matrix
cell) drives which interpreter each job actually uses. The `tox-gh` plugin
(requires tox ≥ 4.31) automatically maps a GitHub Actions matrix Python
version to the matching tox environment, avoiding a hand-duplicated version
list maintained in two places (the workflow YAML and the tox config). This
matters specifically for this category because a library's contract is
"works on every Python/Node/Rust version we claim to support," not "works in
our one deployed environment" — the deployment-target question a service
asks doesn't even apply to something with no deployment of its own.

**Testing against real downstream usage** is this category's most
distinctive testing concern, and Rust's **Crater** is the sharpest available
worked example: it builds and runs the test suites of tens of thousands of
real crates.io and GitHub crates against two compiler versions and diffs the
results, specifically to catch regressions that no compiler-internal test
suite would surface. Network access is disabled during builds to prevent
abuse, and the tool runs isolated in Docker. Crater-scale infrastructure is
obviously out of reach for most projects, but the pattern scales down
cleanly: pin a handful of real downstream consumer repositories as an
integration-test target before cutting a release with any API-surface
change, rather than trusting the library's own suite to catch everything a
real consumer's usage would.

## Release automation

Three tools recur across current comparison sources, each solving the "bump
version, write the changelog, tag, publish" problem with a different amount
of human gating:

| Tool | Shape | Fits |
|---|---|---|
| **semantic-release** | Fully automated — parses commit messages (Conventional Commits), computes the next version, writes the changelog, publishes, with zero human approval step in the loop | Trunk-based teams comfortable with commit-message discipline substituting for a review gate on the release decision itself |
| **Release Please** (Google) | Opens and maintains a standing "release PR" (also Conventional-Commits-driven) that a human merges to actually cut the release | Teams that want automation for the mechanical parts (changelog assembly, version-bump math) but a deliberate human approval point before anything ships |
| **Changesets** | Contributor-authored changeset files — one per PR, describing that change's semver impact in the contributor's own words — accumulate and get assembled into a release | Multi-package repos, or any team preferring an explicit per-PR "here's what this change means for semver" statement over inferring intent from commit messages. The recurring reason cited for preferring it specifically in monorepos: interdependent packages need per-package version bumps computed from a shared changeset pool, which commit-message parsing alone doesn't give you |

**Default recommendation**: **Changesets for a monorepo or multi-package
repo, Release Please for a single-package repo.** A human-gated release PR
is the safer starting default than semantic-release's fully-automated
publish — it costs nothing but one merge click, and it catches a wrong
version-bump inference before it ships. semantic-release's zero-approval
step only pays for itself once a team already has enough Conventional-Commits
discipline, and enough trust in the automation, to accept that risk — reach
for it once that trust is established, not as the starting point for a new
project.

All three are npm/JS-ecosystem-native tools first. Python and Rust projects
commonly adopt one of these anyway for the changelog/tagging mechanics even
when publishing to PyPI or crates.io rather than npm, since "compute the
next version from a structured record of changes" is a language-agnostic
problem — the tool doesn't need to understand your package format to solve
it, only your changelog format.

## Module boundaries and dependency minimalism

[architecture-templates.md](../architecture-templates.md)'s seven-pattern
catalog (layered, hexagonal, microservices, modular monolith, event-driven,
CQRS/event sourcing, serverless) is largely **not the relevant axis** for a
library or SDK the way it is for a service: there's no request to route, no
deployment topology to choose, and often no running process at all. A
library that happens to also ship a long-running component (a language
server, discussed below, or a bundled dev server) can reuse that catalog for
*that* component, but the library's own public surface isn't shaped by it.

What *is* distinctive to this category, and isn't covered by the
cross-cutting doc at all, is **module and plugin boundary design as the
primary internal-architecture concern**. The question isn't "which service
talks to which," it's "which internal module is part of the stable public
surface a consumer can depend on, versus an implementation detail free to
change at any time" — which is exactly what the API-stability-marking
conventions covered earlier in this doc exist to encode. Getting this
boundary wrong in either direction has a real cost: too permissive (everything
importable is implicitly public) and any refactor risks breaking a consumer
who reached into something never meant to be depended on; too restrictive
(nothing is exposed until a formal review) and legitimate extension points
get walled off, pushing consumers toward monkeypatching or forking.

**Minimal transitive dependency footprint** is a second, explicit,
actively-traded-off design axis specific to this category: every dependency
a library takes becomes a burden imposed on every consumer of that library,
not just a cost its own maintainers bear — a service can absorb a heavy
dependency more easily because it's the only thing depending on itself. The
Rust async-runtime ecosystem is a concrete, verifiable illustration.
`smol` is explicitly positioned by its own maintainers as the lighter-weight
choice "for libraries, embedded systems, and CLI tools, anywhere Tokio's
dependency weight feels excessive," while `tokio` is the ecosystem's default
for *applications* that don't mind the weight in exchange for its broader
feature set and ecosystem integration (one 2026 analysis put Tokio's runtime
usage at over 20,000 crates depending on it, dwarfing async-std and smol on
the same chart — a real, if single-source, order-of-magnitude signal rather
than a precisely comparable dependency-count figure for smol itself, which
this pass could not independently pin down to an exact number). The same
heavier-more-featured-versus-lighter-more-embeddable trade-off recurs
whenever any library author chooses its own dependencies.

There's a sharper, more specific trap here worth naming precisely, because
getting it slightly wrong produces advice that sounds right but isn't:
**Tokio's own `AsyncRead`/`AsyncWrite` traits are not the same traits as the
ones the `futures` crate defines**, and `async-std` and `smol` are built on
the `futures` crate's versions. The Rust async book states the practical
consequence directly: "Tokio uses the mio reactor and defines its own
versions of async I/O traits, including `AsyncRead` and `AsyncWrite`. On its
own, it's not compatible with async-std and smol." Concretely, this means
writing a library against `futures::io::AsyncRead` does *not*, by itself,
make that library work transparently with a Tokio-based consumer — it makes
it portable across the `futures`/`async-std`/`smol` side of a split
ecosystem, not across both sides of it. Bridging the split requires an
explicit compatibility adapter — `async-compat` is one such crate, applying
a `Compat` wrapper so a type implementing one trait family can be used where
the other is expected — or a library avoids the question entirely by not
touching raw async I/O or task-spawning at all. The async book's own general
guidance is the cleanest statement of that safer default: "libraries
exposing async APIs should not depend on a specific executor or reactor,
unless they need to spawn tasks or define their own async I/O or timer
futures." A small ecosystem of "agnostic executor" crates exists
specifically to formalize this (e.g. `agnostic_async_executor`, a modestly
adopted crate offering a concrete `AgnosticExecutor` type that a library can
accept from its caller instead of hardcoding a specific runtime's spawn
call) — worth knowing the pattern exists, without treating any single crate
in that space as an established default; that comparative call belongs to
the companion
[preferred-libraries/developer-tooling-libraries.md](../preferred-libraries/developer-tooling-libraries.md).

The `async-std`-to-`smol` consolidation is a real, dated example of what
happens when a library *doesn't* stay runtime-agnostic: `async-std`'s own
README states plainly that "`async-std` has been discontinued; use `smol`
instead." A library that hardcoded a dependency on `async-std` specifically
— rather than on the `futures` traits `async-std` merely implemented — broke
for every consumer once that happened. That's the general, portable
principle worth carrying forward beyond Rust: a library should depend on the
thinnest possible abstraction its consumers already have to deal with (an
async trait, a logging facade, a serialization protocol) rather than a
specific concrete runtime, framework, or implementation. The cost of getting
this wrong is borne by every downstream consumer, not just the library's own
maintainers — precisely the distinction between building an application and
building something other developers build on.

## CLI-specific UX and interaction design

**Command Line Interface Guidelines** (`clig.dev`) is the closest thing this
sub-genre has to a canonical spec, and its conventions are concrete and
load-bearing enough to carry forward close to verbatim.

**Help conventions**: `-h`/`--help` must work after any command or
subcommand, and the help text should *lead with usage examples* rather than
an exhaustive flag list — the guidelines' own framing is that "users tend to
use examples over other forms of documentation." A wall of flag definitions
with no worked example at the top makes a user hunt for how the pieces fit
together; an example up front answers the question they actually have.

**Flags over positional arguments** for anything beyond the one or two most
obvious required arguments. Flags are self-documenting at the call site; a
positional argument requires the caller to remember argument order from
memory or the docs. Every flag should get both a short (`-v`) and long
(`--verbose`) form, but reserve one-letter short forms for genuinely common
flags — handing out `-x`-style single letters to rarely-used flags just
burns the available alphabet.

**Stream discipline**: primary output goes to `stdout`; all logging, errors,
and progress output go to `stderr`. This single rule is what keeps a tool
composable in a Unix pipeline — a caller piping your tool's stdout into
`jq` or `grep` shouldn't have to filter out log lines mixed into the same
stream.

**Exit codes**: zero for success, non-zero for failure — the only signal a
calling script can act on without parsing output text.

**Human output first, machine output as an explicit opt-in**: default to
human-readable formatting, detect non-TTY output (piped or redirected) and
drop decoration automatically, and provide an explicit `--json` (structured,
script-parseable) and/or `--plain` (one record per line) flag for callers
that need to parse output programmatically. Never require a human user to
pass a flag just to get output they can actually read.

**Animations and color are conditional, not assumed**: disable
spinners/progress animations whenever `stdout` isn't an interactive
terminal — the guidelines' own framing is that this is what stops "progress
bars turning into Christmas trees in CI log output" — and respect both a
`--no-color` flag and the `NO_COLOR` environment-variable convention.

**Destructive-action confirmation, scaled to blast radius**: no prompt for a
fully reversible action; a plain y/n confirmation for a moderate one; and
for a genuinely destructive one, require the caller to type the resource's
own name back, or pass an explicit `--confirm=<name>` flag. A single
`--force` flag that bypasses all of the above regardless of blast radius is
exactly the anti-pattern this guideline is warning against — it collapses
three different risk tiers into one bypass.

**Error messages rewritten for humans**, not raw stack traces or `errno`
text — the stated principle is that signal-to-noise ratio directly
determines how long a user takes to recover from a mistake. A user who sees
`ENOENT` has to already know what that means; a user who sees "config file
not found at ~/.myapp/config.toml — run `myapp init` to create one" can act
immediately.

This entire section is a CLI-shaped artifact's UX *contract*, distinct from
— and additive to — the CLI *framework* choice covered in
[preferred-libraries/developer-tooling-libraries.md](../preferred-libraries/developer-tooling-libraries.md).
Every mainstream CLI framework in that companion doc supports building a
tool that follows every convention above; none of them enforce good
`--help` copy or the right confirmation-prompt threshold by default. That
remains an authoring discipline layered on top of whichever framework gets
chosen, not something the framework choice settles for you.

## LSP and IDE-tooling development

Language-server and IDE-tooling development is a real, distinct sub-genre of
developer tooling, not just "another kind of plugin." The **Language Server
Protocol** itself is the foundational fact that makes this its own
architecture concern: one server implementation, written once in whatever
language or runtime the tool author prefers, speaks JSON-RPC over stdio or
sockets to *any* LSP-client editor — VS Code, Neovim, Zed, JetBrains via a
bridge. That's the same "write once, serve many clients" economics that
motivate a library in the first place, just applied to editor integration
specifically instead of to a general API surface. The protocol is actively
maintained, not a legacy artifact from an earlier era of tooling.

This is architecturally distinct from a **build-tool or linter plugin** — a
Vite plugin, an ESLint rule, a Ruff plugin. An LSP server is a long-running,
stateful process that maintains a live document and workspace model and
responds to incremental edit events as a developer types. A build-tool
plugin is typically a synchronous hook invoked once per build or lint pass,
with no persistent state carried across invocations. Both are "developer
tooling that extends someone else's tool," but the architecture and the API
contract each implements against are not the same thing, and treating them
as interchangeable design problems is a mistake — a linter-plugin author
moving to LSP-server work needs to design for state and concurrency
questions (what happens to an in-flight diagnostics computation when the
document changes again before it finishes?) that a per-invocation plugin
never has to answer.

A genuinely distinct concern from the CLI/SDK/library design covered
elsewhere in this doc: an LSP server's own "public API" is the protocol's
fixed message set — `initialize`, `textDocument/completion`,
`textDocument/publishDiagnostics`, and the rest. The server author has no
freedom to design that surface, only to decide which optional capabilities
to implement. That inverts this category's usual semver/API-stability
concern: there's no versioning decision to make for the protocol surface
itself, since it isn't yours to version — the only versioning decision that
does apply is to implementation-specific extensions a server may layer on
top of the standard message set.

## Where this doc stops

Specific library, framework, and CLI-toolkit names, and their license and
maintenance detail, belong entirely to the companion
[preferred-libraries/developer-tooling-libraries.md](../preferred-libraries/developer-tooling-libraries.md) —
this doc names a tool only where the tool itself *is* the architectural fact
being described (`cargo-semver-checks` mechanically enforcing semver rules,
`async-compat` bridging an incompatible-trait split), not as a comparative
recommendation. Deep CI/CD platform mechanics — GitHub Actions YAML syntax,
runner pricing — are out of scope beyond what the release-automation and
matrix-testing sections above need to describe *what* those steps must
accomplish, not a platform-specific tutorial. Build-tool/linter-plugin
development mechanics (writing an actual ESLint rule, a Ruff plugin, a Vite
plugin) are named only as the architectural contrast to LSP servers above; a
dedicated treatment of that sub-genre's own plugin-API conventions would
need its own research pass. Shell-completion generation mechanics in
implementation depth, and monorepo workspace tooling (Nx, Turborepo, Cargo
workspaces) beyond the Changesets-for-monorepos mention above, are both
real, adjacent concerns this doc doesn't go deeper into. Cost modeling and
registry pricing are out of scope, consistent with every other doc in this
skill. The plugin-marketplace review process's internal safety-screening
mechanics aren't documented publicly in enough depth to add here; this doc
describes only the externally-visible shape (submit → automated and human
review → pinned commit SHA → nightly sync).

For the case where what you're building is actually a hosted API that
happens to ship a client SDK alongside it, start from
[Backend & API Services](backend-api-services.md) for the service's own
architecture and treat this doc's SDK-specific sections (semver, deprecation,
docs-as-product, CLI-UX if the SDK ships a CLI) as the client-side layer on
top. For the case where the primary consumer of what you're building is an
LLM agent rather than a human developer or another program, start from
[Agentic & MCP Platforms](agentic-mcp-platforms.md) instead — the two
categories share a family resemblance (both are "someone else's code calls
into mine") but an agent-facing tool surface has its own schema, prompt, and
safety concerns this doc doesn't cover.

## Sources

- https://semver.org/ — direct fetch: SemVer 2.0.0, MAJOR/MINOR/PATCH
  definitions, requirement to declare a precise public API before version
  numbers are meaningful — retrieved 2026-08-31
- https://packaging.python.org/en/latest/discussions/versioning/ — direct
  fetch: PyPA's acknowledgment that most projects don't strictly follow
  semver, explicit Sphinx (strict) vs. NumPy (loose) contrast — retrieved
  2026-08-31
- https://docs.npmjs.com/about-semantic-versioning — direct fetch: npm's own
  semver guidance and major-bump recommendation for breaking changes —
  retrieved 2026-08-31
- https://doc.rust-lang.org/cargo/reference/semver.html — direct fetch: full
  per-construct major/minor/possibly-breaking classification table —
  retrieved 2026-08-31
- https://github.com/obi1kenobi/cargo-semver-checks — direct fetch:
  rustdoc-JSON + `trustfall`-query mechanism, GitHub Action integration,
  acknowledged incomplete lint coverage — retrieved 2026-08-31
- https://github.com/cargo-public-api/cargo-public-api — search-corroborated:
  lists/diffs a crate's public API via rustdoc JSON, CI-usable — retrieved
  2026-08-31
- https://peps.python.org/pep-0844/ — direct fetch: Status Draft, target
  Python 3.16, created 2026-08-05, `@public`/`private()` builtins proposal,
  explicitly builds on the third-party `atpublic` pattern — retrieved
  2026-08-31
- https://peps.python.org/pep-0008/ — direct fetch: confirms `__all__` as
  the declared public-API mechanism and leading-underscore naming as the
  non-public signal underneath it, neither being access control — retrieved
  2026-08-31
- `atpublic` package provenance (search-corroborated across PyPI's own
  project page, Guix/openSUSE/conda-forge packaging metadata, and its
  `public.readthedocs.io` docs): copyright 2016–2025, Barry Warsaw,
  Apache-2.0; a `@public` decorator populating `__all__` and optionally
  module globals at the point of definition — confirms PEP 844's own claim
  that it codifies a decade-old, already-adopted pattern rather than
  inventing a new one — retrieved 2026-08-31
- https://peps.python.org/pep-0387/ — direct fetch: Status Active; two
  consecutive minor releases' minimum warning before removal, explicit
  preference for a 5-year deprecation window for widely-used APIs, and a
  soft-deprecation option (documentation-only, no runtime warning, no
  scheduled removal) — retrieved 2026-08-31
- https://peps.python.org/pep-0702/ — direct fetch: Status Final, shipped in
  Python 3.13; `@warnings.deprecated()` decorator, type-checker diagnostic
  requirement, PEP text itself now marked historical in favor of the
  typing-specs site — retrieved 2026-08-31
- https://docs.python.org/3/deprecations/index.html — search-corroborated:
  `DeprecationWarning` (default-visible only in `__main__`) vs.
  `FutureWarning` (default-visible everywhere) — retrieved 2026-08-31
- Django's `PendingDeprecationWarning` → `DeprecationWarning` two-release
  cycle — search-corroborated across multiple secondary sources, not an
  official Django docs page independently fetched — retrieved 2026-08-31
- https://numpy.org/neps/nep-0023-backwards-compatibility.html —
  search-corroborated: "benefit more than harm" principle, ≥2-release
  deprecation-warning minimum, `.npy`/`.npz` file-format compatibility
  locked independent of library version — retrieved 2026-08-31
- https://docs.pypi.org/trusted-publishers/ — direct fetch: OIDC Trusted
  Publishing mechanics, 15-minute short-lived token, PyPI's recommended
  mechanism over long-lived API tokens — retrieved 2026-08-31
- https://docs.npmjs.com/trusted-publishers — direct fetch: OIDC Trusted
  Publishing, supported CI platforms, minimum npm CLI/Node versions —
  retrieved 2026-08-31
- https://doc.rust-lang.org/cargo/reference/publishing.html — direct fetch:
  confirms Cargo's own reference docs still describe only the classic
  long-lived `cargo login` token flow, no OIDC mention — retrieved
  2026-08-31
- crates.io Trusted Publishing — corroborated across RFC 3691
  (`rust-lang/rfcs`, direct fetch) and two Socket.dev writeups
  (`crates-launches-trusted-publishing`,
  `crates-security-tab-tightened-publishing-controls`, both direct fetch):
  GitLab CI/CD support, per-crate `trustpub_only` enforcement flag (default
  `false`, API-visible); the exact token lifetime is sourced only to the
  RFC's own illustrative example, not a committed figure —
  `crates.io/docs/trusted-publishing` itself would not render via fetch
  (client-rendered SPA) — retrieved 2026-08-31
- https://code.claude.com/docs/en/plugins — direct fetch: plugin manifest
  schema, marketplace mechanics, the two public marketplaces
  (`claude-plugins-official` curated, `claude-plugins-community`
  reviewed-and-commit-SHA-pinned), `claude plugin validate` as the
  pre-submission check — retrieved 2026-08-31
- VS Code Extension Marketplace publishing/versioning —
  search-corroborated: SemVer `X.Y.Z`-only (no prerelease suffixes), global
  Azure DevOps PATs retiring 2026-12-01 in favor of Microsoft Entra ID —
  retrieved 2026-08-31
- https://opentelemetry.io/docs/specs/otel/versioning-and-stability/ —
  direct fetch: full Development/Stable/Deprecated/Removed lifecycle,
  per-level allowed-change rules, spec-vs-per-language independent
  versioning — retrieved 2026-08-31
- Docusaurus versioning — search-corroborated: versioning CLI snapshotting
  docs per release, maintainers' own framing as fitting "software libraries
  or APIs that evolve over time" — retrieved 2026-08-31
- Sphinx as the Python-ecosystem library-documentation standard (`autodoc`,
  cross-referencing) — search-corroborated across multiple 2026
  documentation-tooling roundups — retrieved 2026-08-31
- tox / nox / `tox-gh` matrix-testing mechanics — search-corroborated
  (`tox-gh` requires tox ≥ 4.31, auto-maps GitHub Actions matrix Python
  version to tox environment) — retrieved 2026-08-31
- https://github.com/rust-lang/crater — search-corroborated: ecosystem-wide
  compiler-regression testing across tens of thousands of real crates,
  Docker-isolated, network-disabled builds — retrieved 2026-08-31
- semantic-release vs. Release Please vs. Changesets — search-corroborated
  across multiple 2026 comparison posts, no single primary source — retrieved
  2026-08-31
- https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html —
  direct fetch: confirms Tokio's `AsyncRead`/`AsyncWrite` are its own traits,
  distinct from and incompatible with the `futures`-crate versions
  `async-std`/`smol` use ("On its own, it's not compatible with async-std
  and smol"), and states the runtime-agnostic design principle directly:
  "libraries exposing async APIs should not depend on a specific executor
  or reactor, unless they need to spawn tasks or define their own async I/O
  or timer futures" — retrieved 2026-08-31
- https://corrode.dev/blog/async/ — direct fetch: Tokio runtime usage cited
  at over 20,000 crates depending on it at time of writing, dwarfing
  async-std/smol on the same comparison; no independently-verifiable exact
  dependency count for smol itself found this pass (crates.io's own
  dependency-listing pages are client-rendered and didn't yield content to
  a plain fetch) — retrieved 2026-08-31
- https://github.com/smol-rs/smol — direct fetch (README): confirms smol's
  own positioning as "for libraries, embedded systems, and CLI tools,
  anywhere Tokio's dependency weight feels excessive" — retrieved 2026-08-31
- https://github.com/async-rs/async-std — direct fetch: README confirms
  "`async-std` has been discontinued; use `smol` instead" — retrieved
  2026-08-31
- `agnostic_async_executor` (`github.com/agnostic-rust/agnostic_async_executor`,
  `lib.rs/crates/agnostic_async_executor`) — search-corroborated: a
  concrete `AgnosticExecutor` struct supporting Tokio/async-std/smol/futures
  executors/wasm-bindgen, modest adoption (single-digit GitHub stars at time
  of this pass) — named here as an instance of the runtime-agnostic-executor
  pattern, not as an endorsed default — retrieved 2026-08-31
- `async-compat` (`github.com/smol-rs/async-compat`) — search-corroborated:
  a `Compat` adapter bridging Tokio's I/O traits and the `futures`-crate
  versions `async-std`/`smol` use, cited here as the concrete mechanism that
  resolves the trait-incompatibility trap described above — retrieved
  2026-08-31
- https://clig.dev/ — direct fetch: full Command Line Interface Guidelines —
  help/example-first conventions, flags-over-positional-args, stdout/stderr
  stream discipline, exit-code convention, human-first output with explicit
  `--json`/`--plain` opt-in, TTY-conditional color/animation with
  `NO_COLOR`/`--no-color`, tiered destructive-action confirmation, "rewrite
  errors for humans" principle — retrieved 2026-08-31
- https://github.com/microsoft/language-server-protocol — direct fetch:
  CC-BY-4.0, actively maintained (pushed 2026-08-29), confirms LSP as a
  currently-thriving, not legacy, protocol — retrieved 2026-08-31
- Local precedent (not a web source, read directly):
  `/Users/devopammittra/GitHub/agent-skills/.claude-plugin/plugin.json`,
  `/Users/devopammittra/GitHub/agent-skills/CHANGELOG.md`,
  `/Users/devopammittra/GitHub/agent-skills/CONTRIBUTING.md` — read
  2026-08-31
