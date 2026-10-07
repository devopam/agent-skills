---
name: python-code-review-detect-blocking-call-in-async
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Please review this file for issues:

```python
# app/services/report_service.py
import time
import requests

async def generate_report(user_id: int) -> dict:
    profile = requests.get(f"https://internal-api/users/{user_id}").json()
    time.sleep(2)  # let the downstream cache warm up
    return {"user": profile, "generated": True}
```

Tier: web. This is the whole file, treat it as a full-project review.
