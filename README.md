# claude-goal-loop

A self-running **goal-loop** agent skill for **Claude Code** and **GitHub Copilot CLI**.
`/goal-loop <feature request>` turns a rough idea into **one self-running, bounded
implement-and-verify loop** — it doesn't hand you prompts to run.

Flow: **Assess** (read-only: find the repo's real build/test/lint + reusable patterns, derive
explicit acceptance criteria) → **Plan** (decompose into ordered, dependency-aware increments) →
**Confirm once** → **Run the loop** (one focused change per iteration; each finished criterion
checked by an *independent, skeptical* verifier; stuck-detection that changes approach or escalates)
until every criterion is independently verified and verification is green, or it stops and
summarizes blockers. Non-destructive; stays in scope; resumable via an implementation log.

It's a single skill built on the open [Agent Skills](https://github.com/agentskills/agentskills)
standard, so the same `SKILL.md` works in any agent that supports it — Claude Code, GitHub
Copilot CLI, and more.

## Install (recommended — auto-updates)

```bash
curl -fsSL https://raw.githubusercontent.com/JD2005L/claude-goal-loop/main/install.sh | bash
```

The installer detects which CLIs you have and installs into each:

- **Claude Code** → `~/.claude/skills/goal-loop`, plus a `SessionStart` hook in
  `~/.claude/settings.json` that `git pull`s on every session.
- **GitHub Copilot CLI** → `~/.copilot/skills/goal-loop`, plus a `sessionStart` hook in
  `~/.copilot/hooks/goal-loop-update.json` that does the same.

Either way, future updates arrive automatically with no re-install. Safe to re-run; it replaces a
prior static (non-git) copy. If neither CLI is detected, force one or both:

```bash
INSTALL_CLAUDE=1 INSTALL_COPILOT=1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/JD2005L/claude-goal-loop/main/install.sh)"
```

Then activate it:

- **Claude Code:** active on your next prompt (or run `/reload-skills`).
- **Copilot CLI:** run `/skills reload`, then `/skills info goal-loop` to confirm.

## Manual install (no auto-update)

**Claude Code:**

```bash
mkdir -p ~/.claude/skills/goal-loop
curl -fsSL https://raw.githubusercontent.com/JD2005L/claude-goal-loop/main/SKILL.md \
  -o ~/.claude/skills/goal-loop/SKILL.md
```

**GitHub Copilot CLI:**

```bash
mkdir -p ~/.copilot/skills/goal-loop
curl -fsSL https://raw.githubusercontent.com/JD2005L/claude-goal-loop/main/SKILL.md \
  -o ~/.copilot/skills/goal-loop/SKILL.md
```

## Using it

Invoke the skill the same way in both CLIs:

```
/goal-loop add a dark-mode toggle to the settings page
```

In Copilot CLI you can also just mention it in a sentence, e.g.
`Use the /goal-loop skill to add a dark-mode toggle.`

## Updating the skill (maintainer)

Edit `SKILL.md`, then commit and push. Every client that installed with the auto-update hook
picks up the change on its next session start — no action needed on their end.

## Notes

- Updates are **pull-based**: clients fetch on session start. There is no force-push to live
  installs.
- The repo is public so clients clone/pull without credentials. The skill contains no secrets.
- `install.sh` requires `git`. The Claude Code auto-update hook also uses `python3` (or `python`)
  to edit `settings.json`; if neither is present the skill still installs, just without that hook.
  The Copilot CLI hook is plain JSON and needs no extra tooling.
- On Windows, the Copilot CLI auto-update hook runs via PowerShell and needs PowerShell 7+
  (`pwsh`) on your PATH; otherwise run `install.sh` from WSL or Git Bash, or update manually.
- The installer honors `CLAUDE_CONFIG_DIR` and `COPILOT_HOME` if you've relocated either CLI's
  home directory.
