#!/bin/bash
exec python3 -c "$(cat <<'PYEOF'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

RESET = "\033[0m"
CYAN = "\033[36m"
BOLD = "\033[1m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"


def pct_color(pct: float) -> str:
    if pct > 80:
        return RED
    if pct > 50:
        return YELLOW
    return GREEN


def fmt_secs(secs: int) -> str:
    if secs < 0:
        secs = 0
    if secs < 3600:
        return f"{secs // 60}m"
    if secs < 86400:
        return f"{secs // 3600}h{(secs % 3600) // 60}m"
    return f"{secs // 86400}d{(secs % 86400) // 3600}h"


def parse_reset(value) -> int | None:
    """Return seconds remaining until `value`, or None if unparseable."""
    if value is None:
        return None
    now = datetime.now(timezone.utc)
    try:
        if isinstance(value, (int, float)):
            target = datetime.fromtimestamp(float(value), tz=timezone.utc)
        else:
            s = str(value).strip()
            if s.isdigit():
                target = datetime.fromtimestamp(int(s), tz=timezone.utc)
            else:
                target = datetime.fromisoformat(s.replace("Z", "+00:00"))
        return int((target - now).total_seconds())
    except Exception:
        return None


def git_branch(cwd: str) -> str | None:
    if not cwd or not os.path.isdir(cwd):
        return None
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "--no-optional-locks", "symbolic-ref", "--short", "HEAD"],
            capture_output=True, text=True, timeout=1,
        )
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
        out = subprocess.run(
            ["git", "-C", cwd, "--no-optional-locks", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=1,
        )
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
    except Exception:
        pass
    return None


def get(d, *path, default=None):
    cur = d
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            return default
        cur = cur[key]
    return cur if cur is not None else default


try:
    data = json.load(sys.stdin)
except Exception:
    data = {}

parts = []

# 1. Model
model = get(data, "model", "display_name") or get(data, "model", "id")
if model:
    parts.append(f"{CYAN}{BOLD}{model}{RESET}")

# 2 & 3. Rate-limit windows
for label, key in (("5h", "five_hour"), ("7d", "seven_day")):
    pct = get(data, "rate_limits", key, "used_percentage")
    reset_at = get(data, "rate_limits", key, "resets_at")
    if pct is None:
        continue
    try:
        pct_int = round(float(pct))
    except (TypeError, ValueError):
        continue
    remaining = parse_reset(reset_at)
    time_str = f" ({fmt_secs(remaining)})" if remaining is not None else ""
    parts.append(f"{pct_color(pct_int)}{label}: {pct_int}%{time_str}{RESET}")

# 4. Context window
ctx_pct = get(data, "context_window", "used_percentage")
if ctx_pct is None:
    ctx_pct = get(data, "context", "used_percentage")
if ctx_pct is not None:
    try:
        pct_int = round(float(ctx_pct))
        parts.append(f"{pct_color(pct_int)}ctx: {pct_int}%{RESET}")
    except (TypeError, ValueError):
        pass

# 5. Git branch
cwd = get(data, "cwd") or get(data, "workspace", "current_dir")
branch = git_branch(cwd) if cwd else None
if branch:
    parts.append(f"{CYAN}{BOLD}⎇ {branch}{RESET}")

sys.stdout.write(" | ".join(parts))
PYEOF
)"
