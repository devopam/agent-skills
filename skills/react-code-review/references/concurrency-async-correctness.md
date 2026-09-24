# Concurrency & Async Correctness (React)

## Checks
1. Race conditions on rapid navigation/fetch (abort controllers, stale flags).
2. Effects that set state after unmount without cleanup.
3. Correct dependency arrays; no intentional infinite loops.
4. Transition/`useDeferredValue` usage where UI jank is an issue (React 18+).

## Critical
- Infinite re-render loops from effect/state mistakes.

## Important
- Ignoring aborted fetches and applying stale results.
