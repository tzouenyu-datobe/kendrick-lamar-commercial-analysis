# kendrick-lamar-commercial-analysis
使用 PostgreSQL 與 Looker Studio 分析 Kendrick Lamar 2017-2021 音樂資產變現與串流經濟學
# The King's Catalog: Kendrick Lamar Commercial Analysis

> **[點此進入 Looker Studio 互動式商業數據簡報與點歌台](https://datastudio.google.com/reporting/37a14c48-7e4e-46ff-894d-56627d61d2f8)**

## 專案商業目標
本專案專注於分析饒舌天王 Kendrick Lamar 在 2017-2021 年間的音樂資產價值。
透過結合 3GB 的 Spotify 每日榜單明細與外部政府、學術機構的版稅費率數據，深入探討以下議題：
1. **天王發片變現力**：一首現象級單曲在發行首年能滾出多少真金白銀？
2. **串流稀釋陷阱**：驗證 Spotify 擴張全球低客單價市場，是否讓單次播放分潤逐年遞減？
3. **長青目錄價值**：在 3-4 年不發片的空窗期，舊歌如何作為高殖利率的「金融資產」穩定變現。

## 技術與資料處理流程 (Data Pipeline)
1. **資料清洗與優化匯入 (PostgreSQL)**：排除死鎖 (Table Lock) 與優化索引順序 (Post-Indexing)，將 3GB 原始明細全速於 4 分鐘內匯入完成。
2. **多表聯結 (Relational View Layer)**：將內部榜單與外部歷史費率表、YouTube 連結表進行 `JOIN` 輕量化聚合。
3. **商業智慧視覺化 (Looker Studio)**：串接中繼 Google Sheets，打造 16:9 互動式點歌簡報。

## 檔案說明
* `kendrick_commercial_analysis.sql`: 包含 DDL、資料匯入故障排除、View 建立及高級聚合查詢的完整腳本。
