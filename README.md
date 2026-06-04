# ai-plugins

Dual-platform plugin marketplace for Claude Code and Cursor. Provides reusable skills and agents for AI-assisted development workflows.

## Setup

### Claude Code

```bash
# Add the marketplace
/plugin marketplace add https://github.com/mkaczkowski/ai-plugins.git

# Install a plugin
/plugin install queen@ai-plugins
```

### Cursor (local testing)

```bash
# Clone the repo
git clone https://github.com/mkaczkowski/ai-plugins.git
cd ai-plugins

# Generate Cursor manifests
scripts/generate-cursor-manifests.sh

# Install all plugins locally
scripts/install-cursor-local.sh --all
```

Restart Cursor after installing. Cursor auto-discovers plugins from `~/.cursor/plugins/local/`.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| `queen` | Spec-driven feature orchestrator with parallel discovery, human-in-the-loop architecture design, and quality gates |
| `cursor-consult` | Read-only analysis using Cursor CLI — review changes, ask questions, or get a second opinion from a different AI agent |
| `obsidian` | Obsidian vault integration: CLI, flavored markdown, bases, canvas, defuddle, daily workflow, and epic knowledge base scaffolding |

## Install a Plugin

### Claude Code

```bash
/plugin install queen@ai-plugins
/plugin install cursor-consult@ai-plugins
/plugin install obsidian@ai-plugins
```

### Cursor

Use `scripts/install-cursor-local.sh` to install individual plugins:

```bash
scripts/install-cursor-local.sh queen
scripts/install-cursor-local.sh cursor-consult
scripts/install-cursor-local.sh obsidian
```

## Adding a New Plugin

1. Create `plugins/<name>/` with the following structure:

   ```
   plugins/<name>/
     .claude-plugin/plugin.json   # Plugin manifest
     skills/<name>/SKILL.md       # Skill definition
     agents/                      # Optional agent definitions
     scripts/                     # Optional shell scripts
   ```

2. Add the plugin entry to `.claude-plugin/marketplace.json`.

3. Run `scripts/generate-cursor-manifests.sh` to generate Cursor manifests.

4. Verify with `claude plugin validate .`.

### Plugin manifest (`.claude-plugin/plugin.json`)

```json
{
  "name": "my-plugin",
  "description": "What this plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  },
  "keywords": ["tag1", "tag2"]
}
```

### Skill frontmatter (`skills/<name>/SKILL.md`)

```markdown
---
name: my-plugin
description: One-line description shown to the model
argument-hint: 'example usage'
allowed-tools: Read Glob Grep Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)
---
```

Use `${CLAUDE_PLUGIN_ROOT}` for all script and file references — it resolves to the plugin root at runtime.
