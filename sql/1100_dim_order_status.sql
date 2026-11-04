CREATE TABLE dim_order_status (
    order_status_key INTEGER PRIMARY KEY,
    status VARCHAR(20) UNIQUE
);

INSERT INTO dim_order_status VALUES (-1, NULL);

INSERT INTO dim_order_status
SELECT ROW_NUMBER() OVER (ORDER BY status), status
FROM (
    SELECT DISTINCT status
    FROM raw.sales_order
    WHERE status IS NOT NULL
) AS valores;
