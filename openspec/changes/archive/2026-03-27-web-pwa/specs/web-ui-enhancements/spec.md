## MODIFIED Requirements

### Requirement: Responsive mobile sidebar
The web channel SHALL include a responsive sidebar with a hamburger toggle for mobile viewports. The HTML head SHALL include PWA meta tags for installability and native app behavior.

#### Scenario: Sidebar collapses on mobile
- **WHEN** the web channel is viewed on a viewport narrower than 768px
- **THEN** the sidebar is hidden and a hamburger menu icon is displayed to toggle it

#### Scenario: PWA meta tags present in HTML head
- **WHEN** the web UI index.html is served
- **THEN** the HTML head SHALL include `<link rel="manifest" href="/_app/manifest.json">`, `<meta name="theme-color">`, `<meta name="apple-mobile-web-app-capable" content="yes">`, `<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">`, and `<link rel="apple-touch-icon">`
