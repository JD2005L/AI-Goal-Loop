#!/usr/bin/env bash
# goal-loop skill — install or update for Claude Code and/or GitHub Copilot CLI, with auto-sync.
#
# Detects which CLIs are present and clones the skill into each one's
# `skills/goal-loop` directory, then registers a session-start hook that
# `git pull`s the latest on every session — so future updates arrive
# automatically with no re-install. Safe to re-run; replaces a prior
# non-git (static) install.
#
# Honors CLAUDE_CONFIG_DIR and COPILOT_HOME if you've relocated either CLI's home.
# Force a target even if its dir is absent: INSTALL_CLAUDE=1 / INSTALL_COPILOT=1.
set -euo pipefail

REPO="https://github.com/JD2005L/claude-goal-loop.git"

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
COPILOT_HOME_DIR="${COPILOT_HOME:-$HOME/.copilot}"

installed_any=0

clone_or_update() {
  # $1 = destination skill directory
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  if [ -d "$dest/.git" ]; then
    echo "Updating existing goal-loop clone at $dest ..."
    git -C "$dest" pull --quiet --ff-only || echo "  (pull skipped — local changes or offline)"
  else
    if [ -e "$dest" ]; then
      echo "Replacing prior (non-git) goal-loop install at $dest ..."
      rm -rf "$dest"
    fi
    echo "Cloning goal-loop to $dest ..."
    git clone --quiet "$REPO" "$dest"
  fi
}

# ---------------------------------------------------------------------------
# Claude Code  (~/.claude)
# ---------------------------------------------------------------------------
if [ -d "$CLAUDE_HOME" ] || [ "${INSTALL_CLAUDE:-0}" = "1" ]; then
  clone_or_update "$CLAUDE_HOME/skills/goal-loop"

  # Idempotent SessionStart auto-update hook in <claude-home>/settings.json.
  # Needs python3 (or python). If neither is present we still install the skill,
  # just without the auto-update hook — and we never abort the Copilot path below.
  PY_BIN=""
  for _cand in python3 python; do
    if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'import json, os' >/dev/null 2>&1; then
      PY_BIN="$_cand"; break
    fi
  done
  if [ -n "$PY_BIN" ]; then
    CLAUDE_HOME="$CLAUDE_HOME" "$PY_BIN" - <<'PY'
import json, os
home = os.environ["CLAUDE_HOME"]
p = os.path.join(home, "settings.json")
cmd = 'git -C "%s/skills/goal-loop" pull --quiet --ff-only 2>/dev/null || true' % home
try:
    with open(p) as f:
        s = json.load(f)
    if not isinstance(s, dict):
        s = {}
except FileNotFoundError:
    s = {}
except Exception:
    print("  settings.json is not valid JSON — skipping Claude hook; add it manually.")
    raise SystemExit(0)
ss = s.setdefault("hooks", {}).setdefault("SessionStart", [])
present = any(
    isinstance(g, dict) and any(
        isinstance(h, dict) and h.get("command") == cmd for h in g.get("hooks", [])
    )
    for g in ss
)
if present:
    print("Claude auto-update hook already present.")
else:
    ss.append({"hooks": [{"type": "command", "command": cmd}]})
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as f:
        json.dump(s, f, indent=2)
    print("Added Claude SessionStart auto-update hook.")
PY
  else
    echo "  python3/python not found — installed the Claude skill but skipped the auto-update hook."
    echo "  Add a SessionStart hook to $CLAUDE_HOME/settings.json manually to enable auto-update."
  fi
  installed_any=1
fi

# ---------------------------------------------------------------------------
# GitHub Copilot CLI  (~/.copilot)
# ---------------------------------------------------------------------------
if [ -d "$COPILOT_HOME_DIR" ] || [ "${INSTALL_COPILOT:-0}" = "1" ]; then
  clone_or_update "$COPILOT_HOME_DIR/skills/goal-loop"

  # sessionStart auto-update hook in <copilot-home>/hooks/goal-loop-update.json.
  # Resolves the skill dir at runtime so it honors COPILOT_HOME; includes both a
  # bash key (Linux/macOS) and a powershell key (Windows, needs PowerShell 7+).
  mkdir -p "$COPILOT_HOME_DIR/hooks"
  cat > "$COPILOT_HOME_DIR/hooks/goal-loop-update.json" <<'JSON'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "git -C \"${COPILOT_HOME:-$HOME/.copilot}/skills/goal-loop\" pull --quiet --ff-only 2>/dev/null || true",
        "powershell": "$h = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { \"$env:USERPROFILE\\.copilot\" }; git -C \"$h\\skills\\goal-loop\" pull --quiet --ff-only 2>$null; exit 0",
        "timeoutSec": 30
      }
    ]
  }
}
JSON
  echo "Added Copilot sessionStart auto-update hook at $COPILOT_HOME_DIR/hooks/goal-loop-update.json"
  installed_any=1
fi

if [ "$installed_any" = "0" ]; then
  echo "No Claude Code (~/.claude) or Copilot CLI (~/.copilot) install detected."
  echo "Force one or both and re-run, e.g.:"
  echo "  INSTALL_CLAUDE=1 INSTALL_COPILOT=1 \\"
  echo "    bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/JD2005L/claude-goal-loop/main/install.sh)\""
  exit 1
fi

echo
echo "Done. goal-loop is installed and will auto-update each session."
echo "  Claude Code:  active on your next prompt (or run /reload-skills)."
echo "  Copilot CLI:  run /skills reload, then /skills info goal-loop to confirm."
