SELECT
    COUNT(*) AS pedidos_validos,
    SUM(total_amount) AS ventas_totales,
    ROUND(SUM(total_amount) / NULLIF(COUNT(*), 0), 2) AS ticket_promedio
FROM fact_order
WHERE status IN ('PAID', 'FULFILLED');

SELECT
    CAST(DATE_TRUNC('month', d.full_date) AS DATE) AS mes,
    c.code AS canal,
    COUNT(*) AS pedidos_validos,
    SUM(o.total_amount) AS ventas_totales,
    ROUND(
        SUM(o.total_amount) / NULLIF(COUNT(*), 0),
        2
    ) AS ticket_promedio
FROM fact_order AS o
JOIN dim_date AS d ON d.date_key = o.date_key
JOIN dim_channel AS c ON c.channel_key = o.channel_key
WHERE o.status IN ('PAID', 'FULFILLED')
GROUP BY mes, c.code
ORDER BY mes, canal;

SELECT
    COALESCE(p.name, 'Sin provincia') AS provincia,
    COUNT(*) AS pedidos_validos,
    SUM(o.total_amount) AS ventas_totales
FROM fact_order AS o
LEFT JOIN dim_province AS p
    ON p.province_key = o.province_key
WHERE o.status IN ('PAID', 'FULFILLED')
GROUP BY p.name
ORDER BY ventas_totales DESC;
