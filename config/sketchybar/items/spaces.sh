SPACE_ICONS=($(aerospace list-workspaces --all))

sketchybar --add event aerospace_workspace_change
sketchybar --add event aerospace_monitor_change

for sid in "${SPACE_ICONS[@]}"
do
    sketchybar --add item space.$sid left     \
        --set space.$sid icon=$sid                     \
        display="$(
              v=$(aerospace list-windows --workspace "$sid" --format "%{monitor-appkit-nsscreen-screens-id}" | cut -c1)
              echo "${v:-1}"
            )" \
        icon.padding_left=5                        \
        icon.padding_right=5                       \
        background.padding_left=5                  \
        background.padding_right=5                 \
        background.color=0x44ffffff                \
        background.corner_radius=5                 \
        background.height=22                       \
        background.drawing=off                     \
        label.drawing=off                          \
        script="$PLUGIN_DIR/space.sh"              \
        click_script="aerospace workspace $sid" \
        icon.font="$FONT:Medium:15.0"              \
        --subscribe space.$sid aerospace_workspace_change
done
