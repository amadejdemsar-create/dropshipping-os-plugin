# Dropshipping OS for Claude Code and Codex

The `dropshipping-os` plugin connects Claude Code or Codex to Dropshipping OS (`https://dropshipping.nativeai.agency/api/mcp`), signed in as you with your Dropshipping OS account, and adds the team skills: `visualize`, `web-research`, `prompt-writer`, `ad-copywriter`, `premortem`, `grill-me`, `avatar-walkthrough`, `team-work`, `team-expenses` and `video-watch`. Claude Code also gets the `video-analyst` agent.

The plugin holds no credentials. You need a Dropshipping OS account to sign in.

## Claude Code

```
claude plugin marketplace add amadejdemsar-create/dropshipping-os-plugin
claude plugin install dropshipping-os@dropshipping-os
```

Start Claude Code, run `/mcp`, pick `plugin:dropshipping-os:dropshipping-os` and sign in. Then ask: "List my Dropshipping OS products."

## Codex

```
codex plugin marketplace add amadejdemsar-create/dropshipping-os-plugin
codex plugin add dropshipping-os@dropshipping-os
codex mcp login dropshipping-os
```

Codex loads the ten skills and the same server. The `video-analyst` agent is Claude Code only; in Codex `video-watch` runs its steps in the main session.

## Updating from 1.1.x (token setup)

After you update to 1.2.0 the plugin no longer asks for a token. The first Dropshipping OS tool call opens a browser to sign in, once. The old `dsos_token` and `dsos_url` plugin options are ignored; you can leave them.

A token you added yourself with `claude mcp add ... --header "Authorization: Bearer ..."` keeps working until you remove it, and Claude Code then uses that connection instead of the plugin's. Remove it with `claude mcp remove dropshipping-os` when you want to switch to the sign-in.

## Without the plugin

```
claude mcp add --transport http dropshipping-os https://dropshipping.nativeai.agency/api/mcp
codex mcp add dropshipping-os --url https://dropshipping.nativeai.agency/api/mcp
```

This gives the tools but not the team skills. Any other client that supports remote MCP with OAuth connects to the same URL.

## What stays with a person

Every change is recorded with your name, the client and the time. An agent cannot review creatives, publish ads, order goods, change spend, or create or revoke tokens.
