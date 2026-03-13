## Context

Sid runs as a ZeroClaw daemon on a NixOS mini PC (`mini`). The service is systemd-hardened with strict sandboxing (ProtectSystem=strict, ProtectHome=tmpfs, CapabilityBoundingSet="", etc.). Currently, autonomy is enforced by a command whitelist in config.toml (`allowed_commands`), and the skills/docs reflect the original sysadmin-monitoring persona. Sid now operates as a general-purpose assistant across email, XMPP, Telegram, and calendar (via MCP), and the configuration needs to match.

## Goals / Non-Goals

**Goals:**
- Align skills and docs with Sid's actual role as a general-purpose assistant
- Shift autonomy from command whitelist to systemd sandbox (equivalent security, more flexibility)
- Add morning briefing capability using existing MCP integrations
- Expand PATH so Sid can use common Unix tools without hitting whitelist errors

**Non-Goals:**
- Changing Sid's identity, persona, or voice (IDENTITY.md, SOUL.md unchanged)
- Adding new MCP servers or channels
- Modifying systemd hardening (sandbox stays as-is)
- Adding Home Assistant / voice integration (future work)
- Changing email or MCP skills

## Decisions

### 1. Empty `allowed_commands` instead of removing the field
Setting `allowed_commands = []` means "allow all commands in PATH" in ZeroClaw. This is cleaner than removing the field entirely (which might trigger a serde default). The systemd sandbox is the real security boundary — ProtectSystem=strict prevents writes outside stateDir, ProtectHome=tmpfs hides /home, and CapabilityBoundingSet="" drops all capabilities.

**Alternative considered**: Expanding the whitelist to include new tools. Rejected because it's a maintenance burden that doesn't add security — the sandbox already constrains what commands can do.

### 2. Minimal `forbidden_paths`
Reduce from `["/etc", "/root", "/sys", "~/.ssh", "~/.gnupg", "~/.aws"]` to `["/root"]`. The systemd sandbox already makes most of these inaccessible (ProtectHome=tmpfs hides home dirs, ProtectSystem=strict makes /etc read-only). Keeping `/root` is belt-and-suspenders since root's home might not be covered by ProtectHome.

### 3. Morning briefing as a watchdog mode, not a separate skill
The `/watchdog` skill already has severity classification, cooldown tracking, state persistence, and email delivery. Rather than creating a separate briefing skill, we retool `/watchdog` to add "morning briefing" as a scheduled check alongside alerting. The heartbeat triggers it; watchdog decides if a briefing is due based on state.

### 4. `/cynic` pulls data from MCP tools, not just shell
The life status report uses mcp-dav for calendar and axios-ai-mail for email counts. These are already available via `mcp-gw`. Shell commands still used for hardware stats (the secondary "insult" section) and system uptime.

### 5. New PATH packages as Nix expressions
Add packages directly to the `path` list in `systemd.services.zeroclaw`. This is idiomatic NixOS and ensures they're available in the service's namespace without polluting the system PATH.

## Risks / Trade-offs

- **[Wider command access]** → Mitigated by systemd sandbox. `block_high_risk_commands = false` is already set; the sandbox is what actually prevents damage. `curl` in PATH does expand network access from shell, but Sid already has `web_fetch` tool and network access for API calls.
- **[Morning briefing depends on MCP availability]** → If mcp-dav or axios-ai-mail are down, watchdog should degrade gracefully — skip that section of the briefing rather than failing entirely. The skill instructions will specify this.
- **[Weather via web_fetch is fragile]** → Public weather APIs change. The skill should use a simple, well-known endpoint (e.g., wttr.in) and handle fetch failures gracefully.
- **[State file format changes for watchdog]** → New fields added to `.watchdog-state.json`. Old state files will be missing new fields — watchdog should treat missing fields as defaults (first run).

## Migration Plan

1. Commit all file changes to sid repo
2. Push to trigger nixos-config update
3. Run `nix flake lock --update-input sid` in `~/.config/nixos_config/`
4. Run `nixos-rebuild switch --flake .#mini`
5. Verify service starts: `systemctl status zeroclaw`
6. Test `/cynic` and `/watchdog` via Telegram or XMPP
7. Rollback: revert commit, rebuild — previous config.toml and skills restored from Nix store
