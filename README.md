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

## 簡介

DPIP（Disaster prevention information platform）是一款由臺灣本土團隊設計的 App，整合 TREM-Net (臺灣即時地震觀測網) 之強震即時警報與地震資訊，以及中央氣象署資料，提供一個整合、單一且便利的防災資訊應用程式。

### 強震即時警報

強震即時警報（Earthquake Early Warning, EEW），是藉由部署於各地之地震波觀測站，在地震發生時將測得之地震波回傳至伺服器計算並產生地震速報，為你爭取數秒甚至數十秒之時間，進行防災應變及避難措施。

### TREM-Net 臺灣即時地震觀測網

TREM-Net 是一個 2022 年 6 月初開始於全臺各地部署站點的專案，由兩個觀測網組成，分別為 **SE-Net**（強震觀測網「加速度儀」）及 **MS-Net**（微震觀測網「速度儀」），共同紀錄地震時的各項數據。

## 資料來源

所有資料皆來自於以下單位：

### 官方來源

- [交通部中央氣象署](https://www.cwa.gov.tw/)
- [國家災害防救科技中心](https://www.ncdr.nat.gov.tw/)

### 非官方來源

- TREM-Net by [ExpTech Studio](https://exptech.dev/)
- [The Weather Channel](https://weather.com/?Goto=Redirected)

## 下載

你可以在 [Play Store](https://play.google.com/store/apps/details?id=com.exptech.dpip) 和 [App Store](https://apps.apple.com/tw/app/dpip-%E7%81%BD%E5%AE%B3%E5%A4%A9%E6%B0%A3%E8%88%87%E5%9C%B0%E9%9C%87%E9%80%9F%E5%A0%B1/id6468026362) 上取得 DPIP。

你也可以從我們的 [Release 頁面](https://github.com/ExpTechTW/DPIP/releases/latest)上取得 DPIP 的安裝包進行手動安裝。

## 翻譯

DPIP 支援多語言，並且我們正在 Crowdin 上進行翻譯工作。如果你願意幫助我們將這個專案翻譯成其他語言，歡迎加入我們的 Crowdin 翻譯社群。

你可以通過[點擊這裡前往我們的 Crowdin 專案頁面](https://crowdin.com/project/dpip)，選擇你熟悉的語言並開始翻譯。每一點貢獻都將幫助我們將防災資訊傳遞給更多的人！

沒有看見你熟悉的語言？我們歡迎你在我們的 [Issue](https://github.com/ExpTechTW/DPIP/issues) 中開新的語言請求，我們將會盡速為你開啟。

## 從原始碼建置

### 條件

在開始之前，請確保你的環境已經安裝並配置了以下軟體：

- **Flutter SDK**: [安裝指引](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: 已包含在 Flutter SDK 中
- [**Android Studio**](https://developer.android.com/studio?hl=ja) 或 [**Xcode**](https://developer.apple.com/jp/xcode/) (適用於 iOS 開發)
  - 也可以使用 [VSCode](https://code.visualstudio.com/) 或其他你喜歡的 IDE
- _\*可選\*_ [**Git**](https://git-scm.com/): 用於複製存儲庫

### 建置步驟

1. 複製或下載存儲庫

   - **下載壓縮檔**

     你可以在 Github 上直接下載存儲庫壓縮檔

     ![Download Source ZIP](/.github/assets/download_source.png)

   - **使用 Git**

     使用以下 git 指令來複製這個專案的原始碼

     ```bash
     git clone https://github.com/ExpTechTW/DPIP.git
     ```

2. 切換到專案目錄

   接下來，進入到剛複製的專案目錄：

   ```bash
   cd DPIP
   ```

3. 安裝相依套件

   使用以下指令來安裝專案所需的所有 Dart 和 Flutter 相依套件：

   ```bash
   flutter pub get --no-example
   ```

4. 預組建置

   使用以下指令來產生建置時需要的部分自動產生檔案：

   ```bash
   dart run build_runner build
   ```

5. 建置應用程式

   最後，你可以使用以下指令來建置應用程式：

   - **Android APK**

     ```bash
     flutter build apk --release
     ```

   - **iOS**

     ```bash
     flutter build ios --release
     ```

## 如何貢獻

我們歡迎任何形式的貢獻！你可以通過以下方式參與此專案：

- 報告 Bug 或建議新功能：請在 [Issues](https://github.com/ExpTechTW/DPIP/issues) 。
- 提交程式碼：請 [Fork](https://github.com/ExpTechTW/DPIP/fork) 此倉庫，建立一個新的分支進行修改，然後提交 [Pull Request](https://github.com/ExpTechTW/TREM/pulls)。
- 撰寫文件：幫助我們改進現有文件或撰寫新文件。

衷心感謝所有使 DPIP 成為可能的貢獻者：

<a href="https://github.com/exptechtw/dpip/graphs/contributors"><img src="https://contrib.rocks/image?repo=exptechtw/dpip" ></a>

## 開放原始碼授權

開放原始碼授權資訊請詳見 [LICENSE](LICENSE) 檔案
