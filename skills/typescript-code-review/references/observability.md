# Observability (TypeScript)

## Checks
1. Structured logging (pino/winston/consola etc.) vs ad-hoc `console.log` in production paths.
2. Request/correlation IDs on server paths.
3. Metrics and tracing hooks where enterprise tier applies (OpenTelemetry).
4. No PII in logs by default.

## Important
- Production code paths with only `console.log` and no levels (web+).
- Errors logged without context needed to debug.
