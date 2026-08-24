# Observability Review Domain

## Scope
Reviews logging, monitoring, tracing, and operational readiness. Ensures the
application can be debugged, monitored, and maintained in production.

## Tier Applicability
| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Structured logging | Yes | Yes | Yes |
| No print() in prod | Yes | Yes | Yes |
| Error context | Yes | Yes | Yes |
| Request logging | No | Yes | Yes |
| Distributed tracing | No | No | Yes |
| SLI/SLO definitions | No | No | Yes |
| Error budgets | No | No | Yes |
| Metrics / telemetry | No | Optional | Yes |

## Review Criteria

### Critical
- No logging at all in a non-trivial application
- Sensitive data logged in plaintext, including:
  - Credentials: passwords, API keys, tokens, session IDs, Authorization headers, cookies, DB connection strings
  - PII: full names, email, phone, SSN/national IDs, DOB, addresses, payment card numbers, health/financial data
  - Prompts/responses containing user PII when LLMs are used
  - Full request/response bodies logged without redaction
  - Query strings logged without filtering sensitive parameter names (`password`, `token`, `api_key`, `secret`, `authorization`, `code`, `access_token`, `refresh_token`)

### PII Redaction Requirements (when user data flows through logs)
- Centralized redaction filter / formatter applied to every logger handler
- Allowlist of loggable fields (prefer) over blocklist of sensitive ones
- Exception tracebacks scrubbed before emission (locals may hold credentials)
- Log injection defense: newline/CR stripped from user-derived fields (prevents log forging)
- Retention policy defined: PII-bearing logs have shorter TTL than operational logs
- Log storage access-controlled (not world-readable on disk, not public S3)

### Important

**Logging Quality**
- Structured logging library used (loguru, structlog — not stdlib `logging` or `print()`)
- No `print()` statements in production code paths
- Log levels used appropriately:
  - `DEBUG`: detailed diagnostic info for development
  - `INFO`: routine operational events (startup, request served, task completed)
  - `WARNING`: unexpected but handled situations
  - `ERROR`: failures requiring attention
  - `CRITICAL`: system-level failures requiring immediate action
- Log messages include context: relevant IDs, input values, timing
- Exceptions logged with full traceback (`logger.exception()` or equivalent)

**Error Context**
- Errors include enough context to diagnose without reproducing
- Correlation IDs / request IDs propagated through call chains
- Failed operations log: what was attempted, with what input, what went wrong

**Request Logging (web/enterprise)**
- Incoming requests logged: method, path, status code, duration
- Request/response bodies NOT logged (privacy, size) — only metadata
- Slow requests flagged (configurable threshold)

**Metrics & Telemetry (enterprise)**
- OpenTelemetry or equivalent instrumentation present
- Metrics measure client-perceived quality (not just internal CPU/memory)
- Tail latencies tracked: p95 and p99, not averages
- Custom business metrics where relevant (orders/sec, items processed)

**SLI/SLO Framework (enterprise)**
- Service Level Indicators defined: success rate, latency percentiles
- Service Level Objectives documented: target values and measurement windows
- Error budget concept understood: feature velocity tied to reliability
- Alerting based on SLO burn rate, not raw thresholds

**Distributed Tracing (enterprise)**
- Trace context propagated across service boundaries
- Spans created for meaningful operations (DB queries, external calls)
- Trace sampling configured (not 100% in production)

### Minor
- Log rotation configured for file-based logging
- Structured log format (JSON) for production, human-readable for dev
- Dashboard or runbook referenced in README or docs
- `py-spy` or `Scalene` profiling documented for performance investigation

## Scoring Guide
- 10: Structured logging, proper levels, tracing, SLI/SLO, no print/PII leaks
- 8-9: Good logging with minor gaps, metrics present, no PII issues
- 6-7: Logging present but inconsistent levels, missing request logging or tracing
- 4-5: Mix of print() and logging, no correlation IDs, no metrics
- 1-3: No logging or all print(), PII in logs, no operational visibility
