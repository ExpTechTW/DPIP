import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const rootDir = join(import.meta.dir, '..');
const rootPkg = JSON.parse(readFileSync(join(rootDir, 'package.json'), 'utf-8'));
const version = rootPkg.version;

const packages = [
  'packages/common',
  'packages/web',
  'packages/desktop',
];

for (const pkg of packages) {
  const pkgPath = join(rootDir, pkg, 'package.json');

  try {
    const content = JSON.parse(readFileSync(pkgPath, 'utf-8'));
    if (content.version !== version) {
      content.version = version;
      writeFileSync(pkgPath, JSON.stringify(content, null, 2) + '\n');
      console.log(`Synced ${pkg} -> ${version}`);
    }
  } catch (err) {
    // ignore
  }
}
