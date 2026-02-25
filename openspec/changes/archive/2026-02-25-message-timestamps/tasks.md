## 1. Channel message timestamps

- [x] 1.1 Add `use chrono::TimeZone;` import to `src/channels/mod.rs` via postPatch (file has no existing chrono import)
- [x] 1.2 Replace `append_sender_turn(ctx.as_ref(), &history_key, ChatMessage::user(&msg.content));` in `src/channels/mod.rs` — convert `msg.timestamp` (u64 unix) to local time via `chrono::Local.timestamp_opt(msg.timestamp as i64, 0)`, format as `[%Y-%m-%dT%H:%M:%S%:z]`, prepend to `msg.content`, pass stamped string to `ChatMessage::user()`

## 2. Heartbeat message timestamps

- [x] 2.1 Change `use chrono::Utc;` to `use chrono::{Local, Utc};` in `src/daemon/mod.rs` via postPatch (Utc still needed for health snapshot)
- [x] 2.2 Replace `let prompt = format!("[Heartbeat Task] {task}");` in `src/daemon/mod.rs` — prepend `chrono::Local::now().format("[%Y-%m-%dT%H:%M:%S%:z]")` before `[Heartbeat Task]`

## 3. Webhook message timestamps

- [x] 3.1 Add `use chrono::Local;` import to `src/gateway/mod.rs` via postPatch (file has no existing chrono import)
- [x] 3.2 Replace `let user_messages = vec![ChatMessage::user(message)];` in `run_gateway_chat_simple()` — prepend `chrono::Local::now().format("[%Y-%m-%dT%H:%M:%S%:z]")` to `message`, pass stamped string to `ChatMessage::user()`

## 4. Integration

- [x] 4.1 Add all three patches to the `postPatch` block in `flake.nix`, after the existing futures/reliable.rs patches
- [x] 4.2 Build the flake locally (`nix build .#zeroclaw`) to verify patches apply and compile
- [x] 4.3 Update flake lock and rebuild NixOS service on edge to deploy
