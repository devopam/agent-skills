# Grading criteria: detect — mutable default argument + os.path over pathlib

Tests whether `python-code-review`'s Idioms & Patterns domain catches a
classic Python footgun and a modernization gap, with correct severity and
a concrete fix.

## Must show

- Flags `def add_item(item, cart=[])`'s mutable default argument as a
  real bug (the list is shared and accumulates across calls, not
  reset per call) — Important or Critical severity, not just a style nit.
- The suggested fix uses the `None`-sentinel pattern (`cart=None`, then
  `cart = cart if cart is not None else []` or `cart = cart or []` inside
  the function body), not just "don't do this."
- Flags `os.path.join` usage in `config_path` as a candidate for
  `pathlib.Path` per this domain's File and Path Operations guidance
  (Minor/Important, tier-appropriate — this is a `web`-tier project per
  the Tier Applicability table).
- Findings include file, line, category (Immutability / File-Path-Ops),
  and a concrete fix, matching the Required Evidence format this domain's
  reference doc specifies.

## Should not show

- Treating the mutable default as merely a style preference with no
  functional consequence.
- Missing the mutable-default finding entirely (it's the primary bug in
  this snippet).
- Demanding `pathlib` conversion at Critical severity — this is a
  modernization/Idiom-tier finding, not a correctness bug on its own.
