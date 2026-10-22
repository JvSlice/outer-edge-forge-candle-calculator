const BUILD_VERSION = '__OEF_BUILD_VERSION__';
const PRECACHE_FILES = __OEF_PRECACHE_FILES__;
const APP_SCOPE = new URL(self.registration.scope);
const CACHE_PREFIX = `oef-candles:${APP_SCOPE.pathname}:`;
const CACHE_NAME = `${CACHE_PREFIX}${BUILD_VERSION}`;
const PRECACHE_REQUESTS = PRECACHE_FILES.map((path) => new Request(
  new URL(path, APP_SCOPE).href,
  { cache: 'reload' },
));

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(PRECACHE_REQUESTS);
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME)
      .map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' ||
      url.origin !== APP_SCOPE.origin ||
      !url.pathname.startsWith(APP_SCOPE.pathname)) {
    return;
  }

  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    if (request.mode === 'navigate') {
      return await cache.match(APP_SCOPE.href) || await cache.match(new URL('index.html', APP_SCOPE).href) || fetch(request);
    }
    return await cache.match(request, { ignoreSearch: true }) || fetch(request);
  })());
});
