SELECT
    Campaign_Type,
    COUNT(*)                                               AS total_campaigns,
    ROUND(SUM(Clicks) / SUM(Impressions), 4)               AS overall_CTR,
    ROUND(SUM(Conversions) / SUM(Leads), 4)                AS overall_Conv_Rate,
    ROUND(SUM(Acquisition_Cost * Conversions)
          / SUM(Conversions), 2)                           AS overall_CPA,
    ROUND(
        (SUM(Revenue) - SUM(Acquisition_Cost * Conversions))
        / SUM(Acquisition_Cost * Conversions),
        4
    )                                                      AS overall_ROI

FROM campaigns
GROUP BY Campaign_Type
ORDER BY overall_ROI DESC;