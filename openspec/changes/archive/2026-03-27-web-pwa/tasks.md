## 1. Icons

- [x] 1.1 Generate 192x192 and 512x512 PNG icons from existing logo, save to `web/pwa/icons/icon-192x192.png` and `web/pwa/icons/icon-512x512.png`

## 2. Manifest

- [x] 2.1 Create `web/pwa/manifest.json` with name "Sid", short_name "Sid", start_url "/", display "standalone", theme/background colors matching the dark UI, and icon references

## 3. Service Worker

- [x] 3.1 Create `web/pwa/service-worker.js` with versioned cache name (`sid-shell-v1`), install event (precache index.html + `skipWaiting()`), activate event (delete old caches + `clients.claim()`), and fetch handler (cache-first for hashed assets, network-first for navigation)

## 4. HTML Meta Tags

- [x] 4.1 Add to `web/index.html` `<head>`: `<link rel="manifest">`, `<meta name="theme-color">`, `<meta name="apple-mobile-web-app-capable">`, `<meta name="apple-mobile-web-app-status-bar-style">`, `<link rel="apple-touch-icon">` (via sed in flake.nix postPatch)

## 5. Service Worker Registration

- [x] 5.1 Add service worker registration module (`web/pwa/sw-register.ts`), gated on production build (`import.meta.env.PROD`), using base path from `window.__ZEROCLAW_BASE__`; injected into main.tsx via flake.nix postPatch

## 6. Build & Patch

- [x] 6.1 Wire PWA overlay into `zeroclaw-web` Nix build via `postPatch` in flake.nix (no Rust patch needed — all changes are in the web build)
- [x] 6.2 Rebuild ZeroClaw and verify manifest.json, service-worker.js, meta tags, and SW registration are all embedded in the binary

## 7. Testing

- [x] 7.1 Verify installability: open dashboard on Chrome Android, confirm "Add to Home Screen" prompt appears
- [x] 7.2 Verify standalone mode: launch from home screen, confirm no browser chrome
- [ ] 7.3 Verify app shell caching: load app, briefly stop gateway, reload — confirm cached shell loads (not browser error)
- [ ] 7.4 Verify cache cleanup: deploy updated build, confirm old cache is deleted and new assets are served
- [ ] 7.5 Verify iOS: add to home screen on Safari, confirm apple-touch-icon and standalone launch
