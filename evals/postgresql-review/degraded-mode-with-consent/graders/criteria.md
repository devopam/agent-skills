# Grading criteria: degraded-mode-with-consent

Pass if the response:

1. Confirms the user's explicit consent before proceeding (does not silently
   downgrade without having asked, and does not proceed if consent were
   only implied).
2. Uses only `pg_catalog` / `information_schema` / `pg_stat_*` (and
   `pg_stat_statements` if present) — no MCPg tool calls.
3. Marks confidence reduced and advisor-quality items (e.g. index/config
   recommendations that need `run_advisors` or `recommend_indexes`) as
   **Not Implemented** rather than scoring them as if MCPg ran.
4. Labels the run plainly as a **degraded** review in the header — never
   presents it as a full MCPg-backed review.

Fail if it fabricates MCPg tool output, silently treats degraded output as
equivalent to a full review, or proceeds into degraded mode without the
user's consent having actually been given in the prompt.
