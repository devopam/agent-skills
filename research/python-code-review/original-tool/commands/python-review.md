Run a Python code review on the current project.

**Usage:** `/python-review [mode] [options]`
- No arguments: full project review
- `diff`: review only changed files (git diff against main)
- `diff --base=<branch>`: diff against specific branch
- `--pdf`: force PDF output regardless of config
- `--tier=<script|web|enterprise>`: override project tier

**Arguments:** $ARGUMENTS

---

**REQUIRED SKILL:** Load and follow `~/.claude/skills/python-code-review/SKILL.md`

Parse the arguments:
- If first arg is `diff`, set scope mode to diff. Check for `--base=` to override diff base branch.
- If `--pdf` present, add "pdf" to output formats for this run.
- If `--tier=` present, override the project tier for this run.
- Default: full project review with config from `python-review-config.toml` in project root, falling back to defaults in the skill directory.

**Before generating PDF output** (either because `--pdf` was passed or config enables PDF):
Run this one-liner via Bash to ensure weasyprint is importable — auto-install if missing, skip silently if already present:

```bash
python -c "import weasyprint" 2>/dev/null || pip install weasyprint
```

If the install fails (missing native GTK/Pango libs on Windows, or no network), report the failure to the user, fall back to markdown + console output for this run, and point them to INSTALL.md for the platform-specific native deps. Do not abort the whole review.

Execute the review workflow defined in SKILL.md.
