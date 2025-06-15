[![splash](/.github/assets/splash.png)](#下載)

<div align="center">
<a href="https://github.com/ExpTechTW/DPIP/tree/main"><img alt="status" src="https://img.shields.io/badge/status-stable-blue.svg"></a>
<a href="https://github.com/ExpTechTW/DPIP/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/exptechtw/dpip"></a>
<a href="https://github.com/ExpTechTW/DPIP/actions/workflows/github_actions.yml"><img alt="GitHub Workflow Status" src="https://github.com/ExpTechTW/DPIP/actions/workflows/github_actions.yml/badge.svg"></a>
<a title="Crowdin" target="_blank" href="https://crowdin.com/project/dpip"><img alt="Crowdin Localization" src="https://badges.crowdin.net/dpip/localized.svg"></a>
<a href="https://good-labs.github.io/greater-good-affirmation"><img alt="Greater Good" src="https://good-labs.github.io/greater-good-affirmation/assets/images/badge.svg"></a>
<img alt="GitHub License" src="https://img.shields.io/github/license/exptechtw/dpip">
<a href="https://exptech.dev/dpip"><img alt="website" src="https://img.shields.io/badge/website-exptech.dev-purple.svg"></a>
<a href="https://discord.gg/5dbHqV8ees"><img alt="TREM Discord"  src="https://img.shields.io/discord/926545182407688273?color=%235865F2&logo=discord&logoColor=white"></a>
</div>

DPIP（Disaster Prevention Information Platform）是由臺灣本土團隊開發的行動應用程式，整合了 TREM-Net（臺灣即時地震觀測網）的強震即時警報與地震資訊，以及中央氣象署的資料，為使用者提供一個整合、便捷的防災資訊平台。

### 強震即時警報

強震即時警報（Earthquake Early Warning, EEW）系統透過部署於各地的地震波觀測站，在地震發生時即時回傳地震波數據至伺服器進行分析，並產生地震速報。這項技術能為使用者爭取數秒至數十秒的寶貴時間，讓民眾能及時採取防災應變及避難措施。

### TREM-Net 臺灣即時地震觀測網

TREM-Net 是一個自 2022 年 6 月起開始在全臺各地部署的觀測網專案，由兩個子系統組成：**SE-Net**（強震觀測網，使用加速度儀）及 **MS-Net**（微震觀測網，使用速度儀），共同記錄地震發生時的完整數據。

## 合作夥伴

我們很榮幸能與以下優秀的企業合作，共同推動防災資訊的普及：

<h3>
  <a href="https://www.geoscience.com.tw/">
    巨科資訊有限公司
    <img src="https://github.com/user-attachments/assets/34875ff1-ace2-4e92-ac32-d98e5717b62e" alt="巨科資訊有限公司" width="auto" height="28" align="right">
  </a>
</h3>

巨科資訊有限公司是一家專注於地理資訊系統的專業公司，為我們的開發工作提供了寶貴的設備支援。他們的專業知識和資源對專案的發展起到了重要作用。

<h3>
  <a href="https://www.twds.com.tw/">
    台灣數位串流有限公司
    <img src="https://github.com/user-attachments/assets/e4b793c8-58b3-4058-a246-24f646b4b3d7" alt="台灣數位串流有限公司" width="auto" height="28" align="right">
  </a>
</h3>

台灣數位串流有限公司為我們提供了強大的雲端運算資源和網路頻寬支援，同時也提供了寶貴的技術諮詢。他們的支援確保了我們的服務能夠穩定且高效地運行。

我們由衷感謝這些合作夥伴對開源社群的支持與貢獻。正是有了他們的協助，我們才能持續為使用者提供更好的服務。

## 資料來源

本應用程式的資料來源包括：

### 官方來源

- [交通部中央氣象署](https://www.cwa.gov.tw/)
- [國家災害防救科技中心](https://www.ncdr.nat.gov.tw/)

### 非官方來源

- TREM-Net by [ExpTech Studio](https://exptech.dev/)

## 下載

你可以在 [Play Store](https://play.google.com/store/apps/details?id=com.exptech.dpip) 和 [App Store](https://apps.apple.com/tw/app/dpip-%E7%81%BD%E5%AE%B3%E5%A4%A9%E6%B0%A3%E8%88%87%E5%9C%B0%E9%9C%87%E9%80%9F%E5%A0%B1/id6468026362) 上取得 DPIP。

你也可以從我們的 [Release 頁面](https://github.com/ExpTechTW/DPIP/releases/latest)上取得 DPIP 的安裝包進行手動安裝。

## 翻譯

DPIP 支援多語言，我們正在 Crowdin 平台上進行翻譯。如果你願意協助我們將這個專案翻譯成其他語言，歡迎加入我們的 Crowdin 翻譯社群。

你可以[點擊這裡前往我們的 Crowdin 專案頁面](https://crowdin.com/project/dpip)，選擇你熟悉的語言並開始翻譯。每一份貢獻都將幫助我們將防災資訊傳遞給更多的人！

如果你沒有看到你熟悉的語言，歡迎在我們的 [Issue](https://github.com/ExpTechTW/DPIP/issues) 中提出新的語言請求，我們會盡快為你開啟。

## 從原始碼建置

### 環境需求

在開始建置之前，請確保你的開發環境已安裝並配置以下軟體：

- **Flutter SDK**: [安裝指引](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: 已包含在 Flutter SDK 中
- [**Android Studio**](https://developer.android.com/studio?hl=ja) 或 [**Xcode**](https://developer.apple.com/jp/xcode/)（iOS 開發用）
  - 也可以使用 [VSCode](https://code.visualstudio.com/) 或其他你喜歡的 IDE
- _\*可選\*_ [**Git**](https://git-scm.com/): 用於複製存儲庫

```console
Flutter 3.33.0-0.2.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision 1db45f7408 • 2025-05-29 10:05:06 -0700
Engine • revision 308a517184 • 2025-05-23 15:32:17 -0700
Tools • Dart 3.9.0 (build 3.9.0-100.2.beta) • DevTools 2.46.0
```

### 建置步驟

1. 取得原始碼

   - **下載壓縮檔**

     你可以直接在 Github 上下載存儲庫壓縮檔

     ![Download Source ZIP](/.github/assets/download_source.png)

   - **使用 Git**

     使用以下指令複製專案：

     ```bash
     git clone https://github.com/ExpTechTW/DPIP.git
     ```

2. 進入專案目錄

   ```bash
   cd DPIP
   ```

3. 安裝相依套件

   ```bash
   flutter pub get --no-example
   ```

4. 產生建置檔案

   ```bash
   dart run build_runner build
   ```

5. 建置應用程式

   - **Android APK**

     ```bash
     flutter build apk --release
     ```

   - **iOS**

     ```bash
     flutter build ios --release
     ```

## 如何貢獻

我們歡迎各種形式的貢獻！你可以透過以下方式參與專案：

- 回報問題或提出新功能建議：請在 [Issues](https://github.com/ExpTechTW/DPIP/issues) 中提出
- 提交程式碼：請 [Fork](https://github.com/ExpTechTW/DPIP/fork) 此倉庫，建立新分支進行修改，然後提交 [Pull Request](https://github.com/ExpTechTW/TREM/pulls)
- 改進文件：協助我們改進現有文件或撰寫新文件

衷心感謝所有讓 DPIP 成為可能的貢獻者：

<a href="https://github.com/exptechtw/dpip/graphs/contributors"><img src="https://contrib.rocks/image?repo=exptechtw/dpip" ></a>

## 開放原始碼授權

詳細的授權資訊請參閱 [LICENSE](LICENSE) 檔案

## Star History

<a href="https://star-history.com/#ExpTechTW/DPIP&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=ExpTechTW/DPIP&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=ExpTechTW/DPIP&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=ExpTechTW/DPIP&type=Date" />
 </picture>
</a>
