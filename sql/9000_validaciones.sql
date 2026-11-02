
SELECT
    'pedidos' AS tabla,
    (SELECT COUNT(*) FROM raw.sales_order) AS filas_raw,
    (SELECT COUNT(*) FROM fact_order) AS filas_dw
UNION ALL
SELECT
    'items',
    (SELECT COUNT(*) FROM raw.sales_order_item),
    (SELECT COUNT(*) FROM fact_order_item)
UNION ALL
SELECT
    'pagos',
    (SELECT COUNT(*) FROM raw.payment),
    (SELECT COUNT(*) FROM fact_payment)
UNION ALL
SELECT
    'envios',
    (SELECT COUNT(*) FROM raw.shipment),
    (SELECT COUNT(*) FROM fact_shipment)
UNION ALL
SELECT
    'sesiones',
    (SELECT COUNT(*) FROM raw.web_session),
    (SELECT COUNT(*) FROM fact_web_session)
UNION ALL
SELECT
    'nps',
    (SELECT COUNT(*) FROM raw.nps_response),
    (SELECT COUNT(*) FROM fact_nps);

SELECT
    s.ventas_totales AS ventas_mart,
    (SELECT SUM(total_amount) FROM fact_order
     WHERE status IN ('PAID', 'FULFILLED')) AS ventas_modelo,
    (SELECT SUM(ventas_producto) FROM mart_products
     WHERE canal = '' AND provincia = '') AS productos_mart,
    s.subtotal AS subtotal_pedidos,
    s.ticket_promedio,
    a.usuarios_activos AS usuarios_mart,
    (SELECT COUNT(DISTINCT visitor_key) FROM fact_web_session) AS usuarios_modelo,
    n.nps AS nps_mart,
    (SELECT ROUND(AVG(nps_value) * 100, 2) FROM fact_nps) AS nps_modelo
FROM mart_sales AS s
JOIN mart_activity AS a USING (desde, hasta)
JOIN mart_nps AS n USING (desde, hasta, canal)
WHERE s.desde = (SELECT MIN(desde) FROM mart_periods)
  AND s.hasta = (SELECT MAX(hasta) FROM mart_periods)
  AND s.canal = '' AND s.provincia = '';
