#!/usr/bin/env bash

focused=$(aerospace list-workspaces --focused)

sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$focused"
