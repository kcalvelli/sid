## Why

Sid has no temporal awareness within conversations. Messages arrive as an undifferentiated stream — Sid can't tell if two messages are 30 seconds apart or 6 hours apart. This causes time confabulation (saying "Monday" on Sunday, reporting stale timestamps from earlier heartbeats as current) and prevents time-sensitive reasoning like "you asked about this earlier today."

ZeroClaw's `DateTimeSection` injects a current timestamp into the system prompt per-turn, but individual messages in conversation history carry no temporal markers. The `ChannelMessage` struct already has a `timestamp: u64` field that is discarded when converting to `ChatMessage`.

## What Changes

- Prepend an ISO-8601 bracketed timestamp to every **user/incoming message** before it enters conversation history or the LLM context
- Three injection points, covering all message sources:
  1. **Channel messages** (Telegram, Discord, CLI): use the existing `msg.timestamp` field from `ChannelMessage` for real send-time accuracy
  2. **Heartbeat messages**: stamp with `chrono::Local::now()` at task dispatch time
  3. **Webhook messages**: stamp with `chrono::Local::now()` at receipt time
- Format: `[2026-02-23T15:43:22-05:00] <original message>`
- Assistant messages are NOT stamped

## Capabilities

### New Capabilities
- `message-timestamps`: Prepend bracketed ISO-8601 timestamps with UTC offset to all incoming messages across channel, heartbeat, and webhook paths

### Modified Capabilities

## Impact

- **ZeroClaw source patches**: Three new `postPatch` operations in `flake.nix`, targeting `src/channels/mod.rs`, `src/daemon/mod.rs`, and `src/gateway/mod.rs`
- **Token overhead**: ~30 tokens per user message in conversation history (the timestamp prefix)
- **Build**: No new dependencies — `chrono` with `Local` timezone support is already in ZeroClaw's dependency tree
- **Existing patches**: Must coexist with current `postPatch` fixes (futures crate, duplicate `chat()`)
- **Timezone**: Uses `chrono::Local` which reads `/etc/localtime` — works inside the systemd sandbox (`ProtectSystem=strict` allows reading `/etc`)
