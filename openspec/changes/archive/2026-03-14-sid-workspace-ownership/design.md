## Context

Sid's workspace files (6 markdown files + 4 skill directories) are currently read-only symlinks from the Nix store into `.zeroclaw/workspace/`. Only `MEMORY.md` is writable. Every content change requires a human to edit the git repo, rebuild NixOS, and restart the service. With Sid gaining capabilities via HASS voice integration, this bottleneck prevents autonomous evolution.

The NixOS module (`modules/nixos/default.nix`) manages workspace files via an activation script that creates symlinks on every rebuild. Config, secrets, and service plumbing remain Nix-managed and are not changing.

## Goals / Non-Goals

**Goals:**
- Sid owns all workspace files (markdown + skills) with full read/write access
- Workspace state persists in a GitHub repo (`kcalvelli/sid-workspace`) that Sid manages
- Nix activation bootstraps by cloning the repo on first deploy, then never touches workspace content again
- Sid can commit and push changes autonomously using batched, meaningful commits
- Nix continues to own config.toml, secrets, systemd unit, PATH, and allowed_commands

**Non-Goals:**
- Changing how config.toml, secrets, or service plumbing work
- Giving Sid the ability to modify his own Nix configuration
- Implementing a review/approval flow for workspace changes (accepted risk)
- Two-way sync between the sid repo's workspace files and the GitHub workspace repo

## Decisions

### 1. Workspace repo is the `.zeroclaw/workspace/` directory itself (Option A)

The entire `.zeroclaw/workspace/` directory becomes a git repo clone. No symlinks, no separate checkout location.

**Why not a separate repo cloned elsewhere with symlinks?** That reintroduces the exact symlink architecture we're eliminating. The whole point is real files Sid owns.

**Runtime artifacts** (brain.db, watchdog state, temp files) are excluded via `.gitignore`.

### 2. HTTPS + fine-grained PAT for GitHub auth

**Why not SSH deploy key?** SSH is classified as high-risk in ZeroClaw's security policy. Using HTTPS avoids needing to punch a hole in the command allowlist for `ssh`. A fine-grained PAT scoped to `kcalvelli/sid-workspace` with `contents: write` is minimal-privilege.

**Credential injection:** The PAT is stored as an agenix secret, injected as `SID_GITHUB_TOKEN` environment variable. The activation script configures the repo remote URL to embed the token (`https://x-access-token:${TOKEN}@github.com/...`), or alternatively configures a git credential helper. The token-in-URL approach is simpler and avoids needing a credential helper binary in PATH.

**Alternative considered:** Git credential helper with `store` backend. More complex, requires additional file management. Token-in-remote-URL is sufficient for a single-repo use case.

### 3. Clone-if-missing bootstrap strategy

The activation script checks for `.zeroclaw/workspace/.git`. If absent, it clones the repo. If present, it does nothing — Sid owns the workspace from that point forward.

**What if Sid deletes a file?** It stays deleted until Sid recreates it or resets from git. Nix won't re-seed it.

**What if the workspace needs to be rebuilt from scratch?** Delete `.zeroclaw/workspace/` and rebuild NixOS — the activation script will re-clone from GitHub.

### 4. Git added to allowed_commands

`git` is already in the service PATH. It needs to be in `allowed_commands` in config.toml for ZeroClaw's command allowlist to permit it. Currently `allowed_commands = ["*"]` (allow all), so this is already satisfied. If the policy ever tightens, `git` must be explicitly listed.

### 5. Legacy workspace location removed

`/var/lib/sid/workspace/` and `/var/lib/sid/skills/` (the legacy symlink locations) are no longer populated by the activation script. The activation script still creates `/var/lib/sid/` as the state directory but only `.zeroclaw/workspace/` matters.

### 6. Seed files in sid repo retained as break-glass

`workspace/` and `skills/` in the sid git repo are kept as reference copies. They are no longer referenced by the activation script. They serve as documentation and emergency recovery — if the GitHub repo is lost, these can be used to create a new one.

## Risks / Trade-offs

- **[Sid corrupts his workspace]** → Recovery: `git reset --hard` or delete workspace dir and let Nix re-clone from GitHub. The GitHub repo has full history.
- **[GitHub repo diverges from expectations]** → Keith can always inspect the repo, review commit history, or force-push a correction. Sid's commits create an audit trail.
- **[PAT token expires or is revoked]** → Sid can still read/write files locally. Push fails silently until token is rotated. Add monitoring or have Sid report push failures.
- **[Nix rebuild after migration]** → Activation script must handle the transition: existing symlinks in workspace dir need to be replaced with real files. The clone step handles this if we first remove the old symlink-populated directory. Migration plan below.
- **[Seed files drift from reality]** → Accepted. They're break-glass, not source of truth. Could be removed entirely in the future.

## Migration Plan

1. **Create GitHub repo** `kcalvelli/sid-workspace` with current workspace content (from `workspace/` and `skills/` in sid repo, plus existing `MEMORY.md` from the live workspace).
2. **Create agenix secret** for the fine-grained PAT.
3. **Update NixOS module**: replace symlink logic with clone-if-missing logic, add GitHub token env var.
4. **On first rebuild**: activation script detects no `.git` in workspace, removes old symlinks, clones repo.
5. **Verify**: Sid can read workspace files, commit changes, push to GitHub.
6. **Rollback**: If anything goes wrong, restore the symlink-based activation script (it's all in git). Sid's workspace content is safe in the GitHub repo regardless.
