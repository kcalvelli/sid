## Why

Sid evolved from a cranky sysadmin bot monitoring a dev machine into a general-purpose assistant running on a headless mini PC — handling email, calendar, XMPP, Telegram, and soon Home Assistant voice. The skills (`/cynic`, `/watchdog`), workspace docs (`HEARTBEAT.md`, `TOOLS.md`), and NixOS service config are still oriented around hardware monitoring and a command whitelist. They need to catch up to what Sid actually does now.

## What Changes

- **Rewrite `/cynic` skill**: Replace hardware diagnostics with a "life status report" — calendar events (mcp-dav), unread email (axios-ai-mail MCP), memory stats, channel status, uptime. Keep hardware insult section as secondary. Same BASIC listing format and bitter commentary.
- **Rewrite `/watchdog` skill**: Replace sysadmin hardware monitor with a household morning briefing + alert system. Monitor calendar (mcp-dav), weather for McAdenville NC (web_fetch), unread email (MCP), service health. Keep severity/cooldown/quiet-hours framework. Morning briefing email sent daily after 06:30.
- **Update `HEARTBEAT.md`**: Add morning briefing task ("Run /watchdog to check if a morning briefing is due").
- **Update `TOOLS.md`**: Document sandbox-based security model (not command whitelist), document new tools in PATH (curl, python3, tar, dig, etc.).
- **Loosen ZeroClaw autonomy config**: `allowed_commands = []` (empty = allow all in PATH), `forbidden_paths = ["/root"]` (minimal, systemd sandbox handles the rest).
- **Expand systemd service PATH**: Add curl, python3, gnutar, gzip, inetutils (ping), dnsutils (dig), file, tree.

### What stays the same
- All systemd hardening (ProtectSystem, ProtectHome, NoNewPrivileges, CapabilityBoundingSet, etc.)
- sid user stays isSystemUser with /sbin/nologin
- max_actions_per_hour = 60, max_cost_per_day_cents = 1000
- Email skill, MCP skill unchanged
- IDENTITY.md, SOUL.md, USER.md, AGENTS.md unchanged

## Capabilities

### New Capabilities
- `morning-briefing`: Daily household briefing system — weather, calendar, email summary, service health — sent via email after 06:30 with severity-based alerting for critical items (severe weather).

### Modified Capabilities
_(No existing spec-level requirements are changing — the changes are to skills, workspace docs, and deployment config, not to capabilities tracked in `openspec/specs/`.)_

## Impact

- **Files touched**: `skills/cynic/SKILL.md`, `skills/watchdog/SKILL.md`, `workspace/HEARTBEAT.md`, `workspace/TOOLS.md`, `modules/nixos/default.nix`
- **Service restart required**: Yes (config.toml changes, PATH expansion)
- **NixOS rebuild required**: Yes (`nix flake lock --update-input sid` + `nixos-rebuild switch`)
- **Security posture**: Shifts from command whitelist to systemd sandbox as primary boundary. Net security is equivalent — systemd hardening (ProtectSystem=strict, ProtectHome=tmpfs, CapabilityBoundingSet="", etc.) prevents access to sensitive paths regardless of which commands are available.
- **New dependencies in PATH**: curl, python3, gnutar, gzip, inetutils, dnsutils, file, tree
- **MCP dependencies**: mcp-dav (calendar), axios-ai-mail (email) — accessed via existing mcp-gw integration, no config changes needed
