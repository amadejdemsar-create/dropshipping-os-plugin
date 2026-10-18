---
name: team-work
description: Tasks and time across NativeAI and Dropshipping. Use when someone asks for their tasks or the team's ("show my tasks across NativeAI and dropshipping", "what is Maks working on"), wants to create, assign, reschedule, comment on or archive a task, or logs time ("log 45 minutes on this task"). Works with NativeAI OS or Dropshipping OS connected; both share the same tools.
---

# Team work: tasks and time

The tools come from NativeAI OS or Dropshipping OS (the same names in both): `workspaces`, `team_tasks`, `team_task_get`, `team_task_create`, `team_task_update`, `team_task_comment`, `team_time_log`, `team_time_void`. They act as the signed-in person and record every change as "<person> via <your tool>". If a call says the person must sign in, tell them how (Claude Code: `/mcp`, pick the OS and sign in; Codex: `codex mcp login <server>`) and stop.

## Rules that never bend

1. **One business per record.** Every task belongs to `nativeai` or `dropshipping`. Lists say which; writes must name it. When the request does not make the business clear (for example "add a task to call the supplier" while both are linked), ask which business, in one short question. Never guess.
2. **People are ids, resolved per business.** Call `workspaces` once per conversation. It lists each business's members with their ids. Map a name the person said to a member of THAT business. If exactly one member matches, use them. If none or several match, ask. The same person in the other business is the one with a matching `linkedId`; never assume two accounts are the same person because the names match.
3. **"Across both" is explicit.** Pass `scope: "both"` only when the person asks for both businesses (or "everything", "all my tasks"). If `sources` says one business did not answer or is not linked, say so in one line; never present the missing part as empty.
4. **Retries never duplicate.** Give every write a fresh `idempotencyKey` (a random id). If a write times out or fails with a network error, retry with the SAME key. After any error you did not understand, read the item back before trying again.
5. **Changes carry the version you read.** `team_task_update` needs `expectedVersion` from your last read. On CONFLICT, read the task again, tell the person what changed, and only then apply their change if it still makes sense.

## Common requests

- **"Show my tasks across NativeAI and dropshipping"**: `team_tasks` with `scope: "both"`, `assignee: "me"`, statuses todo, doing, blocked. Group by business label, then overdue, today, this week, later. Name tasks by title, never by id. Dates as D. M.; Slovenian when the person writes Slovenian.
- **"Assign this NativeAI task to Leon with a deadline Friday"**: resolve the task (by the one discussed, or `team_tasks` with `q`), resolve Leon in the NativeAI members, compute the date (Europe/Ljubljana), then `team_task_update` with `assignee`, `due` and `expectedVersion`. Confirm in one line: task, person, date.
- **"Log 45 minutes against this task"**: `team_time_log` with `minutes: 45`, today's date unless they named one, a short note only if they gave one. Time is always logged for the signed-in person.
- **Workload ("who is doing what")**: `team_tasks` without `assignee`, then per person: open, overdue, estimated minutes, minutes logged this week. Always add: "Completed-task counts do not measure productivity: tasks differ in size, and much useful work is not a task." Do not rank people.
- **Archive, comment, status, priority, estimate**: the matching field of `team_task_update`, or `team_task_comment`.
- **A wrong time entry**: `team_time_void` with the reason the person gave. It stays in history.

Change nothing the person did not ask for. After a write, say what changed in one line.
