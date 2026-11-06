# Turns sketchybar-app-font's icon_map.sh into waybar window-rewrite rules.
#
# The font draws an app's icon for the ligature `:name:`, and icon_map.sh maps
# app names to those ligatures in one `case` statement. This reuses that
# community-kept map, the one sketchybar uses on macOS, so new apps need no
# edits here. Matching ignores the case of the first letter, since Linux window
# classes are often lowercase.
#
# Usage: app-icons ICON_MAP FONT_FAMILY > rewrite.json
# shellcheck shell=bash

icon_map=${1:?usage: app-icons ICON_MAP FONT_FAMILY}
family=${2:?usage: app-icons ICON_MAP FONT_FAMILY}

jq --raw-input --slurp --arg family "$family" '
  def icon: " <span font_family=\"\($family)\">\(.)</span>";

  # A regex for one app name from [name, glob]: metacharacters escaped, the
  # first letter in either case, and a trailing glob kept as `.*`.
  def pattern:
    .[1] as $glob
    | .[0]
    | gsub("(?<c>[\\\\^$.|?*+()\\[\\]{}])"; "\\\(.c)")
    | (if .[0:1] | test("^[A-Za-z]$")
       then "[\(.[0:1] | ascii_upcase)\(.[0:1] | ascii_downcase)]\(.[1:])"
       else . end)
    + (if $glob == "*" then ".*" else "" end);

  # Each case arm reads `"Name" | "Other")` then `icon_result=":ligature:"`.
  [ scan("(?m)^\\s*(\"[^\\n]*?\"\\*?)\\)\\s*\\n\\s*icon_result=\"(:[^\"]+:)\"")
    | .[1] as $ligature
    # waybar delimits the regex with <>, so names holding them are skipped.
    | [ .[0] | scan("\"([^\"]+)\"(\\*?)") | select(.[0] | test("[<>]") | not) | pattern ]
    | select(length > 0)
    | { key: "class<^(\(join("|")))$>", value: ($ligature | icon) } ]
  | {
      "hyprland/workspaces": {
        "window-rewrite-default": (":default:" | icon),
        "window-rewrite": from_entries
      }
    }
' "$icon_map"
