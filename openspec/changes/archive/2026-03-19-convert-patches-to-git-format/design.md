## Context

The current `postPatch` in `flake.nix` applies 12+ modifications to ZeroClaw source using embedded Python scripts that call `str.replace()` with exact string matching. Two standalone Rust files (`patches/xmpp.rs`, `patches/openai_proxy.rs`) are copied into the source tree as new modules.

The Python approach was expedient for iterative development — each patch could be tested independently — but now that the patch set is stable, the fragility outweighs the convenience. Any upstream change to a matched string causes a build failure with an opaque Python assertion error.

We are pinned to upstream commit `d2b0593b` (Feb 24, 2026). Upstream is 69 commits ahead, mostly CI/docs churn. When we eventually update, every Python patch must be manually verified against the new source.

## Goals / Non-Goals

**Goals:**
- Replace Python `str.replace()` patches with `git format-patch` style `.patch` files
- Make patch failures produce readable context (unified diff hunks with line numbers, not Python tracebacks)
- Remove `python3` from the build closure
- Preserve identical build output (zero runtime behavioral change)
- Make future upstream rebases a `git rebase` / `git am` workflow

**Non-Goals:**
- Upstreaming any patches (upstream PR backlog is too deep)
- Changing patch behavior or adding new patches
- Updating the pinned upstream commit (separate change)
- Restructuring `xmpp.rs` or `openai_proxy.rs` — these are new files, not diffs

## Decisions

### 1. Use Nix `patches = [...]` (not `postPatch` with `git apply`)

The Nix `patches` attribute on `buildRustPackage` applies patches via `patch -p1` before any build phase. This is the idiomatic Nix approach — patches are applied declaratively, failures are clear, and the mechanism is well-understood.

**Alternative considered**: Keeping `postPatch` but calling `git apply` or `patch -p1` manually. This works but gains nothing over the built-in `patches` attribute and keeps unnecessary complexity in `postPatch`.

### 2. One patch file per logical feature

Group patches by feature, not by file touched:

| Patch file | What it covers |
|-----------|---------------|
| `0001-add-missing-crate-deps.patch` | `futures` + `async-stream` in Cargo.toml |
| `0002-message-timestamps.patch` | ISO-8601 timestamps in channels, daemon, gateway |
| `0003-xmpp-channel-wiring.patch` | Module declaration, config schema, tool registration for XMPP |
| `0004-webhook-agent-loop.patch` | Switch webhook from simple chat to tool loop |
| `0005-models-endpoint.patch` | `/v1/models` static handler |
| `0006-openai-proxy-wiring.patch` | Module declaration + router for `/v1/chat/completions` |
| `0007-email-self-loop-prevention.patch` | Skip emails from own address |
| `0008-email-reply-threading.patch` | Subject via `thread_ts`, `Re:` prefix |
| `0009-email-sent-folder.patch` | IMAP append to Sent after SMTP send |
| `0010-image-vision.patch` | `ImageSource`, vision capability, `[IMAGE:]` parsing |

**Alternative considered**: One mega-patch or one patch per file. Per-feature is the sweet spot — each patch can be independently reviewed, toggled, or dropped, and maps 1:1 to an existing openspec capability.

### 3. Generate patches from a temporary git worktree

To produce the `.patch` files:
1. Clone zeroclaw at the pinned commit into a temp worktree
2. Apply each Python patch script sequentially, committing after each logical feature
3. Run `git format-patch` to extract the commit series
4. Copy the `.patch` files into `patches/`

This is a one-time generation step. Future maintenance edits the `.patch` files directly or regenerates from a branch.

### 4. Retain `postPatch` only for file copies

After moving diffs to `patches`, the `postPatch` block shrinks to:
```nix
postPatch = ''
  cp ${./patches/xmpp.rs} src/channels/xmpp.rs
  cp ${./patches/openai_proxy.rs} src/gateway/openai_proxy.rs
'';
```

These two files are entirely new source (not modifications to existing files), so they can't be expressed as patches against upstream. Copying in `postPatch` is the correct approach.

## Risks / Trade-offs

**[Patch context drift]** → Unified diff patches include surrounding context lines. If upstream changes code near (but not in) a patched region, `patch -p1` may fail even though the logical change still applies. **Mitigation**: Use `-p1 --fuzz=2` (Nix default) which tolerates minor context shifts. For larger drift, regenerate patches against the new upstream commit.

**[Patch ordering matters]** → Numbered prefix (`0001-`, `0002-`, ...) enforces application order. Patches that touch the same file must be ordered correctly. **Mitigation**: The numbering scheme above was designed so patches to the same file are grouped (0007-0009 all touch `email_channel.rs`). Document the dependency in patch commit messages.

**[One-time generation effort]** → Reproducing the exact output of each Python script as a clean git commit requires careful verification. **Mitigation**: Diff the final patched source tree against a build using the old Python approach to confirm byte-identical output.
