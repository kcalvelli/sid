## 1. Cargo Dependencies & Feature Gate

> **Approach changed**: No new crate dependencies needed — raw XMPP protocol over existing `tokio-rustls`, matching the IRC channel pattern. No feature gate — XMPP always compiled (like Telegram, IRC).

- [x] 1.1 ~~Add `xmpp-rs` / `tokio-xmpp` dependencies~~ → No new deps; raw XML over `tokio-rustls` using crates already in Cargo.lock
- [x] 1.2 ~~Add `channel-xmpp` to `buildFeatures`~~ → No feature flag; XMPP compiled unconditionally
- [x] 1.3 Add `pub mod xmpp;` to `src/channels/mod.rs` (via postPatch #6 in flake.nix)

## 2. XMPP Channel — Connection & Auth

- [x] 2.1 Create `src/channels/xmpp.rs` with `XmppChannel` struct (injected via `cp patches/xmpp.rs` in postPatch #5)
- [x] 2.2 Implement STARTTLS connection with custom `rustls::ClientConfig` supporting `ssl_verify = false` (NoVerify verifier)
- [x] 2.3 Implement direct server address connection (bypass SRV lookup, use configured `server:port`)
- [x] 2.4 Implement `Channel::name()` returning `"xmpp"`

## 3. XMPP Channel — Message Handling

- [x] 3.1 Implement `Channel::listen()` — event loop receiving XMPP stanzas, dispatching `ChannelMessage` for DMs (type="chat")
- [x] 3.2 Add MUC join on startup — send presence to all configured `muc_rooms` with `muc_nick`
- [x] 3.3 Implement MUC message handling in `listen()` — filter by mention detection (`@nick`, `nick:`, bare `nick` at word boundary, case-insensitive)
- [x] 3.4 Strip mention from message body, set sender to MUC nick (not full JID)
- [x] 3.5 Implement `Channel::send()` — route to chat or groupchat based on recipient, prefix MUC responses with `sender_nick: `
- [x] 3.6 Filter out bot's own reflected MUC messages (skip messages from own `muc_nick`)

## 4. XMPP Channel — Chat States & Media

- [x] 4.1 Implement `Channel::start_typing()` — send XEP-0085 "composing" chat state
- [x] 4.2 Implement `Channel::stop_typing()` — send XEP-0085 "active" chat state
- [x] 4.3 Implement OOB (XEP-0066) URL detection in incoming messages
- [x] 4.4 Download OOB media for supported types (JPEG, PNG, GIF, WebP ≤3.75MB; PDF ≤32MB) to temp files, include path in ChannelMessage content

## 5. XMPP Channel — Reconnection & Presence

- [x] 5.1 ~~Implement auto-reconnect~~ → Handled by ZeroClaw's `spawn_supervised_listener` (exponential backoff, auto-restart on error)
- [x] 5.2 On reconnect, rejoin all configured MUC rooms and restore presence (handled by `connect_and_setup()` called fresh on each reconnect)
- [x] 5.3 Set initial presence on connect: show="available", status="Sid here - what's up?"

## 6. XMPP Tools

- [x] 6.1 Implement `xmpp_send_message` tool — params: `to`, `body`, optional `type` (auto-detect chat vs groupchat)
- [x] 6.2 Implement `xmpp_list_rooms` tool — stub returning error (IQ bidirectional support deferred)
- [x] 6.3 Implement `xmpp_join_room` tool — send MUC presence, optional `nick` param
- [x] 6.4 Implement `xmpp_leave_room` tool — send unavailable presence
- [x] 6.5 Implement `xmpp_set_presence` tool — params: `show`, `status`
- [x] 6.6 Register XMPP tools in `all_tools_with_runtime()` when XMPP channel is configured (via postPatch #8)

## 7. Config & Schema

- [x] 7.1 Add `XmppConfig` struct to `patches/xmpp.rs` with fields: jid, password, server, port, ssl_verify, muc_rooms, muc_nick (with serde + schemars derives)
- [x] 7.2 Add `xmpp: Option<XmppConfig>` to `ChannelsConfig` struct (via postPatch #7)
- [x] 7.3 Implement default `muc_nick` derivation from JID local part (capitalize first letter)
- [x] 7.4 Add XMPP channel instantiation in `collect_configured_channels()` (via postPatch #6)

## 8. NixOS Module

- [x] 8.1 Add `cfg.xmpp` options to NixOS module: `enable`, `jid`, `server`, `port`, `sslVerify`, `mucRooms`, `mucNick`
- [x] 8.2 Add `xmppConfig` Nix expression generating `[channels_config.xmpp]` section with `XMPP_PASSWORD_PLACEHOLDER`
- [x] 8.3 Add agenix secret for XMPP password (`sid-xmpp-password`)
- [x] 8.4 Add sed substitution for `XMPP_PASSWORD_PLACEHOLDER` in activation script
- [x] 8.5 ~~Update flake.nix `buildFeatures`~~ → N/A (no feature flag)

## 9. Integration & Cleanup

- [x] 9.1 ~~Add XMPP channel timestamp support~~ → Already handled by existing timestamp patch (patch #2 in flake.nix covers all channels via `ChannelMessage.timestamp`)
- [x] 9.2 Test: build succeeds
- [x] 9.3 Test: XMPP channel connects to Prosody, joins MUC, responds to mentions
- [x] 9.4 ~~Remove axios-ai-chat~~ → Bot bridge disabled (`services.axios-chat.bot.enable = false`), Prosody kept
- [x] 9.5 Update workspace docs (TOOLS.md) to document XMPP tools available to agent
