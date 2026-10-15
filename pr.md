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
gh pr checks --watch                             # 等 CI 跑完，見下一節
```

- 描述先寫在**暫存檔**再用 `--body-file` 帶進去，不要寫在指令列裡，也**不要 commit
  進 repo**
- 還在進行中的開草稿：加 `--draft`
- 收到 review 之後避免 force push，否則審查者看不到你改了什麼。必須 rebase 時
  用 `--force-with-lease`，並在 PR 留言說明

---

## 合併條件：CI 全過

**任何一項檢查沒有 pass，PR 就不能合併。** 失敗（fail）、還在跑（pending）、
被取消（cancelled）都算沒過；只有被跳過（skipped）算過 —— 那是路徑過濾判斷這個
PR 不需要它，例如只改文件的 PR 不會 build App。

這條規則對 PR 上出現的**每一項**檢查都成立，不論 GitHub 的分支規則有沒有把它列為
必要。目前每個 PR 會跑的：

| 檢查（`gh pr checks` 顯示的名稱） | 來源 | 什麼時候跑 | 驗什麼 |
|---|---|---|---|
| `build` | `ci.yml` | 每個 PR | commit 訊息、分支已 rebase 到 base、workflow 語法／workflow 安全／layering／l10n／storage／通知音效／lockfile／tooling 各道 gate、format + analyze、codegen 是最新、完整測試（含覆蓋率上傳） |
| `changes` | `android.yml`、`ios.yml` | 每個 PR | 判斷這個 PR 需不需要 build Android／iOS |
| `Android` | `android.yml` | 動到 `android/`、`assets/`、`lib/`、`pubspec.yaml` | Android 能 build |
| `iOS` | `ios.yml` | 動到 `ios/`、`assets/`、`lib/`、`pubspec.yaml` | iOS 能 build |
| `code-review` | `review.yml` | 開 PR、推新 commit | 自動 code review 跑完；它留的意見要逐條回應 |
| `codecov/project` | Codecov | `build` 上傳覆蓋率之後 | 總覆蓋率比 base 掉超過 1% 就失敗 |
| `codecov/patch` | Codecov | 同上 | 新增與修改行的覆蓋率；只回報，不會失敗 |

這張表要跟著 `.github/workflows/` 改：新增、改名或拿掉一個 job，同一個 commit
就要更新這裡。

### 合併前

- 用 `gh pr checks <PR>` 確認全部是 pass 或 skipped，**不要只看綠色勾勾的摘要**
  —— 還在跑的檢查不會讓摘要變紅
- 推了新 commit，之前的結果就不算數，要等新的一輪跑完
- 審查者合併前自己再看一次，不靠 PR 作者說「CI 過了」

### 沒過的時候

- **修好再推一個新的 commit**，不要用 force push 蓋掉（見上面「開 PR」）
- 確定是環境問題（runner 斷線、外部服務逾時）才重跑：`gh run rerun <run-id> --failed`，
  並在 PR 留言寫明重跑的原因。同一項重跑兩次還是失敗，就當成真的失敗處理
- 本機先跑 `tool/check.sh`：`build` 跑的就是同一份，在本機失敗比在 CI 失敗快得多

---

## 禁止

- **任何工具署名**：`Generated with …`、🤖、agent 名稱、模型名稱 —— 和
  [commit.md → 禁止](commit.md#禁止gate-會擋) 同一條規則，PR 描述沒有 gate 擋，
  所以更要自己注意
- **CI 沒有全過就合併**，包括用管理員權限繞過：分支規則的 bypass、`gh pr merge --admin`、
  或不開 PR 直接推 main。真的有緊急狀況必須例外，事後在 PR 或 commit 說明原因
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
