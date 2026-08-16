<!--
  進行中的 PR 請開草稿（Draft）。

  收到 review 之後請避免 force push，否則審查者看不到你改了什麼。

  送出之前，請在本機跑過 AGENTS.md「Before pushing」那份清單 —— CI 跑的就是
  同一份，在本機失敗比在 CI 失敗快得多。
-->

## 這個 PR 做了什麼

<!-- 一句話講清楚。細節寫在 commit 訊息裡，不要寫在這裡。 -->

## 相關 issue

<!-- 「closes #1234」會在合併時自動關閉對應的 issue。 -->

- closes #

## 怎麼驗

<!--
  審查者要怎麼確認這是對的：重現步驟、測過的裝置、UI 變更的前後截圖。

  如果碰到安全關鍵的部分（EEW 推估、警報門檻、通知路徑、背景定位），
  請額外說明你怎麼確認它沒有壞。
-->

## 檢查清單

- [ ] `tool/check_commits.sh origin/main..HEAD` 通過
      —— commit 訊息就是更新日誌，格式見 [commit.md](../commit.md)
- [ ] **一個 commit 一件事**（這條 gate 驗不了，靠自己和 review）
- [ ] `mise exec -- flutter analyze` 與 `mise exec -- flutter test` 通過
- [ ] 新的使用者可見字串都走 `AppLocalizations`，沒有寫死
- [ ] 有 UI 變更的話：用的是 `AppSpacing` / `AppRadius` / `AppMotion`，
      深色模式看過，文字對比度可接受
