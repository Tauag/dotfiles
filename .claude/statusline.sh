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

# orchestration mode badge (marker file touched by the /orchestrate skill)
if [ -n "$session_id" ] && [ -f "$HOME/.claude/orchestrate-sessions/$session_id" ]; then
	orch='\033[35m⛭ Orchestrator\033[0m'
else
	orch='\033[90m⛭ Executor\033[0m'
fi
# fast mode badge (toggled with /fast)
if [ "$(echo "$input" | jq -r '.fast_mode // false')" = "true" ]; then
	fast='\033[32m⚡ Fast on\033[0m'
else
	fast='\033[90m⚡ Fast off\033[0m'
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
	# green under 30%, yellow at 30%+, red at 50%+
	pct=$(awk "BEGIN {printf \"%.1f\", $used_tokens * 100 / $max_tokens}")
	level=$(echo "$pct" | awk '{print ($1 >= 50) ? 2 : (($1 >= 30) ? 1 : 0)}')
else
	ctx_bar="…"
	level=-1
fi

case "$level" in
	2) color='\033[31m' ;;
	1) color='\033[33m' ;;
	0) color='\033[32m' ;;
	*) color='\033[90m' ;;  # context size unknown
esac
reset='\033[0m'
sep=' \033[90m·\033[0m '

# pending scheduled jobs (Stop hook mirrors session_crons into this file) — CronCreate /
# ScheduleWakeup / /loop only fire while this session stays open, so this is the
# "leave the terminal running" signal. Absent when nothing is scheduled.
jobs=$(cat "$HOME/.claude/session-crons/$session_id" 2>/dev/null)
if [ -n "$jobs" ]; then
	set -- $jobs
	n=$1; shift; sched="$*"
	[ "$n" = "1" ] && label='1 job' || label="$n jobs"
	case "$sched" in
		[0-9]*\ [0-9]*) label="$label @ $(echo "$sched" | awk '{printf "%d:%02d", $2, $1}')" ;;
	esac
	jobs_badge="${sep}\033[33m⏰ ${label}\033[0m"
else
	jobs_badge=''
fi

if [ -n "$branch" ]; then
	printf "${orch}${jobs_badge}${sep}${fast}${sep}${color}%s %s${reset}${sep}\033[90m⎇ %s${reset}\n" "$model" "$ctx_bar" "$branch"
else
	printf "${orch}${jobs_badge}${sep}${fast}${sep}${color}%s %s${reset}\n" "$model" "$ctx_bar"
fi
