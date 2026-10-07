# API timestamps may carry fractional seconds and a "Z" or "+HH:MM" suffix.
def iso_epoch: capture("^(?<b>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(?:\\.[0-9]+)?(?<z>Z|(?<s>[+-])(?<h>[0-9]{2}):?(?<m>[0-9]{2}))$")
  | (.b + "Z" | fromdateiso8601)
    - (if .z == "Z" then 0 else (if .s == "+" then 1 else -1 end) * ((.h | tonumber) * 3600 + (.m | tonumber) * 60) end);
def epoch: iso_epoch;
def normalized:
  select(.due_date != null and .due_date != "") |
  . as $t | (.due_date | epoch) as $epoch |
  # Calendar day follows Task#due_calendar_date: UTC date only for UTC-midnight
  # rows, otherwise the owner's zone (this machine's TZ stands in for it).
  # jq % truncates, so also require the fraction (if any) to be zero.
  ((.due_date | test("T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.0+)?(Z|[+-])")) and ($epoch % 86400 == 0)) as $utcMidnight |
  ($utcMidnight or (.is_all_day == true) or (.skip_time == true)) as $anchor |
  {id: (.id | tostring), content: .content,
   date: (if $utcMidnight then $epoch | strftime("%Y-%m-%d") else $epoch | strflocaltime("%Y-%m-%d") end),
   time: (if $anchor then (if (.due_time // "") == "" then null else .due_time end)
          else $epoch | strflocaltime("%H:%M") end),
   important: (.is_important == true), completed: (.completed == true)};
