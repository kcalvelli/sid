## Context

Sid runs ZeroClaw v0.5.9 with the `claude-code` provider. The gateway binds to `0.0.0.0:18789` and now embeds the upstream React dashboard via `rust-embed`. A separate Python `sid-dashboard` service runs on port 8080 providing chat, memory, and cron tabs — all of which the upstream dashboard supersedes with richer functionality.

The heartbeat subsystem is configured but disabled (`heartbeat.enabled = false`). Three tasks are defined in `HEARTBEAT.md` (morning briefing, session review, stay quiet). ZeroClaw v0.5.9 introduces SOPs — event-driven multi-step procedures with approval gates — which are a better fit for these tasks.

Hands (autonomous scheduled agents with knowledge accumulation) are compiled into v0.5.9 but daemon execution isn't wired yet. Swarms require native providers and won't work under `claude-code`.

## Goals / Non-Goals

**Goals:**
- Remove `sid-dashboard` entirely (package, service, module options, source directory)
- Create initial SOP definitions for the three heartbeat tasks as cron-triggered supervised procedures
- Validate SOP loading works at daemon startup
- Document Hands/Swarms status for future adoption

**Non-Goals:**
- MQTT or peripheral SOP triggers (no IoT infrastructure yet)
- Webhook-triggered SOPs for Home Assistant (requires designing the HA→SOP event contract — separate change)
- Enabling Hands (upstream hasn't wired execution)
- Enabling Swarms (incompatible with `claude-code` provider)
- Modifying the upstream dashboard (accept as-is)

## Decisions

### 1. Remove sid-dashboard entirely, not deprecate
The upstream dashboard covers every feature the Python dashboard had plus 8 more pages (config editor, cost analytics, SSE logs, diagnostics, canvas, device pairing, integrations, tools browser). There's no reason to keep two dashboards. The `dashboard/` directory, flake package, and NixOS module options will be deleted.

### 2. SOPs go in workspace, not system config
SOP definitions (`SOP.toml` + `SOP.md`) belong in `~/.zeroclaw/workspace/sops/` (the git-synced workspace), not in the NixOS module. This keeps them version-controlled alongside `IDENTITY.md` and `SOUL.md`, and editable by Sid itself via workspace tools.

### 3. Start with cron-triggered supervised SOPs only
The three heartbeat tasks map to cron triggers with `execution_mode = "supervised"`. This is the lowest-risk entry point — no external event sources needed, approval gates prevent runaway automation, and the cron scheduler is already battle-tested.

### 4. Keep heartbeat config disabled
Rather than removing the heartbeat config entirely, keep it disabled. SOPs replace the use case but the heartbeat system is a different mechanism — no reason to burn the bridge.

### 5. Enable SOP subsystem in NixOS module
Add `[sop]` config section to the generated `config.toml` with `enabled = true`, `sops_dir` pointing to the workspace sops directory, and `default_execution_mode = "supervised"`.

## Risks / Trade-offs

- **SOP maturity**: SOPs are new in v0.5.9. If bugs surface, we fall back to cron jobs via the MCP cron tools (already working).
- **Dashboard auth**: The upstream dashboard uses bearer token pairing. Existing paired tokens work, but the UX for first-time pairing needs manual `POST /pair` or the admin endpoint. Not a blocker — Sid already has paired tokens configured.
- **Workspace sync**: SOP definitions in workspace will be auto-synced to GitHub via the hourly `sid-workspace-push` timer. If an SOP is malformed, the daemon logs a warning but continues — fail-open on load.
