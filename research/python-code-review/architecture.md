# Baseline: Architecture
Status: user-approved      Date: 2026-08-24

## Resolutions (Checkpoint C review, 2026-08-24)

- **Granian adoption trajectory**: mention as a real, current, production-
  stable option alongside Uvicorn/Gunicorn without asserting a
  displacement trend — comparative adoption deferred to a future
  verification pass if ever needed.
- **3-user DB segregation framing**: confirmed — keep as a suggested,
  explicitly-labeled-reasoned implementation of OWASP's sourced
  least-privilege principle, matching Code Quality's "40 lines" treatment.
- **`min_score`/`max_output_records` defaults**: confirmed — remove the
  specific numbers, keep the generic bound-result-size/expose-relevance-
  threshold principle.
- **Middleware domain-boundary correction**: confirmed — Architecture
  keeps structural presence/wiring only; CORS/JWT/rate-limit correctness
  stays Security's lens, cross-referenced not duplicated.

## In scope

- **Separation of concerns (structural review lens)** — impact: high —
  depth: paragraph. Retained from the original tool's domain unchanged in
  substance: business logic free of framework objects (no raw
  `Request`/`Depends` objects reaching the service layer), controllers/views
  extracting scalar values before calling service functions, data access
  separated from business logic, configuration isolated rather than
  scattered as inline constants. Not independently re-sourced this session
  — this is a general software-design principle rather than a claim needing
  a dated citation, and it was already the least contentious part of the
  original file. Kept as Architecture's foundational, all-tiers check.

- **API/interface design & backward compatibility — the required expansion**
  — impact: high — depth: section. This is the scoping doc's confirmed gap:
  the original "API Design" subsection covered only web endpoints
  (`/health`, versioning, error format); the real gap is that *any* Python
  project with an importable public interface (a library, an internal
  package other services import, not just a web service) needs the same
  interface-stability discipline. Four sourced pieces:
  - **Semver discipline** (semver.org, the canonical spec): "increment the
    MAJOR version when you make incompatible API changes," MINOR for
    backward-compatible additions, PATCH for backward-compatible bug fixes.
    On deprecation specifically: "When you deprecate part of your public
    API, you should do two things: (1) update your documentation to let
    users know about the change, (2) issue a new minor release with the
    deprecation in place" — i.e., deprecate in a MINOR release, remove only
    in the next MAJOR. Review angle: a breaking signature/behavior change
    shipped in a minor/patch release (no major bump, no prior deprecation
    window) is a flaggable finding, not a style nit.
  - **`DeprecationWarning` usage** (Python's own `warnings` docs): defined
    as the "base category for warnings about deprecated features when
    those warnings are intended for other Python developers (ignored by
    default, unless triggered by code in `__main__`)" — the default filter
    is `ignore::DeprecationWarning` everywhere except `__main__`, which
    means a library that only calls `warnings.warn(..., DeprecationWarning)`
    is invisible to the *downstream application* using it unless that
    application has opted into showing warnings (`-W`, `PYTHONWARNINGS`, or
    its own test suite's `filterwarnings`). Review angle: flag deprecated
    functions/parameters with no `DeprecationWarning` at all (silent
    breakage risk at removal time) — but don't treat the mere presence of
    `DeprecationWarning` as sufficient; note in review comments that the
    warning is invisible by default outside `__main__`/test contexts, so it
    is necessary but not a substitute for changelog/migration-guide
    documentation of the removal.
  - **Migration windows** (PEP 387, Python's own Backwards Compatibility
    Policy — the concrete, sourced version of "give users time"): minimum
    "wait for the warning to appear in at least two minor Python versions
    of the same major version, or one minor version in an older major
    version" before removal, with a *preferred*, more generous target of
    "5 years before removal." PEP 387 is CPython's own policy for its
    stdlib, not a universal rule every project must match — cite it as the
    documented reference point for "how long is reasonable," not as a
    mandate that every reviewed library must wait 5 years. Review angle:
    a deprecation removed in the very next release (no intervening
    minor/version window at all) is the flaggable pattern regardless of
    which exact window a project chooses.
  - **Docstring-as-contract** (Google Python Style Guide, docstring
    section): the guide's own reasoning for *excluding* API-violation
    exceptions from the Raises section is the sourced form of "docstring as
    contract" — "you should not document exceptions that get raised if the
    API specified in the docstring is violated (because this would
    paradoxically make behavior under violation of the API part of the
    API)." This treats the docstring's Args/Returns/Raises as defining the
    interface contract for *correct* usage; behavior outside that contract
    is explicitly not part of the promise. Review angle: a public
    function's docstring that omits Raises for exceptions it deliberately
    raises on valid-but-exceptional input (not API misuse) is an incomplete
    contract; conversely, don't flag a docstring for not documenting what
    happens when the caller passes the wrong type entirely.
  - **`flake8-boolean-trap` (FBT)** (Ruff's own rule docs, verified
    directly, retrieved this session): three stable rules —
    `FBT001`/`boolean-type-hint-positional-argument`,
    `FBT002`/`boolean-default-value-positional-argument`,
    `FBT003`/`boolean-positional-value-in-call` — flagging boolean-typed or
    boolean-defaulted positional parameters, and boolean literals passed
    positionally at call sites. Ruff's own rationale: "Calling a function
    with boolean positional arguments is confusing as the meaning of the
    boolean value is not clear to the caller" (e.g. `round_number(1.5,
    True)` — what does `True` mean at the call site, and does a later
    reordering of parameters silently invert its meaning for existing
    callers). Ruff's own docs attribute the term "boolean trap" to Adam
    Johnson's 2021 article and recommend three fixes: split into two named
    functions, use an `Enum`, or make the boolean keyword-only
    (`*, up: bool`). Dunder methods, setters, and `@override` are exempted.
    Review angle: a public function signature change that adds/reorders
    positional boolean parameters is a textbook silent-behavior-inversion
    risk across versions — the concrete, linter-backed form the scoping
    doc asked for, distinct from the general semver/deprecation guidance
    above.

- **Database architecture — 3-user segregation is a judgment call, not a
  sourced standard** — impact: high — depth: paragraph. Checked directly
  against OWASP's Database Security Cheat Sheet: it establishes the
  underlying principle ("the accounts should only have the minimal
  permissions required for the application to function," "most
  applications would only need `SELECT`, `UPDATE` and `DELETE`
  permissions," accounts should be "used by a single application or
  service") but **does not prescribe a specific role count or a
  readonly/writer/admin three-way split** — it leaves the concrete role
  architecture to implementers. This is the same shape of finding Code
  Quality's baseline made for "40 lines": the underlying principle (app
  credentials must never be admin credentials — already the original
  tool's sourced Critical item, and it stays Critical) is sound and
  sourced; the specific "3 users" number is this research's own reasoned
  elaboration of least privilege, not something OWASP or a database vendor
  states as a target. Keep the readonly/writer/admin split as an example
  pattern worth suggesting, explicitly labeled as a reasonable
  implementation of least privilege rather than a named standard.

- **Connection pooling — architecture-level implication only, parameter
  table owned by Performance** — impact: med — depth: paragraph. The
  sibling `performance.md` baseline already sources the full SQLAlchemy
  pooling parameter table (`pool_size`=5, `max_overflow`=10,
  `pool_timeout`=30.0, `pool_recycle`=-1/off, `pool_pre_ping`=False — all
  verified against SQLAlchemy 2.0's own pooling docs). **Correction against
  the original architecture.md**: its line `pool_size=5, max_overflow=10,
  pool_timeout=30, pool_recycle=3600, pool_pre_ping=True` presents all five
  as one uniform class of setting, but per SQLAlchemy's own documented
  defaults only the first three (`pool_size`, `max_overflow`,
  `pool_timeout`) *are* the defaults — `pool_recycle=3600` and
  `pool_pre_ping=True` are recommended production **overrides** of
  SQLAlchemy's off/`False` defaults, not defaults themselves. Architecture's
  lens on this (distinct from Performance's parameter-tuning lens): pooling
  is a per-credential resource-management decision — if DB user segregation
  (above) is in place, each role/credential needs its own pool sized to its
  own traffic pattern, not one shared pool sized for the aggregate. Point
  to `performance.md` for the parameter table itself; don't restate it here.

- **ASGI/WSGI deployment pattern — corrected, not just re-verified** —
  impact: high — depth: section. Checked directly against Uvicorn's current
  docs (`Kludex/uvicorn` — the repository moved from `encode/uvicorn`; the
  maintainer's fork is now the canonical upstream) and Gunicorn's own repo
  docs. Two real, dated findings:
  - The original's exact invocation — `gunicorn -k
    uvicorn.workers.UvicornWorker` — is now a **deprecated import path**.
    Uvicorn's own deployment docs state the `uvicorn.workers` module "is
    deprecated and will be removed in a future release," and direct users
    to the separately-maintained `uvicorn-worker` package (`pip install
    uvicorn-worker`, current PyPI version 0.4.0, released 2025-09-20)
    instead — the invocation becomes `gunicorn -k
    uvicorn_worker.UvicornWorker`. This is a narrow, precise finding, not a
    verdict that "Gunicorn-managed Uvicorn is outdated": Gunicorn-managed
    Uvicorn workers remain a documented, current pattern — only the import
    path changed.
  - Uvicorn's docs now also document its **own** native multi-worker
    support: "Uvicorn includes a `--workers` option that allows you to run
    multiple worker processes," using `spawn` rather than Gunicorn's
    pre-fork model — which the docs note as the reason "uvicorn's
    multiprocess manager [works] well on Windows" (where pre-fork doesn't
    apply). This is presented as an additional viable option alongside
    Gunicorn, not a replacement recommendation — review angle: either
    pattern (Gunicorn+`uvicorn-worker`, or Uvicorn's own `--workers`) is
    defensible; what's flaggable is the deprecated `uvicorn.workers` import
    path specifically, and the absence of *any* process manager / worker
    count reasoning at all (single-process Uvicorn directly in production).
  - **Granian** (a Rust-based ASGI/RSGI/WSGI server, verified via PyPI:
    current version 2.8.2, released 2026-08-23, "Production/Stable"
    classifier, stated production users include paperless-ngx, reflex,
    searxng, and companies including Microsoft, Mozilla, and Sentry) exists
    as a real, actively-maintained alternative. Uvicorn's own docs make no
    mention of it (expected — a project doesn't cite competitors), so its
    *relative* adoption trajectory versus Uvicorn/Gunicorn could not be
    surveyed this session (WebSearch budget was exhausted mid-research).
    State Granian's existence and current status honestly; do not claim
    it's displacing the Uvicorn/Gunicorn pattern without a comparative
    source. See Open Questions.
  - Django/Flask -> Gunicorn with sync (or gthread/gevent) worker class is
    unchanged from the original and not re-contested by anything found this
    session.

- **Worker count formula — sourced, but the caveats matter as much as the
  formula** — impact: high — depth: paragraph. Verified directly against
  Gunicorn's own `docs/content/design.md`: `workers = (2 × CPU cores) + 1`
  is Gunicorn's own documented starting formula — not a folk heuristic, a
  real primary-source claim. But the same document immediately qualifies
  it: "Workers ≠ clients. Gunicorn typically needs only 4–12 workers to
  handle heavy traffic," and cautions that over-provisioning "waste[s]
  resources and can reduce throughput" — framing the formula explicitly as
  "start with this formula and adjust under load," not a fixed target. The
  doc does not differentiate the formula by worker class (sync vs.
  gthread/gevent/uvicorn) or workload shape (CPU-bound vs. I/O-bound).
  Review angle: flag a Gunicorn deployment with no worker count reasoning
  at all (bare default `-w 1`, or an arbitrarily large number with no
  load-testing basis) rather than mechanically enforcing the formula's
  output as a hard number — the doc's own "adjust under load" framing means
  a documented deviation from the formula is not itself a defect.

- **Health/ready/startup endpoints — Kubernetes' own probe taxonomy as the
  precise standard** — impact: med — depth: paragraph. Verified against
  Kubernetes' own pod-lifecycle docs: three distinct probe types with
  different failure consequences — **liveness** (failure -> kubelet
  restarts the container; for detecting hangs/deadlocks), **readiness**
  (failure -> pod removed from the load-balancing/Service endpoint list,
  *not* restarted; for "not currently able to serve traffic"), and
  **startup** (failure -> container restarted; for apps with slow
  initialization, gating liveness/readiness checks until startup
  completes). Kubernetes' own docs title the startup-probe use case
  "Protect slow starting containers with startup probes" — this is the
  concrete addition over the original's generic `/health` + `/ready`
  treatment: a slow-initializing Python service (large model/config load,
  cold-start dependency checks) that only has a liveness probe with an
  aggressive `initialDelaySeconds` is at risk of being killed in a restart
  loop before it finishes starting; a startup probe is the documented fix,
  not just a "nice to have" third endpoint. Review angle: a service with a
  liveness probe but no startup probe *and* a non-trivial startup time
  (DB migrations, model loading, cache warming) is a flaggable gap;
  `/health` generally maps to liveness, `/ready` to readiness, and a
  startup-specific check (even reusing the `/health` path with a longer
  `initialDelaySeconds`) covers the third case.

- **Middleware — domain-boundary correction: most of it belongs to
  Security, not Architecture** — impact: high — depth: paragraph. Checked
  directly against this repo's own `security.md` baseline: CORS policy is
  already Security's explicit checklist item ("CORS policy — impact: med —
  depth: checklist"); JWT/broken authentication is already Security's
  checklist item (`alg:none` rejection, HMAC entropy, algorithm
  confusion); rate limiting is already covered under Security's OWASP
  API4:2023 mapping ("Unrestricted resource consumption"). The original
  architecture.md's "Middleware" subsection substantially re-lists these
  same controls under a different domain, which is a duplication the
  scoping doc's domain-boundary discipline argues against. **Resolution**:
  Architecture keeps a structural-completeness check ("is CORS/rate
  limiting/auth middleware present and wired into the app at all" —
  Architecture's presence/wiring lens) but the *correctness* of each
  control's configuration (wildcard CORS, JWT algorithm validation, rate
  limit thresholds) is Security's lens and should cross-reference, not
  restate, Security's checklist. `TrustedHostMiddleware` presence and
  request/response logging middleware were not found in `security.md`'s
  checklist and stay owned by Architecture as structural-completeness
  items with no cross-reference needed.

- **Deployment / container hardening — stays in Architecture, not
  duplicated elsewhere** — impact: med — depth: checklist. Checked against
  `security.md`: it covers secrets in Dockerfile `ENV`/`ARG` (hardcoded
  credentials, a Security concern) but not container hardening structure
  itself (multi-stage builds, non-root user, distroless/minimal base
  images, build-tool absence from the final image) — those stay
  Architecture's deployment-structure lens, unchanged from the original,
  not independently re-sourced this session as they weren't flagged by the
  scoping doc as a gap.

- **Search/lookup endpoint parameters (`min_score`, `max_output_records`)
  — project-specific artifact, not a general convention** — impact: low —
  depth: paragraph. No general Python or web-API convention prescribes a
  `min_score` default of 70 or a `max_output_records` default of 10 — this
  reads as carried over from whatever specific project the original tool
  was authored against, not a sourced or generalizable API design
  standard. Recommend removing the specific defaults and reframing the
  underlying (sound) principle generically: search/lookup endpoints should
  bound result-set size and, where relevance-ranked, expose a
  relevance/score threshold — without prescribing particular numbers.

- **Dual-identifier pattern (integer PK internal, UUID/NanoID external)**
  — impact: low — depth: paragraph. Plausible and commonly seen in
  practice (avoids leaking sequential row counts/enumeration via public
  APIs, decouples internal storage keys from external identifiers) but no
  primary source was fetched this session establishing it as a named
  standard. Keep as a suggested pattern, explicitly labeled reasoned/
  common-practice rather than sourced, consistent with this baseline's
  honesty bar.

- **Tier applicability** — impact: high — depth: table. Retains the
  original's table shape (`| Check | Script | Web | Enterprise |`,
  consistent with performance.md/security.md/testing.md's pattern), updated
  for the corrections above:

  | Check | Script | Web | Enterprise |
  |---|---|---|---|
  | Separation of concerns | Yes | Yes | Yes |
  | App credentials ≠ admin credentials (Critical) | No | Yes | Yes |
  | DB role segregation pattern (reasoned, not a fixed count) | No | Yes | Yes |
  | Semver/deprecation discipline for importable public interfaces | Yes (if published) | Yes | Yes |
  | `FBT` boolean-positional-parameter hygiene | No | Yes | Yes |
  | Docstring-as-contract completeness (Args/Returns/Raises) | No | Yes | Yes |
  | Health/ready endpoints present | No | Yes | Yes |
  | Startup probe present for slow-initializing services | No | Optional | Yes |
  | URL-path API versioning | No | Yes | Yes |
  | Middleware structural presence (CORS/rate-limit/auth wired in — cross-ref Security for correctness) | No | Yes | Yes |
  | Dockerfile: multi-stage, non-root, minimal base | No | Optional | Yes |
  | Worker count reasoning present (formula or documented deviation) | No | Yes | Yes |
  | Reverse proxy in front of app server | No | No | Yes |
  | Service mesh / mTLS / network topology | No | No | Yes |

  Rationale for the one upgrade from the original: semver/deprecation
  discipline now applies to script-tier too, conditional on the script
  being a published/importable module rather than a one-off — the scoping
  doc's stated reason for the expansion ("most Python projects, not just
  web services") is specifically about breadth of applicability, so gating
  it purely to web/enterprise would recreate the gap the expansion was
  meant to close.

## Explicitly out of scope

- **Connection-pool parameter tuning table** (`pool_size`, `max_overflow`,
  etc.) — owned by `performance.md`, cross-referenced above rather than
  duplicated.
- **CORS/JWT/rate-limit control correctness** — owned by `security.md`;
  Architecture keeps only the structural-presence check, per the
  domain-boundary finding above.
- **Packaging & distribution** (pyproject.toml build-backend, wheel/sdist,
  PyPI publishing) — per the scoping doc, this is Standards Compliance's
  gap (build/tooling config correctness), not Architecture's.
- **Separate Database/Migrations domain** — the scoping doc explicitly
  considered and rejected splitting this out; migration safety
  (`upgrade()`/`downgrade()` presence, reviewing autogenerated migrations)
  stays as Architecture's existing Database Architecture subsection,
  unchanged and not re-researched this session (not flagged as a gap).
- **Framework-specific ORM session/connection-pool wiring**
  (`pytest-django`-style per-request session patterns, framework
  middleware internals) — stack-specific, deferred to a future
  `research/stacks/` overlay, consistent with Testing's precedent for the
  same kind of framework-specific exclusion.
- **Granian vs. Uvicorn/Gunicorn adoption comparison** — Granian's current
  status was verified (production-stable, real adoption examples cited on
  its own PyPI page), but a comparative "which is more common now" claim
  could not be sourced this session (WebSearch budget exhausted) — see
  Open Questions rather than asserting a displacement trend.

## Sources

- https://semver.org/ — MAJOR/MINOR/PATCH definitions, deprecation
  guidance ("issue a new minor release with the deprecation in place")
  — retrieved 2026-08-24
- https://docs.python.org/3/library/warnings.html#warning-categories —
  `DeprecationWarning` default-filter behavior (ignored outside
  `__main__`), `PendingDeprecationWarning` distinction — retrieved
  2026-08-24
- https://peps.python.org/pep-0387/ — PEP 387, Python's Backwards
  Compatibility Policy; minimum two-minor-version deprecation window,
  preferred 5-year removal target — retrieved 2026-08-24
- https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings
  — docstring Args/Returns/Raises convention; the "paradoxically make
  behavior under violation of the API part of the API" line as the sourced
  form of docstring-as-contract — retrieved 2026-08-24
- https://docs.astral.sh/ruff/rules/boolean-type-hint-positional-argument/
  (FBT001, verified directly; FBT002/FBT003 confirmed via the FBT category
  listing) — rule rationale, exemptions (dunder/setter/`@override`),
  recommended fixes, attribution of "boolean trap" to Adam Johnson's 2021
  article — retrieved 2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html
  — least-privilege principle for DB accounts; confirms no specific
  role-count/segregation pattern is prescribed — retrieved 2026-08-24
- `research/python-code-review/performance.md` (this repo) — SQLAlchemy
  connection-pool parameter table and default values, cross-referenced
  rather than duplicated; source of the pool_recycle/pool_pre_ping
  defaults-vs-overrides distinction applied above — read 2026-08-24
- https://raw.githubusercontent.com/Kludex/uvicorn/main/docs/deployment/index.md
  — Uvicorn's current deployment docs (repo moved from `encode/uvicorn` to
  `Kludex/uvicorn`); `uvicorn.workers` deprecation notice pointing to
  `uvicorn-worker`, native `--workers` multiprocess support via `spawn`
  — retrieved 2026-08-24 (paraphrased through WebFetch, not verbatim
  copy-pasted — treat exact wording as approximate)
- https://pypi.org/project/uvicorn-worker/ — replacement package for the
  deprecated `uvicorn.workers` import path, current version 0.4.0,
  released 2025-09-20 — retrieved 2026-08-24
- https://raw.githubusercontent.com/benoitc/gunicorn/master/docs/content/design.md
  — Gunicorn's own worker-count formula `(2 × CPU cores) + 1`, "4–12
  workers" typical-heavy-traffic caveat, "start with this formula and
  adjust under load" framing — retrieved 2026-08-24 (paraphrased through
  WebFetch; treat exact wording as approximate)
- https://raw.githubusercontent.com/benoitc/gunicorn/master/docs/content/deploy.md
  — reverse-proxy recommendation (Nginx), `--forwarded-allow-ips`
  guidance; confirms no worker-count formula is repeated here (single
  source of truth is design.md) — retrieved 2026-08-24
- https://pypi.org/project/granian/ — Granian identity, current version
  2.8.2 (released 2026-08-23), Production/Stable status, cited production
  adopters (paperless-ngx, reflex, searxng, Microsoft, Mozilla, Sentry)
  — retrieved 2026-08-24
- https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#types-of-probe
  — three probe types (liveness/readiness/startup), restart-vs-traffic-
  routing failure-consequence distinction — retrieved 2026-08-24
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
  — "Protect slow starting containers with startup probes" section
  heading, confirming the startup-probe-prevents-restart-loop framing
  — retrieved 2026-08-24 (page content partially truncated in fetch; the
  section heading itself is directly confirmed, deeper mechanism inferred
  from the probe-type page above)
- `research/python-code-review/security.md` (this repo) — confirmed CORS,
  JWT/broken-auth, and rate-limiting (API4:2023) are already Security's
  checklist items, driving the Middleware domain-boundary correction above
  — read 2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — the
  required API/interface-design expansion text (semver, `DeprecationWarning`,
  docstring-as-contract, FBT), and the "Database/Migrations as a separate
  domain" rejection precedent — read 2026-08-24
- `research/python-code-review/original-tool/review-domains/architecture.md`
  (this repo) — the baseline being verified/expanded — read 2026-08-24

## Open questions for the user

- **Granian's adoption trajectory relative to Uvicorn/Gunicorn could not be
  surveyed** — this session's WebSearch budget was exhausted before a
  comparative query could run. Granian's own PyPI page confirms it's real,
  current (2.8.2, 2026-08-23), and production-stable with named adopters,
  but whether it's meaningfully displacing the Uvicorn(+Gunicorn) pattern
  in new Python web projects is unverified. Recommend a follow-up
  WebSearch pass before authoring decides whether to mention Granian as a
  peer option or a footnote.
- **3-user DB segregation**: confirm the framing above (keep the pattern
  as a suggested, explicitly-labeled-reasoned implementation of OWASP's
  sourced least-privilege principle, not as a named standard) is the right
  call, matching how Code Quality's baseline handled "40 lines."
- **`min_score`/`max_output_records` defaults**: confirm removal of the
  specific numbers (70 / 10) in favor of the generic "bound result size,
  expose a relevance threshold where applicable" principle is the right
  call, rather than keeping the specific defaults as illustrative examples.
- **Middleware domain-boundary correction**: confirm that pushing
  CORS/JWT/rate-limit *correctness* to Security (Architecture keeps only
  structural presence/wiring) is the intended resolution, rather than
  keeping a deliberately duplicated lighter-weight version in Architecture
  for reviewers who only run the Architecture domain in isolation.
- **WebFetch-sourced quotes are paraphrase, not verified verbatim** — the
  Gunicorn worker-formula quote, the Uvicorn deprecation notice, and the
  Kubernetes startup-probe heading were all retrieved through WebFetch's
  summarization rather than a raw-text diff against the source. The
  substance is verified (the formula, the deprecation, the section
  heading's existence and topic all check out), but exact wording in this
  baseline should be treated as close paraphrase; recommend a verbatim
  spot-check of these three specific lines before they're quoted directly
  in authored skill content.

## Target file(s) + estimated length

- `skills/python-code-review/references/architecture.md` — est. 260–290
  lines (eleven sourced sub-topics at paragraph/section/checklist depth,
  one tier-applicability table, plus scoring-guide and required-evidence
  sections mirroring the original tool's per-domain structure once
  authored — those two sections are not part of this baseline itself).
