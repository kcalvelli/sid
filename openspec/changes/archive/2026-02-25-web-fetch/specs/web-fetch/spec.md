## ADDED Requirements

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
The tool SHALL convert HTML responses to readable text that preserves document structure. Headings, lists, links, and code blocks MUST be represented in the text output.

#### Scenario: HTML with structural elements
- **WHEN** an HTML page contains headings, bullet lists, and code blocks
- **THEN** the returned text preserves those elements in a readable format (markdown-style)

#### Scenario: Script and style removal
- **WHEN** an HTML page contains `<script>` and `<style>` elements
- **THEN** those elements are stripped and do not appear in the returned text

### Requirement: Enforce response size limit
The tool SHALL accept an optional `max_chars` parameter (default: 100,000) and truncate the response content to that limit.

#### Scenario: Response within size limit
- **WHEN** the converted text content is within the `max_chars` limit
- **THEN** the full content is returned with `truncated` set to false

#### Scenario: Response exceeds size limit
- **WHEN** the converted text content exceeds the `max_chars` limit
- **THEN** the content is truncated to `max_chars` characters and `truncated` is set to true

#### Scenario: Caller overrides default limit
- **WHEN** `web_fetch` is called with `max_chars` set to 20000
- **THEN** the response is truncated at 20,000 characters if it exceeds that length

### Requirement: Request timeout and redirect handling
The tool SHALL enforce a 30-second timeout on HTTP requests and follow redirects up to a maximum depth of 5.

#### Scenario: Slow server
- **WHEN** the target server does not respond within 30 seconds
- **THEN** the tool returns a timeout error

#### Scenario: Redirect chain
- **WHEN** the target URL redirects (301/302) up to 5 times
- **THEN** the tool follows the redirects and returns content from the final URL

#### Scenario: Excessive redirects
- **WHEN** the redirect chain exceeds 5 hops
- **THEN** the tool returns an error indicating too many redirects

### Requirement: Wrap content with untrusted-content delimiters
The tool SHALL wrap all fetched content in clearly marked delimiters to signal that the content is from an external, untrusted source.

#### Scenario: Fetched content wrapping
- **WHEN** any URL is successfully fetched
- **THEN** the returned content is wrapped in `--- BEGIN FETCHED CONTENT FROM <url> ---` and `--- END FETCHED CONTENT ---` delimiters

### Requirement: GET-only with no authentication
The tool SHALL only perform HTTP GET requests. It MUST NOT support POST, PUT, DELETE, PATCH, or any method that modifies remote state. It MUST NOT send authentication headers or cookies.

#### Scenario: No write methods
- **WHEN** the tool is invoked
- **THEN** only an HTTP GET request is issued, regardless of input parameters

### Requirement: Tool registration
The tool SHALL be registered unconditionally in the ZeroClaw tool registry, available from all channels (CLI, Telegram, Email, XMPP, heartbeat).

#### Scenario: Available from XMPP
- **WHEN** Sid receives a message via XMPP asking to fetch a URL
- **THEN** the `web_fetch` tool is available and can be invoked

#### Scenario: Available during heartbeat
- **WHEN** a heartbeat task requires checking a web resource
- **THEN** the `web_fetch` tool is available and can be invoked
