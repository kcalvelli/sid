## ADDED Requirements

### Requirement: Web app manifest for installability

The web UI SHALL include a `manifest.json` served at `/_app/manifest.json` with the following properties:
- `name`: "Sid"
- `short_name`: "Sid"
- `start_url`: "/"
- `display`: "standalone"
- `background_color`: dark theme background color matching the existing UI
- `theme_color`: matching the existing UI accent color
- `icons`: array including at least 192x192 and 512x512 PNG icons

#### Scenario: Manifest served correctly
- **WHEN** a browser requests `/_app/manifest.json`
- **THEN** the gateway SHALL respond with a valid JSON manifest with `Content-Type: application/manifest+json`

#### Scenario: Manifest enables install prompt
- **WHEN** a user visits the dashboard on Chrome Android and the manifest is valid
- **THEN** Chrome SHALL show the "Add to Home Screen" install prompt (or the install option in the browser menu)

#### Scenario: Standalone display mode
- **WHEN** the app is launched from the home screen
- **THEN** it SHALL display without browser chrome (no address bar, no navigation buttons)

### Requirement: Service worker for app shell caching

The web UI SHALL include a service worker at `/_app/service-worker.js` that caches the app shell (HTML, CSS, JS, icons) for fast startup. The service worker SHALL use a cache-first strategy for content-hashed assets (JS, CSS) and a network-first strategy for `index.html`.

#### Scenario: Hashed asset served from cache
- **WHEN** the service worker is active and a request is made for a Vite-hashed asset (e.g., `main-abc123.js`)
- **THEN** the service worker SHALL serve the asset from cache if available, falling back to network

#### Scenario: Index.html fetched network-first
- **WHEN** the service worker is active and a navigation request is made
- **THEN** the service worker SHALL attempt a network fetch first, falling back to cached `index.html` only if the network is unavailable

#### Scenario: App loads when gateway is temporarily unreachable
- **WHEN** the gateway is briefly unreachable and the app shell is cached
- **THEN** the web UI SHALL load from the service worker cache and display a connection error in the UI (not a browser error page)

#### Scenario: New assets cached on fetch
- **WHEN** a new Vite-hashed asset is fetched from the network (cache miss)
- **THEN** the service worker SHALL add it to the cache for future requests

### Requirement: Service worker activates immediately on update

The service worker SHALL call `skipWaiting()` during the install event and `clients.claim()` during the activate event, ensuring new service worker versions take effect immediately without requiring the user to close all tabs.

#### Scenario: Updated service worker takes effect
- **WHEN** a new version of the service worker is detected by the browser
- **THEN** the new service worker SHALL activate immediately and control all open clients

### Requirement: Service worker registration in React app

The React app SHALL register the service worker on initial load. Registration SHALL only occur in production builds (not during Vite dev server). The registration path SHALL respect the configured base path (`window.__ZEROCLAW_BASE__`).

#### Scenario: Service worker registered in production
- **WHEN** the app loads in a production build
- **THEN** the service worker SHALL be registered at the appropriate scope

#### Scenario: Service worker not registered in development
- **WHEN** the app loads via the Vite dev server
- **THEN** no service worker registration SHALL occur

### Requirement: PWA icons

The web UI SHALL include PNG icons at 192x192 and 512x512 resolutions in `web/public/icons/`. These icons SHALL be referenced in the manifest and as `<link rel="apple-touch-icon">` in the HTML.

#### Scenario: Icons referenced in manifest
- **WHEN** the manifest is parsed by a browser
- **THEN** it SHALL contain icon entries for 192x192 (`purpose: "any maskable"`) and 512x512 (`purpose: "any maskable"`)

#### Scenario: Apple touch icon
- **WHEN** an iOS user adds the app to their home screen
- **THEN** the system SHALL use the `apple-touch-icon` linked in the HTML head

### Requirement: Stale cache cleanup on service worker activation

The service worker SHALL delete old cache entries during the activate event. Each service worker version SHALL use a versioned cache name (e.g., `sid-shell-v1`). On activation, caches not matching the current version SHALL be deleted.

#### Scenario: Old cache deleted on update
- **WHEN** a new service worker activates with cache name `sid-shell-v2`
- **THEN** the previous `sid-shell-v1` cache SHALL be deleted
