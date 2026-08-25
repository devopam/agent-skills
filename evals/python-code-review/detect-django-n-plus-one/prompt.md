Please review this file for issues:

```python
# app/views/order_views.py
from django.http import JsonResponse
from .models import Order

def order_list(request):
    orders = Order.objects.all()
    data = [
        {"id": o.id, "customer_name": o.customer.name, "total": o.total}
        for o in orders
    ]
    return JsonResponse({"orders": data})
```

Tier: web. This is the whole file, treat it as a full-project review.
