## MODIFIED Requirements

### Requirement: Patch creates runtime URL override in Tauri source
Patches 0011 and 0012 (new numbering) SHALL apply cleanly to v0.6.5 Tauri source. The `cargoHash` SHALL be updated to match v0.6.5's Cargo.lock with desktop patches applied.

#### Scenario: Desktop patches apply to v0.6.5
- **WHEN** `nix build .#zeroclaw-desktop` is run against v0.6.5
- **THEN** patches 0011 (runtime gateway URL) and 0012 (CSP + no decorations) SHALL apply without conflicts

#### Scenario: Desktop build succeeds
- **WHEN** `nix build .#zeroclaw-desktop` completes
- **THEN** a `zeroclaw-desktop` binary SHALL be produced in `$out/bin/`
