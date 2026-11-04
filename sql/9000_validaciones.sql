
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
    (SELECT SUM(total_amount) FROM fact_order JOIN dim_order_status USING (order_status_key)
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

WITH lineas_por_pedido AS (
    SELECT order_id, SUM(line_total) AS suma_lineas
    FROM fact_order_item
    GROUP BY order_id
)
SELECT
    'subtotal_distinto_de_lineas' AS control,
    COUNT(*) AS inconsistencias
FROM fact_order AS o
JOIN lineas_por_pedido AS i ON i.order_id = o.order_id
WHERE o.subtotal <> i.suma_lineas
UNION ALL
SELECT
    'total_distinto_de_subtotal_iva_envio',
    COUNT(*)
FROM fact_order
WHERE total_amount <> subtotal + tax_amount + shipping_fee
UNION ALL
SELECT
    'pedidos_sin_lineas',
    COUNT(*)
FROM fact_order AS o
WHERE NOT EXISTS (
    SELECT 1 FROM fact_order_item AS i WHERE i.order_id = o.order_id
)
UNION ALL
SELECT
    'claves_duplicadas_mart_sales',
    COUNT(*)
FROM (
    SELECT desde, hasta, canal, provincia
    FROM mart_sales
    GROUP BY desde, hasta, canal, provincia
    HAVING COUNT(*) > 1
) AS duplicados_sales
UNION ALL
SELECT
    'claves_duplicadas_mart_activity',
    COUNT(*)
FROM (
    SELECT desde, hasta
    FROM mart_activity
    GROUP BY desde, hasta
    HAVING COUNT(*) > 1
) AS duplicados_activity
UNION ALL
SELECT
    'claves_duplicadas_mart_nps',
    COUNT(*)
FROM (
    SELECT desde, hasta, canal
    FROM mart_nps
    GROUP BY desde, hasta, canal
    HAVING COUNT(*) > 1
) AS duplicados_nps
UNION ALL
SELECT
    'claves_duplicadas_mart_products',
    COUNT(*)
FROM (
    SELECT mes, canal, provincia, product_id
    FROM mart_products
    GROUP BY mes, canal, provincia, product_id
    HAVING COUNT(*) > 1
) AS duplicados_products
UNION ALL
SELECT
    'claves_duplicadas_mart_periods',
    COUNT(*)
FROM (
    SELECT desde, hasta
    FROM mart_periods
    GROUP BY desde, hasta
    HAVING COUNT(*) > 1
) AS duplicados_periods
UNION ALL
SELECT
    'claves_duplicadas_mart_filters',
    COUNT(*)
FROM (
    SELECT tipo, valor
    FROM mart_filters
    GROUP BY tipo, valor
    HAVING COUNT(*) > 1
) AS duplicados_filters
UNION ALL
SELECT
    'claves_duplicadas_mart_charts',
    COUNT(*)
FROM (
    SELECT desde, hasta, canal, provincia, grafico
    FROM mart_charts
    GROUP BY desde, hasta, canal, provincia, grafico
    HAVING COUNT(*) > 1
) AS duplicados_charts
ORDER BY control;
