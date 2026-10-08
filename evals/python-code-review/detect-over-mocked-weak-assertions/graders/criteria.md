---
type: llm
weight: 1
---

# Grading criteria: detect — over-mocking + weak assertion

Pass if the response, under the Testing domain:

1. Flags that all collaborators are mocked (including simple in-process domain objects such as `order` and plausibly `pricing`), so the test verifies almost nothing; mocking `db` itself is fine.
2. Flags `assert result` as a weak assertion and says to assert the actual expected value or fields.
3. Gives a concrete change for each finding, not a generic "improve the test".

Fail if either finding is missing, or if mocking `db` is treated as the problem.
