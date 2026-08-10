---
name: clean-doc-stashes
description: Find stale documents that skills have stashed in ~/.claude (doc snapshots, handoff docs, plan files) and move them to the Trash. Use for "clean up my claude folder", "clean up old docs", "prune snapshots", "clear out old handoffs".
---

# Clean document stashes

Skills save working documents into `~/.claude` and nothing removes them. This skill prunes them with confirmation.

## Where to look

Known stash dirs (this list is self-maintained; see step 5):

- `~/.claude/doc-snapshots/` — before-copies saved for codify-doc-edits. Stale once the doc's codify pass happened or the doc is finalized.
- `~/.claude/handoff/` — session-handoff docs. Stale once the work they describe resumed or shipped.
- `~/.claude/plans/` — plan-mode files. Stale once executed.

Also scan for unknown stashes: any top-level `~/.claude` directory that contains document files (`.md`, `.txt`, `.html`) and isn't in the do-not-touch list. Grep `~/.claude/skills/*/SKILL.md` for the dir name to identify which skill writes there and what the files are for.

Do not touch anything else in `~/.claude`. Everything not listed above (projects, sessions, file-history, cache, paste-cache, backups, telemetry, settings, skills, agents, hooks, commands, plugins, todos, shell-snapshots, ide, logs, debug, tasks, downloads, session-env, session-crons, orchestrate-sessions, history.jsonl, *.json) is harness state, not a doc stash.

## Process

1. List every file in the stash dirs with age and size (`find <dirs> -type f -exec ls -lh {} +`).
2. Propose deletions: default candidates are files older than 30 days, plus anything the user names. Files from today are never candidates.
3. Show the list (path, age, size, one-line guess at what it was for) and ask which to delete. Never delete without this confirmation.
4. Move the confirmed set to the Trash — never `rm`: `trash <files...>` (native at `/usr/bin/trash`, handles name collisions and Finder put-back). Report count and space freed, and leave the stash directories in place (other skills expect them to exist).
5. If an unknown stash dir was found and the user confirmed it holds skill-generated documents, add it to the known list above with a one-line note on what writes there and when its files go stale. Edit this file directly; no approval needed beyond the confirmation in step 3.
