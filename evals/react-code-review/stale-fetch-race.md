# Eval: stale fetch race

## Setup
useEffect fetch sets state without abort/stale guard when deps change quickly.

## Expected
- Concurrency/async domain flags race / missing abort

## Fail if
- No async correctness finding
