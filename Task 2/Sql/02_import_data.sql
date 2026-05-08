-- ============================================================
-- 02_import_data.sql
-- Import 3 file CSV vào MySQL + gán Brand
-- Ref: reading.tex - Section VII.2
-- ============================================================

USE marketing_analytics;

-- Bật local_infile (chạy 1 lần)
SET GLOBAL local_infile = 1;

-- ============================================================
-- Cách 1: LOAD DATA LOCAL INFILE (khuyến nghị)
-- ============================================================

-- Import Nykaa
LOAD DATA LOCAL INFILE 'duong_dan/nykaa_campaign_data.csv'
INTO TABLE campaigns
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Campaign_ID, Campaign_Type, Target_Audience, Duration,
 Channel_Used, Impressions, Clicks, Leads, Conversions,
 Revenue, Acquisition_Cost, ROI, Language,
 Engagement_Score, Customer_Segment, @date_raw)
SET Campaign_Date = STR_TO_DATE(@date_raw, '%d-%m-%Y');

UPDATE campaigns SET Brand = 'Nykaa'
WHERE Campaign_ID LIKE 'NY-%' AND Brand IS NULL;

-- Import Purplle
LOAD DATA LOCAL INFILE 'duong_dan/purplle_campaign_data.csv'
INTO TABLE campaigns
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Campaign_ID, Campaign_Type, Target_Audience, Duration,
 Channel_Used, Impressions, Clicks, Leads, Conversions,
 Revenue, Acquisition_Cost, ROI, Language,
 Engagement_Score, Customer_Segment, @date_raw)
SET Campaign_Date = STR_TO_DATE(@date_raw, '%d-%m-%Y');

UPDATE campaigns SET Brand = 'Purplle'
WHERE Campaign_ID LIKE 'PU-%' AND Brand IS NULL;

-- Import Tira Beauty
LOAD DATA LOCAL INFILE 'duong_dan/tira_beauty_campaign_data.csv'
INTO TABLE campaigns
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Campaign_ID, Campaign_Type, Target_Audience, Duration,
 Channel_Used, Impressions, Clicks, Leads, Conversions,
 Revenue, Acquisition_Cost, ROI, Language,
 Engagement_Score, Customer_Segment, @date_raw)
SET Campaign_Date = STR_TO_DATE(@date_raw, '%d-%m-%Y');

UPDATE campaigns SET Brand = 'Tira Beauty'
WHERE Campaign_ID LIKE 'TI-%' AND Brand IS NULL;
