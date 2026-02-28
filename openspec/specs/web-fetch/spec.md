### Requirement: Fetch URL content via HTTP GET
The `web_fetch` tool SHALL accept a `url` parameter and perform an HTTP GET request, returning the response body as text content.

#### Scenario: Fetch a standard HTML page
- **WHEN** `web_fetch` is called with `url` set to a valid HTTPS URL serving HTML
- **THEN** the tool returns the page content converted to readable text

#### Scenario: Fetch a plain text resource
- **WHEN** `web_fetch` is called with `url` set to a URL serving `text/plain` or other text/* content
- **THEN** the tool returns the raw text content without conversion

#### Scenario: Reject non-text content
- **WHEN** `web_fetch` is called with a URL serving binary content (image/*, application/octet-stream, etc.)
- **THEN** the tool returns an error indicating the content type is not supported

#### Scenario: Invalid URL
- **WHEN** `web_fetch` is called with a URL that is not a valid HTTP or HTTPS URL
- **THEN** the tool returns an error indicating the URL is invalid

### Requirement: Convert HTML to readable text
The tool SHALL convert HTML responses to readable text. The upstream implementation uses `nanohtml2text` for conversion.

#### Scenario: HTML with structural elements
- **WHEN** an HTML page contains headings, bullet lists, and code blocks
- **THEN** the returned text preserves those elements in a readable format

#### Scenario: Script and style removal
- **WHEN** an HTML page contains `<script>` and `<style>` elements
- **THEN** those elements are stripped and do not appear in the returned text

### Requirement: Enforce response size limit
The tool SHALL enforce a configurable maximum response size (configured via `max_response_size` in `[web_fetch]` config). Responses exceeding the limit are truncated.

#### Scenario: Response within size limit
- **WHEN** the response text is within the configured limit
- **THEN** the full content is returned

#### Scenario: Response exceeds size limit
- **WHEN** the response text exceeds the configured limit
- **THEN** the content is truncated with a truncation notice appended

### Requirement: Request timeout and redirect handling
The tool SHALL enforce a configurable timeout (default 30s) and follow redirects up to a maximum depth of 10. Each redirect target is validated against the domain allowlist.

#### Scenario: Slow server
- **WHEN** the target server does not respond within the timeout
- **THEN** the tool returns a timeout error

#### Scenario: Redirect chain within limit
- **WHEN** the target URL redirects up to 10 times
- **THEN** the tool follows the redirects and returns content from the final URL

#### Scenario: Excessive redirects
- **WHEN** the redirect chain exceeds 10 hops
- **THEN** the tool returns an error indicating too many redirects

### Requirement: GET-only with no authentication
The tool SHALL only perform HTTP GET requests. It MUST NOT support POST, PUT, DELETE, PATCH, or any method that modifies remote state.

#### Scenario: No write methods
- **WHEN** the tool is invoked
- **THEN** only an HTTP GET request is issued, regardless of input parameters

### Requirement: SSRF protection
The tool SHALL block requests to localhost, private IP ranges, link-local addresses, and resolved private IPs. Domain allowlist and blocklist are enforced, including on redirect targets.

#### Scenario: Block localhost
- **WHEN** `web_fetch` is called with a URL pointing to localhost or 127.0.0.1
- **THEN** the tool returns an error indicating the host is blocked

#### Scenario: Block private IPs
- **WHEN** `web_fetch` is called with a URL resolving to a private IP (10.x, 172.16.x, 192.168.x)
- **THEN** the tool returns an error indicating the host is blocked

### Requirement: Domain-based access control
The tool SHALL enforce allowed_domains and blocked_domains configuration. If allowed_domains is empty, all requests are denied. Wildcard `*` allows all public hosts. Blocked domains take priority over allowed domains.

#### Scenario: Wildcard allows all public hosts
- **WHEN** `allowed_domains = ["*"]` and the target is a public host
- **THEN** the request is permitted

#### Scenario: Blocked domain rejected
- **WHEN** a domain appears in blocked_domains
- **THEN** the request is rejected even if it matches allowed_domains

### Requirement: Tool availability
The tool SHALL be available when `[web_fetch] enabled = true` in config.toml, accessible from all channels.

#### Scenario: Available from XMPP
- **WHEN** Sid receives a message via XMPP asking to fetch a URL
- **THEN** the `web_fetch` tool is available and can be invoked

#### Scenario: Available during heartbeat
- **WHEN** a heartbeat task requires checking a web resource
- **THEN** the `web_fetch` tool is available and can be invoked
