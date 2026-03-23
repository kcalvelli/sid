## ADDED Requirements

### Requirement: SOP subsystem enabled in daemon config
The system SHALL enable the SOP subsystem in the ZeroClaw config with `sops_dir` pointing to the workspace sops directory.

#### Scenario: Daemon starts with SOP config
- **WHEN** the ZeroClaw daemon starts
- **THEN** the generated `config.toml` SHALL include a `[sop]` section with `enabled = true`, `sops_dir` pointing to the workspace `sops/` directory, and `default_execution_mode = "supervised"`

### Requirement: SOP definitions stored in workspace
SOP definitions SHALL be stored in the git-synced workspace directory under `sops/`, not in the NixOS module or system config.

#### Scenario: SOP directory exists in workspace
- **WHEN** the workspace is initialized
- **THEN** a `sops/` directory SHALL exist containing SOP definitions as subdirectories with `SOP.toml` and optional `SOP.md` files

#### Scenario: SOPs sync to GitHub
- **WHEN** the hourly `sid-workspace-push` timer fires
- **THEN** any new or modified SOP definitions SHALL be committed and pushed alongside other workspace changes

### Requirement: Cron-triggered SOPs use supervised execution mode
All initial SOP definitions SHALL use `execution_mode = "supervised"` with cron triggers to prevent unattended automation until confidence is established.

#### Scenario: SOP triggers on schedule
- **WHEN** a cron-triggered SOP fires
- **THEN** execution SHALL request approval before starting (supervised mode) and log the run to the SOP audit trail

#### Scenario: Approval timeout on normal-priority SOP
- **WHEN** a supervised SOP is waiting for approval and the approval timeout expires
- **THEN** the SOP SHALL remain in `WaitingApproval` status (normal priority SOPs do not auto-approve)
