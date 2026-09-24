# Performance (Node.js)

## Checks
1. Event-loop blocking (sync fs/crypto/cpu on request path).
2. N+1 queries; missing indexes noted at data-access layer.
3. Unbounded memory buffering of uploads/streams.
4. Connection pooling for DB/Redis.

## Important
- Sync `fs` in hot paths; prefer streaming for large payloads.
