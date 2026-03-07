# OpenAI-to-Anthropic Translation Proxy for Home Assistant

## Why

Home Assistant's `extended_openai_conversation` integration requires an OpenAI-compatible `/v1/chat/completions` endpoint. The current patch #8.7 is wrong — it calls ZeroClaw's internal agent loop instead of acting as a transparent proxy. It doesn't support streaming or tool calling.

HA manages its own tool-calling loop (up to 20 iterations). We need a thin translation proxy: OpenAI format → Anthropic Messages API → stream back as OpenAI SSE chunks. This lets HA be the tool orchestrator while Claude provides the intelligence.

## What Changes

- Replace patch #8.7 with a standalone `openai_proxy.rs` module that translates between OpenAI and Anthropic formats
- Add streaming support (SSE) for real-time responses
- Add tool call translation so HA can use its native `call_service`/`get_state` tools
- Inject Sid's identity (IDENTITY.md) into the system prompt
- Forward auth to Anthropic API (OAuth token or API key)
- Wire as sub-router with 1MB body limit (HA sends large entity lists)

## Capabilities

- MODIFIED: `gateway` — replace internal agent-loop endpoint with transparent Anthropic proxy
- NEW: `openai-proxy` — OpenAI-to-Anthropic translation with streaming, tools, identity injection

## Impact

- HA gets a fully functional OpenAI-compatible endpoint with streaming and tool support
- Sid's personality comes through via identity injection without HA-side config
- No dependency on ZeroClaw's internal agent loop — direct Anthropic API forwarding
