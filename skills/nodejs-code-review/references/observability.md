# Observability (Node.js)

## Checks
1. Structured logger with levels; request ID middleware.
2. OpenTelemetry or equivalent at enterprise.
3. Metrics for latency/error rate on critical routes.
4. Redact secrets and PII from logs.

## Important
- Production reliance on `console.log` only (web+).
