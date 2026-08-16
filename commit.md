# Commit 格式

**commit 訊息就是更新日誌。** `tool/release_notes.sh` 直接讀這些訊息去產生
GitHub release 的內容，所以一則寫壞的 commit 會在使用者讀得到的地方留下一個
洞——而 commit 訊息推出去之後**改不了**，唯一的修法是 rebase。

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

### 摘要行

- **英文**，純 ASCII。中文在下面的區塊裡，不在這裡。
- `<type>` 必須是：`feat` `fix` `perf` `refactor` `docs` `test` `chore`
  `build` `ci` `style` `revert`
- `<scope>` 選填，小寫，例如 `mesh` `map` `weather` `eew`
- 最多 **72 字元**，結尾**不加句號**
- 祈使句：`add`、`fix`、`stop`，不是 `added`、`fixes`

### 說明

`feat` / `fix` / `perf` **必須**有雙語說明——它們是會出現在更新日誌裡的三種。
其他類型可以只有一行摘要：沒有人會為了知道 lockfile 動了而去讀更新日誌。

- `=== 中文 ===` 單獨一行，前後都要有內容
- 中文區塊的**第一行是中文標題**，會成為更新日誌中文區的標題
- 說明「為什麼」，不是「做了什麼」——diff 已經說了做什麼
- **寫完這則 commit 的全部變更**。更新日誌是從這裡生出來的，沒寫的東西使用者
  就看不到；而 commit 訊息推出去之後改不了

### 平台

只影響單一平台的變更加一行 trailer：

```
Platform: android
Platform: ios
```

兩個平台都影響就**不要加**。更新日誌會在該項前面放對應的圖示。

### 一個 commit 一件事

不同的功能**分開提交**。理由不是整潔：

- 更新日誌一則 commit 一個項目。兩個功能塞在一起，使用者就會看到一個
  「A 和 B」的條目，而它在分類上只能二選一
- revert 一個功能不會連帶 revert 另一個
- `git bisect` 才指得出是哪一個改動

這條**機器驗不了**——沒有辦法判斷兩個改動算不算「同一件事」。它靠 review，
所以寫在這裡而不是寫進 gate。

### 禁止（gate 會擋）

- **`Co-Authored-By:`** 任何形式
- **任何工具署名**：`Generated with`、🤖、agent 名稱、模型名稱

commit 的作者是人。工具把自己寫進紀錄，等於讓歷史對「誰為這個改動負責」說謊。

---

## 範例

只影響 Android 的修正：

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

兩個平台都有的新功能：

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

不需要說明的：

```
chore(deps): bump the pubspec lockfile
ci: cache the Swift package resolution
```

---

## 更新日誌怎麼組成

分成三區，由 `<type>` 決定，不用自己選標題：

| type | 區塊 |
|---|---|
| `feat` | 🌟 新功能 |
| `perf` `refactor` | 🔌 最佳化 |
| `fix` | 🐞 錯誤修正 |

每一項後面都會標上提交者（CI 解析成 GitHub `@帳號`）。



| | 涵蓋範圍 | 為什麼 |
|---|---|---|
| **快照** `26w33a` | 上一個 tag 到現在 | 讀的人已經有前一個了，只需要增量 |
| **正式版** `26.1` | **上一個正式版**到現在 | 從 `26.1` 升到 `26.2` 的人一個快照都沒看過，只給增量等於只告訴他一小部分 |

所以**正式版會自動累積期間所有快照的內容**，你不需要手動整理。

只有 `feat` / `fix` / `perf` 會進更新日誌。一個沒有改變任何可觀察行為的
`refactor` 是真實的工作，該進 git log，但不該進一份「我要不要更新」的說明。

---

## 不合格怎麼辦

CI 會失敗並印出哪一則、哪裡不對。因為訊息無法事後修改：

```sh
git rebase -i <base>        # 把有問題的標成 reword
git push --force-with-lease
```

用 `--force-with-lease` 而不是 `--force`：如果期間有人推過東西它會拒絕，而那
正是 `--force` 會無聲摧毀別人工作的情況。

本地先驗：

```sh
tool/check_commits.sh origin/main..HEAD
```
