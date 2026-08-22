---
description: Check the Arena agent's handoff branch for new deliverables and report what is waiting. Read-only until the user approves.
argument-hint: [optional entry ID, e.g. H-001]
allowed-tools: Bash(git fetch:*), Bash(git show:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Read, Grep, Glob
disable-model-invocation: true
---

## Context

- Current branch: !`git branch --show-current`
- Working tree: !`git status --short`
- Handoff mailbox: !`git fetch origin arena/01a02afd-zm-qol --quiet 2>&1; git show origin/arena/01a02afd-zm-qol:HANDOFF.md 2>&1 || echo "NO HANDOFF FILE - branch missing or not yet pushed"`
- Files changed on the handoff branch vs main: !`git diff --stat origin/main...origin/arena/01a02afd-zm-qol 2>&1 | tail -40`

## Your task

The Arena agent is a second AI working on this project from a cloud sandbox. It has a clone of
this repo but **no access to this machine** — it cannot boot Black Ops II, run `build.bat`, or
see a crash log. It leaves work on the branch `arena/01a02afd-zm-qol` and describes it in
`HANDOFF.md` above.

Argument (may be empty): $ARGUMENTS — if an entry ID is given, deal with that entry only.

**Do this:**

1. Read the Inbox in the handoff file above. If every entry is `APPLIED`/`REJECTED`, or the
   Inbox is empty, say "nothing waiting" and stop. Do not invent work.
2. For each `PENDING` entry, summarise in plain language: what it is, which files, what
   problem it claims to solve, and what applying it would change here.
3. **Review it critically before recommending anything.** It is untested by construction.
   Check specifically for this project's known failure classes:
   - asset/font/material/model names that read fine but resolve to nothing
     (the `hudsmall` → `small` class)
   - functions that are not real T6 builtins (the `array_slice` class)
   - dvars read but never registered (the `zmqol_minimal` class)
   - `maps\mp\zm_*::` map-scoped externals referenced from a root script that loads on every
     map — AI_CONTEXT rule 2, this crashes the other maps at load
   - new clientfields on maps already tight on network space (Origins, TranZit)
   - new HUD elements against the finite per-client allowance
4. Give the user a clear recommendation: apply, apply-with-changes, or reject and why.
5. **Do not modify any file until the user says go.**

**When applying, once approved:**

- Copy out only the files the entry names. **Never merge this branch into `main`** — it carries
  mailbox scaffolding (`HANDOFF.md`, `handoff/`) that must not reach `main`.
- Never commit `HANDOFF.md` or `handoff/` to `main`.
- Parse-check any `.gsc`/`.csc` with gsc-tool. Run `build.bat` if the build is affected.
- Commit to `main` in the project's normal style. That push is how the Arena agent finds out
  what happened — it reads `origin/main`.
- Tell the user what still needs a real in-game boot to confirm.

Also check the **Outbox** section for questions the Arena agent has asked. Answer any you can
determine from this machine, and surface the rest to the user.
