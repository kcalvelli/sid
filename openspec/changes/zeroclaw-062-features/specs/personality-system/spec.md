## ADDED Requirements

### Requirement: Native identity loading from workspace
ZeroClaw SHALL load `SOUL.md` and `IDENTITY.md` from the workspace directory as the agent's personality and identity, injecting their content into the system prompt for all interactions.

#### Scenario: Personality loaded on startup
- **WHEN** ZeroClaw starts with `SOUL.md` and `IDENTITY.md` present in the workspace
- **THEN** the agent's system prompt SHALL include the content of both files, applied consistently across all channels and sessions

#### Scenario: Missing personality files
- **WHEN** either `SOUL.md` or `IDENTITY.md` is missing from the workspace
- **THEN** ZeroClaw SHALL log a warning and operate without the missing personality component

### Requirement: AGENTS.md bootstrap deprecation
Once native identity loading is enabled, the manual `AGENTS.md` bootstrap instructions that duplicate SOUL.md/IDENTITY.md content SHALL be removed from the workspace.

#### Scenario: No duplicate personality sources
- **WHEN** native identity loading is active
- **THEN** `AGENTS.md` SHALL NOT contain personality or identity directives that duplicate SOUL.md/IDENTITY.md content

### Requirement: Identity configuration
The NixOS module SHALL include an `[identity]` configuration section that specifies workspace-based identity loading.

#### Scenario: Identity config in config.toml
- **WHEN** the NixOS module generates `config.toml`
- **THEN** it SHALL include an `[identity]` section pointing to workspace files for personality loading
