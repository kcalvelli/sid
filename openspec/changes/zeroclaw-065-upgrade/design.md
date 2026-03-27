## Context

Sid runs ZeroClaw v0.6.3 with 22 patches (20 main + 2 desktop). Analysis against v0.6.5 source at ~/Projects/zeroclaw shows 10 patches are now upstreamed or obsolete. The zeroclaw MCP server is dead (not in `mcp-gw list`, all tools native). TOOLS.md in Sid's workspace contains stale `mcp-gw call zeroclaw` examples that confuse the LLM into attempting MCP calls for native tools, and the LLM's habit of appending `2>&1` to shell commands triggers the security policy's unconditional redirect filter, breaking `mcp-gw` access to calendar, Home Assistant, and other external integrations.

Current patch set: 22 files in `patches/`, two standalone .rs source files, zeroclaw-mcp Python package in `mcp-servers/zeroclaw/`.

## Goals / Non-Goals

**Goals:**
- Upgrade ZeroClaw to v0.6.5 with a clean, minimal patch set
- Drop all patches absorbed by upstream or no longer needed
- Remove dead zeroclaw MCP server and all references
- Clean workspace docs to prevent LLM confusion around MCP vs native tools
- Maintain PWA overlay for mobile
- Renumber patches to contiguous 0001-0012 sequence

**Non-Goals:**
- Enabling new v0.6.5 features (context overflow recovery, session state machine, message debouncing, etc.) — those activate automatically or are separate config work
- Modifying security policy or ZeroClaw's redirect filter — the fix is doc-side
- Upstreaming any Sid patches — that's a future goal
- Changing the NixOS module config generation

## Decisions

### 1. Rebase strategy: patch-by-patch onto v0.6.5 source

Rebase each surviving patch individually against the v0.6.5 tag. Regenerate patches that fail to apply by reading the upstream diff and rewriting the hunk context.

**Why not fork-and-merge:** Sid's patches are intentionally maintained as `.patch` files applied at Nix build time, not as a persistent fork. This keeps the upstream relationship clean and makes version bumps auditable.

**Why not squash into fewer patches:** Each patch is one logical feature. This makes it easy to evaluate on future upgrades which patches can be dropped.

### 2. Renumber remaining patches contiguously

After dropping 10 patches, renumber the 12 survivors as 0001-0012. The new numbering groups by category:

| New # | Old # | Description |
|-------|-------|-------------|
| 0001 | 0003 | XMPP channel wiring |
| 0002 | 0004 | Webhook full agent loop |
| 0003 | 0005 | /v1/models endpoint |
| 0004 | 0006 | OpenAI chat completions wiring |
| 0005 | 0007 | Skip self-addressed emails |
| 0006 | 0008 | Email subject threading |
| 0007 | 0009 | Save sent emails to IMAP Sent |
| 0008 | 0012 | Claude Code --dangerously-skip-permissions |
| 0009 | 0014 | SOP provider/model override + Pushover alerts |
| 0010 | 0018 | Skip noreply/bounce emails |
| 0011 | 0021 | Tauri runtime gateway URL |
| 0012 | 0022 | Tauri CSP + no decorations |

### 3. Remove zeroclaw MCP server completely

Delete `mcp-servers/zeroclaw/` directory and the `zeroclaw-mcp` derivation from flake.nix. The server is not in `mcp-gw list`, was never configured in Sid's active MCP gateway, and all its tools (memory, cron, pushover, xmpp) are native ZeroClaw tools.

### 4. Fix TOOLS.md to prevent LLM confusion

Remove all `mcp-gw call zeroclaw ...` examples. Add explicit warning that shell redirects (`>`, `<`, `2>&1`) are blocked by security policy. The shell tool captures stderr natively — redirects are never needed.

### 5. Hash update strategy

Both `cargoHash` and `npmDepsHash` will break after changing the source rev and patch set. Strategy:
1. Update flake input to v0.6.5
2. Set hashes to empty string `""`
3. Attempt `nix build`, capture expected hash from error
4. Update with correct hash
5. Repeat for both zeroclaw and zeroclaw-web derivations

## Risks / Trade-offs

- **[Patch conflicts]** → Gateway patches (0002 new=webhook, 0003/0004 new=OpenAI) touch gateway/mod.rs which has upstream changes for auth rate limiting and actor queues. Mitigation: read upstream diff for those files before rebasing.
- **[SOP provider override patch]** → Largest behavioral patch (7K). Touches agent execution paths that v0.6.5 modified for context overflow recovery. Mitigation: regenerate from scratch if hunk context drifts.
- **[npmDepsHash breakage]** → Web frontend changes in v0.6.5 (chat history persistence) may add/change npm dependencies. Mitigation: standard hash update procedure.
- **[xmpp.rs compatibility]** → The standalone XMPP source file may reference internal APIs that changed in v0.6.5. Mitigation: compile errors will surface; fix imports/signatures as needed.
- **[Desktop cargoHash shared]** → Main and desktop derivations use the same `cargoHash` currently. If v0.6.5 changes workspace deps, both need updating together.

## Open Questions

None — all questions resolved during analysis phase.
