-- ============================================================
-- 06_descriptive_stats.sql
-- Thống kê mô tả (sau cleaning)
-- Ref: reading.tex - Section VII.5
-- ============================================================

USE marketing_analytics;

SELECT
  Brand,
  COUNT(*)                     AS total_campaigns,
  ROUND(AVG(Duration), 1)      AS avg_duration,
  ROUND(AVG(Impressions), 0)   AS avg_impressions,
  ROUND(AVG(Clicks), 0)        AS avg_clicks,
  ROUND(AVG(Conversions), 0)   AS avg_conversions,
  ROUND(SUM(Revenue), 0)       AS total_revenue,
  ROUND(AVG(ROI), 2)           AS avg_roi
FROM campaigns
GROUP BY Brand;
