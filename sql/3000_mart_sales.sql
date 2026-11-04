CREATE VIEW ventas_diarias AS
    SELECT d.full_date AS fecha, c.code AS canal,
           COALESCE(p.name, 'Sin provincia') AS provincia,
           COUNT(*) AS pedidos, SUM(o.subtotal) AS subtotal, SUM(o.total_amount) AS total_amount
    FROM fact_order AS o
    JOIN dim_date AS d ON d.date_key = o.date_key
    JOIN dim_channel AS c ON c.channel_key = o.channel_key
    LEFT JOIN dim_province AS p ON p.province_key = o.province_key
    WHERE o.order_status_key IN (SELECT order_status_key FROM dim_order_status WHERE status IN ('PAID', 'FULFILLED'))
    GROUP BY fecha, canal, provincia;

CREATE VIEW reporte_sales AS
WITH agregados AS (
    SELECT p.desde, p.hasta,
           COALESCE(v.canal, '') AS canal,
           COALESCE(v.provincia, '') AS provincia,
           SUM(v.pedidos)::BIGINT AS pedidos_validos,
           SUM(v.total_amount) AS ventas_totales,
           SUM(v.subtotal) AS subtotal
    FROM reporte_periodos AS p
    JOIN ventas_diarias AS v ON v.fecha BETWEEN p.fecha_desde AND p.fecha_hasta
    GROUP BY p.desde, p.hasta,
             GROUPING SETS ((), (v.canal), (v.provincia), (v.canal, v.provincia))
), completos AS (
    SELECT p.desde, p.hasta, c.canal, pr.provincia,
           COALESCE(a.pedidos_validos, 0) AS pedidos_validos,
           COALESCE(a.ventas_totales, 0) AS ventas_totales,
           COALESCE(a.subtotal, 0) AS subtotal
    FROM reporte_periodos AS p
    CROSS JOIN reporte_canales AS c
    CROSS JOIN reporte_provincias AS pr
    LEFT JOIN agregados AS a USING (desde, hasta, canal, provincia)
)
SELECT *, ventas_totales / 1000000.0 AS ventas_millones,
       ROUND(ventas_totales / NULLIF(pedidos_validos, 0), 2) AS ticket_promedio,
       ventas_totales / NULLIF(pedidos_validos, 0) / 1000.0 AS ticket_miles,
       CASE WHEN provincia <> '' THEN
           COALESCE(ventas_totales * 100.0 / NULLIF(
               MAX(CASE WHEN provincia <> '' THEN ventas_totales END)
                   OVER (PARTITION BY desde, hasta, canal), 0), 0)
       END AS ancho_barra
FROM completos
ORDER BY desde, hasta, canal, ventas_totales DESC, provincia;

CREATE TABLE mart_sales AS
SELECT * FROM reporte_sales;
