#!/usr/bin/env node
/**
 * MediMinder Production Build Script
 * 
 * Produces a production-ready dist/ folder with:
 * - Minified JS & CSS
 * - Hashed asset filenames for cache busting
 * - Copied static assets (icons, manifest, sw.js)
 * - Updated service worker cache list
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.resolve(__dirname, '..');
const DIST = path.join(ROOT, 'dist');

// ANSI colors
const green = (s) => `\x1b[32m${s}\x1b[0m`;
const yellow = (s) => `\x1b[33m${s}\x1b[0m`;
const cyan = (s) => `\x1b[36m${s}\x1b[0m`;

function log(msg) { console.log(`${green('[BUILD]')} ${msg}`); }
function warn(msg) { console.log(`${yellow('[WARN]')}  ${msg}`); }

// ── Step 1: Clean dist ──────────────────────────────────
log('Cleaning dist/ ...');
if (fs.existsSync(DIST)) {
    fs.rmSync(DIST, { recursive: true, force: true });
}
fs.mkdirSync(DIST, { recursive: true });

// ── Step 2: Minify JS files with esbuild ─────────────────
log('Minifying JavaScript...');
const jsFiles = ['api-config.js', 'api-service.js', 'backend-db.js', 'app.js'];
const jsManifest = {}; // original name -> hashed name

for (const file of jsFiles) {
    const src = path.join(ROOT, file);
    const content = fs.readFileSync(src, 'utf8');

    // Use esbuild for minification (bundled with Vite)
    try {
        execSync(`npx esbuild "${src}" --minify --outfile="${path.join(DIST, file)}"`, {
            cwd: ROOT,
            stdio: 'pipe',
        });
    } catch (e) {
        // Fallback: copy as-is
        warn(`esbuild failed for ${file}, copying unminified`);
        fs.copyFileSync(src, path.join(DIST, file));
    }

    // Generate hashed filename
    const minContent = fs.readFileSync(path.join(DIST, file), 'utf8');
    const hash = crypto.createHash('md5').update(minContent).digest('hex').slice(0, 8);
    const ext = path.extname(file);
    const base = path.basename(file, ext);
    const hashedName = `assets/${base}.${hash}${ext}`;

    fs.mkdirSync(path.join(DIST, 'assets'), { recursive: true });
    fs.renameSync(path.join(DIST, file), path.join(DIST, hashedName));
    jsManifest[file] = hashedName;
    log(`  ${cyan(file)} → ${cyan(hashedName)}`);
}

// ── Step 3: Minify CSS ───────────────────────────────────
log('Minifying CSS...');
const cssFile = 'style.css';
const cssSrc = path.join(ROOT, cssFile);
try {
    execSync(`npx esbuild "${cssSrc}" --minify --outfile="${path.join(DIST, cssFile)}"`, {
        cwd: ROOT,
        stdio: 'pipe',
    });
} catch (e) {
    warn('CSS minification failed, copying unminified');
    fs.copyFileSync(cssSrc, path.join(DIST, cssFile));
}

const cssContent = fs.readFileSync(path.join(DIST, cssFile), 'utf8');
const cssHash = crypto.createHash('md5').update(cssContent).digest('hex').slice(0, 8);
const hashedCss = `assets/style.${cssHash}.css`;
fs.renameSync(path.join(DIST, cssFile), path.join(DIST, hashedCss));
jsManifest[cssFile] = hashedCss;
log(`  ${cyan(cssFile)} → ${cyan(hashedCss)}`);

// ── Step 4: Process index.html ────────────────────────────
log('Processing index.html...');
let html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');

// Replace script/css references with hashed versions
html = html.replace('href="style.css"', `href="${hashedCss}"`);
for (const [original, hashed] of Object.entries(jsManifest)) {
    if (original.endsWith('.js')) {
        html = html.replace(`src="${original}"`, `src="${hashed}"`);
    }
}

fs.writeFileSync(path.join(DIST, 'index.html'), html);

// ── Step 5: Copy static assets ──────────────────────────
log('Copying static assets...');
const staticAssets = [
    'manifest.json',
    'sw.js',
];

for (const asset of staticAssets) {
    const src = path.join(ROOT, asset);
    if (fs.existsSync(src)) {
        fs.copyFileSync(src, path.join(DIST, asset));
        log(`  ${cyan(asset)}`);
    }
}

// Copy icons directory
const iconsDir = path.join(ROOT, 'icons');
if (fs.existsSync(iconsDir)) {
    const distIcons = path.join(DIST, 'icons');
    fs.mkdirSync(distIcons, { recursive: true });
    for (const icon of fs.readdirSync(iconsDir)) {
        fs.copyFileSync(path.join(iconsDir, icon), path.join(distIcons, icon));
    }
    log(`  ${cyan('icons/')}`);
}

// ── Step 6: Update service worker cache list ─────────────
log('Updating service worker asset list...');
let swContent = fs.readFileSync(path.join(DIST, 'sw.js'), 'utf8');

// Update CACHE_NAME with build timestamp
const buildTimestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);
swContent = swContent.replace(
    /const CACHE_NAME = '[^']+'/,
    `const CACHE_NAME = 'mediminder-build-${buildTimestamp}'`
);

// Update ASSETS array with hashed filenames
const newAssets = [
    "'./'",
    "'./index.html'",
    `'./${hashedCss}'`,
    ...jsFiles.map(f => `'./${jsManifest[f]}'`),
    "'./manifest.json'",
    "'./icons/icon-192.png'",
    "'./icons/icon-512.png'"
];
swContent = swContent.replace(
    /const ASSETS = \[[\s\S]*?\];/,
    `const ASSETS = [\n    ${newAssets.join(',\n    ')}\n];`
);

fs.writeFileSync(path.join(DIST, 'sw.js'), swContent);

// ── Step 7: Generate build manifest ──────────────────────
const manifest = {
    buildTime: new Date().toISOString(),
    files: jsManifest,
};
fs.writeFileSync(
    path.join(DIST, 'build-manifest.json'),
    JSON.stringify(manifest, null, 2)
);

// ── Summary ──────────────────────────────────────────────
const distFiles = [];
function walkDir(dir, prefix = '') {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        if (entry.isDirectory()) {
            walkDir(path.join(dir, entry.name), `${prefix}${entry.name}/`);
        } else {
            const filePath = path.join(dir, entry.name);
            const size = fs.statSync(filePath).size;
            distFiles.push({ name: `${prefix}${entry.name}`, size });
        }
    }
}
walkDir(DIST);

log('');
log('Build complete! Output:');
console.log('');
let totalSize = 0;
for (const f of distFiles) {
    const sizeKB = (f.size / 1024).toFixed(1);
    totalSize += f.size;
    console.log(`  ${f.name.padEnd(45)} ${sizeKB.padStart(8)} KB`);
}
console.log(`  ${'─'.repeat(55)}`);
console.log(`  ${'Total'.padEnd(45)} ${(totalSize / 1024).toFixed(1).padStart(8)} KB`);
console.log('');
log(`Output: ${cyan('dist/')}`);
