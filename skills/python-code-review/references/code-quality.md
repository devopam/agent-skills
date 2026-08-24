# Code Quality

This is the code quality domain of the `python-code-review` skill's
11-domain reference set. It evaluates structural health: static
type-checking rigor, complexity, naming, import organization, docstring
discipline, and dead code — the properties that determine whether a
codebase stays cheap to change six months from now, independent of whether
it's currently correct or fast.

Two boundaries matter enough to call out up front rather than only at the
point they bite. First, `py.typed` (PEP 561) has two independent halves:
whether a package's types are *actually correct and complete* is this
domain's lens (covered below); whether the `py.typed` file is *packaged
correctly for distribution* — included in wheel/sdist contents, declared in
`package_data` — is a packaging-declaration concern owned by
[Standards Compliance](../references/standards-compliance.md). Second,
mocking correctness, fixture design, and test-suite tooling are
[Testing](../references/testing.md)'s lens, not this one's — this domain
stops at whether *application* code is well-typed and well-structured, not
at whether the tests that exercise it are well-built.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [Type-Checking Rigor as a Graduated Discipline (mypy)](#type-checking-rigor-as-a-graduated-discipline-mypy)
- [pyright: Four Modes, Not a Binary](#pyright-four-modes-not-a-binary)
- [Type-Coverage Tooling: Ratchet, Not Gate](#type-coverage-tooling-ratchet-not-gate)
- [`py.typed` and PEP 561](#pytyped-and-pep-561)
- [Ruff `flake8-annotations` (ANN)](#ruff-flake8-annotations-ann)
- [Ruff `flake8-type-checking` (TC)](#ruff-flake8-type-checking-tc)
- [Ruff `flake8-pyi` (PYI)](#ruff-flake8-pyi-pyi)
- [Modern Typing Syntax](#modern-typing-syntax)
- [Cyclomatic Complexity and Function Size](#cyclomatic-complexity-and-function-size)
- [Import Organization: isort vs. Ruff's `I`](#import-organization-isort-vs-ruffs-i)
- [Docstring Conventions: pydocstyle / Ruff `D`](#docstring-conventions-pydocstyle--ruff-d)
- [Dead Code Detection](#dead-code-detection)
- [Naming, Exceptions, and Other Baseline Hygiene](#naming-exceptions-and-other-baseline-hygiene)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Sources](#sources)

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Type hints present on public functions | Yes | Yes | Yes |
| Bare `except:` / silently-swallowed `except Exception` | Yes | Yes | Yes |
| Naming conventions, no wildcard imports, no implicit relative imports | Yes | Yes | Yes |
| Modern typing syntax (PEP 585/604) where the Python floor supports it | Yes | Yes | Yes |
| Dead code: unreachable code, leftover `print()`/`breakpoint()`, commented-out blocks | Yes | Yes | Yes |
| Ruff `F` (pyflakes: unused imports/variables) enabled | Yes | Yes | Yes |
| Docstring convention picked and stated, even informally | Yes | Yes | Yes |
| Ruff `ANN` (annotation presence) enabled in lint config | No | Yes | Yes |
| Ruff `TC` (`TYPE_CHECKING` gating correctness) enabled | No | Yes | Yes |
| Ruff `PYI` enabled (general-purpose subset, not just stub projects) | No | Yes | Yes |
| mypy or pyright run in CI at all | No | Yes | Yes |
| `C901`/mccabe complexity explicitly opted into lint config | No | Yes | Yes |
| Ruff `D`/pydocstyle convention enforced mechanically, not just by convention | No | Yes | Yes |
| Per-module strict-mode ramp (`disallow_untyped_defs`, etc.) tracked deliberately | No | No | Yes |
| `no_implicit_reexport` / public-API-surface typing discipline | No | No | Yes |
| Type coverage tracked (`--any-exprs-report`, `--verifytypes`) in CI as a ratchet | No | No | Yes |
| `py.typed` type-correctness verified, not just present | N/A unless published | Yes if published | Yes |
| `vulture` dead-code sweep | No | No | Yes |

**Cross-cutting exception, not a tier:** the moment a project publishes a
package — regardless of which tier it otherwise sits at — `py.typed`
correctness and `no_implicit_reexport`-style public-API-surface discipline
become relevant immediately. A script-tier project that ships one small
utility to PyPI still owes its consumers an honestly typed public
interface; don't wait for "enterprise" to ask the question.

Cheap, universal hygiene (hints present, no bare `except`, sane naming)
stays required everywhere. Anything that requires dedicated CI
infrastructure or a deliberate strictness-ramp decision is gated to
web/enterprise or enterprise-only — the same shape `testing.md` uses for
its own tier table.

## Type-Checking Rigor as a Graduated Discipline (mypy)

Treat static typing as a ramp, not a binary "hints present / hints absent"
check. mypy's own `--strict` flag is documented as shorthand for **13
individual flags**, none of which is on by default:
`--disallow-any-generics`, `--disallow-subclassing-any`,
`--disallow-untyped-calls`, `--disallow-untyped-defs`,
`--disallow-incomplete-defs`, `--check-untyped-defs`,
`--disallow-untyped-decorators`, `--warn-redundant-casts`,
`--warn-unused-ignores`, `--warn-return-any`, `--no-implicit-reexport`,
`--strict-equality`, `--extra-checks`.

Two of these are worth naming individually because they're the concrete,
reviewable form of vaguer complaints:

- **`--disallow-untyped-defs`** reports an error on any function definition
  without type annotations *or with incomplete type annotations* — it flags
  both `def f(a, b)` and `def f(a: int, b)`. A codebase with type hints on
  "most" functions but no config enforcing this flag is not actually
  ratcheted; it's one refactor away from regressing silently.
- **`--no-implicit-reexport`** changes the default behavior where an
  imported name is automatically visible to importers of the module that
  imported it. With the flag set, a name must be re-exported explicitly
  (`from x import Y as Y`, or listed in `__all__`) to be visible outside
  the module — the concrete, reviewable form of "does this module leak its
  internals as part of its public type surface."

mypy's own adoption guidance explicitly rejects all-or-nothing rollout:
"many configuration options can be enabled or disabled only for specific
modules," and it recommends enabling `disallow_untyped_defs` "for modules
which you've completed annotations for, in order to prevent new code from
being added without annotations" — a per-module strictness ramp, not a
repo-wide switch. `check_untyped_defs` is singled out as the easy first
step ("strongly recommend enabling this one as soon as you can"). The docs
offer two valid adoption directions: build up toward `--strict`
incrementally module by module, or start at `--strict` globally and
subtract the flags that aren't yet practical.

**Review angle:** a codebase with type hints present but no mypy config at
all, or a flat non-strict config applied uniformly repo-wide, is missing
the actual maturity signal. The config file — which flags are set, whether
overrides are scoped per module — is more informative than hint presence
alone. Ask to see it before scoring this section.

## pyright: Four Modes, Not a Binary

pyright supports four type-checking modes — **off, basic, standard,
strict** — set via `typeCheckingMode` in `pyrightconfig.json` or
`[tool.pyright]` in `pyproject.toml`. The default mode is **standard**, not
basic and not strict — pyright's own docs state plainly that "the default
value for this setting is 'standard'."

The basic-to-strict jump is a genuine ramp of granularity, the same shape
as mypy's per-flag composition, not an off/on switch:

- Strict mode enables `strictListInference`, `strictDictionaryInference`,
  and `strictSetInference` (all off in basic) — e.g. `[1, 'a', 3.4]` infers
  as `list[int | str | float]` under strict, `list[Any]` under basic.
- Strict escalates several diagnostics from warning/none to error,
  including `reportMissingTypeStubs`, `reportAssertAlwaysTrue`,
  `reportInvalidStringEscapeSequence`, and `reportSelfClsParameterName`.
- Some diagnostics — `reportArgumentType`, `reportAssignmentType`,
  `reportReturnType` — are already `error` in *both* basic and standard, so
  the ramp isn't uniform; some checks are load-bearing from the floor up.

**Review angle:** a project using pyright with no explicit
`typeCheckingMode` is silently on standard, not basic. That's usually fine,
but it's worth confirming it's the intended floor rather than an
unexamined default — especially on a codebase that assumes it's running
looser checks than it actually is.

## Type-Coverage Tooling: Ratchet, Not Gate

Two checker-native mechanisms — not third-party add-ons — measure *how
much* of a codebase is actually typed, as distinct from lint-level
presence/absence checks:

- **mypy's report flags.** `--linecount-report` documents the functions
  and lines that are typed and untyped within the codebase.
  `--any-exprs-report` counts `Any` expressions — a proxy for how much of
  the "typed" code is actually meaningfully typed versus typed-as-`Any`.
  `--html-report`/`--txt-report` render these as browsable reports (both
  require `lxml` or the `mypy[reports]` extra).
- **pyright's `--verifytypes <package>`.** Produces a "type completeness
  score": the percentage of symbols with known types. It's explicitly
  framed for a *published library's* public interface — pyright's docs
  call a `py.typed` library "type complete" when all symbols comprising
  its interface have annotations that refer to fully known types.
  Supports `--outputjson` for tooling consumption and `--ignoreexternal`
  to exclude incompleteness inherited from third-party dependencies, and
  is documented as CI-integrable specifically to prevent regression of a
  library's type completeness over time.

For an internal application, mypy's `--any-exprs-report` /
`--linecount-report` is the more relevant signal; for a published library,
`pyright --verifytypes` is the tool built for exactly that use case.

**No source — from mypy, pyright, or elsewhere — states a recommended
numeric target for either measure.** That absence isn't a gap in this
research; it mirrors `testing.md`'s treatment of coverage percentage
directly: **the number is a ratchet, not a gate.** Set a CI check that
fails if type completeness (or the `Any`-expression count) *regresses*
from its current value, exactly the way `coverage.py`'s `fail_under` is
meant to be used — as a floor against silent backsliding, never as a target
to chase. A team that reports "we're at 74% type completeness, aiming for
90%" has invented a target neither tool's own documentation supports;
"we're at 74% and it hasn't dropped since Q2" is the defensible framing.

**Review angle:** treat a rising type-coverage percentage with no other
justification exactly as `testing.md` treats a rising test-coverage
percentage — not evidence of anything on its own. A regression in the
number, unexplained, is the real signal worth investigating.

## `py.typed` and PEP 561

Per PEP 561's own text, a package "MUST add a marker file named
`py.typed`" to declare itself as supporting type checking for its
consumers. For namespace packages, the marker belongs "in the submodules
of the namespace, to avoid conflicts and for clarity." The declaration is
recursive: "if a top-level package includes it, all its sub-packages MUST
support type checking as well" — a package can't declare itself typed and
then ship an untyped subpackage underneath it. Stub-only packages (the
`packagename-stubs` naming convention) are explicitly exempted from
needing the marker, since the `-stubs` suffix itself signals typed status.

**Scope boundary.** This domain owns whether the package's types are
*actually correct and complete* — mypy/pyright clean, a healthy
`--verifytypes` score. Whether the `py.typed` file is *present and
correctly packaged for distribution* — included in `package_data`/wheel
contents so it survives install — is a packaging-declaration concern
belonging to [Standards Compliance](../references/standards-compliance.md).
Flag it if review guidance conflates the two: a package can have a
perfectly correct, `--verifytypes`-clean type surface and still ship a
broken `py.typed` declaration because the file didn't make it into the
wheel, and the reverse (present marker, dishonest types) is equally real.

## Ruff `flake8-annotations` (ANN)

Enforces annotation *presence*, complementing mypy/pyright's annotation
*correctness*:

| Rule | Checks |
|---|---|
| ANN001 | Missing type annotation for function argument |
| ANN002 | Missing type annotation for `*args` |
| ANN003 | Missing type annotation for `**kwargs` |
| ANN201 | Missing return type annotation for public function |
| ANN202 | Missing return type annotation for private function |
| ANN204 | Missing return type annotation for special (dunder) method |
| ANN205 | Missing return type annotation for staticmethod |
| ANN206 | Missing return type annotation for classmethod |
| ANN401 | Disallowed use of `typing.Any` in a function signature |

`ANN101`/`ANN102` (missing annotation for `self`/`cls`) were **removed in
Ruff 0.8.0** — don't describe ANN as checking `self`/`cls` annotations;
current Ruff versions don't have that pair. ANN401 is the direct
lint-level counterpart to mypy's `--disallow-any-generics` /
`--warn-return-any` family: same underlying concern (typed-as-`Any` isn't
really typed), enforced pre-typecheck at effectively zero cost.

## Ruff `flake8-type-checking` (TC)

Targets imports that exist only for type annotations and shouldn't cost a
runtime import — circular-import avoidance, startup-time cost:

| Rule | Checks |
|---|---|
| TC001 | Move first-party import into a `TYPE_CHECKING` block |
| TC002 | Move third-party import into a `TYPE_CHECKING` block |
| TC003 | Move standard-library import into a `TYPE_CHECKING` block |
| TC004 | Move a *runtime-needed* import back out of a `TYPE_CHECKING` block (the inverse mistake) |
| TC005 | Empty `TYPE_CHECKING` block |
| TC006/TC007 | Quote type expressions in `typing.cast()` / type aliases where required |

TC004 and TC005 are enabled by default among Ruff's stable rules; most of
the category is autofixable. **Review angle:** weight TC004 higher than
the others — it's the one that actually causes a bug (an import needed at
runtime was incorrectly gated behind `TYPE_CHECKING` and will `NameError`
in production), not just an optimization. TC001–003 are import-time-cost
savings, real but lower-stakes than TC004's correctness failure.

## Ruff `flake8-pyi` (PYI)

66 rules (`PYI001`–`PYI066`), most stable, many autofixable. Some rules
are genuinely stub-only — `PYI009` ("empty body should contain `...`, not
`pass`"), `PYI021` ("docstrings should not be included in stubs") — both
meaningless outside a `.pyi` file. But PYI is **not** a stub-file-only
category as a whole: `PYI061` ("redundant `Literal[None]`"), for example,
applies to regular `.py` files as well as `.pyi` files — its "what it does"
and "why is this bad" rationale is unqualified by file type; only its
*autofix safety* differs (the fix is unsafe in `.py` files, safe in `.pyi`
files unless comments are present).

**Treat PYI as in-scope for every reviewed repo, not gated to
library/stub-publishing projects.** It's a mixed category: some rules are
stub-syntax-specific and others — type-alias hygiene, redundant or
overlapping type-literal patterns — are general-purpose type-correctness
checks that happen to live under the PYI name for historical
(`flake8-pyi`-derived) reasons. Revisit only the stub-specific subset
(`...`-body rules, `.pyi`-only docstring rules) as conditional on whether
the project actually ships `.pyi` stubs.

## Modern Typing Syntax

Independent of checker strictness, prefer current syntax over the
`typing`-module forms it replaced: `list[str]` over `List[str]` and
`dict[str, int]` over `Dict[str, int]` (PEP 585, available from Python
3.9+, unconditionally usable once the project's floor is 3.9+); `X | Y`
over `Union[X, Y]` and `X | None` over `Optional[X]` (PEP 604, Python
3.10+). A `None` return should be explicit — `-> None`, not an omitted
annotation that happens to type-check the same way, since the omission is
indistinguishable from "nobody annotated this yet" on a diff. Where a type
is complex enough to be reused across signatures, a `TypeAlias` annotation
or (3.12+) a `type` statement documents intent better than repeating the
same nested generic at every call site.

## Cyclomatic Complexity and Function Size

**The `< 10` threshold is real and traceable, not an arbitrary judgment
call.** `mccabe` — the reference implementation, and the same engine
Ruff's `C901` reimplements — states in its own README: "According to
McCabe, anything that goes beyond 10 is too complex." That's sufficient
backing on its own. A secondary, lower-confidence signal points the same
direction: Ruff's own settings docs list `10` as the default for
`lint.mccabe.max-complexity` — treat this as corroborating, not
independently load-bearing, since it comes from a single fetch rather than
convergent re-confirmation.

**Important caveat:** Ruff's `C90`/`C901` (mccabe) category is **not
enabled by default** — it's absent from the "enabled by default" marker
that rules like `E`/`F`/`B`/`UP`/`RUF` carry in Ruff's rule listing. A
project must explicitly `select = ["C90"]` (or list `C901`) to get
complexity checking at all. Complexity checking silently absent from a
Ruff config that doesn't opt in is a gap worth flagging on its own — it's
easy to assume Ruff's broad default rule set already covers this, and it
doesn't.

**"Functions ≤ 40 lines" has no credible source** — not in mccabe's own
docs, not in PEP 8, not in Ruff's or pylint's default configuration.
Function length in lines is a heuristic proxy for complexity, not an
independently defensible threshold in its own right: long functions often
*are* complex, but line count is not what any tool surveyed here actually
measures or defaults to. Don't state a numbered line-count rule. Keep it
as qualitative guidance instead — **a very long function warrants a closer
look**, specifically at whether its cyclomatic complexity is what's
actually driving the length — and let the McCabe-sourced complexity
threshold carry the real enforcement weight.

Two related structural heuristics carry forward from this domain's
original scope without independent re-verification this round, and are
offered as reasoned judgment calls rather than sourced thresholds: nesting
depth beyond 3 levels is worth a second look for an early-return or
extraction opportunity, and a class exposing more than 10 public methods
warrants a decomposition conversation. Treat both as prompts for
discussion, not hard gates, the same way function length is treated above.

## Import Organization: isort vs. Ruff's `I`

Both tools are current; neither has displaced the other outright. `isort`
itself remains actively maintained. Ruff's own FAQ states Ruff's import
sorting "is intended to be near-equivalent to isort's when using isort's
`profile = "black"`," and separately confirms Ruff "can also replace...
isort" — Ruff positions its `I` category as an explicit replacement, not
merely an isort-inspired lookalike. The same FAQ documents real,
non-cosmetic behavioral differences: aliased-import and inline-comment
handling differ; Ruff consolidates non-aliased imports from the same
module into one statement where isort splits at aliased boundaries; and
Ruff classifies a few modules (`_string`, `idlelib`) as standard-library
that isort's static list misses.

**Practical guidance.** A repo already using Ruff for linting gets import
sorting "for free" via the `I` category, with near-isort-compatible output
under the black profile — adding a separate isort dependency and
pre-commit hook is redundant in that case. A project with isort-specific
configuration (custom sections, isort-only plugins) migrating to Ruff's
`I` category should expect the documented edge-case diffs above, not
silent equivalence — check the diff on migration rather than assuming a
no-op.

Three grouped import blocks — standard library, third-party, local —
separated by blank lines and sorted alphabetically within each block, no
wildcard imports (`from module import *`), and no implicit relative
imports remain the baseline expectation regardless of which tool enforces
it.

## Docstring Conventions: pydocstyle / Ruff `D`

Ruff's `lint.pydocstyle.convention` setting accepts exactly three values,
confirmed directly against Ruff's configuration schema: **`"google"`**
("Use Google-style docstrings"), **`"numpy"`** ("Use NumPy-style
docstrings"), and **`"pep257"`** ("Use PEP257-style docstrings"). The
setting is `Option`-typed with no default — confirmed directly against
Ruff's own source (`pydocstyle/settings.rs`, an `Option<Convention>` field
deriving `Default`, i.e. `None` unless a project sets it explicitly). An
unset convention doesn't mean "no docstring rules run" — it means the `D`
rules selected in the lint config run without any convention-specific
carve-outs applied.

Mechanically, each convention doesn't work by enabling a curated allowlist
— it works by turning off the subset of `D` rules that don't apply to that
style. Verified against Ruff's own source: choosing `google` ignores rules
tied to blank-line-before-class formatting, section-underline length,
imperative-mood phrasing, and trailing-period requirements — rules that
encode PEP 257 or NumPy conventions Google style doesn't share. Choosing
`numpy` ignores a different subset — `UndocumentedPublicInit`,
multi-line-summary placement rules, signature-in-docstring, and
parameter-documentation rules that don't map onto NumPy's own section
format. Choosing `pep257` ignores the largest subset of the three, since
PEP 257 itself is the loosest of the named conventions and doesn't mandate
Google/NumPy-style structured sections at all.

The Python ecosystem's docstring conventions remain, as of this writing,
this same named set of three — Google and NumPy are the two competing
*structured* conventions in live use (NumPy dominant in the
scientific/data-stack ecosystem specifically, Google the more common
general-purpose default), both first-class options in pydocstyle and its
Ruff reimplementation. **Recommend Google or NumPy — pick one and enforce
it via `pydocstyle.convention`** rather than presenting Google as the only
legitimate option; `pep257` is a reasonable floor for a codebase that
hasn't committed to structured sections at all, not a long-term
destination.

Independent of which convention is enforced mechanically: docstrings
should describe behavior and parameters, not restate implementation a
reader can already see in the function body; redundant comments that just
narrate the next line add noise, not information; and a `TODO`/`FIXME`
comment without a linked ticket or issue URL is an untracked promise that
tends to outlive everyone's memory of why it's there. Docstrings on
private helper functions are a nice-to-have, not a requirement — the
public surface is where documentation earns its cost.

## Dead Code Detection

**Ruff's `F` category (pyflakes)** is the conservative, high-confidence
baseline: unused imports (`F401`) and unused variables (`F841`) are
unused-name-level checks with low false-positive risk, and are part of
Ruff's default-enabled rule set — this should be on in every project,
script tier included.

**`vulture`** is the broader, lower-confidence sweep that catches what
pyflakes-style checks structurally can't: a fully unused function or class
is not a pyflakes violation the way an unused import or local variable is.
vulture finds unused imports (90% confidence, its own documented figure),
unused variables (60%), unused functions/methods/classes (60%),
unreachable code (100%), and unused function arguments (100%). Those
confidence scores are the tool's own honest acknowledgment that dead-code
detection at this level is heuristic: vulture's docs state plainly that
"due to Python's dynamic nature, static code analyzers like Vulture are
likely to miss some dead code," and code invoked only implicitly —
reflection, string-based dispatch, framework callback registration — can
be false-positive-flagged as unused.

**Recommend both, at different tiers.** Ruff's `F` rules as an always-on
baseline everywhere; `vulture` as an opt-in, whitelist-tuned deeper sweep
at web/enterprise tier, where the false-positive tuning cost is worth
paying.

Beyond what either tool flags mechanically, a review should still catch:
commented-out code blocks left behind rather than deleted (version control
already has the history — dead code in a diff isn't a safety net), code
unreachable after a `return`/`raise`/`break`/`continue`, and leftover
`print()` or `breakpoint()` debug statements that shouldn't ship.

## Naming, Exceptions, and Other Baseline Hygiene

These carry forward from this domain's original scope as established,
low-controversy Python convention rather than newly sourced material this
round:

- **Bare `except:`** swallows everything, including `SystemExit` and
  `KeyboardInterrupt` — this is a **Critical** finding at every tier, not
  a style nitpick. `except Exception` that silently passes without
  logging or re-raising is the same failure mode with a narrower net.
- **Naming:** functions and variables in `snake_case`, classes in
  `PascalCase`, constants in `UPPER_SNAKE_CASE`, private members prefixed
  `_single_leading_underscore`. No single-letter variables except loop
  counters (`i`, `j`, `k`) and well-established conventions (`x`, `y` for
  coordinates, `n` for a count).
- **`__all__`** in `__init__.py` to control what a package's public API
  actually exposes — the runtime-visible counterpart to
  `--no-implicit-reexport`'s static-typing enforcement of the same idea.
- **String quoting** should be consistent within a project (single or
  double, not mixed arbitrarily) — Ruff's formatter or Black settle this
  mechanically once configured; the finding is a project with no
  consistent choice at all.

## Out of Scope

- **`py.typed` file inclusion in package distribution** (wheel/sdist
  contents, `package_data` config) — a packaging-*declaration* concern
  owned by [Standards Compliance](../references/standards-compliance.md).
  This domain owns only whether the types themselves are correct and
  complete.
- **Framework-specific typing patterns** — Django model typing via
  `django-stubs`, Pydantic's own validation-vs-typing overlap. Real, but
  stack-specific; not asserted at this domain level.
- **Runtime type checking / validation libraries** — Pydantic, `attrs`
  validators, `typeguard`'s runtime-enforcement mode. These enforce types
  at runtime against real data, which is a correctness/robustness concern
  closer to an architecture or error-handling lens than to static "is this
  code well-typed" review. Static type-checking rigor (this domain) and
  runtime validation are complementary, not the same discipline.
- **Mocking correctness, fixture design, and test-suite tooling** — see
  [Testing](../references/testing.md). This domain reviews the code under
  test; it doesn't review the tests themselves.
- **Full pydocstyle / `D`-category rule enumeration** — the convention
  identity (Google/NumPy/PEP 257, what each turns off) is in scope; an
  exhaustive per-rule table of every `D1xx`/`D2xx`/`D4xx` code is not.
- **Complexity metrics beyond cyclomatic** — cognitive complexity,
  Halstead metrics, maintainability index. Cyclomatic complexity is the
  one with a traceable, tool-convergent threshold (McCabe's 10, confirmed
  by both `mccabe` and Ruff); the others aren't surveyed here and
  shouldn't be silently assumed equivalent or superior.

## Scoring Guide

- **10** — Type hints are complete on the public surface with a mypy or
  pyright config expressing deliberate strictness (not a flat default), and
  type coverage is tracked as a ratchet, not chased as a target.
  Cyclomatic complexity stays under 10 project-wide, with `C901` actually
  enabled to enforce it. Naming, import organization, and a stated
  docstring convention are consistent throughout. No bare `except`, no
  dead code beyond what `F` and (where used) `vulture` would themselves
  flag as acceptable heuristic noise.
- **8–9** — The above, with minor gaps: a handful of public functions
  missing annotations, one or two `C901` violations, a docstring
  convention followed by habit but not yet enforced mechanically.
- **6–7** — Type hints present but inconsistently enforced (no CI-gated
  checker, or a non-strict config applied uniformly with no per-module
  ramp); several complexity hotspots; import organization and naming
  mostly consistent but with real exceptions.
- **4–5** — Widespread missing types with no checker run in CI at all;
  high-complexity functions common; dead code present; docstring
  convention absent or inconsistent enough that no one could name it.
- **1–3** — No type hints; bare `except` clauses present; naming chaos;
  no documentation; complexity and function size make the code
  effectively unreviewable without a rewrite.

## Sources

- <https://mypy.readthedocs.io/en/stable/existing_code.html> —
  gradual/per-module strict-mode adoption guidance, `check_untyped_defs`
  as the recommended first step, "build up to --strict" vs. "start at
  --strict and subtract" — retrieved 2026-08-24
- <https://mypy.readthedocs.io/en/stable/command_line.html> — full 13-flag
  composition of `--strict`; `--disallow-untyped-defs` and
  `--no-implicit-reexport` exact behavior and default-off status —
  retrieved 2026-08-24
- <https://mypy.readthedocs.io/en/stable/command_line.html#report-generation>
  — `--html-report`/`--txt-report`/`--linecount-report`/`--any-exprs-report`
  as native type-coverage tooling — retrieved 2026-08-24
- <https://github.com/microsoft/pyright/blob/main/docs/configuration.md> —
  pyright's four type-checking modes (off/basic/standard/strict), default
  = standard, `typeCheckingMode` setting, basic-vs-strict diagnostic
  differences — retrieved 2026-08-24
- <https://github.com/microsoft/pyright/blob/main/docs/typed-libraries.md>
  — `--verifytypes` command, "type completeness score" definition,
  `py.typed` "type complete" definition, `--outputjson`/`--ignoreexternal`
  flags, CI integration statement — retrieved 2026-08-24
- <https://peps.python.org/pep-0561/> — `py.typed` marker mechanism (MUST
  requirement, exact filename/placement), namespace-package placement,
  recursive sub-package obligation, `*-stubs` exemption — retrieved
  2026-08-24
- <https://docs.astral.sh/ruff/rules/> — full rule listing; source for ANN
  rule codes (incl. ANN101/ANN102 removal in 0.8.0), TC rule codes and
  default-enabled subset (TC004/TC005), PYI rule count (66), and the
  "enabled by default" legend used to confirm C901/mccabe is opt-in —
  retrieved 2026-08-24
- <https://docs.astral.sh/ruff/rules/redundant-none-literal/> — PYI061
  rule body, confirming PYI is not stub-file-only (this rule's "what it
  does"/"why is this bad" text is unqualified, applying to `.py` files
  with only autofix-safety differing by file type) — retrieved 2026-08-24
- <https://docs.astral.sh/ruff/settings/> — `lint.mccabe.max-complexity`
  default value (10) — retrieved 2026-08-24
- <https://raw.githubusercontent.com/PyCQA/mccabe/master/README.rst> —
  "According to McCabe, anything that goes beyond 10 is too complex";
  complexity checking off by default in the reference tool — retrieved
  2026-08-24
- <https://docs.astral.sh/ruff/faq/> — Ruff import-sorting near-equivalence
  to isort under `profile = "black"`, documented behavioral differences
  (aliased imports, stdlib classification of `_string`/`idlelib`), explicit
  "Ruff can also replace... isort" statement — retrieved 2026-08-24
- <https://pypi.org/project/isort/> — isort current version and
  active-maintenance signal — retrieved 2026-08-24
- <https://pypi.org/project/vulture/> — vulture identity, current version
  (2.16, 2026-03-25), per-category confidence scores, documented
  false-positive limitation from Python's dynamic nature — retrieved
  2026-08-24
- <https://raw.githubusercontent.com/astral-sh/ruff/main/ruff.schema.json>
  — `Convention` enum's three valid values (`google`, `numpy`, `pep257`)
  and their exact descriptions, direct from Ruff's own configuration
  schema — retrieved 2026-08-24 (authoring-time fetch, closing the
  baseline's open question)
- <https://raw.githubusercontent.com/astral-sh/ruff/main/crates/ruff_linter/src/rules/pydocstyle/settings.rs>
  — `convention` field as `Option<Convention>` deriving `Default` (i.e.
  unset by default); per-convention `rules_to_be_ignored()` — the
  mechanism by which each convention turns off a named subset of `D`
  rules rather than enabling an allowlist — retrieved 2026-08-24
  (authoring-time fetch)
- `research/python-code-review/code-quality.md` (this repo) — the approved
  research baseline this reference was authored from, including source
  retrieval dates and the resolutions this document implements — read
  2026-08-24
- `research/python-code-review/original-tool/review-domains/code-quality.md`
  (this repo) — original domain scope (naming, bare-except, dead-code,
  import-block, and documentation baseline items carried forward largely
  as-is) — read 2026-08-24
- `skills/python-code-review/references/testing.md` (this repo) —
  tier-table pattern and "ratchet, not gate" framing this document mirrors
  for type-coverage tracking — read 2026-08-24
