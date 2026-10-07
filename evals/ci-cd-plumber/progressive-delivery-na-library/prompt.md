---
name: ci-cd-plumber-progressive-delivery-na-library
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Inception mode for a pure Python library published to PyPI only (no
deployed service). User asks whether they need canary or blue-green in the
pipeline.
