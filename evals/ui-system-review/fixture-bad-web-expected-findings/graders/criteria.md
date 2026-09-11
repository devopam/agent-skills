# Grading criteria: fixture-bad-web-expected-findings

Pass if the response:

1. Scores **System foundation** and/or **Tokens & theme** and **Icons & media**
   clearly low (not 8–10).
2. Flags dual MUI+Chakra (or dual providers) as Important or Critical.
3. Flags hardcoded hex / magic spacing despite `tokens.css`.
4. Flags mixed icon libraries.
5. Mentions fixed-width / non-responsive shell under Form factors (or similar).
6. Includes remediation ordered by severity; does not claim it already rewrote
   the app.

Fail if the fixture is scored as clean/mature or dual-kit issues are omitted.
