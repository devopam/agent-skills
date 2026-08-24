# Performance

This is the reference `python-code-review` applies when judging whether
Python code is going to be *fast enough* and *stay* fast enough as data and
load grow: database access patterns, connection-pool sizing, caching
trade-offs, memory/data-structure choices, and whether a chosen concurrency
model is even capable of the speedup its author expects from it. It asks a
narrower question than it might sound like: is the code's resource usage
proportionate to the work it's actually doing, or is it paying a cost —
extra queries, unbounded memory growth, a concurrency model fighting the
interpreter — that a straightforward alternative would avoid.

Two adjacent lenses this domain deliberately does not duplicate. First,
**concurrency correctness**: whether an `async def` blocks the event loop,
whether two tasks race on shared state, whether a lock is missing — those
are "is it correct under concurrent execution" questions, not "is it fast"
questions, and they live in the sibling
[Concurrency & Async Correctness](../references/concurrency-async-correctness.md)
domain. This domain keeps only the *throughput* question for concurrency:
is the chosen model (threads vs. processes vs. async) structurally capable
of speeding up the workload at all. Second, **caching sensitive data
without expiry**: a cache with no TTL is a performance-domain mechanism
(caching exists to make things fast) but an unbounded-TTL cache holding
user-specific or security-sensitive data is a data-exposure risk, which is
[Security](../references/security.md)'s lens, not this one's — that finding
is handed off there rather than reviewed twice; see
[Caching](#caching-bounded-vs-unbounded-and-invalidation) below for exactly
where the line falls.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [N+1 Queries — Django](#n1-queries--django)
- [N+1 Queries — SQLAlchemy](#n1-queries--sqlalchemy)
- [Connection Pool Configuration — SQLAlchemy](#connection-pool-configuration--sqlalchemy)
- [Caching: Bounded vs. Unbounded, and Invalidation](#caching-bounded-vs-unbounded-and-invalidation)
- [Profiling: Naming a Current Standard](#profiling-naming-a-current-standard)
- [Memory & Data Structures](#memory--data-structures)
- [Unbounded Queries Without LIMIT](#unbounded-queries-without-limit)
- [Missing Database Indexes](#missing-database-indexes)
- [Style/Idiom Minor Items](#styleidiom-minor-items)
- [Concurrency: Throughput and the GIL](#concurrency-throughput-and-the-gil)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Required Evidence in Findings](#required-evidence-in-findings)
- [Sources](#sources)

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Mutable default arguments | Yes | Yes | Yes |
| Algorithmic/data-structure issues (generators, `set`/`dict` vs. `list`, string concatenation) | Yes | Yes | Yes |
| `threading` vs. `multiprocessing` for CPU-bound work | Yes | Yes | Yes |
| Style/idiom minors (comprehensions, `any()`/`all()`, f-strings) | Yes | Yes | Yes |
| N+1 queries (Django `select_related`/`prefetch_related`, SQLAlchemy `joinedload`/`selectinload`) | No | Yes | Yes |
| Connection pool configuration | No | Yes | Yes |
| Caching strategy present (bounded vs. unbounded, invalidation path) | No | Yes | Yes |
| Unbounded queries without `LIMIT`/pagination | No | Yes | Yes |
| Missing indexes on frequently filtered columns | No | Yes | Yes |
| Profiling evidence cited for non-obvious optimizations | No | Yes | Yes |

A script-tier project still benefits from the checks that cost nothing to
apply regardless of scale: mutable default arguments are a bug whether or
not the script ever serves concurrent traffic, and `threading` on CPU-bound
work fails to speed anything up on a single laptop exactly as it does in
production. Everything that only matters once there's a database under
sustained concurrent load — N+1 detection, pool sizing, caching,
unbounded-query risk, indexing — is gated to web/enterprise, the same
split `testing.md` and `security.md` use for their own infrastructure-
dependent checks.

## N+1 Queries — Django

`select_related()` performs a SQL `JOIN` to fetch forward `ForeignKey` and
`OneToOneField` relations (both forward and reverse for the latter) in the
same query as the base queryset, eliminating the extra per-access query a
naive loop would otherwise issue. `prefetch_related()` issues a separate
query per relation and joins the results in Python — the correct tool for
`ManyToManyField`, reverse-`ForeignKey`, and `GenericRelation`/
`GenericForeignKey` relations, none of which can be expressed as a single
SQL `JOIN`. It also accepts a `Prefetch` object for a custom queryset
(ordering, filtering) targeting a `to_attr`.

**Bare `select_related()` is deprecated.** Calling `select_related()` with
no arguments was historically valid shorthand for "follow every forward
relation." As of Django 6.1 (the current stable release), that bare call is
deprecated and will raise `TypeError` starting in Django 7.0. A review check
that only looks for the *absence* of `select_related`/`prefetch_related` is
now incomplete — it should also flag bare `select_related()` calls still
present in the codebase and require explicit field names.

Otherwise the review angle is unchanged: a loop that accesses a
FK/O2O/M2M attribute per iteration with no matching `select_related`/
`prefetch_related` upstream on the queryset is the N+1 pattern, and it
scales with row count — a query that looks fine against ten test rows can
become hundreds of queries in production.

## N+1 Queries — SQLAlchemy

`joinedload()` and `selectinload()` are both current, non-deprecated
eager-loading strategies in SQLAlchemy 2.0. Per SQLAlchemy's own docs,
`selectinload()` is "the most simple and efficient way to eagerly load
collections of objects" in most scenarios and is preferred over the older
`subqueryload()`, which current docs now label a "Legacy Feature."
`joinedload()` remains the recommended choice specifically for many-to-one
relationships, where a single `JOIN` genuinely is the cheaper plan.

**Review angle:** flag lazy-loaded collection access inside a loop with no
`selectinload()`/`joinedload()` upstream on the query. Flag `subqueryload()`
usage as a legacy-pattern nit, not a defect — it still works, but
`selectinload()` would serve equally well in the scenarios it's used for
and is the currently-recommended default.

**The same pattern shows up without an ORM in the picture at all.** Raw SQL
issued one statement per loop iteration — an `INSERT`/`UPDATE`/`SELECT`
executed inside a `for` loop instead of a single batched statement (a
multi-row `INSERT`, a `WHERE id IN (...)`, `executemany()`) — is the
N+1 pattern's underlying mechanism (one round trip per row instead of one
round trip total) independent of whether an ORM's relationship-loading API
is involved. Flag it the same way, whether the driver is `psycopg`,
`asyncpg`, or a raw DB-API cursor.

## Connection Pool Configuration — SQLAlchemy

SQLAlchemy's connection pool exposes five parameters, all current and
non-deprecated:

| Parameter | Default | Purpose |
|---|---|---|
| `pool_size` | 5 | Max persistent connections kept in the pool |
| `max_overflow` | 10 | Extra temporary connections allowed beyond `pool_size` under peak demand (discarded on return) |
| `pool_timeout` | 30.0s | Wait time before giving up on a checkout |
| `pool_recycle` | -1 (off) | Max connection age before forced recycle — needed for DBs/proxies that silently drop idle connections |
| `pool_pre_ping` | False | Emit a lightweight ping before handing out a pooled connection, to catch and transparently recycle a connection that died server-side |

The default `pool_size=5` is a conservative stdlib default that SQLAlchemy's
own docs frame as suited to typical single-application use, not a threshold
the docs themselves declare too low for anything larger. This document's own
judgment, offered as a labeled opinion rather than a documented rule: a
web or enterprise-tier service handling concurrent request volume above
that default is worth a *question* to the author about sizing, not an
automatic flag — `create_engine()` with no explicit pool configuration at
all, in a service expected to run under sustained load, is the thing
actually worth flagging.

Separately — and this part *is* the pooling docs' own stated purpose for
the parameters, not a sizing opinion — flag `pool_recycle` and
`pool_pre_ping` both absent whenever the deployment target is known to
silently drop idle connections (a managed database or a proxy in front of
one; the pooling docs describe the failure mode generically without naming
specific products). That pair is the documented defense against exactly
that failure: a pooled connection that died server-side while idle, handed
back out to application code as if it were live.

**A correctly-sized pool only helps if connections actually come back to
it.** A connection checked out without a context manager (`with
engine.connect() as conn:` or the ORM session equivalent) and never
explicitly closed on every code path — including exception paths — is
never returned to the pool; under load this exhausts `pool_size` +
`max_overflow` regardless of how well those numbers were chosen, and the
service starts timing out on checkout (`pool_timeout`) instead of failing
fast on the actual error. The same "hold it open past its useful lifetime"
mistake shows up one layer up the stack with HTTP clients: creating a new
`requests.Session()`/`httpx.Client()` per request instead of constructing
one and reusing it discards connection-level keep-alive on every single
call. Flag both as an extension of the same pooling review, not a separate
category — the pool configuration table above is meaningless if the
connections it manages aren't returned, and an HTTP client rebuilt per call
is paying the equivalent cost by never having a pool to return to at all.

## Caching: Bounded vs. Unbounded, and Invalidation

`functools.cache` (added in Python 3.9) is `lru_cache(maxsize=None)` — an
*unbounded* cache. It's faster than `lru_cache` because it skips eviction
bookkeeping entirely, but that speed comes with no size limit.
`functools.lru_cache` (bounded, default `maxsize=128`) is the stdlib's own
stated answer to unbounded growth: its docs note that "the cache's size
limit assures that the cache does not grow without bound on long-running
processes such as web servers." That framing is the review angle in one
sentence — `functools.cache` is the right default for a short-lived script
or a genuinely small, fixed key space; it's a memory-growth risk on
anything reachable from a long-running process (a web handler, a worker
loop) whose key space is unbounded or attacker-influenced, where bounded
`lru_cache` is the safer default.

Before bounded-vs-unbounded is even a question, check for the more basic
finding it presupposes: a code path that repeatedly calls an external API
or service with no caching in front of it *at any size* is the baseline
case this whole section answers, and it's worth flagging on its own before
the bounded/unbounded trade-off is relevant at all.

Three further documented pitfalls worth naming in review once some form of
caching is in place, all from the same `functools` docs:

1. **Caching a bound method includes `self` in the cache key.** That pins
   the instance in memory for as long as the cache entry survives — for
   `functools.cache`, that's the process lifetime unless something calls
   `.cache_clear()`. A cached method on a class with many short-lived
   instances is a slow leak.
2. **Neither decorator is safe on impure functions.** A cache is a memory
   of a return value keyed on arguments; that's wrong for a function with
   side effects, one that must return a distinct mutable object per call,
   or one whose output depends on more than its arguments (`time()`,
   `random()`).
3. **Concurrent first calls can duplicate work, not corrupt state.** Both
   decorators are documented thread-safe for the cache *structure* itself,
   but under concurrent access to an uncached key, "it is possible for the
   wrapped function to be called more than once if another thread makes an
   additional call before the initial call has been completed and cached."
   That's a wasted-work risk worth naming here — it is not the
   correctness/data-race risk that shared-mutable-state review owns, which
   is why it stays in this domain rather than moving to
   [Concurrency & Async Correctness](../references/concurrency-async-correctness.md).

**Cache invalidation is this domain's concern too, as a direct corollary of
the bounded/unbounded trade-off above.** A cache — in-process
(`functools.cache`/`lru_cache`) or external (Redis and similar) — with no
TTL, no invalidation call on the underlying data's write path, and no
documented staleness tolerance serves stale data indefinitely: for the
stdlib decorators, until process restart or an explicit `.cache_clear()`.
That's a data-correctness problem, but one that exists only *because*
caching was chosen for performance, so review of it stays with the
mechanism that created it rather than moving elsewhere.

**One caching finding does move**, though: caching *user-specific or
security-sensitive* data with no expiry is a data-exposure risk (stale
authorization state, or a cache key that leaks data across users), which is
a "can this leak or be misused" question — Security's lens, not
performance's. That finding is captured in
[`security.md`](../references/security.md)'s PII section rather than here;
this file's caching checks stop at "is there a bounded size and an
invalidation path," and hand the sensitive-data case to Security so it
isn't reviewed twice.

## Profiling: Naming a Current Standard

"Profile it" isn't an actionable review comment on its own — two current
tools cover complementary needs, and a PR justifying a non-obvious
optimization should name one of them (or an equivalent) rather than just
asserting "this is faster."

**`py-spy`** (current: 0.4.2) is a sampling profiler that attaches to an
already-running process from the outside. It reads target-process memory
rather than instrumenting it, which is what makes it "extremely low
overhead" and safe to run against production code — it supports Linux,
macOS, Windows, and FreeBSD, and CPython 3.3–3.14 (plus legacy 2.3–2.7).
Its `record` subcommand produces flame graphs, `top` gives live
per-function stats, and `dump` gives a point-in-time per-thread stack
snapshot. Its no-code-changes, attach-to-a-live-process model makes it the
fit for "why is this already-deployed service slow right now."

**`cProfile`** (Python stdlib) is a deterministic profiler — it instruments
every function call/return/exception event for precise per-function timing,
at meaningfully higher overhead than a sampler. Its own docs carry a caveat
that matters directly for review guidance: it's "not for benchmarking
purposes" (that's `timeit`'s job), and it specifically distorts
Python-vs-C-extension comparisons, since it instruments Python-level calls
but not C-level ones. Its fit is local, repeatable investigation of one
slow function during development, not always-on production monitoring.

**Review angle:** a PR that claims a performance win without naming which
tool (or equivalent) produced the before/after numbers is asserting, not
demonstrating — worth a nit even when the optimization itself looks
reasonable.

## Memory & Data Structures

Durable, uncontested CPython facts — long-standing language behavior, not
something that shifts release to release:

- **Mutable default arguments.** `def f(items=[])` evaluates the default
  once, at function-definition time, and shares that same object across
  every call that doesn't pass its own. Use `None` as the default with an
  internal `if items is None: items = []`.
- **Materialization vs. streaming.** Large or unbounded data processed via
  a generator or iterator, not a fully materialized list, wherever the full
  set is never actually needed in memory at once.
- **String concatenation in a loop.** `s += chunk` repeated across
  iterations forces repeated reallocation; `"".join(...)` or
  `io.StringIO` avoid it.
- **Data structure matches access pattern.** `set`/`dict` for membership or
  key lookup (O(1) average) instead of a `list` (O(n) scan) doing the same
  job.

## Unbounded Queries Without LIMIT

A query with no bound — a full `.all()` iterated to completion, no
`LIMIT`, no slice — against a table that can grow without bound is an
OOM/latency risk that scales with *data volume*, not with any code change:
a query that's harmless today against a thousand rows becomes a production
incident against ten million, with no diff to point at. Flag a loop or an
endpoint that materializes a full queryset with no page size, no slice, and
no `.iterator()` use against a table with unbounded growth potential.

## Missing Database Indexes

A `filter()`/`WHERE` clause on a column that is neither the primary key nor
visibly indexed — especially inside a loop or on a frequently hit code
path — is worth flagging for the author to confirm an index actually
exists. This stays a principle-level, "worth checking" flag rather than an
automated verdict: confirming it definitively needs engine-specific
tooling (Postgres `EXPLAIN ANALYZE`, MySQL's optimizer trace) that a static
code-review pass doesn't have access to, and this domain deliberately
doesn't overlay engine-specific tooling at the reference-doc level — the
same cutoff `testing.md` draws around framework-specific test tooling.

## Style/Idiom Minor Items

Durable, uncontroversial Python idiom preferences, carried at low severity:
list comprehensions over `map()`/`filter()` with lambdas; `any()`/`all()`
over a manual loop-and-flag pattern; f-strings over `.format()`/`%` for
non-security string building (see
[`security.md`](../references/security.md) for the security-relevant
string-building cases, e.g. SQL/shell construction, which are a different
and much higher-severity concern than style).

## Concurrency: Throughput and the GIL

This domain keeps exactly one concurrency question: is the chosen
concurrency model *capable* of speeding up this workload at all. `threading`
used for CPU-bound work is a real throughput defect under CPython's GIL —
the GIL serializes bytecode execution across threads in a single process,
so CPU-bound threaded code gets no wall-clock speedup from adding more
threads. This is durable, uncontested CPython behavior. The fix is one of:
`multiprocessing` (separate processes, separate GILs), a C extension that
releases the GIL for the hot path, or recognizing that the workload is
actually I/O-bound, in which case `threading` is the right tool — threads
spend most of their time blocked on I/O with the GIL released, and *do*
get real concurrency there.

**Everything else concurrency-shaped lives in the sibling domain, not
here.** Blocking calls inside `async def` functions, a forgotten `await`, a
fire-and-forget task garbage-collected mid-flight, race conditions,
deadlocks, shared-mutable-state thread-safety, and free-threading (PEP 703)
locking obligations under `--disable-gil` builds are all "is this correct
under concurrent execution" questions, not "is this fast" questions — see
[Concurrency & Async Correctness](../references/concurrency-async-correctness.md)
for all of them. Treat this boundary as a hard one when reviewing: a
`threading`-for-CPU-bound finding belongs here; an async function that
blocks the event loop belongs there, even though both involve `threading`-
or `asyncio`-adjacent code.

## Out of Scope

- **Blocking calls inside `async def` functions.** An async function that
  blocks the event loop breaks concurrent execution for every other task
  scheduled on that loop — a correctness/liveness bug, not a throughput
  measurement. Owned by
  [Concurrency & Async Correctness](../references/concurrency-async-correctness.md).
- **Race conditions, deadlocks, and shared-mutable-state thread-safety.**
  Same destination and the same reason: "is it correct under concurrent
  execution" is that domain's stated lens, not this one's.
- **Free-threading (PEP 703) thread-safety obligations** — new locking
  requirements and borrowed-reference/destructor-timing changes under
  `--disable-gil` builds. GIL-adjacent, but the failure mode is
  correctness, not throughput, so it belongs to the sibling domain too.
- **Caching user-specific or security-sensitive data without expiry** —
  handed off to [Security](../references/security.md); see
  [Caching](#caching-bounded-vs-unbounded-and-invalidation) above for where
  the boundary falls and why.
- **Load/throughput testing tools** (locust, k6-style). "Does the system
  meet a throughput target under simulated load" is Testing's lens, not a
  static-review check this domain performs by reading code — already
  excluded from `testing.md`'s own scope for the same reason.
- **Engine-specific indexing tooling** (Postgres `EXPLAIN ANALYZE`, MySQL's
  optimizer trace) and **framework-specific database tooling** generally —
  this domain stays principle-only here; a future stack-specific overlay is
  the right home for engine-specific depth.

## Scoring Guide

Scored against this domain's actual in-scope checks only. `threading`-for-
CPU-bound-work is scored here because it's a throughput question; blocking
calls in async, races, and deadlocks are **not** scored here — they're
scored by the sibling Concurrency & Async Correctness domain, and counting
them in both places would double-penalize the same defect.

- **10** — No N+1 patterns (Django or SQLAlchemy). Connection pool
  explicitly configured for the service's actual load, or the default is
  demonstrably sufficient. Caching, where used, is bounded or has a
  documented invalidation path. No `threading` applied to CPU-bound work.
  No unbounded queries against growth-prone tables. No mutable default
  arguments. Non-obvious optimizations cite profiling evidence.
- **8-9** — The above, with minor gaps: one missing pool-tuning parameter
  on a service that would benefit from it, a cache with no invalidation
  path but bounded size, a `subqueryload()` left in place where
  `selectinload()` would be preferred.
- **6-7** — One or two real N+1 patterns, or a `create_engine()` call with
  no pool configuration under sustained load, with no critical issues
  otherwise; style/idiom nits present but not pervasive.
- **4-5** — Multiple N+1 patterns across the codebase, an unbounded cache
  on a long-running process with an attacker-influenced key space, or
  `threading` used for genuinely CPU-bound work with no
  `multiprocessing`/C-extension alternative in sight.
- **1-3** — Unbounded queries against large tables with no `LIMIT`/paging
  anywhere, bare deprecated `select_related()` calls left uncorrected,
  mutable default arguments causing observable cross-call state bugs, or
  CPU-bound work parallelized with `threading` as the sole strategy with no
  awareness the GIL prevents any speedup.

## Required Evidence in Findings

Each finding in this domain must include:

- **Severity** — Critical / Important / Minor.
- **Category** — one of: N+1 / Connection-Pooling / Caching / Memory /
  Data-Structure / Concurrency-Throughput / Indexing / Unbounded-Query /
  Profiling / Idiom.
- **File and line number.**
- **Cost mechanism** — one sentence on *why* it's slow or memory-hungry
  (e.g. "N+1: one query per iteration of a loop over N rows, no
  `select_related`/`prefetch_related` upstream"), not just a rule citation.
- **Fix** — a concrete, code-level remediation, not a restatement of the
  finding as advice.

## Sources

- <https://docs.djangoproject.com/en/stable/ref/models/querysets/#select-related>
  (resolves to `/en/6.1/` as of retrieval, the current stable release) —
  `select_related()`/`prefetch_related()` current behavior, relation-type
  coverage (FK, O2O forward/reverse for `select_related`; M2M, reverse-FK,
  `GenericRelation` for `prefetch_related`), `Prefetch`/`to_attr` —
  retrieved 2026-08-24
- <https://docs.djangoproject.com/en/dev/internals/deprecation/> — confirms
  bare `select_related()` (no field arguments) is deprecated as of Django
  6.1, raising `TypeError` starting Django 7.0 — retrieved 2026-08-24
- <https://www.djangoproject.com/download/> — confirms Django 6.1 as the
  latest official stable release as of this research — retrieved 2026-08-24
- <https://docs.sqlalchemy.org/en/20/orm/queryguide/relationships.html> —
  `joinedload()`/`selectinload()` current status, `selectinload()`
  preferred over legacy `subqueryload()`, `joinedload()` preferred for
  many-to-one relationships; confirms SQLAlchemy 2.0.52 (2026-08-11) as the
  version this doc covers — retrieved 2026-08-24
- <https://docs.sqlalchemy.org/en/20/core/pooling.html> — connection pool
  parameter names and defaults (`pool_size`=5, `max_overflow`=10,
  `pool_timeout`=30.0, `pool_recycle`=-1, `pool_pre_ping`=False), confirmed
  current and non-deprecated — retrieved 2026-08-24
- <https://docs.python.org/3/library/functools.html#functools.cache> —
  `functools.cache` (Python 3.9+) as `lru_cache(maxsize=None)`,
  unbounded-growth warning, method-caching `self`-pinning caveat, and the
  thread-safety caveat on duplicate first-call execution — retrieved
  2026-08-24
- <https://github.com/benfred/py-spy> — `py-spy` identity (sampling
  profiler, attaches to a running process, no code changes),
  platform/CPython version support (3.3–3.14), `record`/`top`/`dump`
  subcommands, low-overhead/production-safe framing — retrieved 2026-08-24
- <https://pypi.org/project/py-spy/> — current version 0.4.2, released
  2026-04-24 — retrieved 2026-08-24
- <https://docs.python.org/3/library/profile.html> — `cProfile` as a
  deterministic profiler with "reasonable overhead," the explicit
  not-for-benchmarking caveat, and the Python-vs-C-extension timing
  distortion warning — retrieved 2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — the exact
  Performance/Concurrency boundary language this file implements
  ("Performance keeps throughput/caching/connection-pooling/
  GIL-as-throughput-bottleneck; [Concurrency & Async Correctness] takes
  correctness bugs under concurrency") — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/performance.md`
  (this repo) — starting-point domain content and tier-applicability table
  pattern, verified/corrected/re-scoped per the sources above — read
  2026-08-24
- `research/python-code-review/performance.md` (this repo) — the
  user-approved research baseline this reference was authored from,
  including the Checkpoint B resolutions this document implements — read
  2026-08-24
- [`security.md`](../references/security.md) (this skill) — confirms the
  caching-sensitive-data-without-expiry handoff is captured in that
  domain's PII section, so it isn't duplicated here — read 2026-08-24
