#!/bin/sh
# statusline for claude code - model and context usage only

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# context progress bar (10 blocks wide)
if [ -n "$used" ]; then
	filled=$(echo "$used" | awk '{printf "%d", ($1 / 10 + 0.5)}')
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
	ctx_bar=" [${bar}] ${used}%"
	# red at 60%+, gray otherwise
	is_high=$(echo "$used" | awk '{print ($1 >= 60) ? 1 : 0}')
else
	ctx_bar=" [░░░░░░░░░░] …"
	is_high=0
fi

if [ "$is_high" = "1" ]; then
	color='\033[31m'
else
	color='\033[90m'
fi
reset='\033[0m'

printf "${color}%s%s${reset}\n" "$model" "$ctx_bar"
