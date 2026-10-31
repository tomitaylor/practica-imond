CREATE TABLE mart_sales AS
SELECT
    o.order_id,
    d.full_date AS fecha,
    c.code AS canal,
    COALESCE(p.name, 'Sin provincia') AS provincia,
    o.subtotal,
    o.tax_amount,
    o.shipping_fee,
    o.total_amount
FROM fact_order AS o
JOIN dim_date AS d ON d.date_key = o.date_key
JOIN dim_channel AS c ON c.channel_key = o.channel_key
LEFT JOIN dim_province AS p ON p.province_key = o.province_key
WHERE o.status IN ('PAID', 'FULFILLED');