Please review this project. Tier: web. This is the entire login endpoint —
treat it as representative; there is no rate limiting or brute-force
throttling anywhere in the project, on this or any other endpoint.

```python
# app/api/auth.py
from fastapi import APIRouter, HTTPException
from app.db import get_user_by_email
from app.security import verify_password

router = APIRouter()

@router.post("/login")
def login(email: str, password: str):
    user = get_user_by_email(email)
    if user is None or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {"status": "ok", "user_id": user.id}
```

Please review it.
