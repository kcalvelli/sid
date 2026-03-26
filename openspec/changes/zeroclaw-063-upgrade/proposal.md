## Why

ZeroClaw v0.6.3 was released 2026-03-26 with cost-optimized provider routing, per-provider max_tokens, SSE streaming on the anthropic provider, and improved web UI — all directly relevant to Sid's API billing model and current feature set. Several upstream additions may also absorb or reduce custom patches we carry. Upgrading now captures these wins before the patch set grows further.

## What Changes

- **Bump ZeroClaw flake input** from `v0.6.2` to `v0.6.3`
- **Rebase 17 patches** onto v0.6.3, dropping any that are now upstream
- **Enable cost-optimized provider routing** — aligns with Sid's $5/day, $100/month cost limits and tiered model strategy
- **Enable per-provider max_tokens** — different limits for haiku workers vs opus primary
- **Enable anthropic SSE streaming** — improves perceived latency on the fallback provider path
- **Enable fallback notifications** — users see when provider fallback fires
- **Enable BM25 memory search** — better keyword retrieval alongside existing memory config
- **Enable web UI improvements** — collapsible thinking/reasoning, markdown rendering, mobile sidebar for canvas channel
- **Evaluate OpenAI proxy patch reduction** — upstream "parse proxy tool events from SSE stream" may replace patches 0005/0006 and `openai_proxy.rs`
- **Wire escalate-to-human tool** — upgrades Sid's `ask_user` with urgency routing, useful for auto-mode SOPs
- **Wire report template tool** — enhances morning-briefing SOP output

## Capabilities

### New Capabilities
- `cost-optimized-routing`: Cost-aware provider selection strategy with per-provider max_tokens configuration
- `anthropic-sse-streaming`: SSE streaming support on the anthropic fallback provider
- `fallback-notifications`: User-facing notifications when provider fallback occurs
- `bm25-memory-search`: BM25 keyword search mode for memory retrieval
- `web-ui-enhancements`: Collapsible thinking UI, markdown rendering, responsive mobile sidebar
- `escalate-to-human`: Urgency-routed escalation tool replacing basic ask_user
- `report-template-tool`: Standalone report template engine for SOP-driven reports

### Modified Capabilities
- `patch-management`: Rebase patch set onto v0.6.3; evaluate and drop patches absorbed upstream
- `openai-proxy`: Upstream SSE proxy tool events may replace custom patches 0005/0006 and openai_proxy.rs

## Impact

- **flake.nix / flake.lock**: Version bump, possible cargoHash change, patch list modification
- **modules/nixos/default.nix**: New config sections for routing strategy, streaming, BM25, web UI options
- **patches/**: Rebase all 17 patches; likely drop 0-3 patches if absorbed upstream
- **workspace/sops/**: Morning-briefing SOP can use report template tool
- **Runtime**: No breaking changes expected — all new features are additive config toggles
