-- ============================================================
-- 05_cleaning.sql
-- Xử lý dữ liệu (Data Cleaning) - 7 bước
-- Ref: reading.tex - Section VII.4
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- Bước 1: Xử lý whitespace bằng TRIM()
-- ============================================================
UPDATE campaigns SET Campaign_Type   = TRIM(Campaign_Type);
UPDATE campaigns SET Language         = TRIM(Language);
UPDATE campaigns SET Customer_Segment = TRIM(Customer_Segment);
UPDATE campaigns SET Target_Audience  = TRIM(Target_Audience);

-- Verify: phải chỉ còn 5 giá trị
SELECT DISTINCT Campaign_Type FROM campaigns;

-- ============================================================
-- Bước 2: Xóa dòng có giá trị NULL
-- ============================================================
DELETE FROM campaigns
WHERE Impressions IS NULL
   OR Clicks IS NULL
   OR Leads IS NULL
   OR Conversions IS NULL
   OR Revenue IS NULL
   OR Acquisition_Cost IS NULL;

-- ============================================================
-- Bước 3: Xóa duplicate
-- ============================================================

-- Cách 1: DELETE JOIN (giữ dòng có Duration/Revenue nhỏ hơn)
DELETE c1 FROM campaigns c1
INNER JOIN campaigns c2
  ON c1.Campaign_ID = c2.Campaign_ID
WHERE c1.Duration > c2.Duration
   OR (c1.Duration = c2.Duration
       AND c1.Revenue > c2.Revenue);

-- Cách 2 (thay thế): Bảng tạm + INSERT IGNORE
-- CREATE TABLE campaigns_tmp LIKE campaigns;
-- INSERT IGNORE INTO campaigns_tmp
-- SELECT * FROM campaigns;
-- DROP TABLE campaigns;
-- RENAME TABLE campaigns_tmp TO campaigns;

-- Verify: phải trống (0 duplicate)
SELECT Campaign_ID, COUNT(*) AS dup_count
FROM campaigns
GROUP BY Campaign_ID
HAVING COUNT(*) > 1;

-- ============================================================
-- Bước 4: Xóa dòng vi phạm logic funnel
-- ============================================================
DELETE FROM campaigns
WHERE Clicks > Impressions
   OR Leads > Clicks
   OR Conversions > Leads;

-- ============================================================
-- Bước 5: Xóa dòng có giá trị âm
-- ============================================================
DELETE FROM campaigns
WHERE Impressions < 0
   OR Revenue < 0;

-- ============================================================
-- Bước 6: Xử lý ngày không hợp lệ
-- (Chỉ áp dụng nếu Campaign_Date còn là VARCHAR)
-- ============================================================
DELETE FROM campaigns
WHERE Campaign_Date IS NOT NULL
  AND STR_TO_DATE(Campaign_Date, '%d-%m-%Y') IS NULL;

DELETE FROM campaigns
WHERE STR_TO_DATE(Campaign_Date, '%d-%m-%Y') IS NOT NULL
  AND (STR_TO_DATE(Campaign_Date, '%d-%m-%Y') < '2024-01-01'
       OR STR_TO_DATE(Campaign_Date, '%d-%m-%Y') > '2025-12-31');

-- Nếu cột đã là DATE:
-- DELETE FROM campaigns
-- WHERE Campaign_Date < '2024-01-01'
--    OR Campaign_Date > '2025-12-31';

-- ============================================================
-- Bước 7: Verify toàn bộ
-- ============================================================

-- 1. Tổng rows
SELECT COUNT(*) AS total_rows FROM campaigns;

-- 2. NULL check
SELECT
  SUM(CASE WHEN Impressions IS NULL THEN 1 ELSE 0 END)
    AS null_imp,
  SUM(CASE WHEN Revenue IS NULL THEN 1 ELSE 0 END)
    AS null_rev
FROM campaigns;

-- 3. Duplicate check
SELECT COUNT(*) FROM (
  SELECT Campaign_ID FROM campaigns
  GROUP BY Campaign_ID HAVING COUNT(*) > 1) t;

-- 4. Funnel logic check
SELECT SUM(CASE WHEN Clicks > Impressions
  THEN 1 ELSE 0 END) AS errors FROM campaigns;

-- 5. Negative check
SELECT SUM(CASE WHEN Impressions < 0 OR Revenue < 0
  THEN 1 ELSE 0 END) AS negatives FROM campaigns;
