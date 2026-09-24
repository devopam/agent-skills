# Eval: graceful shutdown at enterprise tier

## Setup
HTTP server with no SIGTERM/`server.close` handling, tier=enterprise.

## Expected
- Scalability/resilience notes absence of graceful shutdown
- Not implemented or Important finding

## Fail if
- Ignores shutdown entirely at enterprise tier
