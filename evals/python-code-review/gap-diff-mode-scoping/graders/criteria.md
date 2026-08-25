# Grading criteria: gap — diff-mode scope detection and respect

Tests that a request phrased as "review my changes against main" is
correctly interpreted as diff-mode scope (per `SKILL.md`'s explicit
routing: "a request phrased as 'review my changes' or 'review this PR'
implies diff mode"), and that the review actually stays scoped to the
stated changed file rather than reviewing the whole repo.

## Must show

- Recognizes and states that this is a diff-mode review (against `main`,
  the default base branch), not a full-project review — should be
  explicit about the scope, not silently assume one or the other.
- Reviews only `app/utils/formatting.py` — the file actually named as
  changed.
- Does not fabricate or claim findings in other files the prompt
  explicitly says are unrelated, pre-existing, and out of scope for this
  review.
- May legitimately note the missing type hints on `format_currency`'s
  parameters (a real, in-scope Code Quality finding on the one file that
  IS in scope) — this is a fine, expected finding, not a scope violation.

## Should not show

- Treating this as a full-project review and inventing or generically
  gesturing at issues elsewhere in "the repo" when no other file's
  content was ever provided.
- Ignoring the stated scope and asking to review everything anyway
  instead of working with the one file given.
- Silently defaulting to full-project mode without acknowledging the
  diff-mode phrasing at all.
