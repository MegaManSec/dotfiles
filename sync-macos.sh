#!/bin/sh
set -eu
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin
export PATH

repo="$(cd "$(dirname "$0")" && pwd)"
tab="$(printf '\t')"
work=""
if [ -e "$HOME/.config/dotfiles/work" ]; then
  work="$repo/macos-work"
fi
dry=0
[ "${1:-}" = "-n" ] && dry=1

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script must run on MacOS." >&2
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  echo "This script must be run as your user, not root." >&2
  exit 1
fi

prefs="
.GlobalPreferences
com.apple.Accessibility
com.apple.ActivityMonitor
com.apple.AdLib
com.apple.AppleMultitouchMouse
com.apple.AppleMultitouchTrackpad
com.apple.CloudSubscriptionFeatures.optIn
com.apple.HIToolbox
com.apple.LaunchServices/com.apple.launchservices.secure
com.apple.Passwords
com.apple.Spotlight
com.apple.Terminal
com.apple.TextInputMenu
com.apple.TextInputMenuAgent
com.apple.WindowManager
com.apple.assistant.support
com.apple.controlcenter
com.apple.driver.AppleBluetoothMultitouch.mouse
com.apple.driver.AppleBluetoothMultitouch.trackpad
com.apple.menuextra.clock
com.apple.ncprefs
com.apple.screensaver
com.apple.symbolichotkeys
com.apple.universalaccess
"

byhost_prefs="
com.apple.controlcenter
com.apple.screensaver
"

work_prefs="
io.tailscale.ipn.macsys
"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

changed=0
prefs_changed=0
dns_changed=0
sidebar_changed=0
import_failed=0

run() {
  echo "+ $*"
  [ "$dry" -eq 1 ] || "$@"
}

file_mode() {
  if [ -x "$1" ]; then echo 0755; else echo 0644; fi
}

put() {
  changed=0
  /usr/bin/cmp -s "$1" "$2" 2>/dev/null && return 0
  changed=1
  [ -d "$(dirname "$2")" ] || run /bin/mkdir -p "$(dirname "$2")"
  run /usr/bin/install -m "$3" "$1" "$2"
}

seed_marker() {
  case "$1" in
    "Library/Application Support/Firefox/Profiles/"*/*)
      case "${1#Library/Application Support/Firefox/Profiles/*/}" in
        user.js|chrome/*|extensions/*) ;;
        *) printf '%s\n' "$1" | cut -d/ -f1-5 ;;
      esac ;;
    "Library/Application Support/com.apple.sharedfilelist/"*) ;;
    "Library/Application Support/"*/*) printf '%s\n' "$1" | cut -d/ -f1-3 ;;
    Library/Shortcuts/*) echo Library/Shortcuts ;;
    .gitconfig.local|.gitconfig.work) echo "$1" ;;
  esac
}

seed() {
  changed=0
  grep -qxF "$2" "$tmp/seeding" || return 0
  put "$home_src/$1" "$HOME/$1" "$3"
}

put_root() {
  changed=0
  sudo /usr/bin/cmp -s "$1" "$2" 2>/dev/null && return 0
  changed=1
  [ -d "$(dirname "$2")" ] || run sudo /usr/bin/install -d -o root -g wheel -m 0755 "$(dirname "$2")"
  run sudo /usr/bin/install -o root -g wheel -m "$3" "$1" "$2"
}

seed_root() {
  changed=0
  sudo test -e "$2" || put_root "$@"
}

put_json() {
  if [ -f "$2" ] && [ -x /usr/bin/jq ]; then
    /usr/bin/jq -s '.[0] * .[1]' "$2" "$1" > "$tmp/merged.json"
    put "$tmp/merged.json" "$2" "$3"
  else
    put "$@"
  fi
}

defaults_host() {
  if [ "$1" = "byhost" ]; then
    shift
    /usr/bin/defaults -currentHost "$@"
  else
    shift
    /usr/bin/defaults "$@"
  fi
}

keep_entries() {
  n="$(/usr/bin/plutil -extract "$1" raw -o - "$tmp/current.plist" 2>/dev/null)" || return 0
  arr="$1"
  shift
  i=0
  while [ "$i" -lt "$n" ]; do
    id=""
    for field in "$@"; do
      if v="$(/usr/bin/plutil -extract "$arr.$i.$field" raw -o - "$tmp/current.plist" 2>/dev/null)"; then
        id="$v"
        break
      fi
    done
    if [ -n "$id" ] && ! /usr/bin/plutil -extract "$arr" xml1 -o - "$tmp/merged.plist" | grep -qF "<string>$id</string>"; then
      /usr/bin/plutil -insert "$arr" -xml "$(/usr/bin/plutil -extract "$arr.$i" xml1 -o - "$tmp/current.plist" | sed '1,3d;$d')" -append "$tmp/merged.plist"
    fi
    i=$((i + 1))
  done
}

merge_pref() {
  if ! defaults_host "$1" export "$2" "$tmp/current.plist" 2>/dev/null; then
    printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict/></plist>' > "$tmp/current.plist"
  fi
  /bin/cp "$3" "$tmp/merged.plist"
  /usr/libexec/PlistBuddy -c "Merge $tmp/current.plist" "$tmp/merged.plist" >/dev/null 2>&1
  case "$2" in
    com.apple.ncprefs)
      keep_entries apps bundle-id ;;
    com.apple.LaunchServices/com.apple.launchservices.secure)
      keep_entries LSHandlers LSHandlerURLScheme LSHandlerContentType ;;
  esac
  if [ "$(/usr/bin/plutil -convert xml1 -o - "$tmp/current.plist")" = "$(/usr/bin/plutil -convert xml1 -o - "$tmp/merged.plist")" ]; then
    return 0
  fi
  prefs_changed=1
  if [ "$1" = "byhost" ]; then
    echo "+ defaults -currentHost import $2"
  else
    echo "+ defaults import $2"
  fi
  if [ "$dry" -eq 0 ] && ! defaults_host "$1" import "$2" "$tmp/merged.plist"; then
    echo "failed to import $2: give Terminal Full Disk Access (System Settings > Privacy & Security), reopen it, and rerun" >&2
    import_failed=1
  fi
}

list_files() {
  if [ "$1" = home ]; then sub=Users/jrogers/; else sub=; fi
  for tree in "$repo/macos" ${work:+"$work"}; do
    [ -d "$tree/$sub" ] || continue
    (cd "$tree/$sub" && find . -type f ! -name .DS_Store ! -path './Users/*') | sed 's|^\./||' | while IFS= read -r rel; do
      if [ -n "$work" ] && [ "$tree" != "$work" ] && [ -e "$work/$sub$rel" ]; then
        continue
      fi
      printf '%s\t%s\n' "$tree" "$rel"
    done
  done
}

[ "$dry" -eq 1 ] || sudo -v

list_files home > "$tmp/home"
while IFS="$tab" read -r tree rel; do
  m="$(seed_marker "$rel")"
  if [ -n "$m" ] && [ ! -e "$HOME/$m" ]; then
    printf '%s\n' "$m"
  fi
done < "$tmp/home" | sort -u > "$tmp/seeding"

while IFS="$tab" read -r tree rel; do
  home_src="$tree/Users/jrogers"
  f="$home_src/$rel"
  dst="$HOME/$rel"
  mode="$(file_mode "$f")"
  m="$(seed_marker "$rel")"
  if [ -n "$m" ]; then
    seed "$rel" "$m" "$mode"
    continue
  fi
  case "$rel" in
    Library/Preferences/pnpm/*)
      put "$f" "$dst" "$mode" ;;
    Library/Preferences/*)
      ;;
    "Library/Application Support/com.apple.sharedfilelist/"*)
      put "$f" "$dst" "$mode"
      [ "$changed" -eq 0 ] || sidebar_changed=1 ;;
    .claude/settings.json)
      put_json "$f" "$dst" "$mode" ;;
    .ssh/*)
      put "$f" "$dst" 0600 ;;
    Library/LaunchAgents/local.hidutilKeyMapping.plist)
      if [ -e "$HOME/.config/dotfiles/swap-section-key" ]; then
        put "$f" "$dst" "$mode"
        if [ "$changed" -eq 1 ]; then
          run launchctl bootout "gui/$(id -u)/local.hidutilKeyMapping" 2>/dev/null || true
          run launchctl bootstrap "gui/$(id -u)" "$dst"
        fi
      else
        echo "skipped ~/$rel: create ~/.config/dotfiles/swap-section-key on a Mac whose keyboard has a § key"
      fi ;;
    *)
      put "$f" "$dst" "$mode" ;;
  esac
done < "$tmp/home"

for d in "$HOME/.ssh" "$HOME/.ssh/agent" "$HOME/.ssh/control" "$HOME/.ssh/config.d"; do
  if [ -d "$d" ] && [ "$(/usr/bin/stat -f %Lp "$d")" != "700" ]; then
    run /bin/chmod 700 "$d"
  fi
done

for p in $prefs; do
  domain="$p"
  [ "$p" = ".GlobalPreferences" ] && domain="NSGlobalDomain"
  merge_pref any "$domain" "$repo/macos/Users/jrogers/Library/Preferences/$p.plist"
done

for p in $byhost_prefs; do
  for f in "$repo/macos/Users/jrogers/Library/Preferences/ByHost/$p".*.plist; do
    [ -f "$f" ] || continue
    merge_pref byhost "$p" "$f"
  done
done

if [ -n "$work" ]; then
  for p in $work_prefs; do
    merge_pref any "$p" "$work/Users/jrogers/Library/Preferences/$p.plist"
  done
fi

list_files system > "$tmp/system"
while IFS="$tab" read -r tree rel; do
  f="$tree/$rel"
  case "$rel" in
    etc/shells)
      grep -v '^#' "$f" | grep -v '^$' | while IFS= read -r shell; do
        if ! grep -qxF "$shell" /etc/shells; then
          echo "+ append $shell to /etc/shells"
          [ "$dry" -eq 1 ] || printf '%s\n' "$shell" | sudo /usr/bin/tee -a /etc/shells >/dev/null
        fi
      done ;;
    etc/sudoers.d/*)
      /usr/sbin/visudo -cqf "$f"
      put_root "$f" "/$rel" 0440 ;;
    var/at/tabs/*)
      grep -v '^# ' "$f" > "$tmp/crontab"
      if ! crontab -l 2>/dev/null | /usr/bin/cmp -s - "$tmp/crontab"; then
        run crontab "$tmp/crontab"
      fi ;;
    usr/local/bin/*)
      put_root "$f" "/$rel" 0755 ;;
    usr/local/etc/blocked-hosts)
      seed_root "$f" "/$rel" 0644 ;;
    usr/local/etc/cloaked-hosts|usr/local/etc/forwarded-hosts)
      put_root "$f" "/$rel" 0644
      [ "$changed" -eq 0 ] || dns_changed=1 ;;
    usr/local/etc/*)
      put_root "$f" "/$rel" 0644 ;;
    opt/homebrew/*)
      if [ -d /opt/homebrew/etc ]; then
        put "$f" "/$rel" 0644
        [ "$changed" -eq 0 ] || dns_changed=1
      else
        echo "skipped /$rel: Homebrew is not installed yet"
      fi ;;
    *)
      echo "skipped /$rel: no rule for it in $(basename "$0")" ;;
  esac
done < "$tmp/system"

if [ "$dns_changed" -eq 1 ]; then
  for plist in /Library/LaunchDaemons/*dnscrypt-proxy*.plist; do
    [ -f "$plist" ] || continue
    run sudo /bin/launchctl kickstart -k "system/$(/usr/bin/plutil -extract Label raw -o - "$plist")" || true
  done
fi

if [ "$sidebar_changed" -eq 1 ]; then
  run /usr/bin/killall sharedfilelistd Finder 2>/dev/null || true
fi

if [ "$prefs_changed" -eq 1 ]; then
  run /usr/bin/killall Dock Finder SystemUIServer ControlCenter 2>/dev/null || true
  echo "Log out and back in to apply the trackpad, keyboard and default app settings."
fi

if [ "$import_failed" -eq 1 ]; then
  exit 1
fi
