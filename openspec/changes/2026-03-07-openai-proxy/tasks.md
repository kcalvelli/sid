# Implementation Tasks

- [ ] Write `patches/openai_proxy.rs`: standalone Rust module with request/response types, message translation, tool translation, auth handling, identity injection, streaming SSE handler, non-streaming fallback
- [ ] Modify `flake.nix`: remove old patch #8.7 (internal agent loop), add new #8.7 (copy module + declare in mod.rs), add #8.8 (wire route as sub-router with 1MB body limit)
- [ ] Create `openspec/specs/openai-proxy/spec.md`: spec for proxy behavior
- [ ] Build test: `nix build .#zeroclaw` to verify compilation
