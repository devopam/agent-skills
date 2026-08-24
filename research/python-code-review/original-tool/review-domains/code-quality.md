# Code Quality Review Domain

## Scope
Evaluates code readability, maintainability, and adherence to Python coding
standards. Focuses on structural quality that affects long-term health.

## Tier Applicability
All checks apply to all tiers (script, web, enterprise).

## Review Criteria

### Critical
- Bare `except:` clauses (swallows all exceptions including SystemExit, KeyboardInterrupt)
- `except Exception` that silently passes without logging or re-raising

### Important

**Type Annotations**
- All public functions and methods have parameter and return type hints
- Modern syntax used: `list[str]` not `List[str]` (PEP 585, Python 3.10+)
- Union types use `X | Y` not `Union[X, Y]` (PEP 604, Python 3.10+)
- `None` return explicitly annotated as `-> None`
- Complex types use `TypeAlias` or `type` statement (3.12+)

**Naming Conventions**
- Functions and variables: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Private members: `_single_leading_underscore`
- No single-letter variables except loop counters (`i`, `j`, `k`) and
  well-known conventions (`x`, `y` for coordinates, `n` for count)

**Complexity**
- Cyclomatic complexity per function < 10 (flag functions scoring 10+)
- Functions ≤ 40 lines of logic (excluding docstring and blank lines)
- Classes with > 10 public methods warrant decomposition review
- Nesting depth ≤ 3 levels (consider early returns or extraction)

**Documentation**
- Google-style docstrings on all public functions and classes
- Docstrings describe behavior and parameters, not implementation
- No redundant comments restating what code already says
- TODO/FIXME comments reference a ticket or issue tracker URL

**Import Organization**
- Three grouped blocks: stdlib, third-party, local — separated by blank lines
- No wildcard imports (`from module import *`)
- No implicit relative imports
- Sorted alphabetically within each block (isort-compatible)

**Dead Code**
- No commented-out code blocks
- No unreachable code after return/raise/break/continue
- No unused imports, variables, or function parameters
- No leftover `print()` or `breakpoint()` debug statements

### Minor
- Docstrings on private helper functions
- Inline comments for non-obvious logic
- Consistent string quoting style (single or double, not mixed)
- Use of `__all__` in `__init__.py` to control public API

## Scoring Guide
- 10: Full type coverage, clean naming, low complexity, thorough docs, zero dead code
- 8-9: Minor gaps in type hints or docstrings, complexity within limits
- 6-7: Several functions missing type hints, some complexity hotspots
- 4-5: Widespread missing types, high complexity functions, dead code present
- 1-3: No type hints, bare excepts, naming chaos, no documentation
