## MODIFIED Requirements

### Requirement: OpenAI proxy source lives in fork source tree
The OpenAI-compatible proxy implementation (`openai_proxy.rs`) SHALL exist as a committed file at `src/gateway/openai_proxy.rs` in the fork's `main` branch. The `/v1/models` endpoint and `/v1/chat/completions` wiring SHALL also be commits on the `main` branch. These files SHALL NOT be copied from an external location during build.

#### Scenario: Source file location
- **WHEN** checking out the `main` branch of the fork
- **THEN** `src/gateway/openai_proxy.rs` SHALL exist as a tracked file in the repository

#### Scenario: Endpoint wiring committed
- **WHEN** viewing the diff of the OpenAI proxy commits on `sid`
- **THEN** the gateway route registration for `/v1/models` and `/v1/chat/completions` SHALL be visible in the commit diff

### Requirement: Upstream evaluation on sync
The custom OpenAI proxy patches SHALL be evaluated against upstream's capabilities on each upstream sync. The custom implementation is retained only if upstream lacks: identity injection from IDENTITY.md, `/v1/models` endpoint, single-burst SSE streaming compatible with Home Assistant, or 1MB body limit. If upstream provides equivalent functionality, the proxy commits SHALL be dropped from the `main` branch.

#### Scenario: Upstream adds OpenAI-compatible endpoint
- **WHEN** a new upstream release includes a `/v1/chat/completions` endpoint with identity injection and HA-compatible streaming
- **THEN** the custom proxy commits SHALL be dropped from `sid` during rebase, with a commit message noting the upstream absorption

#### Scenario: Upstream endpoint lacks required features
- **WHEN** upstream's endpoint does not support identity injection or single-burst SSE
- **THEN** the custom proxy commits SHALL be retained on `sid` and rebased onto the new `main`
