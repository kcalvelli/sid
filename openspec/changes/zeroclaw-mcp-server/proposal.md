## Why

Switching Sid's default provider from `anthropic` to `claude-code` routes inference through the Claude subscription instead of API billing, but loses access to ZeroClaw's native tool registry. Claude Code runs its own agent loop with its own built-in tools — ZeroClaw's memory, cron, XMPP send, and pushover tools are never invoked. An MCP server that bridges ZeroClaw's existing gateway REST API to Claude Code restores these capabilities without reverting to API billing.

## What Changes

- New MCP server (`mcp-servers/zeroclaw/`) that proxies ZeroClaw's gateway API endpoints as MCP tools
- Memory tools: store, recall, forget — backed by ZeroClaw's existing `/api/memory` endpoints
- Cron tools: list, add, remove, run — backed by ZeroClaw's existing `/api/cron` endpoints
- XMPP send: send messages to XMPP rooms/users — requires a new lightweight XMPP client (no existing gateway endpoint)
- Pushover notifications: send push alerts — direct HTTP POST to Pushover API
- NixOS module updates to wire the MCP server into the systemd service
- New Claude Code skill file documenting the available tools

## Capabilities

### New Capabilities
- `zeroclaw-mcp-memory`: MCP tools for persistent memory (store, recall, forget) proxying ZeroClaw's gateway memory API
- `zeroclaw-mcp-cron`: MCP tools for cron/scheduling (list, add, remove, run) proxying ZeroClaw's gateway cron API
- `zeroclaw-mcp-xmpp`: MCP tool for sending XMPP messages (direct client, not gateway-proxied)
- `zeroclaw-mcp-pushover`: MCP tool for sending Pushover push notifications

### Modified Capabilities
<!-- No existing spec-level requirements are changing -->

## Impact

- **New code**: `mcp-servers/zeroclaw/` — MCP server implementation (language TBD in design, likely Python or TypeScript for MCP SDK availability)
- **NixOS module**: `modules/nixos/default.nix` — add MCP server to service PATH, configure gateway URL and credentials
- **Skills**: New skill file documenting the MCP tools for Claude Code's context
- **Dependencies**: MCP SDK, XMPP client library, Pushover API (HTTP only)
- **Config**: Gateway URL (`localhost:{port}`), XMPP credentials (reuse existing), Pushover API token (new secret)
