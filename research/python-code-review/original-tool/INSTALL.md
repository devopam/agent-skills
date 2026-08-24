# Install — python-code-review skill

A Claude Code skill that reviews Python projects across 8 domains
(Standards, Code Quality, Security, Performance, Idioms, Architecture,
Observability, Scalability & Resilience) and emits a scored report to
console, markdown, and optionally PDF.

## Prerequisites

- Claude Code CLI installed (`claude --version`)
- A `~/.claude/` directory (created by Claude Code on first run)

## Install

Extract the tarball into your Claude user directory:

**Git Bash / WSL / macOS / Linux**
```bash
mkdir -p ~/.claude/skills
cd ~/.claude/skills
tar xzvf /path/to/python-code-review-skill-v1.0.tgz
```

**PowerShell (Windows 10+)**
```powershell
mkdir -Force $HOME\.claude\skills | Out-Null
cd $HOME\.claude\skills
tar xzvf C:\path\to\python-code-review-skill-v1.0.tgz
```

This places:
- `~/.claude/skills/python-code-review/` — skill bundle (SKILL.md, config, 8 domain files, report template)
- `~/.claude/skills/commands/python-review.md` — `/python-review` slash command

## Verify

```bash
ls ~/.claude/skills/python-code-review/
ls ~/.claude/skills/commands/python-review.md
```

Launch Claude Code in any Python project and run:
```
/python-review
```

Claude Code auto-discovers the skill on startup — no restart or registry command needed. If `/python-review` is not recognized, quit and relaunch Claude Code once.

## Optional: PDF output

Markdown and console reports work out of the box. PDF is opt-in via the
`--pdf` flag and requires `weasyprint` in whatever Python environment
Claude will invoke.

### One-liner: check-and-install

**macOS / Linux / WSL / Git Bash**
```bash
python -c "import weasyprint" 2>/dev/null || pip install weasyprint
```

**PowerShell**
```powershell
python -c "import weasyprint" 2>$null; if ($LASTEXITCODE -ne 0) { pip install weasyprint }
```

Exit code `0` means weasyprint is importable; anything else triggers install.

### Per-project (recommended)

If your project has a virtual env, install inside it:
```bash
source .venv/bin/activate        # or: .venv\Scripts\activate
python -c "import weasyprint" 2>/dev/null || pip install weasyprint
```

### Platform caveats

`weasyprint` needs native libraries (`pango`, `cairo`, `gdk-pixbuf`):

- **macOS:** `brew install pango`
- **Debian/Ubuntu:** `sudo apt install libpango-1.0-0 libpangoft2-1.0-0`
- **Windows:** GTK runtime — see https://weasyprint.readthedocs.io/en/stable/install.html#windows

If install fails, the skill still produces markdown and console output
— only `--pdf` is affected.

## Update

Replace the folder with a newer tarball:
```bash
rm -rf ~/.claude/skills/python-code-review
cd ~/.claude/skills && tar xzvf /path/to/python-code-review-skill-vNEW.tgz
```

## Uninstall

```bash
rm -rf ~/.claude/skills/python-code-review
rm -f  ~/.claude/skills/commands/python-review.md
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/python-review` not found | Restart Claude Code; confirm the slash command file exists at `~/.claude/skills/commands/python-review.md` |
| PDF output fails | Run the check-and-install one-liner above; verify native GTK/Pango libs are present |
| Report says "no Python files" | Run from a project root that contains `.py` files; check that `src/` or root-level scripts aren't being excluded by `.gitignore` patterns |
| Review scores all domains 0/10 | Tier mismatch — pass `--tier=script` for simple scripts, default is `web`. See `python-review-config.toml` in the skill folder for per-project overrides |

## Configuration

Drop a `python-review-config.toml` in a target project's root to override
defaults (tier, pass/floor scores, per-domain thresholds, disabled
domains). The template lives at
`~/.claude/skills/python-code-review/python-review-config.toml` — copy
and edit.

## Skill files

```
python-code-review/
├── SKILL.md                      # orchestrator
├── INSTALL.md                    # this file
├── python-review-config.toml     # default config + template
├── report-template.md            # markdown report skeleton
├── report-style.css              # PDF stylesheet
└── review-domains/
    ├── standards-compliance.md
    ├── code-quality.md
    ├── security.md               # VAPT/WAPT, injection, CSRF, CORS, SSRF, PII, LLM
    ├── performance.md
    ├── idioms-and-patterns.md
    ├── architecture.md
    ├── observability.md
    └── scalability-and-resilience.md
```
