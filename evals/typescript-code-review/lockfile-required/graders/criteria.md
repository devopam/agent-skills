---
type: llm
weight: 1
---

# Grading criteria: lockfile required for web tier

Pass if the response:

- Dependency/supply-chain domain flags missing lockfile
- Suggests committing lockfile and frozen CI install

Fail if:

- Treats missing lockfile as fine for web/enterprise
