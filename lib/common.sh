#!/bin/bash
# Shared helpers and platform detection sourced by install.sh and the
# per-platform install.*.sh scripts.

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      OS=unknown ;;
esac

is_macos() { [ "$OS" = macos ]; }
is_linux() { [ "$OS" = linux ]; }

# Modification time of a file as a Unix timestamp (BSD vs GNU stat).
file_mtime() {
  if is_macos; then
    stat -f '%m' "$1"
  else
    stat -c '%Y' "$1"
  fi
}

safe_default() {
  local domain="$1" key="$2" type="$3" value="$4"
  local normalized="$value"
  if [ "$type" = "-bool" ]; then
    [ "$value" = "true" ]  && normalized="1"
    [ "$value" = "false" ] && normalized="0"
  fi
  local current
  current=$(defaults read "$domain" "$key" 2>/dev/null)
  if [ "$current" = "$normalized" ]; then
    echo "  Already set: $domain $key"
  else
    defaults write "$domain" "$key" "$type" "$value"
    echo "  Set: $domain $key = $value"
  fi
}

safe_symlink() {
  local target="$1"
  local link_name="$2"

  if [ -L "$link_name" ]; then
    current_target="$(readlink "$link_name")"
    if [ "$current_target" = "$target" ]; then
      echo "  Symlink already exists: $link_name"
    else
      ln -nsf "$target" "$link_name"
      echo "  Updated symlink: $link_name -> $target (was -> $current_target)"
    fi
  elif [ -e "$link_name" ]; then
    echo "  WARNING: $link_name exists as a real file/directory. Skipping."
  else
    ln -nsf "$target" "$link_name"
    echo "  Created symlink: $link_name -> $target"
  fi
}

_rule() {
  local char="$1" title="$2"
  local cols width border
  cols=${COLUMNS:-$(stty size </dev/tty 2>/dev/null | awk '{print $2}')}
  cols=${cols:-80}
  width=$(( cols < 80 ? cols : 80 ))
  border=$(printf "%${width}s" '' | tr ' ' "$char")
  printf '%s\n' "$border"
  printf '%s %s\n' "$char" "$title"
  printf '%s\n' "$border"
}

section() { _rule "#" "$1"; }
banner()  { _rule "*" "$1"; }
