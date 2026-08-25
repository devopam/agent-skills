# Grading criteria: detect — boolean trap + semver misclassification

Tests the **Architecture** domain's API/interface-design expansion — two
distinct findings this scenario is specifically shaped to require both of.

## Must show

- Flags `urgent: bool = False` as a boolean-positional-parameter smell
  (Ruff's `FBT002`-equivalent finding) — a new positional parameter whose
  meaning isn't clear at a future positional call site
  (`send_notification(1, "hi", True)` — what does `True` mean without
  reading the signature). Recommends making it keyword-only
  (`*, urgent: bool = False`) as the fix.
- Flags the **release classification** as wrong: adding a new capability
  (a new parameter, even an optional/backward-compatible one) is a
  MINOR-worthy change per semver's own rules, not a PATCH — PATCH is
  reserved for backward-compatible bug fixes only. The finding should
  name this as a semver-discipline issue (release as 2.4.0, not 2.3.1),
  not just describe the code change.
- Both findings attributed to the **Architecture** domain's scorecard.

## Should not show

- Treating this as a breaking/MAJOR-version change — it is not; the new
  parameter has a default and doesn't break existing callers. Flagging it
  as a breaking change would be a wrong finding, not just an incomplete
  one.
- Missing the semver-classification finding and only catching the
  boolean-trap issue, or vice versa — this scenario is designed to need
  both.
