// https://www.electron.build/configuration/configuration#afterpack
const fs = require('fs');
const path = require('path');

module.exports = async function(context) {
  console.log('🗑️  Removing unused language packs...');

  const appOutDir = context.appOutDir;
  const electronPath = context.electronPlatformName === 'darwin'
    ? path.join(appOutDir, `${context.packager.appInfo.productFilename}.app/Contents/Frameworks/Electron Framework.framework/Versions/A/Resources`)
    : path.join(appOutDir, 'locales');

  // 只保留英文
  const keepLanguages = ['en.lproj', 'en_US.pak'];

  try {
    if (context.electronPlatformName === 'darwin') {
      // macOS: 刪除 .lproj 目錄
      const files = fs.readdirSync(electronPath);
      let removed = 0;

      files.forEach(file => {
        if (file.endsWith('.lproj') && !keepLanguages.includes(file)) {
          const fullPath = path.join(electronPath, file);
          fs.rmSync(fullPath, { recursive: true, force: true });
          removed++;
        }
      });

      console.log(`✅ Removed ${removed} language packs from macOS`);
    } else {
      // Windows/Linux: 刪除 .pak 檔案
      const files = fs.readdirSync(electronPath);
      let removed = 0;

      files.forEach(file => {
        if (file.endsWith('.pak') && !keepLanguages.includes(file)) {
          const fullPath = path.join(electronPath, file);
          fs.unlinkSync(fullPath);
          removed++;
        }
      });

      console.log(`✅ Removed ${removed} language packs from ${context.electronPlatformName}`);
    }
  } catch (err) {
    console.error('⚠️  Error removing language packs:', err.message);
  }
};
