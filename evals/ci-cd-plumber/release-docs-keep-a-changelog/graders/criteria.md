# Grading criteria: release-docs-keep-a-changelog

Pass if the response:

1. Reads/follows guidance consistent with Keep a Changelog (Unreleased
   section, versioned sections, categories such as Added/Changed/Fixed).
2. Leverages Conventional Commits when present rather than inventing
   history.
3. Proposes additive, reviewable changes (new CHANGELOG.md; optional
   release-please or equivalent) rather than destructive rewrites.
4. Stays in release-documentation scope; does not redesign the whole
   pipeline unless asked.
5. Notes any limits (e.g. incomplete history, non-conventional older
   commits) honestly.

Fail if it fabricates detailed release notes not grounded in commits, or
omits the Unreleased section for an active project.
