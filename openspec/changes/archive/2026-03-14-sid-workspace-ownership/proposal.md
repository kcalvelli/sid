## Why

Sid's workspace files (persona, skills, heartbeat tasks, etc.) are currently read-only Nix store symlinks. Every incremental change — adding a heartbeat task, tweaking a skill, updating the HA device map — requires a human to edit files in the git repo, rebuild NixOS, and restart the service. As Sid gains more capabilities (especially via HASS voice integration), this bottleneck blocks autonomous evolution. Sid should own his workspace files directly, storing them in a GitHub repo he manages, so he can adapt without human intervention.

## What Changes

- **BREAKING**: Workspace files (`AGENTS.md`, `IDENTITY.md`, `SOUL.md`, `TOOLS.md`, `HEARTBEAT.md`, `USER.md`) are no longer symlinked from the Nix store. They live as real, writable files in a Sid-owned GitHub repo cloned into `.zeroclaw/workspace/`.
- **BREAKING**: Skills directories (`skills/cynic/`, `skills/watchdog/`, `skills/email/`, `skills/mcp/`) are no longer symlinked from the Nix store. They are part of the workspace repo.
- Activation script changes from "symlink files on every rebuild" to "clone repo if `.git` doesn't exist, otherwise don't touch it."
- `git` added to zeroclaw service `PATH` and `allowed_commands`.
- Fine-grained GitHub PAT (scoped to `kcalvelli/sid-workspace`, `contents: write`) stored in agenix, injected as environment variable.
- Git credential helper configured so Sid can push without interactive auth.
- Legacy symlink location (`/var/lib/sid/workspace/`) removed.
- Seed files in `sid/workspace/` and `sid/skills/` retained as break-glass reference but removed from the activation flow.

## Capabilities

### New Capabilities
- `workspace-git-sync`: Sid's ability to commit and push workspace changes to his own GitHub repo. Covers clone-on-first-deploy, credential injection, auto-commit on logical work units, and push to remote.

### Modified Capabilities
<!-- No existing spec-level requirements are changing. The email, XMPP, and other channel
     capabilities are unaffected — only the deployment mechanism for workspace files changes. -->

## Impact

- **NixOS module** (`modules/nixos/default.nix`): Activation script rewritten for workspace section. Symlink logic removed, clone-if-missing logic added. Git + credential config added.
- **Secrets** (`secrets/`): New agenix secret for GitHub PAT.
- **Systemd service**: `git` added to PATH and allowed_commands. New env var for GitHub token.
- **GitHub**: New repo `kcalvelli/sid-workspace` created with current workspace content.
- **Runtime**: Sid gains write access to all workspace files and the ability to create new files/skills.
