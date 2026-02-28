## Why

Sid has no way to read web content. There's no curl/wget in the service PATH (removed for security), and no native HTTP tool. When Sid needs to check a webpage, read docs, or look something up, it has to ask the user — "like it's 1997 and I'm on WebTV." A read-only web fetch tool fills the biggest gap in Sid's current capability set.

## What Changes

- Add a native `web_fetch` ZeroClaw tool that performs HTTP GET requests and returns page content as text
- HTML responses are converted to readable markdown-ish text (headings, lists, code blocks preserved)
- Non-HTML text responses returned raw
- Binary content rejected
- Size cap on response content to prevent context bloat
- Fetched content wrapped in delimiters to signal untrusted external content
- New Rust source file (`patches/web_fetch.rs`) following the established XMPP tools pattern
- New crate dependency (`html2text`) added via Cargo.toml patch
- Tool registered unconditionally in `src/tools/mod.rs` (not gated on any channel config)

## Capabilities

### New Capabilities
- `web-fetch`: Native HTTP GET tool for reading web pages and text content, with HTML-to-text conversion and size limits

### Modified Capabilities
_(none — this is a new standalone tool with no impact on existing channel or tool behavior)_

## Impact

- **flake.nix**: Three new postPatch steps (add crate, copy source, register tool)
- **New file**: `patches/web_fetch.rs` (~100-150 lines)
- **Dependencies**: `html2text` crate added to Cargo.toml
- **Build**: Rebuild required (new Rust source + new crate)
- **Security**: GET-only, no auth headers, no POST. Timeout and size cap enforced. No domain allowlist (open internet).
- **Config**: No config changes needed — tool is always available
