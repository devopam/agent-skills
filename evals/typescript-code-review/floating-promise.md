# Eval: floating promise flagged

## Setup
TypeScript service handler starts `doWork()` without await or void, tier=web.

## Expected
- Concurrency/async domain finds floating promise / missing await
- Score reduced relative to a correct await version

## Fail if
- No async-related finding
