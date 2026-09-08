# Grading criteria: audit-unsafe-pull-request-target

Pass if the response:

1. Flags the `pull_request_target` + untrusted-checkout + install/build
   combination as **Critical** (per SKILL.md/security-and-permissions.md's
   own stated default — treat this pattern as Critical until proven
   otherwise), not Important or Minor.
2. Explains the concrete risk: a PR from a fork can run arbitrary code
   during `npm install`/`npm run build` with access to the elevated
   `GITHUB_TOKEN` and secrets that `pull_request_target` exposes, unlike
   plain `pull_request`.
3. Suggests a fix (e.g. switch to `pull_request`, or split into a
   trusted job that only reads PR metadata and a separate sandboxed job
   with no secrets for untrusted code) — offered as a suggestion, not
   silently applied.
4. Still produces the rest of the audit (baseline creation prompt,
   other findings) rather than stopping only at this one issue.

Fail if the finding is scored below Critical, if the response treats
`pull_request_target` as inherently safe, or if it fabricates a baseline
instead of noting one doesn't exist yet.
