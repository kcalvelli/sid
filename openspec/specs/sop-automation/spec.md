## MODIFIED Requirements

### Requirement: SOP definitions stored in workspace
SOP definitions SHALL be stored in the git-synced workspace directory under `sops/`, not in the NixOS module or system config. SOP definitions SHALL include provider and model fields to enable native execution.

#### Scenario: Morning briefing SOP with native provider
- **WHEN** the `morning-briefing` SOP is loaded
- **THEN** its `SOP.toml` SHALL specify `provider = "anthropic"` and `model = "claude-sonnet-4-6"` (Sonnet because it produces user-facing email content requiring Sid-lite voice)

#### Scenario: Session review SOP with native provider
- **WHEN** the `session-review` SOP is loaded
- **THEN** its `SOP.toml` SHALL specify `provider = "anthropic"` and `model = "claude-sonnet-4-6"` (Sonnet because it writes to persistent memory)

#### Scenario: Stay-quiet SOP with native provider
- **WHEN** the `stay-quiet` SOP is loaded
- **THEN** its `SOP.toml` SHALL specify `provider = "anthropic"` and `model = "claude-haiku-4-5"` (Haiku because it only checks for alerts, no judgment needed)
