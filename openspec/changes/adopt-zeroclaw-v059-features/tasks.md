## 1. Retire sid-dashboard

- [x] 1.1 Remove `sid-dashboard` package definition from `flake.nix`
- [x] 1.2 Remove `dashboard.*` options (`enable`, `package`, `port`, `openFirewall`) from NixOS module and all references (systemd service, firewall rule, environment vars)
- [x] 1.3 Delete `dashboard/` directory from repository
- [x] 1.4 Verify `nix build .#zeroclaw` still succeeds and upstream dashboard is served at port 18789

## 2. Enable SOP subsystem

- [x] 2.1 Add `[sop]` section to generated `config.toml` in NixOS module: `enabled = true`, `sops_dir` pointing to workspace `sops/` directory, `default_execution_mode = "supervised"`, `approval_timeout_secs = 300`, `max_concurrent_total = 5`
- [x] 2.2 Ensure `sops/` directory exists in workspace (create if needed via workspace setup)

## 3. Create SOP definitions

- [x] 3.1 Create `sops/morning-briefing/SOP.toml` with cron trigger `30 6 * * *` (tz: America/New_York), priority `normal`, execution_mode `supervised`
- [x] 3.2 Create `sops/morning-briefing/SOP.md` with steps: check state → gather data (weather, calendar, email, health) → compose briefing → send email → update state
- [x] 3.3 Create `sops/session-review/SOP.toml` with cron trigger `0 22 * * *` (tz: America/New_York), priority `low`, execution_mode `supervised`
- [x] 3.4 Create `sops/session-review/SOP.md` with steps: review recent conversations → update MEMORY.md if notable → complete
- [x] 3.5 Create `sops/stay-quiet/SOP.toml` with cron trigger `0 23 * * *` (tz: America/New_York), priority `low`, execution_mode `auto`
- [x] 3.6 Create `sops/stay-quiet/SOP.md` with single step: check for critical alerts, complete silently if none

## 4. Validate and document

- [ ] 4.1 Build and deploy, verify SOP definitions load without errors in daemon log
- [ ] 4.2 Verify `sop_list` tool shows all three SOPs with correct triggers
- [x] 4.3 Update workspace `HEARTBEAT.md` with a note that tasks have migrated to SOPs
- [x] 4.4 Document Hands/Swarms status in a workspace note: Hands pending upstream execution wiring, Swarms incompatible with claude-code provider
