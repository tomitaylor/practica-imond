CREATE TABLE mart_nps AS
WITH encuestas AS (
    SELECT n.nps_id, n.date_key, n.nps_value, c.code AS canal
    FROM fact_nps AS n
    JOIN dim_channel AS c ON c.channel_key = n.channel_key
), agregados AS (
    SELECT p.desde, p.hasta, c.canal,
           COUNT(n.nps_id) AS respuestas,
           COUNT(CASE WHEN n.nps_value = 1 THEN n.nps_id END) AS promotores,
           COUNT(CASE WHEN n.nps_value = -1 THEN n.nps_id END) AS detractores,
           ROUND(AVG(n.nps_value) * 100, 2) AS nps
    FROM mart_periods AS p
    CROSS JOIN reporte_canales AS c
    LEFT JOIN dim_date AS d ON d.full_date BETWEEN p.fecha_desde AND p.fecha_hasta
    LEFT JOIN encuestas AS n ON n.date_key = d.date_key
        AND (c.canal = '' OR n.canal = c.canal)
    GROUP BY p.desde, p.hasta, c.canal
)
SELECT * FROM agregados ORDER BY desde, hasta, canal;
