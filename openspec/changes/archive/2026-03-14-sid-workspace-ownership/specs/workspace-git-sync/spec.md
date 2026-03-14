## ADDED Requirements

### Requirement: Workspace repo bootstrap on first deploy
The activation script SHALL clone the GitHub repo `kcalvelli/sid-workspace` into `.zeroclaw/workspace/` when no `.git` directory exists in that location. The clone SHALL use HTTPS with the GitHub PAT token for authentication. After cloning, ownership SHALL be set to `sid:sid` recursively.

#### Scenario: First deploy on clean system
- **WHEN** the NixOS activation script runs and `.zeroclaw/workspace/.git` does not exist
- **THEN** the script clones `https://github.com/kcalvelli/sid-workspace.git` into `.zeroclaw/workspace/`
- **AND** sets ownership of all files to `sid:sid`

#### Scenario: Subsequent rebuild on existing system
- **WHEN** the NixOS activation script runs and `.zeroclaw/workspace/.git` already exists
- **THEN** the script does not modify any files in `.zeroclaw/workspace/`

#### Scenario: Migration from symlink-based workspace
- **WHEN** the activation script runs for the first time after this change and `.zeroclaw/workspace/` contains symlinks but no `.git` directory
- **THEN** the script removes the existing workspace directory contents and clones the repo fresh

### Requirement: GitHub PAT secret management
The system SHALL store a fine-grained GitHub PAT as an agenix secret and inject it as the `SID_GITHUB_TOKEN` environment variable in the zeroclaw service.

#### Scenario: Token available at service start
- **WHEN** the zeroclaw service starts
- **THEN** the `SID_GITHUB_TOKEN` environment variable is set with the decrypted PAT value

#### Scenario: Token used for git remote authentication
- **WHEN** the activation script clones the workspace repo
- **THEN** it uses the PAT token in the remote URL for HTTPS authentication

### Requirement: Git remote configured for push access
The workspace repo SHALL have its remote origin configured with embedded HTTPS credentials so that `git push` works without interactive authentication.

#### Scenario: Sid pushes a commit
- **WHEN** Sid runs `git push` in the workspace directory
- **THEN** the push succeeds using the embedded PAT token without prompting for credentials

#### Scenario: Token rotation
- **WHEN** the PAT token is rotated in agenix and NixOS is rebuilt
- **THEN** the activation script updates the remote URL with the new token

### Requirement: Workspace files are real writable files
All workspace markdown files and skill directories SHALL be real files owned by `sid:sid` with write permission, not symlinks to the Nix store.

#### Scenario: Sid edits a workspace file
- **WHEN** Sid writes to any file in `.zeroclaw/workspace/` (e.g., `HEARTBEAT.md`, `IDENTITY.md`)
- **THEN** the write succeeds and the file contains the updated content

#### Scenario: Sid creates a new skill
- **WHEN** Sid creates a new directory under `.zeroclaw/workspace/skills/` with a `SKILL.md` file
- **THEN** the skill is available to ZeroClaw on next load

#### Scenario: Sid creates a new workspace file
- **WHEN** Sid creates a new markdown file in `.zeroclaw/workspace/`
- **THEN** the file persists across service restarts and NixOS rebuilds

### Requirement: Runtime artifacts excluded from git
The workspace repo SHALL include a `.gitignore` that excludes runtime artifacts that should not be version controlled.

#### Scenario: SQLite database not tracked
- **WHEN** the workspace contains `memory/brain.db`
- **THEN** the file is excluded from git tracking

#### Scenario: Watchdog state not tracked
- **WHEN** the workspace contains `.watchdog-state.json`
- **THEN** the file is excluded from git tracking

#### Scenario: Temporary files not tracked
- **WHEN** the workspace contains files matching `*.tmp`
- **THEN** they are excluded from git tracking

### Requirement: Legacy workspace symlinks removed
The activation script SHALL NOT create symlinks in `/var/lib/sid/workspace/` or `/var/lib/sid/skills/`. These legacy locations are no longer populated.

#### Scenario: NixOS rebuild after migration
- **WHEN** the activation script runs
- **THEN** no symlinks are created in `/var/lib/sid/workspace/` or `/var/lib/sid/skills/`
- **AND** no symlinks are created from the Nix store into `.zeroclaw/workspace/`

### Requirement: Git available as allowed command
`git` SHALL be available in the zeroclaw service PATH and permitted by the command allowlist so Sid can execute git operations.

#### Scenario: Sid runs git commands
- **WHEN** Sid executes `git add`, `git commit`, or `git push` via the shell tool
- **THEN** the commands execute successfully without being blocked by the security policy
