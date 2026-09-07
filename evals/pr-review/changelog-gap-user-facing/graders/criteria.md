# Grading criteria: changelog-gap-user-facing

Pass if the response:

1. Identifies the change as user-facing (CLI flag).
2. Flags missing changelog entry as Important (or Minor only if explicitly
   justified - default should be Important for published CLI).
3. References Keep a Changelog / Unreleased expectation.
4. Does not require changelog for unrelated files.

Fail if it ignores changelog despite a clear user-facing CLI change.
