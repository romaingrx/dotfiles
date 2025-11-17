#!/usr/bin/env sh

if [ -n "$INFO" ]; then
    focused="$INFO"
else
    focused=$(aerospace list-workspaces --focused)
fi

workspace_id="${NAME#space.}"

echo "focused=$focused"
echo "workspace_id=$workspace_id"

if [ "$focused" = "$workspace_id" ]; then
    sketchybar --set $NAME drawing=on background.drawing=on
else
    sketchybar --set $NAME drawing=on background.drawing=off
fi
