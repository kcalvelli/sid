## 1. NixOS Module — Autonomy & PATH

- [x] 1.1 Update `[autonomy]` section in configToml: set `allowed_commands = []`, set `forbidden_paths = ["/root"]`
- [x] 1.2 Add packages to systemd service `path`: curl, python3, gnutar, gzip, inetutils, dnsutils, file, tree

## 2. Skill Rewrites

- [x] 2.1 Rewrite `skills/cynic/SKILL.md` — life status report (calendar via mcp-dav, email count via axios-ai-mail MCP, memory stats, channel status, uptime; hardware insult section secondary)
- [x] 2.2 Rewrite `skills/watchdog/SKILL.md` — household morning briefing + alert system (weather for McAdenville NC via web_fetch, calendar via mcp-dav, email summary via MCP, service health; severity/cooldown/quiet-hours framework retained; morning briefing email after 06:30)

## 3. Workspace Docs

- [x] 3.1 Update `workspace/HEARTBEAT.md` — add morning briefing task ("Run /watchdog to check if a morning briefing is due")
- [x] 3.2 Update `workspace/TOOLS.md` — document sandbox-based security model, document new tools in PATH (curl, python3, tar, dig, ping, file, tree)

## 4. Verification

- [x] 4.1 Confirm all modified files parse correctly (no syntax errors in Nix, valid markdown)
- [x] 4.2 Review that systemd hardening section is unchanged in modules/nixos/default.nix
