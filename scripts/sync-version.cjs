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
