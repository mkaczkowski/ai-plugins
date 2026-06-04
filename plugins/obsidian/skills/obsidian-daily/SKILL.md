---
name: obsidian-daily
description: Obsidian daily workflow (morning standup, 1:1s, quick capture, end-of-day review, weekly review, vault health, search). Usage: /obsidian-daily [morning|1on1 <name>|capture <text>|eod|weekly|health|find <query>|tasks]
argument-hint: '[morning|1on1 <name>|capture <text>|eod|weekly|health|find <query>|tasks]'
---

# Obsidian Daily Workflow

Opinionated daily routines that drive the `obsidian` CLI. Requires Obsidian to be running. For raw CLI syntax, see the `obsidian-cli` skill.

## Conventions

- **`OBSIDIAN_VAULT` must be set.** If it is not, stop and tell the user to `export OBSIDIAN_VAULT="<name>"` in their shell rc.
- **Prefix every `obsidian` call with `vault="$OBSIDIAN_VAULT"`** as the first parameter. Bash blocks below omit the redundant guard for readability, but the first command in any routine should sanity-check: `: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"`.
- **1:1 folder** defaults to `Meetings/1 On 1s`, overridable via `OBSIDIAN_1ON1_PATH`.

Set them in `~/.zshrc` / `~/.bashrc`:

```bash
export OBSIDIAN_VAULT="MyVault"
export OBSIDIAN_1ON1_PATH="People/1-1s"   # optional
```

Or in `~/.claude/settings.json` under `env`.

## Dispatch

Parse arguments to pick a routine (default: `morning`):

| Arg | Routine |
| --- | --- |
| `morning` (or empty) | Morning routine |
| `1on1 <name>` | Before a 1:1 |
| `capture [text]` | Append text (or clipboard) to today's note |
| `eod` | End of day review |
| `weekly` | Weekly review |
| `health` | Vault health report |
| `find <query>` | Search vault |
| `tasks` | Show all open tasks |

---

## Morning Routine

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"

obsidian vault="$OBSIDIAN_VAULT" daily open
obsidian vault="$OBSIDIAN_VAULT" tasks todo verbose | head -30
obsidian vault="$OBSIDIAN_VAULT" recents limit=5

# Scaffold priorities if today's note is empty
if [ "$(obsidian vault="$OBSIDIAN_VAULT" daily:read 2>/dev/null | wc -w)" -lt 5 ]; then
  obsidian vault="$OBSIDIAN_VAULT" daily:append \
    content="## Priorities\n- [ ] \n- [ ] \n- [ ] \n\n## Notes\n"
fi
```

After running, summarize what's open and suggest a focus based on the task list.

---

## Before a 1:1

Extract the person's name from args (`1on1 Alexander` → `Alexander`).

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
ONE_ON_ONE_PATH="${OBSIDIAN_1ON1_PATH:-Meetings/1 On 1s}"
NAME="<extracted name>"
DATE=$(date +%Y-%m)
NOTE_NAME="$NAME - $DATE"
NOTE_PATH="$ONE_ON_ONE_PATH/$NOTE_NAME.md"

# Exact-path existence check (no fuzzy search)
if obsidian vault="$OBSIDIAN_VAULT" read path="$NOTE_PATH" >/dev/null 2>&1; then
  obsidian vault="$OBSIDIAN_VAULT" open path="$NOTE_PATH"
else
  obsidian vault="$OBSIDIAN_VAULT" create name="$NOTE_NAME" path="$ONE_ON_ONE_PATH" \
    content="## $NAME, $DATE\n\n### Notes\n\n### Action items\n- [ ] " open
fi

# Prior action items across all 1:1s with this person
obsidian vault="$OBSIDIAN_VAULT" search:context \
  query="$NAME Action items" path="$ONE_ON_ONE_PATH" limit=10
```

Report whether a note was opened or created, then present the prior action-item hits for context.

---

## Quick Capture

Extract the text from args (`capture fix the relay bug` → `fix the relay bug`). With no text, append clipboard.

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
TEXT="<extracted text, or $(pbpaste) if empty>"
obsidian vault="$OBSIDIAN_VAULT" daily:append content="- $TEXT"
```

Confirm what was appended and show today's note path via `obsidian vault="$OBSIDIAN_VAULT" daily:path`.

---

## End of Day

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"

printf '\n=== Today'\''s open tasks ===\n'
obsidian vault="$OBSIDIAN_VAULT" tasks daily todo verbose

printf '\n=== Completed today ===\n'
obsidian vault="$OBSIDIAN_VAULT" tasks daily done

obsidian vault="$OBSIDIAN_VAULT" daily:append content="\n## Tomorrow\n- [ ] "

printf '\n=== Vault health ===\n'
printf 'Open tasks (total): %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" tasks todo total)"
printf 'Unresolved links:   %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" unresolved total)"
```

Summarize what was completed, what's still open, then wish the user a good evening.

---

## Weekly Review

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"

printf '\n=== All open tasks ===\n'
obsidian vault="$OBSIDIAN_VAULT" tasks todo verbose

printf '\n=== Orphaned notes ===\n'
obsidian vault="$OBSIDIAN_VAULT" orphans | head -20

printf '\n=== Broken links ===\n'
obsidian vault="$OBSIDIAN_VAULT" unresolved verbose

printf '\n=== Vault stats ===\n'
printf 'Total files: %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" vault info=files)"
printf 'Open tasks:  %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" tasks todo total)"
printf 'Orphans:     %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" orphans total)"
printf 'Unresolved:  %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" unresolved total)"
```

Brief summary with suggestions: orphans > 20 → cleanup session; tasks > 50 → grooming session.

---

## Vault Health

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
printf 'Total files: %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" vault info=files)"
printf 'Open tasks:  %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" tasks todo total)"
printf 'Orphans:     %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" orphans total)"
printf 'Unresolved:  %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" unresolved total)"
printf 'Deadends:    %s\n' "$(obsidian vault="$OBSIDIAN_VAULT" deadends total)"
```

If unresolved > 0, run `obsidian vault="$OBSIDIAN_VAULT" unresolved verbose` and offer to fix broken links.

---

## Find / Search

Extract the query from args (`find module federation` → `module federation`).

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
QUERY="<extracted query>"
obsidian vault="$OBSIDIAN_VAULT" search:context query="$QUERY" limit=10
```

Present results cleanly and offer to open any matching note.

---

## Show All Tasks

```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set}"
obsidian vault="$OBSIDIAN_VAULT" tasks todo verbose
printf '\nTotal: %s open tasks\n' "$(obsidian vault="$OBSIDIAN_VAULT" tasks todo total)"
```

Group output by folder when presenting to the user.
