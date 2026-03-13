## Why

The OpenAI proxy currently bypasses the agent loop entirely — it translates HA's OpenAI-format requests directly to the Anthropic Messages API, making Sid a dumb passthrough. This means HA voice/chat gets no tools, no memory, no skills — just raw Claude. The webhook endpoint already proves that `run_gateway_chat_with_tools` delivers full agent capabilities; the proxy should use the same path.

## What Changes

- **Rewrite `openai_proxy.rs` backend**: Replace the direct `reqwest` call to `https://api.anthropic.com/v1/messages` with a call to `run_gateway_chat_with_tools(state, message)`, routing through the full agent loop (tools, memory, shell, cron, email, skills).
- **Remove Anthropic-specific code**: `AnthropicRequest`, `AnthropicMessage`, `AnthropicTool` structs, `translate_messages()`, `translate_tools()`, `get_auth()`, `AuthHeaders`, `PROXY_CLIENT`, SSE parsing of Anthropic events — all replaced by the agent loop which handles provider auth and model selection internally.
- **Simplify streaming**: Agent loop returns a final response string (not a stream). For `stream: true`, emit the complete response as a single-burst SSE sequence (role chunk → content chunk → finish chunk → `[DONE]`). For `stream: false`, return standard OpenAI JSON. No token-by-token streaming needed — TTS needs complete utterances anyway.
- **Keep OpenAI request/response format**: HA's `extended_openai_conversation` still sends and receives OpenAI Chat Completions format. The `/v1/chat/completions` and `/v1/models` routes stay. Gateway bearer token auth stays.
- **Keep identity injection**: IDENTITY.md prepend stays (system prompt context for the agent).

## Capabilities

### New Capabilities

_None — this modifies an existing capability._

### Modified Capabilities

- `openai-proxy`: Backend changes from direct Anthropic API passthrough to full agent loop. Request format stays OpenAI, but responses now come from the agent (with tool results baked in). Streaming becomes single-burst SSE. Tool calls from HA are ignored (agent has its own tools). **BREAKING** for any client that relied on seeing intermediate `tool_calls`/`tool` response cycles in the proxy — those no longer surface.

## Impact

- **Files**: `src/gateway/openai_proxy.rs` (rewrite), patch `0006` (mod.rs route wiring — may need handler signature update)
- **Dependencies**: `reqwest`, `tokio_util`, `async_stream` imports likely removed from proxy; replaced by agent loop imports
- **Runtime**: Requests now invoke the full agent loop (shell commands, memory queries, etc.) — higher latency per request but dramatically more capable responses
- **HA integration**: No HA config changes needed — same endpoint, same format. HA tools (entity lists, service calls) sent in the request are ignored; Sid uses its own tool set.
- **Auth**: `ANTHROPIC_OAUTH_TOKEN` no longer read by the proxy — agent loop handles its own provider auth
