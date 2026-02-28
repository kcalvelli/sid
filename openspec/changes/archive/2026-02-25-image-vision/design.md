## Context

ZeroClaw has a multimodal pipeline (`src/multimodal.rs`) that:
1. Parses `[IMAGE:...]` markers from message content
2. Normalizes references (file paths → base64, URLs → base64)
3. Reconstructs messages with `[IMAGE:data:mime;base64,payload]` markers

The pipeline works. But the Anthropic provider (`src/providers/anthropic.rs`) has no `Image` variant in its `NativeContentOut` enum — only `Text`, `ToolUse`, and `ToolResult`. So when `convert_messages()` processes user messages, it wraps the entire content string (including image markers) as a single `Text` block. Claude never receives vision content blocks.

Separately, our XMPP patch downloads OOB images to `/tmp/xmpp_media_*.ext` but formats them as `[Attached file: /path]` instead of `[IMAGE:/path]`, so they never enter the multimodal pipeline at all.

## Goals / Non-Goals

**Goals:**
- Sid can see images sent via XMPP and describe/respond to them
- Images flow through ZeroClaw's existing multimodal pipeline (no reinvention)
- Claude's native vision API is used (proper `image` content blocks, not base64-in-text)

**Non-Goals:**
- Image generation or editing
- Vision from channels other than XMPP (Telegram etc. would need their own channel fixes)
- Modifying the multimodal pipeline itself (it already works correctly)
- Image caching or persistence beyond `/tmp/`

## Decisions

### 1. Fix the XMPP attachment format to use `[IMAGE:]` markers

**Decision**: Change `[Attached file: {path}]` to `[IMAGE:{path}]` in `patches/xmpp.rs` line 382.

**Rationale**: The multimodal pipeline's `normalize_image_reference()` already handles local file paths — it reads the file, detects MIME type, and base64-encodes it. We just need to feed it the right marker format. One-line change.

### 2. Add `Image` variant to Anthropic provider's `NativeContentOut`

**Decision**: Add a new enum variant matching Claude's vision API format:

```rust
#[serde(rename = "image")]
Image {
    source: ImageSource,
}
```

With:
```rust
#[derive(Debug, Serialize)]
struct ImageSource {
    #[serde(rename = "type")]
    source_type: String,    // "base64"
    media_type: String,     // "image/png" etc.
    data: String,           // base64 payload
}
```

**Rationale**: This serializes to exactly what Claude's API expects: `{"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": "..."}}`.

### 3. Parse `[IMAGE:]` markers in `convert_messages()` for user messages

**Decision**: In the `_ =>` (user) branch of `convert_messages()`, parse image markers and build a mixed `Vec<NativeContentOut>` with `Text` and `Image` blocks.

**Approach**: Use the existing `parse_image_markers()` function from `multimodal.rs` to extract text and image references. For each data URI, parse `data:mime;base64,payload` and construct an `Image` block.

**Rationale**: Reuses ZeroClaw's own parsing logic. No duplicate regex or marker handling.

### 4. Patch via Python string replacement in flake.nix (established pattern)

**Decision**: Patch `src/providers/anthropic.rs` using the same Python `str.replace()` approach used for all other ZeroClaw patches.

**Alternatives considered**:
- Upstream PR → ideal long-term, but blocks Sid from seeing images now
- Separate `.rs` file → the changes are insertions into existing code, not a standalone module

**Rationale**: Follows the established pattern. Patches are localized and auditable.

### 5. Handle `apply_cache_to_last_message` for Image variant

**Decision**: Add `NativeContentOut::Image { .. } => {}` to the match arm in `apply_cache_to_last_message()` so the compiler doesn't warn about non-exhaustive patterns.

**Rationale**: Images don't need cache control markers. The no-op arm keeps it clean.

## Risks / Trade-offs

- **[Upstream breakage]** → If ZeroClaw changes `NativeContentOut` or `convert_messages()` in a future release, the string-replacement patch may fail to apply. Mitigated by pinned version in flake.nix.
- **[Large images in context]** → A 5MB image base64-encoded is ~6.7MB in the API request. Mitigated by the multimodal pipeline's existing `max_image_size_mb` (default 5MB) and `max_images` (default 4) limits.
- **[Only XMPP images]** → Other channels (Telegram, email) would need their own format fixes. Acceptable — XMPP is Sid's primary image-receiving channel.
- **[Multimodal pipeline dependency]** → We rely on `prepare_messages_for_provider()` being called before `convert_messages()`. Need to verify this is the case in the agent loop.
