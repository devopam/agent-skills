# Scalability & Resilience (Node.js)

## Checks
1. Timeouts on outbound HTTP/DB; retry policy with jitter.
2. Graceful shutdown on SIGTERM.
3. Horizontal scale: no sticky in-memory-only session store without shared store.
4. Circuit breakers for fragile dependencies (enterprise).
5. Bulkheads / queue limits for async work.

## Not implemented (flag at enterprise when absent)
- No timeouts; no graceful shutdown; in-memory sessions only in multi-instance deploy.
