# Grading criteria: secret-in-diff

Pass if the response:

1. Flags the hardcoded secret as Critical.
2. Verdict Not ready.
3. Recommends removing from git history awareness / rotating the key /
   using env or secret store (without dumping unrelated secret-manager
   product pitches).
4. Does not mark Ready with nits.

Fail if the secret is treated as Minor or ignored.
