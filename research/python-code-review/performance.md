# Baseline: Performance
Status: user-approved      Date: 2026-08-24

## In scope

- **N+1 query detection — Django** — impact: high — depth: section.
  `select_related()` (verified current against Django 6.1 docs, the latest
  official stable release as of this research) performs a SQL JOIN to fetch
  forward `ForeignKey` and (forward and reverse) `OneToOneField` relations
  in the same query, eliminating the extra per-access query. `prefetch_related()`
  issues a separate query per relation and joins results in Python — the
  correct tool for `ManyToManyField`, reverse-`ForeignKey`, and
  `GenericRelation`/`GenericForeignKey` relations that can't be expressed as
  a single JOIN; it also accepts a `Prefetch` object for custom querysets
  (ordering, filtering) and a `to_attr` target. **Correction against the
  original tool's baseline**: calling `select_related()` with **no
  arguments** — historically valid shorthand for "follow all forward
  relations" — is **deprecated as of Django 6.1** and raises `TypeError`
  starting Django 7.0; the review check should flag bare `select_related()`
  calls and require explicit field names, not just flag its *absence*.
  Review angle unchanged otherwise: a loop that accesses a FK/O2O/M2M
  attribute per iteration without the matching `select_related`/
  `prefetch_related` upstream is the N+1 pattern.

- **N+1 query detection — SQLAlchemy** — impact: high — depth: paragraph.
  `joinedload()` and `selectinload()` (verified current against SQLAlchemy
  2.0 docs, release 2.0.52, dated 2026-08-11) are both live, non-deprecated
  loader strategies for eager-loading relationships. Current guidance from
  SQLAlchemy's own docs: `selectinload()` is "the most simple and efficient
  way to eagerly load collections of objects" in most scenarios and is
  preferred over the older `subqueryload()`, which the docs now label a
  "Legacy Feature"; `joinedload()` remains the recommended choice for
  many-to-one relationships specifically. Review angle: flag lazy-loaded
  collection access inside a loop with no `selectinload`/`joinedload`
  upstream, and flag `subqueryload()` as a legacy-pattern nit where
  `selectinload()` would serve equally well.

- **Connection pool configuration — SQLAlchemy** — impact: high — depth:
  table. Verified current against SQLAlchemy 2.0 pooling docs (no
  deprecation/rename found), with defaults:

  | Parameter | Default | Purpose |
  |---|---|---|
  | `pool_size` | 5 | Max persistent connections kept in the pool |
  | `max_overflow` | 10 | Extra temporary connections allowed beyond `pool_size` under peak demand (discarded on return) |
  | `pool_timeout` | 30.0s | Wait time before giving up on a checkout |
  | `pool_recycle` | -1 (off) | Max connection age before forced recycle — needed for DBs/proxies that silently drop idle connections |
  | `pool_pre_ping` | False | Emit a lightweight ping before handing out a pooled connection, to catch and transparently recycle a connection that died server-side |

  Review angle: flag `create_engine()` calls with no explicit pool
  configuration in a service expected to run under sustained load — the
  default `pool_size=5` is a conservative stdlib default the docs
  themselves frame as suited to typical single-app use, so a web/enterprise
  service handling concurrent request volume above that default is worth a
  question rather than an automatic flag (this sizing judgment is reasoned,
  not stated as a threshold by the pooling doc itself). Separately, flag
  `pool_recycle`/`pool_pre_ping` both absent whenever the deployment target
  is known to silently drop idle connections (the pooling doc names stale/
  dropped connections generically without naming specific proxies or
  managed-DB providers) — this pair is the documented defense against
  exactly that failure mode.

- **Caching — stdlib default and its real trade-off** — impact: med —
  depth: paragraph. Verified against `functools` docs: `functools.cache`
  (added Python 3.9) is `lru_cache(maxsize=None)` — an *unbounded* cache,
  faster than `lru_cache` because it skips eviction bookkeeping, but with
  no size limit; `functools.lru_cache` (bounded, default `maxsize=128`)
  is the stdlib's own stated answer to unbounded growth: "the cache's size
  limit assures that the cache does not grow without bound on long-running
  processes such as web servers." Documented pitfalls worth naming in
  review: (1) caching a method includes `self` in the cache key, which can
  pin instances in memory for the process lifetime; (2) neither decorator
  is safe on functions with side effects, functions that must return a
  distinct mutable object per call, or impure functions (`time()`,
  `random()`); (3) both are documented thread-safe for the *cache
  structure*, but under concurrent first-calls "it is possible for the
  wrapped function to be called more than once if another thread makes an
  additional call before the initial call has been completed and cached" —
  a duplicate-work risk, not a correctness/data-race risk (the latter stays
  with the sibling Concurrency domain per the boundary note below). Review
  angle: `functools.cache` on anything reachable from a long-running
  process (web handler, worker loop) with an unbounded/attacker-influenced
  key space is a memory-growth risk and should prefer bounded `lru_cache`;
  `functools.cache`/`lru_cache` applied to a bound method is worth a nit
  for the pinning effect.

- **Profiling — naming a current standard, not just "profile it"** —
  impact: med — depth: section. Two tools cover complementary needs, both
  verified current:
  - `py-spy` (verified current: 0.4.2, released 2026-04-24) is a sampling
    profiler that attaches to an already-running process from the outside
    — "extremely low overhead" and safe against production code because it
    reads target-process memory rather than instrumenting it; supports
    Linux, macOS, Windows, FreeBSD, and CPython 3.3–3.14 (plus legacy
    2.3–2.7); its `record` subcommand produces flame graphs, `top` gives
    live per-function stats, `dump` gives a point-in-time stack snapshot
    per thread. Its no-code-changes, attach-to-live-process model makes it
    the fit for "why is this already-deployed service slow right now."
  - `cProfile` (Python stdlib, verified against current docs) is a
    deterministic profiler — it instruments every function call/return/
    exception event for precise per-function timing, at higher overhead
    than sampling. The docs' own caveat matters for review guidance: it's
    "not for benchmarking purposes" (use `timeit` for that) and
    specifically distorts Python-vs-C-extension comparisons, since it
    instruments Python-level calls but not C-level ones. Its fit is local,
    repeatable investigation of a specific slow function during
    development, not always-on production monitoring.
  Review angle for "profiling evidence cited" (carried from the original
  tool's Minor tier): a PR justifying a non-obvious optimization should
  name which of these (or an equivalent) produced the before/after numbers,
  not just assert "this is faster."

- **Caching — the other two original-tool bullets, given explicit homes**
  — impact: med — depth: checklist. The original tool's Caching section
  had three items; the bounded-vs-unbounded discussion above covers the
  first ("external API/service calls have caching strategy"). The other
  two, disposed of explicitly rather than silently dropped:
  - *Cache invalidation logic present where caching is used* — stays in
    this domain. It's a direct corollary of the same bounded/unbounded
    trade-off above: a cache with no invalidation path serves stale data
    indefinitely (for `functools.cache`/`lru_cache`, until process
    restart or explicit `.cache_clear()`), which is a correctness-of-data
    concern but one that only exists *because* caching was chosen for
    performance — so it stays with the mechanism that created it. Review
    angle: a cache (in-process or external, e.g. Redis) with no TTL, no
    explicit invalidation call on the underlying data's write path, and no
    documented staleness tolerance is worth flagging.
  - *No caching of user-specific or security-sensitive data without
    expiry* — **moves to the Security domain.** Reasoned, not sourced
    this session: caching sensitive data without expiry is a data-exposure
    risk (stale authorization state, leaked-across-users cache keys), and
    Security is the domain whose lens is "can this leak or be misused," not
    "is this fast." Flag for the user to confirm Security's baseline
    actually picks this up rather than it falling into the gap between the
    two domains.

- **Memory & data structures** — impact: med — depth: checklist (durable
  CPython facts, not re-verified this session per the pacing note — mutable
  default arguments, list-vs-generator materialization, and string
  concatenation in loops are long-standing, uncontested language behavior):
  - Mutable default arguments (`def f(items=[])`) — the default is
    evaluated once at function-definition time and shared across calls;
    use `None` with an internal `if items is None: items = []`.
  - Large/unbounded data processed via generators/iterators rather than
    fully materialized lists, where the full set is never needed at once.
  - String concatenation in a loop (`s += chunk`) — prefer `"".join(...)`
    or `io.StringIO` to avoid repeated reallocation.
  - Data structure choice matches access pattern: `set`/`dict` for
    membership or key lookup (O(1) average) vs. `list` (O(n) scan).

- **Unbounded queries without LIMIT** — impact: high — depth: checklist
  (carried from the original tool's Critical tier, not independently
  re-sourced this session — see Open Questions). A query with no bound
  (`.all()` iterated in full, no `LIMIT`/slicing) against a table that can
  grow unboundedly is an OOM/latency risk that scales with data, not code
  changes — flag loops or endpoints materializing a full queryset with no
  page size, slice, or `.iterator()` use for large tables.

- **Missing database indexes on frequently filtered columns** — impact:
  med — depth: checklist (carried from the original tool's Important tier,
  kept principle-only rather than naming engine-specific tooling — see
  Explicitly out of scope for why, and Open Questions for the follow-up
  call). Review angle: a `filter()`/`WHERE` clause on a column that is
  neither the primary key nor visibly indexed, especially inside a loop or
  a frequently hit code path, is worth flagging for the author to confirm
  an index exists — without engine-specific tooling (Postgres `EXPLAIN
  ANALYZE`, MySQL's optimizer trace) this stays a "worth checking" flag,
  not an automated verdict.

- **Style/idiom minor items carried from the original tool** — impact: low
  — depth: checklist (durable, uncontroversial Python idiom preferences;
  not independently re-sourced this session, carried forward rather than
  silently dropped): list comprehensions preferred over `map()`/`filter()`
  with lambdas; `any()`/`all()` preferred over manual loop-and-flag
  patterns; f-strings preferred over `.format()`/`%` for non-security
  string building.

- **Concurrency, narrowed to throughput/GIL-as-bottleneck** — impact:
  high — depth: paragraph. Per the domain-scoping doc's explicit boundary
  (`research/python-code-review-domain-scoping.md`, "Boundary with
  Performance"), this domain keeps only the throughput question: is the
  chosen concurrency model *capable* of speeding up this workload at all.
  `threading` used for CPU-bound work is a real throughput defect under
  CPython's GIL — the GIL serializes bytecode execution across threads in
  a single process, so CPU-bound threaded code does not get wall-clock
  speedup from adding threads (this is durable, uncontested CPython
  behavior, not re-verified via a fresh fetch this session — the pacing
  note explicitly names it as not needing re-verification); the fix is
  `multiprocessing`, a C extension releasing the GIL, or a genuinely
  I/O-bound workload where `threading` is appropriate because threads
  spend most of their time blocked on I/O with the GIL released. **Moved
  to the sibling Concurrency & Async Correctness domain, not dropped**:
  blocking calls inside `async def` functions, forgotten `await`,
  fire-and-forget tasks garbage-collected mid-flight, race conditions,
  deadlocks, and shared-mutable-state thread-safety — these are
  correctness-under-concurrency questions, not throughput questions, and
  the scoping doc assigns them to that domain explicitly so the two
  domains don't duplicate checks.

- **Tier applicability** — impact: high — depth: table. Carried forward
  from the original tool's table (`original-tool/review-domains/
  performance.md`), adjusted to move the async-correctness row out (now
  the sibling domain's) and keep only the throughput-framed concurrency row:

  | Check | Script | Web | Enterprise |
  |---|---|---|---|
  | Mutable default arguments | Yes | Yes | Yes |
  | Algorithmic/data-structure issues | Yes | Yes | Yes |
  | `threading` vs `multiprocessing` for CPU-bound work | Yes | Yes | Yes |
  | N+1 queries (Django/SQLAlchemy) | No | Yes | Yes |
  | Connection pool configuration | No | Yes | Yes |
  | Caching strategy present (bounded vs. unbounded) | No | Yes | Yes |
  | Profiling evidence cited for non-obvious optimizations | No | Yes | Yes |

## Explicitly out of scope

- **Blocking calls inside `async def` functions** — moved to the sibling
  Concurrency & Async Correctness domain per the scoping doc's explicit
  boundary language. This item existed in the original tool's Critical
  tier for Performance; it is a correctness concern (an async function that
  blocks the event loop breaks concurrent execution for every other task on
  that loop, which is a correctness/liveness bug, not a throughput
  measurement), so it is re-homed rather than dropped. Flag this explicitly
  during authoring so the two domains' review checklists don't both claim
  it.
- **Race conditions, deadlocks, and shared-mutable-state thread-safety** —
  same rationale and destination as above; these are "is it correct under
  concurrent execution," the sibling domain's stated lens, not "is it
  fast."
- **Free-threading (PEP 703) thread-safety obligations** — sibling
  Concurrency domain's territory per the scoping doc (new locking
  obligations, borrowed-reference/destructor-timing changes under
  `--disable-gil` builds); out of scope here even though it's
  GIL-adjacent, because the failure mode is correctness, not throughput.
- **Caching of user-specific or security-sensitive data without expiry**
  — moved to the Security domain; see the Caching sub-section above for
  the reasoning. Named here explicitly so the move isn't silently lost
  between the two domains' baselines.
- **Load/throughput testing tools** (locust, k6-style) — this is "does the
  system meet a throughput target under simulated load," which is
  Testing's lens (already excluded there in `research/python-code-review/
  testing.md`'s own out-of-scope list) rather than a static-review check
  this domain can perform by reading code.

## Sources

- https://docs.djangoproject.com/en/stable/ref/models/querysets/#select-related
  (resolves to `/en/6.1/` as of retrieval, the current stable release) —
  `select_related()`/`prefetch_related()` current behavior, relation-type
  coverage (FK, O2O forward/reverse for select_related; M2M, reverse-FK,
  GenericRelation for prefetch_related), `Prefetch`/`to_attr` — retrieved
  2026-08-24
- https://docs.djangoproject.com/en/dev/internals/deprecation/ — confirms
  bare `select_related()` (no field arguments) is deprecated as of Django
  6.1, raising `TypeError` starting Django 7.0; confirms Django 6.1 is the
  current stable release referenced — retrieved 2026-08-24
- https://www.djangoproject.com/download/ — confirms Django 6.1 as "the
  latest official version" as of this research — retrieved 2026-08-24
- https://docs.sqlalchemy.org/en/20/orm/queryguide/relationships.html —
  `joinedload()`/`selectinload()` current status, `selectinload()`
  preferred over legacy `subqueryload()`, `joinedload()` preferred for
  many-to-one; confirms SQLAlchemy 2.0.52 (2026-08-11) as the version this
  doc covers — retrieved 2026-08-24
- https://docs.sqlalchemy.org/en/20/core/pooling.html — connection pool
  parameter names and defaults (`pool_size`=5, `max_overflow`=10,
  `pool_timeout`=30.0, `pool_recycle`=-1, `pool_pre_ping`=False), confirmed
  current/non-deprecated — retrieved 2026-08-24
- https://docs.python.org/3/library/functools.html#functools.cache —
  `functools.cache` (Python 3.9+) as `lru_cache(maxsize=None)`, unbounded-
  growth warning, method-caching `self`-pinning caveat, thread-safety
  caveat (duplicate first-call execution under concurrent access) —
  retrieved 2026-08-24
- https://github.com/benfred/py-spy — py-spy identity (sampling profiler,
  attaches to running process, no code changes), platform/CPython version
  support (3.3–3.14), `record`/`top`/`dump` subcommands, low-overhead/
  production-safe framing — retrieved 2026-08-24
- https://pypi.org/project/py-spy/ — current version 0.4.2, released
  2026-04-24 — retrieved 2026-08-24
- https://docs.python.org/3/library/profile.html — `cProfile` as
  deterministic profiler with "reasonable overhead," explicit
  not-for-benchmarking caveat and Python-vs-C-extension timing distortion
  warning, conceptual deterministic-vs-statistical profiling distinction —
  retrieved 2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — exact
  Performance/Concurrency boundary language ("Performance keeps
  throughput/caching/connection-pooling/GIL-as-throughput-bottleneck; this
  domain takes correctness bugs under concurrency") — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/performance.md`
  (this repo) — starting-point domain content, tier-applicability table
  pattern, verified/expanded/corrected per above — read 2026-08-24
- `research/python-code-review/testing.md` (this repo) — rigor/format bar
  (sourcing density, honest trade-offs, explicit out-of-scope-with-reason
  sections, Open Questions) and confirmation that load/throughput testing
  is already excluded from Testing's own scope — read 2026-08-24

## Open questions for the user

- **Unbounded-queries-without-LIMIT and missing-index checks** were carried
  forward from the original tool's Critical/Important tiers without fresh
  primary-source verification this session — confirm whether these should
  be re-verified (e.g. Django's own docs on `QuerySet` laziness/slicing,
  or an engine-specific indexing doc) before authoring locks them in, or
  whether the carryover-with-honesty-label already in `## In scope` is
  sufficient.
- **Database indexing strategy stays principle-only** (no engine-specific
  tooling named), consistent with the scoping doc's rejection of
  framework/DB-specific overlays at the domain level — confirm this is the
  right cutoff, or whether a future `research/stacks/` supplement should
  own DB-engine-specific indexing guidance the way it will own
  framework-specific test tooling per Testing's baseline.
- **Connection pool sizing guidance is reasoned, not doc-stated** — the
  claim that default `pool_size=5` often needs raising for web/enterprise
  services under concurrent load is this research's own judgment, not a
  threshold SQLAlchemy's pooling doc itself states. Confirm this framing is
  acceptable to promote into skill content as labeled reasoning, or drop it
  in favor of a plainer "no explicit pool config present" flag with no
  sizing opinion attached.
- **Caching of sensitive data without expiry was moved to Security** on
  this research's own reasoning (not sourced from either domain's existing
  material) — confirm Security's baseline actually picks this item up, so
  it doesn't silently fall into the gap between the two domains' authored
  skills.
- **Scoring Guide will need rewriting on re-home, not carried forward
  as-is.** The original tool's Scoring Guide (`original-tool/review-domains/
  performance.md`, not reproduced in this baseline since scoring wasn't in
  the requested scope) scores directly on "sync-in-async" and "CPU work in
  threads" — both now the sibling Concurrency & Async Correctness domain's
  checks per the boundary in this baseline. If the authored skill's scoring
  guide is drafted by lightly editing the original, it risks double-counting
  those items across both domains' scores. Flagging so authoring rebuilds
  the rubric from this baseline's actual in-scope list rather than patching
  the old one.

## Resolutions (Checkpoint B review, 2026-08-24)

- **Unbounded-queries/missing-index re-verification**: deferred to
  authoring time, per the standing verify-before-publish policy.
- **DB indexing strategy stays principle-only**: confirmed correct cutoff.
- **Connection pool sizing reasoning**: keep as labeled reasoning, not
  dropped — matches this repo's established "judgment call, labeled as
  such" convention used throughout the series.
- **Caching-sensitive-data-without-expiry handoff to Security**:
  confirmed captured — an addendum was added to `security.md`'s PII
  section documenting the handoff explicitly (see that file).
- **Scoring Guide rewrite**: noted for authoring — both this domain and
  the sibling Concurrency domain need their scoring rubric rebuilt from
  each baseline's actual in-scope list, not patched from the original
  tool's, to avoid double-counting re-homed items.

## Target file(s) + estimated length

- skills/python-code-review/references/performance.md — est. 180-220 lines
  (seven sourced sub-topics at paragraph/section/table depth, one
  tier-applicability table, plus scoring-guide and required-evidence
  sections mirroring the original tool's per-domain structure once
  authored — those two sections are not part of this baseline itself).
