# Commit 格式

**commit 訊息就是更新日誌。** `tool/release_notes.sh` 直接讀這些訊息產生 GitHub
release 的內容，所以一則寫壞的 commit 會在使用者讀得到的地方留下一個洞——而
commit 訊息推出去之後**改不了**，唯一的修法是 rebase。

`tool/check_commits.sh` 是 CI gate，不合格直接失敗。

---

## 格式

```
<type>(<scope>): <英文摘要>

<英文說明>

=== 中文 ===
<中文標題>
<中文說明>
```

單一平台的變更多一行 trailer（見「平台」）。

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

## 說明

`feat` / `fix` / `perf` **必須**有雙語說明——它們是會出現在更新日誌裡的三種。
其他類型可以只有摘要一行：沒有人會為了知道 lockfile 動了而去讀更新日誌。

- `=== 中文 ===` 單獨一行，前後都要有內容
- 中文區塊的**第一行是中文標題**，會成為更新日誌中文區的標題
- 兩邊講同一件事，不是逐字翻譯——中文讀者不需要看英文句構

### 寫什麼

**寫「為什麼」，不是「做了什麼」。** diff 已經完整說明做了什麼，而它說不出來
的是：原本會發生什麼壞事、為什麼是這個做法、放棄了什麼。

```
✗ 把 versionCode 改成 commit 數
✓ 舊的寫法從版本字串推導 versionCode，等於把名字和排序焊死：名字之後
  不能改樣式，而不是三段整數的名字根本不能存在
```

**把這則 commit 的全部變更寫完。** 更新日誌是從這裡生出來的，沒寫的東西使用者
就看不到；而訊息推出去之後改不了。

**踩過的坑要寫。** 如果某個看起來對的做法其實是錯的，寫下來——不然下一個人（或
下個月的你）會再做一次。

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
| 一個檔案是**文件**、另一個是**程式** | `AGENTS.md` + `tool/check_commits.sh` |
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

Android 14 requires a foregroundServiceType on every start, and the location
service declared none — so the first EEW after an upgrade killed the app
instead of showing the alert.

=== 中文 ===
修正 Android 14 啟動前景服務時崩潰
Android 14 要求每次啟動都要宣告 foregroundServiceType，而定位服務沒有宣告
——所以升級後的第一則地震速報不是顯示警報，而是讓 app 直接崩潰。
```

### 兩個平台都有的新功能

```
feat(mesh): show the radio's own packet counters

The firmware sends LocalStats down the BLE link every ~15 minutes and never
over the air, so reading it costs no airtime at all. Four new charts answer
what no other signal can: how much of what this radio sends is carried for
someone else, and whether it is the only path the mesh has to it.

=== 中文 ===
顯示電台自己的封包計數
韌體每約 15 分鐘把 LocalStats 從 BLE 送下來，完全不佔用空中時間。四張新圖表
回答了其他訊號答不出來的問題：這台電台送出的東西有多少是替別人扛的，以及它
是不是網路唯一的路徑。
```

### 不需要說明的

```
chore(deps): bump the pubspec lockfile
ci: cache the Swift package resolution
```

---

## 更新日誌怎麼組成

分成三區，由 `<type>` 決定，不用自己選標題——這樣訊息裡的 type 和日誌上的分類
不可能對不起來。

**中文在上、直接展開；英文摺疊在 `<details>` 裡。** app 內只會顯示讀者語言的
那一半（`<details>` 是 HTML，app 的 Markdown 渲染器不支援，不處理的話會把整段
英文攤開在中文下面）。

每一項後面標上提交者，CI 會解析成 GitHub `@帳號`。

| | 涵蓋範圍 | 為什麼 |
|---|---|---|
| **快照** `26w33a` | 上一個 tag 到現在 | 讀的人已經有前一個了，只需要增量 |
| **正式版** `26.1` | **上一個正式版**到現在 | 從 `26.1` 升到 `26.2` 的人一個快照都沒看過，只給增量等於只告訴他一小部分 |

**正式版會自動累積期間所有快照的內容**，不需要手動整理。每一項行尾會標上它第一
次出現在哪個快照，底部有 compare 連結和涵蓋的快照清單。

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
tool/check_commits.sh origin/main..HEAD
```
