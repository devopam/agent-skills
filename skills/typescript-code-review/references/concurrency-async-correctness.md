# Concurrency & Async Correctness (TypeScript)

## Checks
1. Missing `await` on promises that must complete; floating promises.
2. Race conditions on shared in-memory state.
3. `Promise.all` vs `allSettled` appropriateness; unbounded parallel fan-out.
4. AbortSignal / timeout propagation on I/O.
5. Correct use of async iterators and streams.

## Critical
- Unhandled promise rejections that crash or silently lose work.

## Important
- Sequential awaits that should be parallelized on independent I/O (performance crossover).
- Missing cancellation on abandoned requests.
