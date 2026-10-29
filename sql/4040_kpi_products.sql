WITH ventas_producto AS (
    SELECT
        CAST(DATE_TRUNC('month', d.full_date) AS DATE) AS mes,
        p.product_key,
        p.name AS producto,
        SUM(i.quantity) AS unidades,
        SUM(i.line_total) AS ventas_producto
    FROM fact_order_item AS i
    JOIN dim_date AS d ON d.date_key = i.date_key
    JOIN dim_product AS p ON p.product_key = i.product_key
    WHERE i.status IN ('PAID', 'FULFILLED')
    GROUP BY mes, p.product_key, p.name
)
SELECT
    mes,
    producto,
    unidades,
    ventas_producto,
    DENSE_RANK() OVER (
        PARTITION BY mes
        ORDER BY ventas_producto DESC
    ) AS posicion
FROM ventas_producto
ORDER BY mes, posicion, producto;