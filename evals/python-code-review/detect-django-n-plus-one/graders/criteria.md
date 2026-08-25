# Grading criteria: detect — Django N+1 query

Tests the **Performance** domain's Django-specific N+1 detection and its
current, correct fix (not the deprecated bare-`select_related()` form the
authoring pass specifically corrected).

## Must show

- Flags `o.customer.name` accessed inside the list comprehension as an
  N+1 query pattern — `Order.objects.all()` fetches orders in one query,
  then each `o.customer` access triggers a separate query per order.
- Recommends `select_related("customer")` (a forward `ForeignKey`, the
  correct loader for this relation type) added to the queryset —
  `Order.objects.select_related("customer")`.
- If the fix names `select_related` with explicit field arguments (not
  a bare `select_related()` call with no arguments) — bare
  `select_related()` is deprecated as of Django 6.1 and raises
  `TypeError` starting Django 7.0, a correction this domain's own
  research made to the original tool's guidance.
- Attributed to the **Performance** domain's scorecard.

## Should not show

- Recommending `prefetch_related` instead of `select_related` for this
  relation (this is a forward `ForeignKey`/`OneToOneField`-shaped access,
  where `select_related`'s SQL-JOIN approach is correct — `prefetch_related`
  is for `ManyToManyField`/reverse-FK/`GenericRelation`).
- Recommending bare `select_related()` with no field arguments as the fix.
- Missing the N+1 finding entirely.
