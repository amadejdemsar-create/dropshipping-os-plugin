# Dropshipping OS for Claude Code

The `dropshipping-os` plugin connects Claude Code to Dropshipping OS (`https://dropshipping.nativeai.agency/api/mcp`), signed in with your personal token, and adds the team skills: `visualize`, `web-research`, `prompt-writer`, `ad-copywriter`, `premortem`, `grill-me`, `avatar-walkthrough`, `team-work`, `team-expenses`, `video-watch`, and the `video-analyst` agent.

The plugin holds no credentials. You need a Dropshipping OS account to get a token.

## Install

1. In Dropshipping OS open **AI and skills**, then **Connection**, then **New token**. Choose **Claude Code** and copy the token (it is shown once).
2. In a terminal:

```
claude plugin marketplace add amadejdemsar-create/dropshipping-os-plugin
claude plugin install dropshipping-os@dropshipping-os
```

Claude Code asks for the token and the address (keep the default address). Change them later with `/plugin configure dropshipping-os@dropshipping-os`.
3. Restart Claude Code and ask: "List my Dropshipping OS products."

## Without the plugin

```
claude mcp add --scope user --transport http dropshipping-os https://dropshipping.nativeai.agency/api/mcp --header "Authorization: Bearer <your token>"
```

This gives the tools but not the team skills. The token stays in your shell history with this command, so prefer the plugin.

## What stays with a person

Every change is recorded with your name, the client and the time. An agent cannot review creatives, publish ads, order goods, change spend, or create or revoke tokens.
