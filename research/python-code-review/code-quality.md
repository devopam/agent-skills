# Baseline: Code Quality
Status: user-approved      Date: 2026-08-24

## In scope

- **Static type-checking rigor as a graduated discipline (mypy)** — impact:
  high — depth: section. This is the scoping doc's headline required
  expansion (`research/python-code-review-domain-scoping.md`, "Confirmed
  gaps requiring expansion"): the original domain file's "type hints
  present" framing treats typing as binary, but mature tooling treats it as
  a ramp. mypy's own `--strict` flag (verified via
  `mypy.readthedocs.io/en/stable/command_line.html`) is documented as
  shorthand for **13 individual flags**: `--disallow-any-generics`,
  `--disallow-subclassing-any`, `--disallow-untyped-calls`,
  `--disallow-untyped-defs`, `--disallow-incomplete-defs`,
  `--check-untyped-defs`, `--disallow-untyped-decorators`,
  `--warn-redundant-casts`, `--warn-unused-ignores`, `--warn-return-any`,
  `--no-implicit-reexport`, `--strict-equality`, `--extra-checks` — none of
  which is on by default. `--disallow-untyped-defs` specifically "reports an
  error whenever it encounters a function definition without type
  annotations or with incomplete type annotations" (flags both `def f(a,
  b)` and `def f(a: int, b)`). `--no-implicit-reexport` changes the default
  behavior where imported names are automatically re-exported — with it
  set, a name must be re-exported explicitly (`from x import Y as Y`, or
  listed in `__all__`) to be visible to importers, which is the concrete,
  reviewable form of "does this module leak its internals as part of its
  public type surface." mypy's own adoption guidance
  (`mypy.readthedocs.io/en/stable/existing_code.html`) explicitly rejects
  all-or-nothing rollout: "many configuration options can be enabled or
  disabled only for specific modules," recommending e.g. enabling
  `disallow_untyped_defs` "for modules which you've completed annotations
  for, in order to prevent new code from being added without annotations" —
  a per-module strictness ramp, not a repo-wide switch. `check_untyped_defs`
  is singled out as the easy first step ("strongly recommend enabling this
  one as soon as you can"), and the doc offers two adoption directions:
  build up toward `--strict` incrementally, or start at `--strict` and
  subtract flags that aren't yet practical. Review angle: a codebase with
  type hints present but no mypy config at all, or a flat non-strict
  config repo-wide, is missing the actual maturity signal — the config
  file (per-module overrides, which flags are set) is more informative than
  hint presence alone.

- **pyright as an alternative checker** — impact: high — depth: section.
  Verified directly from pyright's own docs
  (`github.com/microsoft/pyright/blob/main/docs/configuration.md`): pyright
  supports four type-checking modes — **off, basic, standard, strict** —
  configured via `typeCheckingMode` in `pyrightconfig.json` or
  `[tool.pyright]` in `pyproject.toml`. The default mode is **standard**
  (not basic, and not strict) — the doc states plainly, "the default value
  for this setting is 'standard'." Basic vs. strict differences confirmed:
  strict mode enables `strictListInference`/`strictDictionaryInference`/
  `strictSetInference` (off in basic — e.g. `[1, 'a', 3.4]` infers as
  `list[int | str | float]` in strict vs. `list[Any]` in basic), and
  escalates several diagnostics from warning/none to error, including
  `reportMissingTypeStubs`, `reportAssertAlwaysTrue`,
  `reportInvalidStringEscapeSequence`, and `reportSelfClsParameterName`.
  Some diagnostics (`reportArgumentType`, `reportAssignmentType`,
  `reportReturnType`) are already `error` in both basic and standard,
  meaning the basic→strict jump is not "off vs. on" but a genuine ramp of
  granularity, same shape as mypy's per-flag composition. Review angle: a
  project using pyright with no explicit `typeCheckingMode` is silently on
  standard, not basic — worth confirming that's the intended floor rather
  than an unexamined default.

- **Type-coverage tooling** — impact: med — depth: paragraph. Two
  independently-sourced, checker-native mechanisms (not third-party add-ons)
  exist for measuring *how much* of a codebase is actually typed, as
  distinct from lint-level presence/absence checks: (1) mypy's own report
  flags (`mypy.readthedocs.io/en/stable/command_line.html#report-generation`)
  — `--linecount-report` documents "the functions and lines that are typed
  and untyped within your codebase," `--any-exprs-report` counts `Any`
  expressions (a proxy for how much of the "typed" code is actually
  meaningfully typed vs. typed-as-`Any`), and `--html-report`/`--txt-report`
  render these as browsable coverage reports (both require `lxml` or the
  `mypy[reports]` extra). (2) pyright's `--verifytypes <package>`
  (verified via `github.com/microsoft/pyright/blob/main/docs/typed-libraries.md`)
  produces "a 'type completeness score' which is the percentage of symbols
  with known types," is explicitly framed for verifying a **published
  library's** public interface (the doc calls a `py.typed` library "type
  complete" when "all of the symbols that comprise its interface have type
  annotations that refer to types that are fully known"), supports
  `--outputjson` for tooling consumption and `--ignoreexternal` to exclude
  incompleteness inherited from third-party dependencies, and is explicitly
  documented as CI-integrable to prevent regression of a library's type
  completeness over time. Review angle: for an internal application, mypy's
  `--any-exprs-report`/`--linecount-report` is the more relevant coverage
  signal; for a published library, `pyright --verifytypes` is the tool
  built for exactly that use case.

- **`py.typed` marker (PEP 561) — type-correctness half only** — impact:
  med — depth: paragraph. Verified against PEP 561's own text
  (`peps.python.org/pep-0561/`): a package "MUST add a marker file named
  `py.typed`" to declare itself as supporting type checking for consumers;
  for namespace packages the marker belongs "in the submodules of the
  namespace, to avoid conflicts and for clarity"; and the declaration is
  recursive — "if a top-level package includes it, all its sub-packages
  MUST support type checking as well." Stub-only packages (the
  `packagename-stubs` naming convention) are explicitly exempted from
  needing the marker, since the `-stubs` suffix itself signals typed
  status. **Scope boundary, per the scoping doc's explicit instruction**:
  this domain owns whether the package's types are *actually correct and
  complete* (mypy/pyright clean, `--verifytypes` score) — whether the
  `py.typed` file is *present and correctly packaged for distribution*
  (i.e., included in `package_data`/wheel contents so it survives install)
  is a packaging-declaration concern and belongs to Standards Compliance,
  not here. Flag violations of this boundary if review guidance conflates
  the two.

- **Ruff `flake8-annotations` (ANN)** — impact: med — depth: table.
  Verified against Ruff's rule listing (`docs.astral.sh/ruff/rules/`,
  retrieved 2026-08-24). Enforces annotation *presence*, complementing
  mypy/pyright's annotation *correctness*:

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

  Note: `ANN101`/`ANN102` (missing annotation for `self`/`cls`) were
  **removed in Ruff 0.8.0** — do not describe ANN as checking `self`/`cls`
  annotations; this matches the pattern already caught in `testing.md`'s
  Checkpoint A correction for `PT004`/`PT005`, so it's worth double-checking
  rule-set claims against the live docs rather than older cached
  knowledge. ANN401 in particular is the direct lint-level counterpart to
  mypy's `--disallow-any-generics`/`warn-return-any` family — same concern
  (typed-as-`Any` isn't really typed), enforced pre-typecheck.

- **Ruff `flake8-type-checking` (TC)** — impact: med — depth: table.
  Verified against Ruff's rule listing. Targets imports that exist only for
  type annotations and should not cost a runtime import (circular-import
  avoidance, startup-time cost):

  | Rule | Checks |
  |---|---|
  | TC001 | Move first-party import into a `TYPE_CHECKING` block |
  | TC002 | Move third-party import into a `TYPE_CHECKING` block |
  | TC003 | Move standard-library import into a `TYPE_CHECKING` block |
  | TC004 | Move a *runtime-needed* import back out of a `TYPE_CHECKING` block (the inverse mistake) |
  | TC005 | Empty `TYPE_CHECKING` block |
  | TC006/TC007 | Quote type expressions in `typing.cast()` / type aliases where required |

  TC004 and TC005 are enabled by default among the stable rules; most are
  autofixable. Review angle: TC004 is the one that actually causes bugs
  (an import needed at runtime was incorrectly gated behind
  `TYPE_CHECKING` and will `NameError` in production) — weight it higher
  than the TC001–003 "could be deferred for import-time savings" rules,
  which are optimizations rather than correctness issues.

- **Ruff `flake8-pyi` (PYI)** — impact: med — depth: paragraph.
  Verified against Ruff's rule listing (66 rules, PYI001–PYI066, most
  stable, many autofixable) plus a direct fetch of one representative rule
  page (`PYI061`, "redundant `Literal[None]`") to resolve scope. Some
  rules are genuinely stub-only (PYI009 "empty body should contain `...`,
  not `pass`", PYI021 "docstrings should not be included in stubs" — both
  meaningless outside a `.pyi` file), but PYI061's own "What it does"/"Why
  is this bad" text is **unqualified** — it applies to regular `.py` files
  as well as `.pyi` files, with only its *autofix safety* differing by
  file type (the fix is unsafe in `.py` files, safe in `.pyi` files unless
  comments are present). Corrected conclusion from an earlier draft of
  this research: PYI is **not** stub-file-only as a category — it's a
  mixed category where some rules are stub-syntax-specific and others
  (type-alias hygiene, redundant/overlapping type-literal patterns) are
  general-purpose type-correctness checks that happen to live under the
  PYI name for historical (flake8-pyi-derived) reasons. Treat PYI as
  in-scope for every reviewed repo, not gated to library/stub-publishing
  projects, and revisit only the subset that references stub-specific
  syntax (`...` bodies, `.pyi`-only docstring rules) as conditional on
  whether the project ships stubs.

- **Cyclomatic complexity threshold — verified, not just carried forward**
  — impact: high — depth: paragraph. The original domain file's "< 10"
  threshold is real and traceable, not an arbitrary judgment call: `mccabe`
  (the reference implementation, `PyCQA/mccabe`, the same engine Ruff's
  `C901` reimplements) states in its own README, "According to McCabe,
  anything that goes beyond 10 is too complex" — the plugin's own default
  `--max-complexity` is unset (complexity checking is opt-in), but 10 is
  the number the tool's authors attribute to McCabe himself. This alone is
  sufficient backing for the threshold. A secondary, lower-confidence
  signal points the same direction: a fetch of
  `docs.astral.sh/ruff/settings/` (retrieved 2026-08-24) returned "10" as
  `lint.mccabe.max-complexity`'s default, but an earlier fetch of the same
  general docs area truncated before reaching that value, and the
  dedicated `complex-structure/` rule page did not itself state a default
  — so treat "Ruff also defaults to 10" as single-fetch-sourced and
  secondary to the mccabe README citation, not as independently
  re-confirmed convergence. Important caveat, also verified: Ruff's
  `C90`/`C901` (mccabe) rule
  category is **not enabled by default** — it lacks the "enabled by
  default" marker in Ruff's rule listing legend, unlike `E`/`F`/`B`/`UP`/
  `RUF`, meaning a project must explicitly `select = ["C90"]` (or list
  `C901`) to get complexity checking at all. Review angle: complexity
  checking silently absent from a Ruff config that doesn't opt in is a gap
  worth flagging, since it's easy to assume Ruff's broad default rule set
  already covers this.

- **"Functions ≤ 40 lines" — flagged as an unsourced judgment call** —
  impact: low — depth: paragraph. No credible primary source was found for
  this specific number (not in mccabe's docs, not in PEP 8, not in Ruff's
  or pylint's default configuration) during this session's fetches. Unlike
  cyclomatic complexity (which traces to McCabe and is corroborated by two
  independent current tools converging on 10), function-length-in-lines
  appears to be a heuristic proxy for complexity rather than a
  independently defensible threshold — long functions often *are* complex,
  but line count is not what any reviewed tool actually measures or
  defaults to. Recommendation: keep this in the authored skill only as
  soft guidance ("very long functions warrant a closer look") rather than
  a numbered rule, or drop the specific "40" and let cyclomatic complexity
  carry the actual enforcement weight.

- **Import organization: isort vs. Ruff's own `I` category** — impact:
  med — depth: paragraph. Both are current, neither has displaced the
  other outright. `isort` itself (verified via PyPI, retrieved 2026-08-24)
  is actively maintained — current stable 8.0.1, with a 9.0.0b5 beta
  release dated 2026-08-16, i.e. days before this research. Ruff's own FAQ
  (`docs.astral.sh/ruff/faq/`, retrieved 2026-08-24) states Ruff's import
  sorting "is intended to be near-equivalent to isort's when using isort's
  `profile = "black"`," and separately confirms "Ruff can also
  replace... isort" — i.e. Ruff explicitly positions its `I` category as a
  replacement, not merely isort-inspired. The same FAQ documents known,
  real behavioral differences: aliased-import and inline-comment handling
  differ, Ruff consolidates non-aliased imports from the same module into
  one statement where isort splits at aliased boundaries, and Ruff
  classifies a few modules (`_string`, `idlelib`) as standard-library that
  isort's static list misses. Practical guidance: a repo already using
  Ruff for linting gets import sorting "for free" via the `I` category
  with near-isort-compatible output under the black profile — adding a
  separate isort dependency and pre-commit hook is redundant in that case,
  but a project with isort-specific config (custom sections, isort-only
  plugins) migrating to Ruff's `I` category should expect the documented
  edge-case diffs, not silent equivalence.

- **Docstring convention: Google-style still reasonable, but stated as a
  choice among a small named set, not the only option** — impact:
  low-med — depth: paragraph. Ruff's `pydocstyle` (`D`) category exposes
  `lint.pydocstyle.convention` accepting a named convention (this session
  confirmed the setting's existence in Ruff's settings reference but could
  not retrieve the full enumerated value list/default before the page
  content truncated in-fetch — see Open Questions). Carried forward as a
  durable, not-independently-re-verified-this-session fact per the pacing
  note: the Python ecosystem's docstring conventions are conventionally
  named **Google style**, **NumPy style**, and **PEP 257** — Google and
  NumPy are the two competing structured conventions in live use (NumPy
  style dominant in the scientific/data-stack ecosystem specifically;
  Google style the more common general-purpose default), both supported as
  first-class options by both `pydocstyle` (the original tool) and Ruff's
  reimplementation. No evidence found this session that a new convention
  has displaced this pair. Keep "Google-style docstrings" as the default
  recommendation but phrase it as "Google or NumPy, pick one and enforce it
  via `pydocstyle.convention`" rather than presenting Google as the only
  legitimate option.

- **Dead code detection: `vulture` as the named current tool** — impact:
  med — depth: paragraph. Verified via PyPI (retrieved 2026-08-24): current
  version 2.16, released 2026-03-25. `vulture` finds unused imports (90%
  confidence), unused variables (60%), unused functions/methods/classes
  (60%), unreachable code (100%), and unused function arguments (100%) —
  the confidence scores are the tool's own documented output, not this
  research's estimate, and are the honest acknowledgment that dead-code
  detection is heuristic: the tool's own docs state, "due to Python's
  dynamic nature, static code analyzers like Vulture are likely to miss
  some dead code," and code invoked only implicitly (reflection,
  string-based dispatch, framework callback registration) can be
  false-positive-flagged as unused. This complements rather than
  duplicates Ruff's own dead-code-adjacent rules (unused imports via `F401`,
  unused variables via `F841`, both in Ruff's default-enabled `F`/pyflakes
  category) — Ruff's checks are conservative/high-confidence
  (unused-name-level, low false-positive risk) while vulture's
  function/class/method-level "never called anywhere" analysis is the
  broader, lower-confidence sweep that catches what pyflakes-style checks
  structurally can't (a fully unused function is not a pyflakes violation
  the way an unused import or local variable is). Recommend both: Ruff's
  `F` rules as an always-on baseline, vulture as an opt-in deeper sweep
  (whitelist-tuned) for web/enterprise tier.

- **Tier applicability for the type-rigor expansion specifically** —
  impact: high — depth: table. The original domain file applies all
  checks to all tiers uniformly; the new graduated-strictness material
  doesn't fit that pattern (a strict mypy/pyright config and CI-gated
  type-coverage tracking is real infrastructure investment, not free):

  | Check | Script | Web | Enterprise |
  |---|---|---|---|
  | Type hints present on public functions (original scope, unchanged) | Yes | Yes | Yes |
  | Bare `except`, naming, no wildcard imports (original scope, unchanged) | Yes | Yes | Yes |
  | Ruff `ANN` (annotation presence) enabled in lint config | No | Yes | Yes |
  | Ruff `TC` (`TYPE_CHECKING` gating correctness) | No | Yes | Yes |
  | mypy/pyright run in CI at all | No | Yes | Yes |
  | Per-module strict-mode ramp (`disallow_untyped_defs` etc.) tracked deliberately | No | No | Yes |
  | `no_implicit_reexport` / public-API-surface typing discipline | No | No | Yes |
  | Type-coverage tracked (`--any-exprs-report`, `--verifytypes`) in CI, regression-gated | No | No | Yes |
  | `py.typed` type-correctness verified (not just present) | N/A unless publishing | Yes if published | Yes |
  | `C901`/mccabe complexity explicitly opted into config | No | Yes | Yes |
  | `vulture` dead-code sweep | No | No | Yes |

  Rationale mirrors `testing.md`'s tier-table precedent: cheap, universal
  hygiene (hints present, no bare except) stays required everywhere;
  anything requiring dedicated CI infrastructure or an explicit strictness
  ramp decision is gated to web/enterprise or enterprise-only. Library-
  publishing projects are the one cross-cutting exception: regardless of
  which tier a project otherwise sits at, the moment it publishes a
  package, `py.typed` correctness and `no_implicit_reexport`-style
  public-API-surface discipline become relevant immediately (a script-tier
  project that happens to publish a small utility package to PyPI still
  needs its public interface to be honestly typed) — flagged explicitly
  in prose here rather than folded into a tier-table cell, since it's a
  cross-cutting condition, not a tier.

## Explicitly out of scope

- **`py.typed` file inclusion in package distribution (wheel/sdist
  contents, `package_data` config)** — packaging-*declaration* concern per
  the scoping doc's explicit instruction; owned by Standards Compliance.
  This domain owns only whether the types themselves are correct/complete.
- **Framework-specific typing patterns** (Django model typing via
  `django-stubs`, Pydantic's own validation-vs-typing overlap) — real but
  stack-specific; consistent with the scoping doc's standing rejection of
  framework-specific overlays at the domain level.
- **Runtime type checking / validation libraries** (Pydantic, attrs
  validators, `typeguard`'s runtime-enforcement mode) — these enforce types
  at runtime against real data, a correctness/robustness concern closer to
  Architecture or Error Handling than to static "is the code well-typed"
  review; static type-checking rigor (this domain) and runtime validation
  are complementary but distinct disciplines.
- **Full pydocstyle/`D`-category rule enumeration** — the convention
  identity (Google/NumPy/PEP 257 as the named options) is in scope; an
  exhaustive per-rule table of every `D1xx`/`D2xx`/`D4xx` code was not
  pursued this session for budget reasons — see Open Questions.
- **Complexity metrics beyond cyclomatic** (cognitive complexity,
  Halstead metrics, maintainability index) — cyclomatic complexity is the
  one with a traceable, tool-convergent threshold (McCabe's 10, confirmed
  by both `mccabe` and Ruff); the others were not surveyed this session and
  should not be silently assumed equivalent or superior.

## Sources

- https://mypy.readthedocs.io/en/stable/existing_code.html — gradual/
  per-module strict-mode adoption guidance, `check_untyped_defs` as
  recommended first step, "build up to --strict" vs. "start at --strict
  and subtract" — retrieved 2026-08-24
- https://mypy.readthedocs.io/en/stable/command_line.html — full 13-flag
  composition of `--strict`; `--disallow-untyped-defs` and
  `--no-implicit-reexport` exact behavior and default-off status —
  retrieved 2026-08-24
- https://mypy.readthedocs.io/en/stable/command_line.html#report-generation
  — `--html-report`/`--txt-report`/`--linecount-report`/`--any-exprs-report`
  as native type-coverage tooling — retrieved 2026-08-24
- https://github.com/microsoft/pyright/blob/main/docs/configuration.md —
  pyright's four type-checking modes (off/basic/standard/strict), default
  = standard, `typeCheckingMode` setting, basic-vs-strict diagnostic
  differences — retrieved 2026-08-24
- https://github.com/microsoft/pyright/blob/main/docs/typed-libraries.md —
  `--verifytypes` command, "type completeness score" definition, `py.typed`
  "type complete" definition, `--outputjson`/`--ignoreexternal` flags, CI
  integration statement — retrieved 2026-08-24
- https://peps.python.org/pep-0561/ — `py.typed` marker mechanism (MUST
  requirement, exact filename/placement), namespace-package placement,
  recursive sub-package obligation, `*-stubs` exemption — retrieved
  2026-08-24
- https://docs.astral.sh/ruff/rules/ — full rule listing; source for ANN
  rule codes (incl. ANN101/ANN102 removal in 0.8.0), TC rule codes and
  default-enabled subset (TC004/TC005), PYI rule count (66), and the
  "enabled by default" legend used to confirm C901/mccabe is opt-in —
  retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/redundant-none-literal/ — PYI061 rule
  body, confirming PYI is not stub-file-only (this rule's "What it does"/
  "Why is this bad" text is unqualified, applying to `.py` files with only
  autofix-safety differing by file type) — retrieved 2026-08-24
- https://docs.astral.sh/ruff/settings/ — `lint.mccabe.max-complexity`
  default value (10) — retrieved 2026-08-24
- https://raw.githubusercontent.com/PyCQA/mccabe/master/README.rst —
  "According to McCabe, anything that goes beyond 10 is too complex";
  complexity checking off by default in the reference tool — retrieved
  2026-08-24
- https://docs.astral.sh/ruff/faq/ — Ruff import-sorting near-equivalence
  to isort under `profile = "black"`, documented behavioral differences
  (aliased imports, stdlib classification of `_string`/`idlelib`), explicit
  "Ruff can also replace... isort" statement — retrieved 2026-08-24
- https://pypi.org/project/isort/ — isort current version (8.0.1,
  released Feb 28, 2026, verbatim-confirmed on a second fetch) and
  active-maintenance signal (9.0.0b5 beta dated 2026-08-16) — retrieved
  2026-08-24 (fetched twice for verification)
- https://pypi.org/project/vulture/ — vulture identity, current version
  (2.16, 2026-03-25), per-category confidence scores, documented
  false-positive limitation from Python's dynamic nature — retrieved
  2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — the
  Code Quality gap statement driving this baseline's required expansion
  (mypy strict-mode adoption, pyright, type-coverage tooling, `py.typed`/
  PYI boundary with Standards Compliance, ANN/TC categories) — read
  2026-08-24
- `research/python-code-review/original-tool/review-domains/code-quality.md`
  (this repo) — starting-point scope (cyclomatic complexity < 10, function
  length ≤ 40 lines, Google-style docstrings, isort-compatible import
  sorting, bare-except Critical item) verified/expanded above rather than
  re-derived — read 2026-08-24
- `research/python-code-review/testing.md` (this repo) — tier-table
  pattern and sourcing/rigor bar this baseline follows — read 2026-08-24

## Open questions for the user

- **`pydocstyle.convention` full value list/default not retrieved.** The
  setting's existence was confirmed but the fetch truncated before the
  enumerated options and default value rendered. The Google/NumPy/PEP 257
  naming is carried forward as durable ecosystem knowledge, not
  re-verified against Ruff's settings page directly this session — a
  five-minute follow-up fetch would close this before authoring.
- **"Functions ≤ 40 lines" has no source.** Recommend either dropping the
  specific number in the authored skill (replacing with qualitative
  guidance) or, if the human reviewer has a source this research missed
  (a style guide, a specific team's convention this tool was originally
  built against), supplying it so the number can be kept with backing.
  Flagging rather than silently keeping or silently dropping.
- **Type-coverage tooling: is a numeric threshold worth stating?** Unlike
  test coverage (where `testing.md` already argues against a hard
  percentage gate), no source found this session states a recommended
  type-completeness percentage for either mypy's reports or pyright's
  `--verifytypes` score. Should the authored skill explicitly mirror
  `testing.md`'s "ratchet, not gate" framing for type coverage too (avoid
  silent regression, don't chase 100%), or leave it unstated until a
  source is found?

## Resolutions (Checkpoint B review, 2026-08-24)

- **`pydocstyle.convention` full value list**: deferred to a direct-fetch
  check at authoring time, per the standing verify-before-publish policy.
- **"Functions ≤ 40 lines"**: drop the specific number; keep as
  qualitative guidance ("very long functions warrant a closer look"), per
  the research's own recommendation — cyclomatic complexity carries the
  actual enforcement weight.
- **Type-coverage numeric threshold**: mirror `testing.md`'s "ratchet, not
  gate" framing for consistency across the two domains.

## Target file(s) + estimated length

- `skills/python-code-review/references/code-quality.md` — est. 230–260
  lines (the original 68-line file's naming/dead-code/bare-except
  material carried forward largely as-is, plus ~10 newly sourced
  sub-topics at section/table depth for the type-rigor expansion, one new
  tier-applicability table, plus scoring-guide and required-evidence
  sections mirroring the original tool's per-domain structure once
  authored — those two sections are not part of this baseline itself).
