/* Offline support for Fence Line. Once the page has loaded online, it keeps working with no connection,
   including from a home-screen icon. The build stamps a new VERSION whenever the files change. */
const APP = 'fence-line';
const VERSION = '2c349ceb8b';
const CACHE = APP + '-' + VERSION;
const FONTS = APP + '-fonts';
const FILES = ["./","index.html","manifest.json","icons/icon-192.png","icons/icon-512.png","icons/maskable-512.png","icons/apple-touch-icon.png"];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((c) => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith(APP + '-') && k !== CACHE && k !== FONTS).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

/* "folder/" and "folder/index.html" are the same page */
function pageKey(url) {
  const u = new URL(url);
  return u.origin + (u.pathname.endsWith('/') ? u.pathname + 'index.html' : u.pathname);
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin === self.location.origin) {
    if (req.mode === 'navigate') {
      /* the newest page when online, the saved copy when not */
      event.respondWith(
        fetch(req)
          .then((res) => {
            if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(pageKey(req.url), copy)); }
            return res;
          })
          .catch(() => caches.match(pageKey(req.url)).then((hit) => hit || caches.match(new URL('index.html', self.registration.scope).href)))
      );
      return;
    }
    event.respondWith(caches.match(req, { ignoreSearch: true }).then((hit) => hit || fetch(req)));
  } else if (url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com') {
    /* keep the rounded font too, so the game looks the same offline */
    event.respondWith(caches.open(FONTS).then((c) => c.match(req).then((hit) => {
      const net = fetch(req).then((res) => { if (res.ok || res.type === 'opaque') c.put(req, res.clone()); return res; }).catch(() => hit || Response.error());
      return hit || net;
    })));
  }
});
