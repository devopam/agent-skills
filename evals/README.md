# project-incubation evals

8 hand-authored cases testing `project-incubation`'s routing and audit
logic: one retrieval scenario per stack category (5), plus 3 gap scenarios
probing edge cases the skill's own flow documents explicitly (a project
straddling two categories, an existing repo with no baseline record, and
an audit against a stale preferred-libraries snapshot).

Each case is a directory with `prompt.md` (the scenario) and
`graders/criteria.md` (what a pass looks like) — the `prompt.md` +
`graders/*.md` shape `claude plugin eval` documents as one of its two
supported case formats.

## Known limitation: not run in this environment

`claude plugin eval` requires early-access enrollment that was not
available when these cases were authored (`claude plugin eval init`
returned `"plugin eval" is currently in early access`). These cases were
hand-authored against the documented format and the actual skill content,
but **have not been executed** — they haven't been machine-scored, and
the case format hasn't been confirmed against a real run.

Once eval access is available, run from the repo root:

```bash
claude plugin eval . --ablation with-without --runs 3 --no-publish
```

`--ablation with-without` reports the score delta against a no-plugin
baseline. `--no-publish` keeps the report local — never publish without
explicit sign-off (publishing sends results to claude.ai). Iterate with
`--runs 1` and `--case <glob>` to target one case at a time while tuning.
