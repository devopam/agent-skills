# Grading criteria: android-dual-theme-xml-compose

Pass if the response:

1. Flags dual XML + Compose theme sources and/or partial MaterialTheme coverage
   as Important (or Critical if framed as conflicting systems).
2. Flags raw Color literals vs colorScheme roles.
3. Flags missing window size class / adaptive layout when tablet support is
   claimed (Form factors / Not Implemented or Important).
4. Remediation suggests unifying on MaterialTheme roles and adaptive layout —
   not applying code changes unsolicited.

Fail if dual-theme risk or tablet claim gap is ignored.
