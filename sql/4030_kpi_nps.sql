SELECT
    CAST(DATE_TRUNC('month', d.full_date) AS DATE) AS mes,
    c.code AS canal,
    COUNT(*) AS respuestas,
    ROUND(AVG(n.nps_value) * 100, 2) AS nps
FROM fact_nps AS n
JOIN dim_date AS d ON d.date_key = n.date_key
JOIN dim_channel AS c ON c.channel_key = n.channel_key
GROUP BY mes, c.code
ORDER BY mes, canal;
