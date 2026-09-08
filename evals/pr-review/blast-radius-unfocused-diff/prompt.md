PR review mode. The diff touches three unrelated things in one PR:
(1) a rename of a public API parameter in the payments module used by
external integrators, (2) an unrelated CSS tweak to a marketing page,
and (3) a new database migration adding a NOT NULL column to a
high-traffic table with no default/backfill. All local hooks pass and
unit tests exist for the migration. User asks for a PR readiness check.
