# Grading criteria: detect — SQL injection + weak password hashing

Tests whether `python-code-review`'s Security domain catches two distinct,
real Critical-tier issues in a small snippet, with correct severity and a
concrete fix — not just a vague "this looks insecure."

## Must show

- Flags the f-string-interpolated SQL query in `get_user_by_email` as SQL
  injection — **Critical** severity, citing the injection category
  (mapped to OWASP A05:2025 Injection or equivalent current citation).
- The suggested fix is a parameterized query (e.g.
  `cursor.execute("SELECT ... WHERE email = %s", (email,))`), not a
  string-sanitization workaround.
- Flags `hash_password`'s use of unsalted SHA-256 for password storage as
  a Critical/Important cryptography finding — names the correct current
  remediation (Argon2id as the lead recommendation, per the domain's own
  sourced preference order), not just "use a better hash."
- Both findings include file, line, what's wrong, why it matters, and a
  concrete fix — matching the Required Evidence format the domain's own
  reference doc specifies.

## Should not show

- Treating the SQL injection as anything less than Critical.
- Suggesting `hashlib.sha256` with a manually-added salt as a sufficient
  fix (the correct fix is a purpose-built password-hashing function, not
  a general-purpose hash plus salt).
- Missing either finding entirely.
