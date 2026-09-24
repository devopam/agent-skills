# Scalability & Resilience (TypeScript)

## Checks
1. Timeouts on outbound calls; retries with backoff/jitter for transient failures.
2. Circuit breaking or bulkheads for critical dependencies (enterprise).
3. Graceful shutdown (SIGTERM) for servers.
4. Idempotency for mutating APIs where relevant.
5. Rate limiting / backpressure awareness.

## Not implemented (report as absence when tier expects them)
- enterprise: no timeouts on external HTTP; no graceful shutdown.
