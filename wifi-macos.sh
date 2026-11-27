#!/bin/sh
set -eu
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin
export PATH

repo="$(cd "$(dirname "$0")" && pwd)"
keychain=/Library/Keychains/System.keychain
tab="$(printf '\t')"

usage() {
  echo "usage: $0 export <file>" >&2
  echo "       $0 import <file>" >&2
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

[ "$#" -eq 2 ] || usage

device="$(networksetup -listallhardwareports | awk '/^Hardware Port: Wi-Fi$/ {getline; print $2; exit}')"
if [ -z "$device" ]; then
  echo "No Wi-Fi interface found." >&2
  exit 1
fi

has_password() {
  security find-generic-password -D "AirPort network password" -a "$1" "$keychain" >/dev/null 2>&1
}

case "$1" in
  export)
    out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
    case "$out" in
      "$repo"/*)
        echo "Refusing to write Wi-Fi passwords inside this public repository." >&2
        exit 1 ;;
    esac
    umask 077
    tmp_out="$(mktemp "$out.XXXXXX")"
    trap 'rm -f "$tmp_out"' EXIT
    networksetup -listpreferredwirelessnetworks "$device" | sed "1d; s/^$tab//" | while IFS= read -r ssid; do
      case "$ssid" in
        *"$tab"*)
          echo "skipped $ssid: the name contains a tab"
          continue ;;
      esac
      if ! has_password "$ssid"; then
        printf '%s\t\n' "$ssid" >> "$tmp_out"
        continue
      fi
      echo "Reading the password for $ssid: approve the prompt with your admin password."
      if password="$(security find-generic-password -D "AirPort network password" -a "$ssid" -w "$keychain" </dev/null 2>/dev/null)"; then
        printf '%s\t%s\n' "$ssid" "$password" >> "$tmp_out"
      else
        echo "skipped $ssid: the password was not read"
      fi
    done
    mv "$tmp_out" "$out"
    echo "Wrote $(wc -l < "$out" | tr -d ' ') networks to $out"
    ;;
  import)
    [ -f "$2" ] || usage
    sudo -v
    known="$(networksetup -listpreferredwirelessnetworks "$device" | sed "1d; s/^$tab//")"
    while IFS="$tab" read -r ssid password; do
      [ -n "$ssid" ] || continue
      if ! printf '%s\n' "$known" | grep -qxF -- "$ssid"; then
        if [ -n "$password" ]; then
          echo "+ add $ssid"
          sudo networksetup -addpreferredwirelessnetworkatindex "$device" "$ssid" 0 WPA2 </dev/null >/dev/null
        else
          echo "+ add $ssid (open)"
          sudo networksetup -addpreferredwirelessnetworkatindex "$device" "$ssid" 0 OPEN </dev/null >/dev/null
        fi
      fi
      if [ -n "$password" ] && ! has_password "$ssid"; then
        echo "+ store the password for $ssid"
        sudo security add-generic-password -a "$ssid" -s AirPort -D "AirPort network password" -l "$ssid" -w "$password" \
          -T /usr/libexec/airportd -T group://AirPort "$keychain" </dev/null
      fi
    done < "$2"
    ;;
  *)
    usage ;;
esac
