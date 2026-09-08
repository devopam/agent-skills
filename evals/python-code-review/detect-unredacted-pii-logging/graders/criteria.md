# Grading criteria: detect — unredacted PII/secret in logs + swallowed traceback

Tests whether `python-code-review`'s Observability domain catches a real
PII/secret-in-logs exposure and a traceback-losing exception handler, with
correct severity and a concrete fix.

## Must show

- Flags logging the full `card_number` (and arguably the email) in plain
  text as a Critical or Important PII/secret-redaction finding — a card
  number in application logs is a real compliance/security exposure, not
  a style nit.
- The suggested fix redacts or masks the sensitive fields (e.g. log only
  a last-4-digits token or a hashed/opaque reference) rather than
  suggesting removal of logging altogether.
- Flags `logger.error(str(e))` as losing the traceback — the fix is
  `logger.exception(...)` (or `logger.error(..., exc_info=True)`), not
  just "log more."
- Findings include file, line, category (PII-Secret-Redaction /
  Log-Context), and a concrete fix, matching the Required Evidence format
  this domain's reference doc specifies.

## Should not show

- Treating the card-number logging as a minor style issue.
- Missing the `str(e)` / lost-traceback finding entirely.
- Suggesting the fix is to simply remove the log line rather than redact
  and preserve useful signal.
