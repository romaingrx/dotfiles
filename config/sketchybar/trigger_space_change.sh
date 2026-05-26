#!/usr/bin/env bash

SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/run/current-system/sw/bin/sketchybar}"
AEROSPACE_BIN="${AEROSPACE_BIN:-/run/current-system/sw/bin/aerospace}"

focused="$("$AEROSPACE_BIN" list-workspaces --focused)"

"$SKETCHYBAR_BIN" --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$focused"
