# claude-goal-loop

A Claude Code skill. `/goal-loop <feature request>` turns a rough idea into **one self-running,
bounded implement-and-verify loop** — it doesn't hand you prompts to run.

Flow: **Assess** (read-only: find the repo's real build/test/lint + reusable patterns, derive
explicit acceptance criteria) → **Plan** (decompose into ordered, dependency-aware increments) →
**Confirm once** → **Run the loop** (one focused change per iteration; each finished criterion
checked by an *independent, skeptical* verifier; stuck-detection that changes approach or escalates)
until every criterion is independently verified and verification is green, or it stops and
summarizes blockers. Non-destructive; stays in scope; resumable via an implementation log.

## Install (recommended — auto-updates)

```bash
curl -fsSL https://raw.githubusercontent.com/JD2005L/claude-goal-loop/main/install.sh | bash
```

This clones the skill to `~/.claude/skills/goal-loop` and adds a Claude Code `SessionStart` hook
that `git pull`s the latest on every session — so future updates arrive automatically with no
re-install. Active on your next prompt (or run `/reload-skills`). Safe to re-run; it replaces a
prior static (non-git) copy.

## Manual install (no auto-update)

```bash
mkdir -p ~/.claude/skills/goal-loop
curl -fsSL https://raw.githubusercontent.com/JD2005L/claude-goal-loop/main/SKILL.md \
  -o ~/.claude/skills/goal-loop/SKILL.md
```

## Updating the skill (maintainer)

Edit `SKILL.md`, then commit and push. Every client that installed with the auto-update hook
picks up the change on its next session start — no action needed on their end.

## Notes

- Updates are **pull-based**: clients fetch on session start. There is no force-push to live
  installs (Claude Code has no such mechanism).
- The repo is public so clients clone/pull without credentials. The skill contains no secrets.
- Requires `git` and `python3` on the client (used by `install.sh`).
