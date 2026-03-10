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
The patch set SHALL cover all modifications currently performed by the Python scripts in `postPatch`. The required patches are:

1. Missing crate dependencies (`futures`, `async-stream` in `Cargo.toml`)
2. Message timestamps (channels, daemon, gateway)
3. XMPP channel wiring (module declaration, config schema, tool registration)
4. Webhook agent loop (simple chat → tool loop)
5. `/v1/models` endpoint
6. OpenAI proxy wiring (module declaration, router)
7. Email self-loop prevention
8. Email reply subject threading
9. Email Sent folder IMAP append
10. Image vision support (structs, capability, content block parsing)

#### Scenario: No patches lost in conversion
- **WHEN** the full set of `.patch` files is applied along with `postPatch` file copies
- **THEN** every modification from the original Python scripts is present in the resulting source tree

#### Scenario: No extra patches introduced
- **WHEN** the full set of `.patch` files is applied
- **THEN** no source modifications exist beyond what the original Python scripts produced
