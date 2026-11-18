#!/usr/bin/env bash

source "$HELPER_DIR/components.sh"

status_item clock \
	update_freq=15 \
	script="$PLUGIN_DIR/clock.sh"
