#!/usr/bin/env python3
"""Registry-driven refresh for compliance-sources snapshots.

Reads compliance-sources/registry.yaml, fetches primary_url (and watch_urls),
writes snapshots/<id>/meta.json with content_hash and retrieved_at.
Prints a markdown summary suitable for a PR body.

Does not commit or open PRs — the workflow handles git/gh.
"""

from __future__ import annotations

import hashlib
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "compliance-sources" / "registry.yaml"
SNAPSHOTS = ROOT / "compliance-sources" / "snapshots"
USER_AGENT = "agent-skills-compliance-sources-refresh/0.1 (+https://github.com/devopam/agent-skills)"


def load_registry() -> dict:
    with REGISTRY.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def fetch(url: str, timeout: int = 60) -> tuple[bytes | None, str | None]:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read(), None
    except Exception as e:  # noqa: BLE001 — report any fetch failure
        return None, f"{type(e).__name__}: {e}"


def normalize(data: bytes) -> bytes:
    """Light normalization to reduce pure-noise hash churn."""
    text = data.decode("utf-8", errors="replace")
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    return "\n".join(lines).encode("utf-8")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    reg = load_registry()
    sources = reg.get("sources") or []
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    rows: list[dict] = []

    for src in sources:
        sid = src["id"]
        freq = src.get("check_frequency") or "monthly"
        if freq not in ("monthly", "weekly", "always"):
            continue
        url = src.get("primary_url")
        if not url:
            continue

        snap_dir = SNAPSHOTS / sid
        snap_dir.mkdir(parents=True, exist_ok=True)
        meta_path = snap_dir / "meta.json"
        prev = {}
        if meta_path.exists():
            prev = json.loads(meta_path.read_text(encoding="utf-8"))

        body, err = fetch(url)
        status = "ok"
        new_hash = None
        if err or body is None:
            status = "fetch_error"
            new_hash = prev.get("content_hash")
            error_msg = err or "empty body"
        else:
            new_hash = sha256(normalize(body))
            error_msg = None

        changed = bool(prev.get("content_hash") and new_hash and prev["content_hash"] != new_hash)
        meta = {
            "id": sid,
            "primary_url": url,
            "retrieved_at": now,
            "content_hash": new_hash,
            "status": status,
            "error": error_msg,
            "previous_hash": prev.get("content_hash"),
            "changed": changed,
            "pack": src.get("pack"),
            "role": src.get("role"),
            "title": src.get("title"),
        }
        meta_path.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
        rows.append(meta)

        # Optional watch URLs — hash recorded under meta only as side note
        for wurl in src.get("watch_urls") or []:
            wbody, werr = fetch(wurl)
            wmeta_path = snap_dir / ("watch-" + sha256(wurl.encode())[:12] + ".json")
            wmeta = {
                "url": wurl,
                "retrieved_at": now,
                "content_hash": sha256(normalize(wbody)) if wbody else None,
                "status": "ok" if wbody else "fetch_error",
                "error": werr,
            }
            wmeta_path.write_text(json.dumps(wmeta, indent=2) + "\n", encoding="utf-8")

    print("## compliance-sources refresh")
    print()
    print(f"Retrieved at: `{now}`")
    print()
    print("| id | status | changed | pack |")
    print("|----|--------|---------|------|")
    for r in rows:
        print(
            f"| `{r['id']}` | {r['status']} | {r.get('changed')} | {r.get('pack')} |"
        )
    changed_n = sum(1 for r in rows if r.get("changed"))
    failed_n = sum(1 for r in rows if r["status"] != "ok")
    print()
    print(f"Changed: **{changed_n}** · Fetch errors: **{failed_n}** · Total: **{len(rows)}**")
    if changed_n:
        print()
        print(
            "Review obligation cards under "
            "`skills/regulatory-compliance-applicability-scan/references/packs/` "
            "if a primary hash change reflects substantive legal updates."
        )
    return 0 if failed_n == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
