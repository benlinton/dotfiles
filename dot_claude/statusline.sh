#!/usr/bin/env bash

data=$(cat)
session_id=$(echo "$data" | jq -r '.session_id // "default"')
total=$(echo "$data" | jq '(.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)')
prev_file="/tmp/.claude-statusline-prev-${session_id}"
cum_file="/tmp/.claude-statusline-cum-${session_id}"
prev=$(cat "$prev_file" 2>/dev/null || echo 0)
cum=$(cat "$cum_file" 2>/dev/null || echo 0)

# If total went down, it's a new context (after /clear) — use current total as delta
if [ "$total" -ge "$prev" ]; then
  delta=$((total - prev))
else
  delta=$total
fi

# Cache total and cumulative values
cum=$((cum + delta))
printf "%d" "$total" > "$prev_file"
printf "%d" "$cum" > "$cum_file"

# Print statusline
echo "$data" | jq -r --argjson delta "$delta" --argjson cum "$cum" '
def commas(n): n | tostring as $s | ($s | length) as $len | if $len <= 3 then $s elif $len <= 6 then $s[0:$len-3] + "," + $s[$len-3:] elif $len <= 9 then $s[0:$len-6] + "," + $s[$len-6:$len-3] + "," + $s[$len-3:] else $s end;
def rpt(s; n): [range(n) | s] | join("");
def bar(pct; width): (pct / 100 * width | round) as $filled | (width - $filled) as $empty | rpt("▓"; $filled) + rpt("░"; $empty);
def fmt(n): if n >= 1000 then (((n/1000*10)|round)/10|tostring)+"k" else (n|tostring) end;
(.context_window.remaining_percentage // 100) as $rem |
(100 - $rem) as $used_pct |
"" + (.model.display_name // "?") + " " + bar($used_pct; 6) + " " + ($used_pct | floor | tostring) + "% | " + "+" + commas($delta) + " tokens | " + fmt($cum) + " session"
'
