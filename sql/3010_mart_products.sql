CREATE TABLE mart_products AS
WITH productos AS (
    SELECT STRFTIME(d.full_date, '%Y-%m') AS mes,
           c.code AS canal, COALESCE(pr.name, 'Sin provincia') AS provincia,
           CAST(p.product_id AS VARCHAR) AS product_id, p.name AS producto,
           i.quantity, i.line_total
    FROM fact_order_item AS i
    JOIN dim_date AS d ON d.date_key = i.date_key
    JOIN dim_channel AS c ON c.channel_key = i.channel_key
    LEFT JOIN dim_province AS pr ON pr.province_key = i.province_key
    JOIN dim_product AS p ON p.product_key = i.product_key
    WHERE i.status IN ('PAID', 'FULFILLED')
), agregados AS (
    SELECT mes, COALESCE(canal, '') AS canal,
           COALESCE(provincia, '') AS provincia, product_id, producto,
           SUM(quantity) AS unidades, SUM(line_total) AS ventas_producto
    FROM productos
    GROUP BY mes, product_id, producto,
             GROUPING SETS ((), (canal), (provincia), (canal, provincia))
)
SELECT *, DENSE_RANK() OVER (
    PARTITION BY mes, canal, provincia ORDER BY ventas_producto DESC
) AS posicion
FROM agregados
ORDER BY mes, canal, provincia, posicion, producto;
