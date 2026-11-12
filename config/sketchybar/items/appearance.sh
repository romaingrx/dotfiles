#### Appearance sync (hidden) ####
# Re-runs the plugin on every macOS light/dark switch, and once at startup.
sketchybar --add event appearance_changed AppleInterfaceThemeChangedNotification \
	--add item appearance.sync right \
	--set appearance.sync drawing=off \
	updates=on \
	script="$PLUGIN_DIR/appearance_sync.sh" \
	--subscribe appearance.sync appearance_changed
