/* ============================================
   MediMinder – Service Worker
   Cache-first strategy for offline support
   ============================================ */

const CACHE_NAME = 'mediminder-v2.1.10';
const API_PATH_PREFIX = '/api/';
const ASSETS = [
    './',
    './index.html',
    './style.css',
    './app.js',
    './api-config.js',
    './api-service.js',
    './backend-db.js',
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
                // Force network fetch to avoid getting stale assets from browser cache
                const stack = ASSETS.map(url => {
                    return fetch(url, { cache: 'reload' }).then(response => {
                        if (!response.ok) throw Error('File not found: ' + url);
                        return cache.put(url, response);
                    });
                });
                return Promise.all(stack);
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

    // Skip API requests - always go to network
    if (event.request.url.includes(API_PATH_PREFIX)) {
        event.respondWith(
            fetch(event.request)
                .catch(() => {
                    // Return offline response for API calls
                    return new Response(
                        JSON.stringify({ error: 'Offline - please check your connection' }),
                        {
                            status: 503,
                            statusText: 'Service Unavailable',
                            headers: { 'Content-Type': 'application/json' }
                        }
                    );
                })
        );
        return;
    }

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
