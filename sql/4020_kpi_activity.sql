SELECT
    CAST(DATE_TRUNC('month', d.full_date) AS DATE) AS mes,
    COUNT(DISTINCT w.visitor_key) AS usuarios_activos
FROM fact_web_session AS w
JOIN dim_date AS d ON d.date_key = w.date_key
GROUP BY mes
ORDER BY mes;
