## MODIFIED Requirements

### Requirement: Patch inventory matches existing features
The patch set SHALL cover all modifications currently performed that are not provided by upstream v0.6.5. Patches absorbed by upstream SHALL be removed. The remaining patches are:

1. XMPP channel wiring (module declaration, config schema, tool registration)
2. Webhook agent loop (simple chat → tool loop)
3. `/v1/models` endpoint for OpenAI compatibility
4. OpenAI proxy wiring (`/v1/chat/completions`)
5. Email self-loop prevention (skip own from_address)
6. Email reply subject threading (thread_ts from subject)
7. Email Sent folder IMAP append
8. Claude Code permission check bypass (`--dangerously-skip-permissions`)
9. SOP provider/model override with Pushover failure notifications
10. Skip noreply/bounce emails

Desktop patches (applied to zeroclaw-desktop only):
11. Tauri runtime gateway URL from `ZEROCLAW_GATEWAY_URL`
12. Tauri CSP broadened for remote gateway + no decorations

#### Scenario: Dropped patches documented
- **WHEN** comparing v0.6.3 and v0.6.5 patch sets
- **THEN** the following 10 patches SHALL have been removed with rationale:
  - 0001 (futures/async-stream deps) — build fix no longer needed
  - 0002 (ISO-8601 timestamps) — native `ChannelMessage.timestamp`
  - 0010 (Telegram context prefix) — native Channel Capabilities system
  - 0011 (Claude Code capabilities) — `ProviderCapabilities::default()` is correct
  - 0013 (/api/swarm endpoint) — MCP server removed, swarm not configured
  - 0015 (swarm agentic loop) — swarm not configured
  - 0016 (canvas WebSocket subprotocol) — upstreamed
  - 0017 (canvas store sharing) — upstreamed
  - 0019 (cross-channel Telegram awareness) — native Channel Capabilities
  - 0020 (strip anthropic/ prefix) — upstreamed

#### Scenario: Remaining patches renumbered
- **WHEN** patches are dropped from the sequence
- **THEN** remaining patches SHALL be renumbered to maintain a contiguous zero-padded sequence from 0001 to 0012

#### Scenario: All patches apply cleanly to v0.6.5
- **WHEN** `nix build .#zeroclaw` is run against the v0.6.5 source
- **THEN** all 12 patches SHALL apply without conflicts

### Requirement: New source files copied in postPatch
Standalone Rust source files that represent entirely new modules (not modifications to upstream files) SHALL be copied into the source tree via `postPatch`, not expressed as patches.

#### Scenario: New module files are copied
- **WHEN** the derivation builds
- **THEN** `patches/xmpp.rs` is copied to `src/channels/xmpp.rs` and `patches/openai_proxy.rs` is copied to `src/gateway/openai_proxy.rs` during `postPatch`
