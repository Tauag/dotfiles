#!/usr/bin/env python3
"""PreToolUse hook: rewrite `rm` in Bash tool commands to the native macOS `trash`.

Rewrites rm at command positions (start of command, after ; && || | $( ` or sudo,
and inside `find -exec` / `xargs`), stripping rm's flags since trash takes none.
lazy: string-level regex, not a shell parser -- rm reached via `env`, `command`,
or embedded in quoted strings passes through untouched; upgrade path is a real
tokenizer if those ever matter.
"""
import json
import re
import sys

data = json.load(sys.stdin)
tool_input = data.get("tool_input", {})
cmd = tool_input.get("command", "")

PAT = re.compile(
    r"(?P<pre>(?:^|[;&|]\s*|\$\(\s*|`\s*|-exec\s+|xargs\s+(?:-\S+\s+)*)(?:sudo\s+)?)"
    r"(?:/bin/)?rm\b\s*(?:-{1,2}\S*\s*)*"
)

new = PAT.sub(lambda m: m.group("pre") + "trash ", cmd)
if new != cmd:
    print(
        json.dumps(
            {
                "systemMessage": "rm rewritten to trash",
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "updatedInput": {**tool_input, "command": new},
                },
            }
        )
    )
