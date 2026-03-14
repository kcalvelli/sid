## 1. GitHub Repo Setup

- [x] 1.1 Create `kcalvelli/sid-workspace` GitHub repo (private)
- [x] 1.2 Populate repo with current workspace files (`AGENTS.md`, `HEARTBEAT.md`, `IDENTITY.md`, `SOUL.md`, `TOOLS.md`, `USER.md`)
- [x] 1.3 Populate repo with current skills directories (`cynic/`, `watchdog/`, `email/`, `mcp/`)
- [x] 1.4 Copy live `MEMORY.md` from `/var/lib/sid/.zeroclaw/workspace/MEMORY.md` into the repo
- [x] 1.5 Add `.gitignore` excluding `memory/brain.db`, `.watchdog-state.json`, `*.tmp`
- [x] 1.6 Push initial commit to GitHub

## 2. Secrets Setup

- [x] 2.1 Create fine-grained GitHub PAT scoped to `kcalvelli/sid-workspace` with `contents: write`
- [x] 2.2 Encrypt PAT as agenix secret (`secrets/github-pat.age`)
- [x] 2.3 Add secret to `secrets/secrets.nix` with sid user access
- [x] 2.4 Re-key secrets if needed

## 3. NixOS Module Changes

- [x] 3.1 Add agenix secret declaration for `sid-github-pat` in the module
- [x] 3.2 Add `githubPatFile` variable pointing to `/run/agenix/sid-github-pat`
- [x] 3.3 Remove `workspaceFiles` list and `workspaceSrc`/`skillsSrc` references from activation flow
- [x] 3.4 Replace workspace symlink logic with clone-if-missing logic in activation script
- [x] 3.5 Add remote URL update step in activation script (re-embeds token on every rebuild for rotation support)
- [x] 3.6 Remove legacy `/var/lib/sid/workspace/` and `/var/lib/sid/skills/` symlink creation
- [x] 3.7 Add `SID_GITHUB_TOKEN` to the service environment file
- [x] 3.8 Ensure `git` remains in service PATH (already present — verify)

## 4. Testing and Migration

- [x] 4.1 Run `nix flake lock --update-input sid` in nixos_config
- [x] 4.2 Run `nixos-rebuild switch` on mini
- [x] 4.3 Verify workspace files are real files (not symlinks) owned by `sid:sid`
- [x] 4.4 Verify Sid can read and write workspace files
- [x] 4.5 Verify Sid can run `git add`, `git commit`, `git push` from workspace
- [x] 4.6 Verify `.gitignore` excludes runtime artifacts
- [x] 4.7 Verify config.toml, secrets, and service plumbing are unaffected
