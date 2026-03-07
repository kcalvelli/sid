# Design Decisions

## D1: Transparent proxy, not agent loop

The endpoint translates OpenAI format to Anthropic Messages API and streams back. HA owns the tool-calling loop — it defines tools, Claude decides which to call, HA executes them. ZeroClaw's internal agent loop is not involved.

## D2: Standalone module via file copy

`patches/openai_proxy.rs` is copied into `src/gateway/openai_proxy.rs` during postPatch. This keeps the proxy self-contained and avoids complex inline patches.

## D3: Auth from environment

Reads `ANTHROPIC_OAUTH_TOKEN` env var. Detects OAuth tokens (JWT or `sk-ant-oat01-` prefix) vs API keys and sets appropriate headers (`Authorization: Bearer` + beta header for OAuth, `x-api-key` for API keys).

## D4: Identity injection via IDENTITY.md

Reads `IDENTITY.md` from the ZeroClaw workspace directory (cached with `OnceLock`). Prepends to whatever system prompt HA sends, so Sid's personality comes through without HA-side configuration.

## D5: Model override

Ignores client-sent model, uses `state.model` (the configured Claude model). HA always sends "sid" as model name.

## D6: Sub-router with 1MB body limit

HA sends large entity lists in system prompts. The endpoint gets its own sub-router with `RequestBodyLimitLayer::new(1_048_576)` to handle this, merged before the gateway's default timeout layer.

## D7: SSE translation map

Anthropic SSE events are translated 1:1 to OpenAI chunks:
- `content_block_delta` text → `delta.content`
- `content_block_start/delta` tool_use → `delta.tool_calls`
- `message_delta` stop_reason → `finish_reason`
- `message_stop` → `[DONE]`
