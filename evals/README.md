# agent-skills evals

Hand-authored eval cases for both skills in this repo, one subdirectory per
skill (`evals/<skill-name>/<case-name>/`) since a single `.claude-plugin/plugin.json`
manifest covers the whole repo and `claude plugin eval` scans its eval
directory recursively.

- **`project-incubation/`** — 12 cases: one retrieval scenario per stack
  category (9, including `retrieval-developer-tooling-libraries`,
  `retrieval-infrastructure-platform-engineering`,
  `retrieval-ml-model-development`, and
  `retrieval-mlops-platform-engineering` for the four categories added
  2026-08-31), plus 3 gap scenarios probing edge cases the skill's own
  flow documents explicitly (a project straddling two categories, an
  existing repo with no baseline record, an audit against a stale
  preferred-libraries snapshot).
- **`python-code-review/`** — 10 cases: 6 detection scenarios (does the
  skill find a real, deliberately planted issue in each of six domains)
  plus 4 mechanism scenarios (tier-gating, diff-mode scoping, the
  Scalability & Resilience domain's distinctive absence-reporting
  mechanic, and domain-boundary non-duplication).

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
`--runs 1` and `--case <glob>` to target one case (or `--case 'project-incubation/*'`
/ `--case 'python-code-review/*'` to target one skill's cases) while tuning.
