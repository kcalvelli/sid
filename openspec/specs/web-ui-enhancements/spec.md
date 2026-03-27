## ADDED Requirements

### Requirement: Collapsible thinking/reasoning UI
The web channel SHALL render thinking/reasoning blocks in a collapsible UI element, allowing users to expand or collapse intermediate reasoning.

#### Scenario: Thinking blocks collapsed by default
- **WHEN** a response includes thinking/reasoning content in the web channel
- **THEN** the thinking content is rendered in a collapsed state with a toggle to expand

### Requirement: Markdown rendering in web chat
The web channel SHALL render markdown formatting in chat messages, including headers, lists, code blocks, and inline formatting.

#### Scenario: Code block rendered with syntax highlighting
- **WHEN** a response contains a fenced code block in the web channel
- **THEN** the code block is rendered with appropriate formatting and syntax highlighting

### Requirement: Responsive mobile sidebar
The web channel SHALL include a responsive sidebar with a hamburger toggle for mobile viewports. The HTML head SHALL include PWA meta tags for installability and native app behavior.

#### Scenario: Sidebar collapses on mobile
- **WHEN** the web channel is viewed on a viewport narrowner than 768px
- **THEN** the sidebar is hidden and a hamburger menu icon is displayed to toggle it

#### Scenario: PWA meta tags present in HTML head
- **WHEN** the web UI index.html is served
- **THEN** the HTML head SHALL include `<link rel="manifest" href="/_app/manifest.json">`, `<meta name="theme-color">`, `<meta name="apple-mobile-web-app-capable" content="yes">`, `<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">`, and `<link rel="apple-touch-icon">`
