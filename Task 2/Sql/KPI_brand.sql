SELECT
    Brand,
    COUNT(*)                                                AS total_campaigns,
    SUM(Revenue)                                            AS total_revenue,
    SUM(Acquisition_Cost * Conversions)                     AS total_spend,
    SUM(Conversions)                                        AS total_conversions,

    -- KPI tổng hợp (weighted average)
    ROUND(SUM(Clicks) / SUM(Impressions), 4)                AS overall_CTR,
    ROUND(SUM(Leads) / SUM(Clicks), 4)                      AS overall_Lead_Rate,
    ROUND(SUM(Conversions) / SUM(Leads), 4)                 AS overall_Conv_Rate,
    ROUND(SUM(Acquisition_Cost * Conversions)
          / SUM(Conversions), 2)                            AS overall_CPA,
    ROUND(
        (SUM(Revenue) - SUM(Acquisition_Cost * Conversions))
        / SUM(Acquisition_Cost * Conversions),
        4
    )                                                       AS overall_ROI

FROM campaigns
GROUP BY Brand
ORDER BY overall_ROI DESC;