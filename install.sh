#!/bin/bash
# Install or remove the ainote clock in place of Omarchy's built-in clock.
#
#   ./install.sh              copy this checkout into the plugin dir and enable it
#   ./install.sh --uninstall  put omarchy.clock back and remove the plugin
#   ./install.sh --uninstall --purge   also log out of ainote and delete credentials
#
# The manifest declares omarchy.clonedFrom = omarchy.clock, so enabling swaps the
# clock entry in place (keeping its position) and the clock hotkey routes here.
# The one thing the shell does not follow is bar.centerAnchor, which matches the
# entry id exactly, so this script points it at us and restores it afterwards.

set -euo pipefail

ID="io.github.seunghan91.ainote-clock"
SOURCE_ID="omarchy.clock"
SRC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$ID"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ainote-clock"
ANCHOR_MARK="$STATE_DIR/took-center-anchor"

: "${OMARCHY_PATH:=/usr/share/omarchy}"
export OMARCHY_PATH
# shellcheck source=/dev/null
source "$OMARCHY_PATH/bin/omarchy-shell-config"

# 0 = id is in the bar layout, 1 = it is not, 2 = shell.json could not be read.
layout_has() {
  local out
  out=$(jq -r --arg id "$1" '[.bar.layout[]?[]? | if type == "object" then .id else . end] | index($id) != null' \
    "$(source_file)" 2>/dev/null) || return 2
  case "$out" in true) return 0 ;; false) return 1 ;; *) return 2 ;; esac
}

wait_for_layout() {
  local id="$1" want="$2" rc
  for _ in $(seq 1 50); do
    rc=0; layout_has "$id" || rc=$?
    [[ $want == present && $rc == 0 ]] && return 0
    [[ $want == absent && $rc == 1 ]] && return 0
    sleep 0.1
  done
  return 1
}

# Discovery runs asynchronously after rescanPlugins, so enable only once the
# catalog lists us.
# Returns nonzero instead of exiting so the caller can roll back first.
wait_for_catalog() {
  omarchy-shell -q shell rescanPlugins >/dev/null 2>&1 || return 1
  for _ in $(seq 1 50); do
    omarchy-plugin-list --json 2>/dev/null | jq -e --arg id "$ID" 'any(.[]; .id == $id)' >/dev/null && return 0
    sleep 0.1
  done
  return 1
}

current_anchor() {
  jq -r '.bar.centerAnchor // ""' "$(source_file)"
}

install_plugin() {
  [[ -f $SRC_DIR/manifest.json ]] || fail "run this from the plugin checkout"
  [[ $SRC_DIR != "$(realpath -m "$PLUGIN_DIR")" ]] || fail "run this from a checkout, not from the installed plugin dir"
  if [[ $(omarchy-shell lock isLocked 2>/dev/null || echo false) == true ]]; then
    fail "the screen is locked; unlock first"
  fi
  # The shell rejects plugin dirs that contain symlinks.
  [[ -z $(find "$SRC_DIR" -path "$SRC_DIR/.git" -prune -o -type l -print) ]] || fail "checkout contains symlinks"

  # Build the new copy beside the old one and swap, so a failed copy never
  # leaves the bar pointing at a half-written plugin.
  local parent stage backup
  parent=$(dirname "$PLUGIN_DIR")
  mkdir -p "$parent"
  stage=$(mktemp -d "$parent/.ainote-clock-stage.XXXXXX")
  backup="$parent/.ainote-clock-previous"
  trap 'rm -rf "$stage"' RETURN
  tar -C "$SRC_DIR" --exclude='./.git' --exclude='./.mockups' --exclude='./.planning' --exclude='./tests' --exclude='./docs' -cf - . |
    tar -C "$stage" -xf -
  chmod 755 "$stage/bin/ainote-clock"
  jq -e --arg id "$ID" '.id == $id' "$stage/manifest.json" >/dev/null || fail "staged manifest is not $ID"

  rm -rf "$backup"
  [[ -d $PLUGIN_DIR ]] && mv "$PLUGIN_DIR" "$backup"
  mv "$stage" "$PLUGIN_DIR"

  if ! { wait_for_catalog && omarchy-plugin-enable "$ID" && wait_for_layout "$ID" present; }; then
    rm -rf "$PLUGIN_DIR"
    [[ -d $backup ]] && mv "$backup" "$PLUGIN_DIR"
    fail "could not enable $ID; previous install restored"
  fi
  rm -rf "$backup"

  # Take over the dead-centre anchor only when it pointed at the clock, and
  # remember that we did so uninstall gives back exactly that.
  mkdir -p "$STATE_DIR"
  if [[ $(current_anchor) == "$SOURCE_ID" ]]; then
    : >"$ANCHOR_MARK"
    commit "$NORMALIZE | .bar.centerAnchor = \$id" --arg id "$ID"
  fi

  echo "ainote 시계를 켰습니다. 시계를 눌러 ainote 에 로그인하세요."
}

uninstall_plugin() {
  if [[ -d $PLUGIN_DIR ]]; then
    if [[ $PURGE == true && -x $PLUGIN_DIR/bin/ainote-clock ]]; then
      "$PLUGIN_DIR/bin/ainote-clock" logout >/dev/null || true
    fi
    # Disabling a clonedFrom plugin puts the source entry back in place. If that
    # does not stick, keep everything so a second run can try again.
    omarchy-plugin-disable "$ID" || fail "could not disable $ID; nothing removed"
    wait_for_layout "$ID" absent || fail "$ID is still in the bar layout; nothing removed"
  fi

  if [[ -f $ANCHOR_MARK ]]; then
    if [[ $(current_anchor) == "$ID" ]]; then
      commit "$NORMALIZE | .bar.centerAnchor = \$src" --arg src "$SOURCE_ID"
    fi
    rm -f "$ANCHOR_MARK"
  fi

  rm -rf "$PLUGIN_DIR"
  omarchy-shell -q shell rescanPlugins >/dev/null 2>&1 || true
  if [[ $PURGE == true ]]; then
    rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/ainote-clock"
  fi
  rmdir "$STATE_DIR" 2>/dev/null || true
  echo "기본 시계로 되돌렸습니다."
}

ACTION=install
PURGE=false
for arg in "$@"; do
  case "$arg" in
    --uninstall) ACTION=uninstall ;;
    --purge) PURGE=true ;;
    -h | --help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) fail "unknown option: $arg" ;;
  esac
done

if [[ $ACTION == install ]]; then install_plugin; else uninstall_plugin; fi
