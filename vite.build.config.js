import { defineConfig } from 'vite';

export default defineConfig({
    // Root directory for source files
    root: '.',

    // Production build configuration
    build: {
        // Output directory
        outDir: 'dist',

        // Clean output directory before build
        emptyOutDir: true,

        // Generate source maps for debugging
        sourcemap: true,

        // Minification (default: esbuild — fast and effective)
        minify: 'esbuild',

        // Rollup options for fine-grained control
        rollupOptions: {
            input: {
                main: 'index.html',
            },
        },

        // Asset file name hashing for cache busting
        assetsDir: 'assets',
    },

    // Dev server configuration
    server: {
        port: 3000,
        proxy: {
            '/api': {
                target: 'http://localhost:8080',
                changeOrigin: true,
            },
        },
    },
});
