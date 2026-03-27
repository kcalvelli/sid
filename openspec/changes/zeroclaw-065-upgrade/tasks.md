## 1. Cleanup — Remove dead code

- [x] 1.1 Delete `mcp-servers/zeroclaw/` directory
- [x] 1.2 Remove `zeroclaw-mcp` derivation from flake.nix (lines 187-205)
- [x] 1.3 Delete `skills/mcp/SKILL.md`
- [x] 1.4 Delete `workspace/skills/mcp/SKILL.md`
- [x] 1.5 Delete dropped patch files: 0001, 0002, 0010, 0011, 0013, 0015, 0016, 0017, 0019, 0020

## 2. Version bump — Update flake.nix inputs and metadata

- [x] 2.1 Update zeroclaw input URL from `v0.6.3` to `v0.6.5`
- [x] 2.2 Update version strings to `"0.6.5"` in zeroclaw, zeroclaw-desktop, and zeroclaw-web derivations
- [x] 2.3 Set `cargoHash` to `""` (placeholder for rebuild)
- [x] 2.4 Set `npmDepsHash` to `""` (placeholder for rebuild)

## 3. Patch rebase — Rebase surviving patches onto v0.6.5

- [x] 3.1 Renumber remaining patches to 0001-0012 per design mapping
- [x] 3.2 Update `patches` list in flake.nix zeroclaw derivation (0001-0010)
- [x] 3.3 Update `patches` list in flake.nix zeroclaw-desktop derivation (0011-0012)
- [x] 3.4 Test-apply each patch against v0.6.5 source: `git apply --check`
- [x] 3.5 Regenerate any patches that fail to apply (read upstream diff, rewrite hunk context)
- [x] 3.6 Verify xmpp.rs compiles against v0.6.5 internal APIs (check imports, trait signatures)
- [x] 3.7 Verify openai_proxy.rs compiles against v0.6.5 internal APIs

## 4. Build — Hash updates and compilation

- [x] 4.1 Run `nix build .#zeroclaw` to get correct `cargoHash` from error output
- [x] 4.2 Update `cargoHash` with correct value
- [x] 4.3 Run `nix build .#zeroclaw` to get correct `npmDepsHash` from error output
- [x] 4.4 Update `npmDepsHash` with correct value
- [x] 4.5 Run `nix build .#zeroclaw` — verify full build succeeds
- [x] 4.6 Run `nix build .#zeroclaw-desktop` — verify desktop build succeeds

## 5. Workspace docs — Clean TOOLS.md

- [ ] 5.1 Remove "Memory (via MCP)" section from TOOLS.md (lines 147-154)
- [ ] 5.2 Remove `mcp-gw call zeroclaw pushover_send` example from TOOLS.md (line 161)
- [ ] 5.3 Remove `mcp-gw call zeroclaw cron_*` examples from TOOLS.md (lines 130-134)
- [ ] 5.4 Remove `mcp-gw call zeroclaw xmpp_send` example from TOOLS.md (line 89)
- [ ] 5.5 Add shell redirect warning: `>`, `<`, `2>&1` blocked by security policy; shell tool captures stderr natively

## 6. Validation

- [ ] 6.1 Verify `nix flake show` has no `zeroclaw-mcp` output
- [ ] 6.2 Verify no `mcp-gw call zeroclaw` references remain in workspace
- [ ] 6.3 Verify patch count is exactly 12 (10 main + 2 desktop)
- [ ] 6.4 Verify patches are numbered 0001-0012 contiguously
