## 1. XMPP Image Format

- [x] 1.1 In `patches/xmpp.rs`, change image attachment format from `[Attached file: {path}]` to `[IMAGE:{path}]` for supported image types (JPEG, PNG, GIF, WebP)
- [x] 1.2 Keep `[Attached file: {path}]` format for non-image files (PDFs)

## 2. Anthropic Provider Patch

- [x] 2.1 Add `ImageSource` struct to `src/providers/anthropic.rs` (fields: source_type, media_type, data)
- [x] 2.2 Add `Image { source: ImageSource }` variant to `NativeContentOut` enum
- [x] 2.3 Add `NativeContentOut::Image { .. } => {}` arm to `apply_cache_to_last_message()`
- [x] 2.4 In `convert_messages()` user branch: parse `[IMAGE:data:mime;base64,payload]` markers and build mixed Text + Image content blocks
- [x] 2.5 Add all patches as Python string-replacement steps in flake.nix postPatch

## 3. Configuration

- [x] 3.1 Verify multimodal pipeline is active (check if `[multimodal]` config section is needed or if defaults suffice)

## 4. Documentation

- [x] 4.1 Update `workspace/TOOLS.md` to note that Sid can now see images shared via XMPP
