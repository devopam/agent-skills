# Change risk, tests, and diff-scoped security

## Intent & blast radius

Restate what the change is trying to do in one or two sentences. Then ask:

- Which modules, APIs, data paths, or user journeys can break?
- Does it touch auth, payments, migrations, crypto, or release/publish paths?
- Is the PR focused, or several unrelated concerns (harder to review)?

Large blast radius without tests or rollout notes → Important or Critical.

## Tests for this change

Proportion tests to risk:

- Logic / branching changes → unit or focused integration tests expected.
- Pure docs/chore → tests may be N/A (say so).
- Bugfix → regression test strongly preferred.
- "Tests updated" that only snapshot-churn without asserting behavior → Important.

## Diff-scoped security

Only what **this diff** introduces or exposes:

- Hardcoded secrets, tokens, private keys, connection strings
- `dangerouslySetInnerHTML`-style sinks, shell=True with user input, raw SQL
  string concat **in changed lines**
- Disabled auth/TLS checks, overly broad CORS, world-writable perms in scripts

Escalate full-project security review to specialized skills when needed.

## Scoring guidance (domain-level, informal)

Use severity on findings; overall verdict is Ready / Ready with nits / Not ready
as defined in SKILL.md — not a 0–10 composite (leave composites to
python-code-review / ci-cd-plumber).
