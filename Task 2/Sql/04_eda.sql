-- ============================================================
-- 04_eda.sql
-- Khám phá dữ liệu (EDA) - 7 bước kiểm tra
-- Ref: reading.tex - Section VII.3
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- 1. Kiểm tra giá trị unique
-- ============================================================
SELECT DISTINCT Campaign_Type FROM campaigns;
SELECT DISTINCT Language FROM campaigns;
SELECT DISTINCT Customer_Segment FROM campaigns;

-- ============================================================
-- 2. Kiểm tra NULL
-- ============================================================
SELECT
  SUM(CASE WHEN Impressions IS NULL THEN 1 ELSE 0 END)
    AS null_impressions,
  SUM(CASE WHEN Clicks IS NULL THEN 1 ELSE 0 END)
    AS null_clicks,
  SUM(CASE WHEN Leads IS NULL THEN 1 ELSE 0 END)
    AS null_leads,
  SUM(CASE WHEN Conversions IS NULL THEN 1 ELSE 0 END)
    AS null_conversions,
  SUM(CASE WHEN Revenue IS NULL THEN 1 ELSE 0 END)
    AS null_revenue,
  SUM(CASE WHEN Acquisition_Cost IS NULL THEN 1 ELSE 0 END)
    AS null_acq_cost
FROM campaigns;

-- ============================================================
-- 3. Kiểm tra duplicate
-- ============================================================
SELECT Campaign_ID, COUNT(*) AS dup_count
FROM campaigns
GROUP BY Campaign_ID
HAVING COUNT(*) > 1
ORDER BY dup_count DESC
LIMIT 10;

-- ============================================================
-- 4. Kiểm tra logic funnel
-- ============================================================
SELECT
  SUM(CASE WHEN Clicks > Impressions THEN 1 ELSE 0 END)
    AS clicks_gt_impressions,
  SUM(CASE WHEN Leads > Clicks THEN 1 ELSE 0 END)
    AS leads_gt_clicks,
  SUM(CASE WHEN Conversions > Leads THEN 1 ELSE 0 END)
    AS conversions_gt_leads
FROM campaigns
WHERE Impressions IS NOT NULL
  AND Clicks IS NOT NULL;

-- ============================================================
-- 5. Kiểm tra giá trị âm
-- ============================================================
SELECT
  SUM(CASE WHEN Impressions < 0 THEN 1 ELSE 0 END)
    AS neg_impressions,
  SUM(CASE WHEN Revenue < 0 THEN 1 ELSE 0 END)
    AS neg_revenue
FROM campaigns;

-- ============================================================
-- 6. Kiểm tra ngày không hợp lệ
-- ============================================================
SELECT Campaign_Date, COUNT(*) AS cnt
FROM campaigns
WHERE Campaign_Date IS NOT NULL
  AND STR_TO_DATE(Campaign_Date, '%d-%m-%Y') IS NULL
GROUP BY Campaign_Date;

-- ============================================================
-- 7. Tổng hợp vấn đề chất lượng dữ liệu
-- (Chạy thủ công, kết quả ghi vào file CSV)
-- ============================================================
