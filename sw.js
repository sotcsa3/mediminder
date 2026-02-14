/* ============================================
   MediMinder – Service Worker
   Cache-first strategy for offline support
   ============================================ */

const CACHE_NAME = 'mediminder-v1.3.21';
const ASSETS = [
    './',
    './index.html',
    './style.css',
    './app.js',
    './firebase-config.js',
    './firebase-db.js',
    './manifest.json',
    './icons/icon-192.png',
    './icons/icon-512.png'
];

// Install: pre-cache all static assets
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('[SW] Pre-caching assets');
                return cache.addAll(ASSETS);
            })
            .then(() => self.skipWaiting())
    );
});

// Activate: clean up old caches
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys()
            .then((keys) => {
                return Promise.all(
                    keys
                        .filter((key) => key !== CACHE_NAME)
                        .map((key) => {
                            console.log('[SW] Removing old cache:', key);
                            return caches.delete(key);
                        })
                );
            })
            .then(() => self.clients.claim())
    );
});

// Fetch: cache-first, fallback to network, then update cache
self.addEventListener('fetch', (event) => {
    // Only handle GET requests
    if (event.request.method !== 'GET') return;

    // Skip cross-origin requests (e.g. Google Fonts)
    if (!event.request.url.startsWith(self.location.origin)) {
        // For fonts, try network first, cache as fallback
        event.respondWith(
            caches.match(event.request)
                .then((cached) => {
                    const fetchPromise = fetch(event.request)
                        .then((response) => {
                            if (response && response.ok) {
                                const clone = response.clone();
                                caches.open(CACHE_NAME).then((cache) => {
                                    cache.put(event.request, clone);
                                });
                            }
                            return response;
                        })
                        .catch(() => cached);

                    return cached || fetchPromise;
                })
        );
        return;
    }

    // For same-origin: cache first, then network update (stale-while-revalidate)
    event.respondWith(
        caches.match(event.request)
            .then((cached) => {
                const fetchPromise = fetch(event.request)
                    .then((response) => {
                        if (response && response.ok) {
                            const clone = response.clone();
                            caches.open(CACHE_NAME).then((cache) => {
                                cache.put(event.request, clone);
                            });
                        }
                        return response;
                    })
                    .catch(() => {
                        // Network failed, return cached if available
                        return cached;
                    });

                // Return cached immediately, update in background
                return cached || fetchPromise;
            })
    );
});
