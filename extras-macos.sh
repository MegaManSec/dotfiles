#!/bin/sh
set -eu
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin
export PATH

repo="$(cd "$(dirname "$0")" && pwd)"
littlesnitch="/Applications/Little Snitch.app/Contents/Components/littlesnitch"
littlesnitch_settings="$repo/littlesnitch-settings.txt"

usage() {
  echo "usage: $0" >&2
  echo "       $0 export-littlesnitch" >&2
  exit 1
}

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script must run on MacOS." >&2
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  echo "This script must be run as your user, not root." >&2
  exit 1
fi

littlesnitch_ready() {
  [ -x "$littlesnitch" ] || return 1
  status="$(sudo "$littlesnitch" list-preferences 2>&1)" || return 1
  case "$status" in
    *"not authorized"*) return 1 ;;
  esac
}

littlesnitch_hint() {
  echo "Enable Little Snitch > Settings > Security > Allow access via Terminal, then rerun." >&2
}

if [ "${1:-}" = "export-littlesnitch" ]; then
  [ "$#" -eq 1 ] || usage
  littlesnitch_ready || { littlesnitch_hint; exit 1; }
  sudo "$littlesnitch" list-preferences | sed 's/^ *//' |
    grep -v -E ' = (<not set|Dictionary \(|Array \(|[0-9]{4}-[0-9]{2}-[0-9]{2} )' |
    grep -v -E '^(activeSilentMode|allowCommandLineAccess|configurationErrorInfo|enabledUserNotificationTypes|globalLastShownWelcomeWindowVersion|ipAddressDatabaseLastUpdateCheckFailed) = ' > "$littlesnitch_settings"
  echo "Wrote $littlesnitch_settings"
  exit 0
fi

[ "$#" -eq 0 ] || usage

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

sudo -v

login_items="$(osascript -e 'tell application "System Events" to get the name of every login item' | tr ',' '\n' | sed 's/^ *//')"
for app in "Magic Switch" "Bitwarden"; do
  if [ ! -d "/Applications/$app.app" ]; then
    echo "skipped login item $app: not installed"
  elif ! printf '%s\n' "$login_items" | grep -qxF "$app"; then
    echo "+ add login item $app"
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/$app.app\", hidden:false}" >/dev/null
  fi
done

guid="$(dscl . -read "/Users/$USER" GeneratedUID | awk '{print $2}')"
key=":CBUser-$guid:CBBlueReductionStatus"
cb="$tmp/corebrightness.plist"
cb_changed=0
sudo /usr/bin/defaults export com.apple.CoreBrightness - | cat > "$cb"
mode="$(/usr/libexec/PlistBuddy -c "Print $key:BlueReductionMode" "$cb" 2>/dev/null || true)"
auto="$(/usr/libexec/PlistBuddy -c "Print $key:AutoBlueReductionEnabled" "$cb" 2>/dev/null || true)"
if [ -z "$mode" ]; then
  echo "skipped Night Shift: open System Settings > Displays > Night Shift once, then rerun"
elif [ "$mode" != "1" ] || [ "$auto" != "1" ]; then
  echo "+ set Night Shift to Sunset to Sunrise"
  /usr/libexec/PlistBuddy -c "Set $key:BlueReductionMode 1" -c "Set $key:AutoBlueReductionEnabled 1" "$cb"
  cb_changed=1
fi
displays="$(/usr/libexec/PlistBuddy -c "Print :DisplayPreferences" "$cb" 2>/dev/null | awk '/^    [^ ]+ = Dict \{$/ {print $1}')"
if [ -z "$displays" ]; then
  echo "skipped auto-brightness: open System Settings > Displays once, then rerun"
fi
for d in $displays; do
  if [ "$(/usr/libexec/PlistBuddy -c "Print :DisplayPreferences:$d:AutoBrightnessEnable" "$cb" 2>/dev/null || true)" != "false" ]; then
    echo "+ turn off automatic brightness for display $d"
    /usr/libexec/PlistBuddy -c "Set :DisplayPreferences:$d:AutoBrightnessEnable false" "$cb" 2>/dev/null ||
      /usr/libexec/PlistBuddy -c "Add :DisplayPreferences:$d:AutoBrightnessEnable bool false" "$cb"
    cb_changed=1
  fi
done
if [ "$cb_changed" -eq 1 ]; then
  sudo /usr/bin/defaults import com.apple.CoreBrightness "$cb"
  sudo /usr/bin/killall corebrightnessd
fi

if [ "$(/usr/bin/defaults -currentHost read -g com.apple.mouse.tapBehavior 2>/dev/null || true)" != "1" ]; then
  echo "+ turn on tap to click"
  /usr/bin/defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
fi

wallpaper="$HOME/wallpaper.jpg"
if [ ! -f "$wallpaper" ]; then
  echo "skipped wallpaper: $wallpaper is missing, run ./sync-macos.sh first"
elif osascript -e 'tell application "System Events" to get picture of every desktop' | tr ',' '\n' | sed 's/^ *//' | grep -qvxF "$wallpaper"; then
  echo "+ set the wallpaper to $wallpaper"
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wallpaper\"" >/dev/null
fi

diag="/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist"
for k in AutoSubmit ThirdPartyDataSubmit; do
  if [ "$(sudo /usr/bin/defaults read "$diag" "$k" 2>/dev/null || true)" != "0" ]; then
    echo "+ turn off $k"
    sudo /usr/bin/defaults write "$diag" "$k" -bool false
  fi
done

if littlesnitch_ready; then
  while IFS= read -r line; do
    printf '%s\n' "$status" | sed 's/^ *//' | grep -qxF -- "$line" && continue
    echo "+ set Little Snitch ${line%% = *} to ${line#* = }"
    sudo "$littlesnitch" write-preference "${line%% = *}" "${line#* = }" </dev/null
  done < "$littlesnitch_settings"
else
  echo "skipped Little Snitch settings:"
  littlesnitch_hint
fi

if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
  echo "+ gh auth login"
  gh auth login
fi

cat <<'EOF'

Still to do by hand:
- Approve the Little Snitch network extension and any Privacy & Security prompts (Full Disk Access, Accessibility, Bluetooth).
- Pair Magic Switch with the other Mac.
- Sign in to Bitwarden and Spotify.
- Log out and back in, then check System Settings > Apple Intelligence & Siri shows Apple Intelligence off.
EOF
