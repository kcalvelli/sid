## ADDED Requirements

### Requirement: Cost-optimized provider routing strategy
The system SHALL support a `routing_strategy` config option that selects providers based on cost when multiple providers can serve a request. When set to `"cost_optimized"`, the system MUST prefer the cheapest provider that meets the request's model requirements.

#### Scenario: Cost-optimized routing selects cheapest provider
- **WHEN** `routing_strategy = "cost_optimized"` is configured and a request can be served by either `anthropic` (direct) or `claude-code` (no API cost)
- **THEN** the system routes to the provider with the lowest per-token cost as defined in `[cost.prices]`

#### Scenario: Routing respects provider availability
- **WHEN** `routing_strategy = "cost_optimized"` is configured and the cheapest provider is unavailable
- **THEN** the system falls back to the next cheapest available provider

### Requirement: Per-provider max_tokens configuration
The system SHALL support `max_tokens` as a per-provider config key, allowing different token limits for different providers and models.

#### Scenario: Worker agent uses lower max_tokens than primary
- **WHEN** `[agents.worker]` is configured with `max_tokens = 2048` and the primary provider has `max_tokens = 8192`
- **THEN** requests through the worker agent are sent with `max_tokens = 2048` and primary requests use `max_tokens = 8192`

#### Scenario: Default max_tokens when not specified
- **WHEN** a provider config omits `max_tokens`
- **THEN** the system uses the upstream default for that model
