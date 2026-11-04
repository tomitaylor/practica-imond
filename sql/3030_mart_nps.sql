CREATE VIEW nps_diario AS
SELECT n.date_key, c.code AS canal,
       COUNT(*) AS respuestas,
       COUNT(*) FILTER (WHERE n.nps_value = 1) AS promotores,
       COUNT(*) FILTER (WHERE n.nps_value = -1) AS detractores
FROM fact_nps AS n
JOIN dim_channel AS c ON c.channel_key = n.channel_key
GROUP BY n.date_key, c.code;

CREATE VIEW reporte_nps AS
WITH agregados AS (
    SELECT p.desde, p.hasta, c.canal,
           COALESCE(SUM(n.respuestas), 0)::BIGINT AS respuestas,
           COALESCE(SUM(n.promotores), 0)::BIGINT AS promotores,
           COALESCE(SUM(n.detractores), 0)::BIGINT AS detractores
    FROM reporte_periodos AS p
    CROSS JOIN reporte_canales AS c
    LEFT JOIN dim_date AS d ON d.full_date BETWEEN p.fecha_desde AND p.fecha_hasta
    LEFT JOIN nps_diario AS n ON n.date_key = d.date_key
        AND (c.canal = '' OR n.canal = c.canal)
    GROUP BY p.desde, p.hasta, c.canal
)
SELECT *, ROUND((promotores - detractores) * 100.0 / NULLIF(respuestas, 0), 2) AS nps
FROM agregados
ORDER BY desde, hasta, canal;

CREATE TABLE mart_nps AS
SELECT * FROM reporte_nps;
