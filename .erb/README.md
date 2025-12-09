# Webpack 配置說明

此目錄包含 Electron main 和 preload process 的 webpack 配置，參考 [electron-react-boilerplate](https://github.com/electron-react-boilerplate/electron-react-boilerplate) 的架構。

## 📁 目錄結構

```
.erb/
├── configs/
│   ├── webpack.config.base.cjs       # 基礎配置
│   ├── webpack.config.main.dev.cjs   # 開發環境配置
│   ├── webpack.config.main.prod.cjs  # 生產環境配置
│   └── tsconfig.json                 # TypeScript 配置
└── package.json                      # 設置為 CommonJS
```

## 🔧 配置特點

### 基礎配置 (webpack.config.base.cjs)
- TypeScript 支援 (ts-loader)
- 錯誤提示模式 (stats: 'errors-only')
- 路徑別名解析 (tsconfig-paths-webpack-plugin)
- CommonJS2 輸出格式
- 輸出檔案使用 `.cjs` 副檔名 (因專案為 ESM 模式)

### 生產環境 (webpack.config.main.prod.cjs)
- ✅ Terser 壓縮
- ✅ Source maps (source-map)
- ✅ Bundle Analyzer (設置 `ANALYZE=true` 啟用)
- ✅ 外部依賴排除 (webpack-node-externals)

### 開發環境 (webpack.config.main.dev.cjs)
- ✅ Inline source maps
- ✅ 未壓縮代碼 (便於調試)
- ✅ Watch 模式支援

## 📦 構建命令

```bash
# 開發環境構建 (watch 模式)
npm run build:electron:dev

# 生產環境構建
npm run build:electron:prod

# 開發模式 (Next.js + Electron)
npm run dev

# 打包應用
npm run package
npm run package:mac
npm run package:win
npm run package:linux
```

## 🔍 Bundle 分析

查看打包大小分析：

```bash
ANALYZE=true npm run build:electron:prod
```

## 📝 注意事項

1. **模組系統**: 配置檔案使用 `.cjs` 擴展名，因為專案根目錄設置為 ESM (`"type": "module"`)
2. **TypeScript**: Electron 源碼使用 TypeScript，經 webpack 編譯後輸出到 `dist/` 目錄
3. **Next.js**: Renderer process 仍由 Next.js 處理，輸出靜態檔案到 `out/` 目錄
4. **Source Maps**: 生產環境使用獨立 source map，開發環境使用 inline source map
5. **Electron Builder**:
   - 配置檔案 `electron-builder.yml` 已更新
   - main entry point 指向 `./dist/main.cjs`
   - 只打包必要的 `dist/main.cjs` 和 `dist/preload.cjs`
   - 排除了構建產物（dmg, exe 等）避免重複打包

## 🆚 與原始方案的差異

**改進前:**
- ❌ Electron 使用 JavaScript
- ❌ 無構建流程
- ❌ 無壓縮優化
- ❌ 無 source maps

**改進後:**
- ✅ Electron 使用 TypeScript
- ✅ Webpack 構建流程
- ✅ 生產環境壓縮
- ✅ 完整 source maps 支援
- ✅ 開發環境 watch 模式
- ✅ Bundle 分析工具
