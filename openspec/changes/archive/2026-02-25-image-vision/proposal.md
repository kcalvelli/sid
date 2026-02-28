## Why

Sid receives images via XMPP (OOB/XEP-0066) but can't see them. The XMPP channel downloads images to `/tmp/` and appends the file path as text, but the Anthropic provider has no vision support — it treats everything as plain text. ZeroClaw already has a multimodal pipeline that normalizes images to base64 data URIs, but the Anthropic provider's `NativeContentOut` enum lacks an `Image` variant, so the pipeline's output is never converted to Claude's vision content blocks.

## What Changes

- **XMPP channel patch**: Change image attachment format from `[Attached file: /path]` to `[IMAGE:/path]` so downloaded images enter ZeroClaw's multimodal pipeline
- **Anthropic provider patch**: Add `Image` variant to `NativeContentOut` enum and parse `[IMAGE:data:mime;base64,...]` markers in `convert_messages()` into proper Claude vision API content blocks
- **Config**: Enable multimodal support in config.toml (`[multimodal] enabled` or equivalent)

## Capabilities

### New Capabilities
- `image-vision`: Ability for Sid to see and describe images received via XMPP using Claude's vision API

### Modified Capabilities
- `xmpp-channel`: Image attachment format changes from `[Attached file: ...]` to `[IMAGE:...]` to integrate with the multimodal pipeline

## Impact

- **patches/xmpp.rs**: Change image attachment format string (~2 lines)
- **flake.nix**: New postPatch step to modify `src/providers/anthropic.rs` (add Image variant, parse markers in convert_messages)
- **modules/nixos/default.nix**: Add `[multimodal]` config section if needed
- **Build**: Rebuild required (Rust source patches)
- **No new dependencies**: Uses existing reqwest, base64, and multimodal infrastructure
