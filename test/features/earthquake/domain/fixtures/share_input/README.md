# 地震報告分享輸入 v2 離線樣本

兩份來源檔都是 2026-11-22 從 ExpTech Core v2 取得的完整 HTTP 本文。解碼後與
eq-report-pic `b135d02bd1ba5103cd3d116a951b1b63a710a312` 的既有封存樣本相符。
測試直接使用本機檔案。

| 檔案 | 來源 | 原始本文 SHA-256 |
| --- | --- | --- |
| `exptech-modern.json` | [2026-04-22 臺東縣近海](https://api.core-tnn1.exptech.dev/api/v2/eq/report/115000-2026-0422-111524) | `e6761038a7eea6b8afa58c936693f35d663bd5ca1ecdb2ad4613b72e2d46e4c1` |
| `exptech-historical.json` | [2016-02-06 美濃](https://api.core-tnn1.exptech.dev/api/v2/eq/report/105006-2016-0206-035726) | `45846febd73dde3e0d2bb29f456093cdb27663dee9b0217a6655c9eaf59a4971` |

現代樣本沿用 eq-report-pic 已核對的完整測站對照。兩個縣市為臺東縣 `10014`、花蓮縣
`10015`。五筆測站為成功 `CHK`、長濱 `ECB`、池上 `ECS`、東河 `EDH`、紅葉 `EHY`。
對照適用於此快照。相關的氣象署附件、同事件公開報告及對照過程見既有來源紀錄。
[eq-report-pic 來源紀錄](https://github.com/ExpTechTW/eq-report-pic/blob/b135d02bd1ba5103cd3d116a951b1b63a710a312/testdata/report-adapters/README.md) ·
[內政部縣市代碼](https://data.gov.tw/dataset/17341) ·
[氣象署公開報告](https://scweb.cwa.gov.tw/zh-tw/earthquake/details/2026042211152439)

`exptech-modern.v2.json` 以既有獨立核對的 ExpTech 報告金樣本為基礎，加上 v2 envelope
與已查證的區域／測站 scoped ID。由 Dart 測試逐位元組比對完整 envelope。Rust
`ShareRenderInputV2::parse` 應產生區域來源的最大震度 2，以及下列 canonical content
SHA-256。

```
6eac3077aae8b992e8c752c2c71a137a5601ad94e52c8d8952e7261b179c9e95
```

美濃樣本保留 Core v2 序碼 9。氣象署原報告的舊制 7 級屬於另一份來源資料。測試覆蓋
未知或舊制量表，以及採 Core v2 量表時仍欠缺適用於歷史快照的區域與測站身分。
其他變體（例如明確 0、清單為空、缺座標證據與縣市最大值衝突）為合成測試。
[ExpTech Core v2 API](https://exptech.dev/docs/api/earthquake/report/) ·
[氣象署美濃原報告](https://scweb.cwa.gov.tw/zh-tw/earthquake/details/2016020603572666006)
