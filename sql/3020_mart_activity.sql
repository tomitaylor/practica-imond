CREATE VIEW reporte_activity AS
SELECT p.desde, p.hasta,
       COUNT(DISTINCT w.visitor_key) AS usuarios_activos,
       COUNT(DISTINCT CASE WHEN w.customer_key <> -1 THEN w.visitor_key END)
           AS usuarios_identificados,
       COUNT(CASE WHEN w.customer_key = -1 THEN w.session_id END)
           AS sesiones_anonimas,
       COUNT(DISTINCT w.visitor_key) / 1000.0 AS usuarios_miles
FROM reporte_periodos AS p
LEFT JOIN dim_date AS d ON d.full_date BETWEEN p.fecha_desde AND p.fecha_hasta
LEFT JOIN fact_web_session AS w ON w.date_key = d.date_key
GROUP BY p.desde, p.hasta
ORDER BY p.desde, p.hasta;

CREATE TABLE mart_activity AS
SELECT * FROM reporte_activity;
