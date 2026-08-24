# Idioms & Patterns Review Domain

## Scope
Evaluates whether code follows Pythonic conventions, uses modern language features,
and avoids well-known anti-patterns. Focused on readability and maintainability
through idiomatic Python.

## Tier Applicability
All checks apply to all tiers (script, web, enterprise).

## Review Criteria

### Critical
(None — idiom violations are quality issues, not blocking failures)

### Important

**Modern Python (3.10+)**
- `match` statements for complex conditional dispatch (where clearer than if/elif)
- `list[str]` not `List[str]`, `dict[str, int]` not `Dict[str, int]` (PEP 585)
- `X | Y` not `Union[X, Y]`, `X | None` not `Optional[X]` (PEP 604)
- Structural pattern matching where it improves clarity
- Walrus operator `:=` where it eliminates redundant calls (not forced)

**File & Path Operations**
- `pathlib.Path` over `os.path` for all path manipulation
- Context managers (`with` statement) for file handles, DB connections, locks
- `smart-open` or `pathlib` over raw `open()` for complex file handling

**Data Handling**
- Comprehensions over verbose for-loops for transformations (no side effects in comprehensions)
- Generator expressions for large sequences that don't need full materialization
- `zip()`, `enumerate()`, `any()`, `all()` over manual index tracking / flag patterns
- Unpacking: `a, b = pair` over `pair[0]`, `pair[1]`
- `dataclasses` or `pydantic.BaseModel` over plain dicts for structured data
- Named tuples or dataclasses over positional tuples for return values with > 2 elements

**Immutability**
- Functions return new objects rather than mutating arguments in place
- `None` as default parameter, initialized inside function body
- `tuple` over `list` for fixed-size, immutable sequences
- `frozenset` over `set` for hashable/immutable set needs

**Error Handling**
- Specific exception types, never bare `except:` or broad `except Exception:`
- Custom exceptions inherit from domain-specific base, not raw `Exception`
- EAFP (try/except) preferred over LBYL (if/check) for duck typing
- Context-rich error messages including relevant variable state

**String Operations**
- f-strings for interpolation (not `.format()` or `%` operator)
- Raw strings (`r"..."`) for regex patterns
- Multi-line strings with triple quotes, not concatenation
- ASCII only in source files

### Minor
- Ternary expressions for simple conditional assignments
- `collections.defaultdict` / `collections.Counter` where applicable
- `functools.lru_cache` for pure function memoization
- `itertools` usage for complex iteration patterns
- Avoiding deeply nested ternaries or comprehensions (readability first)

## Scoring Guide
- 10: Fully idiomatic, modern syntax, clean patterns throughout
- 8-9: Mostly idiomatic, 1-2 legacy patterns (os.path, old typing syntax)
- 6-7: Mix of modern and legacy patterns, some anti-patterns
- 4-5: Predominantly non-idiomatic, verbose where comprehensions fit, os.path throughout
- 1-3: No Pythonic patterns, Java/C-style code, mutable defaults, bare excepts
