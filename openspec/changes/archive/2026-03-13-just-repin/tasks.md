## 1. Upstream Checkout & Analysis

- [x] 1.1 Clone upstream ZeroClaw master to a temp working directory
- [x] 1.2 Identify the target commit hash for repin (HEAD of master) — `b40c9e7`
- [x] 1.3 Read upstream `src/providers/anthropic.rs` `convert_messages()` — empty text blocks NOT handled in assistant/tool branches. Patch 0011 still needed.
- [x] 1.4 Read upstream `src/channels/email_channel.rs` `send()` — upstream has `default_subject` config but does NOT use `thread_ts`. Patch 0008 cannot be simplified.
- [x] 1.5 Verify `memory-postgres` feature still exists in upstream Cargo.toml — confirmed

## 2. Patch Rebase

- [x] 2.1 Apply upstream source at target commit, then rebase patch 0001 (futures/async-stream deps in Cargo.toml) against new upstream
- [x] 2.2 Rebase patch 0002 (ISO-8601 timestamps) — applied clean
- [x] 2.3 Rebase patch 0003 (XMPP wiring) — manual rebase, new module insertions, ChannelsConfig moved
- [x] 2.4 Rebase patch 0004 (webhook agent loop) — applied clean
- [x] 2.5 Rebase patch 0005 (/v1/models endpoint) — manual rebase for route table shifts
- [x] 2.6 Rebase patch 0006 (/v1/chat/completions wiring) — manual rebase for route table shifts
- [x] 2.7 Rebase patch 0007 (skip self-emails) — applied clean
- [x] 2.8 Rebase patch 0008 (email subject threading) — manual rebase for default_subject changes. Cannot simplify (upstream doesn't use thread_ts).
- [x] 2.9 Rebase patch 0009 (save sent to IMAP Sent folder) — manual rebase for default_subject field shift

## 3. Patch Removal

- [x] 3.1 Drop patch 0010 (image-vision) from patches/ — removed
- [x] 3.2 Patch 0011 (empty text blocks) KEPT — upstream does NOT handle empty text in assistant/tool branches. Renumbered to 0010.
- [x] 3.3 Renumber: old 0011→0010. Clean sequence 0001-0010.

## 4. Source File Compilation Check

- [x] 4.1 Verify `patches/xmpp.rs` compiles against new upstream types — ChannelMessage, SendMessage, Channel trait, Tool trait, ToolResult all unchanged
- [x] 4.2 Verify `patches/openai_proxy.rs` compiles against new upstream types — AppState.model still String, minimal surface area

## 5. Flake Update

- [x] 5.1 Update flake.nix: zeroclaw input URL — no change needed, defaults to repo default branch (now `master`)
- [x] 5.2 Update flake.nix: pinned commit updated via `nix flake update zeroclaw` to `6a4ccae` (Mar 13 2026)
- [x] 5.3 Update flake.nix: patches list — removed 0010 (vision), renumbered 0011→0010, version bumped to 0.1.9
- [x] 5.4 Ran `nix flake update zeroclaw` — flake.lock updated
- [x] 5.5 Using cargoLock.lockFile — no cargoHash needed
- [x] 5.6 Verify `buildFeatures = [ "memory-postgres" ]` still compiles — build succeeded

## 6. Build & Verify

- [x] 6.1 Run `nix build` and confirm clean compilation — 551 crate derivations, success
- [x] 6.2 Verify binary: `zeroclaw 0.1.9`
- [x] 6.3 Commit and push — 3386127, pushed to origin/main
