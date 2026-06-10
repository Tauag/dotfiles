#!/bin/sh
# statusline for claude code - model and context usage only

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
max_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# context progress bar (10 blocks wide) + token count
if [ -n "$used_tokens" ] && [ -n "$max_tokens" ] && [ "$max_tokens" -gt 0 ]; then
	pct=$(awk "BEGIN {printf \"%.1f\", $used_tokens * 100 / $max_tokens}")
	filled=$(echo "$pct" | awk '{printf "%d", ($1 / 10 + 0.5)}')
	[ "$filled" -gt 10 ] && filled=10
	empty=$((10 - filled))
	bar=""
	i=0
	while [ $i -lt $filled ]; do
		bar="${bar}█"
		i=$((i + 1))
	done
	i=0
	while [ $i -lt $empty ]; do
		bar="${bar}░"
		i=$((i + 1))
	done
	used_fmt=$(echo "$used_tokens" | rev | sed 's/\([0-9]\{3\}\)/\1,/g' | rev | sed 's/^,//')
	max_fmt=$(echo "$max_tokens" | rev | sed 's/\([0-9]\{3\}\)/\1,/g' | rev | sed 's/^,//')
	ctx_bar=" ${pct}% [${bar}] ${used_fmt}/${max_fmt}"
	# yellow at 10%+, red at 30%+, gray otherwise
	level=$(echo "$pct" | awk '{print ($1 >= 30) ? 2 : (($1 >= 10) ? 1 : 0)}')
else
	ctx_bar=" [░░░░░░░░░░] …"
	level=0
fi

case "$level" in
	2) color='\033[31m' ;;
	1) color='\033[33m' ;;
	*) color='\033[90m' ;;
esac
reset='\033[0m'

printf "${color}%s%s${reset}\n" "$model" "$ctx_bar"
