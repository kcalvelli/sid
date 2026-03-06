## Why

Sid runs on `edge`, Keith's primary development machine. Development power cycles (reboots, kernel updates, hardware experiments) take Sid offline unpredictably. The UM870 `mini` is underutilized, stable, and already on the same Tailscale network. Moving Sid to `mini` gives it a stable home and positions it as the future operator for a containerized Home Assistant instance.

## What Changes

- **Migrate ZeroClaw (Sid) service** from `edge` to `mini` — identical `services.sid` config, all channels preserved
- **Migrate Prosody (XMPP server)** from `edge` to `mini` — same `axios-chat` module, same `chat.taile0fb4.ts.net` domain, Tailscale Serve moves with it
- **Enable agenix on `mini`** — register mini's host key, re-key all relevant secrets in both `sid` and `nixos_config` secret stores
- **Disable both services on `edge`** — clean removal, no stubs
- **Migrate state** — Prosody data (`/var/lib/prosody/`), Sid's MEMORY.md, SQLite brain.db

## What Does NOT Change

- Sid's identity, persona, workspace files, skills — all declarative, deployed by the module
- Channel configuration (Telegram, Email, XMPP, Gateway) — identical, just different host
- XMPP domain (`chat.taile0fb4.ts.net`) — Tailscale Serve provides the same service name from mini
- Auth model (OAuth subscription token via agenix)
- Sid repo structure — no code changes, only nixos_config changes

## Capabilities

### New Capabilities

None — this is a migration, not a feature addition.

### Modified Capabilities

- `zeroclaw-service`: Deployed to `mini` instead of `edge`
- `workspace-deploy`: Same mechanism, different host

## Impact

- **NixOS configs**: `mini.nix` gains sid + axios-chat imports; `edge.nix` loses them
- **Secrets**: mini's host key added to `secrets.nix` in `sid`, `nixos_config`, and `axios-chat` repos; all `.age` files re-keyed
- **Network**: All services remain localhost on mini. Tailscale Serve `svc:chat` moves from edge to mini.
- **PostgreSQL**: Will start on mini (sid module unconditionally enables it). Not used at runtime — tracked as a separate cleanup.
- **Downtime**: Brief window during cutover (Telegram bot token and IMAP IDLE are singletons). Plan for off-hours.

## Open Questions

### Home Assistant Integration Path

The ultimate goal is Sid operating a containerized Home Assistant on mini. Two integration options were evaluated:

| Approach | Status | Notes |
|----------|--------|-------|
| **HA MCP Server** | Blocked | ZeroClaw has zero MCP client support at current rev (no crate, no code, no config). Architecturally cleanest — HA describes its own capabilities — but requires upstream work. |
| **Native Rust tools** | Recommended | `ha_call_service`, `ha_get_state` as postPatch tools (same pattern as XMPP channel). Typed, in the agent loop, localhost REST to `localhost:8123` with a long-lived access token. Simpler than XMPP — just HTTP POST/GET. |
| **Shell curl/hass-cli** | Rejected | Fragile JSON string parsing, widens `allowed_commands` unnecessarily, maintenance burden. |

**Decision: Native Rust tools via REST API.** To be implemented as a separate change after migration is complete and Home Assistant is running.

### PostgreSQL Cleanup

The sid module unconditionally enables PostgreSQL (`ensureDatabases = ["sid"]`). Mini is a shared family machine. Running unused Postgres wastes ~50MB RAM. Should be gated behind an option. Tracked as a separate small change.

### Ollama Direction

Mini is currently an Ollama client pointing to edge. Post-migration, if edge is down, mini has no local inference. Not relevant for Sid (uses Anthropic API), but relevant for future HA voice/local AI features. Flag for later.
