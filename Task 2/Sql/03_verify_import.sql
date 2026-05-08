-- ============================================================
-- 03_verify_import.sql
-- Kiểm tra import thành công
-- Ref: reading.tex - Section VII.2
-- ============================================================

USE marketing_analytics;

-- Đếm tổng số dòng (kỳ vọng = 166,815)
SELECT COUNT(*) AS total_rows FROM campaigns;

-- Đếm theo Brand (kỳ vọng = 55,605 mỗi brand)
SELECT Brand, COUNT(*) AS rows_count
FROM campaigns GROUP BY Brand;
