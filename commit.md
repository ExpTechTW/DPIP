# Commit 格式

**commit 訊息就是更新日誌。** `tool/release/notes.sh` 直接讀這些訊息產生 GitHub
release 的內容，所以一則寫壞的 commit 會在使用者讀得到的地方留下一個洞——而
commit 訊息推出去之後**改不了**，唯一的修法是 rebase。

`tool/check/commits.sh` 是 CI gate，不合格直接失敗。

---

## 提交前必須跑 `tool/commit.sh`

```sh
tool/commit.sh
```

**每一則 commit 之前都要跑，agent 尤其。** 它只讀不寫 —— 不會 commit、不會
stage、不會 fetch、不改任何檔案 —— 但它會把「現在提交會出什麼事」一次講完：

| 它會講 | 為什麼你需要在提交**之前**知道 |
|---|---|
| 你在哪個分支、HEAD 是什麼、base 多久沒動 | 在 `main` 上提交、或拿一個上禮拜的 `origin/main` 判斷落後幾則，兩個都是白做工 |
| 落後 base 幾則、有沒有 merge commit | 兩個都會被 CI 擋，而且都只能用 rebase 修 |
| staged / unstaged / untracked 各是什麼 | 未追蹤的檔案 CI 看不到 —— 少 stage 一個新檔案，只會在 runner 上失敗 |
| 有沒有 stage 到不該進版控的東西 | `build/`、`.dart_tool/`、`build_info.g.dart` |
| 這次改動碰到哪些 feature 與範圍 | 挑 `<scope>`；跨太多區就不要寫 scope |
| 是不是只碰單一平台 | 提醒你補 `Platform:` trailer |
| ARB 只改了一部分 | 少一個語系的 key 會無聲退回英文 |
| 訊息格式的樣板與三個會無聲失敗的規則 | 條目數對不齊、忘了寫 `Category` 行、署名 |
| 現有 commit 過不過 gate | 過不了只能 rebase，越早知道越便宜 |

寫好草稿之後可以先驗再提交：

```sh
tool/commit.sh --message <草稿檔>   # 只驗訊息
tool/commit.sh --check             # 連 CI 的每一道 gate 一起跑
```

提交完**再跑一次** —— 這時它檢查的是你剛寫的那一則。

它不會替你判斷「這是不是一件事」，那件事沒有辦法自動判斷（見
[一個 commit 一件事](#一個-commit-一件事)）；它只會在改動跨了太多 feature、
或文件和程式混在一起的時候，提醒你停一下。

---

## 格式

```
<type>(<scope>): <英文摘要>

<Category>(<locale>): <更新日誌條目>
<Category>(<locale>): <更新日誌條目>
```

摘要行給 `git log` 讀，條目行給使用者讀。單一平台的變更多一行 trailer（見
「平台」）。

**沒有散文說明。** 為什麼這樣做、試過什麼、踩到什麼坑，全部寫在程式碼註解裡
——那是下一個改這段程式的人會看到的地方，而更新日誌的讀者一項都用不到。

---

## 摘要行

```
feat(mesh): show the radio's own packet counters
└┬─┘ └─┬┘  └──────────────┬──────────────────┘
 type scope              摘要
```

### type

| type | 用在 | 進更新日誌？ |
|---|---|---|
| `feat` | 使用者拿到新東西 | 🌟 新功能 |
| `fix` | 修正使用者遇得到的錯誤行為 | 🐞 錯誤修正 |
| `perf` | 一樣的行為，更少的資源 | 🔌 最佳化 |
| `refactor` | 一樣的行為，更好的結構 | 🔌 最佳化 |
| `docs` | 只有文件 | ✗ |
| `test` | 只有測試 | ✗ |
| `build` | 建置、發布、相依套件 | ✗ |
| `ci` | workflow、gate | ✗ |
| `style` | 只有排版，沒有語意 | ✗ |
| `chore` | 其他雜務 | ✗ |
| `revert` | 回退某個 commit | ✗ |

**選 type 的判準是「使用者看不看得到」，不是「改了哪個資料夾」。**

- 把一個使用者可見的行為改動藏在 `build:` 底下，它就不會出現在任何更新日誌裡
  ——這正是拆掉舊 `build: cut releases from tags…` 那則的原因，Play track 改成
  production 是使用者可見的
- 加一個 142 行的腳本不是 `docs:`，就算它旁邊有文件

### scope

選填，小寫，對應功能區：`mesh` `map` `weather` `eew` `notify` `location`
`home` `changelog` `settings`。

跨多個區的改動就**不要寫 scope**——硬填一個會讓更新日誌把它歸錯地方。

### 摘要本身

- **英文，純 ASCII。** 中文在下面的區塊，不在這裡
- **祈使句**：`add`、`fix`、`stop`、`show`。不是 `added`、`fixes`、`adding`
- **不是名詞片語**：`commit message rules` ✗ → `define a bilingual commit format` ✓
- 最多 **72 字元**，結尾**不加句號**
- 說明**做了什麼給使用者**，不是碰了哪個檔案

---

## 更新日誌條目

**這是這份格式存在的理由。** 說明區塊裡的每一行 `Category(locale): 文字` 都是
更新日誌的一個條目，`tool/release/notes.sh` 用一條正則表達式把它們抓出來。

```
feat(map): overlay radar echo on the map

New(zh-Hant): 地圖可以疊加雷達回波
New(en-US): the map can overlay radar echo
```

### 格式

```
New(zh-Hant): 地圖可以疊加雷達回波
└┬┘ └──┬──┘  └────────┬────────┘
分類    語系            條目文字
```

| 分類 | 進更新日誌的哪一區 |
|---|---|
| `New` | 🌟 新功能 |
| `Optimization` | 🔌 最佳化 |
| `Fix` | 🐞 錯誤修正 |

**分類是宣告的，不是從 `<type>` 推的。** 所以一個 `chore:` 的 commit 如果真的
修好了使用者看得到的東西，寫一行 `Fix(...)` 它就會出現——舊做法會讓它無聲消失。

### 語系

| | |
|---|---|
| **必填** | `zh-Hant`、`en-US` |
| 選填 | `zh-Hans` `zh-Hant-HK` `ja-JP` `ko-KR` `th-TH` `vi-VN` `id-ID` `fil-PH` |

必填的兩個是 app 自己的語言，和所有其他人的退路。選填的有人寫就有，沒有就退回
英文——app 內會依讀者的語系挑，挑不到才退。

**gate 會檢查各語言的條目數量對得起來。** 中文寫了兩則、英文只寫一則，那些讀者
拿到的就是一份少一條的清單，而且不會有任何徵兆。

### 寫什麼

**一行講完一件使用者感覺得到的事。**

```
✗ New(zh-Hant): 重構 changelog repository 並加入分頁
✓ New(zh-Hant): 更新日誌改成捲到底再載入下一頁，開啟快很多
```

- 寫**結果**，不是實作。`ETag`、`domain 契約`、`分層 gate` 都是 diff 的事
- 不用寫「為什麼」——那是給審查者的，寫在程式碼註解裡
- 一則 commit 可以有多行，也可以跨分類；但**超過三行就回去看**
  [一個 commit 一件事](#一個-commit-一件事)

### 沒有條目的 commit

`docs` `test` `build` `ci` `style` `chore` `refactor` 通常不寫任何一行，就不會
出現在更新日誌裡。`feat` / `fix` / `perf` **至少要有一行**，gate 會擋。

---

## 平台

只影響單一平台的變更加一行 trailer，放在說明**之前**：

```
fix(notify): stop the crash when Android 14 starts the service

Platform: android

Android 14 requires a foregroundServiceType on every start…
```

- 只接受 `android` 或 `ios`（gate 會擋拼錯的——拼錯只會讓圖示無聲消失）
- **兩個平台都影響就不要加**
- 更新日誌會在該項前面放對應的平台圖示

---

## 一個 commit 一件事

**這條 gate 驗不了**——沒有辦法判斷兩個改動算不算「同一件事」。把它做成猜測式
的檢查會擋掉正當的跨模組修改，然後大家開始想辦法繞過它，那比沒有檢查更糟。
它靠 review，所以寫在這裡。

### 為什麼

- 更新日誌**一則 commit 一個項目**。兩件事塞在一起，使用者會看到一個「A 和 B」
  的條目，而它在三個分類裡只能選一個
- revert 一件事不會連帶 revert 另一件
- `git bisect` 才指得出是哪一個改動

### 徵兆

看到這些就停下來想一下：

| 徵兆 | 例子 |
|---|---|
| 摘要裡有 **and** | `show one language and draw the tags locally` |
| 摘要在**列舉** | `cut releases from tags, notes from commits, symbols from both` |
| 說明分成**互不相關的兩段** | 第一段講語言、第二段講圖示 |
| 一個檔案是**文件**、另一個是**程式** | `AGENTS.md` + `tool/check/commits.sh` |
| 需要**兩個 type** 才講得清楚 | 一半是 `fix` 一半是 `feat` |

這五個都不是硬性錯誤——`fix: stop A and B from racing` 是合法的，兩者是同一個
競態。但它們值得停一下。

### 怎麼拆

```sh
git reset --mixed HEAD~1     # 保留變更，取消 commit
git add <第一組檔案>
git commit
git add <第二組檔案>
git commit
```

同一個檔案裡有兩件事的話，先寫出中間狀態、commit、再寫回最終狀態、再 commit。

---

## 禁止（gate 會擋）

- **`Co-Authored-By:`** 任何形式
- **任何工具署名**：`Generated with`、🤖、agent 名稱、模型名稱

commit 的作者是人。工具把自己寫進紀錄，等於讓歷史對「誰為這個改動負責」說謊
——而那份紀錄正是幾年後有人要問「當初為什麼這樣做」時會去讀的東西。

---

## 範例

### 只影響 Android 的修正

```
fix(notify): stop the crash when Android 14 starts the service

Platform: android

Fix(zh-Hant): 修正 Android 14 上升級後第一則地震速報會讓 app 閃退
Fix(en-US): fix the app crashing on the first earthquake alert after an
  upgrade on Android 14
```

### 一則 commit，兩個條目

```
perf(changelog): fetch one page at a time

Optimization(zh-Hant): 更新日誌改成捲到底再載入下一頁，開啟快很多
Optimization(en-US): the changelog loads a page at a time and opens faster
Fix(zh-Hant): 修正某一頁載入失敗會清空整個清單
Fix(en-US): a failed page no longer clears the list already on screen
```

### 多一個語言

有人寫了就有，沒寫就退回英文。

```
fix(changelog): show one language instead of both

Fix(zh-Hant): 更新日誌不再中英文一起顯示
Fix(en-US): the changelog no longer shows both languages at once
Fix(ja-JP): 更新履歴が日本語と英語を同時に表示しなくなりました
```

### 不進更新日誌的

```
chore(deps): bump the pubspec lockfile
ci: cache the Swift package resolution
```

### 錯的長什麼樣

```
✗ New(zh-Hant): 重構 changelog repository，改用 cursor 分頁，並把 pageSize
    移到 domain 契約（分層 gate 說 presentation 不能伸進 data）
```

實作細節、檔名、分層規則——**全部在 diff 裡**，而更新日誌的讀者一項都用不到。

---

## 更新日誌怎麼組成

三個區塊由條目的 `Category` 決定，**不是**由 commit 的 `<type>` 推導——所以訊息
裡寫的分類和日誌上的分類不可能對不起來。

**繁體中文直接展開；其他每個語言各自摺在 `<details>` 裡**，並用
`<!-- dpip-lang:xx -->` 標記包起來。app 內只會顯示讀者語系的那一份：找不到完全
相符就找同語言、再找不到就退回英文（`<details>` 是 HTML，app 的 Markdown 渲染器
不支援，不處理的話十種語言會全部攤在同一頁）。

每一項後面標上**真正寫它的人**，以及該則 commit 的連結。

歸屬不是取 commit 的 author：GitHub squash 一個 PR 時會把作者設成按下合併的人。
`41a3c1e8 Fix eew (#534)` 的作者是合併者，而它的每一行都是別人寫的。所以摘要帶
`(#N)` 時，作者取自**那個 PR 自己的 commits**，再併入 `Co-authored-by:` trailer；
都沒有才退回 commit 的 author。是 GitHub 帳號，不是 git 顯示名稱 —— 顯示名稱 @
不到任何人。

| | 涵蓋範圍 | 為什麼 |
|---|---|---|
| **快照** `26w33a` | 上一個 tag 到現在 | 讀的人已經有前一個了，只需要增量 |
| **正式版** `26.1` | **上一個正式版**到現在 | 從 `26.1` 升到 `26.2` 的人一個快照都沒看過，只給增量等於只告訴他一小部分 |

**每一則條目都會標上平台圖示**——只影響一個平台就標一個，兩個都影響就兩個都標。
只標單平台的話，其餘每一行都變成「兩個平台都有」和「沒有人說」分不出來，而那是
兩件不同的事。

正式版會累積期間所有快照的內容，**每一則行尾標上它第一次出現在哪個測試版**：

```
- ⬢ ⬡ 更新日誌改成捲到底再載入下一頁 — @whes1015 · `26w33b`
- ⬡ 修正 iOS 上拖曳雷達時間軸會跟不上手指 — @whes1015
```

跑測試版的人用它對照自己已經有什麼；**沒有標記的就是這一版才第一次出現**，誰都
還沒看過。快照本身的條目全部來自它自己，所以不標。

署名是 GitHub 帳號，CI 透過 API 解析。**不是 git 的顯示名稱**——顯示名稱 @ 不到
任何人，而且用名字去搜會搜出不只一個帳號，猜錯比不標更糟。

實際長相就是上面各節的範例，`tool/release/notes.sh` 直接照這個格式輸出。

> **squash 會壓縮條目數。** 正則是逐行抓的，所以 squash 不會像舊格式那樣把內容
> 弄壞——但四則 commit 的條目會全部掛在同一個作者和同一個快照下。要保留就用
> rebase-merge。

---

## 合併前必須 rebase

CI 會擋兩件事（`ci.yml` 的「Branch is rebased on the base」）：

| 擋什麼 | 為什麼 |
|---|---|
| 分支裡有 **merge commit** | `check_commits.sh` 用 `--no-merges` 走訪——merge 訊息是產生的不是寫的——所以**任何從 merge 進來的東西都不會被檢查**。用 merge 就等於繞過整個 gate |
| 分支**落後** base | 它是對著一個已經不存在的 main 測過的；通過的那些 gate 描述的是一棵沒有人會拿到的樹 |

```sh
git fetch origin
git rebase origin/main
git push --force-with-lease
```

**PR 裡任何一則不合格，整個 CI 就失敗。** gate 走的是分支自己的頂端
（`github.event.pull_request.head.sha`）而不是 checkout 出來的合併節點——
pull request 會建一個分支併入 base 的合成 merge，而這個 gate 判的每一則都必須
是有人真的寫過的。

---

## 不合格怎麼辦

CI 會印出哪一則、哪裡不對。因為訊息無法事後修改：

```sh
git rebase -i <base>        # 把有問題的標成 reword
git push --force-with-lease
```

用 `--force-with-lease` 而不是 `--force`：期間有人推過東西它會拒絕，而那正是
`--force` 會無聲摧毀別人工作的情況。

推之前先在本機驗：

```sh
tool/check/commits.sh origin/main..HEAD
```
