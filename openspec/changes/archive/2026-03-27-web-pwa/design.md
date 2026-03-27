## Context

ZeroClaw's web UI is a React 19 + Vite app compiled to `web/dist/`, embedded into the Rust binary via rust-embed, and served at `/_app/*` with an SPA fallback. The gateway already handles path-prefix rewriting (injecting `window.__ZEROCLAW_BASE__` into index.html). Static assets get immutable cache headers; index.html gets `no-cache`. The existing `web/public/` directory holds `logo.png` which Vite copies to `dist/` at build time.

For PWA installability, browsers require: (1) a valid web app manifest linked from the HTML, (2) a registered service worker, and (3) the page to be served over HTTPS. The gateway already serves over HTTPS.

## Goals / Non-Goals

**Goals:**
- Make the dashboard installable as a home screen app on iOS and Android
- Standalone display mode (no browser chrome)
- Minimal service worker that caches the app shell for fast launch
- Proper PWA icons and theme color

**Non-Goals:**
- Offline message access or sync (messages require the gateway)
- Push notifications (would need a whole push infrastructure)
- Background sync
- Complex caching strategies for API responses
- Desktop PWA install (nice side effect, but mobile is the target)

## Decisions

### 1. Service worker scope: serve from `/_app/` not root

The service worker controls a scope based on its URL path. Serving it at `/_app/service-worker.js` gives it scope over `/_app/*` which is where all static assets live. The SPA fallback already handles root navigation, so the SW doesn't need root scope. This avoids needing a new gateway route or `Service-Worker-Allowed` header.

**Alternative considered:** Serving at `/service-worker.js` with root scope. Would require a dedicated gateway route outside the `/_app/` static handler. Unnecessary complexity for shell caching.

### 2. Cache-first strategy for hashed assets, network-first for index.html

Vite produces content-hashed filenames for JS/CSS (e.g., `main-abc123.js`). These are immutable — cache-first is correct and fast. `index.html` must be network-first to pick up new deployments, falling back to cache only when offline.

### 3. Plain JS service worker in `web/public/`, not a Vite plugin

Vite PWA plugins (vite-plugin-pwa / workbox) add significant complexity and dependencies for what amounts to ~30 lines of cache logic. A hand-written `service-worker.js` in `web/public/` is simpler, predictable, and gets copied to `dist/` by Vite automatically.

**Alternative considered:** `vite-plugin-pwa` with workbox. Rejected — adds build dependencies and config surface for a minimal caching requirement.

### 4. Generate icons at 192x192 and 512x512 from existing logo

PWA manifest requires at least 192x192 and 512x512 icons. These can be generated from the existing `web/public/logo.png` (or `zeroclaw-trans.png`). Stored as PNGs in `web/public/icons/`.

### 5. Manifest linked from index.html with `/_app/` prefix

The manifest `<link>` in `index.html` uses `href="/_app/manifest.json"` to match the static file serving path. The gateway's path-prefix rewriting will handle deployments with non-root base paths.

## Risks / Trade-offs

- **[iOS limitations]** iOS PWAs have limited service worker support and lose state on eviction. → Acceptable — we're only caching the shell, not state. The app just needs to load fast and look native.
- **[Service worker update]** Stale service workers can serve old app shells after a deploy. → Network-first for index.html mitigates this. The SW will also `skipWaiting()` + `clients.claim()` on activation to take over immediately.
- **[Scope mismatch]** If the gateway's path-prefix rewriting changes the base path, the SW scope may not cover it. → The `__ZEROCLAW_BASE__` injection already handles this; SW registration should use the same base.
