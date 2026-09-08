Please review this file for issues:

```python
# app/services/cart.py
import os

def add_item(item, cart=[]):
    cart.append(item)
    return cart

def config_path(name, base=None):
    base = base or os.path.join("/etc/app", name)
    return base
```

Tier: web. This is the whole file, treat it as a full-project review.
