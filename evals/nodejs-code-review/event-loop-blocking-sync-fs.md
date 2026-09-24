# Eval: sync fs on request path

## Setup
Request handler uses `fs.readFileSync` on large files per request, tier=web.

## Expected
- Performance domain flags event-loop blocking / sync I/O

## Fail if
- No performance finding
