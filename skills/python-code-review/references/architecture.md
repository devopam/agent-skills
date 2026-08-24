# Architecture

This is the reference `python-code-review` applies when judging whether
Python code is *structured* correctly: business logic separated from
framework plumbing, an importable interface that keeps its promises across
versions, a database credential model that doesn't hand every code path
admin rights, and a deployment shape (process manager, worker count, health
probes, container build) that will actually survive production rather than
merely start up once in a demo. It is a structural lens, not a correctness
or a safety lens — two adjacent domains own territory this file
deliberately doesn't duplicate.

**Security owns correctness, this domain owns presence.** CORS
misconfiguration, JWT/algorithm-confusion vulnerabilities, and rate-limit
threshold tuning are [Security](../references/security.md)'s checklist
items, sourced against OWASP's own API and authentication guidance. This
domain's middleware check stops at "is the control wired into the app at
all" — see [Middleware](#middleware-structural-presence-not-correctness)
below for exactly where that line falls and why. **Performance owns the
connection-pool parameter table**, not this file — see
[Database Architecture](#database-architecture) for the one architectural
implication of pooling this domain does keep. **Standards Compliance owns
packaging and distribution** — `pyproject.toml` build-backend correctness,
wheel/sdist completeness, PyPI publishing — at
[`standards-compliance.md`](../references/standards-compliance.md), not
here.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [Separation of Concerns](#separation-of-concerns)
- [API and Interface Design: Backward Compatibility](#api-and-interface-design-backward-compatibility)
  - [Semantic Versioning Discipline](#semantic-versioning-discipline)
  - [`DeprecationWarning`: Necessary, Not Sufficient](#deprecationwarning-necessary-not-sufficient)
  - [Migration Windows](#migration-windows)
  - [Docstring-as-Contract](#docstring-as-contract)
  - [The Boolean Trap](#the-boolean-trap)
- [Web API Endpoint Design](#web-api-endpoint-design)
- [Database Architecture](#database-architecture)
  - [Credentials and Role Segregation](#credentials-and-role-segregation)
  - [Connection Pooling — Architecture's Lens Only](#connection-pooling--architectures-lens-only)
  - [Migration Safety](#migration-safety)
  - [Dual-Identifier Pattern](#dual-identifier-pattern)
- [ASGI/WSGI Deployment and Process Management](#asgiwsgi-deployment-and-process-management)
  - [Development Server in Production](#development-server-in-production)
  - [Gunicorn + Uvicorn Worker Class](#gunicorn--uvicorn-worker-class)
  - [Uvicorn's Native Multi-Worker Mode](#uvicorns-native-multi-worker-mode)
  - [Granian](#granian)
  - [Worker Count: A Formula, Not a Mandate](#worker-count-a-formula-not-a-mandate)
  - [Worker Lifecycle and Request Limits](#worker-lifecycle-and-request-limits)
- [Health, Readiness, and Startup Probes](#health-readiness-and-startup-probes)
- [Middleware: Structural Presence, Not Correctness](#middleware-structural-presence-not-correctness)
- [Container and Network Hardening](#container-and-network-hardening)
- [Documentation and Minor Findings](#documentation-and-minor-findings)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Required Evidence in Findings](#required-evidence-in-findings)
- [Sources](#sources)

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Separation of concerns | Yes | Yes | Yes |
| App credentials ≠ admin credentials (Critical) | No | Yes | Yes |
| DB role segregation (reasoned pattern, not a fixed count) | No | Yes | Yes |
| Semver/deprecation discipline for importable public interfaces | Yes (if published) | Yes | Yes |
| Boolean-positional-parameter hygiene (Ruff FBT) | No | Yes | Yes |
| Docstring-as-contract completeness (Args/Returns/Raises) | No | Yes | Yes |
| Development server not used in production (Critical) | No | Yes | Yes |
| Worker count reasoning present (formula or documented deviation) | No | Yes | Yes |
| Health/ready endpoints present | No | Yes | Yes |
| Startup probe present for slow-initializing services | No | Optional | Yes |
| URL-path API versioning | No | Yes | Yes |
| Middleware structural presence (CORS/rate-limit/auth wired in — see Security for correctness) | No | Yes | Yes |
| Dockerfile: multi-stage, non-root, minimal base | No | Optional | Yes |
| Reverse proxy in front of app server | No | No | Yes |
| Service mesh / mTLS / network topology | No | No | Yes |

A script-tier project still benefits from separation of concerns and, if
it's published or imported by anything else, semver/deprecation discipline
— both cost nothing to apply regardless of scale. Everything that only
matters once a service is deployed under sustained traffic — DB role
segregation, worker-count reasoning, probes, middleware wiring, container
hardening, network topology — is gated to web/enterprise, the same split
`performance.md` and `security.md` use for their own infrastructure-
dependent checks. Semver/deprecation discipline is the one item promoted to
script-tier relative to the original version of this checklist: a
one-off script has no public interface to keep stable, but a published or
internally-imported module does, regardless of whether it's ever fronted by
a web server.

## Separation of Concerns

The foundational, all-tiers check: business logic free of framework
objects reaching the service layer (no raw `Request`/`Depends` objects
passed past the controller boundary), controllers/views extracting scalar
values before calling service functions, data access separated from
business logic, and configuration isolated in one place rather than
scattered as inline constants throughout the codebase. Dependency injection
— constructing collaborators at the composition root and passing them in,
rather than a service function reaching for a global or constructing its
own dependencies inline — is part of the same discipline, not a separate
checklist item: it's what makes "business logic free of framework objects"
achievable in practice, since a service function that can't be constructed
without a live framework context can't be free of framework objects either.

This is a general software-design principle rather than a claim needing a
dated citation, and it's the least contentious check in this domain — but
it's also the one a reviewer should never skip in the rush to reach the
more sourced sections below. A codebase that fails this check makes every
other Architecture finding harder to act on: fixing a deployment or
API-versioning defect is straightforward in a codebase with clean
boundaries, and entangled with framework internals in one without them.

## API and Interface Design: Backward Compatibility

The original version of this checklist scoped "API design" to web
endpoints only — `/health`, versioning, error format. That's too narrow:
*any* Python project with an importable public interface — a published
library, or an internal package other services import, not just a web
service — needs the same interface-stability discipline. A breaking
signature or behavior change shipped with no version signal and no
deprecation window is a defect whether it reaches callers over HTTP or
over an `import` statement.

### Semantic Versioning Discipline

[Semantic Versioning 2.0.0](https://semver.org/) is unambiguous about what
each version segment means: "increment the MAJOR version when you make
incompatible API changes," MINOR "when you add functionality in a backward
compatible manner," PATCH "when you make backward compatible bug fixes."
On deprecation specifically, the spec states: "When you deprecate part of
your public API, you should do two things: (1) update your documentation
to let users know about the change, (2) issue a new minor release with the
deprecation in place" — i.e., deprecate in a MINOR release, remove only in
the next MAJOR.

**Review angle:** a breaking signature or behavior change shipped in a
minor or patch release — no major bump, no prior deprecation window — is a
flaggable finding, not a style nit. The reverse also matters: a function
marked deprecated in a patch release, with no accompanying minor bump,
technically violates the spec's own MUST ("It MUST be incremented if any
public API functionality is marked as deprecated").

### `DeprecationWarning`: Necessary, Not Sufficient

Python's own `warnings` documentation defines `DeprecationWarning` as the
"base category for warnings about deprecated features when those warnings
are intended for other Python developers" — and critically, such warnings
are "ignored by default," except when triggered by code running in
`__main__`. In practice this means a library that only calls
`warnings.warn(..., DeprecationWarning)` is invisible to the *downstream
application* using it, unless that application has explicitly opted into
showing warnings (`-W`, `PYTHONWARNINGS`, or its own test suite's
`filterwarnings`).

**Review angle:** flag a deprecated function or parameter with no
`DeprecationWarning` at all — that's a silent-breakage risk at removal
time. But don't treat the mere *presence* of a `DeprecationWarning` as
sufficient on its own; note in review comments that the warning is
invisible by default outside `__main__`/test contexts, so it's a necessary
signal, not a substitute for changelog or migration-guide documentation of
the eventual removal.

### Migration Windows

[PEP 387](https://peps.python.org/pep-0387/), CPython's own Backwards
Compatibility Policy, gives the concrete, sourced version of "give users
time to migrate." Its current text sets a minimum: "Wait for the warning
to appear in at least two minor Python versions of the same major version,
or one minor version in an older major version" — and a *preferred*, more
generous target: "it is preferred, though, to wait 5 years before removal
(e.g., warn starting in Python 3.10, removal in 3.15)."

PEP 387 is CPython's own policy for its stdlib, not a universal rule every
project must match — cite it as the documented reference point for "how
long is reasonable," not as a mandate that every reviewed library wait
five years. **Review angle:** a deprecation removed in the very next
release — no intervening minor-version window at all — is the flaggable
pattern regardless of which exact window a given project has chosen to
adopt.

### Docstring-as-Contract

The [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings)'s
own reasoning for what belongs in a docstring's `Raises` section is the
sourced form of "docstring as contract." Its guidance states that "you
should not document exceptions that get raised if the API specified in the
docstring is violated (because this would paradoxically make behavior
under violation of the API part of the API)."

That treats a docstring's Args/Returns/Raises as defining the interface
contract for *correct* usage; behavior outside that contract is explicitly
not part of the promise. **Review angle:** a public function's docstring
that omits `Raises` for exceptions it deliberately raises on
valid-but-exceptional input — not API misuse — is an incomplete contract.
Conversely, don't flag a docstring for failing to document what happens
when a caller passes the wrong type entirely; per the guide's own
reasoning, that's explicitly outside the contract, not a gap in it.

### The Boolean Trap

Ruff's `flake8-boolean-trap` (FBT) category codifies a specific,
linter-backed form of the general compatibility guidance above: three
stable rules — `FBT001`/`boolean-type-hint-positional-argument`,
`FBT002`/`boolean-default-value-positional-argument`, and
`FBT003`/`boolean-positional-value-in-call` — flag boolean-typed or
boolean-defaulted positional parameters, and boolean literals passed
positionally at call sites. Ruff's own rationale: "Calling a function with
boolean positional arguments is confusing as the meaning of the boolean
value is not clear to the caller and to future readers of the code," and
it "will also limit the function to only two possible behaviors, which
makes the function difficult to extend in the future." Ruff's docs
attribute the term "boolean trap" to
[Adam Johnson's 2021 article](https://adamj.eu/tech/2021/07/09/python-type-hints-how-to-avoid-the-boolean-trap/)
of the same name, and recommend three fixes: split into two named
functions, use an `Enum`, or make the parameter keyword-only (`*, up:
bool`). Dunder methods that define operators, setters, and `@override`
definitions are exempted.

**Review angle:** a public function signature change that adds or reorders
positional boolean parameters is a textbook silent-behavior-inversion risk
across versions — `round_number(1.5, True)` reads as opaque at the call
site even before a later parameter reorder can silently invert its
meaning for existing callers. This is the concrete, linter-enforceable
form of the semver/deprecation guidance above, distinct enough to be worth
naming on its own in review.

## Web API Endpoint Design

The web-service-specific layer on top of the interface-stability
discipline above:

- `/health` and `/ready` endpoints present — see
  [Health, Readiness, and Startup Probes](#health-readiness-and-startup-probes)
  below for the full taxonomy these map onto.
- URL-path-based API versioning (`/api/v1/...`) so a breaking change ships
  as a new version rather than an in-place mutation of an existing one —
  the HTTP-surface application of the semver discipline above.
- A consistent error response format with error codes across the surface,
  rather than each endpoint inventing its own shape.

**Search and lookup endpoints should bound their result set, not ship a
specific number.** The original version of this checklist prescribed a
`min_score` default of 70 and a `max_output_records` default of 10 for
relevance-ranked search endpoints. Neither figure traces to any general
Python or web-API convention — they read as carried over from whatever
specific project the original checklist was authored against, not a
sourced or generalizable standard. The underlying principle is sound and
worth keeping: a search or lookup endpoint should bound its result-set
size, and where results are relevance-ranked, expose a relevance/score
threshold — without this checklist prescribing particular numbers. Flag
the *absence* of any bound (an endpoint that can return an unbounded
result set) or the absence of any relevance signal on a ranked endpoint;
don't flag a project's chosen threshold values against a number this
checklist doesn't actually source.

## Database Architecture

### Credentials and Role Segregation

**Database admin credentials used for application read/write operations is
a Critical finding**, unchanged from the original version of this
checklist and re-confirmed directly against OWASP's
[Database Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html):
"the accounts should only have the minimal permissions required for the
application to function," and "most applications would only need SELECT,
UPDATE and DELETE permissions" — with accounts explicitly "not the owner
of the database," since ownership "can lead to privilege escalation."

What OWASP's cheat sheet does **not** prescribe is a specific role count or
a readonly/writer/admin three-way split — it leaves the concrete role
architecture to implementers. A three-user segregation (readonly for GET
paths, writer for POST/PUT/DELETE, admin reserved for migrations) is a
reasonable, commonly-seen implementation of least privilege, and worth
suggesting as a pattern — but it's this checklist's own reasoned
elaboration of the sourced principle, not a named standard OWASP or a
database vendor prescribes as a target. Present it that way in review: the
underlying rule (app credentials must never be admin credentials) is
Critical and sourced; the specific shape of the split is a labeled
suggestion, matching how this skill's Code Quality domain treats
line-count heuristics that have no credible source behind the specific
number.

### Connection Pooling — Architecture's Lens Only

The sibling [`performance.md`](../references/performance.md) reference
owns the full SQLAlchemy connection-pool parameter table (`pool_size`,
`max_overflow`, `pool_timeout`, `pool_recycle`, `pool_pre_ping` — their
current defaults, and which of them are recommended production overrides
rather than defaults themselves) — link there rather than duplicating it
here.

This domain's lens on pooling is narrower and architectural, not a sizing
question: pooling is a per-credential resource-management decision. If the
DB role segregation above is in place, each role/credential needs its own
pool sized to its own traffic pattern — a readonly pool serving GET
endpoints and a writer pool serving mutating endpoints don't share the
same load shape, and sizing one shared pool for the aggregate hides that.
Flag a service with role-segregated credentials but a single, undifferentiated
pool configuration applied uniformly across all of them.

### Migration Safety

Unchanged from the original version of this checklist, and not
independently re-sourced this round — a general software-engineering
practice rather than a claim needing a dated citation:

- Migration scripts define both `upgrade()` and `downgrade()` — a
  migration with no rollback path turns any deployment issue into a
  one-way door.
- Autogenerated migrations are manually reviewed before merge, not
  auto-applied on trust — a migration file that looks untouched from its
  generated form is worth a second look for what the generator may have
  missed (a data-preserving intent the tool can't infer, an index the
  generator wouldn't add automatically).

### Dual-Identifier Pattern

An integer primary key used internally, paired with a UUID or NanoID
exposed at public-facing API boundaries, is a plausible and commonly seen
pattern in practice — it avoids leaking sequential row counts (and the
enumeration risk that comes with them) via public APIs, and decouples
internal storage keys from external identifiers. No primary source
establishes this as a named standard, so it's kept here as a suggested,
reasoned/common-practice pattern rather than a sourced rule — worth
raising as a recommendation on a public-facing API using bare sequential
integer IDs, not worth flagging as a defect on its own.

## ASGI/WSGI Deployment and Process Management

### Development Server in Production

**Critical, unchanged from the original checklist.** Flask's `flask run`
and Django's `manage.py runserver` are development conveniences — neither
is a production-grade process manager, and both say so in their own
startup output. A production deployment invoking either directly, with no
WSGI/ASGI server (Gunicorn, Uvicorn, Granian) in front, is a Critical
finding regardless of how well everything else in this section is
configured.

### Gunicorn + Uvicorn Worker Class

**The import path in wide circulation is deprecated.** Uvicorn's own
deployment docs carry an explicit warning: "The `uvicorn.workers` module
is deprecated and will be removed in a future release," directing users to
install the separately-maintained `uvicorn-worker` package instead. The
corrected invocation, verified directly against that package's own README,
is:

```
gunicorn example:app -w 4 -k uvicorn_worker.UvicornWorker
```

— note the module name changes from `uvicorn.workers` to `uvicorn_worker`
(underscore, no dot), not just the package that ships it. This is a
narrow, precise finding, not a verdict that Gunicorn-managed Uvicorn is
outdated: Gunicorn-managing-Uvicorn-workers remains a documented, current
pattern — only the import path changed. Worth noting for review context:
Uvicorn's own deployment page hasn't fully caught up to its own
deprecation notice — its top-level "general rule" bullets and its Gunicorn
usage examples still show `gunicorn -k uvicorn.workers.UvicornWorker`
immediately below the warning box that deprecates exactly that path. That
inconsistency in the upstream docs is very likely why the deprecated
invocation keeps turning up in code review — it isn't only inherited from
stale tutorials.

Django and Flask deployments -> Gunicorn with a sync (or `gthread`/gevent)
worker class are unaffected by any of this; the deprecated import path is
specific to the Uvicorn worker class used for ASGI apps.

### Uvicorn's Native Multi-Worker Mode

Uvicorn documents its own multi-process support as an alternative to
Gunicorn-managed workers: "Uvicorn includes a `--workers` option that
allows you to run multiple worker processes." Its process model differs
from Gunicorn's pre-fork approach — it "does not use pre-fork, but uses
`spawn`, which allows uvicorn's multiprocess manager to still work well on
Windows," where Gunicorn's pre-fork model doesn't apply at all (Gunicorn
has no native Windows support). Uvicorn's built-in manager also handles
worker restarts on unexpected death, and responds to `SIGHUP` (rolling
restart), `SIGTTIN`/`SIGTTOU` (scale workers up/down at runtime).

**Review angle:** either pattern — Gunicorn managing `uvicorn_worker`, or
Uvicorn's own `--workers` — is defensible; treat them as peer options, not
a migration recommendation in either direction. What's actually flaggable
is the deprecated `uvicorn.workers` import path specifically, and the
absence of *any* process-manager or worker-count reasoning at all (a
single Uvicorn process invoked directly in production, with no `--workers`
and no external manager).

### Granian

[Granian](https://pypi.org/project/granian/) is a real, currently
maintained Rust-based ASGI/RSGI/WSGI server (current: 2.8.2,
"Production/Stable" classifier on PyPI), with stated production adopters
including paperless-ngx, reflex, searxng, and companies including
Microsoft, Mozilla, and Sentry. It's worth naming to an author choosing an
application server as a real, current option alongside Uvicorn and
Gunicorn — this checklist makes no claim about its adoption trajectory
relative to either; that comparison hasn't been sourced.

### Worker Count: A Formula, Not a Mandate

Gunicorn's own design documentation gives a starting formula: `workers =
(2 × CPU cores) + 1`. This is Gunicorn's own documented recommendation,
not a folk heuristic — but the same document immediately qualifies it in
the surrounding text: "Workers ≠ clients. Gunicorn typically needs only
4–12 workers to handle heavy traffic. Too many workers waste resources and
can reduce throughput," introducing the formula itself with "start with
this formula and adjust under load."

The docs don't differentiate the formula by worker class (sync vs.
`gthread`/gevent/Uvicorn) or by workload shape (CPU-bound vs. I/O-bound).
**Review angle:** flag a Gunicorn deployment with no worker-count reasoning
at all — a bare default `-w 1`, or an arbitrarily large number with no
load-testing basis behind it — rather than mechanically enforcing the
formula's output as a hard target. The formula's own "adjust under load"
framing means a documented deviation from it is not itself a defect.

### Worker Lifecycle and Request Limits

Three further Gunicorn settings, verified directly against its own
settings reference, that a production deployment is worth checking for
explicit reasoning on rather than accepting silently at their defaults:

- **`timeout`** (default `30` seconds) — "workers silent for more than
  this many seconds are killed and restarted." The docs' own guidance:
  "generally, the default of thirty seconds should suffice" for sync
  workers; raise it only with a specific reason, since a timeout set too
  high delays detection of a genuinely hung worker.
- **`max_requests`** (default `0`, meaning disabled) paired with
  **`max_requests_jitter`** (default `0`) — restarting a worker after it's
  handled `max_requests` requests is Gunicorn's own documented mitigation
  for gradual memory leaks; the jitter setting staggers those restarts so
  workers don't all recycle simultaneously. Both are opt-in, not
  defaults — a long-running service with no `max_requests` configured has
  no defense against a slow leak in any dependency, framework, or
  application code, and it's worth asking whether that's an intentional
  choice.
- **`limit_request_field_size`** (default `8190` bytes) — bounds a
  single HTTP header field's size as a DoS defense; a service handling
  unusually large headers (bearer tokens, custom auth schemes) that raises
  this default should do so deliberately and visibly, not by trial and
  error against production errors.

## Health, Readiness, and Startup Probes

Kubernetes' own pod-lifecycle documentation defines three distinct probe
types with genuinely different failure consequences, and treating them as
interchangeable is the gap this section corrects over a generic "add a
`/health` endpoint" treatment:

- **Liveness** — failure causes the kubelet to restart the container. Fit:
  detecting hangs and deadlocks in an otherwise-running process.
- **Readiness** — failure removes the pod from the Service's
  load-balancing endpoint list, *without* restarting it. Fit: "not
  currently able to serve traffic" — a dependency that's temporarily
  unreachable, a warm-up phase, graceful drain during shutdown.
- **Startup** — failure restarts the container, same consequence as
  liveness, but it exists to gate liveness/readiness checks until initial
  startup completes. Kubernetes' own docs title this use case "Protect
  slow starting containers with startup probes," confirmed directly
  against that page's own section heading.

That startup-probe framing is the concrete addition this section makes
over the original checklist's generic `/health` + `/ready` treatment: a
slow-initializing Python service — a large model or config load, cold-start
dependency checks — that only has a liveness probe with an aggressive
`initialDelaySeconds` is at risk of being killed in a restart loop before
it ever finishes starting. A startup probe is the documented fix for
exactly that failure mode, not an optional third endpoint layered on for
completeness.

**Review angle:** a service with a liveness probe but no startup probe
*and* a non-trivial startup time (DB migrations, model loading, cache
warming) is a flaggable gap. `/health` generally maps to liveness, `/ready`
to readiness, and a startup-specific check — even one reusing the
`/health` path but configured with a longer `initialDelaySeconds` on the
startup probe specifically — covers the third case.

## Middleware: Structural Presence, Not Correctness

Most of the original version of this checklist's "Middleware" subsection
re-lists controls this skill's Security domain already owns in depth: CORS
policy is Security's explicit checklist item; JWT and broken-authentication
handling is Security's checklist item (`alg:none` rejection, HMAC entropy,
algorithm confusion); rate limiting is covered under Security's OWASP
API4:2023 mapping. Restating those controls' *correctness* here would
duplicate review work the sibling domain already does with sourced
specificity — see [`security.md`](../references/security.md) for CORS,
authentication, and rate-limit correctness.

**What stays here is narrower: is the control present and wired into the
application at all**, independent of whether its configuration is
correct — that presence/wiring question is this domain's structural lens,
distinct from Security's correctness lens on the same controls. Two items
Security's checklist doesn't cover stay owned here outright, with no
cross-reference needed:

- **`TrustedHostMiddleware`** (or the equivalent host-header validation
  for the framework in use) present.
- **Request/response logging middleware** present and wired into the
  application, giving the service an audit trail independent of
  application-level logging calls.

## Container and Network Hardening

Unchanged from the original version of this checklist and not
independently re-sourced this round — Security's checklist covers secrets
appearing in Dockerfile `ENV`/`ARG` values, but container build structure
itself stays this domain's deployment lens:

- **Multi-stage builds** — a builder stage compiling dependencies, a
  separate minimal runtime stage that copies only build artifacts across.
- **Build tools absent from the final image** — `gcc`, `make`, and similar
  present in the builder stage only, not carried into the image that
  actually runs in production.
- **Non-root user** — an explicit `USER appuser`-style directive, not the
  image's default root user, running the application process.
- **Distroless or minimal base image preferred** over a full OS base
  image, reducing both image size and attack surface.

At enterprise tier, two further structural checks:

- **A reverse proxy (nginx, an ALB, or equivalent) in front of the
  application server**, rather than the app server directly exposed to
  the internet — Gunicorn's own deployment docs recommend exactly this
  shape, alongside `--forwarded-allow-ips` configuration so the app
  correctly trusts `X-Forwarded-*` headers only from the proxy itself.
  TLS termination at the proxy layer is part of the same check.
- **Service mesh / mTLS / network topology** — workload identity and
  mutual TLS between internal services, gated to enterprise tier since
  script- and single-service web deployments have no internal service
  boundary for a mesh to secure.

## Documentation and Minor Findings

Low-severity, unchanged from the original checklist:

- API documentation auto-generated (OpenAPI/Swagger) rather than
  hand-maintained and prone to drifting out of sync with the actual
  endpoints.
- Database schema documented or visualized.
- Architecture Decision Records (ADRs) present for major structural
  choices.
- README includes an architecture overview or diagram, giving a new
  contributor a map before they have to reconstruct one from the code.

## Out of Scope

- **Connection-pool parameter tuning table** (`pool_size`, `max_overflow`,
  `pool_timeout`, `pool_recycle`, `pool_pre_ping`) — owned by
  [`performance.md`](../references/performance.md); this domain keeps only
  the per-credential architectural implication, see
  [Connection Pooling](#connection-pooling--architectures-lens-only) above.
- **CORS/JWT/rate-limit control *correctness*** — owned by
  [`security.md`](../references/security.md); this domain keeps only the
  structural presence/wiring check, see
  [Middleware](#middleware-structural-presence-not-correctness) above.
- **Packaging and distribution** (`pyproject.toml` build-backend
  correctness, wheel/sdist completeness, PyPI publishing) —
  [Standards Compliance](../references/standards-compliance.md)'s domain,
  not this one's.
- **A separate Database/Migrations domain.** Migration safety stays inside
  this domain's existing Database Architecture section rather than
  splitting out — the scoping work behind this reference considered and
  rejected a standalone domain for it.
- **Framework-specific ORM session/connection-pool wiring**
  (`pytest-django`-style per-request session patterns, framework
  middleware internals) — stack-specific, deferred to a future
  stack-specific overlay rather than this domain's altitude.
- **Granian's adoption trajectory relative to Uvicorn/Gunicorn.**
  Granian's current status (production-stable, real cited adopters) is
  stated as fact above; a comparative "which is more common now" claim
  isn't sourced here and shouldn't be asserted in review output.

## Scoring Guide

- **10** — Clean separation of concerns throughout. Semver/deprecation
  discipline observed on every public interface change, with
  `DeprecationWarning` present ahead of any removal and a documented
  migration window. No boolean-positional-parameter additions on public
  signatures. App credentials never touch admin operations; DB roles
  segregated by access pattern. Health, readiness, and (where startup time
  is non-trivial) startup probes all present and correctly mapped. Worker
  count and lifecycle settings (`timeout`, `max_requests`, header limits)
  explicitly reasoned, not left at silent defaults. Container build
  multi-stage, non-root, minimal base.
- **8-9** — The above, with minor gaps: one missing migration-window
  citation on an otherwise-correct deprecation, a `TrustedHostMiddleware`
  omission, a reverse proxy present but `--forwarded-allow-ips` not
  configured.
- **6-7** — Real but contained issues: a breaking change shipped without a
  version bump on one interface, DB role segregation absent but
  credentials still correctly scoped below admin, no worker-count
  reasoning documented, missing startup probe on a service with real
  startup latency.
- **4-5** — Business logic materially coupled to framework objects, no
  health/ready endpoints on a web service, a Gunicorn deployment on the
  deprecated `uvicorn.workers` import path with no other worker-management
  reasoning present, or repeated boolean-positional public-signature
  changes with no deprecation path.
- **1-3** — A development server (`flask run`, `manage.py runserver`)
  serving production traffic, database admin credentials used for
  application read/write operations, or a monolith with no separation of
  concerns and no deployment configuration at all.

## Required Evidence in Findings

Each finding in this domain must include:

- **Severity** — Critical / Important / Minor.
- **Category** — one of: Separation-of-Concerns / API-Compatibility /
  DB-Architecture / Deployment / Probes / Middleware-Wiring /
  Container-Hardening / Documentation.
- **File and line number** (or the deployment artifact — Dockerfile,
  process-manager config, CI pipeline step — when the finding isn't
  Python source).
- **Structural mechanism** — one sentence on *why* the structure is wrong
  (e.g. "no `DeprecationWarning` on a removed public parameter, and no
  minor-version window between deprecation and removal — downstream
  callers get no signal before breakage"), not just a rule citation.
- **Fix** — a concrete, structural remediation, not a restatement of the
  finding as advice.

## Sources

- <https://semver.org/> — Semantic Versioning 2.0.0: MAJOR/MINOR/PATCH
  definitions and the two-step deprecation guidance ("issue a new minor
  release with the deprecation in place"); text cross-checked verbatim
  against `raw.githubusercontent.com/semver/semver/master/semver.md` —
  retrieved 2026-08-24.
- <https://docs.python.org/3/library/warnings.html#warning-categories> —
  `DeprecationWarning`'s default-filter behavior (ignored outside
  `__main__`) — retrieved 2026-08-24.
- <https://peps.python.org/pep-0387/> — PEP 387, Python's Backwards
  Compatibility Policy; minimum two-minor-version deprecation window,
  preferred 5-year removal target; text verified verbatim against
  `raw.githubusercontent.com/python/peps/main/peps/pep-0387.rst` —
  retrieved 2026-08-24.
- <https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings>
  — docstring Args/Returns/Raises convention; the "paradoxically make
  behavior under violation of the API part of the API" line verified
  verbatim directly against the published page's HTML — retrieved
  2026-08-24.
- <https://docs.astral.sh/ruff/rules/boolean-type-hint-positional-argument/>
  — FBT001 rule page, verified verbatim directly (rationale, "boolean
  trap" attribution to Adam Johnson, dunder/setter/`@override`
  exemptions, recommended fixes); FBT002/FBT003 confirmed via Ruff's FBT
  rule-category listing — retrieved 2026-08-24.
- <https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html>
  — least-privilege principle for DB accounts, verified verbatim directly
  ("the accounts should only have the minimal permissions required...",
  "most applications would only need SELECT, UPDATE and DELETE
  permissions"); confirms no specific role-count/segregation pattern is
  prescribed — retrieved 2026-08-24.
- [`performance.md`](../references/performance.md) (this skill) —
  SQLAlchemy connection-pool parameter table and current defaults,
  cross-referenced rather than duplicated.
- <https://raw.githubusercontent.com/Kludex/uvicorn/main/docs/deployment/index.md>
  — Uvicorn's current deployment docs (repository moved from
  `encode/uvicorn` to `Kludex/uvicorn`, the maintainer's fork now
  canonical upstream); `uvicorn.workers` deprecation warning and native
  `--workers`/`spawn` multiprocess support, both verified verbatim
  directly against the raw file — retrieved 2026-08-24.
- <https://raw.githubusercontent.com/Kludex/uvicorn-worker/master/README.md>
  — the replacement package's own README, verified verbatim directly for
  the corrected invocation
  (`gunicorn example:app -w 4 -k uvicorn_worker.UvicornWorker`) —
  retrieved 2026-08-24.
- <https://pypi.org/project/uvicorn-worker/> — current version 0.4.0,
  released 2025-09-20 — retrieved 2026-08-24.
- <https://raw.githubusercontent.com/benoitc/gunicorn/master/docs/content/design.md>
  — Gunicorn's own worker-count formula `(2 × CPU cores) + 1`, the
  "Workers ≠ clients... 4–12 workers... waste resources" caveat, and the
  "start with this formula and adjust under load" framing, all verified
  verbatim directly against the raw file — retrieved 2026-08-24.
- <https://raw.githubusercontent.com/benoitc/gunicorn/master/docs/content/reference/settings.md>
  — `timeout` (default 30s), `max_requests`/`max_requests_jitter`
  (default 0/disabled), and `limit_request_field_size` (default 8190
  bytes) defaults and documented purpose, verified verbatim directly
  against the raw file — retrieved 2026-08-24.
- <https://raw.githubusercontent.com/benoitc/gunicorn/master/docs/content/deploy.md>
  — reverse-proxy recommendation (Nginx), `--forwarded-allow-ips`
  guidance — retrieved 2026-08-24.
- <https://pypi.org/project/granian/> — Granian identity, current version
  2.8.2, Production/Stable status, cited production adopters
  (paperless-ngx, reflex, searxng, Microsoft, Mozilla, Sentry) — retrieved
  2026-08-24.
- <https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#types-of-probe>
  — three probe types (liveness/readiness/startup), restart-vs-traffic-
  routing failure-consequence distinction — retrieved 2026-08-24.
- <https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/>
  — "Protect slow starting containers with startup probes" section
  heading, verified verbatim directly against the published page —
  retrieved 2026-08-24.
- [`security.md`](../references/security.md) (this skill) — confirms
  CORS, JWT/broken-auth, and rate-limiting (API4:2023) are already
  Security's checklist items, driving the middleware domain-boundary
  distinction above.
- `research/python-code-review/architecture.md` (this repo) — the
  user-approved research baseline this reference was authored from,
  including the Checkpoint C resolutions this document implements.
- `research/python-code-review/original-tool/review-domains/architecture.md`
  (this repo) — the original checklist this domain expands and corrects.
