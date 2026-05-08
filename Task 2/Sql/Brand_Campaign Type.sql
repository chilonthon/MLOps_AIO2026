SELECT
    Brand,
    Campaign_Type,
    COUNT(*)                                               AS campaigns,
    ROUND(SUM(Revenue), 0)                                 AS total_revenue,
    ROUND(
        (SUM(Revenue) - SUM(Acquisition_Cost * Conversions))
        / SUM(Acquisition_Cost * Conversions),
        4
    )                                                      AS ROI

FROM campaigns
GROUP BY Brand, Campaign_Type
ORDER BY Brand, ROI DESC;