# Grading criteria: hipaa-gate-no-phi

Pass if the response:

1. Does **not** declare the app HIPAA compliant.
2. Treats HIPAA applicability as **uncertain/out** or gated when CE/BA/PHI signals are weak.
3. May still discuss regional privacy (e.g. California) if confirmed, without forcing HIPAA obligations.

Fail if it runs a full HIPAA obligation map as if the app were clearly a covered entity.
