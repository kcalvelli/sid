## Context

Sid currently reaches XMPP via an external Python bridge (axios-ai-chat) that relays messages to ZeroClaw's `/webhook` endpoint. The webhook handler passes empty tools and skills to the LLM — it's a single-shot request, not an agent loop. This means XMPP gets personality but zero tool use: no email, no shell commands, no memory writes.

ZeroClaw already has 20+ native channel implementations following a consistent `Channel` trait pattern. Each channel provides a `listen()` method (long-running message receiver) and `send()` (outbound), runs inside a supervised listener with auto-reconnect, and feeds into the shared agent loop that has full tool access.

The project uses `tokio` + `rustls` for async networking and TLS. The Rust XMPP ecosystem offers `tokio-xmpp` (low-level, async, tokio-native) and `xmpp-rs` (higher-level wrapper around `tokio-xmpp`). Both are maintained by the same xmpp-rs project.

## Goals / Non-Goals

**Goals:**
- Native XMPP channel implementing `Channel` trait — full agent loop with tools, memory, skills
- Direct messages and MUC groupchat with mention-based activation (matching existing bridge behavior)
- Chat state notifications (composing/active) via `start_typing()`/`stop_typing()`
- OOB media detection and download (XEP-0066)
- XMPP-specific tools the agent can call: send messages, list/join/leave rooms, set presence
- Config via `[channels_config.xmpp]` in config.toml, NixOS module options, agenix secret injection
- Auto-reconnect with exponential backoff (handled by existing supervised listener infrastructure)
- Works with Prosody over STARTTLS, including self-signed certs and Tailscale MagicDNS

**Non-Goals:**
- End-to-end encryption (OMEMO/OX) — not needed for private Prosody instance
- File upload via HTTP Upload (XEP-0363) — agent sends text; media is inbound only
- Multi-account support — single JID per deployment
- Roster management — bot connects to pre-configured rooms, doesn't manage contact lists
- Message archive (MAM, XEP-0313) — agent has its own conversation history via ZeroClaw memory

## Decisions

### 1. Use `xmpp-rs` (high-level) over raw `tokio-xmpp`

**Choice:** `xmpp-rs` crate (re-exports `tokio-xmpp` internals with higher-level abstractions)

**Rationale:** `xmpp-rs` provides `ClientBuilder`, `Event` enum, and built-in stanza parsing for presence, messages, and IQs. Raw `tokio-xmpp` requires manual XML stanza construction. Since we need standard XMPP operations (message send/receive, MUC join, presence, disco), the higher-level API reduces boilerplate. Both crates are from the same project (`xmpp-rs` on crates.io) so there's no ecosystem split risk.

**Alternative:** Raw `tokio-xmpp` — more control but more XML wrangling. Not worth it for standard XMPP operations.

### 2. Share XMPP client between channel and tools via `Arc<XmppClient>`

**Choice:** Wrap the XMPP client connection in `Arc<Mutex<XmppClient>>` and pass a clone to both the channel listener and the XMPP tool implementations.

**Rationale:** XMPP tools (`xmpp_send_message`, `xmpp_join_room`, etc.) need to send stanzas on the same authenticated connection the channel uses. ZeroClaw's tool registry takes `Vec<Box<dyn Tool>>` — each tool gets an Arc reference to the shared client. The Mutex serializes write access to the XML stream (reads go through the event loop in `listen()`).

**Alternative:** Separate connections for channel and tools — wasteful, and Prosody may enforce per-resource limits. Using the same connection/resource is the XMPP-correct approach.

### 3. Feature-gate XMPP channel behind `channel-xmpp` Cargo feature

**Choice:** Add XMPP as an optional Cargo feature, similar to how Matrix uses `channel-matrix`.

**Rationale:** `xmpp-rs` and its transitive dependencies (`tokio-xmpp`, `minidom`, `xmpp-parsers`) add compile time and binary size. Feature-gating keeps builds lean for deployments that don't need XMPP. The Nix flake enables the feature in `buildFeatures`.

**Alternative:** Always-on — simpler but adds ~15 crates to every build. Given the existing pattern of feature-gated channels, follow convention.

### 4. STARTTLS with custom TLS config for self-signed certs

**Choice:** Build a custom `rustls::ClientConfig` that optionally disables certificate verification when `ssl_verify = false` in config. Pass the server address separately from the JID domain to support Tailscale setups where DNS resolution differs.

**Rationale:** The Prosody instance uses self-signed certificates and is accessed via Tailscale MagicDNS hostname, which differs from the XMPP domain. Standard XMPP SRV lookup and certificate validation would fail. The existing Python bridge handles this via slixmpp's `disable_starttls` and custom SSL context.

**Alternative:** Require proper certificates (Let's Encrypt) — not practical for a Tailscale-only Prosody instance with no public DNS.

### 5. MUC message routing: mention-gated activation

**Choice:** In MUC rooms, only process messages that mention the bot (by nick, `@nick`, or `nick:`). Strip the mention prefix before passing to the agent. Prefix responses with `sender_nick: `.

**Rationale:** Preserves existing bridge behavior. Without mention gating, the bot would respond to every message in every room, which is both noisy and expensive (each message triggers an LLM call). The mention patterns match what users are already accustomed to.

**Alternative:** Respond to all MUC messages — too aggressive. Configurable activation patterns — over-engineering for current needs.

### 6. XMPP tools registered conditionally when XMPP channel is active

**Choice:** XMPP tools are created by the XmppChannel constructor and returned via a `tools()` method. They're added to the tools registry in `collect_configured_channels()` only when XMPP is configured.

**Rationale:** Tools like `xmpp_send_message` only make sense when there's an active XMPP connection. Other channels (Telegram, email) don't register channel-specific tools — but XMPP presence management and room operations are genuinely useful agent capabilities that don't exist in other channels' scope.

**Alternative:** Register tools globally — confusing when XMPP isn't configured (tool calls would fail).

### 7. DNS resolution: use system resolver, skip SRV/XMPP DNS

**Choice:** Connect directly to the configured `server` address and port. Do not perform XMPP SRV record lookup or custom DNS resolution.

**Rationale:** The deployment uses Tailscale MagicDNS, which doesn't support SRV records. The Python bridge explicitly disables aiodns-style resolution for this reason. Direct connection to `server:port` is simpler and works universally.

**Alternative:** SRV lookup with fallback — unnecessary complexity when server is always explicitly configured.

## Risks / Trade-offs

- **[xmpp-rs crate maturity]** The `xmpp-rs` ecosystem is less mature than, say, the Telegram bot API crates. API surface may change. → Mitigation: Pin exact crate versions in Cargo.toml. The crate is actively maintained and covers our needs (basic messaging + MUC + presence).

- **[Shared client mutex contention]** The Mutex on the XMPP client could bottleneck if the agent calls multiple XMPP tools concurrently while messages are arriving. → Mitigation: XMPP stanza writes are fast (small XML payloads). Contention is unlikely at Sid's message volume. If needed, can switch to `tokio::sync::Mutex` for async-aware locking.

- **[Self-signed cert bypass]** Disabling TLS verification when `ssl_verify = false` reduces transport security. → Mitigation: Only used on Tailscale networks (encrypted overlay). The Prosody instance is not publicly accessible. Config defaults to `ssl_verify = true`.

- **[Breaking change: axios-ai-chat removal]** Users relying on the webhook bridge for XMPP lose that path. → Mitigation: The webhook endpoint itself isn't removed — it just stops being the XMPP transport. The bridge can still be used for other purposes. Clear documentation of the migration.

## Migration Plan

1. Add `xmpp-rs` dependency and XMPP channel implementation (behind feature flag)
2. Add NixOS module options (`cfg.xmpp.enable`, password secret, server config)
3. Add `channel-xmpp` to `buildFeatures` in flake.nix, add any needed `postPatch` for dependency wiring
4. Configure `[channels_config.xmpp]` in config.toml template
5. Create agenix secret for XMPP password
6. Deploy with `nixos-rebuild switch` — both webhook bridge and native channel can coexist during testing
7. Verify: DMs, MUC messages, tools, chat states, reconnection
8. Remove axios-ai-chat service from edge.nix
9. Optionally disable the webhook gateway if no longer needed
