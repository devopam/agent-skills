---
type: llm
weight: 1
---

# Grading criteria: detect — mutable default argument + os.path over pathlib

Pass if the response:

1. Flags the mutable default `cart=[]` in `add_item` as a real bug (shared
   state across calls) at Important or Critical severity.
2. Proposes a fix that uses a `None` default (a fresh list inside the body,
   or returning a new list without mutating the argument).
3. Notes that `os.path.join` in `config_path` could use `pathlib.Path`
   (any severity up to Important; it may be folded into another finding).
4. Cites file and line (or line number) for the findings.

Fail if the mutable default is missed or treated as only a style preference,
or if `pathlib` conversion is demanded at Critical severity.
