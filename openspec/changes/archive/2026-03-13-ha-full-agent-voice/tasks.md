## 1. Strip Anthropic Backend

- [x] 1.1 Remove `AnthropicRequest`, `AnthropicMessage`, `AnthropicTool` structs
- [x] 1.2 Remove `translate_messages()`, `translate_tools()`, `content_to_string()` functions
- [x] 1.3 Remove `get_auth()`, `AuthHeaders` struct, `PROXY_CLIENT` static
- [x] 1.4 Remove `reqwest`, `tokio_util`, `tokio::io::AsyncBufReadExt`, `StreamReader` imports
- [x] 1.5 Remove Anthropic SSE parsing in `handle_streaming()`

## 2. Agent Loop Integration

- [x] 2.1 Add import for `run_gateway_chat_with_tools` from gateway module
- [x] 2.2 Write `extract_message()` helper: extract system messages + last user message from OAI messages array, concatenate into single string with identity prepended
- [x] 2.3 Rewrite `handle_chat_completions()` to call `run_gateway_chat_with_tools(state, message)` instead of building/sending Anthropic request

## 3. Response Formatting

- [x] 3.1 Rewrite `handle_non_streaming()`: take agent response string, return OpenAI `ChatCompletion` JSON with `choices[0].message.content` set to the response
- [x] 3.2 Rewrite `handle_streaming()`: take agent response string, emit single-burst SSE (role chunk → content chunk → finish chunk → `[DONE]`)
- [x] 3.3 Keep `oai_chunk()` helper and `error_response()` helper (still needed)

## 4. Cleanup and Patch Update

- [x] 4.1 Update the patch file that adds `openai_proxy.rs` to the build (ensure new source compiles)
- [x] 4.2 Verify `ChatCompletionsRequest` and `OaiMessage` types are retained (still needed for request parsing)
- [x] 4.3 Remove unused `OaiToolCall`, `OaiFunction`, `OaiTool`, `OaiToolFunction` types if no longer referenced

## 5. Spec Update

- [x] 5.1 Update `openspec/specs/openai-proxy/spec.md` to reflect agent-loop backend (sync delta spec)
