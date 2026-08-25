Please review this project. Tier: enterprise. It's a production payment-
processing service that calls two external systems (a fraud-scoring API
and a banking partner API) on every request. Here's the core handler —
treat this as representative of the whole codebase, there is no circuit
breaker, no retry-with-backoff, and no timeout configured anywhere in the
project, on any external call.

```python
# app/handlers/payment_handler.py
import requests

def process_payment(payment_id: str, amount: float):
    fraud_result = requests.post(
        "https://fraud-api.internal/score",
        json={"payment_id": payment_id, "amount": amount},
    ).json()

    if fraud_result["score"] > 0.8:
        return {"status": "rejected"}

    bank_result = requests.post(
        "https://banking-partner.example.com/charge",
        json={"payment_id": payment_id, "amount": amount},
    ).json()

    return {"status": "completed", "bank_ref": bank_result["ref"]}
```

Nothing in this code is technically broken — it runs correctly on the
happy path. Please review it.
