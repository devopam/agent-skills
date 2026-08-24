# Baseline: Observability
Status: user-approved      Date: 2026-08-24

## Resolutions (Checkpoint D review, 2026-08-24)

- **loguru downgrade**: confirmed — explicitly demote to "acceptable if
  already adopted, verify version floor," structlog as primary.
- **Presidio weight trade-off**: note it rather than recommending
  unconditionally — dependency-aware framing, consistent with the
  capability-detection pattern used elsewhere in this skill.
- **Log-injection reasoned qualifier**: accepted, consistent with this
  repo's honest-labeling convention.
- **Zero-code OTel instrumentation stability**: deferred to a
  direct-fetch check at authoring time, per the standing
  verify-before-publish policy.
- **Tracing/metrics depth**: keep checklist depth — SLI/SLO principle
  depth already lives in `project-incubation`, and a full API walkthrough
  reads as how-to content rather than review criteria.

## In scope

- **Structured logging library recommendation — structlog over loguru** —
  impact: high — depth: paragraph. The original domain file recommends
  "loguru, structlog" as roughly interchangeable. That's now stale.
  Sibling Standards Compliance research found loguru's latest release,
  0.7.3, dates to 2024-12-06 (Python 3.5–3.13, sole maintainer) against
  structlog's 26.1.0 (2026-06-06, active multi-release cadence, Python
  3.15 support) — see
  `research/python-code-review/standards-compliance.md` (search
  "loguru"). That file flagged the coincidence of loguru and httpx
  sharing an identical last-release date as a possible fetch artifact
  and recommended a direct re-check. This research re-checked against
  PyPI's JSON API (https://pypi.org/pypi/loguru/json) — a different URL
  and cache key than standards-compliance.md's fetch of the HTML project
  page, ruling out a same-URL cache-hit explanation — and it returned
  the identical upload timestamp, `2024-12-06T11:20:54`. The staleness
  is genuine, not a fetch/caching artifact — loguru is ~20 months stale
  with no 3.14/3.15 support claim as of this research date. **The
  authored skill should recommend structlog as the primary structured-
  logging pick and demote loguru to "acceptable if already adopted,
  verify it still meets your Python version floor" rather than listing
  the two as equals.** stdlib `logging` remains correct to flag as
  insufficiently structured for production log aggregation (no native
  JSON/key-value rendering) but is not "wrong" — it's the console-
  readable fallback structlog itself wraps.

- **PII/secret redaction pattern for structured logs** — impact: high —
  depth: section. structlog ships **no built-in redaction processor** —
  confirmed by direct fetch of
  https://www.structlog.org/en/stable/processors.html (retrieved
  2026-08-24): the documented built-in processors cover timestamping,
  rendering (JSONRenderer, ConsoleRenderer), and context-merging, not
  field censoring. The library's documented pattern is to write a
  custom processor — a plain callable
  `(logger, method_name, event_dict) -> event_dict` inserted into the
  processor chain — that strips or masks keys before the final renderer
  runs. This is consistent with the original domain file's "centralized
  redaction filter/formatter applied to every handler" requirement and
  should be kept, with the concrete mechanism named: a custom structlog
  processor (or, for stdlib `logging`, a `logging.Filter` subclass
  attached to every handler) as the enforcement point, not per-call-site
  discipline.
  For dedicated PII-detection libraries: **Microsoft Presidio**
  (`presidio-analyzer` for detection, `presidio-anonymizer` for the
  redaction/anonymization step) is the currently-maintained option —
  confirmed via direct fetch of
  https://pypi.org/project/presidio-analyzer/ (retrieved 2026-08-24):
  latest release **2.2.364, 2026-07-22**, three active maintainers,
  regex + Named Entity Recognition based detection of PII in
  unstructured text. This is the recommendation the authored skill
  should lead with for free-text PII detection, superseding `scrubadub`
  (regex-only detector, also confirmed via direct fetch of
  https://pypi.org/project/scrubadub/, retrieved 2026-08-24: latest
  release 2.0.1, 2023-09-01, ~3 years stale) — scrubadub can still be
  named as a lighter-weight alternative but should carry a staleness
  caveat, not be presented as the primary pick. Both are detectors for
  free-text fields; for structured log fields (dict/kwarg-based, the
  structlog/stdlib-`extra=` case) an explicit allowlist-of-loggable-keys
  processor remains the more reliable and dependency-free control and
  should be the primary recommendation regardless, with
  Presidio/scrubadub positioned as the tool for scrubbing free-text
  message bodies and exception strings that can't be field-allowlisted.

- **Metrics/telemetry — OpenTelemetry Python SDK status** — impact:
  med — depth: paragraph. Directly fetched
  https://opentelemetry.io/docs/languages/python/ (retrieved
  2026-08-24): **Traces and Metrics components are Stable; Logs remain
  in Development.** SDK supports Python 3.10+. This means an OTel-based
  metrics/tracing recommendation is on solid ground, but an
  OTel-for-logs recommendation should be flagged as immature — structlog/
  stdlib logging plus a JSON exporter to whatever log backend is in use
  remains the safer near-term default for the logs pillar, while traces
  and metrics can lean on OTel proper. Cross-reference: the
  three/four-pillars framing and CNCF Graduated-maturity status (May 11,
  2026) for OpenTelemetry overall are already verified in
  `skills/project-incubation/references/architecture-principles.md` —
  cite that rather than re-deriving the project-level maturity claim
  here; this domain's addition is the per-signal (traces/metrics/logs)
  stability split, which that file does not break out.

- **Auto-instrumentation (`opentelemetry-instrumentation-*`)** — impact:
  low-med — depth: paragraph. Directly fetched
  https://opentelemetry.io/docs/zero-code/python/ (retrieved
  2026-08-24): Python's "zero-code" instrumentation works via two CLI
  tools — `opentelemetry-bootstrap` (scans installed packages, e.g.
  detects Flask, and installs the matching
  `opentelemetry-instrumentation-flask` package) and
  `opentelemetry-instrument` (a wrapper that launches the app with
  instrumentation attached, configured via env vars like
  `OTEL_SERVICE_NAME`, `OTEL_TRACES_EXPORTER`, no source changes
  required). Mechanism is monkey-patching of supported library entry
  points at runtime. Useful as a checklist item ("is
  opentelemetry-instrumentation-{framework} present for the web
  framework/DB driver in use, or is tracing hand-rolled") but the fetch
  did not surface a documented stability/maturity statement for
  zero-code instrumentation specifically, separate from the SDK-level
  stability above — do not claim a version/stability number for it
  beyond what's stated here.

- **Distributed tracing setup pattern** — impact: low — depth: checklist
  (carried over, not independently re-verified this session — budget
  prioritized items 1-2 per task instructions). Original criteria (trace
  context propagated across service boundaries, spans created for
  meaningful operations, sampling configured below 100% in production)
  are stable, non-date-sensitive OTel concepts and are kept as-is.

- **Log levels, error context, correlation IDs, request logging** —
  impact: med — depth: checklist. Carried forward from the original
  domain file largely unchanged — these are stable practice statements
  (DEBUG/INFO/WARNING/ERROR/CRITICAL semantics, `logger.exception()` for
  tracebacks, request method/path/status/duration logging without
  bodies) not tied to a library version or a fast-moving standard, so
  re-verification against a dated primary source has low marginal value.

- **Log injection defense — cross-reference only** — impact: med —
  depth: pointer. Security's domain file
  (`research/python-code-review/security.md`) covers log/CRLF injection
  as part of its "Injection" checklist item (SQL/NoSQL/Cypher/LDAP/
  XPath/SSTI/command/log injection), now mapped to OWASP A05:2025
  Injection (was A03:2021 in the prior OWASP edition). This domain's
  distinct angle, per the task brief, is structural, and is **reasoned
  here rather than drawn from a single sourced claim** (this repo's
  honest-labeling convention, as used in standards-compliance.md for its
  CI/CD checklist): a structured logging library with a dict/kwarg-based
  event API (structlog, or stdlib `logging` with `extra=`), *when its
  terminal processor/formatter is one that escapes special characters on
  serialization* — e.g. structlog's `JSONRenderer`, confirmed present on
  the processors page fetched above — closes most newline/CRLF
  log-forging, because user-supplied values become JSON-escaped field
  values rather than raw bytes concatenated into the log line. This
  protection is renderer-dependent, not automatic from "using structlog"
  alone: structlog's own dev-mode default, `ConsoleRenderer` (same
  page), is a human-readable formatter and does not document
  newline-escaping behavior, so a structlog app configured only with
  `ConsoleRenderer` in production would retain the exposure. The
  authored skill should state the rationale with that qualifier —
  "structured logging closes log-forging when paired with an escaping
  renderer (JSON in production), not merely by virtue of using a
  structured-logging library" — rather than an unqualified "structured
  logging prevents log injection" claim. The attack mechanics themselves
  belong to Security, not here.

## Explicitly out of scope

- **SLI/SLO framework and error-budget mechanics (deep dive)** — already
  verified in depth in
  `skills/project-incubation/references/architecture-principles.md`
  (SRE framing, SLI→SLO→error-budget chain, retrieved 2026-08-19). That
  file operates at the architecture-principle altitude while this domain
  reviews code-level implementation; re-deriving the same primary-source
  claims here would duplicate rather than add. This domain keeps only a
  short carried-over checklist pointer (SLIs defined, SLOs documented,
  burn-rate alerting) and defers the "why this matters" framing to that
  file.
- **Full OpenTelemetry SDK API walkthrough (span creation code,
  exporter configuration syntax, context propagation code samples)** —
  out of budget for this pass; the task brief marked tracing/metrics
  detail as "only if budget allows" and lower priority than the
  logging-library and PII-redaction items. A future pass fetching
  https://opentelemetry.io/docs/languages/python/instrumentation/ could
  fill this in.
- **`py-spy`/`Scalene` profiling tooling verification** — carried over
  unverified from the original file's Minor tier; not re-fetched this
  session (low impact, low priority per task brief).
- **Log aggregation backend selection (ELK, Loki, Datadog, etc.)** — out
  of scope for a code-review skill; backend choice is an infra/ops
  decision, not something reviewable from source code.

## Sources

- https://www.structlog.org/en/stable/processors.html — confirms
  structlog ships no built-in PII/secret redaction processor; documents
  the custom-processor pattern (`(logger, method_name, event_dict) ->
  event_dict`) as the intended extension point — retrieved 2026-08-24
- https://pypi.org/project/loguru/ — confirms latest release 0.7.3,
  2024-12-06, Python 3.5–3.13 — retrieved 2026-08-24
- https://pypi.org/pypi/loguru/json — PyPI JSON API, a different URL/
  cache key from the HTML project page above; confirms identical upload
  timestamp `2024-12-06T11:20:54` — used to independently rule out the
  fetch-caching-artifact hypothesis standards-compliance.md raised —
  retrieved 2026-08-24
- https://pypi.org/project/presidio-analyzer/ — Microsoft Presidio, PII
  detection via regex + NER; latest release 2.2.364, 2026-07-22, 3
  active maintainers — the currently-maintained option, recommended
  ahead of scrubadub — retrieved 2026-08-24
- https://pypi.org/project/scrubadub/ — PII-scrubbing library for free
  text (names, emails, phone numbers, credit cards, SSNs, addresses);
  latest release 2.0.1, 2023-09-01, ~3 years stale — secondary/
  lighter-weight option, not the primary pick — retrieved 2026-08-24
- https://opentelemetry.io/docs/languages/python/ — Python SDK: Traces
  and Metrics are Stable, Logs is in Development; SDK supports Python
  3.10+ — retrieved 2026-08-24
- https://opentelemetry.io/docs/zero-code/python/ — documents
  `opentelemetry-bootstrap` and `opentelemetry-instrument` as the
  zero-code auto-instrumentation mechanism (monkey-patching supported
  library entry points, env-var configuration) — retrieved 2026-08-24
- `research/python-code-review/standards-compliance.md` (search
  "loguru") — source of the loguru-staleness finding this domain
  incorporates for the logging-library recommendation; also source of
  structlog's 26.1.0 / 2026-06-06 currency figure — retrieved 2026-08-24
  (as cited there)
- `research/python-code-review/security.md` (search "Injection") —
  source of the log-injection / OWASP A05:2025 mapping this domain
  cross-references rather than duplicates
- `skills/project-incubation/references/architecture-principles.md` —
  source of the verified three/four-pillars and SLI/SLO/error-budget
  framing this domain cross-references rather than re-deriving

## Open questions for the user

- Should the authored skill explicitly downgrade loguru from "equal
  alternative to structlog" to "legacy/verify-still-wanted," or keep
  listing both without a preference note? This research recommends the
  downgrade given the confirmed ~20-month release gap and lack of stated
  3.14/3.15 support, but that's an editorial call for authoring, not a
  fact this research can settle further.
- Presidio (`presidio-analyzer` + `presidio-anonymizer`) is confirmed
  current and actively maintained and is now this file's lead PII-
  detection recommendation, with scrubadub demoted to a lighter-weight/
  staleness-caveated secondary option. Presidio is a heavier dependency
  (NER models) than scrubadub's regex-only approach — worth an authoring
  decision on whether to recommend it unconditionally or note the
  weight trade-off for lightweight projects.
- The log-injection "structured logging closes most CRLF forging"
  rationale in this file is explicitly labeled reasoned-not-sourced and
  qualified as renderer-dependent (JSON renderers escape, console
  renderers don't document escaping). Confirm this qualifier is
  acceptable for authoring, or whether it should be dropped entirely if
  the authored skill prefers only single-sourced claims in this
  section.
- The zero-code OpenTelemetry instrumentation fetch did not surface an
  explicit stability/maturity label distinct from the SDK-level
  Stable/Development split. Worth a follow-up fetch of
  https://opentelemetry.io/docs/languages/python/instrumentation/ before
  authoring makes any stability claim about auto-instrumentation
  specifically.
- Distributed tracing and full metrics/SLI implementation depth were
  explicitly deprioritized by the task's budget guidance and are only
  checklist-level here. Confirm whether the authored reference file
  needs a deeper tracing section (code-level span/context examples) or
  whether checklist depth is sufficient given SLI/SLO principle depth
  already lives in project-incubation.

## Target file(s) + estimated length

- skills/python-code-review/references/observability.md — est. 140-170
  lines (structured-logging recommendation + PII redaction section are
  the two substantial additions over the original 90-line file; tracing/
  metrics/SLI sections stay checklist-depth per the cross-references
  above)
