## Context

ZeroClaw assembles LLM context from multiple sources: system prompt (with `DateTimeSection`), conversation history, and memory entries. The `ChannelMessage` struct carries a `timestamp: u64` field populated by each channel implementation, but `process_channel_message()` discards it when creating `ChatMessage::user(&msg.content)`. Heartbeat and webhook paths construct prompt strings with no temporal metadata at all.

The system prompt's `DateTimeSection` gives Sid "what time is it now" but not "when did earlier messages arrive" — so multi-turn conversations are temporally flat.

All patches are delivered via `postPatch` in the Nix flake, alongside existing fixes for the `futures` crate and duplicate `chat()` in `reliable.rs`.

## Goals / Non-Goals

**Goals:**
- Every user message the LLM sees carries a bracketed ISO-8601 timestamp with UTC offset
- Channel messages use the real send-time from the channel (e.g., Telegram's message timestamp)
- Heartbeat and webhook messages use `chrono::Local::now()` at dispatch/receipt time
- Format is consistent across all sources: `[2026-02-23T15:43:22-05:00]`

**Non-Goals:**
- Stamping assistant/LLM responses (system prompt `DateTimeSection` already provides "now")
- Modifying ZeroClaw's conversation storage schema or database
- Adding per-message metadata fields to `ChatMessage` (we prepend to content string)
- Upstream PR to ZeroClaw (this is a local postPatch; upstreaming is a future decision)

## Decisions

### 1. Prepend to content string vs. add metadata field

**Decision**: Prepend `[timestamp] ` to `msg.content` before creating `ChatMessage`.

**Rationale**: `ChatMessage` is a simple struct passed directly to the LLM provider. Adding a metadata field would require changes throughout the provider layer and prompt assembly — far more invasive. The LLM can parse bracketed timestamps naturally. This approach requires no structural changes to ZeroClaw.

**Alternative considered**: Adding a `timestamp: Option<String>` to `ChatMessage` and rendering it in prompt assembly. Rejected — too many touchpoints for a postPatch.

### 2. Three injection points (Option B) vs. single point (Option A)

**Decision**: Patch three locations independently — channels, heartbeat, webhook.

**Rationale**: Channel messages carry their real send-time via `msg.timestamp`. A single injection point in `run_tool_call_loop()` would only have `now()`, losing the actual message time. Option B preserves temporal accuracy for Telegram messages that may have been queued.

**Alternative considered**: Single patch in `run_tool_call_loop()` stamping the last user message with `now()`. Simpler but loses real send-time for channel messages.

### 3. ISO-8601 with offset, compact

**Decision**: `[%Y-%m-%dT%H:%M:%S%:z]` → `[2026-02-23T15:43:22-05:00]`

**Rationale**: Unambiguous, machine-parseable, includes timezone offset so the LLM doesn't confuse UTC and local time. Compact enough to not dominate the message. Brackets visually separate metadata from content.

### 4. Timezone source

**Decision**: Use `chrono::Local` (reads `/etc/localtime` from the host).

**Rationale**: Already used by ZeroClaw's `DateTimeSection`. The systemd sandbox (`ProtectSystem=strict`) allows reading `/etc`. The host's NixOS `time.timeZone` config controls `/etc/localtime`. For channel messages, convert the unix timestamp via `chrono::Local` for consistent offset display.

## Risks / Trade-offs

- **[Token overhead]** → ~30 extra tokens per user message in history. With max 50 messages in channel history, worst case ~1500 tokens. Acceptable given the 200K context window.
- **[Patch fragility]** → `postPatch` sed operations are brittle across ZeroClaw version bumps. → Pin to a specific ZeroClaw commit (already the case via flake.lock). Review patches on each upstream update.
- **[Timezone mismatch]** → If the NixOS host timezone changes, timestamps shift. Historical messages in conversation would show the old offset. → Acceptable; timezone changes are rare and conversations are ephemeral.
- **[Heartbeat timestamp reflects dispatch, not execution]** → Heartbeat stamps `now()` when the task is dispatched, not when the LLM processes it. If there's queue delay, the stamp is slightly early. → Acceptable; heartbeat latency is typically sub-second.
