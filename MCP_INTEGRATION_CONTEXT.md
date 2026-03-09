# MCP Gateway Integration for Sid — Continuation Context

## What We're Doing
Wiring `mcp-gw` CLI into Sid's ZeroClaw service so Sid can call MCP tools (email, GitHub, web search, calendar, etc.) via the MCP Gateway running on edge.

## Current Problem
`mcp-gw` is in Sid's PATH but hits `localhost:8085` (no servers) instead of the remote gateway. ZeroClaw sanitizes env vars from subprocesses, so `MCP_GATEWAY_URL` set on the systemd service doesn't reach `mcp-gw`.

### Fix Already Committed (may not be deployed)
- **sid repo** (`e78871a`): Added `mcpGatewayPackage` and `mcpGatewayUrl` options to `modules/nixos/default.nix`. When both are set, a wrapper script is generated that bakes the URL into `mcp-gw` via `export MCP_GATEWAY_URL=... && exec .../mcp-gw "$@"`.
- **nixos_config** (`3ea6a96`): `hosts/mini.nix` sets `mcpGatewayPackage = pkgs.mcp-gateway;` and `mcpGatewayUrl = "https://axios-mcp-gateway.taile0fb4.ts.net";`

### What to Verify
1. Check sid input is up to date: `nix flake lock --update-input sid` in `~/.config/nixos_config`
2. Rebuild: `sudo nixos-rebuild switch --flake ~/.config/nixos_config#mini`
3. Restart: `sudo systemctl restart zeroclaw`
4. Check the wrapper is in the service PATH:
   ```bash
   sudo cat /proc/$(pgrep -f "zeroclaw daemon")/environ | tr '\0' '\n' | grep '^PATH=' | tr ':' '\n' | grep mcp
   ```
   Should show a `writeShellScriptBin` store path, NOT `mcp-gateway-0.1.0/bin`.
5. If still showing the raw package, the wrapper Nix logic may need debugging. Check `modules/nixos/default.nix` around line 357.

### How to Test
```bash
# As sid user (simulates what ZeroClaw does)
sudo -u sid bash -c 'mcp-gw list'

# Should show connected servers, NOT all disconnected
# If all disconnected, the URL isn't baked in — check which binary:
sudo -u sid bash -c 'which mcp-gw && head -5 $(which mcp-gw)'
```

### Working Manual Test (proves network/DNS are fine)
```bash
sudo -u sid bash -c 'export MCP_GATEWAY_URL=https://axios-mcp-gateway.taile0fb4.ts.net && mcp-gw list'
# This works — returns connected servers
```

## Key Files
- `/home/keith/Projects/sid/modules/nixos/default.nix` — Sid NixOS module (wrapper logic ~line 357)
- `/home/keith/Projects/sid/skills/mcp/SKILL.md` — MCP skill for Sid
- `~/.config/nixos_config/hosts/mini.nix` — mini host config (sid service options ~line 155)
- `/home/keith/Projects/mcp-gateway/src/mcp_gateway/cli.py` — mcp-gw CLI source

## Service Details
- Systemd service name: `zeroclaw` (NOT `sid`)
- User: `sid`, HOME: `/var/lib/sid`
- Shell: nologin (use `sudo -u sid bash -c '...'`)
- Gateway URL: `https://axios-mcp-gateway.taile0fb4.ts.net`
- `pkgs.mcp-gateway` comes from axios overlay (`inputs.mcp-gateway.overlays.default`)
