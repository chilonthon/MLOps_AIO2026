SELECT
    Campaign_ID,
    Brand,
    Campaign_Type,
    Target_Audience,
    Channel_Used,
    Duration,
    Language,
    Customer_Segment,
    Campaign_Date,

    -- Funnel metrics
    Impressions,
    Clicks,
    Leads,
    Conversions,
    Revenue,

    -- Chi phí
    Acquisition_Cost                                              AS CPA,
    ROUND(Acquisition_Cost * Conversions, 2)                     AS Total_Spend,
    ROUND(Revenue - Acquisition_Cost * Conversions, 2)           AS Profit,

    -- KPIs
    ROUND(Clicks / NULLIF(Impressions, 0), 4)                    AS CTR,
    ROUND(Leads / NULLIF(Clicks, 0), 4)                          AS Lead_Rate,
    ROUND(Conversions / NULLIF(Leads, 0), 4)                     AS Conversion_Rate,
    ROI,
    Engagement_Score,

    -- Phân loại hiệu quả
    CASE
        WHEN ROI > 5 THEN 'Excellent'
        WHEN ROI > 2 THEN 'Good'
        WHEN ROI > 0 THEN 'Moderate'
        ELSE 'Poor'
    END AS ROI_Category

FROM campaigns
ORDER BY Brand, ROI DESC;