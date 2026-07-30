#!/bin/sh
# statusline for claude code - model and context usage only

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
[ -n "$effort" ] && model="$model ($effort)"

# git branch (+ ⧉ when in a linked worktree)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
branch=$(git -C "$dir" branch --show-current 2>/dev/null)
[ -z "$branch" ] && branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)  # detached HEAD
if [ -n "$branch" ] && [ "$(git -C "$dir" rev-parse --git-dir 2>/dev/null)" != "$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null)" ]; then
	branch="$branch ⧉"
fi
session_id=$(echo "$input" | jq -r '.session_id // empty')

# activity indicator (state file written by UserPromptSubmit/PostToolUse/Notification/Stop hooks)
state=$(cat "$HOME/.claude/session-state/$session_id" 2>/dev/null)
case "$state" in
	generating) act='\033[36mGenerating\033[0m' ;;   # can't take input
	waiting)    act='\033[33mWaiting\033[0m' ;;      # blocked on your input (permission/question)
	*)          act='\033[32mReady\033[0m' ;;        # ready to prompt
esac

# orchestration mode badge (marker file touched by the /orchestrate skill)
if [ -n "$session_id" ] && [ -f "$HOME/.claude/orchestrate-sessions/$session_id" ]; then
	orch='\033[35m⛭ Orchestrator\033[0m'
else
	orch='\033[90m⛭ Executor\033[0m'
fi
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
max_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# token count, abbreviated (42K/1M)
fmt_tokens() {
	awk -v n="$1" 'BEGIN {
		if (n >= 999500) printf "%.1fM", n / 1000000
		else if (n >= 1000) printf "%.0fK", n / 1000
		else printf "%d", n
	}' | sed 's/\.0M/M/'
}
if [ -n "$used_tokens" ] && [ -n "$max_tokens" ] && [ "$max_tokens" -gt 0 ]; then
	ctx_bar="$(fmt_tokens "$used_tokens")/$(fmt_tokens "$max_tokens")"
	# yellow at 10%+, red at 30%+, gray otherwise
	pct=$(awk "BEGIN {printf \"%.1f\", $used_tokens * 100 / $max_tokens}")
	level=$(echo "$pct" | awk '{print ($1 >= 30) ? 2 : (($1 >= 10) ? 1 : 0)}')
else
	ctx_bar="…"
	level=0
fi

case "$level" in
	2) color='\033[31m' ;;
	1) color='\033[33m' ;;
	*) color='\033[90m' ;;
esac
reset='\033[0m'
sep=' \033[90m·\033[0m '

if [ -n "$branch" ]; then
	printf "${act}${sep}${orch}${sep}${color}%s %s${reset}${sep}\033[90m⎇ %s${reset}\n" "$model" "$ctx_bar" "$branch"
else
	printf "${act}${sep}${orch}${sep}${color}%s %s${reset}\n" "$model" "$ctx_bar"
fi
