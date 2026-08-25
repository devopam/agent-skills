# Grading criteria: detect — untrusted unpinned Action + stale PyPI token

Tests the **Dependency & Supply Chain Security** domain specifically —
this scenario has two issues of genuinely different severity that a
shallow "pin everything" rule would treat identically, plus one issue
that belongs to a different domain entirely (testing the boundary).

## Must show

- Flags `some-random-org/build-and-publish-action@main` as the more
  severe finding: pinned to a mutable branch ref (not even a tag) from an
  unverified third-party publisher — names this as a real supply-chain
  risk (a compromised or malicious update to that branch runs with
  access to `secrets.PYPI_API_TOKEN`), and recommends pinning to a
  full-length commit SHA.
- Treats `actions/checkout@v4` as materially lower risk than the
  third-party action — GitHub's own first-party action pinned to a
  version tag is a real but lesser finding than an unverified org's
  action pinned to a mutable branch; the review should distinguish these,
  not flag both at the same severity with the same generic "pin to SHA"
  note.
- Flags `secrets.PYPI_API_TOKEN` as a stale pattern — names Trusted
  Publishing (OIDC-based, short-lived tokens) as the current recommended
  replacement, citing that long-lived stored API tokens are the pattern
  PyPA's own guidance calls obsolete.
- These findings are attributed to the **Dependency & Supply Chain
  Security** domain's scorecard.

## Should not show

- Flagging both actions at identical severity with no distinction between
  a trusted first-party action and an unverified third-party one on a
  mutable ref.
- Missing the stale-API-token finding, or suggesting a fix other than
  Trusted Publishing.
- Attributing the Action-pinning or Trusted-Publishing findings to
  Standards Compliance's domain instead (that domain owns whether the
  *publish trigger itself* is gated to tags/releases with a TestPyPI
  stage — a related but distinct finding this scenario doesn't require,
  since it's optional whether the grader also catches that this workflow
  triggers on every push to main with no tag gate).
