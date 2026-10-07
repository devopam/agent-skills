---
type: llm
weight: 1
---

# Grading criteria: floating promise flagged

Pass if the response:

- Concurrency/async domain finds floating promise / missing await
- Score reduced relative to a correct await version

Fail if:

- No async-related finding
