---
name: codify-doc-edits
description: Diff the user's manual edits to a generated document against the original version and turn recurring patterns into updates to the document-writing rules in ~/.claude/CLAUDE.md. Use for "codify my edits", "review what I changed and update the rules", "turn my edits into rules", or after the user says they hand-edited a generated doc and wants the lessons captured.
---

# Codify document edits

The rules live in `~/.claude/CLAUDE.md` under "Writing style" (the numbered document rules). This skill proposes changes to that list and applies them after approval.

1. Get both versions. Before: the copy in `~/.claude/doc-snapshots/`; if none exists, extract the last generated version from the session transcript (`~/.claude/projects/<project>/<session>.jsonl` — find the last Write or Notion replace_content call for the doc), or ask the user for it. After: the current doc.
2. Diff. Categorize each change: deletion, compression, rewording, or design/scope cut.
3. Draft a candidate rule for each pattern with 2+ instances. Check it against the existing rules first; amend a close match rather than adding a new rule. Design/scope cuts don't become rules — they're one-doc decisions unless the user says otherwise.
4. A rule must hold for any document type, not just the one being diffed. If it only works for one genre (system designs, runbooks, proposals), generalize the wording or drop it.
5. Propose additions and amendments in conversation with one before/after example each. Edit CLAUDE.md only after the user approves.
6. New rules must read like the existing ones: one line, plain words.

Past before-versions live in `~/.claude/doc-snapshots/` for reference.
