## Context

Sid runs on ZeroClaw as a NixOS service. Tools are either shell commands (gated by an allowlist and risk classification) or native Rust tools (compiled into the binary via patches). Network shell commands like curl/wget were removed from the service for security. The XMPP channel already uses `reqwest` for OOB media downloads, establishing a pattern for in-process HTTP. Native tools implement the `Tool` trait (`name`, `description`, `parameters_schema`, `execute`) and are registered in `src/tools/mod.rs`.

## Goals / Non-Goals

**Goals:**
- Give Sid the ability to read any public web page
- Return content in a format useful for LLM context (text, not raw HTML)
- Follow the existing native tool pattern (no shell, no config changes)
- Keep the implementation small and self-contained

**Non-Goals:**
- POST, PUT, DELETE, or any write operations
- Authentication headers or cookie handling
- JavaScript rendering (static HTML only)
- Domain allowlisting (decided against — GET-only is sufficient)
- PDF or binary file fetching (XMPP OOB already handles media)
- Caching or rate limiting

## Decisions

### 1. Native Rust tool, not shell command

**Decision**: Implement as a native `Tool` trait impl, not by re-adding curl to the allowlist.

**Alternatives considered**:
- Add curl back to allowed_commands → fights security model, opens shell escape surface, curl flags are complex and error-prone
- Proxy through a sidecar service → unnecessary complexity for a GET-only use case

**Rationale**: The XMPP tools proved this pattern works. reqwest is already in the dependency tree. A native tool has a constrained API surface (only GET, only the parameters we define) vs. curl which can do anything.

### 2. `html2text` crate for HTML conversion

**Decision**: Use the `html2text` crate for HTML-to-text conversion.

**Alternatives considered**:
- Hand-rolled regex tag stripping → loses document structure (headings, lists, code blocks), fragile
- `scraper` crate → CSS selector based, requires us to write extraction logic
- `ammonia` → sanitizer, strips dangerous HTML but doesn't convert to text

**Rationale**: `html2text` does exactly one thing: renders HTML as readable text with markdown-style formatting. One function call (`from_read`). Preserves headings, lists, links, code blocks — important for Sid reading docs and articles.

### 3. Unconditional registration (no config gate)

**Decision**: Register the tool in `tools/mod.rs` unconditionally, not gated on any channel config.

**Rationale**: Unlike XMPP tools (which only make sense when XMPP is configured), web_fetch is useful from any channel — Telegram, email, CLI, heartbeat. No config field needed.

### 4. Content delimiter wrapping

**Decision**: Wrap fetched content in `--- BEGIN/END FETCHED CONTENT ---` delimiters.

**Rationale**: Cheap mitigation for prompt injection from hostile web content. Gives the model a clear signal that the enclosed text is untrusted external input. Not bulletproof, but zero-cost.

### 5. Default size cap of 100,000 characters

**Decision**: Default max_chars of 100,000 (~25K tokens), overridable per call.

**Rationale**: Balances usefulness (most articles are 5K-20K chars) against context bloat. The caller (Sid/LLM) can request less if it only needs a summary-length excerpt.

## Risks / Trade-offs

- **[Large pages]** → Mitigated by size cap and truncation indicator in response
- **[Prompt injection via fetched content]** → Mitigated by content delimiters; inherent risk in any system that reads untrusted input
- **[Slow fetches blocking agent loop]** → Mitigated by 30-second timeout; reqwest is async so it won't block other tasks
- **[New crate dependency]** → `html2text` is small and well-maintained; one new crate is acceptable for the functionality gained
- **[No JS rendering]** → SPAs and JS-heavy sites will return empty/skeleton content. Acceptable — Sid's primary use cases (articles, docs, reference pages) are mostly server-rendered

## Open Questions

_(none — design is straightforward and well-constrained by the explore session)_
