Please review this file for issues:

```python
# app/repositories/user_repo.py
import psycopg2

def get_user_by_email(conn, email: str):
    cursor = conn.cursor()
    query = f"SELECT id, email, password_hash FROM users WHERE email = '{email}'"
    cursor.execute(query)
    return cursor.fetchone()

def hash_password(password: str) -> str:
    import hashlib
    return hashlib.sha256(password.encode()).hexdigest()
```

Tier: web. This is the whole file, treat it as a full-project review.
