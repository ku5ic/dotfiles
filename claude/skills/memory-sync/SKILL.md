---
name: memory-sync
description: Sync ~/claude-memory with GitHub, import machine-local memories, merge duplicates, settle contradictions, and file each memory in its project folder. Use when the user types /memory-sync.
disable-model-invocation: true
---

`~/claude-memory/general/memory-layout.md` says where a memory goes. Read it first. This skill never changes a memory's meaning without the user's answer.

## 1. Preconditions

- No `~/claude-memory`: clone it with `git clone git@github.com:ku5ic/claude-memory.git ~/claude-memory`.
- `~/claude-memory` without `.git`: confirm, then rename it to `~/claude-memory.local`, clone, and treat the renamed folder as one more import source in step 3.
- Stop and show it when a rebase or merge is in progress, or there are unmerged paths or a stash entry.

## 2. Pull

1. `git -C ~/claude-memory add -A`. Unstaged new files make the pull abort when the remote has the same path.
2. `git -C ~/claude-memory pull --rebase --autostash`. It exits 0 even when the stash conflicts, so check `git -C ~/claude-memory status --short` for unmerged paths.
3. Settle each conflict by reading both sides. Both facts kept in one file when they agree, step 5 when they don't. When one side deleted the file, its fact was merged elsewhere, so find that file and add what the edited side says. The stash stays until step 8.

## 3. Import

Sources: every `memory/` under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/`, and `~/claude-memory.local`.

- A source's project is the git top level of the `cwd` in its transcripts. The folder name is ambiguous, since `-` in it can be `/`, `.`, or `-`. With no transcript, propose a name and ask.
- A fact already in `~/claude-memory` isn't imported again. Import what the source adds.
- Never overwrite a file. The same slug with a different fact gets a new slug.

## 4. File and merge

- A memory at the root, or in the wrong folder, moves to the right one. Its `originSessionId` names a transcript, `<id>.jsonl`, whose `cwd` is the project. With no transcript and no project named in the text, ask.
- Two memories with one fact become one. Keep the newest wording, the earlier dates, and every reason. Fix `[[links]]` to the dropped slug.
- A fact that only names one project moves out of `general/`. A fact saved in two projects moves into it.

## 5. Contradictions

Two memories that can't both be followed, or one the user's `~/.claude/CLAUDE.md` contradicts.

Ask with AskUserQuestion, both statements quoted with their dates, the newest first as recommended. Four per call. Edit the kept one to say what changed, and delete the other.

## 6. Index

One line per memory in the root `MEMORY.md`. A project's line starts its hook with the project name. Then run `claude_memory_check.sh` until it prints nothing.

## 7. Review

1. `gitleaks dir ~/claude-memory --no-banner --redact`. A finding stops the run.
2. `git -C ~/claude-memory add -A`, then show `git -C ~/claude-memory diff --cached --stat`, and one line for each merge, move, deletion, and settled contradiction.
3. Ask whether to commit, and list in the same question every source file step 9 deletes after the push. Mark the ones whose fact is in no memory, such as the losing side of a contradiction, since that is their last copy. Memories from work projects go to this repo too, so name any that hold credentials, customers, or unreleased work.

With nothing staged, skip the commit. Unpushed commits still get step 8, and leftover source files still get step 9 after a yes. With none of the three, say so and stop.

## 8. Commit and push

After a yes, one Bash call each:

1. `git -C ~/claude-memory commit -m "chore(memory): sync <hostname>"`. It's signed, so wait for the approval prompt.
2. The kit blocks Claude from pushing to `main`, so end the turn by asking the user to type `! git -C ~/claude-memory push`. Go on once `git -C ~/claude-memory status -sb` no longer says `ahead`. If the push is rejected, go back to the pull. A conflict there is a rebase conflict, settled the same way, then `git -C ~/claude-memory rebase --continue`.
3. `git -C ~/claude-memory stash drop`, only when step 2 left an autostash and the push landed.

## 9. Clean up

`~/claude-memory` is the single source of truth, so no copy stays outside it. Only after the push landed:

1. Compare each source file with the memory it went to. Skip, and report, one that changed since step 3 or whose last copy the user didn't approve deleting.
2. `rm` the rest by name in one Bash call, each source's `MEMORY.md` included. The kit blocks `find -delete`.
3. List what is left under the sources. Anything but the skipped files is a failure to report.

## Output

Counts of imported, merged, moved, and deleted memories, contradictions settled, and old copies deleted, plus the pushed commit and any skipped file. Nothing else.
