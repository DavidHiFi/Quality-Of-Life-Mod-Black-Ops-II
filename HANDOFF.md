# HANDOFF — Arena agent → Claude Code

**This file lives only on `arena/01a02afd-zm-qol`. It is never merged into `main`.**

It is a mailbox. The Arena agent (cloud sandbox, no access to the user's PC) writes
deliverables and intent here. Claude Code (the user's PC, full system access) reads it,
decides whether to apply, and does the parts that need a real machine.

---

## Roles — why this split exists

| | Arena agent | Claude Code |
|---|---|---|
| Runs on | Cloud sandbox, clone of this repo | The user's Windows 11 PC |
| Can do | Read/write repo files, web research, push to its own branch | Everything, plus `build.bat`, Plutonium, the game, real logs |
| Cost to user | Free | Pro 5-hour usage window |
| Cannot do | Touch the PC, run the game, run a build, see a crash log unless pasted | — |

**The point of the split: the Arena agent does the token-expensive work (reading 15,000-line
files, drafting, research) so Claude Code spends its window on execution and testing.**

---

## Protocol

### Claude Code — how to check the mailbox

```bash
git fetch origin arena/01a02afd-zm-qol
git show origin/arena/01a02afd-zm-qol:HANDOFF.md
```

Read the **Inbox** below. Each entry states what it is, why, and exactly what you should do.
If Inbox is empty, say so and stop — do not go looking for work.

### Rules for Claude Code

1. **Never `git merge` this branch into `main`.** It carries scaffolding (this file included)
   that must not reach `main`. Copy out the specific files an entry names, or cherry-pick a
   named commit. Nothing else.
2. **Never commit `HANDOFF.md` or `handoff/` to `main`.** They are branch-local by design.
   The repo is the mod's own source only — see `.gitignore`, the 2026-08-20 note.
3. **You are the reviewer, not a courier.** Arena cannot boot the game, so nothing here has
   been run. Treat every deliverable as untested. If an entry is wrong for reasons only
   visible on the real machine, say so and do not apply it.
4. **Verify before applying.** Anything touching `.gsc`/`.csc` gets a gsc-tool parse check.
   Anything touching the build gets a real `build.bat` run.
5. **Report back by pushing to `main`** with a normal commit message. Arena reads
   `origin/main`, so that is how it learns what happened.

### Arena agent — how to post

Add an entry to Inbox. Keep it short: Claude Code reading this file costs the user tokens,
so the manifest stays a manifest. Detail belongs in the delivered file, not here.

Entry format:

```
### [ID] Title
- **Files:** paths added/changed on this branch
- **Intent:** one or two lines on what problem it solves
- **Action for Claude:** the literal steps to take
- **Tested:** no — Arena cannot boot the game. What needs checking on the real machine.
- **Status:** PENDING | APPLIED | REJECTED
```

---

## Inbox

### [H-000] Protocol bootstrap — no deliverable
- **Files:** `HANDOFF.md`, `handoff/arena-sync.md`
- **Intent:** Establish the mailbox and the `/arena-sync` command. Nothing to apply to the
  mod itself.
- **Action for Claude:** None. If the user has not installed the slash command yet, offer to
  copy `handoff/arena-sync.md` to `~/.claude/commands/arena-sync.md` — **personal scope, not
  the repo**, so the repo stays mod-source-only.
- **Tested:** n/a
- **Status:** PENDING

---

## Outbox — questions for Claude Code / the user

Things Arena cannot determine from a clone and would otherwise guess at. Answers can come
back as a commit to `main` touching this file, or just pasted into the Arena chat.

1. Confirm the local repo path on the Windows machine, and whether it is the same clone that
   pushes to `origin`.
2. Does gsc-tool run from a fixed path on that machine? A pre-flight linter would want to
   shell out to it.
3. Are `CLAUDE.md` / `AI_CONTEXT.md` still at `Projects Sources\zm_qol - dev\`, and does the
   `AI_CONTEXT` rule numbering cited in ~20 GSC comments still match that file?
