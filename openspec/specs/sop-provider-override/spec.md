## ADDED Requirements

### Requirement: Per-SOP provider and model override
The SOP TOML schema SHALL support optional `provider` and `model` fields that override the primary agent's provider for that SOP's execution.

#### Scenario: SOP with provider override
- **WHEN** an SOP defines `provider = "anthropic"` and `model = "claude-haiku-4-5"` in its `SOP.toml`
- **THEN** the SOP engine SHALL create a dedicated provider instance for that SOP's step execution using the specified provider and model

#### Scenario: SOP without provider override
- **WHEN** an SOP does not specify `provider` or `model`
- **THEN** the SOP engine SHALL use the primary agent's provider (current behavior, backward compatible)

#### Scenario: Invalid provider name
- **WHEN** an SOP specifies a provider name that doesn't exist or can't be created
- **THEN** the SOP engine SHALL log a warning and skip that SOP during loading (fail-closed, don't fall back silently)

### Requirement: SOP failure notification
The system SHALL send a Pushover notification when an SOP run fails, including the SOP name, failed step, and error context.

#### Scenario: SOP step fails
- **WHEN** a worker executing an SOP step encounters an error after provider-level retries are exhausted
- **THEN** the system SHALL mark the run as failed, log to audit trail, and send a Pushover notification with SOP name, step name, and error message
