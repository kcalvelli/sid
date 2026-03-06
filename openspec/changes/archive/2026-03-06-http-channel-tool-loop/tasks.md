## 1. Patch webhook handler

- [x] 1.1 Add postPatch step in `flake.nix` that modifies `src/gateway/mod.rs` to replace the `run_gateway_chat_simple()` call in `handle_webhook()` with `run_gateway_chat_with_tools()`, generating an ephemeral `webhook-<uuid>` session ID per request
- [x] 1.2 Ensure the patch handles the non-streaming branch (the current webhook code path)

## 2. Verification

- [x] 2.1 Build the patched ZeroClaw package (`nix build .#zeroclaw`) and confirm it compiles
- [x] 2.2 Deploy to edge (`nix flake lock --update-input sid` + `nixos-rebuild switch`) and test with curl: send a message that requires tool use (e.g., "What's the server uptime?") and confirm the response includes tool output
- [x] 2.3 Test that a simple conversational message (no tool use) still returns a normal response
