# OpenAI-to-Anthropic Translation Proxy

## Purpose

Provides an OpenAI-compatible `/v1/chat/completions` endpoint that translates requests to the Anthropic Messages API and streams responses back in OpenAI format. Designed for Home Assistant's `extended_openai_conversation` integration.

## Behavior

### Request Translation

- OpenAI `messages` array → Anthropic `messages` + `system` prompt
- System messages extracted and concatenated as Anthropic system prompt
- Tool messages merged into single user message with `tool_result` content blocks (Anthropic requires alternating roles)
- Assistant messages with `tool_calls` converted to `tool_use` content blocks
- OpenAI `tools[].function` unwrapped; `parameters` renamed to `input_schema`

### Identity Injection

- `IDENTITY.md` read from workspace dir (`ZEROCLAW_WORKSPACE` env or `/var/lib/sid/.zeroclaw/workspace/`)
- Cached with `OnceLock` (read once, reused)
- Prepended to system prompt with separator

### Auth

- `ANTHROPIC_OAUTH_TOKEN` env var required
- OAuth tokens (JWT or `sk-ant-oat01-` prefix): `Authorization: Bearer` + `anthropic-beta: oauth-2025-04-20`
- API keys: `x-api-key` header

### Model Override

- Client-sent model ignored; uses `state.model` (configured Claude model)

### Streaming (stream: true)

SSE translation:

| Anthropic Event | OpenAI Chunk |
|---|---|
| `message_start` | `delta: {"role": "assistant"}` |
| `content_block_start` type=tool_use | `delta: {"tool_calls": [{"index": N, "id": ID, "type": "function", "function": {"name": NAME, "arguments": ""}}]}` |
| `content_block_delta` text_delta | `delta: {"content": TEXT}` |
| `content_block_delta` input_json_delta | `delta: {"tool_calls": [{"index": N, "function": {"arguments": PARTIAL}}]}` |
| `message_delta` stop_reason=end_turn | `finish_reason: "stop"` |
| `message_delta` stop_reason=tool_use | `finish_reason: "tool_calls"` |
| `message_stop` | `data: [DONE]` |

### Non-streaming (stream: false or absent)

Returns complete `ChatCompletion` object with choices array.

### Defaults

- `max_tokens`: from request if present, default 4096
- Body limit: 1MB (HA sends large entity lists)

### Error Handling

- Missing `ANTHROPIC_OAUTH_TOKEN` → 500
- Anthropic non-200 → return body as OpenAI error format
- Connection failure → 502 Bad Gateway
