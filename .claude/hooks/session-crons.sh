#!/bin/sh
# Stop hook: mirror this session's pending scheduled jobs (CronCreate, ScheduleWakeup,
# /loop) into a marker file the statusline reads. They only fire while the session is
# open, so the badge is the "don't close this terminal yet" signal.
#
# lazy: refreshed only on Stop, so cancelling a pending wakeup with Esc leaves the badge
# up until the next turn ends. Upgrade path: no other hook event carries session_crons.
dir="$HOME/.claude/session-crons"
jq -r '[(.session_id // ""),
        ((.session_crons // []) | length),
        ((.session_crons // []) | map(select(.recurring == false) | .schedule) | first // "")
       ] | @tsv' | {
	read -r sid n sched || exit 0
	[ -n "$sid" ] || exit 0
	mkdir -p "$dir"
	if [ "${n:-0}" -eq 0 ]; then
		rm -f "$dir/$sid"
	else
		printf '%s %s\n' "$n" "$sched" > "$dir/$sid"
	fi
}
