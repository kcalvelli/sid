// Register PWA service worker in production builds only.
export function registerServiceWorker(): void {
  if (!import.meta.env.PROD) return;
  if (!('serviceWorker' in navigator)) return;

  const base = (window as any).__ZEROCLAW_BASE__ ?? '';
  const swUrl = `${base}/_app/service-worker.js`;

  window.addEventListener('load', () => {
    navigator.serviceWorker.register(swUrl).catch((err) => {
      console.warn('SW registration failed:', err);
    });
  });
}
