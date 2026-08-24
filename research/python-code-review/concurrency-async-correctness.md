# Baseline: Concurrency & Async Correctness
Status: user-approved      Date: 2026-08-24

**Domain boundary (stated explicitly per scoping doc instruction):** this
domain owns *correctness under concurrent execution* — races, deadlocks,
await hygiene, cancellation semantics, and free-threading thread-safety
obligations. The sibling Performance domain keeps *throughput* concerns —
caching, connection pooling, and the GIL as a throughput bottleneck (i.e.
"should this be `multiprocessing` instead of `threading` for CPU-bound
work" is Performance's question; "is this shared-state access safe" is
this domain's question). Performance's existing scope note already lists
"asyncio used correctly: no blocking calls in async context" and "Thread
safety: shared mutable state protected by locks" — those two checks move
here rather than being duplicated; Performance's scope note should be
edited at authoring time to remove them and cross-reference this domain.

## In scope

- **Free-threading (PEP 703 / PEP 779) — current status, verified directly**
  — impact: high — depth: section. This was the single highest-priority
  fact to nail down, and it resolves cleanly with no ambiguity when PEP 703
  and PEP 779 are read together (a prior research pass on the sibling
  Performance domain reportedly struggled here — the fix is reading both
  PEPs, not just PEP 703's text, since PEP 703 alone describes only the
  starting position).
  - **PEP 703** (free-threaded CPython, `--disable-gil`) has **Status:
    Final**, targeted **Python-Version: 3.13**. The Steering Council's
    acceptance was explicitly conditional: "the rollout be gradual and
    break as little as possible." PEP 703's own text keeps the GIL as
    default: "The global interpreter lock will remain the default for
    CPython builds and python.org downloads. A new build configuration
    flag, `--disable-gil` will be added to the configure script." This
    was the Phase I (experimental, opt-in) starting point in 3.13.
  - **PEP 779** (also **Status: Final**) is the follow-on that defines a
    three-phase rollout and formally declares free-threaded Python
    **"officially supported"** as of **Python 3.14** — this is Phase II,
    not Phase III. Phase II has concrete numeric entry criteria PEP 779
    states directly: single-threaded performance penalty around
    "10-15% slower" (hard ceiling 15%), memory overhead target "20%
    (geometric mean, as measured by pyperformance)," and "proven, stable
    APIs" with no further breaking changes expected. Corroborated
    independently by Python 3.14's own "What's New" doc, which lists PEP
    779 under a "Free-threaded Python is officially supported" heading and
    states the implementation "described in PEP 703 has been finished,"
    with the measured single-threaded performance penalty now "roughly
    5-10%, depending on the platform and C compiler used" — inside PEP
    779's Phase-II ceiling.
  - **What "officially supported" does NOT mean**: it is not the default
    build. PEP 779 states Phase III (making free-threading the *default*
    build) is deliberately left undecided: "The decision to make
    free-threaded Python the default (phase III) is very different, and we
    expect it will revolve around community support, willingness, and
    showing clear benefit" — no criteria or timeline given.
  - **Verified current-as-of-research-date status, including 3.15**: as of
    this research (2026-08-24), free-threaded CPython is an **officially
    supported, still-opt-in, non-default build** (available via a `t`
    suffix interpreter/installer, e.g. `python3.14t`). The stable-docs URL
    (`docs.python.org/3/whatsnew/3.15.html`) 404s because that path always
    serves the current *stable* release (3.14) — not evidence about 3.15
    itself. The actual in-development page,
    `docs.python.org/3.15/whatsnew/3.15.html` (fetched directly, confirmed
    in draft form for **Python 3.15.0rc1**), contains **no Phase III
    default-build announcement**; its only free-threading-related addition
    is **PEP 803** (Stable ABI for free-threaded builds, `abi3t`), which
    lets C extensions targeting the Stable ABI compile for free-threaded
    builds — an extension-compatibility improvement, not a change to
    default-build status. Phase III remains unannounced through 3.15rc1.
  - **Review-relevant consequence** (this is where the domain's practical
    check lives, and is reasoned from the above, not separately quoted
    from a source): a codebase cannot be reviewed for free-threading
    correctness in the abstract — it depends on whether the target
    deployment actually runs a free-threaded (`t`-suffixed) interpreter.
    Where it does (or where a project's CI/packaging explicitly targets
    it), review should flag: reliance on the GIL for implicit atomicity of
    compound operations (see the race-conditions subsection below, which
    applies unconditionally, GIL or not, but whose blast radius is larger
    under free-threading since even the *already-known-unsafe* operations
    now interleave at finer granularity); C-extension code assuming
    GIL-serialized access without its own locking; and any place code
    comments or design assume "only one thread runs Python bytecode at a
    time."

- **Structured concurrency: `asyncio.TaskGroup`** — impact: high — depth:
  section. Added Python 3.11+. Verified directly against
  `docs.python.org/3/library/asyncio-task.html`. Cancellation propagation,
  quoted exactly: "The first time any of the tasks belonging to the group
  fails with an exception other than `asyncio.CancelledError`, the
  remaining tasks in the group are cancelled. No further tasks can then be
  added to the group. At this point, if the body of the `async with`
  statement is still active ... the task directly containing the `async
  with` statement is also cancelled. The resulting `asyncio.CancelledError`
  will interrupt an `await`, but it will not bubble out of the containing
  `async with` statement." Exception aggregation, quoted exactly: "Once all
  tasks have finished, if any tasks have failed with an exception other
  than `asyncio.CancelledError`, those exceptions are combined in an
  `ExceptionGroup` or `BaseExceptionGroup` ... which is then raised."
  Review angle: `TaskGroup` (structured — the parent scope can't exit until
  all children finish or are cancelled) is the documented replacement for
  bare `asyncio.gather()`/manually-tracked task lists for any new code
  needing to run multiple coroutines concurrently and handle their
  failures together; flag hand-rolled task-list-plus-`gather` patterns in
  new code as a candidate for `TaskGroup` when the correctness properties
  above (all-fail visibility, propagated cancellation) matter and the
  target Python is 3.11+.

- **Exception groups and `except*` (PEP 654)** — impact: high — depth:
  paragraph. Verified against `docs.python.org/3/library/exceptions.html`.
  `ExceptionGroup` (extends `Exception`) and `BaseExceptionGroup` (extends
  `BaseException`) exist specifically "when it is necessary to raise
  multiple unrelated exceptions," and are "recognised by `except*`, which
  matches their subgroups based on the types of the contained exceptions."
  This is the direct language-level mechanism `TaskGroup` uses to surface
  more than one task failure instead of only the first. Review angle: code
  that catches a `TaskGroup`'s raised exception with a plain `except
  Exception:` will only see the `ExceptionGroup` wrapper, not the
  individual task exceptions — `except*` (matched by exception type) or
  the group's `.exceptions` tuple / `.subgroup()` / `.split()` methods are
  required to inspect what actually failed. A bare `except Exception:`
  around `TaskGroup`-using code that doesn't account for the wrapper is a
  reviewable defect.

- **Asyncio pitfalls: fire-and-forget tasks garbage-collected mid-flight**
  — impact: high — depth: checklist. Verified directly against
  `asyncio.create_task()`'s documented "Important" warning, quoted
  exactly: "Save a reference to the result of this function, to avoid a
  task disappearing mid-execution. The event loop only keeps weak
  references to tasks. A task that isn't referenced elsewhere may get
  garbage collected at any time, even before it's done." The docs'
  own documented fix, quoted as code:
  ```python
  background_tasks = set()
  for i in range(10):
      task = asyncio.create_task(some_coro(param=i))
      background_tasks.add(task)          # strong reference
      task.add_done_callback(background_tasks.discard)  # avoid unbounded growth
  ```
  Review checklist derived directly from this:
  - `asyncio.create_task(...)` called without assigning/storing the
    returned `Task` anywhere reachable — the classic silent-failure
    pattern (task looks fire-and-forget, actually may vanish before
    completion with no error surfaced).
  - A task stored only in a local variable that goes out of scope before
    the task completes (same root cause as above, less obvious at review
    time).
  - No `add_done_callback` (or equivalent `await`/`TaskGroup` membership)
    to either propagate exceptions raised inside the task or remove it
    from a tracking collection once done — an unhandled exception inside a
    forgotten task is otherwise silently logged by the event loop's
    default exception handler rather than raised anywhere the caller sees.

- **Asyncio pitfalls: forgotten `await` and blocking calls in async
  context** — impact: high — depth: checklist. Verified directly against
  `docs.python.org/3/library/asyncio-dev.html`. A call to an `async def`
  function without `await` (or without scheduling via
  `asyncio.create_task()`) returns an unexecuted coroutine object rather
  than running it; the docs state exactly this and the resulting runtime
  signal verbatim: "When a coroutine function is called, but not awaited
  ... or the coroutine is not scheduled with `asyncio.create_task()`,
  asyncio will emit a `RuntimeWarning`" — shown as
  `RuntimeWarning: coroutine 'test' was never awaited`. In debug mode
  (`asyncio.run(main(), debug=True)`), the same warning additionally
  prints a full traceback of where the coroutine was created ("Coroutine
  created at (most recent call last)"), which the docs present as the
  tool for actually locating the source of the problem rather than just
  detecting that it happened. Review angle: this `RuntimeWarning` is a
  real, distinct-from-Ruff runtime signal — it fires even on code Ruff's
  static ASYNC checks wouldn't catch (a coroutine reference simply never
  invoked with `await`) — worth naming explicitly as a check: does the
  project run with warnings-as-errors or debug mode in CI/tests, so this
  class of defect surfaces instead of silently no-op'ing. Blocking calls
  inside `async def` (synchronous I/O,
  `time.sleep()`, unbuffered subprocess calls, blocking HTTP clients) stall
  the entire single-threaded event loop for every concurrently-scheduled
  coroutine, not just the caller — this is exactly the class of defect
  Ruff's `ASYNC2xx`/`ASYNC25x` rules below exist to catch mechanically.

- **Ruff's `flake8-async` (ASYNC) rule category — current rule content**
  — impact: high — depth: table. Verified directly against
  `docs.astral.sh/ruff/rules/#flake8-async-async` (retrieved 2026-08-24).
  15 stable rules, 1 preview:

  | Code | Rule | Status |
  |---|---|---|
  | ASYNC100 | `cancel-scope-no-checkpoint` | Stable |
  | ASYNC105 | `trio-sync-call` | Stable |
  | ASYNC109 | `async-function-with-timeout` | Stable |
  | ASYNC110 | `async-busy-wait` | Stable |
  | ASYNC115 | `async-zero-sleep` | Stable |
  | ASYNC116 | `long-sleep-not-forever` | Stable |
  | ASYNC119 | `yield-in-context-manager-in-async-generator` | Preview |
  | ASYNC210 | `blocking-http-call-in-async-function` | Stable |
  | ASYNC212 | `blocking-http-call-httpx-in-async-function` | Stable |
  | ASYNC220 | `create-subprocess-in-async-function` | Stable |
  | ASYNC221 | `run-process-in-async-function` | Stable |
  | ASYNC222 | `wait-for-process-in-async-function` | Stable |
  | ASYNC230 | `blocking-open-call-in-async-function` | Stable |
  | ASYNC240 | `blocking-path-method-in-async-function` | Stable |
  | ASYNC250 | `blocking-input-in-async-function` | Stable |
  | ASYNC251 | `blocking-sleep-in-async-function` | Stable |

  Two clusters, with per-rule applicability verified individually (not
  inferred from rule names — each of the six 1xx-range rules below was
  fetched separately to confirm which async framework(s) its own "What it
  does"/"Why is this bad?" text actually names): (a) blocking-call
  detection in async functions (ASYNC210/212/220-222/230/240/250/251 —
  HTTP clients, subprocess spawning/waiting, file `open()`, `pathlib`
  blocking methods, `input()`, `time.sleep()`) — framework-agnostic
  (these check for blocking stdlib/HTTP-client calls inside any `async
  def`, regardless of which async library schedules it); this is the
  mechanical, lintable form of the forgotten-await/blocking-call checklist
  item above, and the concrete tool answer to "how would a reviewer
  actually catch this at scale." (b) Structured-concurrency hygiene in the
  1xx range, which splits by framework rule-by-rule rather than as a
  block: **ASYNC100** (`cancel-scope-no-checkpoint`) and **ASYNC109**
  (`async-function-with-timeout`) explicitly name both `asyncio` (e.g.
  `asyncio.timeout`) and `trio`/`anyio` in their own docs, so both fire on
  plain-`asyncio` code. **ASYNC110** (`async-busy-wait`, sleep-in-a-
  `while`-loop) uses `asyncio.sleep()`/`asyncio.Event()` in its own
  example code, so it also applies to bare `asyncio`. **ASYNC105**
  (`trio-sync-call`), **ASYNC115** (`async-zero-sleep`), and **ASYNC116**
  (`long-sleep-not-forever`) are trio/anyio-only by their own docs'
  text and examples (`trio.sleep(0)`/`anyio.sleep(0)`,
  `trio.sleep()`/`anyio.sleep()` past 24h) — these three specifically do
  **not** fire on bare-`asyncio` code and should be noted as
  trio/anyio-only in the authored skill, while the rest of the 1xx range
  is not framework-restricted.

- **Race conditions and deadlocks in threaded code; GIL atomicity
  boundaries** — impact: high — depth: section. Verified directly against
  `docs.python.org/3/faq/library.html` (the "What kinds of global value
  mutation are thread-safe?" FAQ entry) and
  `docs.python.org/3/library/threading.html`. The FAQ enumerates *specific*
  operations documented as atomic under the GIL: `L.append(x)`,
  `L1.extend(L2)`, `x = L[i]`, `x = L.pop()`, `L1[i:j] = L2`, `L.sort()`,
  `x = y`, `x.field = y`, `D[x] = y`, `D1.update(D2)`, `D.keys()` — and
  explicitly lists compound operations that are **not** atomic despite
  looking like single steps: `i = i+1`, `L.append(L[-1])`, `L[i] = L[j]`,
  `D[x] = D[x] + 1`. The FAQ's own guidance, quoted verbatim: "When in
  doubt, use a mutex!" This is the direct primary-source answer to "does
  the GIL make my shared counter/accumulator thread-safe" — no, not for
  any read-modify-write compound operation, GIL or not. Review angle:
  `counter += 1`, `dict[key] = dict.get(key, 0) + 1`, and similar
  read-modify-write patterns on shared mutable state accessed from more
  than one thread are a defect regardless of whether the code currently
  runs under a GIL build (where the race window is merely narrow) or a
  free-threaded build (where it's wider and more likely to actually
  manifest) — the correct fix in both cases is the same: an explicit
  `threading.Lock`.
  - **Deadlock, Lock vs. RLock**: verified directly — a plain
    `threading.Lock` re-acquired by the same thread that already holds it
    blocks forever (self-deadlock): "When the state is locked, `acquire()`
    blocks until a call to `release()` in another thread changes it to
    unlocked." `threading.RLock` exists specifically to allow the *same*
    thread to re-acquire (nested `acquire()`/`release()` pairs), but the
    docs warn: "Failing to call release as many times the lock has been
    acquired can lead to deadlock" — making `with lock:` the documented
    preferred pattern over manual `acquire()`/`release()` pairs precisely
    because it can't leak an unbalanced acquire.
  - **Multi-lock ordering deadlock** (classic "thread A holds lock 1 wants
    lock 2, thread B holds lock 2 wants lock 1"): this is **not** directly
    addressed in the `threading` module docs fetched this session — it's
    well-established general concurrency theory, not stdlib-specific
    guidance, so it's flagged here as a reasoned inclusion rather than a
    directly-quoted one. Review angle: code acquiring more than one lock
    should acquire them in a single, consistent global order everywhere in
    the codebase; inconsistent acquisition order across two code paths is
    the reviewable defect pattern, even without a specific primary source
    naming "lock ordering" by that term.

## Explicitly out of scope

- **GIL as a throughput bottleneck / `multiprocessing` vs. `threading` for
  CPU-bound work** — Performance domain's lens ("is it fast enough,"
  belongs with connection pooling/caching), not this domain's correctness
  lens. Already present in Performance's existing scope note
  ("`threading` used for CPU-bound work (should use `multiprocessing` or C
  extension)") — leave it there.
- **Caching, connection pooling, N+1 queries, general async throughput
  optimization** — Performance domain, unrelated to correctness-under-
  concurrency.
- **`multiprocessing`-specific IPC/pickling correctness** (what can and
  can't cross a process boundary, `Manager` proxy object semantics) — a
  real and distinct topic, but not researched this session; flagged as a
  candidate for a future pass rather than silently absorbed into the
  threading/asyncio content above. See Open Questions.
- **Trio- or AnyIO-specific structured-concurrency semantics beyond what
  Ruff's ASYNC rules mechanically check** — `asyncio.TaskGroup` was chosen
  as the researched primary because it's stdlib and Python 3.11+ ubiquity
  makes it the highest-value target; a deep Trio/AnyIO-native review pass
  (nurseries, cancel scopes beyond ASYNC100's mechanical check) is
  reasonable to defer to a future stack-specific overlay, consistent with
  how the Testing baseline deferred framework-specific test tooling.
- **Distributed-systems concurrency** (distributed locks, consensus,
  eventual consistency across services) — out of scope for a single-
  codebase Python review skill; this domain is about concurrency
  correctness *within one process/codebase*, not across a distributed
  system.
- **`async`/`await` performance overhead, event-loop selection
  (`uvloop` vs. stdlib), or event-loop-per-thread architecture choices**
  — Performance's lens.

## Sources

- https://peps.python.org/pep-0703/ — free-threaded CPython proposal;
  Status: Final; Python-Version: 3.13; GIL remains default,
  `--disable-gil` is the opt-in build flag; Steering Council's conditional
  "gradual rollout" acceptance note — retrieved 2026-08-24
- https://peps.python.org/pep-0779/ — three-phase free-threading rollout
  plan; Status: Final; Phase II ("officially supported," Python 3.14)
  numeric entry criteria (performance penalty ceiling, memory overhead
  target, API stability); explicit statement that Phase III (default
  build) timeline/criteria are undecided — retrieved 2026-08-24
- https://docs.python.org/3/whatsnew/3.14.html — corroborates PEP 779:
  "Free-threaded Python is officially supported" heading; PEP 703
  implementation "finished" including C API changes; measured
  single-threaded performance penalty "roughly 5-10%" — retrieved
  2026-08-24
- https://docs.python.org/3.15/whatsnew/3.15.html — version-pinned
  in-development page (docs.python.org/3/whatsnew/3.15.html 404s because
  that path always serves the current stable release, 3.14, not evidence
  either way about 3.15); confirmed draft status for Python 3.15.0rc1; no
  Phase III (default-build) announcement present; only free-threading
  addition is PEP 803 (Stable ABI for free-threaded builds, `abi3t`) —
  retrieved 2026-08-24
- https://docs.python.org/3/library/asyncio-dev.html — never-awaited-
  coroutine `RuntimeWarning`, exact trigger condition, and debug-mode's
  additional creation-traceback output — retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/cancel-scope-no-checkpoint/,
  .../async-function-with-timeout/, .../async-busy-wait/,
  .../async-zero-sleep/, .../long-sleep-not-forever/ — individual ASYNC
  1xx-range rule pages, fetched separately to verify per-rule
  asyncio-vs-trio/anyio applicability rather than inferring it from rule
  names or the category-listing page alone — retrieved 2026-08-24
- https://docs.python.org/3/library/asyncio-task.html — `TaskGroup`
  cancellation-propagation and exception-aggregation behavior (quoted
  verbatim above); `asyncio.create_task()`'s "Important" warning on weak
  task references and the documented `background_tasks` set-plus-
  `add_done_callback` fix pattern — retrieved 2026-08-24
- https://docs.python.org/3/library/exceptions.html#exception-groups —
  `ExceptionGroup`/`BaseExceptionGroup` (PEP 654) definition, `except*`
  matching semantics, `.subgroup()`/`.split()`/`.derive()` — retrieved
  2026-08-24
- https://docs.astral.sh/ruff/rules/#flake8-async-async — full current
  `flake8-async` (ASYNC) rule listing, 15 stable + 1 preview, verified
  code-by-code — retrieved 2026-08-24
- https://docs.python.org/3/faq/library.html#what-kinds-of-global-value-mutation-are-thread-safe
  — enumerated atomic vs. non-atomic operations under the GIL; "When in
  doubt, use a mutex!" guidance — retrieved 2026-08-24
- https://docs.python.org/3/library/threading.html#lock-objects — Lock
  vs. RLock semantics, self-deadlock-on-reacquire behavior for plain
  `Lock`, RLock's nested-acquire support and its own
  unbalanced-release-causes-deadlock warning, `with lock:` as the
  recommended pattern — retrieved 2026-08-24
- `C:\Users\devop\GitHub\agent-skills\research\python-code-review-domain-scoping.md`
  — this domain's justification, subsection list, and explicit boundary
  statement against Performance — read 2026-08-24
- `C:\Users\devop\GitHub\agent-skills\research\python-code-review\original-tool\review-domains\performance.md`
  — confirmed the two overlapping bullets ("asyncio used correctly: no
  blocking calls," "Thread safety: shared mutable state protected by
  locks") that move to this domain rather than being duplicated — read
  2026-08-24
- `C:\Users\devop\GitHub\agent-skills\research\python-code-review\testing.md`
  — rigor/structure bar this baseline was written to match (named
  tools/versions, verbatim quotes, honest "reasoned not sourced" labeling,
  tier-table pattern) — read 2026-08-24

## Open questions for the user

- **`multiprocessing` IPC/pickling correctness was not researched this
  session** (out of scope above, but flagged rather than silently
  dropped) — worth a dedicated follow-up fetch of
  `docs.python.org/3/library/multiprocessing.html`'s "Programming
  guidelines" section before authoring, if the domain should cover
  process-boundary correctness in addition to thread/async correctness.
- **Lock-ordering deadlock (acquire multiple locks in inconsistent order
  across code paths) has no direct stdlib-doc citation** — included as
  reasoned general concurrency-theory content (labeled as such above)
  rather than a quoted primary source. Confirm this reasoned-inclusion
  policy is acceptable here, matching how the Testing baseline handled its
  "weak assertion" and "large conftest.py" points.
- **Trio/AnyIO depth**: this baseline deliberately kept Trio coverage to
  "what Ruff's ASYNC100/105/110/115/116 mechanically check" rather than
  researching Trio's nursery/cancel-scope model directly, since
  `asyncio.TaskGroup` (stdlib, 3.11+) was prioritized as higher-value.
  Confirm that's the right cutoff, or whether Trio/AnyIO warrant their own
  research pass given how common they are in newer async codebases.
- **Free-threading review checklist is reasoned, not a direct tool-rule
  citation** — no Ruff/mypy rule category was found (or searched for)
  that mechanically flags "code implicitly relying on GIL atomicity" for
  free-threaded builds specifically; the review angle stated above (flag
  compound read-modify-write on shared state, flag C-extensions assuming
  GIL-serialized access) is derived from PEP 703/779 plus the general
  atomicity FAQ, not from a dedicated free-threading linter. Worth a
  follow-up search for one before authoring locks this in as the domain's
  free-threading-specific checklist.

## Resolutions (Checkpoint B review, 2026-08-24)

- **`multiprocessing` IPC/pickling correctness**: leave out of this v1
  pass — not researched this session, noted as a candidate future
  addition rather than delaying authoring.
- **Lock-ordering deadlock, reasoned-not-sourced inclusion**: accepted —
  consistent with the honest-labeling pattern already used across this
  research series.
- **Trio/AnyIO depth cutoff**: confirmed correct — stick to what Ruff's
  ASYNC rules mechanically check; a full Trio/AnyIO-native pass deferred
  to a future stack-specific overlay.
- **Free-threading checklist, reasoned not tool-cited**: accepted, same
  honest-labeling basis.

## Target file(s) + estimated length

- `skills/python-code-review/references/concurrency-async-correctness.md`
  — est. 220–260 lines (seven sourced sub-topics: free-threading status,
  TaskGroup, exception groups, two asyncio-pitfall checklists, Ruff ASYNC
  table, race-conditions-and-deadlocks section, at section/table/checklist
  depth), plus scoring-guide and required-evidence sections mirroring the
  original tool's per-domain structure once authored — those two sections
  are not part of this baseline itself, consistent with how the Testing
  baseline scoped its own length estimate. (This baseline document itself
  ran to ~400 lines because it also carries verbatim source quotes and
  per-rule verification trails that the authored skill file would
  compress into shorter reviewer-facing guidance.)
