const CACHE_NAME = 'sid-shell-v1';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;

  // Only handle GET requests
  if (request.method !== 'GET') return;

  // Navigation requests (HTML pages): network-first, cache fallback
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          return response;
        })
        .catch(() => caches.match(request))
    );
    return;
  }

  // Static assets under /_app/: cache-first for hashed files, network-first for others
  if (request.url.includes('/_app/')) {
    // Vite hashed assets (contain a hash like main-abc123.js) are immutable
    const isHashed = /[-\.][a-f0-9]{8,}\.\w+$/.test(request.url);

    if (isHashed) {
      // Cache-first for immutable hashed assets
      event.respondWith(
        caches.match(request).then((cached) => {
          if (cached) return cached;
          return fetch(request).then((response) => {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
            return response;
          });
        })
      );
    } else {
      // Network-first for non-hashed assets (manifest, icons, etc.)
      event.respondWith(
        fetch(request)
          .then((response) => {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
            return response;
          })
          .catch(() => caches.match(request))
      );
    }
  }
});
