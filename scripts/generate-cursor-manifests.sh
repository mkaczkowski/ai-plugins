#!/usr/bin/env bash
set -euo pipefail

# generate-cursor-manifests.sh -- Generate .cursor-plugin/ manifests from .claude-plugin/ sources
#
# Usage:
#   generate-cursor-manifests.sh [MARKETPLACE_ROOT]
#
# MARKETPLACE_ROOT defaults to the repo root (two levels up from this script).
#
# Reads .claude-plugin/marketplace.json (source of truth) and generates:
#   .cursor-plugin/marketplace.json
#   plugins/<name>/.cursor-plugin/plugin.json  (for each plugin)
#
# Exit codes:
#   0 -- all manifests generated
#   2 -- fatal error (source not found, python3 unavailable)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE_ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CLAUDE_MARKETPLACE="$MARKETPLACE_ROOT/.claude-plugin/marketplace.json"

if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 is required but not found" >&2
  exit 2
fi

if [ ! -f "$CLAUDE_MARKETPLACE" ]; then
  echo "ERROR: source marketplace.json not found at $CLAUDE_MARKETPLACE" >&2
  exit 2
fi

# ── Generate root .cursor-plugin/marketplace.json ─────────────────────────────

mkdir -p "$MARKETPLACE_ROOT/.cursor-plugin"

python3 - "$CLAUDE_MARKETPLACE" "$MARKETPLACE_ROOT/.cursor-plugin/marketplace.json" <<'PYEOF'
import json, sys

src_path, dst_path = sys.argv[1], sys.argv[2]

with open(src_path) as f:
    src = json.load(f)

cursor_marketplace = {
    "name": src["name"],
    "owner": src["owner"],
    "plugins": [
        {
            "name": p["name"],
            "source": p["source"],
            "description": p["description"],
        }
        for p in src.get("plugins", [])
    ],
}

with open(dst_path, "w") as f:
    json.dump(cursor_marketplace, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF

echo "  wrote .cursor-plugin/marketplace.json"

# ── Generate per-plugin .cursor-plugin/plugin.json ────────────────────────────

PLUGIN_ENTRIES=$(python3 - "$CLAUDE_MARKETPLACE" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for p in data.get("plugins", []):
    print(f"{p['name']}|{p['source']}")
PYEOF
) || exit 2

while IFS='|' read -r name source; do
  [ -z "$name" ] && continue

  local_source="${source#./}"
  plugin_dir="$MARKETPLACE_ROOT/$local_source"
  claude_manifest="$plugin_dir/.claude-plugin/plugin.json"

  if [ ! -f "$claude_manifest" ]; then
    echo "  SKIP $name: .claude-plugin/plugin.json not found" >&2
    continue
  fi

  mkdir -p "$plugin_dir/.cursor-plugin"

  python3 - "$claude_manifest" "$plugin_dir/.cursor-plugin/plugin.json" "$plugin_dir" <<'PYEOF'
import json, os, sys

src_path, dst_path, plugin_dir = sys.argv[1], sys.argv[2], sys.argv[3]

with open(src_path) as f:
    src = json.load(f)

cursor_plugin = {
    "name": src["name"],
    "description": src["description"],
    "version": src["version"],
    "author": src["author"],
    "keywords": src.get("keywords", []),
}

# Add path fields only for directories that exist
if os.path.isdir(os.path.join(plugin_dir, "skills")):
    cursor_plugin["skills"] = "skills"
if os.path.isdir(os.path.join(plugin_dir, "agents")):
    cursor_plugin["agents"] = "agents"
if os.path.isdir(os.path.join(plugin_dir, "rules")):
    cursor_plugin["rules"] = "rules"

with open(dst_path, "w") as f:
    json.dump(cursor_plugin, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF

  echo "  wrote $local_source/.cursor-plugin/plugin.json"

done <<< "$PLUGIN_ENTRIES"

echo ""
echo "Cursor manifests generated successfully."
