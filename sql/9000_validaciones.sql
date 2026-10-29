
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