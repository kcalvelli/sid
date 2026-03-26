## ADDED Requirements

### Requirement: User notification on provider fallback
The system SHALL notify the user when a provider fallback occurs, indicating which provider was unavailable and which fallback was used.

#### Scenario: Fallback notification in channel
- **WHEN** the primary provider fails and the system falls back to the `anthropic` provider
- **THEN** the user receives a notification in the active channel indicating the fallback occurred

#### Scenario: Notification does not interrupt response
- **WHEN** a fallback notification is generated
- **THEN** the notification is delivered as metadata or a brief prefix, not as a separate message that breaks conversation flow
