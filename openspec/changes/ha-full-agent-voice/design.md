## Context

The OpenAI proxy (`openai_proxy.rs`) currently acts as a format translator: it receives OpenAI Chat Completions requests from Home Assistant, converts them to Anthropic Messages API format, sends a `reqwest` call to `https://api.anthropic.com/v1/messages`, and translates the response back. This makes Sid a passthrough — no tools, no memory, no skills.

Meanwhile, the `/webhook` endpoint already calls `run_gateway_chat_with_tools(state, message)` to invoke the full agent loop. The proxy should use the same path.

## Goals / Non-Goals

**Goals:**
- Route HA requests through the full agent loop so Sid can use tools (shell, memory, cron, email, skills)
- Maintain OpenAI Chat Completions format compatibility for HA's `extended_openai_conversation`
- Support both `stream: true` (SSE) and `stream: false` (JSON) response modes
- Keep the handler simple — delegate all agent work to `run_gateway_chat_with_tools`

**Non-Goals:**
- Token-by-token streaming (agent loop returns final response; burst SSE is sufficient for voice TTS)
- Surfacing intermediate tool calls to HA (agent resolves tools internally, returns final text)
- Using HA-provided tools (agent has its own tool registry)
- Multi-turn conversation state (each request is independent, same as webhook)

## Decisions

### 1. Use `run_gateway_chat_with_tools` as the backend

**Choice**: Call the same function the webhook handler uses.

**Rationale**: It already handles the full agent loop — tool execution, memory, skills, provider auth, model selection. No need to build a parallel integration path.

**Alternative considered**: Calling `agent::process_message()` directly — rejected because `run_gateway_chat_with_tools` already wraps it with proper context setup (session ID, tool registry, system prompt construction).

### 2. Extract user message from OpenAI message array

**Choice**: Take the last user message's text content from the OpenAI `messages` array. Prepend any system messages as context.

**Rationale**: `run_gateway_chat_with_tools` takes a single `&str` message. HA typically sends: system prompt (entity list + instructions) + user message (voice transcript). We concatenate system content and user content into a single string, separated clearly.

**Alternative considered**: Passing the full message history — rejected because the agent loop manages its own conversation context and the webhook pattern already works with single messages.

### 3. Single-burst SSE for streaming mode

**Choice**: For `stream: true`, emit the complete response as 3 SSE events: role chunk → content chunk → finish chunk → `[DONE]`.

**Rationale**: The agent loop returns a final string, not a token stream. HA's voice pipeline needs the full utterance for TTS anyway. HA's chat card handles both streaming and non-streaming. Single-burst SSE satisfies the streaming protocol contract without requiring infrastructure changes to the agent loop.

### 4. Ignore HA-provided tools

**Choice**: The `tools` field in the OpenAI request is accepted but ignored.

**Rationale**: HA sends its entity/service tools for the LLM to call back. But with the agent loop, Sid has its own tools (shell, memory, etc.) and doesn't need HA's. The agent decides what tools to use. HA tool calls would require a fundamentally different integration pattern (callback to HA) that's out of scope.

### 5. Keep identity injection via system prompt assembly

**Choice**: Still read `IDENTITY.md` and pass it as context to the agent. The agent loop's own system prompt construction handles this, but we also prepend HA's system messages as additional context.

**Rationale**: HA sends useful context in system messages (entity lists, room context). This should be passed to the agent as part of the user query context so Sid knows what devices are available.

### 6. Remove all Anthropic-specific code

**Choice**: Delete `AnthropicRequest`, `AnthropicMessage`, `AnthropicTool`, `translate_messages()`, `translate_tools()`, `get_auth()`, `AuthHeaders`, `PROXY_CLIENT`, and all Anthropic SSE parsing.

**Rationale**: The agent loop handles provider communication internally. These types and functions become dead code.

## Risks / Trade-offs

- **[Higher latency]** → Agent loop with tool execution takes longer than a direct API call. Mitigation: acceptable for voice (user expects a pause while Sid "thinks"), and the capability gain is worth it.
- **[No intermediate tool visibility]** → HA won't see tool_calls/tool responses in the chat history. Mitigation: HA's chat card shows the final response, which is what matters for voice. If HA tool integration is needed later, it's a separate feature.
- **[No real streaming]** → SSE burst means HA's chat card won't show incremental text. Mitigation: Voice pipeline doesn't benefit from incremental text anyway (TTS buffers). Chat card shows complete response, which is fine.
- **[System prompt merging]** → HA's system prompt (entity lists) merged into user message could confuse the agent if it's very long. Mitigation: HA already sends large entity lists (hence 1MB body limit); the agent handles large context well.
