const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const rootPkg = JSON.parse(fs.readFileSync(path.join(rootDir, 'package.json'), 'utf-8'));
const version = rootPkg.version;

const packages = [
  'packages/common',
  'packages/web',
  'packages/desktop',
];

// Sync versions
for (const pkg of packages) {
  const pkgPath = path.join(rootDir, pkg, 'package.json');

  try {
    const content = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
    if (content.version !== version) {
      content.version = version;
      fs.writeFileSync(pkgPath, JSON.stringify(content, null, 2) + '\n');
      console.log(`Synced ${pkg} -> ${version}`);
    }
  } catch (err) {
    // ignore
  }
}

// Sync common/public to web/public and desktop/public
const commonPublic = path.join(rootDir, 'packages/common/public');
const targets = [
  path.join(rootDir, 'packages/web/public'),
  path.join(rootDir, 'packages/desktop/public'),
];

function copyRecursive(src, dest) {
  if (!fs.existsSync(src)) return;

  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    for (const item of fs.readdirSync(src)) {
      copyRecursive(path.join(src, item), path.join(dest, item));
    }
  } else {
    // Only copy if target doesn't exist or source is newer
    const shouldCopy = !fs.existsSync(dest) ||
      fs.statSync(src).mtimeMs > fs.statSync(dest).mtimeMs;
    if (shouldCopy) {
      fs.copyFileSync(src, dest);
    }
  }
}

for (const target of targets) {
  copyRecursive(commonPublic, target);
}
console.log('Synced common/public to web and desktop');
