# Plugin Marketplace

Dual-platform plugin marketplace for Claude Code and Cursor.

## Structure

```
.claude-plugin/marketplace.json        # Marketplace catalog, source of truth
.cursor-plugin/marketplace.json        # Generated Cursor marketplace manifest
plugins/<name>/.claude-plugin/         # Plugin manifest (plugin.json), source of truth
plugins/<name>/.cursor-plugin/         # Generated Cursor plugin manifest
plugins/<name>/skills/                 # Skill definitions (SKILL.md), shared by both platforms
plugins/<name>/agents/                 # Agent definitions (.md), shared by both platforms
plugins/<name>/scripts/                # Shell scripts (Claude Code only)
scripts/                               # Repo-level tooling
```

## Conventions

- Plugin names: kebab-case
- Use `${CLAUDE_PLUGIN_ROOT}` in SKILL.md for all file/script references
- Scripts can use `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` for inter-script sourcing
- Keep plugin version in sync between `plugin.json` and `marketplace.json`
- Run `scripts/generate-cursor-manifests.sh` after adding or modifying plugins to keep Cursor manifests in sync

## Commands

```bash
# Validate marketplace structure (both Claude Code and Cursor manifests)
claude plugin validate .

# Generate Cursor-compatible manifests from Claude Code sources
scripts/generate-cursor-manifests.sh

# Install plugins locally for Cursor testing
scripts/install-cursor-local.sh --all

# Test locally (Claude Code)
# /plugin marketplace add /path/to/ai-plugins
# /plugin install <plugin-name>@ai-plugins
```
