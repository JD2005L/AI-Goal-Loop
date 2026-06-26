---
name: goal-loop
description: >-
  This skill should be used when the user gives a rough feature request and wants it built in ONE
  operation, not handed prompts to run themselves. Invoked as `/goal-loop <feature>`, it (1) assesses
  the request and derives explicit, checkable acceptance criteria grounded in the repo's real
  build/test/lint commands and existing patterns; (2) decomposes the goal into an ordered,
  dependency-aware plan; (3) presents the end state, criteria, and plan for a single confirmation;
  then (4) RUNS a bounded implement-and-verify loop — one focused change per iteration, each finished
  criterion checked by an INDEPENDENT skeptical verifier, with stuck-detection that changes approach
  or escalates — until all criteria independently pass, or it stops and summarizes blockers. Resumable
  via an implementation log. Non-destructive; stays in scope; no unrelated redesigns.
---

# Goal-Loop — build a feature by looping to its acceptance criteria

`/goal-loop <feature request>` is **one operation that runs**, like running a single command. It does not hand back a prompt to paste. The flow is **Assess → Plan → Confirm (once) → Run the loop**, where the loop has independent verification and stuck-detection built in.

The acceptance criteria are the loop's measure: the loop is *done* exactly when every criterion is **independently verified** to pass and verification is green.

## Inputs

The rough feature request is whatever the user passed as arguments:

> $ARGUMENTS

If it's empty, ask what to build. If it's too vague to write measurable criteria (you can't tell where it lives or what "done" looks like), ask **one or two** focused clarifying questions, then continue. Don't over-question — prefer sensible defaults from existing patterns and record them as assumptions.

## Step 1 — Assess (read-only)

Do a quick **read-only** pass — this is research, not the implementation:

- **Verification commands.** Find the real build, test, and lint/format commands (`CLAUDE.md`, `README`, `package.json` scripts, `*.csproj`/`*.sln`, `Makefile`, `pyproject.toml`, CI configs, lint configs). Record the exact commands. If **no tests cover this area**, the measure is build/lint **plus a concrete manual test plan** — do not invent a fake suite.
- **Reusable patterns.** Identify the specific existing components, helpers, icons, styles, conventions, and test patterns this feature should reuse. Name them concretely (file/class/component names).
- **Acceptance criteria.** Turn the request into explicit pass/fail criteria, grouped under: **User-visible behavior · State handling · Error/edge cases · Tests/build/lint · Accessibility** (if UI; else mark N/A) **· Non-regression**. Each criterion must be checkable from observable behavior or command output, not a vague goal.
- **UX assumptions.** Where the request leaves UX or implementation open, choose defaults from existing patterns and record each assumption explicitly.

## Step 2 — Plan (decompose before looping)

Turn the acceptance criteria into an **ordered, dependency-aware list of small increments** — the path to the end state, sequenced so each step builds on the last (foundational/blocking work first, edge-cases and polish later). Map each increment to the criterion/criteria it advances. This plan is what the loop walks; record it in the implementation log so it survives interruption. Re-order or extend it as you learn — but don't abandon it for ad-hoc wandering.

## Step 3 — Confirm once, then run

Post a single, concise plan:

- the feature restated as a **measurable end state**;
- the **acceptance criteria** (the loop's measure);
- the **ordered increment plan** (Step 2);
- the **verification commands** you'll run each pass (and the manual test plan if no tests cover the area);
- the **existing patterns** you'll reuse and any **UX assumptions**;
- the **bounded stop** (criteria met → done; otherwise stop after ~12 iterations or when genuinely blocked, and summarize);
- the **non-destructive / in-scope** guarantees.

Then ask the user to **confirm or adjust**. Skip this confirmation only if the invocation already says to just run it (e.g. "no confirm", "just do it", "go"). Once confirmed, start the loop in this same session — do **not** ask the user to paste anything.

## Step 4 — Run the loop

Open (or resume) an implementation log at `.claude/goal-loops/<slug>.md` (`<slug>` = a short kebab name for the feature). This log is the resumable state — it holds the increment plan, each criterion's status, and per-criterion attempt counts; it survives context compaction and new sessions.

Then iterate. **Each iteration:**

1. **Pick** the next increment from the plan (or the highest-priority unmet criterion).
2. **Change** — make one focused change to advance it. Reuse the named existing patterns. No speculative changes, no unrelated refactors or redesigns.
3. **Verify (real signal)** — run the verification commands and show their output in the transcript.
4. **Verify (independent + adversarial)** — when a criterion now looks satisfied, prove it **skeptically** before marking it PASS: judge it from the evidence (diff + command output) with a *try-to-disprove-it* mindset, defaulting to FAIL if it isn't clearly demonstrated. For any non-trivial criterion, run this check as a **separate subagent** (Agent tool, e.g. `general-purpose`) given only the criterion plus the evidence and asked to refute it — so the implementer isn't grading its own work. Then re-mark **every** criterion PASS/FAIL with the evidence that justifies it.
5. **Stuck-detection** — record the attempt and outcome per criterion in the log. If the same criterion fails **~2 times with no real progress**, stop repeating the same fix: diagnose the root cause and **change approach** (different file/strategy/assumption). If the changed approach still fails, **stop and escalate to the user** with the specific blocker — don't keep cycling.
6. **Log** — append a dated entry: the increment, the one change made, both verification results, criterion statuses, the attempt count, and the next step.

Surface evidence as you go — the transcript is the proof; an unshown check didn't happen.

### Stop conditions (bounded — never an indefinite loop)

- **Done:** every acceptance criterion is **independently verified** PASS and verification is green. Run a final independent verification sweep across **all** criteria before declaring done; then stop changing code and post the final summary.
- **Bounded stop:** if blocked, still stuck after a changed approach, or after ~12 iterations without convergence — stop and summarize the blockers, what's PASS vs FAIL, and what remains. Don't keep grinding speculatively.

Once done, make **no further edits** — don't gold-plate.

### Final summary (the built-in verification)

When the loop ends, post: what changed, the list of files changed, the verification commands run with pass/fail output, each acceptance criterion marked PASS/FAIL (noting it was independently verified), and any remaining risks or unverified behavior.

## Resuming

If `/goal-loop` is run again for the same feature (or after an interruption), read `.claude/goal-loops/<slug>.md` first (plan, criterion statuses, attempt counts), re-confirm the criteria, and continue from the last logged state instead of restarting.

## Global constraints (always)

- **Non-destructive git only** — no `reset --hard`, force-push, history rewrite, branch deletion, or deleting files you didn't create. Stage only files you changed.
- **Stay in scope** — touch only what this feature needs; no unrelated areas.
- **Prefer existing project patterns**, components, icons, tests, and style conventions — cite them by name.
- **No tests for the area → build/lint + a clear manual test plan**, not an invented suite.
- **Document UX assumptions explicitly.**
- **Independent verification before "done"** — a criterion only counts as PASS once it's been checked skeptically by something other than the change that produced it (a separate subagent for non-trivial ones).
- **Stuck-detection over repetition** — change approach or escalate rather than re-trying the same failing fix.
- **Bounded, not indefinite** — the loop always has the stop conditions above.
- This skill **runs** the work after confirmation; it does not just emit prompts for the user to run.
