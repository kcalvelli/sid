## ADDED Requirements

### Requirement: Webhook endpoint invokes the full agent loop

The gateway `/webhook` endpoint SHALL invoke the full agent loop with tools and skills when processing a request. The webhook handler SHALL call `run_gateway_chat_with_tools()` (or equivalent agent entry point) instead of `run_gateway_chat_simple()`. The system prompt SHALL include all registered tools, skills, and the tool use protocol specification. The agent loop SHALL iterate up to `max_tool_iterations` times, executing tool calls as they occur.

#### Scenario: Webhook request triggers tool use
- **WHEN** an authenticated POST request is sent to `/webhook` with `{"message": "What's the server uptime?"}`
- **THEN** the agent loop SHALL execute, the agent SHALL be able to invoke the shell tool to run `uptime`, and the response SHALL include the tool's output

#### Scenario: Webhook request with no tool use needed
- **WHEN** an authenticated POST request is sent to `/webhook` with `{"message": "Hello, how are you?"}`
- **THEN** the agent loop SHALL execute but complete in a single iteration with a conversational response (no tools invoked)

#### Scenario: Agent loop respects max_tool_iterations
- **WHEN** the agent loop reaches the configured `max_tool_iterations` limit during a webhook request
- **THEN** the loop SHALL stop iterating and return the last response to the HTTP client

### Requirement: Webhook requests use ephemeral sessions

Each webhook request SHALL generate a unique ephemeral session ID (format: `webhook-<uuid>`). The session SHALL exist only for the duration of the request's agent loop iterations. The session SHALL NOT persist across separate HTTP requests.

#### Scenario: Each request gets an isolated session
- **WHEN** two concurrent POST requests are sent to `/webhook`
- **THEN** each request SHALL have its own independent session ID and agent loop state

### Requirement: Webhook authentication unchanged

The webhook endpoint SHALL continue to require a valid paired token in the `Authorization: Bearer <token>` header. Unauthenticated requests SHALL be rejected before the agent loop is invoked.

#### Scenario: Authenticated request with tools
- **WHEN** a POST request with a valid Bearer token is sent to `/webhook`
- **THEN** the request SHALL be authenticated and processed through the agent loop with full tool access

#### Scenario: Unauthenticated request rejected
- **WHEN** a POST request without a valid Bearer token is sent to `/webhook`
- **THEN** the request SHALL be rejected with an appropriate HTTP error status before any agent processing occurs

### Requirement: Webhook response format preserved

The webhook response SHALL remain a JSON object with `model` and `response` fields. The `response` field SHALL contain the agent's final text response after all tool iterations complete. Tool call/result details SHALL NOT appear in the response body.

#### Scenario: Response after tool use
- **WHEN** the agent uses tools during a webhook request and produces a final text response
- **THEN** the HTTP response SHALL be `{"model": "<model>", "response": "<final text>"}` with no tool call artifacts in the response field
