const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

const APP_JS_PATH = path.join(__dirname, '../app.js');
const INDEX_HTML_PATH = path.join(__dirname, '../index.html');
const SW_PATH = path.join(__dirname, '../sw.js');

function getCurrentVersion() {
    const content = fs.readFileSync(APP_JS_PATH, 'utf8');
    const match = content.match(/const APP_VERSION = '(\d+\.\d+\.\d+)';/);
    if (!match) {
        console.error('Could not find APP_VERSION in app.js');
        process.exit(1);
    }
    return match[1];
}

function incrementVersion(version, type = 'patch') {
    const [major, minor, patch] = version.split('.').map(Number);
    if (type === 'major') return `${major + 1}.0.0`;
    if (type === 'minor') return `${major}.${minor + 1}.0`;
    return `${major}.${minor}.${patch + 1}`;
}

function updateAppJs(newVersion) {
    let content = fs.readFileSync(APP_JS_PATH, 'utf8');
    content = content.replace(/const APP_VERSION = '\d+\.\d+\.\d+';/, `const APP_VERSION = '${newVersion}';`);
    fs.writeFileSync(APP_JS_PATH, content);
}

function updateIndexHtml(newVersion) {
    let content = fs.readFileSync(INDEX_HTML_PATH, 'utf8');
    // Regex to match "vX.Y.Z" usage in specific IDs
    // We look for patterns like id="splash-version">v1.3.0< and id="app-version">v1.3.0<

    // Replace splash version
    content = content.replace(/(id="splash-version">)v\d+\.\d+\.\d+(<\/p>)/, `$1v${newVersion}$2`);

    // Replace app version
    content = content.replace(/(id="app-version">)v\d+\.\d+\.\d+(<\/div>)/, `$1v${newVersion}$2`);

    fs.writeFileSync(INDEX_HTML_PATH, content);
}

function updateSwJs(newVersion) {
    let content = fs.readFileSync(SW_PATH, 'utf8');
    // Update CACHE_NAME to force cache invalidation
    // Looks for: const CACHE_NAME = 'mediminder-v...';
    content = content.replace(/const CACHE_NAME = 'mediminder-v[^']+';/, `const CACHE_NAME = 'mediminder-v${newVersion}';`);
    fs.writeFileSync(SW_PATH, content);
}

function gitCommit(newVersion, noCommit = false) {
    try {
        if (noCommit) {
            console.log('Skipping git commit due to --no-commit flag.');
            return;
        }
        execSync(`git add ${APP_JS_PATH} ${INDEX_HTML_PATH} ${SW_PATH}`);
        execSync(`git commit -m "chore: bump version to v${newVersion}"`);
        console.log(`Committed version bump: v${newVersion}`);
    } catch (e) {
        console.error('Git commit failed:', e.message);
    }
}

// Main execution
const currentVersion = getCurrentVersion();
const args = process.argv.slice(2);
const type = args.find(arg => !arg.startsWith('--')) || 'patch'; // 'patch', 'minor', 'major'
const noCommit = args.includes('--no-commit');

const newVersion = incrementVersion(currentVersion, type);

console.log(`Bumping version: ${currentVersion} -> ${newVersion} (${type})`);

updateAppJs(newVersion);
updateIndexHtml(newVersion);
updateSwJs(newVersion);
gitCommit(newVersion, noCommit);

console.log('Done! 🚀');
