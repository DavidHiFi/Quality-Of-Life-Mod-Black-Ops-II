# `.agents/` — session checkpoints for zm_qol

Checkpoints live here as `checkpoint_N.md`, next sequential number.

**Read the newest one at the start of every session.** If this folder holds nothing but this README,
the last session closed cleanly — start from `../CLAUDE.md` and `../AI_CONTEXT.md` instead. That is
the healthy state.

See `../CLAUDE.md` §5 for why this project's checkpoint discipline is git-less: no commit hashes to
anchor state to, so be explicit about file + function names instead.

A checkpoint has one job: bridge an interrupted or context-limited session — "here is where I was,
here is what not to try again and why, here is the next concrete step." Write one when a session is
interrupted mid-task. Don't write one as a routine end-of-session ritual.

When a checkpoint's task is resolved: fold anything durable into `../CLAUDE.md` or `../AI_CONTEXT.md`,
then delete the checkpoint. Don't keep resolved checkpoints "just in case."

---

## Template

```markdown
# Checkpoint N — <one-line headline of where things stand>

**Supersedes N-1 for live state.** <what the older one is still the record of, if anything>

**Written <date>.** <deployed?>, <tested in-game?>

---

## 1. STATE

What's built, what's copied to the Plutonium mods folder, what's actually been launched and tested.

---

## 2. WHAT'S DONE

<what was accomplished, which file(s)/function(s) touched>

---

## 3. 🛑 WHAT NOT TO TRY AGAIN

<each dead end, WITH the reason it's dead — this is the section that pays>

<if this checkpoint invalidates earlier guidance, say so loudly:
"🛑 CHECKPOINT X IS NOW KNOWN WRONG — <why>. Do not follow it.">

---

## 4. ⏳ TEST BACKLOG

<everything built/deployed but unverified in-game, riskiest first>

---

## 5. NEXT, in order

1. <specific and actionable — "launch the Mods menu and buy Mule Kick on zm_tomb", not "keep testing">
2.
3.
```
