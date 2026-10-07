---
name: python-code-review-gap-overall-scorecard-verdict
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Review this tiny web-tier module (full project scope). Produce the full
skill output including domain scores and overall verdict.

```python
# app/health.py
def ok():
    return {"status": "ok"}
```

Tier: web.
