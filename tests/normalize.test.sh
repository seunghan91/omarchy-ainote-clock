#!/bin/bash
# Date classification for bin/task-normalize.jq — formats observed from the ainote API.
set -u
cd "$(dirname "$0")/.." || exit 2
pass=0 fail=0
check() { # tz due_date [flags-json] expected
  local got
  got=$(jq -nc --arg d "$2" "{id:\"1\",content:\"t\",due_date:\$d} + $3" |
    TZ=$1 jq -c -L bin 'include "task-normalize"; normalized | {date,time}')
  if [[ $got == "$4" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1 $2 $3: $got != $4"; fi
}
check Asia/Seoul 2026-10-07T00:00:00Z '{}' '{"date":"2026-10-07","time":null}'
check Asia/Seoul 2026-10-07T09:00:00+09:00 '{}' '{"date":"2026-10-07","time":null}'
check Asia/Seoul 2026-10-07T00:00:00.000Z '{"due_time":"15:00"}' '{"date":"2026-10-07","time":"15:00"}'
check Asia/Seoul 2026-10-07T23:30:00Z '{}' '{"date":"2026-10-08","time":"08:30"}'
check Asia/Seoul 2026-10-07T15:00:00Z '{"skip_time":true}' '{"date":"2026-10-08","time":null}'
check America/Los_Angeles 2026-10-08T09:00:00.123+09:00 '{}' '{"date":"2026-10-07","time":"17:00"}'
check America/Los_Angeles 2026-10-07T17:00:00.123-07:00 '{}' '{"date":"2026-10-07","time":"17:00"}'
check America/Los_Angeles 2026-10-08T09:00:00.000+09:00 '{}' '{"date":"2026-10-08","time":null}'
echo "PASS $pass / FAIL $fail — normalize"
[[ $fail == 0 ]]
