Please review this file for issues. Context: this is a small, standalone
utility library published to PyPI. The function below already exists in
the current released version with the signature
`def send_notification(user_id: int, message: str) -> bool:` — this PR
adds a new parameter to it.

```python
# notify_lib/core.py
def send_notification(user_id: int, message: str, urgent: bool = False) -> bool:
    """Send a notification to a user.

    Args:
        user_id: The recipient's user ID.
        message: The notification body.
        urgent: Whether to bypass the user's quiet-hours setting.
    """
    ...
```

The maintainer plans to release this as a patch version bump (the next
release after the current one, e.g. 2.3.0 -> 2.3.1). Tier: web.
