#!/usr/bin/env bash

focused=$(aerospace list-workspaces --focused)

/run/current-system/sw/bin/sketchybar --trigger space_change FOCUSED_WORKSPACE="$focused"
