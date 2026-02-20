## Why

GenX64 currently runs on OpenClaw with a claude-api-proxy shim to reach Anthropic models. ZeroClaw (github:zeroclaw-labs/zeroclaw) talks to Anthropic directly, eliminating the proxy layer and simplifying the service topology from three systemd units (openclaw-gateway + claude-api-proxy + watchdog timer) down to one service plus one timer. The agent persona ("Sid") and security model remain identical — this is a runtime swap, not a personality change.

## What Changes

- **BREAKING**: Replace `nix-openclaw` flake input with `zeroclaw` (github:zeroclaw-labs/zeroclaw)
- **BREAKING**: Remove `claude-api-proxy` service and package entirely — ZeroClaw speaks Anthropic API natively
- **BREAKING**: Remove `modules/home-manager/` — all deployment handled by NixOS module directly
- **BREAKING**: Remove `skills/browser/` — not needed for Sid's use case
- **BREAKING**: Remove `pkgs/claude-api-proxy/` — no longer needed
- Replace `openclaw-gateway.service` with `zeroclaw.service` running as `sid` user (renamed from `genxbot`)
- Replace `genxbot-watchdog` and `genxbot-inbox-check` systemd timers with ZeroClaw native cron (configured in `config.toml`, driven by HEARTBEAT.md)
- Keep `genxbot-log-export` as a NixOS systemd timer (requires root for journalctl)
- Rename system user from `genxbot` to `sid` with identical isolation model
- Deploy ZeroClaw `config.toml` via NixOS (owned by sid, mode 0400) with agenix secret injection at runtime
- Workspace identity files (IDENTITY.md, SOUL.md, USER.md, AGENTS.md, HEARTBEAT.md) copied verbatim — deployed as Nix store symlinks (read-only, immutable)
- New TOOLS.md documenting ZeroClaw's available tools for Sid
- MEMORY.md remains writable, copied in at deploy time (not managed by Nix)
- Keep agenix for secrets (telegram-bot-token.age, genxbot-email-password.age); drop gemini-api-key.age

## Capabilities

### New Capabilities

- `zeroclaw-service`: ZeroClaw daemon configuration, systemd service unit, config.toml generation, and secret injection for the sid user
- `workspace-deploy`: Immutable workspace file deployment (Nix store symlinks for identity files, writable MEMORY.md directory, skills symlinking)
- `log-export-timer`: System-level journalctl log export timer for watchdog consumption (requires root, kept as NixOS systemd timer)

### Modified Capabilities

_(No existing specs to modify — this is a greenfield repo)_

## Impact

- **Flake inputs**: `nix-openclaw` → `zeroclaw`; `agenix` retained
- **System user**: `genxbot` → `sid` (same isolation: isSystemUser, nologin, /var/lib/sid)
- **Systemd services**: 3 units → 1 service + 1 timer
- **Secrets**: Drop gemini-api-key.age, keep telegram-bot-token.age and genxbot-email-password.age
- **Network**: Same localhost-only model (gateway on 127.0.0.1:18789)
- **Security**: Identical defense-in-depth (read-only workspace, exec restrictions, user isolation) — ZeroClaw's `[autonomy]` section replaces exec-approvals.json
- **Skills**: cynic/, watchdog/, email/ preserved verbatim; browser/ dropped
- **Dependencies**: Consumers must update any references from `genxbot` to `sid` in their NixOS configurations
