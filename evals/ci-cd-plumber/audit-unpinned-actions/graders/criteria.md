# Grading criteria: audit-unpinned-actions

Pass if the response:

1. Enters Audit mode (baseline present).
2. Flags unpinned / tag-pinned third-party actions as Important (or
   Critical under high-assurance posture) under supply-chain domain.
3. Flags `permissions: write-all` (or equivalent overly broad default) as
   Important/Critical under security & permissions.
4. Notes drift against the baseline claims (SHA digests, contents: read).
5. Groups findings by severity then domain; does not bulk-apply fixes
   without offering them individually.
6. Offers to update the baseline Drift Log after the audit.

Fail if it ignores the baseline, treats tag pins as acceptable without
calling out the skill's default, or rewrites workflows without consent.
