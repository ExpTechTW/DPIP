# ExpTech 地震報告來源樣本

兩份檔案是 2026-11-22 從 ExpTech Core v2 取得的原始 HTTP 本文，保留數字寫法及 UTF-8 原始位元組。
資料來源為中央氣象署、ExpTech Studio。 [ExpTech 地震報告 API](https://exptech.dev/docs/api/earthquake/report/)

| 檔案 | 報告 | 原始本文 SHA-256 |
| --- | --- | --- |
| exptech-modern.json | [115000-2026-0422-111524 臺東縣近海](https://api.core-tnn1.exptech.dev/api/v2/eq/report/115000-2026-0422-111524) | e6761038a7eea6b8afa58c936693f35d663bd5ca1ecdb2ad4613b72e2d46e4c1 |
| exptech-historical.json | [105006-2016-0206-035726 美濃](https://api.core-tnn1.exptech.dev/api/v2/eq/report/105006-2016-0206-035726) | 45846febd73dde3e0d2bb29f456093cdb27663dee9b0217a6655c9eaf59a4971 |

臺東樣本的規模為 ML 3.9，詳情中的縣市最大震度為臺東 2、花蓮 1。Core v2 只提供縣市與
測站名稱及測站座標。此快照另有臺東縣 10014、花蓮縣 10015 的行政區對照，及成功 CHK、
長濱 ECB、池上 ECS、東河 EDH、紅葉 EHY 的氣象署測站對照。這些對照僅適用於已查核的快照。
[等值快照與測站查核紀錄](https://github.com/ExpTechTW/eq-report-pic/blob/b135d02bd1ba5103cd3d116a951b1b63a710a312/testdata/report-adapters/README.md)
[氣象署公開報告](https://scweb.cwa.gov.tw/zh-tw/earthquake/details/2026042211152439)
[內政部縣市代碼](https://data.gov.tw/dataset/17341)

美濃樣本保留 Core v2 的震度序碼 9，氣象署原報告使用舊制 7 級。歷史轉換過程及此快照的
縣市與測站代碼對照仍待查核。
[氣象署美濃原報告](https://scweb.cwa.gov.tw/zh-tw/earthquake/details/2016020603572666006)

在專案根目錄重放來源樣本。測試用本機 HTTP 替身，通過正式的區域選擇、ETag 快取及 repository。

`tool/dev/test.sh test/features/earthquake/data/earthquake_report_source_test.dart`
