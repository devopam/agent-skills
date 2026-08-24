# Testing

This is the reference `python-code-review` applies when judging the quality
of test code that already exists in a codebase — fixture design, mocking
correctness, isolation, assertion strength, and the tooling that keeps a
suite honest over time. It does not evaluate whether tests were written
before or after the implementation (TDD-as-process); that is a
process/discipline question owned by `project-incubation`'s
[`architecture-principles.md` §8](../../project-incubation/references/architecture-principles.md).
This domain asks a narrower question: given the tests in front of you right
now, do they actually prove what they claim to prove, and will they still
pass for the right reasons in six months?

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [Coverage: Tooling and What the Percentage Means](#coverage-tooling-and-what-the-percentage-means)
- [Fixture Scope Discipline](#fixture-scope-discipline)
- [Fixture Composition vs. Duplication, and conftest.py Breadth](#fixture-composition-vs-duplication-and-conftestpy-breadth)
- [Mocking Discipline](#mocking-discipline)
- [Over-Mocking: Mock at Boundaries, Not Internals](#over-mocking-mock-at-boundaries-not-internals)
- [Test Isolation: Order and Shared State](#test-isolation-order-and-shared-state)
- [Filesystem Isolation](#filesystem-isolation)
- [Database Isolation](#database-isolation)
- [Network Calls in Unit Tests](#network-calls-in-unit-tests)
- [Assertion Quality](#assertion-quality)
- [Property-Based Testing (Hypothesis)](#property-based-testing-hypothesis)
- [Naming and Organization: flake8-pytest-style (PT)](#naming-and-organization-flake8-pytest-style-pt)
- [Flaky Test Patterns](#flaky-test-patterns)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Sources](#sources)

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Fixture scope hygiene (function-default, widening justified) | Yes | Yes | Yes |
| Assertion specificity / `pytest.raises` usage | Yes | Yes | Yes |
| Test isolation principle (no shared state, order-independence) | Yes | Yes | Yes |
| Bare coverage percentage treated as a quality gate (flag as anti-pattern) | Yes | Yes | Yes |
| Time-dependent assertions don't depend on real wall-clock time (principle) | Yes | Yes | Yes |
| `pytest.mark.parametrize` for near-duplicate tests | No | Yes | Yes |
| Mocking-at-boundaries / `autospec` discipline | No | Yes | Yes |
| Filesystem isolation (`tmp_path`) | No | Yes | Yes |
| Network isolation (`pytest-socket`) | No | Yes | Yes |
| `flake8-pytest-style` (PT) idiom conformance | No | Yes | Yes |
| Database isolation pattern present | No | Yes | Yes |
| Time-freezing library (`time-machine`) actually installed and used | No | Yes | Yes |
| Reruns (`pytest-rerunfailures`) used to mask rather than fix flakiness | No | Yes | Yes |
| Property-based testing (Hypothesis) on invariant-heavy code | No | No | Yes |
| Mutation testing (`mutmut`) as a suite-quality signal | No | No | Yes |
| `pytest-randomly` wired into CI | No | No | Yes |

A script-tier project — single-file, throwaway, no CI — still benefits from
not writing tests that lie to themselves: weak assertions and
order-dependent state are cheap, universal hygiene regardless of project
size. Everything that requires infrastructure investment (dedicated
fixtures for isolation, a linting plugin, mutation testing, property-based
testing, CI-wired flake detection) is gated to web/enterprise or
enterprise-only, mirroring how `performance.md` gates N+1/connection-pooling
checks to web+ and `security.md` gates mTLS/workload-identity to
enterprise-only.

## Coverage: Tooling and What the Percentage Means

**Tooling identity.** `coverage.py` (current: 7.15.4, released 2026-08-06;
supports Python 3.10–3.15rc1 and PyPy3 3.10/3.11) is the underlying
measurement engine. `pytest-cov` (current: 7.1.0, released 2026-03-21) is a
thin pytest-plugin wrapper around it, adding automatic `.coverage` file
erasing/combination, `pytest-xdist` (distributed test run) support, and
pytest-consistent `sys.path` handling. This pair remains the standard —
including on a direct check for displacement: `coverage.py` itself has
absorbed the performance argument that would otherwise motivate switching
away from it, by making a `sys.monitoring`-based core (PEP 669,
`COVERAGE_CORE=sysmon`) the default on Python 3.14+. A real faster
alternative does exist — **SlipCover** (current: 1.1.0, released
2026-08-13) uses just-in-time bytecode instrumentation and
de-instrumentation instead of Python's tracing facilities, and benchmarks
1.1–3.4x faster than `coverage.py` on CPython 3.10.5 (with far larger
multiples on PyPy 3.9) — but that headline figure was measured against
`coverage.py`'s older, tracing-based core, the same one `coverage.py` no
longer defaults to on 3.14+; the gap SlipCover was built to close is
exactly the one coverage.py's own `sys.monitoring` adoption narrows from
the other side. It's a narrower, less-integrated tool, not a displacement
of the incumbent pair; treat it as worth knowing about for a
performance-sensitive suite on an older Python version, not as something to
flag a codebase for not using.

**The percentage is a ratchet, not a gate.** Three independent sources
converge on the same position. Martin Fowler's canonical ["Test
Coverage"](https://martinfowler.com/bliki/TestCoverage.html) article argues
that treating a coverage percentage as a *target* backfires — quoting Brian
Marick, "if you make a certain level of coverage a target, people will try
to attain it," typically by writing assertion-free tests that merely
execute lines without checking anything. Fowler is explicitly suspicious of
100% coverage ("would smell of someone writing tests to make the coverage
numbers happy"), calls a number below 50% "a real cause for concern," and
treats the 80s–90s as what healthy projects land on *as a byproduct* of
thoughtful testing — never as a number to chase directly. `coverage.py`'s
own docs define [`fail_under`](https://coverage.readthedocs.io/en/latest/config.html#report-fail-under)
mechanically (exit code 2 if coverage drops under a configured percentage)
but state no recommended target value anywhere — the tool ships the
ratchet mechanism, not an opinion on the number. This repo's own
`architecture-principles.md` independently states that
"coverage-percentage-chasing is explicitly discouraged in current practice
in favor of 'meaningful coverage plus mutation testing.'"

Practical guidance that falls out of this: set `fail_under` to whatever the
suite currently achieves and use it as a regression floor — coverage should
never silently drop — but never treat a rising percentage as evidence of
anything on its own, and never reward it. A low number is a real signal
worth investigating (large swaths of untested code); a high number proves
nothing about whether the tests that produced it actually assert anything
meaningful.

**Mutation testing is the signal a percentage can't give you (enterprise
tier).** `mutmut` mutates code — `<` becomes `<=`, constants get
incremented, `break` swaps for `continue` — and checks whether the suite
catches the change. It directly detects the "100% coverage, zero real
assertions" failure mode that a raw percentage structurally cannot, because
a test can execute every line of a function while asserting nothing about
its behavior. This is gated to enterprise tier because running the full
suite once per mutant is expensive — cheap for a fast, small script-tier
suite but genuinely costly at scale — matching the baseline's own reasoning
for the cutoff.

**Review angle:** a `fail_under` configured above what the suite currently
achieves is a quality gate wearing a ratchet's clothing — flag it the same
way a hardcoded coverage target in CI would be flagged. A PR whose stated
justification for a new or padded test is "raises coverage to X%," with no
claim about what the test actually verifies, is itself a review finding.

## Fixture Scope Discipline

pytest defines five fixture scopes — `function` (default), `class`,
`module`, `package`, `session` — each torn down at a different point:
function scope at the end of the test, class scope at the end of the last
test in the class, module scope at the end of the last test in the module,
package scope at the end of the last test in the package where the fixture
is defined, session scope at the end of the whole run. The documented
discipline: default to function scope for isolation, and widen only for
genuinely expensive, reusable setup — pytest's own docs explicitly justify
module- or session-scoped fixtures for network-dependent or otherwise
time-expensive resources. A structural constraint worth knowing when
reviewing fixture graphs: a broader-scoped fixture cannot meaningfully
depend on a narrower one (a session-scoped fixture can't consume a
module-scoped one, because the narrower one would already be torn down
while the broader one is still alive).

**Review angle:** flag a fixture scoped wider than its actual reuse
justifies — a session-scoped fixture consumed by exactly one test file is
usually an isolation bug waiting to happen, not an optimization. Flag the
inverse too: expensive setup (a real database connection, a large fixture
file, a subprocess) re-created at function scope with no stated reason,
which is a needless performance cost with no isolation benefit if the
resource is genuinely read-only across tests.

## Fixture Composition vs. Duplication, and conftest.py Breadth

`conftest.py` fixtures are visible to every test in their directory and all
subdirectories — pytest's own docs demonstrate this hierarchical,
overriding visibility directly, including that a fixture defined in a
nested `conftest.py` can override one defined higher up. This directory-wide
visibility is a double-edged mechanism: it's the correct tool for genuinely
shared setup, and the same mechanism is what makes an overly broad
top-level `conftest.py` a real cost. Every fixture placed there is
collected and visible for the entire test tree even when only a handful of
tests use it, which becomes a discoverability and coupling problem once the
file grows past a page — a reader can no longer tell, from a test file
alone, which fixtures it actually depends on. (This specific "keep it lean"
caution is reasoned directly from the hierarchical-visibility mechanism
pytest's docs state, rather than a caution pytest's docs state verbatim.)

**Review angle:** a fixture used by exactly one test module belongs in that
module, not in the shared `conftest.py`. A `conftest.py` that has grown
large is itself worth flagging for a splitting discussion — nested
`conftest.py` files per subdirectory, matching pytest's own supported
override pattern — rather than accepting one flat, all-purpose file as the
only option.

## Mocking Discipline

`unittest.mock` (Python stdlib) is the underlying mechanism; `pytest-mock`
(current: 3.15.1, released 2025-09-16) is a thin wrapper around the same
patching API whose real value-add is automatic teardown — its `mocker`
fixture undoes every patch at test end without an explicit
`patch.stopall()` call or context-manager nesting — plus pytest-native
assertion introspection on failure. Current preference in pytest codebases
leans toward `pytest-mock`'s `mocker` fixture for the teardown ergonomics;
`unittest.mock` directly remains correct, and necessary, outside a pytest
context, or when using `autospec`/`create_autospec` in ways that need the
raw API.

**Where to patch.** Sourced directly from `unittest.mock`'s own docs: "you
patch where an object is looked up, not necessarily where it is defined."
If module `a` defines `SomeClass` and module `b` imports it by value
(`from a import SomeClass`), then patching `a.SomeClass` does nothing to
the code under test — `b` already holds its own reference. The correct
target is `b.SomeClass`. This is the concrete, reviewable form of "mocking
at the wrong layer": a test that patches a name in its defining module when
the code under test imported that name by value is silently mocking
nothing, and the test will pass whether or not the real dependency was
ever called — the single most common way a mock-based test lies about what
it verifies.

**`autospec` / `create_autospec`.** These create a mock whose signature is
checked against the real object's — calling the mock with arguments the
real object wouldn't accept raises `TypeError` at test time, the same way
the real call would. This closes the gap where a hand-built `Mock()`
silently accepts any call, including calls that no longer match reality
after the real interface changed underneath the mock. A mocked
collaborator without `autospec` is a contract that nothing enforces; a
mocked collaborator with `autospec` fails loudly the moment the mock and
the real object disagree.

**Review angle:** when reviewing a `patch(...)` call, always trace where
the patched name is actually looked up from the code path under test, not
where it's defined — a patch target that matches the defining module but
not the importing module is a defect even though the test will pass. When
reviewing a hand-built `Mock()` standing in for a real class or function,
ask whether `autospec=True` (or `create_autospec`) would have caught a
stale interface; if there's no reason it wouldn't, its absence is worth
flagging.

## Over-Mocking: Mock at Boundaries, Not Internals

Martin Fowler's ["Mocks Aren't
Stubs"](https://martinfowler.com/articles/mocksArentStubs.html)
distinguishes state verification (stubs — check the end state after the
call) from behavior verification (mocks — check the calls that were made),
and names the risk of mock-heavy ("mockist") testing specifically: mockist
tests are "more coupled to the implementation of a method" and break under
refactors that don't change any observable behavior, and "expectations on
mockist tests can be incorrect, resulting in unit tests that run green but
mask inherent errors" — exactly the "test verifies nothing real" failure
mode a review should be hunting for. Fowler's own discipline: mock
awkward, expensive, or non-deterministic collaborations — external
services, email, network — and use the real object for cheap, deterministic
domain collaborators. Always pair fine-grained mock-based tests with
coarser integration or acceptance tests that exercise the real wiring,
because mocking removes the "mini-integration test" property that using
real collaborators gives a test for free — a suite that mocks everything
can be entirely green while the real objects, wired together, would fail
immediately.

**Review angle:** a test file where every collaborator is mocked, including
simple in-process domain objects with no I/O, no randomness, and no
meaningful cost, is worth flagging even when the suite passes — it's a
signal the test is verifying its own mocks' configuration rather than the
code's actual behavior.

## Test Isolation: Order and Shared State

`pytest-randomly` (current: 4.1.0, released 2026-04-20) randomizes test
order at the module, class, and function level specifically to surface
hidden inter-test dependencies — its own stated rationale is that
"randomness in testing can be quite powerful to discover hidden flaws in
the tests themselves." It additionally resets the global random seed
deterministically before each test (from a printed base seed), so tests
that use randomized input data stay reproducible even though execution
order isn't fixed. That a dedicated, actively maintained plugin exists
specifically to randomize order and catch what breaks is direct tool-level
evidence that order-dependent tests are a recognized, non-hypothetical
failure class, not a theoretical concern raised only in code review.

**Review angle:** any test that relies on a previous test's side effect —
module-level mutable state set by an earlier test, a fixture scoped broader
than the state it actually needs, a database row left behind by a prior
test — is a defect regardless of whether the suite currently happens to run
in an order that hides it. At enterprise tier, `pytest-randomly` wired into
CI turns this from a code-review judgment call into an automated, repeated
check; below that tier the principle still applies, just without the
tooling to enforce it continuously.

## Filesystem Isolation

pytest's `tmp_path` fixture provides a fresh temporary directory unique to
each test function, function-scoped by default. `tmp_path_factory` is the
session-scoped counterpart, used deliberately when directories must be
shared across tests or when a single expensive resource should be created
once per session rather than regenerated per test.

**Review angle:** any test writing to a hardcoded path, a shared fixture
directory, or the current working directory without going through
`tmp_path` or `tmp_path_factory` is a filesystem isolation defect — it will
eventually collide with a parallel test run (`pytest-xdist`), leave state
behind for the next run, or fail non-deterministically depending on what
ran before it.

## Database Isolation

No framework-neutral primary source covers the concrete mechanism here —
transaction-rollback and fresh-schema patterns are genuinely ORM- and
framework-specific, and this domain deliberately stops short of a
framework-specific overlay at the reference-doc level. The principle that
does hold universally: every test must start from a known database state.
That can mean a transaction opened per test and rolled back at teardown,
a fresh schema per test, or fixture data explicitly reset between tests —
the mechanism varies by stack, but the requirement doesn't. Where the
underlying database layer supports it, prefer transactional rollback over
manual cleanup: rollback is atomic and can't leave partial state behind the
way a cleanup routine that itself fails partway through can.

**Review angle:** flag any test that depends on data left behind by a prior
test or by manual setup outside the test itself. The concrete mechanism —
`pytest-django`'s `db` fixture, SQLAlchemy session-per-test patterns,
`factory_boy` for fixture data — is real, mature tooling, but stack-specific
enough that it's deferred to a future stack-specific overlay rather than
asserted here.

## Network Calls in Unit Tests

`pytest-socket` (current: 0.8.1, released 2026-08-19) disables or restricts
`socket` calls during test runs by default, with opt-in allowance
per-test or per-fixture. That a maintained plugin exists specifically to
block network access during test runs — rather than trusting each test
author to avoid it — is direct tool-level evidence that unintended network
access inside what's meant to be a unit test is a recognized,
name-worthy failure class: non-deterministic, slow, and environment-
dependent (it passes on a laptop with connectivity and fails in a sandboxed
CI runner, or vice versa).

**Review angle:** any test labeled or treated as a unit test that makes a
real HTTP, database, or socket call without an explicit, intentional
integration-test marker is a flaky-test risk worth flagging, independent of
whether it happens to pass today.

## Assertion Quality

`pytest.raises()` used as a context manager is documented as the preferred
modern usage — the pre-`with` callable form is described in pytest's own
docs as "rarely used" today. Its `match` parameter takes a regex matched
via `re.search()` (so a partial match passes), which lets a test assert not
just *that* an exception type was raised but *what it says* — the
difference between a test that would still pass if the error message
silently changed to something wrong, and one that wouldn't. A documented
pitfall: `pytest.raises()` matches subclasses of the given exception too,
so a test asserting `pytest.raises(ValueError)` will silently pass even if
the code actually raised a more specific, unexpected subclass. Checking
`excinfo.type` directly is the documented fix when exact-type matching
matters and a subclass would represent a real behavior change.

`pytest.mark.parametrize` is the documented mechanism for collapsing
near-duplicate test functions that differ only in input and expected output
into a single function run N times — it directly targets the
copy-paste-a-test-and-change-one-literal anti-pattern. Decorators stack for
combinatorial coverage across multiple parameters, and `pytest.param()`
supports per-case marks (for example, `xfail` on one parameter set without
affecting the others in the same parametrize call).

**Weak assertions.** `assert result` proves only that `result` is truthy;
`assert result == {"status": "ok"}` proves the actual shape of the value.
This isn't separately documented by pytest itself, but it's a direct
corollary of the same specificity principle `pytest.raises(match=...)`
demonstrates — reasoned, not separately sourced, and flagged as such.

**Review angle:** an assertion that would still pass if the code under test
silently started doing the wrong thing — `assert result`, `assert
response.status_code in (200, 201, 204)` when exactly one is expected,
`pytest.raises(Exception)` with no `match` — is a specificity defect even
when it currently passes for the right reason.

## Property-Based Testing (Hypothesis)

Hypothesis (current: 6.165.10, released 2026-08-16, "Production/Stable")
generates inputs across a described range rather than requiring each
example be hand-written, and automatically shrinks a failing run down to
the simplest reproducing case. Its own documented example is a custom sort
function that looks correct against every hand-picked example but fails on
`sorted([0, 0])` — a duplicate-element edge case a human is unlikely to
think to write by hand, and exactly the class of bug example-based tests
systematically under-sample.

**When it pays off (reasoned, not directly quoted from Hypothesis's docs).**
Property-based testing is worth the setup where two conditions both hold:
the input space is large or combinatorial, and a general property is
statable independent of any one input — round-trip serialize/deserialize,
parser invariants, idempotency, commutativity, "output is always
sorted/bounded/non-negative." It pays off less where behavior is
fundamentally a table of specific business rules with no general property
to state; example-based parametrized tests are the better fit there, and
Hypothesis adds setup friction without adding value. This criterion is
derived from Hypothesis's own shrinking-example mechanism rather than
quoted from an explicit "use it when / don't use it when" statement in its
docs — flagged as reasoned, not sourced, deliberately.

**Review angle:** at enterprise tier, code with a statable invariant and no
property-based test covering it (a serializer, a parser, anything claiming
idempotency) is worth flagging as a coverage gap qualitatively different
from a missing example-based test — it's specifically the class of bug
example-based tests are bad at finding.

## Naming and Organization: flake8-pytest-style (PT)

`flake8-pytest-style`'s current rule set, verified directly against Ruff's
rule listing, spans several distinct concerns. Fixture-decorator style
(`PT001`–`PT003`): parentheses style on `@pytest.fixture`, keyword vs.
positional fixture configuration, redundant `scope="function"` (already the
default). Parametrize correctness (`PT006`/`PT007`: correct types for
parametrize names and values; `PT014`: duplicate parametrize cases).
Plain-`assert`-over-unittest-style assertions (`PT008`/`PT009`).
Exception-testing rigor (`PT010`: require an explicit exception type in
`pytest.raises()`; `PT011`: flag overly broad `pytest.raises(Exception)`
and suggest `match`; `PT012`: single-statement `raises()` blocks — the same
specificity concerns raised above, enforced mechanically). Deprecated-API
migration (`PT020`: `@pytest.yield_fixture` → plain `@pytest.fixture` with
`yield`). Fixture-usage hygiene (`PT019`/`PT021`/`PT022`/`PT025`/`PT026`:
`usefixtures` misuse, `request.addfinalizer` vs. `yield` teardown, empty or
misapplied `usefixtures`). Warning-testing rigor (`PT029`–`PT031`) exists
but is still **preview** status, not yet stable — treat it as forward-
looking, not a current baseline.

**Correction against an earlier draft of this domain's research:**
`PT004`/`PT005` — fixture-naming underscore rules — are **removed** from
current Ruff. Do not describe `flake8-pytest-style` as checking fixture
naming conventions around leading underscores; that rule pair no longer
exists.

Independent corroboration beyond Ruff's own rule listing: pytest's own
[`goodpractices.html`](https://docs.pytest.org/en/stable/explanation/goodpractices.html)
doc recommends `flake8-pytest-style` by name for "catching pytest usage
errors" — this isn't only a Ruff-side judgment call about what's worth
linting; pytest's own maintainers point at the same tool.

**Review angle:** a codebase running Ruff without the `PT` rule set enabled
is missing a maintainer-endorsed, mechanically enforceable layer of the
checks already described in this document (exception-testing rigor,
parametrize correctness, deprecated fixture APIs) — worth flagging as a
tooling gap independent of whether any individual test currently violates
one of those rules.

## Flaky Test Patterns

**Time-dependent tests without freezing time.** A test asserting
time-sensitive behavior — expiry logic derived from `datetime.now()`, a
"created in the last 5 minutes" check — without freezing the clock is
inherently flaky near date/DST boundaries and under CI load, where wall-
clock timing is not guaranteed. The underlying principle (assertions about
time-sensitive behavior shouldn't depend on the real wall clock) applies at
every tier, script included — it costs nothing to write a test that doesn't
race the clock. Actually installing a time-freezing library is the
web/enterprise-tier check, the same split this document already draws for
`pytest-randomly`: the principle is free and universal, the tooling that
enforces it is an infrastructure investment gated to tiers that carry one.

For the tooling itself, `time-machine` (current: 3.4.0, released
2026-08-10, "Production/Stable," single active maintainer, 100%
self-coverage) is the recommended choice over the older `freezegun`
(current: 1.5.5, released 2025-08-09, still maintained, supports Python
3.8–3.13). Both solve the same problem; `time-machine`'s own [documented
comparison](https://time-machine.readthedocs.io/en/latest/comparison.html)
against `freezegun` gives concrete, mechanism-level reasons rather than
just a version number: `freezegun` works by "a find-and-replace mock of all
the places that the `datetime` and `time` modules have been imported," and
the cost of that mocking is proportional to the number of loaded modules —
in a large project this can add several seconds of overhead per test, by
`time-machine`'s own account of the trade-off. Because `freezegun` finds
only module-level imports, it can miss functions held as class attributes
or otherwise referenced outside a plain module import, and it "can't
affect C extensions that call the standard library functions, including
(I believe) Cython-ized Python code" — real correctness gaps, not just a
performance difference. `time-machine` is built to combine the advantages
of `freezegun` and `libfaketime` (faster, broader-reaching mocking) without
`libfaketime`'s `LD_PRELOAD` requirement. This is `time-machine`'s own
characterization of a competitor, not an independent third-party
benchmark, so weigh it accordingly — but the mechanism claims are specific
enough to be checked rather than taken purely on faith, and `freezegun`
remains a maintained, still-common incumbent with its own [migration
guide](https://time-machine.readthedocs.io/en/latest/migration.html)
available for codebases moving off it. Recommend `time-machine` for new
test suites; don't flag an existing, correctly-used `freezegun` suite as a
defect on tooling choice alone.

**Network calls in unit tests** — see [Network Calls in Unit
Tests](#network-calls-in-unit-tests) above; `pytest-socket` is the same
flaky-test concern viewed from the tooling side.

**Order-dependent assertions / shared state** — see [Test Isolation: Order
and Shared State](#test-isolation-order-and-shared-state) above.

**Reruns as a mask, not a fix.** `pytest-rerunfailures` (current: 16.6,
released 2026-08-17) automatically reruns failed tests to "eliminate
intermittent failures," and its own documentation frames reruns
pragmatically — it even documents `--max-suite-reruns` to bound cost when
many tests are flaky at once, with no caution in the docs themselves against
relying on reruns as a substitute for fixing the underlying cause. Add that
caution here, since the tool's own docs don't: a rerun-to-green suite hides
non-determinism rather than resolving it, and every rerun that turns a
failure into a pass without investigation is a data point about a real bug
that got silently discarded. `pytest-rerunfailures` is a legitimate
mitigant for tests that are already known-flaky for a specific, understood
reason — a genuinely racy external dependency outside the codebase's
control — not a substitute for fixing an avoidably flaky test.

**Review angle:** a rerun marker (`@pytest.mark.flaky`, a suite-wide
`--reruns` in CI config) attached to a test with no comment or linked issue
explaining *why* it's flaky is worth flagging — the marker without the
explanation is indistinguishable from reruns being used to paper over a
real, unfixed bug.

## Out of Scope

- **Whether TDD (red-green-refactor) was practiced.** This domain reviews
  the quality of test code that exists today, not the process that
  produced it. Covered as a universal software-project principle in
  `project-incubation`'s
  [`architecture-principles.md` §8](../../project-incubation/references/architecture-principles.md);
  cross-referenced above rather than duplicated.
- **Bare `except:` clauses and silently-swallowed exceptions.** Testability-
  adjacent (an untestable error path is a symptom), but owned by
  [`code-quality.md`](../references/code-quality.md)'s Critical section in
  this same skill, not duplicated here.
- **CI pipeline configuration for running or gating tests** — fail-the-
  build-on-red, test-stage config in CI YAML. That's "is the build/tooling
  config correct," `standards-compliance.md`'s lens, not this domain's
  test-*code*-quality lens.
- **Load and performance testing** (`locust`, k6-style throughput testing)
  — `performance.md`'s lens ("is it fast"), not Testing's.
- **Fuzzing for security vulnerability discovery** — `security.md`'s lens.
  This domain's property-based-testing coverage is about correctness
  properties; security fuzzers share generation machinery with Hypothesis
  but target adversarial input discovery, a different goal.
- **Framework-specific test tooling** — `pytest-django`'s `db` fixture,
  `factory_boy`, `responses`/`httpretty` for HTTP mocking, SQLAlchemy
  session-per-test helpers. Real and mature, but stack-specific; deferred
  to a future `research/stacks/`-derived overlay rather than asserted at
  this domain level, consistent with how database isolation's concrete
  mechanism is deferred above.

## Scoring Guide

Scored against this domain's actual failure modes — never against a
coverage percentage; a numeric coverage target does not appear anywhere in
this rubric, deliberately, per the ratchet-not-gate guidance above.

- **10** — Assertions are specific throughout (no bare `assert result`,
  `pytest.raises` uses `match` or checks `excinfo.type` where subclass
  ambiguity matters). Fixtures are function-scoped by default with any
  widening justified by real reuse. Tests are order-independent and pass
  under randomized execution. Mocking targets boundaries (external
  services, network, non-determinism), not in-process domain objects;
  `autospec` is used where a hand-built mock stands in for a real
  interface. Filesystem and network access go through `tmp_path` /
  `pytest-socket` rather than real paths or real sockets. `PT` rules pass
  clean.
- **8–9** — The above, with minor gaps: a handful of unspecific assertions,
  one or two fixtures scoped wider than justified, `PT` violations present
  but not pervasive.
- **6–7** — Assertion quality is inconsistent (real specificity gaps
  alongside solid tests); some tests depend on execution order or leave
  behind filesystem/database state; mocking occasionally reaches past
  clear boundaries into internal domain objects.
- **4–5** — Widespread weak assertions (`assert result`, bare
  `pytest.raises(Exception)`); real order-dependence that only "works" by
  accident of current test ordering; mocking so pervasive that tests verify
  mock configuration rather than behavior; no filesystem or network
  isolation where the suite makes real I/O calls.
- **1–3** — Tests execute code without asserting anything meaningful;
  suite fails or behaves differently under `pytest-randomly`; mocks patch
  the wrong target (defining module instead of where it's looked up) such
  that the "test" exercises nothing; time-dependent tests are flaky near
  boundaries; a rising coverage percentage is the suite's only stated
  justification for existing.

## Sources

- <https://coverage.readthedocs.io/en/latest/> — coverage.py identity,
  current version (7.15.4, 2026-08-06), supported Python range —
  retrieved 2026-08-24
- <https://coverage.readthedocs.io/en/latest/config.html#report-fail-under>
  — `fail_under` mechanics; confirms no recommended target percentage —
  retrieved 2026-08-24
- <https://coverage.readthedocs.io/en/latest/changes.html> — `sys.monitoring`
  (PEP 669) core made default for Python 3.14+; no competing coverage tool
  referenced in coverage.py's own changelog — retrieved 2026-08-24
  (displacement check)
- <https://pypi.org/project/pytest-cov/> — pytest-cov as a thin wrapper
  around coverage.py, current version (7.1.0, 2026-03-21), xdist support —
  retrieved 2026-08-24
- <https://pypi.org/project/slipcover/> — SlipCover identity, JIT
  bytecode-instrumentation mechanism, benchmarked speedup vs. coverage.py
  on CPython 3.10.5 / PyPy 3.9, current version (1.1.0, 2026-08-13) —
  retrieved 2026-08-24 (displacement check)
- <https://martinfowler.com/bliki/TestCoverage.html> — coverage percentage
  as a weak/gameable signal when used as a target; published 2012-04-17 —
  retrieved 2026-08-24
- <https://docs.pytest.org/en/stable/how-to/fixtures.html> — fixture scope
  levels, teardown timing, scope-nesting constraint, conftest.py
  hierarchical/overriding fixture visibility — retrieved 2026-08-24
- <https://docs.pytest.org/en/stable/explanation/goodpractices.html> —
  pytest's own recommendation of `flake8-pytest-style` by name — retrieved
  2026-08-24
- <https://hypothesis.readthedocs.io/en/latest/> — Hypothesis identity and
  mechanism (input generation plus shrinking) — retrieved 2026-08-24
- <https://pypi.org/project/hypothesis/> — current version (6.165.10,
  2026-08-16), Production/Stable status, `sorted([0, 0])` shrinking example
  — retrieved 2026-08-24
- <https://pypi.org/project/pytest-mock/> — pytest-mock identity, `mocker`
  fixture, automatic-teardown value-add, current version (3.15.1,
  2025-09-16) — retrieved 2026-08-24
- <https://docs.python.org/3/library/unittest.mock.html> — "patch where
  looked up, not where defined," `autospec`/`create_autospec`
  signature-checking behavior — retrieved 2026-08-24
- <https://martinfowler.com/articles/mocksArentStubs.html> — mock vs. stub
  distinction, over-mocking/mockist-test risks, guidance to mock awkward
  collaborations and pair with coarser integration tests — retrieved
  2026-08-24
- <https://docs.pytest.org/en/stable/how-to/parametrize.html> —
  `pytest.mark.parametrize` purpose, stacking, `pytest.param()` per-case
  marks — retrieved 2026-08-24
- <https://docs.pytest.org/en/stable/how-to/assert.html> — `pytest.raises()`
  context-manager form, `match` parameter (regex via `re.search()`),
  subclass-matching pitfall and `excinfo.type` fix — retrieved 2026-08-24
- <https://docs.pytest.org/en/stable/how-to/tmp_path.html> — `tmp_path`
  (function-scoped) and `tmp_path_factory` (session-scoped) filesystem
  isolation fixtures — retrieved 2026-08-24
- <https://pypi.org/project/pytest-randomly/> — test-order randomization
  rationale, deterministic seed reset, current version (4.1.0, 2026-04-20)
  — retrieved 2026-08-24
- <https://pypi.org/project/pytest-socket/> — network-call blocking by
  default, opt-in exceptions, current version (0.8.1, 2026-08-19) —
  retrieved 2026-08-24
- <https://pypi.org/project/pytest-rerunfailures/> — automatic rerun of
  failed tests, `--max-suite-reruns`, current version (16.6, 2026-08-17);
  docs do not themselves caution against masking root-cause flakiness —
  retrieved 2026-08-24
- <https://pypi.org/project/time-machine/> — time-machine identity, current
  version (3.4.0, 2026-08-10), Production/Stable — retrieved 2026-08-24
- <https://time-machine.readthedocs.io/en/latest/comparison.html> —
  time-machine's own documented comparison against freezegun (mocking
  mechanism, performance, class-attribute and C-extension gaps) —
  retrieved 2026-08-24 (freezegun-vs-time-machine check)
- <https://pypi.org/project/freezegun/> — freezegun current version
  (1.5.5, 2025-08-09), supported Python range (3.8–3.13), maintenance
  status — retrieved 2026-08-24 (freezegun-vs-time-machine check)
- <https://mutmut.readthedocs.io/en/latest/> — mutation testing identity
  and mechanism (mutate code, verify tests catch it) — retrieved 2026-08-24
- `research/python-code-review/testing.md` (this repo) — the approved
  research baseline this reference was authored from, including source
  retrieval dates and the resolutions this document implements — read
  2026-08-24
- `skills/project-incubation/references/architecture-principles.md` §7–8
  (this repo) — Testability vs. TDD distinction, cross-referenced rather
  than duplicated — read 2026-08-24
