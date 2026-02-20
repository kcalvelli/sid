## Context

GenX64 deploys Sid (a cynical Gen X AI persona on a fictional Commodore 64) via OpenClaw with a claude-api-proxy shim for Anthropic model access. The stack comprises three systemd services (openclaw-gateway, claude-api-proxy, watchdog timer), a home-manager module for workspace deployment, and agenix-managed secrets.

ZeroClaw replaces OpenClaw with native Anthropic support via subscription auth (`zeroclaw auth paste-token --provider anthropic`), eliminating the proxy layer entirely. ZeroClaw also provides native cron scheduling, making the watchdog and inbox-check timers redundant as separate systemd units.

The new repo is called `sid` (not GenX64) and deploys a `sid` system user (not `genxbot`).

## Goals / Non-Goals

**Goals:**

- Swap OpenClaw runtime for ZeroClaw with zero personality drift — workspace identity files copied verbatim
- Use ZeroClaw subscription auth (anthropic provider) instead of API key + proxy
- Consolidate systemd topology: 1 service (zeroclaw) + 1 timer (log-export)
- Maintain identical security posture: read-only workspace (Nix store symlinks), user isolation, restricted commands
- Keep agenix for Telegram bot token and email password secrets
- ZeroClaw `config.toml` deployed via NixOS, secret injection at activation time via agenix

**Non-Goals:**

- Modifying Sid's personality, tone, or identity in any way
- Adding new channels beyond Telegram
- Implementing a web UI or dashboard
- Managing MEMORY.md via Nix (it's deployed manually from the live GenX64 instance)
- Browser automation (dropped entirely)
- Re-encrypting existing .age files (reuse filenames from GenX64)

## Decisions

### D1: Subscription auth via `zeroclaw auth` instead of API key in config.toml

ZeroClaw supports subscription-native auth profiles stored at `~/.zeroclaw/auth-profiles.json` (encrypted at rest). For Anthropic, the setup is:

```
zeroclaw auth paste-token --provider anthropic --profile default --auth-kind authorization
```

This means:
- No `api_key` field in config.toml
- No agenix secret for an Anthropic API key
- Auth is set up once via `zeroclaw auth` on the sid user and persists in `~/.zeroclaw/`
- The NixOS activation script creates `~/.zeroclaw/` owned by sid with mode 0700

**Alternative considered:** Injecting API key into config.toml at runtime via agenix (GenX64 approach). Rejected because ZeroClaw's native auth is more secure (encrypted at rest with its own key) and avoids the fragile jq-merge-at-ExecStartPre pattern.

### D2: Single NixOS module (no home-manager)

Everything lives in `modules/nixos/default.nix`:
- System user creation (`sid`)
- Agenix secret declarations
- ZeroClaw systemd service
- Log-export systemd timer
- Activation script for workspace symlinks and directory setup

**Alternative considered:** Keeping home-manager for workspace deployment. Rejected because the sid user is a headless system user with no interactive session — home-manager adds complexity for no benefit.

### D3: ZeroClaw native cron replaces watchdog and inbox-check timers

ZeroClaw's `[heartbeat]` config (interval_minutes = 30) drives periodic tasks. HEARTBEAT.md tells the agent what to do on each heartbeat (check email, update MEMORY.md, stay quiet unless actionable). The watchdog skill reads logs written by the log-export timer.

**Alternative considered:** Keeping all timers as systemd units. Rejected because ZeroClaw's built-in scheduler is simpler and the agent already knows what to do via HEARTBEAT.md.

### D4: Log-export stays as NixOS systemd timer

The log-export service runs as root to read journalctl, filters system logs, and writes to `/var/lib/sid/.local/share/sid/watchdog.log` owned by sid. This can't run inside ZeroClaw's sandbox — it needs root for journal access.

### D5: Config.toml deployed as Nix-managed file with secret injection

The `config.toml` is written by the NixOS activation script. Telegram bot token is injected from agenix at activation time using `sed` on the deployed file. The file is owned by sid with mode 0400.

The `api_key` field is omitted — auth is handled by ZeroClaw's auth profile system.

### D6: Drop gemini-api-key.age, keep telegram and email secrets

ZeroClaw uses Anthropic directly via subscription auth. No Gemini fallback. The existing `telegram-bot-token.age` and `genxbot-email-password.age` files are reused with their original filenames to avoid re-encryption.

### D7: Workspace immutability via Nix store symlinks

Identical pattern to GenX64: IDENTITY.md, SOUL.md, USER.md, AGENTS.md, HEARTBEAT.md, and TOOLS.md are deployed as symlinks to Nix store paths (read-only). MEMORY.md is a writable file in `/var/lib/sid/workspace/` owned by sid — not managed by Nix, copied in at deploy time from GenX64.

## Risks / Trade-offs

- **[Auth profile bootstrapping]** → ZeroClaw auth must be set up manually on first deploy via `sudo -u sid zeroclaw auth paste-token --provider anthropic --profile default --auth-kind authorization`. Document in README.
- **[MEMORY.md migration]** → Must be copied from live GenX64 instance at deploy time. If forgotten, Sid starts with no memory. → Document the copy step clearly.
- **[ZeroClaw maturity]** → ZeroClaw is newer than OpenClaw. If bugs surface, rollback means re-deploying GenX64. → Keep GenX64 repo intact as fallback.
- **[Email password secret ownership]** → genxbot-email-password.age is currently owned by keith user in GenX64 for axios-ai-mail. In sid, it should be owned by sid user if Sid accesses email directly. → Update agenix owner to sid.

## Migration Plan

1. Build the sid flake repo with all files
2. Copy workspace identity files verbatim from GenX64
3. Copy skills/ verbatim from GenX64 (cynic, watchdog, email — skip browser)
4. Copy secrets/*.age files from GenX64 (telegram-bot-token.age, genxbot-email-password.age)
5. Add sid flake to target machine's NixOS config
6. `nixos-rebuild switch`
7. Bootstrap auth: `sudo -u sid zeroclaw auth paste-token --provider anthropic --profile default --auth-kind authorization`
8. Copy MEMORY.md from GenX64 instance: `cp /var/lib/genxbot/workspace/MEMORY.md /var/lib/sid/workspace/MEMORY.md && chown sid:sid /var/lib/sid/workspace/MEMORY.md`
9. Verify: `systemctl status zeroclaw` and test Telegram interaction
10. Disable GenX64 services on old deployment

**Rollback:** Re-enable GenX64 services, disable sid flake module. No data loss since MEMORY.md exists on both.

## Open Questions

- What is the exact ZeroClaw binary name and command to start the daemon? (Assumed: `zeroclaw agent` or `zeroclaw gateway` — needs verification against ZeroClaw docs)
- Does ZeroClaw's `[channels_config.telegram]` accept a token file path or does it need the token in config.toml directly?
