#!/usr/bin/env bash
set -euo pipefail

# install-cursor-local.sh -- Install marketplace plugins locally for Cursor testing
#
# Usage:
#   install-cursor-local.sh <plugin-name>    Install a single plugin
#   install-cursor-local.sh --all            Install all plugins
#   install-cursor-local.sh --list           List available plugins
#   install-cursor-local.sh --uninstall <name|--all>  Remove local installs
#
# Copies plugin files to ~/.cursor/plugins/local/<name>/ where Cursor
# auto-discovers them on restart (or Cmd+Shift+P > "Developer: Reload Window").
#
# Exit codes:
#   0 -- success
#   1 -- bad arguments or plugin not found
#   2 -- fatal error (python3 unavailable, marketplace.json missing)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MARKETPLACE_JSON="$MARKETPLACE_ROOT/.claude-plugin/marketplace.json"

CURSOR_LOCAL_DIR="$HOME/.cursor/plugins/local"

# ── Preflight ─────────────────────────────────────────────────────────────────

if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 is required but not found" >&2
  exit 2
fi

if [ ! -f "$MARKETPLACE_JSON" ]; then
  echo "ERROR: marketplace.json not found at $MARKETPLACE_JSON" >&2
  exit 2
fi

# ── Parse plugin list ─────────────────────────────────────────────────────────

get_plugin_names() {
  python3 - "$MARKETPLACE_JSON" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for p in data.get("plugins", []):
    print(p["name"])
PYEOF
}

get_plugin_source() {
  python3 - "$MARKETPLACE_JSON" "$1" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for p in data.get("plugins", []):
    if p["name"] == sys.argv[2]:
        print(p["source"])
        break
PYEOF
}

# ── Install one plugin ────────────────────────────────────────────────────────

install_plugin() {
  local name="$1"
  local source
  source=$(get_plugin_source "$name")

  if [ -z "$source" ]; then
    echo "ERROR: plugin '$name' not found in marketplace.json" >&2
    return 1
  fi

  local local_source="${source#./}"
  local plugin_dir="$MARKETPLACE_ROOT/$local_source"
  local target="$CURSOR_LOCAL_DIR/$name"

  if [ ! -f "$plugin_dir/.cursor-plugin/plugin.json" ]; then
    echo "  SKIP $name: .cursor-plugin/plugin.json not found (run scripts/generate-cursor-manifests.sh first)" >&2
    return 1
  fi

  rm -rf "$target"
  mkdir -p "$target"
  for dir in .cursor-plugin skills agents scripts rules commands; do
    [ -d "$plugin_dir/$dir" ] && cp -R "$plugin_dir/$dir" "$target/"
  done

  echo "  [OK] $name -> $target"
}

# ── Uninstall one plugin ──────────────────────────────────────────────────────

uninstall_plugin() {
  local name="$1"
  local target="$CURSOR_LOCAL_DIR/$name"

  if [ -d "$target" ]; then
    rm -rf "$target"
    echo "  [OK] uninstalled $name"
  else
    echo "  [SKIP] $name not installed"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
  echo "Usage: install-cursor-local.sh <plugin-name|--all|--list|--uninstall>"
  exit 1
fi

case "$1" in
  --list)
    echo "Available plugins:"
    get_plugin_names | while read -r name; do
      if [ -d "$CURSOR_LOCAL_DIR/$name" ]; then
        echo "  $name (installed)"
      else
        echo "  $name"
      fi
    done
    ;;

  --uninstall)
    shift
    if [ "${1:-}" = "--all" ]; then
      echo "Uninstalling all local plugins..."
      get_plugin_names | while read -r name; do
        uninstall_plugin "$name"
      done
    elif [ -n "${1:-}" ]; then
      uninstall_plugin "$1"
    else
      echo "Usage: install-cursor-local.sh --uninstall <plugin-name|--all>"
      exit 1
    fi
    echo ""
    echo "Done. Restart Cursor to apply."
    ;;

  --all)
    echo "Installing all plugins for local Cursor testing..."
    echo ""
    FAILED=0
    while read -r name; do
      install_plugin "$name" || FAILED=1
    done < <(get_plugin_names)
    echo ""
    if [ "$FAILED" -ne 0 ]; then
      echo "Done with errors. See above for details."
      exit 1
    fi
    echo "Done. Restart Cursor to apply."
    ;;

  *)
    echo "Installing plugin '$1' for local Cursor testing..."
    echo ""
    install_plugin "$1"
    echo ""
    echo "Done. Restart Cursor to apply."
    ;;
esac
