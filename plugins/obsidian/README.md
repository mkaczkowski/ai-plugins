# obsidian

Drive a running Obsidian vault from Claude Code. Seven bundled skills cover daily routines, project scaffolding, CLI automation, flavored markdown authoring, Bases, Canvas, and web content extraction.

## When to use it

- **You live in an Obsidian vault** and want Claude to read, write, and maintain notes without you leaving the terminal.
- **You run recurring rituals** (morning standup, 1:1 prep, EOD review, weekly review) and want them scripted, not remembered.
- **You author Obsidian-flavored markdown** (wikilinks, callouts, embeds, Bases, Canvas) and want Claude to get the syntax right first try.
- **You are developing an Obsidian plugin or theme** and want a reload/error/screenshot loop.

## Use cases

| Situation | What to ask Claude |
| --- | --- |
| Start of day | `/obsidian-daily morning` — opens today's note, shows open tasks, scaffolds priorities |
| Before a 1:1 | `/obsidian-daily 1on1 Alex` — opens or creates this month's 1:1 note, surfaces prior action items |
| Mid-flow thought | `/obsidian-daily capture fix relay bug` — appends a bullet to today's note (clipboard if no text) |
| End of day | `/obsidian-daily eod` — lists done/open tasks, seeds "Tomorrow" section, prints vault health |
| Weekly cleanup | `/obsidian-daily weekly` — open tasks, orphans, broken links, stats + suggestions |
| Quick lookup | `/obsidian-daily find module federation` |
| Kick off a project | `/obsidian-project-scaffold new "Auth Refactor" PROJ-999` — creates a project folder with an index, a brief, resources, and a meetings folder |
| Author a note | "Create a project note with a warning callout and a wikilink to Architecture Notes" |
| Build a database view | "Make a Base showing all active projects sorted by due date" |
| Sketch a diagram | "Create a canvas with three grouped nodes connected left to right" |
| Clip a webpage | "Defuddle this URL into the vault as a reading note" |
| Plugin dev loop | "Reload my plugin, check errors, take a screenshot" |

## Bundled skills

| Skill | Purpose |
| --- | --- |
| `obsidian-daily` | Opinionated daily routines (custom) |
| `obsidian-project-scaffold` | Scaffold a new project knowledge base with templated files (custom) |
| `obsidian-cli` | Drive the `obsidian` CLI against a running vault |
| `obsidian-markdown` | Obsidian Flavored Markdown: wikilinks, callouts, embeds, properties |
| `obsidian-bases` | Author `.base` files (views, filters, formulas) |
| `json-canvas` | Author `.canvas` files (nodes, edges, groups) |
| `defuddle` | Extract clean markdown from web pages via the Defuddle CLI |

`obsidian-daily` and `obsidian-project-scaffold` are invoked with slash commands (`/obsidian-daily <routine>`, `/obsidian-project-scaffold new "<title>"`). The rest are model-invoked: describe what you want and the right skill loads automatically.

## Requirements

- Obsidian app running locally (the CLI talks to the live instance).
- `obsidian` CLI on `PATH`. On macOS, symlink it from the app bundle:
  ```bash
  ln -s /Applications/Obsidian.app/Contents/MacOS/obsidian-cli /usr/local/bin/obsidian
  ```
- `defuddle` CLI on `PATH` only if you use the `defuddle` skill.

## Configuration

The custom skills read these environment variables:

| Variable | Required | Purpose |
| --- | --- | --- |
| `OBSIDIAN_VAULT` | yes | Target vault name passed to every `obsidian` CLI call |
| `OBSIDIAN_1ON1_PATH` | no (default `Meetings/1 On 1s`) | Folder where 1:1 notes live (`obsidian-daily`) |
| `OBSIDIAN_PROJECTS_PATH` | no (default `Work/Projects`) | Parent folder for scaffolded projects (`obsidian-project-scaffold`) |

Set them in your shell rc:

```bash
export OBSIDIAN_VAULT="MyVault"
export OBSIDIAN_1ON1_PATH="People/1-1s"
```

Or in `~/.claude/settings.json`:

```json
{
  "env": {
    "OBSIDIAN_VAULT": "MyVault",
    "OBSIDIAN_1ON1_PATH": "People/1-1s"
  }
}
```

## Install

```
/plugin install obsidian@ai-plugins
```

## Attribution

Five skills (`obsidian-cli`, `obsidian-markdown`, `obsidian-bases`, `json-canvas`, `defuddle`) are vendored from [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) by Steph Ango, MIT licensed. Only `obsidian-cli/SKILL.md` was modified (added a note about the `OBSIDIAN_VAULT` env var convention). See [LICENSE](./LICENSE). The `obsidian-daily` skill is original.
