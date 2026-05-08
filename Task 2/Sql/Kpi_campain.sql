USE marketing_analytics;
SELECT
    Campaign_ID,
    Brand,
    Campaign_Type,
    Channel_Used,
    Impressions,
    Clicks,
    Leads,
    Conversions,
    Revenue,
    Acquisition_Cost,

    -- Tự tính KPIs
    ROUND(Clicks / NULLIF(Impressions, 0), 4)                    AS calc_CTR,
    ROUND(Leads / NULLIF(Clicks, 0), 4)                          AS calc_Lead_Rate,
    ROUND(Conversions / NULLIF(Leads, 0), 4)                     AS calc_Conversion_Rate,
    Acquisition_Cost                                              AS calc_CPA,
    ROUND(Acquisition_Cost * Conversions, 2)                     AS calc_Total_Spend,
    ROUND(
        (Revenue - Acquisition_Cost * Conversions)
        / NULLIF(Acquisition_Cost * Conversions, 0),
        4
    )                                                             AS calc_ROI,

    -- ROI có sẵn trong dataset (để so sánh)
    ROI AS original_ROI

FROM campaigns
LIMIT 20;