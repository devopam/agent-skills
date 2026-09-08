Please review this file for issues:

```python
# app/services/checkout.py
import logging

logger = logging.getLogger(__name__)

def charge_card(user_email, card_number, amount):
    logger.info(f"Charging card for {user_email}: card={card_number} amount={amount}")
    try:
        result = payment_gateway.charge(card_number, amount)
    except Exception as e:
        logger.error(str(e))
        raise
    return result
```

Tier: web. This is the whole file, treat it as a full-project review.
