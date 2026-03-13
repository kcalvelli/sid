## MODIFIED Requirements

### Requirement: Request Translation
The proxy SHALL extract user content from the OpenAI `messages` array and pass it to the agent loop as a single message string. System messages SHALL be prepended as context. The `tools` field in the request SHALL be accepted but ignored — the agent uses its own tool registry. Assistant and tool messages in the history SHALL be ignored (agent manages its own conversation state).

#### Scenario: Simple user message
- **WHEN** HA sends a Chat Completions request with a system message and a user message
- **THEN** the proxy SHALL concatenate the system message content and user message content, separated by a newline, and pass it to `run_gateway_chat_with_tools`

#### Scenario: Request with tools field
- **WHEN** HA sends a request with a `tools` array containing HA entity/service tools
- **THEN** the proxy SHALL accept the request without error but SHALL NOT pass the tools to the agent loop

#### Scenario: Multi-turn history
- **WHEN** HA sends a request with multiple assistant/user/tool messages in the history
- **THEN** the proxy SHALL extract only the system messages and the last user message for the agent call

### Requirement: Auth
The proxy SHALL NOT read `ANTHROPIC_OAUTH_TOKEN` or perform any provider authentication. The agent loop SHALL handle all provider auth internally via the configured provider registry.

#### Scenario: No auth env var
- **WHEN** `ANTHROPIC_OAUTH_TOKEN` is not set in the environment
- **THEN** the proxy SHALL still accept requests (agent loop handles its own auth)

### Requirement: Streaming (stream: true)
The proxy SHALL emit the agent's complete response as a single-burst SSE sequence in OpenAI Chat Completions chunk format: role chunk (`{"role": "assistant"}`), content chunk (`{"content": "<full response>"}`), finish chunk (`{"finish_reason": "stop"}`), then `[DONE]`.

#### Scenario: Streaming voice request
- **WHEN** HA sends a request with `stream: true` and the agent returns a text response
- **THEN** the proxy SHALL return an SSE stream with exactly 3 data events plus `[DONE]`, containing the complete response text in the content chunk

#### Scenario: Streaming with agent tool use
- **WHEN** the agent internally uses tools (e.g., shell) to produce the response
- **THEN** the SSE stream SHALL contain only the final text response, not intermediate tool calls

### Requirement: Non-streaming (stream: false or absent)
The proxy SHALL return a complete OpenAI `ChatCompletion` JSON object with the agent's response in `choices[0].message.content`.

#### Scenario: Non-streaming request
- **WHEN** HA sends a request with `stream: false` or no `stream` field
- **THEN** the proxy SHALL return a JSON response with `object: "chat.completion"`, `finish_reason: "stop"`, and the agent's response as `content`

### Requirement: Identity Injection
`IDENTITY.md` SHALL still be read from the workspace directory and cached. It SHALL be included as part of the context passed to the agent.

#### Scenario: Identity available
- **WHEN** `IDENTITY.md` exists in the workspace directory
- **THEN** the identity content SHALL be prepended to the system context passed to the agent

#### Scenario: Identity missing
- **WHEN** `IDENTITY.md` does not exist or is empty
- **THEN** the proxy SHALL proceed without identity context

### Requirement: Error Handling
The proxy SHALL return OpenAI-format error responses for failures.

#### Scenario: Agent loop error
- **WHEN** `run_gateway_chat_with_tools` returns an error
- **THEN** the proxy SHALL return a 500 status with an OpenAI error JSON body

#### Scenario: Invalid JSON request
- **WHEN** the request body is not valid JSON or missing required fields
- **THEN** the proxy SHALL return a 400 status with an OpenAI error JSON body

## REMOVED Requirements

### Requirement: Anthropic API Communication
**Reason**: Replaced by agent loop invocation. The proxy no longer communicates directly with the Anthropic API.
**Migration**: All Anthropic API communication is handled internally by the agent loop via the provider registry.

### Requirement: Anthropic SSE Translation
**Reason**: Replaced by single-burst SSE from agent response. No Anthropic SSE events to parse.
**Migration**: Streaming responses are now constructed from the agent's final text response.

### Requirement: Model Override
**Reason**: Agent loop handles model selection via config. The proxy no longer needs to override the model.
**Migration**: Model is configured in `config.toml` and used by the agent loop automatically.
