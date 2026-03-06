## Why

The gateway `/webhook` endpoint currently uses `run_gateway_chat_simple()`, which passes empty tools and skills arrays to the LLM — making it a single-shot text completion with no agent capabilities. This means HTTP clients (curl, integrations, future web UI) get Sid's personality but none of his tools (shell, email, XMPP, etc.). The full agent loop already exists via `run_gateway_chat_with_tools()` used by channel handlers; the webhook just needs to call it.

## What Changes

- Modify the gateway webhook handler to call `run_gateway_chat_with_tools()` instead of `run_gateway_chat_simple()`, giving HTTP requests access to the full agent loop with tools, skills, and multi-turn iteration
- Add session tracking to webhook requests so tool-use conversations maintain state across iterations within a single request
- Preserve the existing authentication (paired token) and request/response format

## Capabilities

### New Capabilities
- `http-channel-tool-loop`: Gateway webhook endpoint invokes the full agent loop with tools and skills instead of simple single-shot LLM call

### Modified Capabilities

_(none — this is an internal gateway change, no existing spec requirements change)_

## Impact

- **Code**: `src/gateway/mod.rs` — `handle_webhook()` function and related message preparation
- **Upstream**: This is a patch against ZeroClaw source applied in `flake.nix`
- **Config**: No config changes needed — existing `[gateway]` config already has tool-related settings via `[autonomy]`
- **Risk**: Low — webhook is currently a dead-simple passthrough; switching to the agent loop uses the same code path all channels already use
