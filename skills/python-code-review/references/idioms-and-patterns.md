# Idioms & Patterns

This is the idioms domain of the `python-code-review` skill's 11-domain
reference set. It evaluates whether code reads as *current, idiomatic
Python* — modern syntax over the legacy forms it replaced, standard-library
data structures used for what they're actually good at, and the small
structural patterns (comprehensions, context managers, unpacking, EAFP)
that separate Python written fluently from Python written as if it were a
different language with Python's syntax bolted on. None of this is a
blocking-severity concern on its own; it's the layer that determines
whether a codebase stays pleasant and cheap to read six months from now.

Two boundaries matter enough to state up front. First, bare `except:` and
silently-swallowed `except Exception:` are owned by
[Code Quality](../references/code-quality.md)'s Critical section, per this
skill's own domain split — this document's error-handling guidance below
covers exception *design* (EAFP vs. LBYL, custom exception hierarchies,
context-rich messages), not the swallowed-exception failure mode itself.
Second, PEP 585/604's *type-checker*-relevant treatment (how `list[str]`
and `X | Y` interact with mypy/pyright strictness) belongs to
[Code Quality](../references/code-quality.md)'s "Modern Typing Syntax"
section; this domain owns the same PEPs at the general syntax-currency
level — write current forms, enforced mechanically by Ruff's `UP` category
— without re-deriving the type-checker angle.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [The Modern Python Floor: 3.11+, 3.12+ for PEP 695](#the-modern-python-floor-311-312-for-pep-695)
- [Ruff's Idiom Rule Categories: UP, C4, SIM, PTH](#ruffs-idiom-rule-categories-up-c4-sim-pth)
- [File and Path Operations](#file-and-path-operations)
- [Data Handling: Comprehensions, Generators, and Structured Data](#data-handling-comprehensions-generators-and-structured-data)
- [Dataclasses vs. Pydantic: A Sourced Decision Rule](#dataclasses-vs-pydantic-a-sourced-decision-rule)
- [Immutability Defaults](#immutability-defaults)
- [Error Handling](#error-handling)
- [The Walrus Operator: PEP 572's Own Style Guidance](#the-walrus-operator-pep-572s-own-style-guidance)
- [String Operations and Other Durable Conventions](#string-operations-and-other-durable-conventions)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Sources](#sources)

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Current syntax (PEP 585/604 forms, f-strings, comprehensions over verbose loops, EAFP over LBYL) | Yes | Yes | Yes |
| `pathlib.Path` over `os.path` for path manipulation | Yes | Yes | Yes |
| Context managers for file handles, DB connections, locks | Yes | Yes | Yes |
| No mutable default arguments; functions return new objects rather than mutating arguments in place | Yes | Yes | Yes |
| `tuple`/`frozenset` over `list`/`set` for fixed, immutable data | Yes | Yes | Yes |
| Exception design: specific types, EAFP over LBYL, custom exceptions off a domain base (bare `except:` itself is [Code Quality](../references/code-quality.md)'s check) | Yes | Yes | Yes |
| `dataclasses`/`pydantic.BaseModel` chosen per the trust-boundary rule, not plain dicts | Yes | Yes | Yes |
| Ruff `UP` (pyupgrade) enabled — default-on the moment Ruff runs at all | Yes | Yes | Yes |
| Ruff `C4` (flake8-comprehensions) explicitly selected in lint config | No | Yes | Yes |
| Ruff `SIM` (flake8-simplify) explicitly selected in lint config | No | Yes | Yes |
| Ruff `PTH` (flake8-use-pathlib) explicitly selected in lint config | No | Yes | Yes |
| PEP 695 `type` statement / `UP040` — gated to projects whose declared `requires-python` floor is 3.12+, independent of tier | Conditional on floor | Conditional on floor | Conditional on floor |

Reading and writing idiomatic syntax costs nothing beyond habit, so the
principle-level rows stay required at every tier, script included — a
one-file throwaway script still shouldn't reach for `os.path.join` or a
manually-tracked loop index. What's gated to web/enterprise is
specifically the *mechanical enforcement layer*: `C4`, `SIM`, and `PTH` are
real Ruff categories that require an explicit `select` to turn on (see
below), and a script-tier project without a lint config at all has nothing
to opt in. The PEP 695 row is gated differently from the rest of this
table — not by tier, but by the project's own declared Python floor — for
reasons covered in the next section.

## The Modern Python Floor: 3.11+, 3.12+ for PEP 695

The realistic "modern Python" floor for new guidance is **3.11+, not
3.10+**. Per the [Python Developer's Guide's version status
table](https://devguide.python.org/versions/), Python 3.10 exits its
security-only support window in **October 2026**, while 3.11 remains security-only-supported
until October 2027 and 3.12 until October 2028, with 3.13 and 3.14 still
actively maintained. Framing guidance as "3.10+" was reasonable when 3.10
had years of runway left; recommending it as a floor today means
recommending the version about to leave security support entirely.
Anchor idiom guidance to **3.11 as the realistic floor**, and treat **3.12
as its own, higher bar** for the one idiom that specifically requires it:

**PEP 695's `type` statement (3.12+).** Ruff's rule **`UP040`**
(`non-pep695-type-alias`, stable since v0.0.283) flags legacy
`TypeAlias`-annotated assignments and `TypeAliasType` calls and rewrites
them to the PEP 695 form — `type UserId = int` instead of
`UserId: TypeAlias = int`. The rule is **gated to Ruff's own
`target-version` setting at 3.12+**: on a project configured (or
defaulted) below 3.12, `UP040` does nothing, silently, even with `UP`
otherwise enabled. Don't flag `TypeAlias`-style code as an idiom violation
on a project whose declared floor is below 3.12 — there's nothing to
migrate to yet. **Gate this specific check by the project's own declared
minimum Python** (`requires-python` in `pyproject.toml`, or the
equivalent `python_requires` in `setup.cfg`), not by review tier: read the
declared floor, and only surface the PEP 695 recommendation when it's
3.12 or higher. This is deliberately different from every other tier gate
in this document — a script-tier project targeting 3.12+ should still get
the suggestion, and an enterprise-tier project pinned to 3.11 by a
dependency shouldn't be nagged about a syntax it structurally can't use
yet.

## Ruff's Idiom Rule Categories: UP, C4, SIM, PTH

Ruff (verified directly against [its rule
reference](https://docs.astral.sh/ruff/rules/)) supplies exactly this
domain's mechanical enforcement layer through four rule categories. Ruff's
own docs state: "By default, Ruff enables rules from the `F`, `E`, `B`,
`UP`, and `RUF` categories, as well as many more" — confirmed on two
independent hosts (the docs site and raw GitHub source, since docs-site
anchors can resolve to one cached page). That sentence is the load-bearing
distinction for this table: **`UP` (pyupgrade) ships enabled out of the
box**, while **`C4`, `SIM`, and `PTH` are absent from that named list**
and require an explicit `select` to turn on. (The off-by-default status of
`C4`/`SIM`/`PTH` is inferred from their absence from Ruff's own
enabled-by-default list, not a separately-quoted "these are opt-in"
statement — flagged as inferred rather than directly sourced.) The
practical consequence for review: recommending these three categories
isn't "verify they're already running," it's "tell the project to opt
in."

| Category | Default-on | Verified rule examples | Idiom it enforces |
|---|---|---|---|
| `UP` pyupgrade | Yes | `UP040` `non-pep695-type-alias` (3.12+ `type` statement, see above); PEP 604/585 union and generic modernization rules | Current syntax over legacy `typing`-module forms |
| `C4` flake8-comprehensions | No | 19 stable, mostly auto-fixable rules — `C416` `unnecessary-comprehension` (rewrite as `list()`/`dict()`), `C401`/`C402` unnecessary generator→set/dict, `C420` use `dict.fromkeys` | Comprehensions used correctly, not as verbose no-ops |
| `SIM` flake8-simplify | No | `SIM105` `suppressible-exception` (prefer `contextlib.suppress(...)` over try/except/pass), `SIM115` `open-file-with-context-handler`, `SIM117` merge nested `with` statements, `SIM118` `in-dict-keys` (drop redundant `.keys()`), `SIM108` collapsible if→ternary, `SIM110` `reimplemented-builtin` (a for-loop reimplementing `any`/`all`) | Context managers, ternaries, `any()`/`all()` over manual flag patterns |
| `PTH` flake8-use-pathlib | No | 20+ stable, mostly fixable 1:1 mappings — `PTH123` `open()`→`Path.open()`, `PTH118` `os.path.join()`→`Path` + `/`, `PTH110` `os.path.exists()`→`Path.exists()` | `pathlib.Path` over `os.path` |

**Review angle:** a Ruff config that only inherits the defaults is quietly
missing three of this domain's four enforcement categories. Ask to see
the `select`/`extend-select` list before crediting a project with
"idiomatic, lint-enforced" status on comprehensions, simplification
patterns, or pathlib usage — `UP` alone doesn't cover any of those three.

## File and Path Operations

**`pathlib.Path` over `os.path`, unconditionally.** The preference is now
backed by a concrete rule set (`PTH`, above) rather than convention alone
— 20+ Ruff rules exist purely to migrate `os.path`/`os.*` calls to `Path`
equivalents, which is ecosystem-level evidence this is a settled idiom,
not a style opinion. **No documented carve-out was found** for preferring
`os.path` in any circumstance — no official source describing a
performance-sensitive hot loop or interop constraint where `os.path`
should be kept. Treat `pathlib.Path` as the unconditional default: convert
with `str(path)` or `os.fspath(path)` specifically at interop boundaries
— a C extension or third-party API that only accepts `str` — rather than
reaching for `os.path` more broadly because one call site needs a string.

**Context managers** (`with` statement) remain the correct tool for file
handles, database connections, and locks — anything with an acquire/release
lifecycle. `SIM115` (`open-file-with-context-handler`) and `SIM117`
(collapse nested `with` statements into one) are the mechanical
enforcement layer for this, already covered in the table above.

**`smart-open`: narrower than the original guidance implied.** A prior
draft of this guidance grouped `smart-open` and `pathlib` together as
"either one, over raw `open()`, for complex file handling" — that
conflates two tools with different jobs. Verified via
[PyPI](https://pypi.org/project/smart-open/) (current version 8.0.1,
released 2026-07-15, three active maintainers), `smart-open`'s actual
purpose is **streaming large files to and from remote/cloud backends** —
S3, GCS, Azure Blob Storage, HDFS, SFTP, HTTP(S) — with a local-filesystem
fallback, not a general replacement for local `open()`/`pathlib` usage.
The corrected guidance: `pathlib.Path.open()` (as a context manager) for
local files, full stop; reach for `smart-open` specifically when code
needs backend-agnostic streaming to or from cloud object storage, not as
a generic upgrade over `open()` for merely "complex" local file handling.

**Review angle:** `os.path` and `pathlib` mixed within the same codebase
with no stated reason is a stronger finding than either one used
consistently — it usually means a partial, abandoned migration rather
than a deliberate choice, and each mixed call site is a `PTH` violation
waiting to be enabled.

## Data Handling: Comprehensions, Generators, and Structured Data

These remain current, durable idioms — carried forward without
independent re-verification this round beyond confirming their mechanical
enforcement exists (`C4`/`SIM`, above), since no displacement was expected
or found:

- **Comprehensions over verbose for-loops** for transformations, with no
  side effects inside the comprehension itself — a comprehension that
  calls a mutating function per element for its side effect rather than
  its return value defeats the point and should be a plain loop instead.
- **Generator expressions** for large sequences that don't need full
  materialization — the same transformation as a comprehension, without
  paying the memory cost of building the whole collection up front.
- **`zip()`, `enumerate()`, `any()`, `all()`** over manual index tracking
  or hand-rolled boolean-flag loops — `SIM110`
  (`reimplemented-builtin`) is the mechanical check for the `any`/`all`
  case specifically.
- **Unpacking** (`a, b = pair`) over positional indexing
  (`pair[0]`, `pair[1]`) wherever the shape is fixed and known.
- **Named tuples or dataclasses over positional tuples** for return values
  with more than two elements, so a caller doesn't need to remember which
  index means what.

## Dataclasses vs. Pydantic: A Sourced Decision Rule

Recommending "`dataclasses` or `pydantic.BaseModel` over plain dicts,"
without distinguishing the two, understates a real functional difference.
Verified directly against both tools' own documentation:

- **`dataclasses`** is documented, in the stdlib docs, purely as
  boilerplate reduction — auto-generating `__init__`, `__repr__`, and
  `__eq__` from declared fields. **No validation behavior is documented or
  implied anywhere in the module's own docs.** A dataclass performs no
  runtime type or value checking at construction; `Point(x="not a
  number")` succeeds silently if nothing downstream happens to check.
- **Pydantic's own docs** state directly: "Untrusted data can be passed to
  a model and, after parsing and validation, Pydantic guarantees that the
  fields of the resultant model instance will conform to the field types
  defined on the model." Validation at construction is the actual
  point of the library, not an incidental feature. Pydantic also ships
  `pydantic.dataclasses.dataclass` — a decorator-compatible middle ground
  that keeps `@dataclass` ergonomics while adding Pydantic's validation.

**Sourced decision rule:** use `pydantic.BaseModel` (or
`pydantic.dataclasses.dataclass` where `@dataclass`-shaped ergonomics
matter) when the data originates **outside the process's own control** —
API request bodies, config files, external JSON/YAML, user input —
because validating at that boundary is the actual job to be done. Use
plain stdlib `dataclasses` for **internal, already-typed data** passed
between functions and modules within one trust boundary, where
re-validating on every construction is pure overhead with nothing to
guard against. Plain dicts remain the anti-pattern being reviewed against
either way — neither tool's benefit (structure, or structure plus
validation) is available to a caller passing around bare `dict[str,
Any]`.

**Review angle:** a `BaseModel` used purely as an internal value object
between trusted internal functions, with no data ever crossing a process
or trust boundary through it, is over-engineered — the validation cost is
being paid for nothing. The inverse is the more common and more serious
finding: a plain `dataclass` (or a bare dict) sitting directly at an
API/config/user-input boundary with no validation step anywhere in the
path from external bytes to typed object.

## Immutability Defaults

These remain durable, low-controversy Python conventions, carried forward
without independent re-sourcing this round:

- Functions return new objects rather than mutating arguments in place —
  a caller shouldn't need to read a function's body to find out whether
  the list it passed in is still the same list afterward.
- `None` as the default value for a mutable parameter, with the real
  default constructed inside the function body — never a literal mutable
  default (`def f(items=[])`), since a mutable default is evaluated once,
  at function-definition time, and shared across every call that doesn't
  override it.
- `tuple` over `list` for fixed-size, immutable sequences.
- `frozenset` over `set` where the collection is meant to be hashable or
  is never mutated after construction.

## Error Handling

Exception *design*, as distinct from the swallowed-exception failure mode
that [Code Quality](../references/code-quality.md) owns as a Critical
finding at every tier:

- **Specific exception types.** Catch the narrowest exception the failure
  mode actually produces, not a broad `Exception` catch reused across
  unrelated failure paths. (Bare `except:` and silent `except Exception:`
  themselves are Code Quality's Critical-severity check, cross-referenced
  here rather than duplicated — see that document for the finding's own
  severity framing.)
- **Custom exceptions inherit from a domain-specific base**, not raw
  `Exception` directly — a project-level `AppError` (or similar) that
  domain exceptions subclass gives calling code one place to catch "any
  of our own errors" without also catching unrelated stdlib exceptions.
- **EAFP over LBYL** ("easier to ask forgiveness than permission" over
  "look before you leap") where duck typing is in play — attempt the
  operation inside a `try`/`except` rather than pre-checking with
  `hasattr`/`isinstance`, which both reads more idiomatically in Python
  and avoids a race between the check and the use (a file that exists at
  `os.path.exists()` time and is gone by `open()` time, a dict key
  present at `in` time and removed by `[]` time in concurrent code).
- **Context-rich error messages** that include the relevant variable
  state at the point of failure — `raise ValueError(f"expected a
  positive int, got {value!r}")`, not a bare `raise ValueError()` that
  forces the next reader to reconstruct what was being validated from
  surrounding code.

**Review angle:** a broad `except Exception` reused as the catch clause
across several unrelated failure paths in the same module is a strong
signal no one has actually enumerated what can fail at each call site —
it's the exception-design symptom that usually co-occurs with (though is
distinct from) the swallowed-exception finding Code Quality owns.

## The Walrus Operator: PEP 572's Own Style Guidance

The walrus operator (`:=`) has its own defining PEP, and PEP 572 doesn't
stop at introducing the syntax — it includes a **"Style guide
recommendations"** section stating a concrete preference, not a
neutral "use it where convenient" framing:

> If either assignment statements or assignment expressions can be used,
> prefer statements; they are a clear declaration of intent.

The PEP also directs restructuring to statement form whenever the walrus
form "would lead to ambiguity about execution order." Appendix A (Tim
Peters's findings, cited directly in the PEP) sharpens this into concrete
do/don't-use guidance:

- **Good use:** capturing a function's result directly in a loop or `if`
  header to avoid a redundant second call — `if result := solution(xs,
  n): ...` instead of calling `solution(xs, n)` once to test it and again
  to use it.
- **Avoid:** using the walrus on an already-long line, or where the
  assignment target is conceptually unrelated to the surrounding
  expression — either signals the walrus is being used for compactness at
  the expense of clarity, which is the opposite of the PEP's own
  rationale.
- **Avoid:** subtle chained forms like `while total != (total := total +
  term):`, which depend on strict left-to-right evaluation order to read
  correctly and are exactly the "ambiguity about execution order" case
  the style guide calls out.

This is a strictly more actionable standard than "use it where it
eliminates a redundant call, but don't force it" — when reviewing walrus
usage, check it against the PEP's own two rules (prefer a statement when
either form works; avoid it where order becomes ambiguous) rather than a
vaguer readability gut-check.

**Review angle:** a walrus expression that needs a second read to
determine what gets assigned and when — a chained comparison, a
multi-clause boolean expression with the walrus buried inside one branch
— fails the PEP's own bar even if it happens to be correct. Flag it as a
clarity regression, not a style nitpick, since the PEP's own authors
already made this exact trade-off explicit.

## String Operations and Other Durable Conventions

Carried forward as established, low-controversy convention — not
independently re-verified this round, since no displacement was expected
or plausible for any of these:

- **f-strings** for interpolation, over `.format()` or the `%` operator.
- **Raw strings** (`r"..."`) for regex patterns, so backslashes don't need
  double-escaping.
- **Triple-quoted strings** for genuinely multi-line text, not
  string-literal concatenation across lines.
- **ASCII-only source files** — non-ASCII identifiers and string literals
  outside what a project's declared encoding and tooling explicitly
  support are a portability risk, not a style preference.
- **Ternary expressions** for simple conditional assignments — `SIM108`
  is the mechanical check for an if/else block that's just a ternary in
  disguise.
- **`collections.defaultdict` / `collections.Counter`** where the access
  pattern matches what they're built for, over hand-rolled
  `dict.setdefault` chains or manual counting loops.
- **`functools.lru_cache`** for pure-function memoization.
- **`itertools`** for complex iteration patterns — chaining, grouping,
  windowing — over hand-rolled equivalents.
- **`match` statements, PEP 585 (`list[str]`), PEP 604 (`X | Y`)** remain
  current, standard idioms with no displacement found or expected. Their
  automated enforcement is the `UP` category's PEP 604/585 conversion
  rules (see the Ruff table above) — cited here as a category pointer
  rather than an enumerated rule-code list.
- **Avoiding deeply nested ternaries or comprehensions** — readability
  first. A comprehension or ternary that needs a second read to parse is
  worse than the verbose loop or if/else block it would have replaced;
  the preference for comprehensions and ternaries above is a default, not
  a mandate to compress every loop and branch into one expression.

## Out of Scope

- **Bare `except:` / silently-swallowed `except Exception:`** — owned by
  [Code Quality](../references/code-quality.md)'s Critical section per
  this skill's domain split; cross-referenced above, not duplicated.
- **Framework-specific Ruff categories** — Django (`DJ`), pandas-vet
  (`PD`), NumPy (`NPY`), and similar stack-specific rule sets are real and
  mature, but out of scope at this general-domain level per this skill's
  own domain-scoping decision. Deferred to a future stack-specific
  overlay rather than asserted here.
- **PEP 585/604's type-checker-strictness interaction** — whether these
  forms satisfy a given mypy/pyright strictness level is
  [Code Quality](../references/code-quality.md)'s "Modern Typing Syntax"
  lens; this document owns the syntax-currency idiom, not the
  type-checker angle.

## Scoring Guide

- **10** — Current syntax throughout (PEP 585/604 forms, f-strings,
  comprehensions used correctly), `pathlib.Path` used unconditionally for
  path work, `UP`/`C4`/`SIM`/`PTH` all explicitly enabled in lint config.
  Structured data uses the dataclass-vs-Pydantic boundary rule correctly.
  Walrus usage (where present) follows PEP 572's own statement-preferred,
  order-unambiguous guidance. Exception design uses specific types and a
  domain exception base; EAFP used consistently where duck typing applies.
- **8–9** — The above, with minor gaps: a handful of `os.path` holdovers,
  one or two rule categories not yet enabled, otherwise consistent idiom
  use.
- **6–7** — A real mix of modern and legacy patterns — some
  comprehensions, some verbose loops doing the same job; `os.path` and
  `pathlib` both present without a clear reason; no `C4`/`SIM`/`PTH`
  enabled even though `UP` is (the default-on category present, the
  opt-in ones absent).
- **4–5** — Predominantly non-idiomatic: verbose loops where a
  comprehension clearly fits, `os.path` throughout, plain dicts used
  where the dataclass-vs-Pydantic boundary rule calls for one or the
  other, broad `except Exception` reused across unrelated failure paths.
- **1–3** — No Pythonic patterns in evidence — Java/C-style code, mutable
  default arguments, bare `except:` clauses, positional-tuple returns
  with no names attached to any element.

## Sources

- <https://devguide.python.org/versions/> — Python version support table;
  confirms 3.10 exits security-only support October 2026, 3.11 October
  2027, 3.12 October 2028 — retrieved 2026-08-24
- <https://docs.astral.sh/ruff/rules/> — full Ruff rule listing; source
  for `UP040` (`non-pep695-type-alias`, stable since v0.0.283, gated to
  `target-version` 3.12+), the `C4` category (19 rules, `C400`–`C420`),
  the `SIM` category (including `SIM101`, `SIM105`, `SIM108`, `SIM110`,
  `SIM115`, `SIM117`, `SIM118`), and the `PTH` category (`PTH100`–`PTH124`,
  `PTH201`–`PTH203`) — retrieved 2026-08-24
- <https://raw.githubusercontent.com/astral-sh/ruff/main/README.md> — the
  default-rules statement ("By default, Ruff enables rules from the `F`,
  `E`, `B`, `UP`, and `RUF` categories, as well as many more"), confirmed
  on a second independent host to rule out single-source cache risk;
  confirms `UP` ships default-on, from which `C4`/`SIM`/`PTH` being
  off-by-default is inferred (not separately, explicitly stated) —
  retrieved 2026-08-24
- <https://peps.python.org/pep-0572/> — PEP 572 (walrus operator), the
  primary source for its own "Style guide recommendations" section
  (prefer statements when either form works; avoid where execution order
  becomes ambiguous) and Appendix A (Tim Peters's do/don't-use findings)
  — retrieved 2026-08-24
- <https://docs.python.org/3/library/dataclasses.html> — confirms
  `dataclasses` is documented purely as boilerplate reduction
  (`__init__`/`__repr__`/`__eq__` generation), with no validation behavior
  documented — retrieved 2026-08-24
- <https://pydantic.dev/docs/validation/latest/concepts/models/> (redirect
  target of `docs.pydantic.dev/latest/concepts/models/`) — the
  "untrusted data ... after parsing and validation, Pydantic guarantees
  fields ... conform to the field types" statement; confirms
  `pydantic.dataclasses.dataclass` exists as a dataclass/validation middle
  ground — retrieved 2026-08-24
- <https://pypi.org/project/smart-open/> — `smart-open`'s actual purpose
  (streaming to/from S3/GCS/Azure/HDFS/SFTP/HTTP, not general local file
  handling), current version 8.0.1 released 2026-07-15, three active
  maintainers — retrieved 2026-08-24
- `research/python-code-review/idioms-and-patterns.md` (this repo) — the
  approved research baseline this reference was authored from, including
  source retrieval dates and the resolutions this document implements —
  read 2026-08-24
- `research/python-code-review/original-tool/review-domains/idioms-and-patterns.md`
  (this repo) — original domain scope; every recommendation above either
  verifies, corrects (`smart-open`), or extends (dataclass/Pydantic,
  walrus, PEP 695, version floor) a specific line from this file — read
  2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) —
  framework-specific rule category rejection at the domain-scoping level,
  applied above to keep Django/pandas/NumPy Ruff categories out of scope
  — read 2026-08-24
- `skills/python-code-review/references/code-quality.md` (this repo) —
  tier-table pattern this document mirrors, and the Critical-severity
  bare-`except` finding cross-referenced rather than duplicated above —
  read 2026-08-24
