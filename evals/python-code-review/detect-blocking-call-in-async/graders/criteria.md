# Grading criteria: detect — blocking calls inside an async function

Tests whether `python-code-review` correctly attributes a blocking-call-
in-async finding to the **Concurrency & Async Correctness** domain
specifically, not Performance — the exact boundary the domain-scoping
research drew and the authoring pass carried through both files.

## Must show

- Flags both `requests.get(...)` (a synchronous, blocking HTTP call) and
  `time.sleep(2)` inside `async def generate_report` as blocking-call
  defects — each stalls the entire single-threaded event loop for every
  other concurrently-scheduled coroutine, not just this request.
- Attributes this finding to the **Concurrency & Async Correctness**
  domain's scorecard, not Performance's — if the review output shows a
  per-domain breakdown, this finding's domain tag must be Concurrency &
  Async Correctness.
- Suggests concrete fixes: an async HTTP client (e.g. `httpx.AsyncClient`)
  in place of `requests`, and `asyncio.sleep(2)` in place of `time.sleep(2)`.
- If Ruff-rule-backed guidance is cited, names rules from the `ASYNC`
  category (e.g. `blocking-http-call-in-async-function`,
  `blocking-sleep-in-async-function`) rather than a generic category.

## Should not show

- Attributing this finding to the Performance domain's score instead of
  Concurrency & Async Correctness's.
- Missing either blocking call.
- Treating this as merely a style/idiom issue rather than a correctness
  defect (an async function that blocks the loop is a liveness bug, not
  a preference).
