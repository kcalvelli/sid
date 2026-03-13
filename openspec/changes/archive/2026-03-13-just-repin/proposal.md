## Why

ZeroClaw upstream has 234 commits since our pinned commit (d2b0593b, Feb 24 2026). Current master is at v0.1.9a (Mar 12 2026). Key motivations to repin now:

- **Vision support landed upstream** — our patch 0010 duplicates what `anthropic.rs` now has natively, creating maintenance burden and potential conflicts.
- **Email channel improvements** — upstream added configurable subject and async SMTP fixes that may simplify our email subject threading patch (0008).
- **Bug fixes we need** — graceful SIGTERM shutdown, workspace absolute path fix, email async SMTP fix, Telegram photo dedup fix.
- **Branch migration** — upstream moved from `main` to `master`; we should track the correct branch.

## What Changes

- **Repin flake.nix** to current ZeroClaw master (v0.1.9a, ~Mar 12 2026)
- **Rebase all patches** against new upstream (structural changes in channels/mod.rs, email_channel.rs, config/schema.rs, Cargo.toml, gateway/mod.rs)
- **Drop patch 0010** (image-vision) — upstream now has full Anthropic vision support with ImageSource, NativeContentOut::Image, data URI parsing
- **Evaluate patch 0008** (email subject threading) — upstream added configurable email subject; check if our threading logic can be simplified or partially replaced
- **Drop patch 0011** (empty text blocks) if upstream vision work resolved the root cause
- **Update flake.nix branch ref** from `main` to `master` if applicable

## Capabilities

### New Capabilities

(none — this is a maintenance repin, not new functionality)

### Modified Capabilities

- `image-vision`: Capability is now provided by upstream; our patch is being removed. Spec should be updated to reflect this is no longer a patch but native upstream behavior.
- `email-channel`: Upstream email changes (configurable subject, async SMTP) may affect our threading patch. Evaluate whether spec requirements are met by upstream or still need patching.

## Impact

- **flake.nix**: Pinned commit hash, cargoHash, patch list
- **flake.lock**: Updated zeroclaw input
- **patches/**: All 11 patch files need rebase; 0010 dropped, 0008 possibly simplified, 0011 possibly dropped
- **patches/xmpp.rs, patches/openai_proxy.rs**: No changes expected (no upstream overlap) but must compile against new upstream
- **Risk**: Cargo.toml structural changes (new features, profiles, dependency bumps) make patch 0001 high-conflict. channels/mod.rs has new modules (tts, transcription, clawdtalk, linq, etc.) affecting patch 0003.
