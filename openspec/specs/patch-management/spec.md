## Requirements

### Requirement: Custom features are commits on the fork's main branch
Each custom feature or fix that diverges from upstream ZeroClaw SHALL be a single commit (or minimal commit chain) on `main` of the `kcalvelli/zeroclaw-nix` fork. Each commit message SHALL describe the feature, following conventional commit format (e.g., `feat: wire XMPP channel`, `fix: skip noreply emails`).

#### Scenario: List custom features
- **WHEN** running `git log upstream/master..main --oneline` in the fork
- **THEN** the output SHALL show one commit per custom feature with a descriptive message

#### Scenario: Review a single feature
- **WHEN** viewing the diff of a single commit on `main`
- **THEN** the diff SHALL contain only changes related to that feature

### Requirement: patches/ directory removed from sid repo
The `patches/` directory in the sid repo SHALL NOT exist. All patch files and source files have been migrated to the fork as commits on `main`. No `.patch` files or standalone `.rs` files SHALL remain in the sid repo.

#### Scenario: Clean sid repo
- **WHEN** listing files in the sid repo
- **THEN** no `patches/` directory SHALL exist
