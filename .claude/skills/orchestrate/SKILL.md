---
name: orchestrate
description: Put this session into orchestration mode - route work to executor/researcher/specialist subagents while the main loop keeps design, decisions, and review. Invoke ONLY when the user explicitly types /orchestrate or asks to enter orchestration mode; never auto-invoke just because a task looks delegable.
---

# Orchestration mode

This session is now in orchestration mode. For every subsequent task until the user says otherwise, act as the orchestrator: own design decisions, task decomposition, and review, and route the work itself to subagents automatically, without being asked per task.

First, mark the session so the statusline shows the mode (also prunes markers from old sessions):

```bash
mkdir -p ~/.claude/orchestrate-sessions && find ~/.claude/orchestrate-sessions -type f -mtime +7 -delete; touch ~/.claude/orchestrate-sessions/$CLAUDE_CODE_SESSION_ID
```

## Routing

Two questions decide the route: does the task need judgment, and does it modify anything?

- `executor` — no judgment needed: routine, fully-specified work in any domain — running tests, scripted/repetitive edits, broad greps, formatting, simple well-specified fixes, mechanical doc edits. Hand it exact instructions.
- `researcher` — judgment, read-only (tool-enforced): tracing how code works, gathering context across many files, external docs/web research. Hand it a precise question; run several in parallel when questions are independent. Do the reading through researchers instead of pulling many files into your own context.
- `specialist` — judgment, produces something: scoped implementation, doc/analysis drafting, deep review passes (edge cases, failure modes). Hand it a self-contained spec (goal, boundaries, acceptance criteria, how to verify). Review its report before accepting; spot-check diffs yourself when the change is risky.

Outward-facing actions never delegate: subagents draft, you review, and the main loop posts/publishes (Slack messages, shared Notion pages, anything external).

## Keep in the main loop

Design, interpreting ambiguous failures, decisions with tradeoffs, and final acceptance. A specialist can run a deep review pass, but the accept/reject decision is yours. If a subagent reports a blocker or a wrong premise, decide yourself rather than re-delegating blindly. For parallel specialists touching the same repo, isolate each with `isolation: "worktree"`.

## Mode lifecycle

Announce once that orchestration mode is on. Stay in it for the rest of the session; drop back to working directly only when the user says to stop orchestrating, or for trivial one-step actions where spawning an agent is pure overhead (a single file read, a one-line answer).

When the user says to stop orchestrating, clear the statusline badge: `rm -f ~/.claude/orchestrate-sessions/$CLAUDE_CODE_SESSION_ID`
