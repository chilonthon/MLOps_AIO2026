-- ============================================================
-- 07_kpi_calculations.sql
-- Tính KPI bằng SQL (4 phần)
-- Ref: reading.tex - Section VII.6
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- 1. Tính KPI cho từng campaign
-- ============================================================
SELECT
  Campaign_ID, Brand, Campaign_Type,
  Impressions, Clicks, Leads, Conversions,
  Revenue, Acquisition_Cost,

  -- Tự tính KPIs
  ROUND(Clicks / NULLIF(Impressions, 0), 4)
    AS calc_CTR,
  ROUND(Leads / NULLIF(Clicks, 0), 4)
    AS calc_Lead_Rate,
  ROUND(Conversions / NULLIF(Leads, 0), 4)
    AS calc_Conversion_Rate,
  Acquisition_Cost AS calc_CPA,
  ROUND(Acquisition_Cost * Conversions, 2)
    AS calc_Total_Spend,
  ROUND(
    (Revenue - Acquisition_Cost * Conversions)
    / NULLIF(Acquisition_Cost * Conversions, 0),
    4
  ) AS calc_ROI,

  -- ROI có sẵn trong dataset (để so sánh)
  ROI AS original_ROI
FROM campaigns
LIMIT 20;

-- ============================================================
-- 2. KPI tổng hợp theo Brand (Weighted Average)
-- ============================================================
SELECT
  Brand,
  COUNT(*) AS total_campaigns,
  SUM(Revenue) AS total_revenue,
  SUM(Acquisition_Cost * Conversions) AS total_spend,

  -- KPI tổng hợp (weighted average)
  ROUND(SUM(Clicks) / SUM(Impressions), 4)
    AS overall_CTR,
  ROUND(SUM(Leads) / SUM(Clicks), 4)
    AS overall_Lead_Rate,
  ROUND(SUM(Conversions) / SUM(Leads), 4)
    AS overall_Conv_Rate,
  ROUND(SUM(Acquisition_Cost * Conversions)
        / SUM(Conversions), 2)
    AS overall_CPA,
  ROUND(
    (SUM(Revenue) - SUM(Acquisition_Cost * Conversions))
    / SUM(Acquisition_Cost * Conversions),
    4
  ) AS overall_ROI
FROM campaigns
GROUP BY Brand
ORDER BY overall_ROI DESC;

-- ============================================================
-- 3. KPI theo loại Campaign
-- ============================================================
SELECT
  Campaign_Type,
  COUNT(*) AS total_campaigns,
  ROUND(SUM(Clicks) / SUM(Impressions), 4)
    AS overall_CTR,
  ROUND(SUM(Acquisition_Cost * Conversions)
        / SUM(Conversions), 2)
    AS overall_CPA,
  ROUND(
    (SUM(Revenue) - SUM(Acquisition_Cost * Conversions))
    / SUM(Acquisition_Cost * Conversions),
    4
  ) AS overall_ROI
FROM campaigns
GROUP BY Campaign_Type
ORDER BY overall_ROI DESC;

-- ============================================================
-- 4. Phân tích chéo: Brand × Campaign Type
-- ============================================================
SELECT
  Brand, Campaign_Type,
  COUNT(*) AS campaigns,
  ROUND(SUM(Revenue), 0) AS total_revenue,
  ROUND(
    (SUM(Revenue) - SUM(Acquisition_Cost * Conversions))
    / SUM(Acquisition_Cost * Conversions),
    4
  ) AS ROI
FROM campaigns
GROUP BY Brand, Campaign_Type
ORDER BY Brand, ROI DESC;
