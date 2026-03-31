# Upstream Sync

## Purpose

Defines the branch strategy and workflow for maintaining the `kcalvelli/zeroclaw-nix` fork and syncing with upstream `zeroclaw-labs/zeroclaw` releases.

## Requirements

### Requirement: Two-branch structure
The fork SHALL maintain two branches: `upstream/master` (read-only tracking of zeroclaw-labs) and `main` (release tag + nix packaging + feature patches). The `upstream/master` branch SHALL contain zero commits not present in the original zeroclaw-labs repository. `main` SHALL be the default branch.

#### Scenario: Inspect branch lineage
- **WHEN** examining the fork's git history
- **THEN** `main` SHALL be a descendant of a zeroclaw release tag with nix packaging and feature patch commits on top

#### Scenario: upstream/master is clean
- **WHEN** comparing `upstream/master` to the zeroclaw-labs remote
- **THEN** they SHALL be identical — no fork-specific commits

#### Scenario: List fork-specific commits
- **WHEN** running `git log upstream/master..main --oneline`
- **THEN** the output SHALL show only nix packaging commits and feature patch commits — nothing else

### Requirement: Nix packaging commits on main only
Nix-specific files (`flake.nix`, `flake.lock`, `nix/*.nix`) SHALL exist only on `main`, never on `upstream/master`. These files SHALL be added as commits on top of the release tag when creating the `main` branch.

#### Scenario: upstream/master has no nix files
- **WHEN** checking out `upstream/master`
- **THEN** no `flake.nix`, `flake.lock`, or `nix/` directory SHALL exist

#### Scenario: main includes nix packaging
- **WHEN** checking out `main`
- **THEN** `flake.nix`, `nix/package.nix`, `nix/web.nix`, `nix/desktop.nix`, and `nix/module.nix` SHALL exist

### Requirement: Upstream sync via merge to main
When upstream releases a new version, the sync workflow SHALL be: (1) fetch and fast-forward `upstream/master`, (2) merge the new release tag into `main`. Nix packaging commits survive because they touch files upstream doesn't have. Feature patch commits may conflict on files they modify — conflicts are resolved inline during the merge.

#### Scenario: Upstream releases v0.6.6
- **WHEN** zeroclaw-labs publishes v0.6.6 and the fork syncs
- **THEN** `upstream/master` SHALL fast-forward to include v0.6.6, and `main` SHALL contain a merge commit bringing v0.6.6 changes in alongside the existing nix and feature commits

#### Scenario: Nix files do not conflict with upstream
- **WHEN** merging a new upstream tag into `main`
- **THEN** the merge SHALL not conflict on nix-specific files because upstream does not have them

#### Scenario: Feature patch conflicts with upstream
- **WHEN** merging a new upstream tag and a feature patch touches a file that upstream also changed
- **THEN** the conflict SHALL be resolved in the merge commit with a message noting what was adjusted

### Requirement: Absorbed patches dropped during sync
If an upstream release absorbs a custom feature (making the fork's commit unnecessary), the redundant commit SHALL be reverted or squashed out of `main` during the sync, with the merge commit message noting which patches were absorbed.

#### Scenario: Patch absorbed by upstream
- **WHEN** upstream v0.6.6 includes the email reply-threading fix that exists as a commit on `main`
- **THEN** the merge commit message SHALL note "Absorbed upstream: email reply-threading" and the redundant code SHALL be resolved in favor of upstream's implementation

### Requirement: Upstream remote configuration
The fork SHALL configure `upstream` as a git remote pointing to `https://github.com/zeroclaw-labs/zeroclaw.git`. When the remote is unreachable (account suspended), fetch operations SHALL fail gracefully without affecting the fork's usability. The remote SHALL be documented so future maintainers know its purpose.

#### Scenario: Upstream reachable
- **WHEN** `git fetch upstream` succeeds
- **THEN** `upstream/master` SHALL be updated and new tags SHALL be available for sync

#### Scenario: Upstream unreachable
- **WHEN** `git fetch upstream` fails (404, timeout)
- **THEN** the fork SHALL continue to function normally — all builds, branches, and workflows operate on local state only

### Requirement: Sync checklist documented in SYNC.md
The fork SHALL include a `SYNC.md` documenting the step-by-step upstream sync process: fetch, merge tag, update nix hashes, build, test, push. This document SHALL be the authoritative reference for performing syncs.

#### Scenario: New maintainer performs sync
- **WHEN** a person unfamiliar with the fork reads the sync documentation
- **THEN** they SHALL be able to perform a complete upstream sync by following the documented steps without additional context
