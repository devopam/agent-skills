# Baseline: Testing
Status: user-approved      Date: 2026-08-24

## In scope

- **Coverage tooling identity** — impact: high — depth: paragraph.
  `coverage.py` (verified current: 7.15.4, released 2026-08-06, supports
  Python 3.10–3.15rc1 and PyPy3 3.10/3.11) is the underlying measurement
  engine; `pytest-cov` (verified current: 7.1.0, released 2026-03-21) is a
  thin pytest-plugin wrapper around it — "provides coverage functionality as
  a pytest plugin," adding automatic `.coverage` file erasing/combination,
  `pytest-xdist` (distributed test run) support, and pytest-consistent
  `sys.path` handling. Neither has been displaced. **Caveat**: this session's
  web-search budget was exhausted before a displacement survey could be run
  (see Open Questions) — the claim "still the standard" rests on absence of
  contrary evidence in the fetches performed, not on a positive competitive
  scan. State this limitation in the authored skill rather than asserting
  the pair is uncontested.

- **Coverage percentage guidance — honest, not a number** — impact: high —
  depth: section. Three independent sources converge on the same position,
  which is stronger than any one of them: (1) Martin Fowler's canonical
  "TestCoverage" article (published 2012-04-17, still the standard citation
  on this topic) argues that treating a coverage percentage as a *target*
  backfires — quoting Brian Marick, "if you make a certain level of coverage
  a target, people will try to attain it" by writing assertion-free tests
  that merely execute lines. Fowler is explicitly suspicious of 100% ("would
  smell of someone writing tests to make the coverage numbers happy"),
  states coverage below 50% is "a real cause for concern," and treats the
  80s–90s as what healthy projects land on *as a byproduct* of thoughtful
  testing — not as a number to chase directly. (2) `coverage.py`'s own docs
  define the `fail_under` config mechanically (exit code 2 if under a set
  percentage) but give **no** recommended target value — the tool provides
  the ratchet, not the number. (3) This repo's own
  `skills/project-incubation/references/architecture-principles.md` §8
  independently states that "coverage-percentage-chasing is explicitly
  discouraged in current practice in favor of 'meaningful coverage plus
  mutation testing.'" Defensible skill guidance: use `fail_under` as a
  regression ratchet (don't let coverage silently drop), not as a quality
  gate; treat a low number as a real signal worth investigating, but never
  reward a rising percentage on its own. Fold in mutation testing
  (`mutmut`, current, actively maintained, no explicit version/date
  confirmed but recent GitHub Actions activity) as the *actual* test-quality
  signal for enterprise-tier projects: it mutates code (`<` → `<=`,
  increments constants, swaps `break`/`continue`) and checks whether the
  suite catches the change — directly detecting the "100% coverage, zero
  real assertions" failure mode that a raw percentage cannot.

- **Fixture scope discipline** — impact: high — depth: section. pytest
  defines five fixture scopes — function (default), class, module, package,
  session — each torn down at a different point (function: end of test;
  class: end of last test in class; module: end of last test in module;
  package: end of last test in the package where the fixture is defined;
  session: end of the whole run). Documented discipline: default to
  function scope for isolation; widen only for genuinely expensive,
  reusable setup (module/session-scoped fixtures are explicitly justified
  by pytest's own docs for network-dependent or otherwise time-expensive
  resources); a broader-scoped fixture cannot meaningfully depend on a
  narrower one (a session fixture can't consume a module fixture). Review
  angle: flag fixtures scoped wider than their actual reuse justifies
  (session-scoped fixture used by one test file), and flag the inverse —
  expensive setup re-run at function scope with no justification.

- **Fixture composition vs. duplication, and conftest.py breadth** —
  impact: med — depth: paragraph. `conftest.py` fixtures are available to
  every test in their directory and subdirectories (pytest's own docs
  demonstrate this hierarchical/overriding behavior directly). This
  directory-wide visibility is the double-edged mechanism: it's the correct
  tool for genuinely shared setup, and the same mechanism is what makes an
  overly broad top-level `conftest.py` a real cost — every fixture placed
  there is collected and visible for the entire test tree even when only a
  handful of tests use it, which is a discoverability and coupling problem
  once conftest.py grows past a page. (This specific "keep it lean" caution
  is not stated verbatim in pytest's docs — it's derived directly from the
  hierarchical-visibility mechanism the docs *do* state; flagged here as
  reasoned rather than quoted.) Review angle: fixtures used by exactly one
  test module belong in that module, not the shared conftest.py; a
  conftest.py that has grown large is itself worth flagging for a splitting
  discussion (nested conftest.py per subdirectory, matching pytest's own
  supported override pattern) rather than one flat file.

- **Mocking discipline: unittest.mock vs. pytest-mock** — impact: high —
  depth: section. `unittest.mock` (Python stdlib) is the underlying
  mechanism; `pytest-mock` (verified current: 3.15.1, released
  2025-09-16, actively maintained — 6 listed maintainers, Trusted
  Publishing/Sigstore attestations) is "a thin-wrapper around the patching
  API provided by the mock package" whose real value-add is automatic
  teardown (undoes patches at test end without an explicit
  `patch.stopall()`/context-manager nesting) via its `mocker` fixture, plus
  pytest-native assertion introspection. Current preference in pytest
  codebases leans toward `pytest-mock`'s `mocker` fixture for the teardown
  ergonomics, while `unittest.mock` remains correct (and necessary) outside
  a pytest context or for `autospec`/`create_autospec` used directly.
  **Where to patch** (sourced directly from `unittest.mock` docs): "you
  patch where an object is looked up, not necessarily where it is
  defined" — patching `a.SomeClass` does nothing if module `b` already did
  `from a import SomeClass`; the correct target is `b.SomeClass`. This is
  the concrete, reviewable form of "mocking at the wrong layer" — a test
  that patches a name in the defining module when the code under test
  imported it by value is silently mocking nothing. **`autospec` /
  `create_autospec`**: creates a mock whose signature is checked against
  the real object's — calling it with the wrong arguments raises
  `TypeError` at test time the same way the real call would, closing the
  gap where a mock silently accepts calls the real object would reject
  (the concrete defense against tests passing against a stale mock after
  the real interface changed).

- **Over-mocking as an anti-pattern; mocking at boundaries, not internals**
  — impact: high — depth: section. Martin Fowler's "Mocks Aren't Stubs"
  distinguishes state verification (stubs — check the end state) from
  behavior verification (mocks — check the calls made), and the article's
  own stated risk of mock-heavy ("mockist") testing is real and specific:
  mockist tests are "more coupled to the implementation of a method" and
  break under refactors that don't change observable behavior; and
  "expectations on mockist tests can be incorrect, resulting in unit tests
  that run green but mask inherent errors" — exactly the "test verifies
  nothing real" failure mode named in the research brief. Fowler's own
  discipline: mock awkward, expensive, or non-deterministic collaborations
  (external services, email, network); use the real object for cheap,
  deterministic domain collaborators; and always pair fine-grained
  mock-based tests with coarser integration/acceptance tests that exercise
  the real wiring, because mocking removes the "mini-integration test"
  property that using real collaborators gives you for free. Review angle:
  a test file where every collaborator is mocked, including simple
  in-process domain objects, is a signal worth flagging even if it passes.

- **Test isolation: shared mutable state and execution order** — impact:
  high — depth: section. `pytest-randomly` (verified current: 4.1.0,
  released 2026-04-20, actively maintained, 100% coverage on itself)
  randomizes test order at module/class/function level specifically to
  surface hidden inter-test dependencies — its own stated rationale:
  "randomness in testing can be quite powerful to discover hidden flaws in
  the tests themselves" — and additionally resets the global random seed
  before each test (deterministically, from a printed base seed) so tests
  using randomized data stay reproducible. This is the direct tool-level
  evidence that order-dependent tests are a recognized, non-hypothetical
  failure class, not a theoretical concern. Review angle: any test that
  relies on a previous test's side effect (module-level mutable state, a
  fixture with broader scope than the state it holds warrants, a database
  row left behind by an earlier test) is a defect regardless of whether the
  suite currently happens to run in an order that hides it.

- **Filesystem test isolation** — impact: med — depth: paragraph. pytest's
  `tmp_path` fixture provides a fresh temporary directory unique to each
  test function (function-scoped by default); `tmp_path_factory` is the
  session-scoped fixture used when directories must be deliberately shared
  or when a single expensive resource should be created once per session
  rather than regenerated per test. Review angle: any test writing to a
  hardcoded path, a shared fixture directory, or the working directory
  without going through `tmp_path`/`tmp_path_factory` is a filesystem
  isolation defect.

- **Database test isolation — principle only, mechanism deferred** —
  impact: med — depth: paragraph. No framework-neutral primary source
  covers this (ORM- and framework-specific transaction-rollback and
  fresh-schema patterns differ by stack), and the scoping doc already
  rejected a framework-specific overlay at the domain level. State the
  principle only: every test must start from a known database state
  (transaction-per-test rollback, or fresh-schema-per-test, or fixture data
  reset between tests), and flag tests that depend on data left behind by
  a prior test or by manual setup. Defer the concrete mechanism
  (`pytest-django`'s `db` fixture, SQLAlchemy session-per-test patterns,
  factory_boy) to a future stack-specific overlay, consistent with how the
  scoping doc handles framework-specific Ruff categories.

- **Network calls in unit tests** — impact: med — depth: paragraph.
  `pytest-socket` (verified current: 0.8.1, released 2026-08-19, actively
  maintained) disables/restricts `socket` calls during test runs by
  default, with opt-in per-test/per-fixture allowance — direct tool
  evidence that unintended network access in what's meant to be a unit
  test is a recognized, name-worthy failure class (non-deterministic,
  slow, environment-dependent). Review angle: any "unit" test making a real
  HTTP/DB/socket call without an explicit, intentional integration-test
  marker is a flaky-test risk worth flagging.

- **Assertion quality: specific vs. weak assertions, `pytest.raises`,
  `parametrize`** — impact: high — depth: section. `pytest.raises()`
  context-manager form is documented as the preferred modern usage (the
  pre-`with` callable form is "rarely used" today); the `match` parameter
  (regex via `re.search()`, so partial matches pass) lets a test assert not
  just *that* an exception type was raised but *what it says* — the
  specificity distinction the research brief asks for. A documented pitfall:
  `pytest.raises()` matches subclasses of the given exception too, which
  can silently pass a test that actually raised a more specific,
  unexpected exception — checking `excinfo.type` directly is the documented
  fix when exact-type matching matters. `pytest.mark.parametrize` is
  documented as the mechanism to collapse near-duplicate test functions
  differing only in input/expected-output into one function run N times —
  directly reduces the copy-paste-test-with-one-changed-literal anti-pattern
  the research brief names, and supports stacking decorators for
  combinatorial coverage and `pytest.param()` for per-case marks (e.g.
  `xfail` on one parameter set without affecting the others). Weak-assertion
  guidance (e.g. `assert result` vs. `assert result == {"status": "ok"}`) is
  not separately documented by pytest itself but is a direct corollary of
  the same specificity principle `pytest.raises(match=...)` demonstrates —
  flagged as reasoned, not separately sourced.

- **Property-based testing (Hypothesis)** — impact: med (higher at
  enterprise tier) — depth: section. Hypothesis (verified current: 6.165.10,
  released 2026-08-16, "Production/Stable" classifier) generates inputs
  across a described range rather than requiring each example be
  hand-written, and automatically shrinks a failing run to the simplest
  reproducing case — its own documented example is a custom sort function
  that looks correct on hand-picked examples but fails on `sorted([0, 0])`,
  a duplicate-element edge case a human is unlikely to think to write by
  hand. **Warrant criterion (derived, not directly quoted from a
  source)**: property-based testing pays off where (a) the input space is
  large/combinatorial and (b) a general property is statable independent of
  any one input — round-trip serialize/deserialize, parser invariants,
  idempotency, commutativity, "output is always sorted/bounded/non-negative"
  — and pays off less where behavior is fundamentally a table of specific
  business rules with no general property to state (in which case
  example-based parametrized tests are the better fit and Hypothesis adds
  friction without value). This derivation should be flagged for user
  confirmation rather than presented as directly sourced (see Open
  Questions) — the fetches performed found the mechanism and the shrinking
  example but not an explicit "use it when / don't use it when" statement
  in Hypothesis's own docs.

- **Test naming/organization conventions — `flake8-pytest-style` (PT)** —
  impact: med — depth: table. Verified directly against Ruff's rule
  listing (fetched 2026-08-24). Real, current PT rule coverage spans:
  fixture-decorator style (`PT001`–`PT003`: parentheses style, keyword vs.
  positional fixture config, redundant `scope='function'`), parametrize
  correctness (`PT006`/`PT007`: correct types for names/values, `PT014`:
  duplicate parametrize cases), plain-`assert`-over-unittest-style
  (`PT008`/`PT009`), exception-testing rigor (`PT010`: require an explicit
  exception type in `pytest.raises()`, `PT011`: flag overly broad
  `pytest.raises(Exception)` and suggest `match`, `PT012`: single-statement
  `raises()` blocks), warning-testing rigor (`PT029`–`PT031`, **preview**
  status — not yet stable), deprecated-API migration (`PT020`:
  `@pytest.yield_fixture` → plain `@pytest.fixture` with `yield`), and
  fixture-usage hygiene (`PT019`/`PT021`/`PT022`/`PT025`/`PT026`:
  `usefixtures` misuse, `request.addfinalizer` vs. `yield` teardown, empty
  or misapplied `usefixtures`). **Correction against an earlier internal
  draft of this research**: `PT004`/`PT005` (fixture-naming-underscore
  rules) are **removed** from current Ruff — do not describe PT as
  checking fixture-naming underscores. Independent corroboration beyond
  Ruff: pytest's own `goodpractices.html` doc recommends
  `flake8-pytest-style` by name for "catching pytest usage errors" —
  meaning this isn't only a Ruff-side judgment call, pytest's own
  maintainers point at the same tool.

- **Flaky test patterns** — impact: high — depth: checklist.
  - Time-dependent tests without freezing time: `time-machine` (verified
    current: 3.4.0, released 2026-08-10, "Production/Stable", author Adam
    Johnson, 100% self-coverage) exists specifically to let a test set/travel
    the system clock deterministically rather than depending on real
    wall-clock time (e.g. asserting on `datetime.now()`-derived expiry
    logic). A test asserting time-sensitive behavior without freezing time
    is inherently flaky near date/DST boundaries and under CI load. (Direct
    freezegun-vs-time-machine comparison could not be sourced this session
    — see Open Questions.)
  - Network calls in unit tests — see `pytest-socket` above.
  - Order-dependent assertions / shared state — see `pytest-randomly` above.
  - `pytest-rerunfailures` (verified current: 16.6, released 2026-08-17,
    actively maintained, 7 listed maintainers) automatically reruns failed
    tests to "eliminate intermittent failures." **Judgment call, not
    sourced from the docs**: the plugin's own documentation does not caution
    against using reruns to paper over real flakiness — it frames reruns
    pragmatically (it even documents `--max-suite-reruns` to bound cost when
    many tests are flaky at once). The skill should add that caution itself:
    a rerun-to-green suite hides the underlying non-determinism rather than
    fixing it, and `pytest-rerunfailures` is a mitigant for tests already
    known-flaky-for-good-reason (e.g. a genuinely racy external dependency),
    not a substitute for fixing an avoidably flaky test.

- **Tier applicability** — impact: high — depth: table. Reasoned against
  the tier-table pattern used by `performance.md` and `security.md` in the
  original tool (a `| Check | Script | Web | Enterprise |` table), not the
  degenerate all-tiers case in `code-quality.md`:

  | Check | Script | Web | Enterprise |
  |---|---|---|---|
  | Fixture scope hygiene (function-default, justified widening) | Yes | Yes | Yes |
  | Assertion specificity / `pytest.raises` usage | Yes | Yes | Yes |
  | Test isolation (shared state, order-independence) | Yes | Yes | Yes |
  | Bare coverage number as a gate (flag as anti-pattern) | Yes | Yes | Yes |
  | `pytest.mark.parametrize` for duplication | No | Yes | Yes |
  | Mocking-at-boundaries / `autospec` discipline | No | Yes | Yes |
  | Filesystem isolation (`tmp_path`) | No | Yes | Yes |
  | Network isolation (`pytest-socket`) | No | Yes | Yes |
  | `flake8-pytest-style` (PT) idiom conformance | No | Yes | Yes |
  | Database isolation pattern present | No | Yes | Yes |
  | Property-based testing (Hypothesis) coverage on invariant-heavy code | No | No | Yes |
  | Mutation testing (`mutmut`) as a suite-quality signal | No | No | Yes |
  | `pytest-randomly` wired into CI | No | No | Yes |

  Rationale: a script-tier project (single-file, throwaway, no CI) still
  benefits from not writing tests that lie to themselves (weak assertions,
  order-dependent state) — those are cheap, universal hygiene. Everything
  requiring infrastructure investment (fixtures for isolation, dedicated
  linting, mutation testing, property-based testing, CI-wired flake
  detection) is gated to web/enterprise or enterprise-only, mirroring how
  Performance gates N+1/connection-pooling to web+ and Security gates
  mTLS/workload-identity to enterprise-only.

## Explicitly out of scope

- **Whether TDD (red-green-refactor) was practiced** — this domain reviews
  the quality of test code that exists in the codebase today, not the
  process that produced it. Already covered as a universal
  software-project principle in
  `skills/project-incubation/references/architecture-principles.md` §8;
  cross-reference rather than duplicate.
- **Bare `except:` / silently-swallowed exceptions** — already Code
  Quality's Critical item (`research/python-code-review/original-tool/review-domains/code-quality.md`);
  it's a testability-adjacent concern (untestable error paths) but owned
  there, not duplicated here.
- **CI pipeline configuration for running/gating tests** (fail-the-build-
  on-red, test-stage config in CI YAML) — this is "is the build/tooling
  config correct," which is Standards Compliance's lens, not this domain's
  test-*code*-quality lens.
- **Load/performance testing** (locust, k6-style throughput testing) —
  Performance domain's lens ("is it fast"), not Testing's.
- **Fuzzing for security vulnerability discovery** — Security domain's
  lens; this domain's property-based-testing coverage is about correctness
  properties, not adversarial input discovery, even though Hypothesis and
  security fuzzers share generation machinery.
- **Framework-specific test tooling** (`pytest-django`'s `db` fixture,
  `factory_boy`, `responses`/`httpretty` for HTTP mocking, SQLAlchemy
  session-per-test helpers) — real and mature, but stack-specific;
  consistent with the scoping doc's rejection of framework-specific
  overlays at the domain level, defer to a future `research/stacks/`
  supplement.
- **Coverage-tool alternatives to pytest-cov/coverage.py** — not asserted
  as nonexistent, but not surveyed this session (web-search budget
  exhausted); see Open Questions rather than silently claiming the
  incumbent pair is uncontested.

## Sources

- https://docs.astral.sh/ruff/rules/#flake8-pytest-style-pt — full current
  `flake8-pytest-style` (PT) rule listing, including that PT004/PT005 are
  removed and PT029–031 are preview-status — retrieved 2026-08-24
- https://coverage.readthedocs.io/en/latest/ — coverage.py identity,
  current version (7.15.4, 2026-08-06), supported Python range — retrieved
  2026-08-24
- https://coverage.readthedocs.io/en/latest/config.html#report-fail-under
  — `fail_under` mechanics; confirms no recommended target percentage is
  stated by the tool itself — retrieved 2026-08-24
- https://martinfowler.com/bliki/TestCoverage.html — canonical "coverage
  percentage as a weak/gameable signal" position; published 2012-04-17,
  still the standard citation — retrieved 2026-08-24
- https://docs.pytest.org/en/stable/how-to/fixtures.html — fixture scope
  levels (function/class/module/package/session), teardown timing,
  scope-nesting constraint (broader can't depend on narrower), and
  conftest.py hierarchical/overriding fixture visibility — retrieved
  2026-08-24
- https://docs.pytest.org/en/stable/explanation/goodpractices.html —
  pytest's own recommendation of `flake8-pytest-style` by name; test
  layout and `importlib` import-mode guidance — retrieved 2026-08-24
- https://hypothesis.readthedocs.io/en/latest/ — Hypothesis identity and
  mechanism (input generation + shrinking) — retrieved 2026-08-24
- https://pypi.org/project/hypothesis/ — current version (6.165.10,
  2026-08-16), Production/Stable status, `sorted([0,0])` shrinking example
  — retrieved 2026-08-24
- https://pypi.org/project/pytest-mock/ — pytest-mock identity, `mocker`
  fixture, automatic-teardown value-add over raw `unittest.mock`, current
  version (3.15.1, 2025-09-16) — retrieved 2026-08-24
- https://docs.python.org/3/library/unittest.mock.html — "patch where
  looked up, not where defined" (the concrete form of wrong-layer
  mocking), and `autospec`/`create_autospec` signature-checking behavior —
  retrieved 2026-08-24
- https://martinfowler.com/articles/mocksArentStubs.html — mock vs. stub
  distinction (behavior vs. state verification), over-mocking/mockist-test
  risks (implementation coupling, incorrect expectations masking real
  errors), guidance to mock awkward collaborations and pair with coarser
  integration tests — retrieved 2026-08-24
- https://docs.pytest.org/en/stable/how-to/parametrize.html —
  `pytest.mark.parametrize` purpose, duplication reduction, stacking and
  `pytest.param()` per-case marks — retrieved 2026-08-24
- https://docs.pytest.org/en/stable/how-to/assert.html — `pytest.raises()`
  context-manager form as preferred modern usage, `match` parameter
  (regex via `re.search()`), subclass-matching pitfall and `excinfo.type`
  fix — retrieved 2026-08-24
- https://docs.pytest.org/en/stable/how-to/tmp_path.html — `tmp_path`
  (function-scoped) and `tmp_path_factory` (session-scoped) filesystem
  isolation fixtures — retrieved 2026-08-24
- https://pypi.org/project/pytest-randomly/ — test-order randomization,
  stated rationale ("discover hidden flaws in the tests themselves"),
  deterministic seed reset for reproducibility, current version (4.1.0,
  2026-04-20) — retrieved 2026-08-24
- https://pypi.org/project/pytest-socket/ — network-call blocking in
  tests by default, opt-in exceptions, current version (0.8.1,
  2026-08-19) — retrieved 2026-08-24
- https://pypi.org/project/pytest-rerunfailures/ — automatic rerun of
  failed tests to mitigate intermittent failures, `--max-suite-reruns`,
  current version (16.6, 2026-08-17); confirmed the docs do *not*
  themselves caution against masking root-cause flakiness (added as this
  research's own judgment call, labeled as such above) — retrieved
  2026-08-24
- https://pypi.org/project/time-machine/ — deterministic time
  travel/freezing for tests, current version (3.4.0, 2026-08-10),
  Production/Stable — retrieved 2026-08-24
- https://mutmut.readthedocs.io/en/latest/ — mutation testing identity and
  mechanism (mutate code, verify tests catch it), positioned as the
  test-quality signal plain coverage can't provide — retrieved 2026-08-24
- https://pypi.org/project/pytest-cov/ — pytest-cov as a thin wrapper
  around coverage.py, current version (7.1.0, 2026-03-21), xdist support
  — retrieved 2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — Testing's
  scoping-pass corroboration via `flake8-pytest-style`; framework-specific
  overlay rejection precedent applied to database-isolation and
  framework-test-tooling out-of-scope calls above — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/code-quality.md`
  (this repo) — bare-except Critical item, confirmed not duplicated here
  — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/performance.md`,
  `.../security.md` (this repo) — tier-applicability table pattern (`|
  Check | Script | Web | Enterprise |`) mirrored above, rather than the
  degenerate all-tiers form in code-quality.md — read 2026-08-24
- `skills/project-incubation/references/architecture-principles.md` §7–8
  (this repo) — Testability vs. TDD distinction (cross-referenced, not
  duplicated), and independent "coverage-chasing discouraged, favor
  meaningful coverage plus mutation testing" corroboration for the
  coverage-percentage guidance above — read 2026-08-24

## Open questions for the user

- **Coverage-tooling displacement survey not completed.** This session's
  WebSearch budget was exhausted after the first two queries (before any
  results returned), so "pytest-cov/coverage.py are still the standard"
  rests on no-contrary-evidence-found in direct fetches, not on a
  competitive scan. If a newer tool (e.g. something built on `sys.monitoring`
  performance work, or a Rust-backed coverage collector) has gained real
  adoption, this baseline would miss it. Recommend a follow-up pass with
  search budget available before authoring locks this section in.
- **Freezegun vs. time-machine**: both exist for the same problem
  (deterministic time in tests); this research verified time-machine's
  current status but could not source a direct comparison (maintenance
  trajectory, performance, API differences) this session. Worth a
  five-minute follow-up fetch of freezegun's own PyPI/GitHub page before
  authoring picks one to recommend (or recommends both, tier-gated).
  Currently the pattern trend as of the last verified maintainer activity
  favors time-machine as the more actively maintained option
  (100% self-coverage, recent August 2026 release, single dedicated
  maintainer) — but this is an inference from time-machine's page alone,
  not a head-to-head source.
- **Hypothesis "when warranted" criterion is derived, not sourced.** The
  in-scope section above states a warrant criterion (large/combinatorial
  input space + a statable general property) reasoned from Hypothesis's
  own shrinking-example mechanism, not quoted from an explicit "use this
  when" statement in Hypothesis's docs (three separate fetches targeting
  that comparison did not surface one). Please confirm this framing reads
  as correct before it's promoted into skill content, or point at a
  better primary source if one exists.
- **Database isolation mechanism is deliberately left unspecified** (only
  the principle — known starting state per test — is in scope here). Is a
  framework-agnostic default worth stating anyway in the authored skill
  (e.g. "prefer transactional rollback over manual cleanup where the DB
  layer supports it"), or should the skill stay silent until a stack
  overlay exists, per the scoping doc's precedent?
- **Mutation testing's tier placement** — this baseline places `mutmut` at
  enterprise-only given its cost (running the full suite once per mutant is
  expensive). Confirm that's the right cutoff rather than "web and
  enterprise," given Performance/Security's own tier tables sometimes
  extend web-tier checks further than intuition suggests.

## Resolutions (Checkpoint A review, 2026-08-24)

- **Coverage-tooling displacement survey, freezegun-vs-time-machine
  comparison**: both deferred to a direct-fetch check at authoring time,
  per the standing verify-before-publish policy. Tentatively lean
  time-machine per the signal already found (recent release, single
  active maintainer, 100% self-coverage), confirm/adjust once verified.
- **Hypothesis "when warranted" criterion**: accepted as correctly
  reasoned — keep the derived framing, still labeled "reasoned, not
  directly quoted" in the authored doc per the baseline's own honest
  practice.
- **Database isolation default**: add one framework-agnostic guidance
  line ("prefer transactional rollback over manual cleanup where the DB
  layer supports it") — genuinely framework-agnostic enough not to
  violate the no-framework-overlay rule. Deeper mechanism stays deferred
  to a future stack-specific overlay.
- **Mutation testing tier placement**: keep enterprise-only as baselined
  — the full-suite-per-mutant cost justifies the higher bar.

## Target file(s) + estimated length

- `skills/python-code-review/references/testing.md` — est. 260–300 lines
  (nine sourced sub-topics at section/table depth, one tier-applicability
  table, plus scoring-guide and required-evidence sections mirroring the
  original tool's per-domain structure once authored — those two sections
  are not part of this baseline itself).
