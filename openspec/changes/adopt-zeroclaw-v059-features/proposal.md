## Why

ZeroClaw v0.5.9 ships a React 19 web dashboard, Standard Operating Procedures (SOPs) with event-driven triggers, and multi-agent Hands/Swarms — all compiled into the binary but not yet configured for Sid. Adopting these replaces our custom Python dashboard with a richer upstream alternative, and gives Sid structured automation beyond simple cron jobs.

## What Changes

- **Retire `sid-dashboard`**: Remove the custom Python dashboard service (port 8080) and its NixOS module wiring. The upstream React dashboard is already embedded in the gateway binary at port 18789 and covers chat, memory, cron, config editing, cost analytics, logs, and diagnostics.
- **Enable SOPs**: Create SOP definitions in the workspace for event-driven automation. Initial SOPs target Home Assistant webhook triggers (via the existing `/v1/chat/completions` OpenAI proxy path) and cron-triggered procedures replacing the disabled heartbeat tasks.
- **Migrate heartbeat to SOPs**: Convert the three `HEARTBEAT.md` tasks (morning briefing, session review, stay quiet) into supervised SOPs with cron triggers and approval gates, replacing the disabled heartbeat subsystem.
- **Document Hands readiness**: Hands execution isn't wired in the v0.5.9 daemon scheduler yet. Document the architectural fit so adoption is straightforward when upstream lands the trigger.

## Capabilities

### New Capabilities
- `sop-automation`: Event-driven Standard Operating Procedures with webhook/cron triggers, multi-step workflows, and approval gates
- `upstream-web-dashboard`: Upstream React 19 dashboard replacing custom sid-dashboard

### Modified Capabilities
- `morning-briefing`: Migrating from disabled heartbeat config to SOP-based cron triggers with approval gates

## Impact

- **NixOS module** (`modules/nixos/default.nix`): Remove `dashboard.enable`, `dashboard.port`, `dashboard.openFirewall`, `dashboard.package` options and the `sid-dashboard` systemd service. Gateway already serves the dashboard.
- **Flake packages**: Remove `sid-dashboard` package definition from `flake.nix`. `zeroclaw-web` build stays as-is.
- **`dashboard/` directory**: Archive or delete — no longer needed.
- **Workspace**: New `sops/` directory with TOML+Markdown SOP definitions.
- **Workspace `HEARTBEAT.md`**: Kept as reference but heartbeat config replaced by SOP cron triggers.
- **No API changes**: SOPs use existing gateway endpoints. Dashboard uses existing `/api/*` routes.
