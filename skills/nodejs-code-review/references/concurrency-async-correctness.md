# Concurrency & Async Correctness (Node.js)

## Checks
1. Floating promises; missing await in request handlers.
2. Shared mutable state across concurrent requests without coordination.
3. Proper use of worker_threads / child processes for CPU work.
4. Queue consumers: ack/nack and idempotency.

## Critical
- Race on wallet/balance-like updates without atomicity.
