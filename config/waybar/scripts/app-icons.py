"""Turn sketchybar-app-font's icon_map.sh into waybar window-rewrite rules.

The font draws an app's icon for the ligature `:name:`, and icon_map.sh maps
app names to those ligatures. This reuses that community-kept map, the one
sketchybar uses on macOS, so new apps need no edits here. Matching ignores the
case of the first letter, since Linux window classes are often lowercase.

Usage: app-icons.py ICON_MAP FONT_FAMILY > rewrite.json
"""

import json
import re
import sys

icon_map, family = sys.argv[1:]
text = open(icon_map, encoding="utf-8").read()


def icon(ligature):
    return f" <span font_family='{family}'>{ligature}</span>"


def pattern(name):
    glob = name.endswith("*")
    name = re.sub(r"([\\^$.|?*+()\[\]{}])", r"\\\1", name.rstrip("*"))
    if name[:1].isascii() and name[:1].isalpha():
        name = f"[{name[0].upper()}{name[0].lower()}]{name[1:]}"
    return name + (".*" if glob else "")


rules = {}
for names, ligature in re.findall(r'^\s*("[^\n]*?"\*?)\)\s*\n\s*icon_result="(:[^"]+:)"', text, re.M):
    # waybar's rule syntax delimits the regex with <>, so skip names holding them.
    found = ["".join(n) for n in re.findall(r'"([^"]+)"(\*?)', names) if not re.search("[<>]", n[0])]
    if not found:
        continue
    alternatives = "|".join(pattern(n) for n in found)
    rules[f"class<^({alternatives})$>"] = icon(ligature)

json.dump(
    {
        "hyprland/workspaces": {
            "window-rewrite-default": icon(":default:"),
            "window-rewrite": rules,
        }
    },
    sys.stdout,
    ensure_ascii=False,
)
