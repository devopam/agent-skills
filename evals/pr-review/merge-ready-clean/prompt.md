---
name: pr-review-merge-ready-clean
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Pre-submit. Diff is a one-line bugfix in `parse_date` plus a regression
test in `tests/test_parse_date.py`. pre-commit was run successfully (user
states so). CHANGELOG Unreleased updated under Fixed. No secrets. User:
"Ready to open the PR?"

The repository is in the current working directory; the change is committed on the current branch and `main` is the base.
