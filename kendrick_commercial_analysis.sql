-- =========================================================================
-- Project: The King's Catalog - Kendrick Lamar Commercial Analysis (2017-2021)
-- Author: Your Name
-- Description: From Big Data ingestion optimization to Relational Database BI View.
-- =========================================================================

-------------------------------------------------------------------------
-- STEP 1: 資料庫初始化與建表 (DDL)
-------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS spotify_charts (
    id SERIAL PRIMARY KEY,
    title TEXT,
    rank INT,
    date DATE,
    artist TEXT,
    url TEXT,
    region TEXT,
    chart VARCHAR(20),
    trend VARCHAR(20),
    streams INT
);

-- 建立外部費率對照表（引用自英國 CMA 官方調查與學術論文）
CREATE TABLE IF NOT EXISTS external_spotify_rates (
    payout_year INT PRIMARY KEY,
    per_stream_rate NUMERIC(7, 6),
    source_citation TEXT
);

-- 建立 YouTube 連結對照表（用於 Looker Studio 互動點歌台）
CREATE TABLE IF NOT EXISTS song_youtube_mapping (
    title TEXT PRIMARY KEY,
    youtube_url TEXT
);

-------------------------------------------------------------------------
-- STEP 2: 大數據優化匯入流程 (Data Ingestion & Lock Troubleshooting)
-------------------------------------------------------------------------

-- [DBA Optimization Tip] 
-- 如果後台發生圖形介面傳輸超時死鎖 (Table Lock)，請在全新視窗執行以下兩行殺掉死鎖：
-- SELECT pid, query FROM pg_stat_activity WHERE query ILIKE '%COPY%';
-- SELECT pg_terminate_backend(YOUR_PID);

-- [Performance Tip] 在執行大檔案 COPY 前，務必先拔除 (DROP) 索引，
-- 避免資料庫陷入「邊倒水邊劃地圖」的極端緩慢狀態。
DROP INDEX IF EXISTS idx_charts_artist_date;
DROP INDEX IF EXISTS idx_charts_title;

-- 執行全速記憶體搬運（3GB 海量資料保證 4 分鐘內速通）
-- 註：執行前請確保 CSV 位於 C 槽根目錄 'C:/charts.csv'
COPY spotify_charts(title, rank, date, artist, url, region, chart, trend, streams)
FROM 'C:/charts.csv' 
DELIMITER ',' 
CSV HEADER;

-- [Post-Indexing] 資料完全匯入後，再行補建索引，此時建立速度最快
CREATE INDEX IF NOT EXISTS idx_charts_artist_date ON spotify_charts (artist, date);
CREATE INDEX IF NOT EXISTS idx_charts_title ON spotify_charts (title);

-------------------------------------------------------------------------
-- STEP 3: 外部參考數據注入 (Data Seeding)
-------------------------------------------------------------------------
INSERT INTO external_spotify_rates (payout_year, per_stream_rate, source_citation) VALUES
(2017, 0.003970, 'CMA UK & Academic Literature Estimates'),
(2018, 0.004370, 'CMA UK & Academic Literature Estimates'),
(2019, 0.004370, 'CMA UK & Academic Literature Estimates'),
(2020, 0.003180, 'UNI ScholarWorks & MPRA Research'),
(2021, 0.003300, 'Spotify Loud & Clear / MPRA Historicals')
ON CONFLICT (payout_year) DO UPDATE SET per_stream_rate = EXCLUDED.per_stream_rate;

INSERT INTO song_youtube_mapping (title, youtube_url) VALUES
('HUMBLE.', 'https://www.youtube.com/watch?v=tvTRZJ-4EyI'),
('DNA.', 'https://www.youtube.com/watch?v=NLZRYQMLDW4'),
('All The Stars (with SZA)', 'https://www.youtube.com/watch?v=JQbjS0_ZfJ0'),
('Money Trees', 'https://www.youtube.com/watch?v=smqhSl0u_gI'),
('LOYALTY. FEAT. RIHANNA.', 'https://www.youtube.com/watch?v=Dlh-dzB2z4Y'),
('LOVE. FEAT. ZACARI.', 'https://www.youtube.com/watch?v=ox7PxVxmB-U'),
('Alright', 'https://www.youtube.com/watch?v=Z-48u_uWMHY')
ON CONFLICT (title) DO NOTHING;

-------------------------------------------------------------------------
-- STEP 4: 建立多表聯結商業清洗檢視表 (Relational View Layer)
-------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_kendrick_commercial_analysis AS
SELECT 
    c.date,
    EXTRACT(YEAR FROM c.date)::INT AS payout_year,
    c.title,
    c.artist,
    c.region,
    c.chart,
    c.rank,
    c.streams,
    (c.streams * r.per_stream_rate) AS estimated_daily_payout_usd,
    COALESCE(
        m.youtube_url, 
        'https://www.youtube.com/results?search_query=Kendrick+Lamar+' || REPLACE(c.title, ' ', '+')
    ) AS youtube_url
FROM spotify_charts c
JOIN external_spotify_rates r ON EXTRACT(YEAR FROM c.date)::INT = r.payout_year
LEFT JOIN song_youtube_mapping m ON c.title = m.title
WHERE c.artist ILIKE '%Kendrick Lamar%'
  AND c.chart = 'top200'
  AND c.streams IS NOT NULL;

-------------------------------------------------------------------------
-- STEP 5: 導出至 Looker Studio BI 儀表板的最終高級聚合查詢
-------------------------------------------------------------------------
SELECT 
    payout_year,
    title,
    region,
    MAX(youtube_url) AS youtube_url,
    COUNT(*) AS total_days_on_chart,
    MIN(rank) AS peak_rank,
    SUM(streams) AS total_streams,
    ROUND(SUM(estimated_daily_payout_usd)::NUMERIC, 2) AS total_estimated_payout_usd
FROM view_kendrick_commercial_analysis
GROUP BY payout_year, title, region
ORDER BY payout_year DESC, total_estimated_payout_usd DESC;
