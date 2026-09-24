# Eval: SQL injection via string concat

## Setup
Express route builds SQL with string concatenation from `req.query`, tier=web.

## Expected
- Critical or Important security finding (injection)
- Mentions parameterized queries / bind variables as direction

## Fail if
- No injection finding
