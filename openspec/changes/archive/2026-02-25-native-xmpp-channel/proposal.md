## Why

Sid's XMPP presence currently depends on an external Python bridge (axios-ai-chat) that relays messages through ZeroClaw's `/webhook` endpoint. This is one-directional — the webhook passes empty tools and skills, giving XMPP personality but no agent capabilities. A native XMPP channel eliminates the bridge, gives Sid full tool use over XMPP, and enables XMPP-specific tools (send messages, manage MUC rooms, set presence).

## What Changes

- Add a native XMPP channel implementing ZeroClaw's `Channel` trait using `tokio-xmpp` / `xmpp-rs`
- Connect directly to Prosody via STARTTLS (port 5222), with self-signed cert and custom server address support
- Handle direct messages and MUC groupchat with mention detection (matching existing bridge behavior)
- Send chat state notifications (XEP-0085: composing, active)
- Detect and download media via OOB (XEP-0066) URLs
- Auto-reconnect with exponential backoff
- Add agent-callable XMPP tools: `xmpp_send_message`, `xmpp_list_rooms`, `xmpp_join_room`, `xmpp_leave_room`, `xmpp_set_presence`
- Add `[channels_config.xmpp]` configuration section (jid, password, server, port, ssl_verify, muc_rooms, muc_nick)
- Add NixOS module options for XMPP channel (`cfg.xmpp.enable`, password via agenix)
- **BREAKING**: Remove dependency on axios-ai-chat bridge — XMPP traffic goes directly through ZeroClaw

## Capabilities

### New Capabilities
- `xmpp-channel`: Native XMPP channel for ZeroClaw — connection management, message handling (DM + MUC), mention detection, chat states, media via OOB, XMPP tools, and reconnection logic

### Modified Capabilities
- (none — no existing spec requirements change)

## Impact

- **Rust source**: New `src/channels/xmpp.rs` (or `xmpp/mod.rs`) implementing `Channel` trait, plus XMPP tool definitions
- **Cargo.toml**: Add `tokio-xmpp`, `xmpp-parsers`, `minidom` (or `xmpp-rs` umbrella) crate dependencies
- **flake.nix**: `postPatch` to add XMPP crate deps; may need additional `buildInputs` if native TLS libs required
- **NixOS module** (`modules/nixos/default.nix`): New `cfg.xmpp` options, XMPP config section in config.toml, agenix secret for XMPP password
- **NixOS host config** (`hosts/edge.nix`): Enable XMPP channel, configure JID/server/rooms
- **axios-ai-chat**: No longer needed for XMPP — can be removed from edge host config
- **Prosody**: No server-side changes needed — bot connects as a regular XMPP client
