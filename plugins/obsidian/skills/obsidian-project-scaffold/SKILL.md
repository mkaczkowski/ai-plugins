---
name: obsidian-project-scaffold
description: Scaffold a lightweight project knowledge base in Obsidian — index, brief, resources, and meeting notes. Usage: /obsidian-project-scaffold new "<title>" [TICKET-123] [base/path]
argument-hint: 'new "<title>" [TICKET-123] [base/path]'
---

# Obsidian Project Scaffold

Creates a consistent, lightweight folder structure for a new project knowledge base, pre-populated with template files.

The scaffold is deliberately small: a project hub (`_index.md`), a single consolidated `Project Brief`, a living `Resources & Links` note, and a `meetings/` folder. Add deeper docs (design specs, canvases) by hand only when a project actually needs them.

## Conventions

- **`OBSIDIAN_VAULT` must be set.** If not, stop and tell the user to `export OBSIDIAN_VAULT="<name>"`.
- **`OBSIDIAN_PROJECTS_PATH`** sets the default parent folder. Defaults to `Work/Projects`.
- The first command must sanity-check: `: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"`.
- **Write file contents via temp files**, not inline `content="..."` strings. This keeps content readable and avoids quoting/escaping bugs.

Set them in `~/.zshrc`:

```bash
export OBSIDIAN_VAULT="MyVault"
export OBSIDIAN_PROJECTS_PATH="Work/Projects"  # optional
```

## Dispatch

| Arg | Action |
|-----|--------|
| `new "<title>" [TICKET] [path]` | Scaffold a new project folder |
| `list` | List existing projects at the default path |

**Argument parsing for `new`:**
- The **title** must be quoted: everything inside the quotes
- A token matching `[A-Z]+-\d+` (e.g. `PROJ-123`) anywhere after the title is the optional **ticket**
- A trailing path segment containing `/` is an optional **base path override**

Examples:
```
new "AI Agents with Structured Output" PROJ-123
new "Module Federation Research"
new "Auth Refactor" PROJ-999 Work/Personal/Projects
```

---

## Scaffold Routine

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
VAULT="$OBSIDIAN_VAULT"
BASE="${OBSIDIAN_PROJECTS_PATH:-Work/Projects}"

TITLE="<extracted title>"
TICKET="<extracted ticket, or empty>"
PROJECT_PATH="$BASE/$TITLE"
DATE=$(date +%Y-%m-%d)

# Slug for the moc tag: lowercase, spaces to hyphens, strip anything else
TAG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')

# Heading includes the ticket when provided
if [ -n "$TICKET" ]; then
  HEADING="$TICKET — $TITLE"
else
  HEADING="$TITLE"
fi
```

### 0 — Collision check

Before creating anything, check whether the project already exists:

```bash
if obsidian vault="$VAULT" read path="$PROJECT_PATH/_index.md" >/dev/null 2>&1; then
  echo "Project already exists at: $PROJECT_PATH"
  echo "Open it? (y/n)"
  # If user confirms, open the index. Otherwise abort.
  obsidian vault="$VAULT" open path="$PROJECT_PATH/_index.md"
  exit 0
fi
```

### 1 — `_index.md` (project hub)

Build the ticket tag line conditionally — omit it entirely when no ticket is provided to avoid a blank `- ` tag in frontmatter.

```bash
# Build optional ticket tag line
TICKET_TAG_LINE=""
if [ -n "$TICKET" ]; then
  TICKET_TAG_LINE="\n  - $(echo "$TICKET" | tr '[:upper:]' '[:lower:]')"
fi

cat > /tmp/project-index.md << CONTENT
---
tags:
  - moc
  - project
  - $TAG$TICKET_TAG_LINE
---

# $HEADING

> [!info] Status
> **Phase:** Planning
> **Target:** TBD
> **Owner:**

## Docs

- [[Project Brief]] — goals, scope, approach, milestones, risks
- [[Resources & Links]] — key links and rolling notes

## Meetings

- *(dated notes go in \`meetings/\`)*

---

## Open Questions

- [ ]
- [ ]
- [ ]
CONTENT

obsidian vault="$VAULT" create name="_index" path="$PROJECT_PATH" content="$(cat /tmp/project-index.md)"
```

### 2 — `Project Brief`

A single consolidated doc: overview, goals, scope, approach, milestones, and risks. This replaces the separate spec/design/risk documents — keep it short and grow sections only as needed.

```bash
JIRA_LINE=""
[ -n "$TICKET" ] && JIRA_LINE="\n**Ticket:** $TICKET"

cat > /tmp/project-brief.md << CONTENT
# $HEADING
$JIRA_LINE
**Status:** Draft
**Last Updated:** $DATE

---

## Overview

*One paragraph: what this is and why it matters. What problem does it solve, and for whom?*

## Goals & Success Metrics

*What does success look like? How will we know when we're done?*

- [ ]

## Scope

### In Scope

### Out of Scope

## Approach

*High-level plan or chosen direction. Link out to a deeper design doc only if the project needs one.*

## Milestones

| Milestone | Target | Status |
|---|---|---|
| M1 | | Planned |

## Risks & Open Questions

| Risk / Question | Owner | Status |
|---|---|---|
| | | Open |
CONTENT

obsidian vault="$VAULT" create name="Project Brief" path="$PROJECT_PATH" content="$(cat /tmp/project-brief.md)"
```

### 3 — `Resources & Links`

```bash
JIRA_LINK=""
[ -n "$TICKET" ] && JIRA_LINK="| **Ticket** | [$TICKET] |"

cat > /tmp/project-resources.md << CONTENT
# Resources & Links — $HEADING

> *Living document. Add links and notes as the project progresses.*

## Key Links

| Resource | Link |
|---|---|
$JIRA_LINK
| **Spec / Design** | |
| **Repo / PRs** | |

## Decisions Log

*(Record key decisions with dates as they happen)*

## Notes

CONTENT

obsidian vault="$VAULT" create name="Resources & Links" path="$PROJECT_PATH" content="$(cat /tmp/project-resources.md)"
```

### 4 — `meetings/` placeholder

Create a starter note so the folder exists and is visible from day one:

```bash
cat > /tmp/project-meetings.md << CONTENT
# Meeting Notes — $HEADING

Add dated meeting notes here. Naming convention:

\`YYYY-MM-DD <Topic>.md\`

Examples:
- \`2026-04-03 Kickoff.md\`
- \`2026-04-07 Design Review.md\`
CONTENT

obsidian vault="$VAULT" create name="_notes" path="$PROJECT_PATH/meetings" content="$(cat /tmp/project-meetings.md)"
```

### 5 — Open the index

```bash
obsidian vault="$VAULT" open path="$PROJECT_PATH/_index.md"
```

After scaffolding, report the full path and list the files created. Offer to open any specific file or immediately start filling in the Project Brief.

---

## List Routine

Search by the `project` tag — more specific than the shared `moc` tag, so it won't pick up daily notes or other maps of content:

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
BASE="${OBSIDIAN_PROJECTS_PATH:-Work/Projects}"
obsidian vault="$OBSIDIAN_VAULT" search:context query="tags: project" path="$BASE" limit=50
```

Present as a clean list of project names with their folder paths. If the search returns no results, remind the user that `_index.md` files must include `project` in their `tags` frontmatter to appear here.
