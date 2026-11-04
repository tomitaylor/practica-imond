CREATE TABLE dim_payment_status (
    payment_status_key INTEGER PRIMARY KEY,
    status VARCHAR(20) UNIQUE
);

INSERT INTO dim_payment_status VALUES (-1, NULL);

INSERT INTO dim_payment_status
SELECT ROW_NUMBER() OVER (ORDER BY status), status
FROM (
    SELECT DISTINCT status
    FROM raw.payment
    WHERE status IS NOT NULL
) AS valores;
