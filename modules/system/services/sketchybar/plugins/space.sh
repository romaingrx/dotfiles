#!/bin/sh

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/space.sh

# Get the focused workspace from the event or fallback to aerospace command
WORKSPACE="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

WORKSPACE_ACTIVE_COLOR="0xffefbaff"
WORKSPACE_INACTIVE_COLOR="0x44ffffff"

if [ "$1" = "$WORKSPACE" ]; then
    sketchybar --set $NAME background.color=$WORKSPACE_ACTIVE_COLOR background.drawing=on
else
    sketchybar --set $NAME background.color=$WORKSPACE_INACTIVE_COLOR background.drawing=on
fi

# Debug logging
LOG_FILE="$HOME/Desktop/sketchybar_.log"
{
    echo "Time: $(date)"
    echo "WORKSPACE from event: $FOCUSED_WORKSPACE"
    echo "WORKSPACE from aerospace: $(aerospace list-workspaces --focused)"
    echo "Current workspace arg: $1"
    echo "NAME: $NAME"
    echo "-------------------"
} >> "$LOG_FILE"
