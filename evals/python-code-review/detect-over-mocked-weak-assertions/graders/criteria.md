# Grading criteria: detect — over-mocking + weak assertion

Tests the **Testing** domain's ability to catch a test that runs green
but verifies almost nothing — every collaborator mocked (including
whatever `order`/`pricing` domain objects likely are, not just genuinely
expensive/external ones like `db`), and an assertion so weak
(`assert result`) it would pass against nearly any non-`None`/non-falsy
return value.

## Must show

- Flags the blanket mocking of all four collaborators (`db`, `pricing`,
  `order`, `logger`) as over-mocking — reasons that mocking a simple,
  in-process domain object (`order`, and plausibly `pricing`) removes the
  "mini-integration test" property real collaborators would give for
  free, per the domain's own sourced mocking-discipline guidance
  (awkward/expensive/non-deterministic collaborators are the right things
  to mock; cheap deterministic ones generally shouldn't be).
- Flags `assert result` as a weak/non-specific assertion — the fix is
  asserting the actual expected shape/value (e.g.
  `assert result == {...}` or specific field checks), not merely that
  something truthy came back.
- Both findings attributed to the **Testing** domain's scorecard.

## Should not show

- Treating `db` being mocked as a problem — mocking a database
  connection is the correct, expected pattern this scenario isn't testing
  against.
- Missing either finding, or only flagging one of the two.
- A finding phrased so generically ("this test could be better") that it
  wouldn't tell a developer what to actually change.
