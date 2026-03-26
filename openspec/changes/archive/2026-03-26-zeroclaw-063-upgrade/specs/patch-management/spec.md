## MODIFIED Requirements

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
