#!/usr/bin/env bash
# goal-loop skill — install or update, with auto-sync.
# Clones the skill into ~/.claude/skills/goal-loop and adds a Claude Code SessionStart
# hook that `git pull`s the latest on every session start, so future updates arrive
# automatically. Safe to re-run; replaces a prior non-git (static) install.
set -euo pipefail

REPO="https://github.com/JD2005L/claude-goal-loop.git"
DEST="$HOME/.claude/skills/goal-loop"

mkdir -p "$HOME/.claude/skills"

if [ -d "$DEST/.git" ]; then
  echo "Updating existing goal-loop clone..."
  git -C "$DEST" pull --quiet --ff-only || echo "  (pull skipped — local changes or offline)"
else
  if [ -e "$DEST" ]; then
    echo "Replacing prior (non-git) goal-loop install..."
    rm -rf "$DEST"
  fi
  echo "Cloning goal-loop..."
  git clone --quiet "$REPO" "$DEST"
fi

# Add an idempotent SessionStart auto-update hook to ~/.claude/settings.json
python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
cmd = 'git -C "$HOME/.claude/skills/goal-loop" pull --quiet --ff-only 2>/dev/null || true'
try:
    with open(p) as f:
        s = json.load(f)
    if not isinstance(s, dict):
        s = {}
except FileNotFoundError:
    s = {}
except Exception:
    print("  settings.json is not valid JSON — skipping hook; add it manually.")
    raise SystemExit(0)
ss = s.setdefault("hooks", {}).setdefault("SessionStart", [])
present = any(
    isinstance(g, dict) and any(
        isinstance(h, dict) and h.get("command") == cmd for h in g.get("hooks", [])
    )
    for g in ss
)
if present:
    print("Auto-update hook already present.")
else:
    ss.append({"hooks": [{"type": "command", "command": cmd}]})
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as f:
        json.dump(s, f, indent=2)
    print("Added SessionStart auto-update hook.")
PY

echo
echo "Done. goal-loop is installed at $DEST and will auto-update each session."
echo "It's active on your next prompt (or run /reload-skills now)."
