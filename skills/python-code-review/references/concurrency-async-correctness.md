# Concurrency & Async Correctness

This is the reference `python-code-review` applies when judging whether code
that runs concurrently — threads, `asyncio` coroutines and tasks, or a
free-threaded interpreter — behaves correctly under interleaving: races,
deadlocks, await hygiene, cancellation semantics, and the thread-safety
obligations a free-threaded build removes the GIL's cover for. It asks "is
this shared-state access, cancellation path, or task lifecycle safe," never
"is this fast." The sibling
[`performance.md`](../references/performance.md) owns the throughput
lens on the same code — caching, connection pooling, and the GIL as a
*bottleneck* rather than a correctness backstop (whether CPU-bound work
should move to `multiprocessing` instead of `threading` is Performance's
question; whether concurrent access to shared state is safe is this
domain's). Two checks that lived in Performance's scope before this domain
existed move here rather than being duplicated: "asyncio used correctly, no
blocking calls in async context" and "thread safety: shared mutable state
protected by locks." If a finding is about `async`/`await` overhead,
event-loop selection (`uvloop` vs. stdlib), or `multiprocessing` chosen for
CPU-bound work, it belongs in Performance, not here.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [Free-Threading (PEP 703 / PEP 779): Current Status](#free-threading-pep-703--pep-779-current-status)
- [Structured Concurrency: `asyncio.TaskGroup`](#structured-concurrency-asynciotaskgroup)
- [Exception Groups and `except*` (PEP 654)](#exception-groups-and-except-pep-654)
- [Fire-and-Forget Tasks and the Weak-Reference GC Gotcha](#fire-and-forget-tasks-and-the-weak-reference-gc-gotcha)
- [Forgotten `await` and Blocking Calls in Async Context](#forgotten-await-and-blocking-calls-in-async-context)
- [Ruff's `flake8-async` (ASYNC) Rule Set](#ruffs-flake8-async-async-rule-set)
- [Race Conditions and GIL Atomicity Boundaries](#race-conditions-and-gil-atomicity-boundaries)
- [Deadlocks: Lock vs. RLock, and Lock Ordering](#deadlocks-lock-vs-rlock-and-lock-ordering)
- [Conditional: Free-Threaded Deployment Target](#conditional-free-threaded-deployment-target)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Required Evidence in Findings](#required-evidence-in-findings)
- [Sources](#sources)

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Blocking calls inside `async def` (sync I/O, `time.sleep()`, blocking HTTP/subprocess) | Yes | Yes | Yes |
| `asyncio.create_task()` result stored with a strong reference, not fire-and-forget | Yes | Yes | Yes |
| Read-modify-write races on shared mutable state across threads (`counter += 1`, `d[k] = d.get(k, 0) + 1`) | Yes | Yes | Yes |
| Shared mutable state protected by `threading.Lock`/`with lock:`, not manual `acquire()`/`release()` | Yes | Yes | Yes |
| `asyncio.TaskGroup` preferred over hand-rolled task-list + `gather()` for new concurrent code (3.11+) | No | Yes | Yes |
| `except*` / `ExceptionGroup` inspection around `TaskGroup`-using code, not a bare `except Exception:` | No | Yes | Yes |
| Ruff's `flake8-async` (`ASYNC`) rule set enabled in lint config | No | Yes | Yes |
| Never-awaited-coroutine `RuntimeWarning` surfaced via warnings-as-errors or `debug=True` in CI/tests | No | Yes | Yes |
| Multi-lock acquisition ordering kept consistent across code paths | No | Yes | Yes |
| Free-threading correctness review (GIL-atomicity reliance, C-extension locking) | Conditional* | Conditional* | Conditional* |

\* Gated by deployment target, not project scale — see [Conditional:
Free-Threaded Deployment Target](#conditional-free-threaded-deployment-target).

A script-tier project still benefits from the checks that cost nothing to
apply regardless of size: a forgotten `await`, a fire-and-forget task that
silently vanishes, and a racy shared counter are defects in a fifty-line
script exactly as much as in a service. What's gated to web/enterprise is
the infrastructure-shaped half of this domain — adopting a structured-
concurrency primitive across a codebase, wiring a linter category into CI,
enforcing warnings-as-errors — the same script-vs.-infrastructure split
`testing.md` and `performance.md` draw for their own tier tables.

## Free-Threading (PEP 703 / PEP 779): Current Status

Free-threaded CPython's status is precise and easy to get wrong by reading
only half the story, so it's worth stating exactly.

**PEP 703** (the free-threaded CPython proposal, `--disable-gil`) has
Status: Final, targeted at Python 3.13. Its acceptance by the Steering
Council was explicitly conditional on "the rollout be gradual and break as
little as possible," and the PEP's own text keeps the GIL as the default
build: a new `--disable-gil` configure flag is added, but "the global
interpreter lock will remain the default for CPython builds and python.org
downloads." That's Phase I — experimental, strictly opt-in, as it shipped
in 3.13.

**PEP 779**, also Status: Final, is the follow-on that defines the full
three-phase rollout and is the one that actually declares free-threaded
Python **"officially supported"** — as of **Python 3.14**, and that's
Phase II, not Phase III. Phase II has concrete numeric entry criteria: a
single-threaded performance penalty ceiling around "10-15% slower," a
memory-overhead target of "20% (geometric mean, as measured by
pyperformance)," and "proven, stable APIs" with no further breaking
changes expected. Python 3.14's own "What's New" doc corroborates this
independently, listing PEP 779 under a "Free-threaded Python is officially
supported" heading, stating the PEP 703 implementation "has been
finished," and reporting a measured single-threaded penalty of "roughly
5-10%, depending on the platform and C compiler used" — inside PEP 779's
Phase II ceiling.

**What "officially supported" does not mean: the default build.** PEP 779
is explicit that Phase III — making free-threading the *default* build —
is a deliberately separate, undecided question: "the decision to make
free-threaded Python the default (phase III) is very different, and we
expect it will revolve around community support, willingness, and showing
clear benefit," with no criteria or timeline given.

**Status through 3.15.** As of this domain's research (2026-08-24),
free-threaded CPython remains an officially supported, still-opt-in,
non-default build, available via a `t`-suffixed interpreter (e.g.
`python3.14t`). Checking the in-development 3.15 docs directly (not the
stable-docs URL, which always serves the current *stable* release and so
404s for an unreleased version rather than saying anything about it) shows
no Phase III default-build announcement through 3.15.0rc1; the only
free-threading-related addition is PEP 803 (Stable ABI for free-threaded
builds, `abi3t`), which lets C extensions targeting the Stable ABI compile
for free-threaded builds — an extension-compatibility improvement, not a
change to default-build status.

**What this means for review.** A codebase cannot be reviewed for
free-threading correctness in the abstract — it depends on whether the
target deployment actually runs a `t`-suffixed interpreter, or whether the
project's CI/packaging targets one explicitly. See [Conditional:
Free-Threaded Deployment Target](#conditional-free-threaded-deployment-target)
for the checklist that applies once that's true. Where it isn't true, the
race-condition and lock-discipline guidance below still applies
unconditionally — free-threading only widens an already-real race window,
it doesn't create the underlying defect.

## Structured Concurrency: `asyncio.TaskGroup`

`asyncio.TaskGroup` (3.11+) is the documented replacement for a
hand-tracked list of tasks plus `asyncio.gather()` wherever new code needs
to run multiple coroutines concurrently and handle their failures
together. Two correctness properties `gather()` doesn't give you for free
are the reason to prefer it:

**Cancellation propagation.** The first task that fails with anything
other than `asyncio.CancelledError` cancels every other task still running
in the group, and no further tasks can be added to it. If the `async with
TaskGroup()` block is still active when that happens, the task containing
it is cancelled too — the resulting `CancelledError` interrupts an
`await` inside the block but does not bubble out past the `async with`
itself.

**Exception aggregation.** Once every task in the group has finished, if
more than one failed with something other than `CancelledError`, those
exceptions are combined into an `ExceptionGroup` (or `BaseExceptionGroup`)
and raised together — not just the first one, the way `gather()`'s
default `return_exceptions=False` behavior effectively surfaces only
whichever exception it happens to see first.

`TaskGroup` is structured in the sense that matters for correctness: the
parent scope cannot exit until every child has either finished or been
cancelled, so there's no window where a background task keeps running
after the code that spawned it has moved on unaware. **Review angle:**
new code that runs multiple coroutines concurrently and needs to observe
all of their failures (not just the first) or propagate cancellation
correctly is a candidate for `TaskGroup` over a hand-rolled task list plus
`gather()`, once the target Python is 3.11+. This isn't a mandate to
rewrite every existing `gather()` call — it's a bar for new code and a
flag when reviewing code that clearly needed these properties and didn't
get them.

## Exception Groups and `except*` (PEP 654)

`ExceptionGroup` (extends `Exception`) and `BaseExceptionGroup` (extends
`BaseException`) exist specifically for the case where more than one
unrelated exception needs to be raised together, and are matched by
`except*`, which selects subgroups by the type of the exceptions they
contain. This is the language-level mechanism `TaskGroup` relies on to
surface more than one task failure instead of collapsing to just the
first.

The reviewable consequence: code that wraps `TaskGroup`-using code in a
plain `except Exception:` sees only the `ExceptionGroup` wrapper, not the
individual task exceptions inside it — a `try`/`except` written before the
call site adopted `TaskGroup`, or copied from non-structured-concurrency
code, will silently stop matching what it used to catch. Getting at what
actually failed requires `except*` (matched by exception type, same as a
normal `except` clause but subgroup-aware) or the group's own
`.exceptions` tuple, `.subgroup()`, or `.split()` methods.

**Review angle:** a bare `except Exception:` around `TaskGroup`-using code
that doesn't account for the `ExceptionGroup` wrapper is a defect — not a
style nit, since it changes what the `except` clause actually catches
compared to pre-`TaskGroup` code the author may have been mentally
modeling it against.

## Fire-and-Forget Tasks and the Weak-Reference GC Gotcha

`asyncio.create_task()`'s own documentation carries an "Important" warning
that names a real, non-obvious failure mode directly: the event loop only
holds a **weak** reference to a task. "A task that isn't referenced
elsewhere may get garbage collected at any time, even before it's done" —
so a task that looks fire-and-forget can vanish mid-execution with no
error surfaced anywhere. This is a silent-failure pattern, not a crash:
nothing raises, nothing logs by default, the work simply doesn't finish.

The documented fix, verbatim from the same docs:

```python
background_tasks = set()
for i in range(10):
    task = asyncio.create_task(some_coro(param=i))
    background_tasks.add(task)          # strong reference
    task.add_done_callback(background_tasks.discard)  # avoid unbounded growth
```

Storing the task in a collection gives it a strong reference so the
garbage collector leaves it alone; registering `discard` as a done
callback keeps that collection from growing without bound over the life
of a long-running process.

**Review checklist**, derived directly from this pattern:

- `asyncio.create_task(...)` called without assigning or storing the
  returned `Task` anywhere reachable — the classic case, and the easiest
  to miss because the code still "runs" most of the time in a short-lived
  process where GC pressure never gets high enough to collect the task
  before it finishes.
- A task stored only in a local variable that goes out of scope before
  the task completes — same root cause, harder to spot at review time
  since a reference does exist, just not long enough.
- No `add_done_callback` (or equivalent `await`, or `TaskGroup`
  membership) to propagate an exception raised inside the task, or to
  remove it from a tracking collection once done. Without one, an
  unhandled exception inside a forgotten task is logged by the event
  loop's default exception handler and nowhere else — the caller never
  sees it, and nothing fails loudly.

## Forgotten `await` and Blocking Calls in Async Context

Calling an `async def` function without `await` (and without scheduling
it via `asyncio.create_task()`) doesn't run it — it returns an unexecuted
coroutine object. The docs state the resulting signal exactly:
`asyncio` emits `RuntimeWarning: coroutine '...' was never awaited`. In
debug mode (`asyncio.run(main(), debug=True)`), the same warning also
prints a full traceback of where the coroutine was created — the docs
present this as the actual tool for locating the bug, not just detecting
that it happened.

This `RuntimeWarning` is a genuine runtime signal distinct from anything
Ruff's static `ASYNC` checks catch — a coroutine reference that's simply
never invoked with `await` isn't a lint-detectable pattern in general,
it's a warning that only fires when the code actually runs. **Review
angle:** check whether the project runs with warnings-as-errors or debug
mode in CI/tests. Without one of those, this exact class of defect
degrades to a silent no-op instead of a visible failure — the coroutine
that should have sent an email, written a record, or awaited a lock
simply never runs, and the test suite stays green because nothing raised.

Blocking calls inside `async def` — synchronous I/O, `time.sleep()`,
unbuffered subprocess calls, a blocking HTTP client — are a related but
distinct defect: they stall the entire single-threaded event loop for
every concurrently scheduled coroutine, not just the caller. This is
exactly the class of defect Ruff's `ASYNC2xx`/`ASYNC25x` rules exist to
catch mechanically — see the next section.

## Ruff's `flake8-async` (ASYNC) Rule Set

Ruff's `flake8-async` category currently has 15 stable rules and 1 preview
rule:

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

Two clusters worth telling apart, because their framework applicability
differs:

**Blocking-call detection** (`ASYNC210`/`212`/`220`–`222`/`230`/`240`/
`250`/`251`) — HTTP clients, subprocess spawning and waiting, file
`open()`, blocking `pathlib` methods, `input()`, `time.sleep()`. These are
framework-agnostic: they check for blocking stdlib/HTTP-client calls
inside any `async def`, regardless of which library schedules the
coroutine. This is the mechanical, lintable form of the forgotten-await
checklist's blocking-call half above, and the concrete answer to "how
would a reviewer catch this at scale" — flag any codebase running Ruff
without this cluster enabled as missing an easy, high-value check.

**Structured-concurrency hygiene** in the 1xx range splits by framework
rule-by-rule rather than as a block, verified per rule against each rule's
own documented example rather than inferred from naming alone:

- **ASYNC100** (`cancel-scope-no-checkpoint`) and **ASYNC109**
  (`async-function-with-timeout`) name both `asyncio` (e.g.
  `asyncio.timeout`) and `trio`/`anyio` directly in their own docs — both
  fire on plain-`asyncio` code.
- **ASYNC110** (`async-busy-wait`, sleep-in-a-`while`-loop) uses
  `asyncio.sleep()`/`asyncio.Event()` in its own example code, so it also
  applies to bare `asyncio`.
- **ASYNC105** (`trio-sync-call`), **ASYNC115** (`async-zero-sleep`), and
  **ASYNC116** (`long-sleep-not-forever`) are trio/anyio-only by their own
  docs' text and examples (`trio.sleep(0)`/`anyio.sleep(0)`,
  `trio.sleep()`/`anyio.sleep()` used past 24h) — these three specifically
  do **not** fire on bare-`asyncio` code. Don't cite them as a gap in an
  `asyncio`-only codebase; they mechanically can't fire there.

This domain's Trio/AnyIO coverage is capped at what these rules
mechanically check — see [Out of Scope](#out-of-scope) for why a deeper,
nursery/cancel-scope-native Trio review is deferred rather than asserted
here.

## Race Conditions and GIL Atomicity Boundaries

The GIL makes some individual bytecode-level operations atomic, and it's a
documented, specific list — not "anything that looks like one line." The
CPython FAQ enumerates what's actually safe: `L.append(x)`, `L1.extend(L2)`,
`x = L[i]`, `x = L.pop()`, `L1[i:j] = L2`, `L.sort()`, `x = y`,
`x.field = y`, `D[x] = y`, `D1.update(D2)`, `D.keys()`. It's equally
explicit about what only *looks* atomic but isn't: `i = i + 1`,
`L.append(L[-1])`, `L[i] = L[j]`, `D[x] = D[x] + 1` — every one of these is
a read followed by a separate write, and the GIL provides no protection
across the gap between them. The FAQ's own guidance is unambiguous: "When
in doubt, use a mutex!"

This directly answers "does the GIL make my shared counter thread-safe" —
no, not for any read-modify-write compound operation, GIL or not.
**Review angle:** `counter += 1`, `dict[key] = dict.get(key, 0) + 1`, and
any structurally similar read-modify-write on state shared across more
than one thread is a defect regardless of whether the code currently runs
under a GIL build (where the race window is merely narrow) or a
free-threaded build (where the same window is wider and far more likely
to actually manifest). The fix is identical in both cases: an explicit
`threading.Lock` around the read-modify-write, not a hope that the
operation happens to be one of the atomic ones on the list above.

## Deadlocks: Lock vs. RLock, and Lock Ordering

A plain `threading.Lock` re-acquired by the thread that already holds it
blocks forever — self-deadlock. The docs are direct about the mechanism:
"when the state is locked, `acquire()` blocks until a call to `release()`
in another thread changes it to unlocked" — there's no thread-identity
check that would let the *same* thread back in. `threading.RLock` exists
specifically to allow nested `acquire()`/`release()` pairs from the same
thread, but its own docs carry a matching warning: "failing to call
release as many times the lock has been acquired can lead to deadlock" —
an unbalanced RLock is just as deadlock-prone as a plain Lock misused, in
a different direction. This is exactly why `with lock:` is the documented
preferred pattern over manual `acquire()`/`release()` pairs: it cannot
leak an unbalanced acquire, even when an exception is raised inside the
critical section.

**Multi-lock ordering deadlock** — thread A holds lock 1 and wants lock 2
while thread B holds lock 2 and wants lock 1 — has no direct citation in
the `threading` module's own docs; it's well-established general
concurrency theory rather than stdlib-specific guidance, and is included
here as a reasoned addition rather than a sourced one. **Review angle:**
code that acquires more than one lock should acquire them in a single,
consistent global order everywhere in the codebase. Inconsistent
acquisition order across two code paths — even when each path looks
correct in isolation — is the reviewable defect, whether or not a
specific incident has ever surfaced it.

## Conditional: Free-Threaded Deployment Target

The checks below apply only when the target deployment actually runs a
free-threaded (`t`-suffixed) interpreter, or when a project's CI/packaging
explicitly targets one — see [Free-Threading (PEP 703 / PEP
779)](#free-threading-pep-703--pep-779-current-status) for why this can't
be evaluated in the abstract. This checklist is reasoned from PEP 703/779
plus the atomicity FAQ above, not drawn from a dedicated free-threading
linter category — none was found to exist yet. Label findings here as
free-threading-specific rather than implying a tool flagged them
mechanically.

Where a free-threaded build is in play, review should flag:

- **Reliance on the GIL for implicit atomicity of compound operations.**
  The [race-conditions guidance above](#race-conditions-and-gil-atomicity-boundaries)
  applies unconditionally, GIL or not — but its blast radius is larger
  under free-threading, since even the already-unsafe operations on the
  FAQ's non-atomic list now interleave at finer granularity and are more
  likely to actually manifest as a bug rather than stay a latent risk.
- **C-extension code that assumes GIL-serialized access** without its own
  locking. Code that was safe purely because the GIL guaranteed only one
  thread ran Python bytecode at a time loses that guarantee outright on a
  free-threaded build.
- **Design or comments that assume single-bytecode-thread execution.**
  Any place the codebase's own reasoning — in comments, docstrings, or
  architecture — leans on "only one thread runs Python bytecode at a
  time" is a claim that stops being true the moment the target
  interpreter is free-threaded, and is worth flagging even before finding
  a concrete race, since it signals the surrounding code wasn't written
  with that possibility in mind.

## Out of Scope

- **`multiprocessing` IPC/pickling correctness** (what can and can't cross
  a process boundary, `Manager` proxy object semantics) — a real, distinct
  topic that wasn't researched for this domain's baseline. Flagged as a
  candidate for a future addition rather than silently folded into the
  threading/asyncio guidance above; don't extend this document's
  authority to process-boundary correctness questions until that pass
  happens.
- **GIL as a throughput bottleneck / `multiprocessing` vs. `threading` for
  CPU-bound work** — [`performance.md`](../references/performance.md)'s
  lens ("is it fast enough"), not this domain's correctness lens.
- **Caching, connection pooling, N+1 queries, general async throughput
  optimization** — [`performance.md`](../references/performance.md),
  unrelated to correctness under concurrency.
- **Trio- or AnyIO-native structured-concurrency semantics beyond what
  Ruff's `ASYNC` rules mechanically check** (nurseries, cancel scopes as a
  model in their own right). `asyncio.TaskGroup` was prioritized as the
  researched primary because it's stdlib and ubiquitous from Python
  3.11+; a deep Trio/AnyIO-native pass is reasonable to defer to a future
  stack-specific overlay, the same way `testing.md` defers
  framework-specific test tooling.
- **Distributed-systems concurrency** (distributed locks, consensus,
  eventual consistency across services) — this domain is about
  concurrency correctness *within one process/codebase*, not across a
  distributed system.
- **`async`/`await` performance overhead, event-loop selection (`uvloop`
  vs. stdlib), or event-loop-per-thread architecture choices** —
  [`performance.md`](../references/performance.md)'s lens.

## Scoring Guide

Scored against tier-applicable checks only (per [Tier
Applicability](#tier-applicability)) — a script-tier project isn't
penalized for skipping the infrastructure-shaped checks the table marks
"No" for it, and the free-threading conditional only applies when the
deployment target makes it relevant.

- **10** — No blocking calls inside `async def`; every `create_task()`
  result is stored with a strong reference and has a way to surface its
  exceptions; shared mutable state is protected by explicit locks with no
  read-modify-write races; `with lock:` used throughout, no manual
  `acquire()`/`release()` pairs; new concurrent code uses `TaskGroup` with
  correct `except*` handling where applicable; Ruff's `ASYNC` rules pass
  clean; multi-lock ordering is consistent; if a free-threaded target
  applies, no GIL-atomicity reliance found.
- **8-9** — The above, with minor gaps: a fire-and-forget task or two
  without a done-callback, one `ASYNC` violation, a single lock-ordering
  inconsistency that hasn't caused an incident.
- **6-7** — Real gaps present but contained: a blocking call inside an
  `async def` on a non-hot path, a shared counter race in a low-traffic
  code path, `gather()` used where `TaskGroup` was clearly warranted but
  isn't actively causing harm, `ASYNC` rules not enabled but no severe
  violation surfaced by hand review.
- **4-5** — Widespread read-modify-write races on shared state; manual
  `acquire()`/`release()` pairs without `with lock:`, risking a leaked
  lock on an exception path; fire-and-forget tasks with no exception
  surfacing anywhere; a bare `except Exception:` silently swallowing a
  `TaskGroup`'s `ExceptionGroup`.
- **1-3** — Blocking calls inside `async def` on hot paths, stalling the
  event loop for every concurrent coroutine; self-deadlocking `Lock`
  re-acquisition; inconsistent multi-lock ordering with a demonstrated or
  clearly plausible deadlock; free-threaded target with C-extension code
  assuming GIL-serialized access and no locking of its own.

## Required Evidence in Findings

Each finding must include:

- **Severity** (Critical / Important / Minor)
- **Category** (one of: Race-Condition / Deadlock / Task-Lifecycle /
  Blocking-Call / Cancellation / Exception-Handling / Free-Threading)
- **Standard/tool reference** where applicable (PEP 703 / PEP 779 / PEP
  654, Ruff `ASYNC` rule code, the specific `threading`/`asyncio` docs
  section)
- **File and line number**
- **Interleaving scenario** — one concrete sentence describing the
  specific thread/task interleaving (or GC timing, for the fire-and-forget
  case) that produces the wrong result, not just "this could race"
- **Fix** — concrete remediation (wrap in `with lock:`, store the task
  reference and add a done callback, switch to `TaskGroup` with `except*`,
  establish a consistent lock-acquisition order, etc.)

## Sources

- <https://peps.python.org/pep-0703/> — free-threaded CPython proposal;
  Status: Final; Python-Version: 3.13; GIL remains default,
  `--disable-gil` is the opt-in build flag; Steering Council's conditional
  "gradual rollout" acceptance — retrieved 2026-08-24
- <https://peps.python.org/pep-0779/> — three-phase free-threading
  rollout; Status: Final; Phase II ("officially supported," Python 3.14)
  numeric entry criteria; explicit statement that Phase III (default
  build) timeline/criteria are undecided — retrieved 2026-08-24
- <https://docs.python.org/3/whatsnew/3.14.html> — corroborates PEP 779:
  "Free-threaded Python is officially supported"; PEP 703 implementation
  "finished"; measured single-threaded performance penalty "roughly
  5-10%" — retrieved 2026-08-24
- <https://docs.python.org/3.15/whatsnew/3.15.html> — version-pinned
  in-development page confirming draft status for Python 3.15.0rc1; no
  Phase III (default-build) announcement present; only free-threading
  addition is PEP 803 (Stable ABI for free-threaded builds, `abi3t`) —
  retrieved 2026-08-24
- <https://docs.python.org/3/library/asyncio-dev.html> — never-awaited-
  coroutine `RuntimeWarning`, exact trigger condition, debug mode's
  creation-traceback output — retrieved 2026-08-24
- <https://docs.astral.sh/ruff/rules/#flake8-async-async> — full current
  `flake8-async` (`ASYNC`) rule listing, 15 stable + 1 preview — retrieved
  2026-08-24
- <https://docs.astral.sh/ruff/rules/cancel-scope-no-checkpoint/>,
  `.../async-function-with-timeout/`, `.../async-busy-wait/`,
  `.../async-zero-sleep/`, `.../long-sleep-not-forever/` — individual
  `ASYNC` 1xx-range rule pages, fetched separately to verify per-rule
  asyncio-vs-trio/anyio applicability rather than inferring it from rule
  names — retrieved 2026-08-24
- <https://docs.python.org/3/library/asyncio-task.html> — `TaskGroup`
  cancellation-propagation and exception-aggregation behavior;
  `asyncio.create_task()`'s weak-reference warning and the documented
  `background_tasks` set-plus-`add_done_callback` fix — retrieved
  2026-08-24
- <https://docs.python.org/3/library/exceptions.html#exception-groups> —
  `ExceptionGroup`/`BaseExceptionGroup` (PEP 654) definition, `except*`
  matching semantics, `.subgroup()`/`.split()`/`.derive()` — retrieved
  2026-08-24
- <https://docs.python.org/3/faq/library.html#what-kinds-of-global-value-mutation-are-thread-safe>
  — enumerated atomic vs. non-atomic operations under the GIL; "When in
  doubt, use a mutex!" guidance — retrieved 2026-08-24
- <https://docs.python.org/3/library/threading.html#lock-objects> — Lock
  vs. RLock semantics, self-deadlock-on-reacquire behavior for plain
  `Lock`, RLock's nested-acquire support and unbalanced-release warning,
  `with lock:` as the recommended pattern — retrieved 2026-08-24
- `research/python-code-review/concurrency-async-correctness.md` (this
  repo) — the approved research baseline this reference was authored
  from, including source retrieval dates and the resolutions this
  document implements — read 2026-08-24
