## Why

The ZeroClaw web dashboard already has a responsive mobile layout, but it runs in a browser tab — with browser chrome eating screen space, no home screen icon, and no app-like launch experience. Making it a PWA lets Keith install it as a standalone app on his phone, getting a native-feeling Sid interface without message-splitting issues that plague Telegram.

## What Changes

- Add `manifest.json` to `web/public/` with app name, icons, theme color, and `display: standalone`
- Add a minimal service worker to `web/public/` for offline app shell caching (HTML, CSS, JS assets only — not messages)
- Add PWA meta tags to `web/index.html` (`<link rel="manifest">`, `theme-color`, `apple-mobile-web-app-capable`, app icons)
- Register the service worker in the React app entrypoint
- Ensure the service worker is served at the correct scope for installability

## Capabilities

### New Capabilities
- `web-pwa`: Progressive Web App manifest, service worker, and meta tags for installable standalone web app

### Modified Capabilities
- `web-ui-enhancements`: Add PWA meta tags and manifest link to the web channel's HTML head

## Impact

- **Frontend**: New files in `web/public/` (manifest.json, service-worker.js, app icons), minor edits to `web/index.html` and `web/src/main.tsx`
- **Backend**: No changes — rust-embed automatically picks up new files in `web/dist/` at compile time
- **Service worker scope**: Must be served from root or `/_app/` scope; may need a gateway route adjustment if `/_app/service-worker.js` doesn't satisfy scope requirements
- **Icons**: Need to generate PWA icon set (192x192, 512x512 minimum) from existing `logo.png`
