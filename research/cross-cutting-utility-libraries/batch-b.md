# Baseline: Cross-Cutting Utility Libraries (Batch B) — Date/time, local caching, terminal output, testing utilities, environment detection, background scheduling
Status: draft      Date: 2026-08-31      Snapshot date: 2026-08-31

This is one of two parallel batches researching
`references/cross-cutting-utility-libraries.md` — a **new** reference doc,
distinct in shape from every existing `references/stacks/<category>.md` or
`references/preferred-libraries/<category>.md`. Those are category-specific
(one stack category → one doc). This doc is **cross-domain**: a single file
naming application-level utility libraries that recur across *every*
category, read at Phase 6 of `project-incubation`'s flow in addition to
whichever category-specific doc(s) apply. A parallel agent is researching
`batch-a.md` in this same directory — not touched here.

**The bar every entry below was held to**, per the task brief's own framing
(the user's verbatim example: `smart_open` abstracting away
local/S3/GCS/Azure file access, `dotenv` abstracting secrets management
across local/cloud): a library earns a slot because it eliminates a
specific, concrete, named class of boilerplate or bug — not because it is
merely popular. Every row below states what breaks or what gets tedious
*without* the library, anchored on the library's own documentation
(direct-fetched) wherever one exists, not paraphrased secondary-blog
content.

## Local precedent

Checked directly this pass, not assumed:

- **`/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/backend/app/requirements.txt`**
  (read in full, 190 packages): contains **`cachetools==7.0.5`** (Domain
  2 — in-process caching, Python) and **`apscheduler==3.11.2`** (Domain 6 —
  background scheduling, Python) — both are real, current local evidence
  for two of this batch's six recommendations, not hypothetical. It also
  contains `python-dateutil==2.9.0.post0`, `pytz==2023.3.post1`,
  `tzdata==2023.3`, `tzlocal==5.3.1`, and `colorama==0.4.6`/
  `termcolor==3.3.0` — i.e. this real production codebase reaches for
  **stdlib-adjacent, lower-level** date/timezone and terminal-color
  libraries rather than `pendulum`/`arrow`/`rich`. That is itself an honest
  data point: it is not using a Domain-1 or Domain-3 library from this
  batch, only the more primitive tools those libraries wrap. `click==8.3.1`
  is also present (CLI framework — out of scope here per the task's own
  scope-boundary note, already owned by
  `developer-tooling-libraries.md`). **No `dotenv` grep was needed here**
  since `.env`/secrets handling is Batch A's domain, not this batch's — not
  independently checked in this pass.
- **`/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/frontend/package.json`**
  (read in full): a React 19 + Vite + TanStack Query + antd application.
  **None** of this batch's npm-side domains appear: no `date-fns`/`luxon`/
  `dayjs`, no `lru-cache`/`node-cache`, no `chalk`/`ora`/`cli-table3` (this
  is a browser app, not a CLI/script, so terminal-formatting libraries are
  correctly absent — see Domain 3's scope note), no `@faker-js/faker` or
  time-mocking library in `devDependencies` (no visible frontend test suite
  in this `package.json` at all — only `eslint`, no `vitest`/`jest`), no
  `cross-env`/`is-ci`, no `node-cron`/`node-schedule` (a frontend SPA has no
  server-side scheduling concern). This is an honest **absence**, not an
  oversight in this research pass — worth stating plainly rather than
  fabricating a match that isn't there.

## Domain 1: Date/time handling — impact: high — depth: table + narrative

**The stdlib footgun this whole domain exists to fix**: Python's
`datetime` distinguishes "naive" (no timezone) and "aware" (has timezone)
objects at runtime only — comparing or subtracting a naive and an aware
datetime raises `TypeError` at the point of use, not at write time, and
the type system cannot statically prevent the mistake. Separately, stdlib
`datetime` arithmetic near a DST transition can silently produce wrong
wall-clock results because, per direct-fetched confirmation from
`whenever`'s own README (below), stdlib "only consider[s] DST when
calculations involve *two* timezones" — a design decision, not a bug, that
still surprises people doing single-timezone arithmetic across a DST
boundary.

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Pendulum** (`python-pendulum/pendulum`) | Python | Drop-in-feeling replacement for stdlib `datetime` with correct DST-aware arithmetic and a fluent API (`.add(hours=8)`, human-readable diffs like `in 2 hours`) built in, rather than reaching for `pytz`/`dateutil` boilerplate to get the same correctness | MIT | The most established "just replace `datetime` and get correctness" option; still widely used. **Honest 2026 caveat, directly verified rather than taken from `whenever`'s own framing**: this pass independently re-fetched Pendulum's own release history and confirmed only two releases (`3.1.0`, `3.2.0`) landed between `3.0.0` (Dec 2023) and this snapshot — a real, verifiable slowdown in release cadence, not just a competitor's marketing claim | Direct GitHub fetch: 6,671 stars, 446 forks, 267 open issues, pushed 2026-08-20 (repo itself is active — issues/PRs still land — but the *release* cadence has genuinely slowed); direct PyPI fetch: v3.2.0; direct GitHub releases fetch confirms the 2-releases-in-2.5-years pattern independently |
| **Arrow** (`arrow-py/arrow`) | Python | Similar goal to Pendulum — a friendlier, more consistent API over stdlib `datetime`/`dateutil`, humanized output, easy timezone shifting | Apache-2.0 | The older, still-active alternative to Pendulum; per `whenever`'s own README (see below, cited as the competing library's own comparative framing, not independently re-derived) it "keeps the same footguns" as stdlib around naive/aware typing, which is the honest reason it's listed third rather than first in this table, not because it's unmaintained | Direct GitHub fetch: 9,050 stars, 775 forks, 190 open issues, pushed 2026-06-22 |
| **`whenever`** (`ariebovenberg/whenever`) — a genuinely new, worth-naming entrant, not yet a default | Python | The only library of the three that fixes *both* pain points at once: DST-correct arithmetic (like Pendulum) *and* type-checker-enforceable naive-vs-aware distinction (via distinct `PlainDateTime`/`ZonedDateTime`/etc. types) that Pendulum and Arrow don't provide. Optional Rust extension for speed, with a pure-Python fallback for environments that can't compile extensions | MIT | **Verified via direct fetch of the library's own README, not assumed**: it explicitly frames itself against both competitors — "keeps the same footguns" (of Arrow) and Pendulum's "long maintenance slump with only two releases in the last four years" (a claim this pass independently corroborated above, not just trusted). Its own published benchmark (1M iterations) shows it outperforming both Arrow and Pendulum on parse/normalize/compare/shift/timezone-change/format. **Still pre-1.0** — the README states directly: "Holding off on 1.0 a little longer so we can get the API just right for the long term... Until 1.0, the API may change with minor releases." Named here as a real, current, worth-tracking option for a new project willing to accept pre-1.0 API-stability risk in exchange for correctness guarantees the other two don't offer — not yet the default recommendation for that reason | Direct GitHub fetch: 2,400 stars, 37 forks, 17 open issues, pushed 2026-08-24 (very active for its size); direct PyPI fetch: v0.10.5 (pre-1.0, confirms the README's own framing) |
| stdlib `datetime` | Python | Zero-dependency baseline; adequate when a project never crosses DST boundaries in arithmetic and doesn't need cross-timezone humanized diffs — named as the explicit "when none of the above is warranted" answer, matching this repo's own convention of naming the zero-dependency stdlib option (e.g. `argparse` in the CLI-framework table) rather than omitting it | PSF License | The right default until a project actually hits one of the two footguns above; reaching for Pendulum/Arrow/`whenever` preemptively on every project is exactly the kind of non-differentiated "just add a dependency" habit the task brief warns against | N/A — ships with CPython |
| **date-fns** (`date-fns/date-fns`) | npm/TS | Tree-shakeable, purely functional (no mutation, no chaining state) date manipulation — a different design philosophy from Moment's mutable-object legacy, letting bundlers eliminate unused functions | **License field returns `null` on GitHub's API and the repo has no root `LICENSE.md`/`LICENSE` file reachable at the `main` branch path this pass** — flagged as an honest gap rather than guessed; the npm package page states MIT, but that was not independently re-confirmed against a primary license file this pass | By a wide margin the highest current npm download volume of the three date libraries researched — the practical default for a new TS project doing date arithmetic without needing full IANA-timezone-object modeling | Direct GitHub fetch: 36,645 stars, 2,004 forks, 1,003 open issues, pushed 2026-08-30; direct npm-downloads-API fetch: **100.05M/week** |
| **Luxon** (`moment/luxon`) | npm/TS | The Moment.js team's own designated successor — immutable objects (unlike Moment) plus first-class `Intl`-backed timezone/locale handling via `DateTime`/`Duration`/`Interval` classes, closer in spirit to the eventual native `Temporal` API's object model than date-fns's plain-function approach | MIT | The right choice when a project needs richer timezone-aware object modeling (not just function-based math) and wants an API shape that will translate more directly to `Temporal` once that's the norm | Direct GitHub fetch: 16,449 stars, 796 forks, 180 open issues, pushed 2026-08-09; direct npm-downloads-API fetch: 39.35M/week |
| **Day.js** (`iamkun/dayjs`) | npm/TS | A near-drop-in, much smaller (~2KB) Moment.js-API-compatible replacement — the pain it eliminates is specifically **bundle size** for a project already writing Moment-style chained calls (`.format()`, `.add()`) that doesn't want date-fns's functional rewrite or Luxon's different object model | MIT | Highest star count of the three (reflects Moment's legacy popularity migrating to it), the pragmatic choice for a Moment-shaped codebase migrating off the now-legacy-mode Moment.js with minimal rewrite | Direct GitHub fetch: 48,664 stars, 2,469 forks, 1,308 open issues, pushed 2026-08-31 (very active); direct npm-downloads-API fetch: 70.09M/week |

**The native `Temporal` API — verified current status, not assumed, since
this changes the recommendation meaningfully.** Two primary sources
direct-fetched this pass:

- `github.com/tc39/proposal-temporal` (direct fetch): the proposal is at
  **Stage 4**, TC39's final stage — meaning it will be merged into
  ECMA-262/ECMA-402. Per the repo's own tracked shipping dates: Firefox 139
  shipped support in May 2025, Chrome 144 followed in January 2026, and
  **Node.js 26 shipped it in May 2026**.
- `nodejs.org/en/blog/release/v26.0.0` (direct fetch of the official
  release notes): confirms in the release's own words — *"The Temporal API
  is now enabled by default in Node.js 26"* — and the semver-major commit
  log entry reads *"build: enable Temporal by default"* (PR #61806).
- `developer.mozilla.org` (direct fetch, MDN compat data, page dated
  2025-12-08): flags Temporal as **"Limited availability... not Baseline
  because it does not work in some of the most widely-used browsers"** as
  of that page's own last-update date — i.e. Safari support was not yet
  confirmed shipped as of this pass, an honest gap in cross-browser
  coverage even though the spec itself is finalized and two major engines
  plus Node 26 already ship it.

**Practical read for this doc**: `Temporal` is no longer a distant
proposal — it is Stage 4 and live in Node 26 and two major browsers — but
it is **not yet safe as the default recommendation for a library needing
broad browser-runtime compatibility** given the still-incomplete
cross-browser picture (Safari status unconfirmed this pass) and that most
production Node deployments in 2026 are not yet uniformly on Node 26+.
date-fns/Luxon/Day.js remain the practical 2026 recommendation for now,
with `Temporal` flagged as the thing to plan a migration path toward once
runtime-version constraints allow it — not a "wait and see" dismissal, a
"verified real, not yet universally deployable" status.

## Domain 2: Local/in-process caching — impact: high — depth: table + a real severity finding

Distinct from a distributed cache (Redis/Memcached), which is an
infrastructure choice, not an application-level library choice — that
boundary is drawn explicitly rather than blurred.

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **cachetools** (`tkem/cachetools`) | Python | Per direct fetch of its own README: stdlib `functools.lru_cache` offers only **one** eviction policy (pure LRU) and **no TTL support**. cachetools' own worked example — `TTLCache(maxsize=1024, ttl=600)` to "cache weather data for no longer than ten minutes" — is exactly the concrete, named pain point the task brief asks for: data that must expire on a wall-clock timer, which `lru_cache` structurally cannot express | MIT | **Real local precedent**: `ubi-csr-tmf`'s backend `requirements.txt` pins `cachetools==7.0.5` directly — confirmed by direct read this pass, not assumed. In-memory-only by design (no persistence across restarts) — the deliberate discriminator against the row below | Direct GitHub fetch: 2,775 stars, 204 forks, only 1 open issue (aggressively triaged), pushed 2026-08-31 (very active); direct PyPI fetch: v7.1.7; direct PyPI-downloads fetch: 52.9M/week |
| **diskcache** (`grantjenks/python-diskcache`) — **named with a serious, direct-fetch-confirmed caution, not a clean recommendation** | Python | Per direct fetch of its own README: solves the specific pain of a cache that must **survive process restarts** and **not be bounded by available RAM** — its own stated framing is that "gigabytes of empty space is left on disks as processes vie for memory," i.e. the pain it eliminates is exactly "I need a cache bigger than I can afford to keep in memory, and it must not evaporate on redeploy" — a genuinely different discriminator from cachetools' in-memory-only model | Apache-2.0 (confirmed via direct `LICENSE` file fetch) | **A real, current, load-bearing finding from this pass, not carried over from memory**: (1) the repo's last commit is **2024-03-03** — over 2.5 years stale relative to this snapshot, confirmed via direct `gh api .../commits` fetch, a materially worse staleness signal than any tool flagged in the `developer-tooling-libraries.md` precedent doc; (2) **an unpatched, moderate-severity CVE exists against it**: `CVE-2025-69872` (GitHub Security Advisory `GHSA-w8v5-vhqr-4h9v`, direct-fetched), disclosed February 2026 — DiskCache uses Python `pickle` for serialization by default, and "an attacker with write access to the cache directory can achieve arbitrary code execution when a victim application reads from the cache." **No patched version exists as of this pass.** Open PRs addressing it (`#3166`-adjacent discussion, "Restrict pickle deserialization to safe types," opened 2026-07-03, 4 comments, unmerged) sit unresolved. **Recommendation for the authored doc**: name diskcache as the only real Python disk-persisted local-cache library found, but with an explicit "unmaintained + unpatched CVE" caution box, and name `joblib.Memory` (below) as a viable alternative for the specific sub-case of memoizing expensive deterministic function calls (not a general drop-in cache-object replacement) | Direct GitHub fetch: 2,905 stars, 179 forks, 75 open issues, last commit 2024-03-03 (stale), `pushed_at` 2024-08-10; direct PyPI fetch: v5.6.3 (the CVE's own advisory confirms "through 5.6.3" is affected — i.e. the latest published version is the vulnerable one) |
| **`joblib.Memory`** (`joblib/joblib`) — named as a narrower alternative, not a like-for-like replacement | Python | A different-shaped tool worth naming precisely because diskcache's maintenance state is a real problem: `joblib.Memory` disk-caches the *results of deterministic function calls* (decorator-based, `memory.cache(fn)`), a narrower use case than diskcache's general key-value cache-object API, but a genuinely actively maintained one | BSD-3-Clause | Not a full substitute for diskcache's `Cache`/`FanoutCache` general-purpose API — named honestly as the closest actively-maintained alternative for the "memoize an expensive deterministic call to disk" sub-case specifically, not oversold as solving the same problem | Direct GitHub fetch: 4,388 stars, 474 forks, 438 open issues, pushed **2026-08-31** (same day as this pass — a stark contrast to diskcache's 2024-03-03 last commit) |
| **lru-cache** (`isaacs/node-lru-cache`) | npm/TS | Per direct fetch of its own README: a "cache object that deletes the least-recently-used items," with configurable `maxSize`/`sizeCalculation` for memory-bounded (not just count-bounded) eviction and TTL support — the same class of pain cachetools solves in Python, ported to the npm ecosystem, and stdlib JS has no equivalent at all (no `functools.lru_cache` analog exists in JS) | BlueOak-1.0.0 (a real, current, less-common OSI-approved license — not a licensing red flag, just worth naming precisely rather than assuming MIT) | By a wide margin the dominant npm option by download volume; authored by the same maintainer (`isaacs`) as `npm` itself, a strong maintenance-pedigree signal | Direct GitHub fetch: 5,911 stars, 375 forks, only 3 open issues, pushed 2026-07-07; direct npm-downloads-API fetch: **562.6M/week** |
| node-cache (`node-cache/node-cache`) | npm/TS | A simpler, object-literal-style in-memory TTL cache — less configurable than lru-cache (no size-based eviction, count-based only) but a lower-ceremony API for simple TTL-only use cases | MIT | Named for completeness, but the honest current-adoption gap versus lru-cache is stark and worth stating plainly rather than presenting the two as peers | Direct GitHub fetch: 2,372 stars, 146 forks, 76 open issues, **last pushed 2024-06-04** — over 2 years stale, a real maintenance gap; direct npm-downloads-API fetch: 5.36M/week — **lru-cache outpulls it roughly 105:1** on weekly downloads, the starkest adoption gap of any pair in this entire batch |

## Domain 3: Terminal output formatting — impact: med-high — depth: table + scope note

**Scope-boundary discipline, stated precisely per the task brief's
instruction**: this domain is *not* a CLI argument-parsing framework
(Click/Typer/Commander/Clap — already owned by
[`developer-tooling-libraries.md`](../../skills/project-incubation/references/preferred-libraries/developer-tooling-libraries.md)'s
CLI-framework section, read directly this pass to confirm). The concern
here is narrower and different in kind: making a script's or app's
**output** — tables, progress bars, colored/styled text — legible, usable
inside *any* Python/Node process (a data pipeline's log lines, a one-off
script's summary table, a long-running job's progress bar) regardless of
whether that process has any argument-parsing structure at all. A script
with zero CLI arguments can still have this need; a CLI framework does not
itself solve it.

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Rich** (`Textualize/rich`) | Python | Per direct fetch of Rich's own docs: "writing rich text (with color and style) to the terminal, and... displaying advanced content such as tables, markdown, and syntax highlighted code" — eliminates hand-rolled ANSI escape-code management, manual table-column alignment math, and separate libraries for progress bars vs. colored text vs. tracebacks vs. pretty-printed data structures, unifying all of it under one API. Its own docs specifically call out its value "as a debugging aid by pretty printing and syntax highlighting data structures" — a distinct, concrete use beyond just "pretty CLI output" | MIT | **Confirmed dominant, not assumed**: this is genuinely the extremely-dominant option the task brief anticipated — no other Python terminal-formatting library in this pass's research came close on stars or download volume. Also the basis for Textual (TUI framework) and `rich-click`, extending its reach beyond standalone use | Direct GitHub fetch: 57,290 stars, 2,319 forks, 372 open issues, pushed 2026-06-23; direct PyPI fetch: v15.0.0; direct PyPI-downloads fetch: **99.07M/week** |
| **chalk** (`chalk/chalk`) | npm/TS | Per direct fetch of its own README, tagline: **"Terminal string styling done right"** — chainable/nestable style composition (`chalk.red.bold('text')`) instead of manually concatenating raw ANSI escape sequences and tracking reset codes | MIT | The npm-ecosystem default for colored terminal text specifically — the single highest-download library in this table by a wide margin | Direct GitHub fetch: 23,308 stars, 1,026 forks, 0 open issues, pushed 2026-07-26; direct npm-downloads-API fetch: **505.5M/week** |
| **ora** (`sindresorhus/ora`) | npm/TS | Terminal spinners for long-running async operations — the pain it eliminates is hand-rolling a manual `setInterval`-driven cursor-position/frame-cycling loop plus terminal-width/TTY-detection edge cases (falling back gracefully when stdout isn't a TTY, e.g. in CI logs) | MIT | The de facto standard spinner library in the npm ecosystem, from the same prolific maintainer (`sindresorhus`) as many foundational Node utility packages | Direct GitHub fetch: 9,742 stars, 292 forks, 0 open issues, pushed 2026-06-22; direct npm-downloads-API fetch: 90.55M/week |
| **cli-table3** (`cli-table/cli-table3`) | npm/TS | Renders aligned, bordered ASCII/Unicode tables from row/column data — eliminates manual column-width calculation and Unicode-box-drawing-character alignment (which breaks easily with manual string padding, especially with variable-width content) | MIT | The maintained continuation of the original (now-stale) `cli-table` — named specifically as the "3" fork because it's the actively current one | Direct GitHub fetch: 632 stars, 50 forks, 26 open issues, pushed 2026-04-19; direct npm-downloads-API fetch: 34.4M/week — smaller absolute volume than chalk/ora, consistent with "table rendering" being a narrower need than "any colored output" or "any spinner," not a maintenance-signal concern |

## Domain 4: Testing utilities beyond a test runner — impact: high — depth: table + a real ownership-history finding

Scoped to fixtures/fakes/time-freezing — explicitly **not** the test
runner/framework itself (pytest, Jest, etc.), which is out of scope here.

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **factory_boy** (`FactoryBoy/factory_boy`) | Python | Eliminates hand-writing repetitive object-construction boilerplate in every test (`User(name="test1", email="test1@test.com", ...)` repeated with minor variations across dozens of tests) — declarative `Factory` classes generate valid, varied test objects (often ORM model instances) with sensible defaults and easy per-test overrides, plus sequences for guaranteed-unique fields | MIT | The established Python standard specifically for **test-data object construction**, distinct in purpose from Faker (below) which generates realistic-looking *field values*, not whole domain objects — the two are complementary, not competing, a distinction worth stating precisely since they're often confused | Direct GitHub fetch: 3,805 stars, 421 forks, 211 open issues, pushed 2026-01-01 (about 8 months stale relative to this pass — worth noting, though issue/PR activity and its role as a stable, feature-complete library make this a lower-concern staleness signal than diskcache's, not independently further investigated this pass); direct PyPI fetch: v3.3.3 |
| **Faker** (`joke2k/faker`, PyPI: `Faker`) | Python | Eliminates hand-writing (or worse, hand-copy-pasting) realistic-looking fake names/emails/addresses/company names/etc. for test fixtures or seed data — without this, tests either use obviously-fake placeholder strings (`"testtesttest"`) that don't exercise realistic-length/format edge cases, or developers write ad hoc random-string generators themselves | MIT | The dominant Python fake-data generator; complements factory_boy directly (factory_boy's `Faker` provider integration is a first-class, documented pairing) | Direct GitHub fetch: 19,384 stars, 2,112 forks, 33 open issues, pushed 2026-08-21 (active); direct PyPI fetch: v40.37.0 |
| **time-machine** (`adamchainz/time-machine`) — **now the currently-preferred option, a real transition confirmed this pass** | Python | Per direct fetch of the library's own comparison docs (`time-machine.readthedocs.io/.../comparison.html`): eliminates two concrete, named freezegun limitations — **(1) speed**: freezegun's mocking cost "is proportional to the number of loaded modules" (i.e. it gets slower as a codebase grows), which time-machine avoids; **(2) coverage correctness**: freezegun "won't find functions that have been 'hidden' inside arbitrary objects, such as class-level attributes," whereas time-machine "mocks the standard library functions everywhere they may be referenced" — a real correctness gap, not just a performance one | MIT | **Verified as a genuine, documented transition, not assumed from general reputation**: time-machine's own docs frame this as a direct, named upgrade path ("Migrating from freezegun or libfaketime" is a dedicated docs page). Honest limitation also directly confirmed from the same page: time-machine "only works with CPython" (excludes PyPy) and cannot mock "other libraries using date/time system calls" outside the stdlib surface it patches | Direct GitHub fetch: 994 stars, 52 forks, 7 open issues, pushed 2026-08-28 (active); direct PyPI fetch: v3.5.0 |
| freezegun (`spulec/freezegun`) — **named to flag the transition, not as the current default** | Python | Still the more widely-known/historically-dominant time-freezing library, and still functional — named specifically so the authored doc can state the time-machine transition explicitly rather than silently dropping freezegun and leaving a reader who's used it confused about why it's absent | Apache-2.0 | **A real staleness signal, matching this batch's other "legacy but still widely pulled" pattern** (diskcache, and the precedent doc's setuptools/bump2version examples): last pushed **2025-08-19** — about a year stale relative to this snapshot — while still pulling **11.5M/week** on PyPI, more raw weekly downloads than time-machine (no comparable direct download figure captured for time-machine this pass; rate-limited by `pypistats.org` after repeated fetches — flagged honestly as an incomplete data point rather than fabricated) | Direct GitHub fetch: 4,524 stars, 301 forks, 167 open issues, pushed 2025-08-19 (stale); direct PyPI-downloads fetch: 11.5M/week |
| **@faker-js/faker** (`faker-js/faker`) — **the current, actively-maintained package; verify this precisely, there was a real incident** | npm/TS | Same pain as Python's Faker: realistic fake data generation for tests/fixtures/demos, ported to TS with full type definitions | MIT (confirmed via direct `LICENSE`/`package.json` fetch) | **A real, verified ownership situation, not a rumor**: the original `faker.js` npm package's own author deliberately corrupted/unpublished it in **January 2022** (the well-documented "Marak Squires" incident, alongside the same author's `colors.js` sabotage). Direct fetch of `@faker-js/faker`'s current README confirms the community is aware of and addresses this directly — it has a dedicated section titled **"What happened to the original faker.js?"** linking to the team's own January 14, 2022 update. `@faker-js/faker` is the actively maintained community-governed successor under the `faker-js` GitHub org, not a random fork — this is the correct current package to recommend, not the original `faker`/`faker.js` npm name | Direct GitHub fetch: 15,477 stars, 1,117 forks, 98 open issues, pushed **2026-08-31** (same day as this pass, very active); direct npm-downloads-API fetch: 18.56M/week |
| **`@sinonjs/fake-timers`** (`sinonjs/fake-timers`) | npm/TS | The standalone time-mocking engine that also powers Sinon's `sinon.useFakeTimers()` — eliminates manually stubbing `setTimeout`/`setInterval`/`Date.now()`/`process.hrtime()` by hand in tests that need deterministic control over time-dependent code | BSD-3-Clause | Named as the standalone package specifically because it can be used directly (without pulling in all of Sinon's mocking/stubbing/spying surface) when only time control is needed — a narrower, more precise dependency than adopting the full Sinon toolkit for this one purpose | Direct GitHub fetch: 859 stars, 124 forks, 15 open issues, pushed 2026-08-20; direct npm-downloads-API fetch: 70.84M/week (this high figure reflects it being a transitive dependency of the much more widely used full `sinon` package, not 70M/week of standalone direct adoption — worth reading with that caveat rather than at face value) |

## Domain 5: Environment/runtime feature detection — impact: low-med (honest finding: this is a real but narrow need) — depth: paragraphs + table

**Python: verified honestly that this is largely a non-issue, not forced
into a table.** Python's own `sys`/`platform`/`os` stdlib modules
(`sys.platform`, `platform.system()`, `os.name`, `sys.version_info`) cover
the realistic cross-cutting needs directly and are the idiomatic answer —
this pass found **no genuinely current, widely-adopted third-party Python
library** whose entire purpose is "detect what environment/runtime you're
running in" the way `is-ci`/`cross-env` fill that role in npm. Named
honestly as a **non-slot** rather than forcing a padded entry to satisfy
the task's structure — the task brief itself explicitly asked for this
honesty ("don't force an entry if the honest finding is 'stdlib is
sufficient here'").

**npm: a genuinely mixed, worth-stating-precisely picture** — one tool
here is archived, which is itself informative:

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here (or a caveat) | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **cross-env** (`kentcdodds/cross-env`) — **named with a direct, verified caveat: the repo is archived** | npm/TS | Windows `cmd.exe`/PowerShell and POSIX shells use different syntax for setting an inline environment variable in an npm script (`set FOO=bar && cmd` on Windows vs. `FOO=bar cmd` on POSIX) — cross-env normalizes this to one syntax that works on both, in `package.json` `"scripts"` entries | MIT | **A real, directly-verified status change worth flagging plainly**: `gh api repos/kentcdodds/cross-env` confirms `"archived": true`, last pushed 2025-11-16. Per direct fetch of the repo's own README and the linked issue (#257) explaining the "done" status: the maintainer states cross-env "is 'done' as in it does what it does and there's no need for new features," and will only "fix security/critical bugs and keep the Node.js support up-to-date" — **this pass found the repo has since gone further and been fully archived**, a stronger status than the README's own "done, maintenance-only" framing suggested at the time it was written, worth noting as the framing has evolved past what the README itself says. **Still the practically necessary tool for this problem** — no actively-maintained alternative solving exactly this npm-script cross-platform env-var syntax problem was found this pass; an archived-but-still-functional, still-massively-downloaded tool, the same "legacy inertia, still correct to use" pattern as setuptools in the precedent doc, except here there genuinely isn't a live replacement to point to instead | Direct GitHub fetch: 6,523 stars, 267 forks, **`archived: true`**, pushed 2025-11-16; direct npm-downloads-API fetch: 25.33M/week (still very high despite archival — confirms continued real-world reliance) |
| **is-ci** (`watson/is-ci`) | npm/TS | A single boolean check — "is this process running inside a CI environment?" — checking dozens of CI-specific environment variables (`CI`, `GITHUB_ACTIONS`, `GITLAB_CI`, `JENKINS_URL`, etc.) by hand in every project that needs to branch behavior (e.g., skip an interactive prompt, disable a spinner, use a different reporter) is real, tedious, and easy to get incompletely right | MIT | Still genuinely relevant in 2026 — CI-detection remains a real per-project need (interactive CLIs, test reporters, install scripts all commonly branch on it) and no stdlib/platform-native equivalent exists; its very high, still-current download volume is itself the honest current-relevance signal, distinct from cross-env's archived status above | Direct GitHub fetch: 401 stars, 14 forks, 0 open issues, pushed 2024-12-08 (about 1.75 years stale relative to this snapshot — a small, single-purpose utility whose staleness likely reflects "nothing left to add" rather than abandonment, similar to chalk's own 0-open-issues pattern, though this wasn't independently further investigated); direct npm-downloads-API fetch: 21.83M/week |

## Domain 6: Lightweight background/scheduled task execution — impact: med-high — depth: table + scope note

**Scope-boundary discipline, stated precisely per the task brief's
instruction**: read the opening scope section of
[`integration-event-driven-systems.md`](../../skills/project-incubation/references/stacks/integration-event-driven-systems.md)
directly this pass — that doc's territory is full message-broker/pub-sub
architecture (Kafka, RabbitMQ, SNS/SQS, delivery semantics, sagas,
dead-letter queues, stream processing). This domain is scoped narrowly to
the genuinely different concern of **in-process or single-node periodic/
deferred task execution** — a periodic cleanup job, a deferred email send,
a nightly report — running inside one application process or one worker,
with no message broker, no cross-service delivery guarantee, and no
distributed-consumer-group concept. The dividing line: the moment a task
needs to be reliably handed off *between* services or survive a
node-level crash with guaranteed redelivery, it has crossed into
Integration & Event-Driven Systems' territory, not this domain's.

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **APScheduler** (`agronholm/apscheduler`) | Python | Eliminates hand-rolling a `while True: time.sleep(...)` polling loop or a bare `threading.Timer` chain to run a function on a cron-like schedule or at a specific future time, inside a single Python process — provides cron-style, interval, and one-off "run at" triggers with a persistent job store option (SQLite/Redis-backed) so scheduled jobs can survive a process restart without needing a separate broker | MIT | **Real local precedent**: `ubi-csr-tmf`'s backend `requirements.txt` pins `apscheduler==3.11.2` directly, confirmed by direct read this pass. **Current maintenance state, precisely verified rather than assumed**: the stable `3.x` line is still being actively released (`3.11.3` released 2026-06-28, direct-fetched from the repo's own GitHub releases) — this is not a stalled project. A `4.0.0` line exists but is still in alpha (`4.0.0a6`, released 2025-04-27, direct-fetched) — **the honest read is that `3.x` remains the correct current recommendation for a new project in 2026**, not `4.0.0a6`, since the alpha line hasn't reached a stable release over a year after that alpha tag | Direct GitHub fetch: 7,619 stars, 778 forks, 54 open issues, pushed 2026-08-30 (very active); direct PyPI fetch: v3.11.3; direct PyPI-downloads fetch: 7.59M/week |
| **node-cron** (`node-cron/node-cron`) | npm/TS | Eliminates hand-writing cron-expression parsing/scheduling logic — takes a standard cron string (`"0 0 * * *"`) and a callback, runs it in-process on that schedule, no external scheduler daemon needed | ISC | The lighter-weight, narrowly-cron-syntax-focused option of the two npm choices researched — the better fit when the need is genuinely "run this on a cron schedule," nothing more | Direct GitHub fetch: 3,278 stars, 283 forks, 4 open issues, pushed 2026-08-19 (active); direct npm-downloads-API fetch: 5.33M/week |
| node-schedule (`node-schedule/node-schedule`) — **named with a staleness caveat** | npm/TS | Broader scheduling vocabulary than node-cron: supports cron syntax *and* recurrence rules *and* one-off `Date`-object-based future scheduling in a single API — the pain it eliminates specifically is needing more than pure cron-syntax expressiveness (e.g., "every 2nd Tuesday" or "at this exact future timestamp") without hand-rolling the date-math | MIT | Higher star count than node-cron (reflects longer history/broader past adoption) but a **real, direct-fetch-confirmed staleness gap**: last pushed **2025-06-19** — over a year stale relative to this snapshot — while pulling fewer weekly downloads than the more actively maintained node-cron. The honest recommendation: node-cron for new projects unless node-schedule's specific richer-recurrence-rule API is a hard requirement, in which case its staleness should be weighed explicitly, not glossed over | Direct GitHub fetch: 9,206 stars, 501 forks, 174 open issues, pushed 2025-06-19 (stale); direct npm-downloads-API fetch: 4.41M/week — **lower than node-cron's**, despite node-schedule's higher star count, a real adoption-vs-reputation gap worth stating plainly |
| stdlib `sched` / plain `threading.Timer` (Python) | Python | Named as the explicit zero-dependency floor, same pattern as `argparse`/stdlib `datetime` elsewhere in this batch: adequate for a single one-off deferred callback in a script that doesn't warrant a dependency, but does not provide cron-expression parsing, persistent job stores, or reliable interval scheduling across process restarts — the reason APScheduler is the practical default the moment a project needs more than one trivial deferred call | PSF License | The right floor to name explicitly rather than silently pushing every project toward APScheduler by default | N/A — ships with CPython |

## Explicitly out of scope

- **CLI argument-parsing frameworks** (Click, Typer, Commander.js, Clap) —
  fully owned by `developer-tooling-libraries.md`'s CLI-framework section,
  read directly this pass to confirm the boundary. Domain 3 above
  (terminal output formatting) is a **genuinely different, narrower**
  concern: making a process's *output* — tables, progress spinners, styled
  text — legible inside any script or application, independent of whether
  that process parses CLI arguments at all. A CLI framework's job is
  turning `sys.argv`/`process.argv` into structured commands/options; a
  terminal-formatting library's job is making whatever gets printed to
  stdout look good. Neither subsumes the other — a data pipeline script
  with zero CLI arguments still legitimately wants Rich for its progress
  bars and pretty-printed summaries.
- **Full distributed message-broker/event-driven architecture** (Kafka,
  RabbitMQ, SQS/SNS, delivery semantics, sagas, dead-letter queues, stream
  processing) — fully owned by `integration-event-driven-systems.md`,
  whose opening scope section was read directly this pass to confirm the
  boundary. Domain 6 above is scoped narrowly to **in-process or
  single-node** periodic/deferred task execution with no cross-service
  delivery guarantee — the moment a task needs to survive a node crash
  with guaranteed cross-service redelivery, it belongs to that other doc,
  not here.
- **Distributed/shared caching** (Redis, Memcached) — an infrastructure
  choice, not an application-level utility-library choice; Domain 2 above
  is scoped explicitly to in-process (cachetools/lru-cache) or
  single-node-disk-persisted (diskcache/joblib.Memory/node-cache) caching
  only.
- **Full test-runner/framework choice** (pytest, Jest, unittest) — Domain 4
  covers only fixtures/fakes/time-freezing libraries used *alongside*
  whichever runner a project already has, not the runner itself.
- **Secrets/environment-variable-loading libraries** (`dotenv`,
  cloud-secrets-manager clients) — the user's own framing example in the
  task brief names `dotenv` explicitly, but that concern was assigned to
  the parallel `batch-a.md` agent's domains, not this batch's Domain 5
  (which is narrowly "detect what runtime/CI environment I'm in," a
  genuinely different question from "load my secrets/config values") —
  not researched here to avoid duplicating that other pass's work.
- **File I/O abstraction across local/cloud storage** (`smart_open` and
  similar) — the user's other own framing example, also assigned to
  `batch-a.md`'s domains per the task split, not re-researched here.

## Sources

- Local file reads (not web sources): `/Users/devopammittra/GitHub/
  ubi-csr-tmf/aws/container/backend/app/requirements.txt` (full read, 190
  packages), `/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/
  frontend/package.json` (full read),
  `/Users/devopammittra/GitHub/agent-skills/skills/project-incubation/
  references/preferred-libraries/developer-tooling-libraries.md` (read in
  full for the CLI-framework scope boundary),
  `/Users/devopammittra/GitHub/agent-skills/skills/project-incubation/
  references/stacks/integration-event-driven-systems.md` (opening scope
  section read for the background-scheduling scope boundary),
  `/Users/devopammittra/GitHub/agent-skills/research/stacks/
  developer-tooling-libraries/libraries.md` (read in full as the structural/
  rigor-bar precedent this doc follows) — all read 2026-08-31.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license, stars,
  forks, open issues, `pushed_at`, `archived`) for: python-pendulum/pendulum
  (`sdispater/pendulum` redirect), arrow-py/arrow, ariebovenberg/whenever,
  date-fns/date-fns, moment/luxon, iamkun/dayjs, tkem/cachetools,
  grantjenks/python-diskcache, isaacs/node-lru-cache, node-cache/node-cache,
  Textualize/rich, chalk/chalk, sindresorhus/ora, cli-table/cli-table3,
  FactoryBoy/factory_boy, joke2k/faker, spulec/freezegun,
  adamchainz/time-machine, faker-js/faker, sinonjs/fake-timers,
  kentcdodds/cross-env, watson/is-ci, agronholm/apscheduler,
  node-cron/node-cron, node-schedule/node-schedule, joblib/joblib —
  retrieved 2026-08-31.
- `gh api repos/sdispater/pendulum/releases` and
  `gh api repos/agronholm/apscheduler/releases` — direct release-history
  fetches used to independently verify (not just trust) the
  "Pendulum release cadence has slowed" and "APScheduler 4.0 is still
  alpha" claims — retrieved 2026-08-31.
- `gh api repos/grantjenks/python-diskcache/commits` and `.../issues` —
  direct fetches confirming last commit 2024-03-03 and the unresolved,
  0-comment/low-comment 2026 PRs/issues around `CVE-2025-69872` —
  retrieved 2026-08-31.
- `github.com/advisories/GHSA-w8v5-vhqr-4h9v` — direct fetch of the GitHub
  Security Advisory for `CVE-2025-69872` (DiskCache unsafe pickle
  deserialization, moderate severity, no patched version) — retrieved
  2026-08-31; corroborated by WebSearch results from sentinelone.com,
  snyk.io, and cvedetails.com (search-corroborated only, not independently
  direct-fetched beyond the GitHub Advisory itself).
- Direct WebFetch of each library's own README/docs for the
  specific-pain-point claims quoted throughout: `ariebovenberg/whenever`
  GitHub README, `tc39/proposal-temporal` GitHub repo,
  `nodejs.org/en/blog/release/v26.0.0`,
  `developer.mozilla.org/.../Temporal` (MDN compat data),
  `raw.githubusercontent.com/kentcdodds/cross-env/master/README.md` plus
  the linked issue `kentcdodds/cross-env#257`,
  `raw.githubusercontent.com/adamchainz/time-machine/main/README.rst` and
  `time-machine.readthedocs.io/en/latest/comparison.html`,
  `raw.githubusercontent.com/grantjenks/python-diskcache/master/README.rst`,
  `raw.githubusercontent.com/faker-js/faker/main/README.md`,
  `rich.readthedocs.io/en/stable/introduction.html`,
  `raw.githubusercontent.com/tkem/cachetools/master/README.rst`,
  `raw.githubusercontent.com/isaacs/node-lru-cache/main/README.md`,
  `raw.githubusercontent.com/chalk/chalk/main/readme.md` — all retrieved
  2026-08-31.
- Direct PyPI JSON-API fetches (`pypi.org/pypi/<name>/json`) for current
  version numbers: pendulum, arrow, whenever, cachetools, diskcache, rich,
  factory_boy, Faker, freezegun, time-machine, APScheduler — retrieved
  2026-08-31.
- Direct `pypistats.org/api/packages/<name>/recent` fetches for weekly
  download counts: cachetools, rich, apscheduler, freezegun, pendulum —
  retrieved 2026-08-31. **Honest gap**: `pypistats.org` rate-limited
  (`429`) repeated requests for arrow, whenever, diskcache, factory_boy,
  Faker, and time-machine after the first several calls this pass — those
  entries above cite GitHub/PyPI-version signal only, not a download
  figure; not fabricated to fill the gap.
- Direct `registry.npmjs.org`/`api.npmjs.org/downloads/point/last-week/
  <name>` fetches for: date-fns, luxon, dayjs, lru-cache, node-cache,
  chalk, ora, cli-table3, @faker-js/faker, @sinonjs/fake-timers, cross-env,
  is-ci, node-cron, node-schedule — retrieved 2026-08-31.
- Direct raw-file fetches for license verification:
  `grantjenks/python-diskcache/master/LICENSE` (Apache-2.0, corrects
  GitHub API's `NOASSERTION`), `faker-js/faker/main/LICENSE` and
  `package.json` (MIT). `date-fns/date-fns`'s license could **not** be
  pinned to a primary-source file this pass — `LICENSE.md` 404'd at the
  path tried and the repo's `package.json` `license` field itself returns
  `null` — flagged as an honest gap in the Domain 1 table rather than
  assumed MIT from the npm registry page alone.
- WebSearch corroboration (not independently direct-fetched primary source
  beyond what's cited above): the January 2022 Marak Squires
  `faker.js`/`colors.js` sabotage incident's broader context (the README's
  own "What happened to the original faker.js?" section was direct-fetched
  and confirms the community's own acknowledgment, but the incident's full
  external narrative is general knowledge/search-corroborated, not
  re-derived from a single primary source this pass); `CVE-2025-69872`'s
  broader coverage (sentinelone.com, snyk.io, cvedetails.com,
  cvefeed.io) — the advisory itself was direct-fetched from GitHub, these
  are corroborating secondary sources only — retrieved 2026-08-31.

## Open questions for the user

- **diskcache's status is a real problem for this doc's Domain 2
  recommendation, not a minor caveat.** It is the only general-purpose
  disk-persisted local-cache library found with meaningful adoption, but
  it has been essentially unmaintained since March 2024 and carries an
  unpatched moderate-severity RCE-capable CVE. Should the authored
  `references/cross-cutting-utility-libraries.md` file (a) still name
  diskcache but with a prominent caution box (this baseline's current
  lean), (b) omit a disk-persisted-cache recommendation entirely and state
  the gap honestly, or (c) do a deeper follow-up search this pass didn't
  have room for (e.g. `shelve`+manual TTL wrapping, `sqlitedict`,
  a newer 2026 entrant not surfaced by this pass's searches)?
- **date-fns's license could not be pinned to a primary-source file this
  pass** (see Sources) — worth a direct follow-up fetch of a specific
  release tag's `LICENSE` file (rather than `main`, which may have moved
  or renamed the file) before the authored doc states a license for it
  with full confidence.
- **`whenever`'s pre-1.0 status**: is it worth naming in the authored doc
  as a "watch this" entrant only, or as a genuine secondary recommendation
  for a new project that explicitly values type-safety/correctness over
  API stability? This baseline leans toward the former (name it, flag
  pre-1.0 clearly, don't make it the default) but the authoring pass
  should make that call deliberately rather than by default.
- **`Temporal`'s practical adoption timeline** — Stage 4 and live in
  Node 26 plus two major browsers is a big, current, easy-to-get-wrong-if-
  assumed-stale piece of news this pass verified directly. Should the
  authored doc frame this more assertively (e.g., "start writing new
  Node 26+-only utility code against `Temporal` directly, skip adding a
  library dependency") given how recent and fast this shipped, or stay
  conservative given most production Node fleets aren't on 26 yet? This
  baseline stayed conservative; the authoring pass should decide
  deliberately.
- **factory_boy's own repo staleness** (pushed 2026-01-01, ~8 months
  before this snapshot) wasn't investigated as deeply as diskcache's or
  freezegun's — is this a "feature-complete, low-churn" situation
  (parallel to MkDocs core in the precedent doc) or worth a closer look
  before the authored doc recommends it without caveat? Flagged, not
  resolved, this pass.
- **`pypistats.org` rate-limiting left six Python packages without a
  download-count figure** (arrow, whenever, diskcache, factory_boy, Faker,
  time-machine) — a follow-up pass with better request pacing (or an
  alternate source, e.g. `pepy.tech`) could fill this gap before
  authoring if the authored doc's convention requires a download figure
  for every row, matching the precedent doc's own near-universal coverage.

## Target file(s) + estimated length

- `skills/project-incubation/references/cross-cutting-utility-libraries.md`
  — this batch covers 6 of an unknown total number of domains (the other
  domains live in the parallel `batch-a.md`); once both batches are
  reviewed and merged, estimate final combined length once Batch A's scope
  is known. This batch alone, if authored standalone, would run
  approximately 250–320 lines (6 domain sections each with a table +
  narrative, one scope-boundary note per domain that overlaps an existing
  category doc, plus the Temporal-API and diskcache-CVE narrative asides
  that don't fit a table row cleanly).
