## Context

The ZeroClaw gateway exposes two HTTP paths:

1. **`POST /webhook`** — calls `run_gateway_chat_simple()`, which builds a system prompt with empty tools/skills arrays and makes a single LLM call via `provider.chat_with_history()`. No agent loop, no tool execution.
2. **Channel handlers** (WhatsApp, Email, XMPP, etc.) — call `run_gateway_chat_with_tools()`, which delegates to `crate::agent::process_message_with_session()`. This runs the full agent loop: system prompt includes tool specs and protocol, tool calls are parsed and executed iteratively up to `max_tool_iterations`.

The webhook endpoint already has access to the `AppState` which contains `tools_registry_exec` — the executable tools are loaded and ready, the webhook just doesn't use them.

## Goals / Non-Goals

**Goals:**
- Webhook requests go through the full agent loop with tools and skills
- HTTP clients get the same agent capabilities as channel-based messages
- No config changes required — existing `[gateway]` and `[autonomy]` settings apply

**Non-Goals:**
- Streaming intermediate tool calls back to the caller — HA's conversation agent expects a single response string, not a stream of events
- Multi-turn conversation sessions across separate HTTP requests (each request is independent)
- OpenAI-compatible `/v1/chat/completions` endpoint (config exists but isn't wired up — separate concern)

## Decisions

### Use `run_gateway_chat_with_tools()` instead of `run_gateway_chat_simple()`

**Decision**: Modify `handle_webhook()` to call `run_gateway_chat_with_tools()` for the non-streaming path.

**Rationale**: This function already exists, is battle-tested by all channel handlers, and handles the full agent loop including tool parsing, execution, and iteration. No need to build a new code path.

**Alternative considered**: Modifying `prepare_gateway_messages_for_provider()` to pass tools — rejected because that only adds tools to the prompt without the execution loop, so tool calls would appear in output but never execute.

### Blocking wait-for-completion semantics

**Decision**: The HTTP handler holds the connection open while the agent loop runs to completion (potentially several seconds for complex tool use), then returns the final text response. No intermediate tool call events are sent to the caller.

**Rationale**: The primary consumer is Home Assistant's conversation agent, which expects a single response string back. HA's voice pipeline is already waiting on Whisper + LLM + Piper, so a few extra seconds for tool execution is fine. Streaming intermediate tool calls would complicate the HA integration significantly for no benefit.

### Per-request ephemeral sessions

**Decision**: Generate a unique session ID per webhook request (e.g., `webhook-<uuid>`) rather than requiring clients to supply one.

**Rationale**: The webhook is stateless between requests. Within a single request, the agent loop may iterate multiple times (tool call → result → next call), and `process_message_with_session` needs a session ID for that iteration context. Using an ephemeral ID keeps each request isolated without requiring client-side session management.

### Patch applied via `flake.nix` postPatch

**Decision**: Add the change as a Python patch in `flake.nix`'s `postPatch` phase, consistent with existing patches (XMPP channel, message timestamps).

**Rationale**: All ZeroClaw source modifications are applied this way. Keeps patches co-located and versioned with the Nix build.

## Risks / Trade-offs

- **[Longer response times]** → The agent loop may make multiple LLM calls + tool executions per request. HTTP clients need appropriate timeouts. Mitigation: `max_tool_iterations` caps iteration count.
- **[Tool side effects from unauthenticated callers]** → Paired token auth already gates access. Mitigation: existing `[autonomy]` config controls which commands are allowed and blocked.
- **[Upstream divergence]** → Future ZeroClaw updates may change `handle_webhook()` or `run_gateway_chat_with_tools()` signatures. Mitigation: postPatch will fail at build time if signatures change, making it obvious.
