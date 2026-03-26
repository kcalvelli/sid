## MODIFIED Requirements

### Requirement: Evaluate upstream SSE proxy against custom implementation
The custom OpenAI proxy patches (0005, 0006) and `openai_proxy.rs` replacement file SHALL be evaluated against v0.6.3's upstream "parse proxy tool events from SSE stream" feature. The custom implementation is retained only if upstream lacks: identity injection from IDENTITY.md, `/v1/models` endpoint, single-burst SSE streaming compatible with Home Assistant, or 1MB body limit.

#### Scenario: Upstream provides equivalent functionality
- **WHEN** v0.6.3's built-in proxy provides `/v1/models`, `/v1/chat/completions` with agent loop routing, identity injection, and SSE streaming
- **THEN** patches 0005/0006 and `openai_proxy.rs` are dropped, and the upstream config is used

#### Scenario: Upstream is partial
- **WHEN** v0.6.3's built-in proxy lacks identity injection or Home Assistant compatibility
- **THEN** the custom patches are retained and rebased onto v0.6.3, layering on top of upstream changes
