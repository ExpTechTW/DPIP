# Pull Request 格式

**commit 訊息是更新日誌，PR 描述是審查紀錄。** 兩者各有各的讀者：

| | 誰讀 | 有 gate 嗎 | 進 main 嗎 |
|---|---|---|---|
| commit 訊息 | 使用者（更新日誌）、幾年後追問「為什麼」的人 | 有，`tool/check/commits.sh` | 會，原封不動 |
| PR 標題與描述 | 審查者、之後翻 PR 找脈絡的人 | **沒有** | 不會 |

這個 repo 只開放 rebase 合併，所以進 main 的是 commit 本身，不是 PR 的標題和描述
（見 [commit.md → gate 只看 commit](commit.md#gate-只看-commit不看-pr-標題與描述)）。
也正因為沒有 gate 在看，PR 的格式只能靠這份文件和 review。

---

## 標題

```
test(map): cover the station sheet and the typhoon panel
└┬─┘ └┬┘  └───────────────────┬────────────────────┘
type scope                   摘要
```

**英文，[Conventional Commits](https://www.conventionalcommits.org/) 格式：
`<type>(<scope>): <summary>`。**

- `type` 與 `scope` 用 [commit.md](commit.md#type) 的同一張表。跨很多區的改動
  **不要寫 scope**，硬填一個只會讓人誤以為範圍很小
- 祈使句、純 ASCII、最多 72 字元、結尾不加句號 —— 和 commit 摘要一樣
- **只有一則 commit 的 PR，標題就是那則 commit 的摘要**，一字不改
- 多則 commit 時寫整體做了什麼；`type` 取最主要的那個（有 `feat` 就是 `feat`，
  只有測試就是 `test`）
- 不要用 GitHub 從分支名生出來的預設標題（`Fix/version week`）

---

## 描述

**繁體中文，詳細紀錄。** 照 [`.github/pull_request_template.md`](.github/pull_request_template.md)
的四段寫，每一段都要有內容。

### 這個 PR 做了什麼

- **做了什麼、為什麼**：開頭一兩句講清楚，讓只讀第一段的人也知道這個 PR 在幹嘛
- **改動內容**：動到哪些模組、哪些檔案。**正式程式碼和測試分開說**，正式程式碼的
  改動再小也要點名 —— 那是審查者最該看的地方
- **有數字就給數字**：前後對比（覆蓋率、耗時、檔案大小、請求次數），並寫明怎麼量的、
  在哪裡量的
- **沒做的、刻意留下的、疑似問題**：範圍外的事、發現了但沒修的 bug（附 `檔案:行號`）、
  還沒在實機確認的部分。寫出來，不要讓審查者自己發現

### 相關 issue

- 開 PR 前先搜：`gh issue list --state all --search '<關鍵字>'`
- **修好的**寫 `closes #N`（合併時 GitHub 會自動關閉）
- **相關但沒有解決的**寫 `refs #N`
- 接續前一個 PR 的，引用那個 PR（`接續 #584`）
- **真的沒有就寫「沒有對應的 issue」**，不要留下範本裡空的 `closes #`

### 怎麼驗

- 跑了哪些檢查、結果是什麼（`tool/check.sh`、`tool/dev/test.sh` 幾個測試通過）
- 實機或模擬器測了什麼。**沒測的要直說**，例如「尚未在 iOS 實機上看過」
- 碰到安全關鍵的部分 —— EEW 推估、警報門檻、通知路徑、背景定位 —— 額外說明
  你怎麼確認它沒有壞
- UI 變更附前後截圖，深色模式也要

### 檢查清單

範本最後的清單照實勾選。沒做到的不要勾，在旁邊寫原因。

---

## 開 PR

```sh
git fetch origin && git rebase origin/main      # 落後 main 的分支 CI 會擋
tool/check/commits.sh origin/main..HEAD          # commit 訊息先過
git push -u origin <branch>                      # pre-push 會跑 CI 的每一道 gate
gh pr create --base main \
  --title '<type>(<scope>): <summary>' \
  --body-file <描述檔>
```

- 描述先寫在**暫存檔**再用 `--body-file` 帶進去，不要寫在指令列裡，也**不要 commit
  進 repo**
- 還在進行中的開草稿：加 `--draft`
- 收到 review 之後避免 force push，否則審查者看不到你改了什麼。必須 rebase 時
  用 `--force-with-lease`，並在 PR 留言說明

---

## 禁止

- **任何工具署名**：`Generated with …`、🤖、agent 名稱、模型名稱 —— 和
  [commit.md → 禁止](commit.md#禁止gate-會擋) 同一條規則，PR 描述沒有 gate 擋，
  所以更要自己注意
- 只有一句話、或整段照抄 commit 訊息的描述
- 把 PR 描述當成給未來的人看的紀錄：那是 commit 訊息和程式碼註解的工作，
  PR 描述不會進 main

---

## 範例

````markdown
標題：fix(map): stop the wind particles flickering on Android

## 這個 PR 做了什麼

把 maplibre fork 從 `9804c2f9` 升到 `48bce744`，修正 Android 上風場粒子閃爍，
iOS 的粒子改在地圖同一個 Metal pass 內繪製。

- fork 範圍內的修改：`71d58c4`（iOS Metal pass）、`403330f`（Android custom
  layer）、`f51a147`（Android 閃爍）、`48bce74`（iOS composite）
- 四個 ref 一起升級（兩個直接相依、兩個 `dependency_overrides`）——
  pubspec 註解要求它們指向同一個 fork commit
- `pubspec.lock` 在移開 `pubspec_overrides.yaml` 後重新產生，沒有本機路徑

## 相關 issue

沒有對應的 issue。

## 怎麼驗

- `tool/check.sh` 全過；`test/features/map` 351 個測試通過
- **尚未在實機上看過**：請在 Android 與 iOS 開風場預報圖層，確認粒子不閃爍、
  拖動縮放時跟著地圖
````
