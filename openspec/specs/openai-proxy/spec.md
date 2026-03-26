# OpenAI-Compatible Agent Proxy

## Purpose

Provides an OpenAI-compatible `/v1/chat/completions` endpoint backed by the full ZeroClaw agent loop. Home Assistant's `extended_openai_conversation` integration sends OpenAI Chat Completions format requests; the proxy routes them through `crate::agent::process_message()` for full tool, memory, and skill support, and returns responses in OpenAI format.

## Behavior

### Request Translation

The proxy extracts user content from the OpenAI `messages` array and passes it to the agent loop as a single message string. System messages are prepended as context. The `tools` field in the request is accepted but ignored — the agent uses its own tool registry. Assistant and tool messages in the history are ignored (agent manages its own conversation state).

### Identity Injection

- `IDENTITY.md` read from workspace dir (`ZEROCLAW_WORKSPACE` env or `/var/lib/sid/.zeroclaw/workspace/`)
- Cached with `OnceLock` (read once, reused)
- Prepended to the message context passed to the agent

### Streaming (stream: true)

Single-burst SSE: the agent's complete response emitted as a sequence of OpenAI Chat Completions chunks:

| Step | SSE Data |
|---|---|
| 1 | `delta: {"role": "assistant"}` |
| 2 | `delta: {"content": "<full response>"}` |
| 3 | `finish_reason: "stop"` |
| 4 | `data: [DONE]` |

No token-by-token streaming — the full response is delivered in one burst.

### Non-streaming (stream: false or absent)

Returns complete `ChatCompletion` JSON object with the agent's response in `choices[0].message.content`.

### Defaults

- Body limit: 1MB (HA sends large entity lists)

### Error Handling

- Agent loop error → 500 with OpenAI error format
- Invalid JSON request → 400 with OpenAI error format

### Upstream Evaluation (v0.6.3)

The custom OpenAI proxy patches (0005, 0006) and `openai_proxy.rs` replacement file SHALL be evaluated against upstream's "parse proxy tool events from SSE stream" feature on each ZeroClaw upgrade. The custom implementation is retained only if upstream lacks: identity injection from IDENTITY.md, `/v1/models` endpoint, single-burst SSE streaming compatible with Home Assistant, or 1MB body limit.
