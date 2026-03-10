## Why

The `postPatch` block in `flake.nix` is ~560 lines of embedded Python string-replacement scripts that modify ZeroClaw source at build time. These patches use exact string matching (`assert old in src; src.replace(old, new, 1)`) which is fragile — any upstream change to the matched strings silently breaks the build or, worse, the assertion fails with an opaque Python traceback. Converting to standard `git format-patch` files makes patches diffable, reviewable, and rebasing onto new upstream commits becomes a normal `git rebase` workflow instead of a forensic debugging session.

## What Changes

- Replace all Python `str.replace()` patch scripts in `postPatch` with `.patch` files generated via `git format-patch`
- Reorganize `patches/` directory: currently holds `xmpp.rs` and `openai_proxy.rs` (new source files); will also hold `.patch` files for modifications to existing upstream sources
- Simplify `postPatch` to apply patches via `git apply` or Nix `patches = [...]` and copy new source files
- Retain the two standalone Rust source files (`xmpp.rs`, `openai_proxy.rs`) as-is — these are additions, not diffs
- Keep the `Cargo.toml` fix for missing `futures`/`async-stream` crates as a patch file

## Capabilities

### New Capabilities

- `patch-management`: How patches are organized, applied, and maintained against upstream ZeroClaw — covering file layout, naming conventions, and the Nix derivation's patch application mechanism

### Modified Capabilities

_(none — all existing capabilities retain the same runtime behavior; this is purely a build-process change)_

## Impact

- **flake.nix**: `postPatch` block reduced from ~560 lines to ~10 lines (copy new files + minimal setup)
- **patches/**: New `.patch` files for each logical change (timestamps, email fixes, vision, webhook loop, models endpoint, chat completions wiring)
- **Build dependencies**: `python3` no longer needed in `postPatch` (can be removed from build closure)
- **No runtime changes**: All patches produce identical source output — this is a build ergonomics change only
