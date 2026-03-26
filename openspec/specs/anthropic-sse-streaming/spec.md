## ADDED Requirements

### Requirement: SSE streaming on anthropic provider
The anthropic provider SHALL support Server-Sent Events (SSE) streaming for chat responses, delivering tokens incrementally to channels that support streaming.

#### Scenario: Streaming response via anthropic fallback
- **WHEN** the primary provider (claude-code) is unavailable and the system falls back to anthropic
- **THEN** the anthropic provider delivers the response as an SSE stream rather than waiting for the complete response

#### Scenario: Non-streaming channels receive complete response
- **WHEN** a channel does not support streaming (e.g., email, Telegram)
- **THEN** the anthropic provider buffers the SSE stream internally and delivers a complete response to the channel
