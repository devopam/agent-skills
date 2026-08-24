# Standards Compliance Review Domain

## Scope
Checks whether the project follows structural and tooling standards that ensure
maintainability, reproducibility, and team consistency.

## Tier Applicability
| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Project layout | Yes | Yes | Yes |
| pyproject.toml | Yes | Yes | Yes |
| .env.example | No | Yes | Yes |
| Pre-commit hooks | No | Yes | Yes |
| Quality scripts | No | Yes | Yes |
| CI/CD config | No | Optional | Yes |

## Review Criteria

### Critical
(None — standards compliance issues are never blocking on their own)

### Important

**Project Structure**
- `src/<project_name>/` layout present
- `tests/` directory exists and mirrors src structure
- `pyproject.toml` exists (not `setup.py` or `requirements.txt` alone)
- `.gitignore` present with Python-specific patterns
- No `__pycache__`, `.pyc`, or `.egg-info` committed

**Environment & Config**
- `.env.example` template exists (web/enterprise tier)
- No `.env` file committed (contains secrets)
- Configuration loaded via environment variables or config library
- No hardcoded connection strings, API keys, or credentials in source

**Capability Detection**
For each capability in `[standards.recommended_libraries]`:
1. Scan `pyproject.toml` dependencies and import statements
2. If a recommended library is found → no comment
3. If an alternative library serving the same capability is found → informational note
4. If NO library for the capability is detected → flag at `missing_capability_severity`

When flagging a missing capability, suggest from the recommended list:
- "No structured logging detected. Consider: loguru, structlog"
- "No retry mechanism found for external calls. Consider: tenacity"

**Development Tooling**
- Formatter configured (black, ruff, or autopep8 in pyproject.toml or config file)
- Linter configured (flake8, ruff, or pylint)
- Type checker configured (mypy or pyright)
- Pre-commit hooks present (`.pre-commit-config.yaml`) — web/enterprise tier

### Minor
- `README.md` present with project description
- `CHANGELOG.md` present
- `scripts/` directory with quality/setup automation
- `docs/` directory for documentation
- License file present

## Scoring Guide
- 10: All important checks pass, all minor items present
- 8-9: All important checks pass, some minor items missing
- 6-7: Most important checks pass, 1-2 gaps in capability detection
- 4-5: Missing pyproject.toml or src layout, multiple capability gaps
- 1-3: No recognizable project structure, widespread gaps
