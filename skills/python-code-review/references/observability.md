# Observability

This is the observability domain of the `python-code-review` skill's
domain set. It reviews whether a codebase is debuggable from its own
output — structured logging, PII/secret redaction at the logging layer,
and the presence and shape of tracing/metrics instrumentation. Two
sibling files own adjacent, deeper territory this file deliberately
doesn't re-derive: [`project-incubation`'s architecture-principles](../../project-incubation/references/architecture-principles.md#6-observability)
owns the three-pillars framing, OpenTelemetry's CNCF-Graduated project
maturity, and the SLI/SLO/error-budget mechanics at
[§5 Scalability & Reliability](../../project-incubation/references/architecture-principles.md#5-scalability--reliability)
— this domain reviews code-level implementation against those principles,
not the principles themselves. [Security](../references/security.md#injection)
owns the attack mechanics and OWASP citation for log injection; this
domain's log-injection content is the structural angle only — which
logging construction pattern closes the hole, not how the exploit works.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [Structured Logging](#structured-logging)
- [PII and Secret Redaction](#pii-and-secret-redaction)
- [Log Levels, Error Context, Correlation IDs, Request Logging](#log-levels-error-context-correlation-ids-request-logging)
- [Log Injection: the Structural Angle](#log-injection-the-structural-angle)
- [Tracing and Metrics (OpenTelemetry)](#tracing-and-metrics-opentelemetry)
- [Zero-Code Auto-Instrumentation](#zero-code-auto-instrumentation)
- [SLIs and SLOs (Checklist Depth)](#slis-and-slos-checklist-depth)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Sources](#sources)

---

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Log level semantics used correctly (DEBUG–CRITICAL) | Yes | Yes | Yes |
| `logger.exception()` used for tracebacks, not `logger.error(str(e))` | Yes | Yes | Yes |
| No PII/secrets logged in plaintext (redaction-mechanism angle) | Yes | Yes | Yes |
| Structured logging library in use (structlog primary; stdlib `logging` acceptable console fallback) | No | Yes | Yes |
| Centralized redaction processor/filter applied to every handler | No | Yes | Yes |
| Correlation/request IDs propagated through the log context | No | Yes | Yes |
| Request logging (method/path/status/duration, no bodies) | No | Yes | Yes |
| JSON renderer used in production (log-injection defense angle) | No | Yes | Yes |
| Tracing/metrics instrumented via OpenTelemetry conventions | No | Yes | Yes |
| Auto-instrumentation present for the web framework/DB driver in use, or tracing deliberately hand-rolled | No | Yes | Yes |
| Presidio (or equivalent NER-based) free-text PII detection | No | No | Yes |
| Sampling configured below 100% in production | No | No | Yes |
| SLIs defined, SLOs documented, burn-rate alerting wired | No | No | Yes |

A script-tier project still owes itself the free stuff: correct log
levels, real tracebacks via `logger.exception()`, and never printing a
secret. Everything that requires picking and wiring a library —
structlog, a redaction processor, an OTel exporter — is gated to
web/enterprise, following [§5](../../project-incubation/references/architecture-principles.md#5-scalability--reliability)'s
own logic: a weekend prototype does not need an error-budget policy or a
paging rotation, but a service handling other people's requests does.
Presidio, production sampling policy, and formal SLI/SLO tracking are
enterprise-only — they're infrastructure investments a web-tier project
can reasonably defer, not corrections a script-tier project is missing.

---

## Structured Logging

**structlog is the primary recommendation; loguru is acceptable only if
already adopted, with its version floor verified.** The two used to be
listed as roughly interchangeable — that's now stale. structlog is at
**26.1.0** (released 2026-06-06), on an active multi-release cadence,
with Python 3.15 support. loguru's latest release is **0.7.3**, dated
**2024-12-06** — about 20 months stale as of this writing, covering
Python 3.5–3.13 with no stated 3.14 or 3.15 support, and maintained by a
single maintainer. That gap was independently confirmed against two
different PyPI endpoints (the HTML project page and the JSON API,
different URLs and cache keys), which rules out a fetch-caching artifact
explaining the timestamp — the staleness is real. A codebase already on
loguru isn't an automatic finding, but flag it: confirm the pinned
version still covers the project's Python floor, since 0.7.3 is the last
release and there's no visible signal a newer one is coming.

stdlib `logging` remains correct to flag as insufficiently structured
for production log aggregation — it has no native JSON/key-value
rendering, so every consumer downstream (a log shipper, a SIEM, a
teammate grepping) has to parse free text. It is not *wrong*, though —
it's the console-readable fallback that structlog itself wraps
(structlog's `ConsoleRenderer` is a human-friendly formatter sitting on
top of the same processor pipeline as its JSON path). The finding is
"no structured event API," not "uses the stdlib."

---

## PII and Secret Redaction

structlog ships **no built-in redaction processor.** Its documented
processor set covers timestamping, rendering (`JSONRenderer`,
`ConsoleRenderer`), and context-merging — not field censoring. The
library's own documented extension point is a custom processor: a plain
callable `(logger, method_name, event_dict) -> event_dict` inserted into
the processor chain ahead of the final renderer, which strips or masks
keys before they're serialized. For stdlib `logging`, the equivalent
construct is a `logging.Filter` subclass attached to every handler. Either
way, the enforcement point is centralized and applied uniformly — not
per-call-site discipline, which degrades the moment someone forgets.

**The primary, dependency-free control is a field allowlist**, not a
detection library: for structured log fields (the dict/kwarg-based
case — structlog's `event_dict`, or stdlib `logging`'s `extra=`), an
explicit list of keys allowed to reach the sink is more reliable than
scanning values after the fact, and it costs nothing to add. This should
be the default recommendation regardless of what else is in play.

Where an allowlist doesn't help — free-text message bodies and exception
strings, where PII can show up anywhere in an unstructured blob —
**Microsoft Presidio** (`presidio-analyzer` for detection,
`presidio-anonymizer` for the anonymization step) is the currently
maintained option: latest release **2.2.364** (2026-07-22), three active
maintainers, regex plus Named Entity Recognition detection. It supersedes
`scrubadub`, whose latest release is **2.0.1** (2023-09-01) — about
three years stale — and which detects via regex only. scrubadub can
still be named as a lighter-weight alternative, but carries a staleness
caveat rather than standing as the primary pick.

Presidio's NER models are a real weight trade-off, though — don't
recommend it unconditionally. It's a heavier dependency than scrubadub's
regex-only approach, and for a lightweight web-tier project that trade-off
may not be worth it against a well-maintained field allowlist plus
scrubadub for the residual free-text surface. Treat Presidio as the
enterprise-tier pick where the free-text PII surface is large enough (raw
user content, support tickets, LLM prompts/completions) to justify the
dependency weight — this mirrors the capability-detection framing used
elsewhere in this skill: recommend the heavier tool when the codebase's
own shape indicates it's warranted, not by default.

---

## Log Levels, Error Context, Correlation IDs, Request Logging

Carried forward largely unchanged — these are stable practice statements,
not tied to a library version or a fast-moving standard:

- DEBUG/INFO/WARNING/ERROR/CRITICAL used for their actual semantic
  meaning, not as a volume dial (e.g. routine request handling logged at
  ERROR because someone wanted it to always show up).
- `logger.exception()` used inside an `except` block so the traceback is
  captured, rather than `logger.error(str(e))`, which discards the stack.
- Correlation/request IDs generated or propagated (from an incoming
  header, or minted at the edge) and threaded through every log line for
  a single request — structlog's context-binding (`bind()` /
  `contextvars`-backed context) is the idiomatic mechanism; stdlib
  `logging` needs an explicit `LoggerAdapter` or filter to get the same
  effect.
- Request logging captures method, path, status code, and duration —
  never the request or response body, which is where secrets and PII
  leak in via this exact path.

---

## Log Injection: the Structural Angle

Security's domain file covers log/CRLF injection under its
[Injection](../references/security.md#injection) checklist item, mapped
to **A05:2025 Injection (was A03:2021)** — that's where the attack
mechanics and OWASP citation live. This domain's distinct angle is
structural: which logging construction pattern actually closes the hole.

A structured logging library with a dict/kwarg-based event API
(structlog, or stdlib `logging` with `extra=`) closes most newline/CRLF
log-forging **when its terminal renderer escapes on serialization** —
structlog's `JSONRenderer` is confirmed to do this, since user-supplied
values become JSON-escaped field values rather than raw bytes
concatenated into the log line. This protection is renderer-dependent,
not automatic from "using structlog" alone: structlog's own dev-mode
default, `ConsoleRenderer`, is a human-readable formatter with no
documented newline-escaping behavior. A structlog app configured with
`ConsoleRenderer` in production keeps the exposure it was supposed to
have closed. State the finding with that qualifier — "structured logging
closes log-forging when paired with an escaping renderer (JSON in
production), not merely by virtue of using a structured-logging
library" — not as an unqualified "structured logging prevents log
injection."

---

## Tracing and Metrics (OpenTelemetry)

OpenTelemetry's Python SDK has a **per-signal stability split**: Traces
and Metrics components are **Stable**; Logs remains in **Development**.
The SDK supports Python 3.10+. Practically: an OTel-based
tracing/metrics recommendation is on solid ground and should be the
default for a web/enterprise-tier service. An OTel-*for-logs*
recommendation should be flagged as immature — structlog or stdlib
logging with a JSON renderer, exported to whatever log backend is in
use, remains the safer near-term default for the logs pillar, while
traces and metrics lean on OTel proper. (The three/four-pillars framing
and OpenTelemetry's CNCF Graduated-maturity status live in
[architecture-principles §6](../../project-incubation/references/architecture-principles.md#6-observability)
— this domain's addition on top of that is specifically the per-signal
stability split, which that file doesn't break out.)

At review time, checklist depth is enough — a full API walkthrough
(span-creation code, exporter configuration syntax, context-propagation
samples) is how-to content, not review criteria:

- Trace context is propagated across service boundaries (not silently
  dropped at a queue hop or an outbound HTTP call).
- Spans are created for meaningful operations, not either omitted
  entirely or created at a granularity so fine they're noise.
- Sampling is configured below 100% in production — unsampled tracing at
  scale is a cost and volume problem, not a correctness one, but it's
  still a finding.

---

## Zero-Code Auto-Instrumentation

Python's "zero-code" instrumentation path works via two CLI tools:
**`opentelemetry-bootstrap`**, which scans installed packages and
installs the matching `opentelemetry-instrumentation-*` package (e.g.
detecting Flask and pulling in
`opentelemetry-instrumentation-flask`), and **`opentelemetry-instrument`**,
a wrapper that launches the application with instrumentation attached,
configured entirely through environment variables (`OTEL_SERVICE_NAME`,
`OTEL_TRACES_EXPORTER`, and similar) with no source changes required. The
underlying mechanism is monkey-patching of supported library entry points
at runtime. As a review checklist item: is
`opentelemetry-instrumentation-{framework}` present for the web
framework/DB driver actually in use, or is tracing hand-rolled where an
auto-instrumentation package already exists for that dependency.

Neither the zero-code documentation page nor OpenTelemetry's Python
manual-instrumentation page states an explicit stability/maturity label
for zero-code instrumentation specifically, distinct from the SDK-level
Traces/Metrics-Stable, Logs-Development split above — the manual-
instrumentation page doesn't discuss zero-code at all, and the zero-code
page carries no stability statement of its own. Don't claim a
stability/version number for auto-instrumentation beyond what's stated
here; if a future check turns one up, this note should be updated rather
than assumed away.

---

## SLIs and SLOs (Checklist Depth)

Kept at checklist depth deliberately — the "why this matters" framing
(SRE's SLI → SLO → error-budget chain, complexity as a reliability
property) is already covered at
[architecture-principles §5](../../project-incubation/references/architecture-principles.md#5-scalability--reliability),
and re-deriving that here would duplicate rather than add. At code-review
altitude, the checkable surface is:

- SLIs are defined (the signals actually measured — latency, error rate,
  availability).
- SLOs are documented (the target values those signals are held to).
- Burn-rate alerting exists, so budget consumption triggers a response
  before the SLO itself is breached.

---

## Out of Scope

- **Full SLI/SLO framework and error-budget mechanics** — see
  [architecture-principles §5](../../project-incubation/references/architecture-principles.md#5-scalability--reliability)
  for the depth version; this domain keeps only the checklist above.
- **Full OpenTelemetry SDK API walkthrough** (span-creation code,
  exporter configuration syntax, context-propagation code samples) —
  how-to content, not review criteria.
- **Log/CRLF injection attack mechanics and OWASP mapping** — owned by
  [Security](../references/security.md#injection); this file covers only
  the structural (renderer-dependent) angle.
- **`py-spy`/`Scalene` profiling tooling** — not verified against a
  current source as of this pass; treat any recommendation here as
  unconfirmed until independently checked.
- **Log aggregation backend selection** (ELK, Loki, Datadog, and similar)
  — an infra/ops decision, not something reviewable from source code.

---

## Scoring Guide

- **10** — Structured logging in place (structlog, or a version-checked
  loguru) with a centralized redaction processor and a field allowlist.
  Correlation IDs threaded through every request. Tracing and metrics
  instrumented via OpenTelemetry with sampling configured for production.
  SLIs/SLOs documented with burn-rate alerting.
- **8-9** — Structured logging and redaction in place; one gap such as
  missing correlation IDs or unsampled production tracing.
- **6-7** — Structured logging present but the redaction control is
  informal (no centralized processor/filter, relying on per-call-site
  discipline), or tracing/metrics are absent on a service that clearly
  needs them.
- **4-5** — stdlib `logging` only, with no structured event API and no
  redaction control; PII or secrets found in log output.
- **1-3** — Secrets or credentials logged in plaintext; no log-level
  discipline; `str(e)` used in place of `logger.exception()` throughout,
  losing tracebacks needed for incident response.

---

## Sources

- https://www.structlog.org/en/stable/processors.html — confirms
  structlog ships no built-in PII/secret redaction processor; documents
  the custom-processor pattern (`(logger, method_name, event_dict) ->
  event_dict`) as the intended extension point, and confirms
  `JSONRenderer`/`ConsoleRenderer` as the built-in renderers. Retrieved
  2026-08-24.
- https://pypi.org/project/loguru/ — latest release 0.7.3, 2024-12-06,
  Python 3.5–3.13. Retrieved 2026-08-24.
- https://pypi.org/pypi/loguru/json — PyPI JSON API; confirms the
  identical upload timestamp `2024-12-06T11:20:54` against a different
  URL/cache key than the HTML project page, ruling out a fetch-caching
  artifact. Retrieved 2026-08-24.
- https://pypi.org/project/presidio-analyzer/ — Microsoft Presidio,
  regex + NER PII detection; latest release 2.2.364, 2026-07-22, three
  active maintainers. Retrieved 2026-08-24.
- https://pypi.org/project/scrubadub/ — regex-only free-text PII
  scrubbing; latest release 2.0.1, 2023-09-01, ~3 years stale. Retrieved
  2026-08-24.
- https://opentelemetry.io/docs/languages/python/ — Python SDK: Traces
  and Metrics are Stable, Logs is in Development; SDK supports Python
  3.10+. Retrieved 2026-08-24.
- https://opentelemetry.io/docs/zero-code/python/ — documents
  `opentelemetry-bootstrap` and `opentelemetry-instrument` as the
  zero-code auto-instrumentation mechanism (monkey-patching supported
  library entry points, env-var configuration); no stability/maturity
  label stated for zero-code instrumentation specifically. Retrieved
  2026-08-24.
- https://opentelemetry.io/docs/languages/python/instrumentation/ —
  checked at authoring time for a zero-code-specific stability label
  distinct from the SDK-level split above; the page covers manual
  instrumentation only and does not mention zero-code, `opentelemetry-
  bootstrap`, or `opentelemetry-instrument` at all — negative result,
  confirming no such label is documented. Retrieved 2026-08-24.
- `research/python-code-review/standards-compliance.md` (search
  "loguru") — source of the loguru-staleness finding this domain
  incorporates, and of structlog's 26.1.0 / 2026-06-06 currency figure.
- `research/python-code-review/security.md` (search "Injection") —
  source of the log-injection / OWASP A05:2025 mapping this domain
  cross-references rather than duplicates.
- `skills/project-incubation/references/architecture-principles.md` —
  source of the three/four-pillars framing, OpenTelemetry's CNCF
  Graduated-maturity status, and the SLI/SLO/error-budget chain this
  domain cross-references rather than re-deriving.
- `research/python-code-review/observability.md` (this repo) — the
  approved research baseline this file was authored from; retained as
  the provenance record for the decisions above.
