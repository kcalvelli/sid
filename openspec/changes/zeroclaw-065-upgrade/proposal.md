## Why

ZeroClaw v0.6.5 delivers agent reliability improvements (context overflow recovery, preemptive context checks, graceful shutdown on iteration limits), gateway hardening (auth rate limiting, per-session actor queues), and channel robustness (message debouncing, Matrix E2EE recovery). These directly address Sid's pain points as a long-running daemon on API billing: context blowouts waste money, concurrent channel messages cause race conditions, and there's no recovery when the agent hits limits. The upgrade also absorbs 10 of our 22 patches — reducing rebase surface by 45% and moving toward a maintainable patch set of only custom Sid functionality.

## What Changes

- **BREAKING**: Bump ZeroClaw from v0.6.3 to v0.6.5 (new `cargoHash`, `npmDepsHash`, source rev)
- **Drop 10 patches** that are now upstreamed or obsolete:
  - 0001 (futures/async-stream deps — build fix, no longer needed)
  - 0002 (ISO-8601 timestamps — native `ChannelMessage.timestamp`)
  - 0010 (Telegram context prefix — native Channel Capabilities system)
  - 0011 (Claude Code capabilities — default is correct)
  - 0013 (/api/swarm endpoint — MCP server removed, swarm not configured)
  - 0015 (swarm agentic loop — swarm not configured)
  - 0016 (canvas WebSocket subprotocol — upstreamed)
  - 0017 (canvas store sharing — upstreamed)
  - 0019 (cross-channel Telegram awareness — native Channel Capabilities)
  - 0020 (strip anthropic/ prefix — upstreamed)
- **Keep 12 patches** (10 main + 2 desktop), renumber 0001-0012
- **Remove zeroclaw MCP server**: delete `mcp-servers/zeroclaw/` directory and `zeroclaw-mcp` derivation from flake.nix (not in `mcp-gw list`, all tools native)
- **Remove dead MCP skill docs**: `skills/mcp/SKILL.md` and `workspace/skills/mcp/SKILL.md`
- **Clean up TOOLS.md**: remove all `mcp-gw call zeroclaw` examples (memory, pushover, cron, xmpp), add shell redirect warning (`>`, `<`, `2>&1` blocked by security policy)
- **Update PWA overlay**: rebuild `npmDepsHash` for updated web frontend (chat history persistence)
- **Rebase remaining patches** onto v0.6.5 source

## Capabilities

### New Capabilities
- `zeroclaw-065-rebase`: Version bump, patch drop/renumber/rebase, hash updates, and build validation

### Modified Capabilities
- `patch-management`: Patch inventory changes from 22 to 12; renumbering scheme; dropped patch rationale
- `web-pwa`: npmDepsHash update for v0.6.5 web frontend changes
- `tauri-desktop-package`: cargoHash update, desktop patches rebase onto v0.6.5

### Removed Capabilities
- `swarm-mcp-bridge`: Swarm not configured, MCP server removed
- `zeroclaw-mcp-cron`: Native cron tools replace MCP path
- `zeroclaw-mcp-memory`: Native memory tools replace MCP path
- `zeroclaw-mcp-pushover`: Native pushover tool replaces MCP path
- `zeroclaw-mcp-xmpp`: Native XMPP tools replace MCP path

## Impact

- **flake.nix**: ZeroClaw input rev, `cargoHash`, `npmDepsHash`, patch list, remove `zeroclaw-mcp` derivation
- **patches/**: Delete 10 .patch files, renumber remaining 12 as 0001-0012
- **mcp-servers/zeroclaw/**: Delete entire directory
- **skills/mcp/**: Delete MCP skill docs
- **workspace TOOLS.md**: Remove dead MCP examples, add redirect warning
- **NixOS module**: No changes expected (config.toml generation unchanged)
- **Build validation**: Full `nix build` required — cargoHash and npmDepsHash will need updating after rebase
