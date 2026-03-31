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

### Source Location

The OpenAI-compatible proxy implementation (`openai_proxy.rs`) SHALL exist as a committed file at `src/gateway/openai_proxy.rs` in the fork's `main` branch. The `/v1/models` endpoint and `/v1/chat/completions` wiring SHALL also be commits on `main`. These files SHALL NOT be copied from an external location during build.

#### Scenario: Source file location
- **WHEN** checking out the `main` branch of the fork
- **THEN** `src/gateway/openai_proxy.rs` SHALL exist as a tracked file in the repository

#### Scenario: Endpoint wiring committed
- **WHEN** viewing the diff of the OpenAI proxy commits on `main`
- **THEN** the gateway route registration for `/v1/models` and `/v1/chat/completions` SHALL be visible in the commit diff

### Upstream Evaluation on Sync

The custom OpenAI proxy commits SHALL be evaluated against upstream's capabilities on each upstream sync. The custom implementation is retained only if upstream lacks: identity injection from IDENTITY.md, `/v1/models` endpoint, single-burst SSE streaming compatible with Home Assistant, or 1MB body limit. If upstream provides equivalent functionality, the proxy commits SHALL be dropped from `main`.

#### Scenario: Upstream adds OpenAI-compatible endpoint
- **WHEN** a new upstream release includes a `/v1/chat/completions` endpoint with identity injection and HA-compatible streaming
- **THEN** the custom proxy commits SHALL be dropped from `main` during merge, with a commit message noting the upstream absorption

#### Scenario: Upstream endpoint lacks required features
- **WHEN** upstream's endpoint does not support identity injection or single-burst SSE
- **THEN** the custom proxy commits SHALL be retained on `main`
