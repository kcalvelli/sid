## ADDED Requirements

### Requirement: ZeroClaw source updated to v0.6.5
The flake input SHALL reference `github:zeroclaw-labs/zeroclaw/v0.6.5` and the version strings in both `zeroclaw` and `zeroclaw-desktop` derivations SHALL be `"0.6.5"`.

#### Scenario: Flake input points to v0.6.5
- **WHEN** inspecting the `zeroclaw` input in flake.nix
- **THEN** the URL SHALL be `github:zeroclaw-labs/zeroclaw/v0.6.5`

#### Scenario: Derivation versions updated
- **WHEN** inspecting the `version` attribute of zeroclaw and zeroclaw-desktop derivations
- **THEN** both SHALL be `"0.6.5"`

### Requirement: cargoHash updated for v0.6.5
The `cargoHash` in both zeroclaw and zeroclaw-desktop derivations SHALL match the Cargo.lock of v0.6.5 with the surviving patch set applied.

#### Scenario: Build succeeds with new cargoHash
- **WHEN** `nix build .#zeroclaw` is run
- **THEN** the cargo vendor phase SHALL succeed without hash mismatch errors

### Requirement: npmDepsHash updated for v0.6.5 web frontend
The `npmDepsHash` in the `zeroclaw-web` derivation SHALL match the package-lock.json of v0.6.5.

#### Scenario: Web frontend builds with new hash
- **WHEN** `nix build .#zeroclaw` is run (which depends on zeroclaw-web)
- **THEN** the npm install phase SHALL succeed without hash mismatch errors

### Requirement: zeroclaw-web version updated
The `zeroclaw-web` derivation version SHALL be `"0.6.5"`.

#### Scenario: Web derivation version matches
- **WHEN** inspecting the `version` attribute of zeroclaw-web
- **THEN** it SHALL be `"0.6.5"`

### Requirement: zeroclaw MCP server removed from flake
The `zeroclaw-mcp` derivation SHALL be removed from flake.nix. The `mcp-servers/zeroclaw/` directory SHALL be deleted.

#### Scenario: No zeroclaw-mcp in flake outputs
- **WHEN** inspecting `nix flake show`
- **THEN** no `zeroclaw-mcp` package SHALL appear in the outputs

#### Scenario: MCP server directory deleted
- **WHEN** listing the repository contents
- **THEN** `mcp-servers/zeroclaw/` SHALL not exist

### Requirement: Dead MCP skill docs removed
The files `skills/mcp/SKILL.md` and `workspace/skills/mcp/SKILL.md` SHALL be deleted.

#### Scenario: No MCP skill files
- **WHEN** searching for `skills/mcp/SKILL.md` in the repository
- **THEN** no matches SHALL be found

### Requirement: TOOLS.md cleaned of dead MCP references
All `mcp-gw call zeroclaw` examples in `workspace/TOOLS.md` SHALL be removed. A warning SHALL be added that shell commands MUST NOT use redirects (`>`, `<`, `2>&1`) because the security policy blocks them unconditionally and the shell tool captures stderr natively.

#### Scenario: No zeroclaw MCP examples in TOOLS.md
- **WHEN** searching TOOLS.md for `mcp-gw call zeroclaw`
- **THEN** zero matches SHALL be found

#### Scenario: Redirect warning present
- **WHEN** reading the shell tools section of TOOLS.md
- **THEN** a warning SHALL state that `>`, `<`, and `2>&1` are blocked by the security policy's hardcoded redirect filter
