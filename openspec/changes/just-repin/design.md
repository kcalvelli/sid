## Context

Sid pins ZeroClaw at commit `d2b0593b` (Feb 24 2026) and applies 11 git patches + 2 source files. Upstream is now at v0.1.9a (~234 commits ahead) on `master` branch. The codebase has structural changes in files we patch: new channel modules in `channels/mod.rs`, email channel refactoring, new Cargo features/dependencies, and native Anthropic vision support.

## Goals / Non-Goals

**Goals:**
- Repin to current ZeroClaw master (v0.1.9a)
- Rebase all retained patches cleanly against new upstream
- Drop patch 0010 (vision) — upstream covers this natively
- Drop patch 0011 (empty text blocks) if upstream vision work resolves the root cause
- Evaluate whether patch 0008 (email subject threading) can leverage upstream's configurable subject feature to simplify
- Update branch tracking from `main` to `master`

**Non-Goals:**
- Picking up new upstream features (TTS, Linq, Matrix enhancements, etc.) — separate changes
- Modifying openai_proxy.rs or xmpp.rs functionality
- Changing the agent loop or webhook behavior
- Any runtime behavior changes beyond what the repin inherits

## Decisions

### 1. Drop patch 0010 (image-vision)

Upstream `providers/anthropic.rs` now has: `ImageSource` struct, `NativeContentOut::Image` variant, data URI parsing, local file reading with MIME detection, ephemeral cache control on image blocks. This fully supersedes our patch. The `[IMAGE:data:mime;base64,...]` marker parsing and multi-content block conversion are native.

**Alternative**: Keep our patch and let it conflict. Rejected — maintaining a duplicate implementation is pure cost.

### 2. Check patch 0011 (empty text blocks) against upstream

Patch 0011 guards against empty `msg.content` producing empty text content blocks in `convert_messages()`. This may have been addressed as part of the upstream vision work (which restructured content block handling). If upstream's `convert_messages` already handles empty content gracefully, drop 0011 too.

**Action during implementation**: Read upstream's `convert_messages()` in `anthropic.rs` and check for empty-content guards before deciding.

### 3. Evaluate patch 0008 (email subject threading) simplification

Our patch does two things:
1. **Inbound**: Extracts subject from `email.content` (which starts with "Subject: ...") into `thread_ts` field
2. **Outbound**: Uses `thread_ts` as the reply subject with "Re: " prefix

Upstream added a configurable `subject` field on `EmailConfig` and has legacy `"Subject: "` prefix parsing in the `send()` path. The inbound side still sets `thread_ts: None` upstream, so our extraction logic is still needed. But the outbound `send()` now has a `message.subject` field — we should check if we can use that instead of `thread_ts` for reply subjects.

**Decision**: Keep the patch but rebase it. During rebase, check if the outbound path can be simplified by using `message.subject` when available. The inbound extraction (`thread_ts` population) remains necessary regardless.

### 4. Rebase strategy for high-conflict patches

- **Patch 0001 (Cargo.toml deps)**: Upstream added features, profiles, bumped deps. Rebase by finding the correct insertion points for `futures` and `async-stream` in the new Cargo.toml.
- **Patch 0003 (XMPP wiring)**: `channels/mod.rs` has many new modules. Add `xmpp` alongside the new entries. `config/schema.rs` has new config structs — add `XmppConfig` in the same pattern.
- **Patches 0005/0006 (OpenAI proxy wiring)**: `gateway/mod.rs` has new routes — add our `/v1/` routes alongside them. Low structural risk.
- **Patches 0007/0008/0009 (email)**: `email_channel.rs` had async SMTP refactor. These patches touch `process_unseen` and `send()` — will need careful context adjustment.

### 5. Patch renumbering after dropping

After dropping 0010 and potentially 0011, renumber remaining patches to maintain a clean sequence. If both are dropped, patches 0001-0009 remain as-is (no renumbering needed since dropped patches are at the end).

## Risks / Trade-offs

- **[Cargo.lock divergence]** → Upstream's Cargo.lock will have different dependency versions. The `cargoHash` in flake.nix must be updated. Build and verify.
- **[Compile errors from API changes]** → xmpp.rs and openai_proxy.rs reference internal ZeroClaw types that may have changed signatures. → Must compile-test both files against new upstream.
- **[email_channel.rs structural changes]** → Upstream refactored async SMTP into `spawn_blocking`. Our 3 email patches touch nearby code. → Careful manual rebase with context verification.
- **[buildFeatures change]** → If upstream's feature flags changed, `buildFeatures = [ "memory-postgres" ]` may need adjustment. → Verify feature name still exists in new Cargo.toml.
