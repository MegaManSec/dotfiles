#!/bin/sh
set -euo pipefail

VOL_TMP="/home/user/.config/i3/.volume"

curvol="$(mixer -S vol | awk -F":" '{print $NF}')"

touch "$VOL_TMP"
chmod 600 "$VOL_TMP"

[ -O "$VOL_TMP" ] || exit 1 # Ensure we're the owner
[ -f "$VOL_TMP" ] || exit 1 # Ensure it's a file
[ -L "$VOL_TMP" ] && exit 1 # Ensure it's not a symlink

VOL="$(cat "$VOL_TMP")"

if [ "$curvol" -gt 0 ]; then
	echo "$curvol" > "$VOL_TMP"
	mixer vol set 0
else
	mixer vol set "$VOL"
fi
