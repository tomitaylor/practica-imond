CREATE TABLE mart_products AS
SELECT
    i.order_item_id,
    i.order_id,
    d.full_date AS fecha,
    c.code AS canal,
    COALESCE(pr.name, 'Sin provincia') AS provincia,
    p.product_id,
    p.name AS producto,
    p.category AS categoria,
    i.quantity AS unidades,
    i.line_total AS ventas_producto
FROM fact_order_item AS i
JOIN dim_date AS d ON d.date_key = i.date_key
JOIN dim_channel AS c ON c.channel_key = i.channel_key
LEFT JOIN dim_province AS pr ON pr.province_key = i.province_key
JOIN dim_product AS p ON p.product_key = i.product_key
WHERE i.status IN ('PAID', 'FULFILLED');