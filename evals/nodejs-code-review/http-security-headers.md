# Eval: HTTP security posture

## Setup
Express app with no helmet/security headers, CORS `*`, tier=web.

## Expected
- Security domain flags headers and CORS
- Suggests remediation without inventing non-existent files

## Fail if
- Claims the app is secure with no findings
