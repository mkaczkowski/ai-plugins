---
name: obsidian-epic-scaffold
description: Scaffold a structured epic/topic knowledge base in Obsidian with design, visual, reference, and meetings folders. Usage: /obsidian-epic-scaffold new "<title>" [TICKET-123] [base/path]
argument-hint: 'new "<title>" [TICKET-123] [base/path]'
---

# Obsidian Epic Scaffold

Creates a consistent folder structure for a new epic or topic knowledge base, pre-populated with template files.

## Conventions

- **`OBSIDIAN_VAULT` must be set.** If not, stop and tell the user to `export OBSIDIAN_VAULT="<name>"`.
- **`OBSIDIAN_EPICS_PATH`** sets the default parent folder. Defaults to `Work/Epics`.
- The first command must sanity-check: `: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"`.
- **Write file contents via temp files**, not inline `content="..."` strings. This keeps content readable and avoids quoting/escaping bugs.

Set them in `~/.zshrc`:

```bash
export OBSIDIAN_VAULT="MyVault"
export OBSIDIAN_EPICS_PATH="Work/Epics"  # optional
```

## Dispatch

| Arg | Action |
|-----|--------|
| `new "<title>" [TICKET] [path]` | Scaffold a new epic folder |
| `list` | List existing epics at the default path |

**Argument parsing for `new`:**
- The **title** must be quoted: everything inside the quotes
- A token matching `[A-Z]+-\d+` (e.g. `PROJ-123`) anywhere after the title is the optional **ticket**
- A trailing path segment containing `/` is an optional **base path override**

Examples:
```
new "AI Agents with Structured Output" PROJ-123
new "Module Federation Research"
new "Auth Refactor" PROJ-999 Work/Personal/Epics
```

---

## Scaffold Routine

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
VAULT="$OBSIDIAN_VAULT"
BASE="${OBSIDIAN_EPICS_PATH:-Work/Epics}"

TITLE="<extracted title>"
TICKET="<extracted ticket, or empty>"
EPIC_PATH="$BASE/$TITLE"
DATE=$(date +%Y-%m-%d)

# Slug for the moc tag: lowercase, spaces to hyphens
TAG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Heading and HLD name depend on whether a ticket was provided
if [ -n "$TICKET" ]; then
  HEADING="$TICKET — $TITLE"
  HLD_NAME="HLD - $TICKET"
else
  HEADING="$TITLE"
  HLD_NAME="HLD - $TITLE"
fi
```

### 0 — Collision check

Before creating anything, check whether the epic already exists:

```bash
if obsidian vault="$VAULT" read path="$EPIC_PATH/_index.md" >/dev/null 2>&1; then
  echo "Epic already exists at: $EPIC_PATH"
  echo "Open it? (y/n)"
  # If user confirms, open the index. Otherwise abort.
  obsidian vault="$VAULT" open path="$EPIC_PATH/_index.md"
  exit 0
fi
```

### 1 — `_index.md` (MOC)

Build the ticket tag line conditionally — omit it entirely when no ticket is provided to avoid a blank `- ` tag in frontmatter.

```bash
# Build optional ticket tag line
TICKET_TAG_LINE=""
if [ -n "$TICKET" ]; then
  TICKET_TAG_LINE="\n  - $(echo "$TICKET" | tr '[:upper:]' '[:lower:]')"
fi

cat > /tmp/epic-index.md << CONTENT
---
tags:
  - moc
  - epic
  - $TAG$TICKET_TAG_LINE
---

# $HEADING

> [!info] Status
> **Phase:** Planning
> **Target:** TBD
> **Authors:**

## Design

- [[design/$HLD_NAME]] — technical design with estimates and risks
- [[design/Product Spec - $TITLE]] — PRD: scope, user stories, milestones
- [[design/Prerequisites & Risks]] — prerequisite status and risk register

## Visual

- *(add canvas files to \`visual/\` as needed)*

## Reference

- [[reference/Resources & Links]] — key links, chosen approach, rolling notes

## Meetings

- *(meeting notes go in \`meetings/\`)*

---

## Chosen Approach

*TBD*

## Open Questions

- [ ]
- [ ]
- [ ]
CONTENT

obsidian vault="$VAULT" create name="_index" path="$EPIC_PATH" content="$(cat /tmp/epic-index.md)"
```

### 2 — `design/HLD`

```bash
cat > /tmp/epic-hld.md << CONTENT
## Document Metadata

| Field | Value |
|---|---|
| **Project** | $TICKET |
| **Authors (FE)** | |
| **Authors (BE)** | |
| **Last Updated** | $DATE |
| **Next Steps** | |

## Reviewers

| Name | Role | Status |
|---|---|---|
| | | Pending |

---

## 1. Scope and Goals

### In Scope

### Out of Scope

### Assumptions

---

## 2. High-Level Design

### Architecture Overview

### Data Flow

---

## 3. Key Technical Decisions

| Decision | Rationale |
|---|---|
| | |

---

## 4. Estimates

### Frontend

| # | Component | Estimate | Notes |
|---|---|---|---|
| | | | |
| | **FE Total** | | |

### Backend

| # | Component | Estimate | Notes |
|---|---|---|---|
| | | | |
| | **BE Total** | | |

---

## 5. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| | | | |

---

## Appendix: Key Files

\`\`\`
# Add relevant file paths here
\`\`\`
CONTENT

obsidian vault="$VAULT" create name="$HLD_NAME" path="$EPIC_PATH/design" content="$(cat /tmp/epic-hld.md)"
```

### 3 — `design/Product Spec`

Only include the Jira line when a ticket was provided:

```bash
JIRA_LINE=""
[ -n "$TICKET" ] && JIRA_LINE="\n**Jira:** $TICKET"

cat > /tmp/epic-spec.md << CONTENT
# $HEADING
$JIRA_LINE
**Status:** Draft
**Last Updated:** $DATE

---

## Overview

*One paragraph summary of the feature.*

## Problem

*What problem does this solve? Who is affected?*

## Solution

*High-level description of the proposed solution.*

## User Stories

### User Story 1

| Field | Value |
|---|---|
| **As a** | |
| **I want to** | |
| **So that** | |

**Acceptance Criteria:**
- [ ]

---

## Milestones

| Milestone | Ticket | Scope | Priority | Status |
|---|---|---|---|---|
| M1 | $TICKET | | P0 | Planned |

## Out of Scope

## Open Questions

- [ ]
CONTENT

obsidian vault="$VAULT" create name="Product Spec - $TITLE" path="$EPIC_PATH/design" content="$(cat /tmp/epic-spec.md)"
```

### 4 — `design/Prerequisites & Risks`

```bash
cat > /tmp/epic-prereqs.md << CONTENT
# Prerequisites & Risks — $HEADING

## Prerequisites

| Prerequisite | Owner | Ticket | Priority | Blocks | Status |
|---|---|---|---|---|---|
| | | | P0 | | Pending |

## Risks

| Risk | Likelihood | Impact | Owner | Status | Mitigation |
|---|---|---|---|---|---|
| | Medium | High | | Active | |
CONTENT

obsidian vault="$VAULT" create name="Prerequisites & Risks" path="$EPIC_PATH/design" content="$(cat /tmp/epic-prereqs.md)"
```

### 5 — `reference/Resources & Links`

```bash
JIRA_LINK=""
[ -n "$TICKET" ] && JIRA_LINK="| **Jira Epic** | [$TICKET] |"

cat > /tmp/epic-resources.md << CONTENT
# Resources & Links — $HEADING

> *Living document. Add links and notes as the epic progresses.*

## Key Links

| Resource | Link |
|---|---|
$JIRA_LINK
| **Product Spec** | |
| **Design Specs** | |
| **HLD** | |

## Decisions Log

*(Record key decisions with dates as they happen)*

## Notes

CONTENT

obsidian vault="$VAULT" create name="Resources & Links" path="$EPIC_PATH/reference" content="$(cat /tmp/epic-resources.md)"
```

### 6 — `meetings/` placeholder

Create a starter note so the folder exists and is visible from day one:

```bash
cat > /tmp/epic-meetings.md << CONTENT
# Meeting Notes — $HEADING

Add dated meeting notes here. Naming convention:

\`YYYY-MM-DD <Topic>.md\`

Examples:
- \`2026-04-03 Alignment with Extract Team.md\`
- \`2026-04-07 AMS Knowledge Transfer.md\`
CONTENT

obsidian vault="$VAULT" create name="_notes" path="$EPIC_PATH/meetings" content="$(cat /tmp/epic-meetings.md)"
```

### 7 — Open the index

```bash
obsidian vault="$VAULT" open path="$EPIC_PATH/_index.md"
```

After scaffolding, report the full path and list the files created. Offer to open any specific file or immediately start filling in the HLD.

---

## List Routine

Search by the `moc` tag — more reliable than content matching:

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
BASE="${OBSIDIAN_EPICS_PATH:-Work/Epics}"
obsidian vault="$OBSIDIAN_VAULT" search:context query="tags: moc" path="$BASE" limit=50
```

Present as a clean list of epic names with their folder paths. If the search returns no results, remind the user that `_index.md` files must include `moc` in their `tags` frontmatter to appear here.
