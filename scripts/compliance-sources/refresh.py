#!/usr/bin/env python3
"""Registry-driven refresh for compliance-sources snapshots.

Fetches primary_url (and watch_urls) with timed retries + backoff on failure.
Writes snapshots/<id>/meta.json. Prints markdown summary for PR bodies.
"""

from __future__ import annotations

import hashlib
import json
import socket
import sys
import time
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
USER_AGENT = (
    "agent-skills-compliance-sources-refresh/0.3 "
    "(+https://github.com/devopam/agent-skills)"
)
FETCH_TIMEOUT_SEC = 20
MAX_BODY_BYTES = 2_000_000
# Timed retries for transient portal failures / timeouts
MAX_ATTEMPTS = 3
BACKOFF_SEC = (2.0, 5.0, 10.0)  # before attempt 2, 3, (unused 4th)


def load_registry() -> dict:
    with REGISTRY.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def fetch_once(url: str, timeout: int = FETCH_TIMEOUT_SEC) -> tuple[bytes | None, str | None]:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "text/html,application/xhtml+xml,application/pdf,*/*",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            chunks: list[bytes] = []
            total = 0
            while True:
                chunk = resp.read(64 * 1024)
                if not chunk:
                    break
                total += len(chunk)
                if total > MAX_BODY_BYTES:
                    remain = MAX_BODY_BYTES - (total - len(chunk))
                    if remain > 0:
                        chunks.append(chunk[:remain])
                    break
                chunks.append(chunk)
            return b"".join(chunks), None
    except (urllib.error.URLError, socket.timeout, TimeoutError, OSError) as e:
        return None, f"{type(e).__name__}: {e}"
    except Exception as e:  # noqa: BLE001
        return None, f"{type(e).__name__}: {e}"


def fetch(url: str) -> tuple[bytes | None, str | None, int]:
    """Return (body, error, attempts_used). Retries on failure with backoff."""
    last_err: str | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        body, err = fetch_once(url)
        if body is not None and not err:
            return body, None, attempt
        last_err = err or "empty body"
        if attempt < MAX_ATTEMPTS:
            delay = BACKOFF_SEC[attempt - 1]
            print(
                f"  retry {attempt}/{MAX_ATTEMPTS} after {delay}s: {last_err}",
                file=sys.stderr,
            )
            time.sleep(delay)
    return None, last_err, MAX_ATTEMPTS


def normalize(data: bytes) -> bytes:
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

        print(f"Fetching {sid} ...", file=sys.stderr)
        body, err, attempts = fetch(url)
        status = "ok"
        new_hash = None
        if err or body is None:
            status = "fetch_error"
            new_hash = prev.get("content_hash")
            error_msg = err or "empty body"
        else:
            new_hash = sha256(normalize(body))
            error_msg = None

        changed = bool(
            prev.get("content_hash") and new_hash and prev["content_hash"] != new_hash
        )
        meta = {
            "id": sid,
            "primary_url": url,
            "retrieved_at": now,
            "content_hash": new_hash,
            "status": status,
            "error": error_msg,
            "attempts": attempts,
            "previous_hash": prev.get("content_hash"),
            "changed": changed,
            "pack": src.get("pack"),
            "role": src.get("role"),
            "title": src.get("title"),
        }
        meta_path.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
        rows.append(meta)

        for wurl in src.get("watch_urls") or []:
            wbody, werr, _wattempts = fetch(wurl)
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
    print("| id | status | attempts | changed | pack |")
    print("|----|--------|----------|---------|------|")
    for r in rows:
        print(
            f"| `{r['id']}` | {r['status']} | {r.get('attempts')} | "
            f"{r.get('changed')} | {r.get('pack')} |"
        )
    changed_n = sum(1 for r in rows if r.get("changed"))
    failed_n = sum(1 for r in rows if r["status"] != "ok")
    print()
    print(
        f"Changed: **{changed_n}** · Fetch errors: **{failed_n}** · Total: **{len(rows)}**"
    )
    print()
    print(
        f"Retry policy: up to **{MAX_ATTEMPTS}** attempts per URL, "
        f"backoff {list(BACKOFF_SEC)}s, timeout {FETCH_TIMEOUT_SEC}s."
    )
    if changed_n:
        print()
        print(
            "Review obligation cards under "
            "`skills/regulatory-compliance-applicability-scan/references/packs/` "
            "if a primary hash change reflects substantive legal updates."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
