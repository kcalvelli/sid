## REMOVED Requirements

### Requirement: Patches applied via Nix patches attribute
**Reason**: Patches are now commits on the fork's `main` branch. The Nix derivation builds from the fork's source directly — no `patches` attribute needed.
**Migration**: All 10 server patches and 2 desktop patches are applied as git commits on `main` of `kcalvelli/zeroclaw-nix`. The `patches` attribute in `buildRustPackage` is removed.

### Requirement: One patch file per logical feature
**Reason**: Replaced by git commits. Each logical feature is a commit on `main` with a descriptive message, providing the same traceability without the `.patch` file format.
**Migration**: Patch numbering (`0001-`, `0002-`) is replaced by git commit order on `main`.

### Requirement: New source files copied in postPatch
**Reason**: `xmpp.rs` and `openai_proxy.rs` are committed directly into the fork's source tree at their correct paths (`src/channels/xmpp.rs`, `src/gateway/openai_proxy.rs`). No `postPatch` copy step needed.
**Migration**: Files move from `sid-repo/patches/` to `zeroclaw-nix/src/` as commits on `main`.

### Requirement: Python3 not required for patching
**Reason**: No patching step exists. The fork builds from committed source.
**Migration**: Requirement is satisfied by default — no action needed.

### Requirement: Identical build output
**Reason**: The fork's source tree is the final source tree — there is no "before and after patching" to compare. Build reproducibility is guaranteed by nix's fixed-output derivation and cargo hash pinning.
**Migration**: Verification is a one-time check during initial fork creation: confirm the built binary from the fork matches the previously-deployed binary.

### Requirement: Patch inventory matches existing features
**Reason**: The concept of a "patch inventory" is replaced by `main` commit log. `git log main..sid --oneline` shows all custom features.
**Migration**: The 10 server patches and 2 desktop patches become commits. The inventory is the branch diff.

## ADDED Requirements

### Requirement: Custom features are commits on the sid branch
Each custom feature or fix that diverges from upstream ZeroClaw SHALL be a single commit (or minimal commit chain) on `main`. Each commit message SHALL describe the feature, following conventional commit format (e.g., `feat: wire XMPP channel`, `fix: skip noreply emails`).

#### Scenario: List custom features
- **WHEN** running `git log main..sid --oneline`
- **THEN** the output SHALL show one commit per custom feature with a descriptive message

#### Scenario: Review a single feature
- **WHEN** viewing the diff of a single commit on `main`
- **THEN** the diff SHALL contain only changes related to that feature

### Requirement: patches/ directory removed from sid repo
The `patches/` directory in the sid repo SHALL be deleted after all patch files and source files are migrated to the fork. No `.patch` files or standalone `.rs` files SHALL remain in the sid repo.

#### Scenario: Clean sid repo
- **WHEN** listing files in the sid repo after migration
- **THEN** no `patches/` directory SHALL exist
