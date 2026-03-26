## ADDED Requirements

### Requirement: Patches applied via Nix patches attribute
The Nix derivation SHALL apply all modifications to upstream ZeroClaw source files using the `patches` attribute on `buildRustPackage`, not embedded scripts in `postPatch`.

#### Scenario: Clean build with patches
- **WHEN** the derivation is built with `nix build`
- **THEN** all `.patch` files listed in `patches` are applied via `patch -p1` before the build phase, and the build succeeds

#### Scenario: Patch failure produces readable output
- **WHEN** a `.patch` file fails to apply due to upstream source changes
- **THEN** the build error includes the unified diff hunk that failed, the expected context lines, and the file path — not a Python traceback

### Requirement: One patch file per logical feature
Each `.patch` file SHALL correspond to exactly one logical feature or fix. Patches SHALL be numbered with a zero-padded prefix (`0001-`, `0002-`, ...) that defines application order.

#### Scenario: Patch file naming
- **WHEN** listing files in the `patches/` directory
- **THEN** each `.patch` file follows the pattern `NNNN-<kebab-case-description>.patch` where NNNN is a zero-padded sequence number

#### Scenario: Independent review
- **WHEN** reviewing a single `.patch` file
- **THEN** the patch contains only changes related to its named feature, with a descriptive commit message as the patch header

### Requirement: New source files copied in postPatch
Standalone Rust source files that represent entirely new modules (not modifications to upstream files) SHALL be copied into the source tree via `postPatch`, not expressed as patches.

#### Scenario: New module files are copied
- **WHEN** the derivation builds
- **THEN** `patches/xmpp.rs` is copied to `src/channels/xmpp.rs` and `patches/openai_proxy.rs` is copied to `src/gateway/openai_proxy.rs` during `postPatch`

#### Scenario: postPatch contains only file copies
- **WHEN** inspecting the `postPatch` attribute
- **THEN** it contains only `cp` commands for new source files, with no Python scripts, `sed`, or string-replacement logic

### Requirement: Python3 not required for patching
The derivation SHALL NOT depend on `python3` in its build closure for the purpose of applying patches.

#### Scenario: Build closure excludes python3
- **WHEN** the `postPatch` block is evaluated
- **THEN** no reference to `${pkgs.python3}` or any Python interpreter exists in the derivation's patch-related phases

### Requirement: Identical build output
The patched source tree produced by the new `.patch` files and `postPatch` file copies SHALL be byte-identical to the source tree produced by the previous Python `str.replace()` approach.

#### Scenario: Verification against previous approach
- **WHEN** comparing the source tree after patch application (new approach) against the source tree after `postPatch` (old approach) for the same upstream commit
- **THEN** `diff -r` on the two source trees produces no differences

### Requirement: Patch inventory matches existing features
The patch set SHALL cover all modifications currently performed that are not provided by upstream v0.6.3. Patches absorbed by upstream SHALL be removed. The remaining patches are:

1. Missing crate dependencies (`futures`, `async-stream` in `Cargo.toml`) — verify if still needed
2. Message timestamps (channels, daemon, gateway)
3. XMPP channel wiring (module declaration, config schema, tool registration)
4. Webhook agent loop (simple chat → tool loop)
5. `/v1/models` endpoint — **evaluate against upstream SSE proxy support**
6. OpenAI proxy wiring — **evaluate against upstream SSE proxy support**
7. Email self-loop prevention
8. Email reply subject threading
9. Email Sent folder IMAP append
10. Telegram channel context prefix
11. Claude Code capability reporting fix
12. Claude Code permission check bypass
13. Swarm gateway endpoint
14. SOP provider override
15. Swarm agentic agent loop
16. Canvas WebSocket subprotocol response
17. CanvasStore shared singleton

#### Scenario: Patches that fail to apply are evaluated
- **WHEN** a patch fails to apply against v0.6.3 source
- **THEN** the upstream diff is inspected to determine if the change was absorbed, and the patch is either dropped (if absorbed) or regenerated (if conflicting but not absorbed)

#### Scenario: Dropped patches are documented
- **WHEN** a patch is dropped because v0.6.3 includes the functionality
- **THEN** the patch file is removed from `patches/` and the reason is documented in the commit message

#### Scenario: Remaining patches renumbered
- **WHEN** patches are dropped from the sequence
- **THEN** remaining patches are renumbered to maintain a contiguous zero-padded sequence
