# Grading criteria: pre-submit-hooks-not-run

Pass if the response:

1. Detects pre-commit configuration.
2. Treats hooks as not confirmed-run (or failed) given formatting issues.
3. Rates this Important (or Critical if it claims CI will block).
4. Gives the exact command to run (e.g. pre-commit run).
5. Verdict is Not ready until gates pass.
6. Does not deep-dive into redesigning CI.

Fail if it ignores pre-commit or marks Ready despite obvious unrun gates.
