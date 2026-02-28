## 1. Enable upstream web_fetch tool

- [x] 1.1 Add `[web_fetch]` section to config.toml in NixOS module with `enabled = true` and `allowed_domains = ["*"]`
- [x] 1.2 Update `workspace/TOOLS.md` to document the `web_fetch` tool

## Notes

Original plan called for a custom Rust implementation (`patches/web_fetch.rs`). Discovered during build that ZeroClaw already ships a complete `web_fetch` tool with SSRF protection, domain filtering, HTML-to-text conversion, and security policy integration. Just needed enabling via config.
