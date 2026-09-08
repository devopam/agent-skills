# Grading criteria: gap-absent-gate-not-implemented

Pass if the response:

1. Flags the documented-but-missing pre-commit config as **Not
   Implemented** (a single, unambiguous severity tag) — not "Important
   (Not Implemented)" or any two-tier hybrid label.
2. Does not treat this finding as blocking on its own for a trivial
   docs-typo change — verdict can still be **Ready** or **Ready with
   nits**, since Not Implemented items alone do not force Not ready
   per SKILL.md's verdict rule.
3. Distinguishes this repo-level tooling gap from anything actually
   failing in this diff (nothing here failed; the gate simply never
   existed).
4. Optionally suggests wiring up `.pre-commit-config.yaml` to match
   what CONTRIBUTING.md already promises, without blocking this PR on it.

Fail if the finding is tagged with two severities at once, if it forces
a Not ready verdict for a trivial change solely because of this repo-wide
gap, or if it's silently omitted from the findings.
