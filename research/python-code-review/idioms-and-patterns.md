# Baseline: Idioms & Patterns
Status: user-approved      Date: 2026-08-24

## Resolutions (Checkpoint C review, 2026-08-24)

- **`os.path` carve-out**: accept "no carve-out found" — `pathlib`
  unconditionally preferred, convert with `str(path)`/`os.fspath()` at
  interop boundaries.
- **PEP 695 tier gating**: confirmed — gate by the project's own declared
  minimum Python (`requires-python`), not by review tier.
- **NamedTuple-vs-dataclass depth**: leave at original depth, not
  independently re-verified this pass.
- **UP035–047 exact rule codes**: don't include unverified codes in the
  authored doc; keep the `UP` category pointer general rather than
  citing specific numbers this session couldn't reliably confirm.

## In scope

- **Modern-Python floor should move from 3.10 to 3.11/3.12** — impact: high
  — depth: paragraph. Python's own devguide (fetched 2026-08-24) shows
  **3.10 exits its security-only support window in October 2026** — about
  two months from today — while 3.11 (security-only until October 2027),
  3.12 (security-only until October 2028), 3.13 and 3.14 remain actively
  maintained. The original tool's "Modern Python (3.10+)" framing was
  reasonable when 3.10 had years of life left; it's now recommending the
  version about to go fully unsupported as the floor. Recommend re-anchoring
  guidance to **3.11+ as the realistic floor, with 3.12+ called out
  specifically for PEP 695** (see next item) rather than bundling everything
  under one "3.10+" umbrella.

- **PEP 695 `type` statement (3.12+) — real, sourced, currently missing
  from the original** — impact: high — depth: paragraph. Verified directly
  against Ruff's rule reference (fetched 2026-08-24): rule **UP040**
  (`non-pep695-type-alias`, stable since v0.0.283) flags `TypeAlias`
  annotations and `TypeAliasType` assignments and suggests the PEP 695
  `type X = ...` statement instead — but it is **gated to `target-version`
  3.12+** in Ruff's config, meaning it silently does nothing on projects
  still targeting 3.10/3.11. This is the concrete idiom-layer counterpart
  to what Code Quality's sibling research already found on the typing side
  — add it here specifically as a "modern syntax" item, tier-gated to
  projects whose declared minimum Python is 3.12+.

- **Ruff's non-framework idiom rule categories — verified current content,
  and which ones are default-on** — impact: high — depth: table. The
  original tool describes idiom enforcement in prose without naming a
  specific tool; Ruff (fetched 2026-08-24, `docs.astral.sh/ruff/rules/`)
  supplies exactly this layer through four categories. **Important,
  previously-unverified nuance**: Ruff's own docs state "By default, Ruff
  enables rules from the `F`, `E`, `B`, `UP`, and `RUF` categories, as well
  as many more" — confirmed on two independent hosts (Ruff's docs site and
  raw GitHub source, since the docs-site fragment anchors all resolve to
  one cached page and don't independently corroborate each other). So
  **pyupgrade (UP) ships enabled out of the box**, while
  **flake8-comprehensions (C4), flake8-simplify (SIM), and
  flake8-use-pathlib (PTH) are absent from that named list** and, by
  inference (not a separately-quoted "these are opt-in" statement),
  require explicit `select`. This matters for the skill's advice:
  recommending these categories is not "verify they're on," it's "tell the
  user to opt in" — though the C4/SIM/PTH-off half of that claim is
  inferred, not directly quoted.

  | Category | Default-on | Verified rule examples (code — behavior) | Maps to original's bullet |
  |---|---|---|---|
  | `UP` pyupgrade | Yes | UP040 `non-pep695-type-alias` (3.12+ `type` stmt); PEP 604/585 union & generic modernization rules | "Modern Python (3.10+)" |
  | `C4` flake8-comprehensions | No | 19 stable, mostly auto-fixable rules, e.g. C416 `unnecessary-comprehension` (rewrite as `list()`/`dict()`), C401/C402 unnecessary generator→set/dict, C420 use `dict.fromkeys` | "Comprehensions over verbose for-loops" |
  | `SIM` flake8-simplify | No | SIM105 `suppressible-exception` (use `contextlib.suppress(...)` over try/except/pass), SIM115 `open-file-with-context-handler`, SIM117 merge nested `with`, SIM118 `in-dict-keys` (drop `.keys()`), SIM108 collapsible if→ternary, SIM110 `reimplemented-builtin` (for-loop reimplementing `any`/`all`/etc.) | "Context managers", "Ternary expressions", "any()/all() over manual flags" |
  | `PTH` flake8-use-pathlib | No | 20+ stable, mostly fixable 1:1 mappings, e.g. PTH123 `open()`→`Path.open()`, PTH118 `os.path.join()`→`Path`+`/`, PTH110 `os.path.exists()`→`Path.exists()` | "pathlib.Path over os.path" |

  Recommend the authored skill name these four categories explicitly and
  state the default-on/off split, rather than the original's unattributed
  prose description.

- **`pathlib.Path` over `os.path`** — impact: med — depth: paragraph. The
  original's preference stands and is now backed by a concrete rule set
  (`PTH`, above) rather than just convention — 20+ Ruff rules exist purely
  to migrate `os.path`/`os.*` calls to `Path` equivalents, evidence the
  ecosystem treats this as a settled idiom, not a style opinion. **No
  documented carve-out was found this session** (i.e., no official source
  saying "prefer os.path when X") — treat the "no nuance found" as a
  genuine gap in this research pass rather than asserting a nuance-free
  recommendation; see Open Questions.

- **`smart-open` correction** — impact: med — depth: paragraph. The
  original bullet ("`smart-open` or `pathlib` over raw `open()` for complex
  file handling") conflates two different tools. Verified via PyPI (fetched
  2026-08-24, current version 8.0.1, released 2026-07-15, three active
  maintainers): `smart-open`'s actual purpose is "streaming large files"
  to/from **remote/cloud backends** — S3, GCS, Azure Blob Storage, HDFS,
  SFTP, HTTP(S) — with a local-filesystem fallback, not a general
  replacement for local `open()`/`pathlib` usage. Recommend narrowing this
  guidance: `pathlib.Path.open()`/context managers for local files;
  `smart-open` specifically when code needs backend-agnostic streaming
  to/from cloud object storage, not as a generic "complex file handling"
  upgrade.

- **Walrus operator (`:=`) — PEP 572's own style guidance, more specific
  than "not forced"** — impact: med — depth: section. Verified directly
  against PEP 572 (peps.python.org, fetched 2026-08-24), the operator's own
  defining document, which includes a "Style guide recommendations"
  section stating explicitly: **"If either assignment statements or
  assignment expressions can be used, prefer statements; they are a clear
  declaration of intent"**, and to restructure to statements whenever the
  walrus form "would lead to ambiguity about execution order." Appendix A
  (Tim Peters's findings, cited in the PEP itself) gives concrete
  do/don't-use guidance: good for capturing a function's result directly in
  a loop/if header (`if result := solution(xs, n):`) to avoid a redundant
  second call; avoid when the line is already long or the assignment
  target is "conceptually unrelated" to the surrounding expression; avoid
  subtle chained forms like `while total != (total := total + term):` that
  depend on strict left-to-right evaluation order. This is a strictly more
  actionable version of the original's "where it eliminates redundant
  calls, not forced" — recommend replacing that line with these two
  concrete rules (prefer-statement-when-either-works; avoid when order
  becomes ambiguous) plus the loop/if-header capture example.

- **Dataclasses vs. Pydantic — a sourced decision rule where the original
  had none** — impact: high — depth: section. The original recommends
  "`dataclasses` or `pydantic.BaseModel` over plain dicts" without
  distinguishing the two. Verified this session: (1) `dataclasses`' own
  stdlib docs (fetched 2026-08-24) describe the module purely as reducing
  boilerplate (auto-generating `__init__`/`__repr__`/`__eq__`) — **no
  validation behavior is documented or implied**, confirming by omission
  that a dataclass performs no runtime type/value checking on construction.
  (2) Pydantic's own docs (fetched 2026-08-24, `docs.pydantic.dev`
  redirects to `pydantic.dev/docs/...`) state directly: "Untrusted data can
  be passed to a model and, after parsing and validation, Pydantic
  guarantees that the fields of the resultant model instance will conform
  to the field types defined on the model" — and separately confirm
  `pydantic.dataclasses.dataclass` exists as a decorator-compatible middle
  ground (dataclass ergonomics plus Pydantic validation). **Sourced
  decision rule for the authored skill**: use `pydantic.BaseModel` (or
  `pydantic.dataclasses.dataclass` if `@dataclass`-shaped ergonomics matter)
  when the data originates outside the process's own control — API request
  bodies, config files, external JSON/YAML, user input — because validation
  at the boundary is the actual point. Use plain stdlib `dataclasses` for
  internal, already-typed data passed between functions/modules within one
  trust boundary, where re-validating on every construction is pure
  overhead. Plain dicts remain the anti-pattern being reviewed against
  either way.

- **`match` statement, PEP 585 (`list[str]`), PEP 604 (`X | Y`)** — impact:
  low — depth: paragraph (per task guidance, durable/low-priority to
  re-verify in depth). These remain current, standard Python (3.10+) idioms
  with no displacement found or expected; not re-verified beyond confirming
  via Ruff's `UP` category (above) that automated enforcement for the PEP
  604/585 conversions exists and ships default-on.

## Explicitly out of scope

- **Framework-specific Ruff categories** (Django `DJ`, pandas-vet `PD`,
  NumPy `NPY`, FastAPI/Airflow-adjacent rules) — real and mature, per the
  domain-scoping doc's own explicit rejection of framework-specific rule
  categories at the general-domain level (`research/python-code-review-domain-scoping.md`,
  "Framework-specific rule categories" item); deferred to a future
  stack-specific overlay, not this domain.
- **NamedTuple vs. dataclass decision rule at the same depth as
  dataclass-vs-Pydantic** — the task asked specifically about the
  dataclass/Pydantic split; NamedTuple guidance in the original ("named
  tuples or dataclasses over positional tuples for return values") was not
  independently re-verified this session beyond confirming it's not
  contradicted by anything found. Flagged rather than silently expanded.
- **ASCII-only source files, multi-line triple-quoted strings, f-strings
  over `.format()`/`%`** — durable PEP 8-level conventions, not re-verified
  this session (task flagged these as low-priority/durable); no
  displacement is expected or plausible.
- **Bare `except:` / broad `except Exception:`** — already owned by Code
  Quality's Critical section per the original tool's own domain split
  (`original-tool/review-domains/code-quality.md`); Idioms & Patterns'
  "Important" list already cross-references this without duplicating
  ownership — kept as-is.
- **`itertools`/`functools.lru_cache`/`collections.defaultdict` Minor-tier
  items** — not re-verified this session; no signal found suggesting these
  durable idioms have changed.

## Sources

- https://devguide.python.org/versions/ — current Python version support
  table; confirms 3.10 exits security-only support October 2026, 3.11
  October 2027, 3.12 October 2028 — retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/#pyupgrade-up (full rules page,
  `docs.astral.sh/ruff/rules/`) — verified UP040
  (`non-pep695-type-alias`, stable since v0.0.283, gated to
  `target-version` 3.12+) — retrieved 2026-08-24
- https://raw.githubusercontent.com/astral-sh/ruff/main/README.md — the
  default-rules sentence ("By default, Ruff enables rules from the `F`,
  `E`, `B`, `UP`, and `RUF` categories, as well as many more") verified
  verbatim on a **second, independent host** (raw GitHub source, not the
  cached `docs.astral.sh` page) after an initial single-source read was
  caught as cache-risk during self-review — see note below. This confirms
  `UP` ships default-on. **`C4`/`SIM`/`PTH` being off by default is
  inferred from their absence from this list, not a separate explicit
  "these are opt-in" statement** — flagged as inferred, not directly
  quoted, per this baseline's own sourcing standard — retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/#flake8-comprehensions-c4 — full C4
  rule listing (19 rules, C400–C420, all stable, mostly fixable) —
  retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/#flake8-simplify-sim — verified SIM
  rule set including SIM101, SIM102, SIM105, SIM108, SIM110, SIM113,
  SIM115, SIM117, SIM118, SIM201, SIM300, SIM401 with exact
  names/messages, all stable — retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/#flake8-use-pathlib-pth — full PTH
  rule listing (PTH100–PTH124, PTH201–PTH203), all stable, mostly
  fixable, direct os.path→pathlib mappings — retrieved 2026-08-24
- https://peps.python.org/pep-0572/ — PEP 572 (walrus operator) primary
  source; "Style guide recommendations" section (prefer statements when
  either works; avoid where execution order becomes ambiguous) and
  Appendix A (Tim Peters's do/don't-use findings) — retrieved 2026-08-24
- https://docs.python.org/3/library/dataclasses.html — confirms
  dataclasses are documented purely as boilerplate-reduction
  (`__init__`/`__repr__`/`__eq__` generation), no validation behavior
  documented — retrieved 2026-08-24
- https://pydantic.dev/docs/validation/latest/concepts/models/ (redirect
  target of docs.pydantic.dev/latest/concepts/models/) — "untrusted data
  ... after parsing and validation, Pydantic guarantees fields ... conform
  to the field types" statement; confirms `pydantic.dataclasses.dataclass`
  exists as a dataclass/validation middle ground — retrieved 2026-08-24
- https://pypi.org/project/smart-open/ — smart-open's actual purpose
  (streaming to/from S3/GCS/Azure/HDFS/SFTP/HTTP, not general local file
  handling), current version 8.0.1 released 2026-07-15, three active
  maintainers — retrieved 2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) —
  "Framework-specific rule categories" rejection at the domain-scoping
  level, applied here to keep Django/pandas/NumPy Ruff categories out of
  scope — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/idioms-and-patterns.md`
  (this repo) — baseline starting point; every claim above either verifies,
  corrects (smart-open), or extends (dataclass/Pydantic, walrus, PEP 695,
  version floor) a specific line from this file — read 2026-08-24
- `research/python-code-review/testing.md` (this repo) — rigor/format
  standard this baseline follows (impact/depth tags, dated sources, honest
  gaps flagged as open questions rather than silently asserted) — read
  2026-08-24

## Open questions for the user

- **No documented `os.path`-over-`pathlib` carve-out was found.** This
  session did not locate an official source describing any scenario where
  `os.path` is still preferable (e.g. hot-loop performance-sensitive code,
  or interop with APIs that require `str` paths). Worth a follow-up fetch
  of a performance-focused source (or accept "no carve-out, `pathlib`
  unconditionally preferred, convert with `str(path)`/`os.fspath()` at
  interop boundaries" as the authored guidance) before finalizing.
- **PEP 695 tier gating.** UP040 requires `target-version = "py312"` in
  Ruff config to fire. Should the authored skill gate this idiom check to
  "only flag if the project's own declared minimum Python is 3.12+" (read
  from `pyproject.toml`/`setup.cfg`), consistent with how Testing gates
  Hypothesis/mutation testing to enterprise tier — or should it be a
  softer "consider raising your floor to 3.12 to unlock this" suggestion
  regardless of the project's current declared minimum? This baseline
  leans toward the former (gate on declared minimum) but did not find a
  precedent in the other domain baselines for gating a check on the
  target project's own version declaration rather than its tier.
- **NamedTuple-vs-dataclass decision rule** was left at the original's
  depth (not independently re-verified or sharpened) since the task's
  explicit ask was the dataclass/Pydantic split. Worth a short follow-up
  pass if the authored skill wants the same rigor applied there (e.g.
  `typing.NamedTuple` for lightweight positional+named access with zero
  behavior, vs. `@dataclass` once methods or mutability control are
  needed).
- **Match-statement / PEP 585 / PEP 604 depth** was deliberately kept
  shallow per the task's own low-priority framing. If the authored skill
  wants named linter enforcement for these beyond the `UP` category
  pointer above (e.g. specific UP rule codes for each PEP 604/585
  conversion), a follow-up fetch pass would need to pin exact rule codes —
  this session's fetches returned inconsistent code-to-slug mappings for
  the UP035–UP047 range across repeated attempts (likely due to the
  summarizing fetch tool truncating a very large page differently each
  call) and those exact numbers should not be trusted without a direct
  re-check.

## Resolutions (self-review, 2026-08-24)

- **PEP 695 tier gating (Open Question above)**: leaning toward gating by
  the project's own declared minimum (`requires-python` in
  `pyproject.toml`) rather than by review tier — reasoning: gating by
  declared minimum is the only option that avoids false-positive nagging
  on projects that legitimately can't move to 3.12 yet (e.g. a dependency
  pin), and the skill should read `requires-python` and stay silent below
  3.12 rather than surface a "someday" suggestion. This is a lean, not a
  final decision — the open question above (no precedent found for
  gating-by-declared-version vs. gating-by-tier) still stands for the user
  to confirm before authoring locks it in.

## Target file(s) + estimated length

- `skills/python-code-review/references/idioms-and-patterns.md` — est.
  180–220 lines (expands the original's 68 lines with: a sourced
  version-floor recommendation, a Ruff-category table with default-on
  status, the PEP 695/UP040 addition, a corrected smart-open line, sharper
  walrus-operator guidance, and a sourced dataclass-vs-Pydantic decision
  rule — while keeping Minor-tier and unverified-but-durable items close
  to their original wording).
