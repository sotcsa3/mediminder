const fs = require('fs');
const path = require('path');

const srcFiles = [
    'index.html',
    'app.js',
    'style.css',
    'manifest.json',
    'sw.js',
    'api-config.js',
    'api-service.js',
    'backend-db.js'
];
const srcDirs = ['icons'];

const destDir = path.join(__dirname, '../www');

if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir);
}

// remove all files in destination directory
fs.readdirSync(destDir).forEach(file => {
    const filePath = path.join(destDir, file);
    fs.rmSync(filePath, { recursive: true, force: true });
});


srcFiles.forEach(file => {
    const srcPath = path.join(__dirname, '../', file);
    const destPath = path.join(destDir, file);
    if (fs.existsSync(srcPath)) {
        fs.copyFileSync(srcPath, destPath);
        console.log(`Copied ${file}`);
    } else {
        console.warn(`File not found: ${file}`);
    }
});

srcDirs.forEach(dir => {
    const srcPath = path.join(__dirname, '../', dir);
    const destPath = path.join(destDir, dir);
    if (fs.existsSync(srcPath)) {
        fs.cpSync(srcPath, destPath, { recursive: true });
        console.log(`Copied directory ${dir}`);
    } else {
        console.warn(`Directory not found: ${dir}`);
    }
});

console.log('Build complete! -> www/');
