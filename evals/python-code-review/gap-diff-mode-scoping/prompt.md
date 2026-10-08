---
name: python-code-review-gap-diff-mode-scoping
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

Please review my changes against main. I only touched one file —
`app/utils/formatting.py` — everything else in the repo is unrelated,
pre-existing code I didn't touch and don't want reviewed right now. The
repo has other files with known, pre-existing issues (unrelated to this
change) that I'm intentionally leaving out of scope for this review.

```python
# app/utils/formatting.py (the only changed file)
def format_currency(amount, currency="USD"):
    return f"{amount:.2f} {currency}"
```

The repository is in the current working directory; my change is committed on the current branch and `main` is the base.
