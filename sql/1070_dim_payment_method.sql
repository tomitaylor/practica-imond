CREATE TABLE dim_payment_method (
    payment_method_key INTEGER PRIMARY KEY,
    method VARCHAR(20) UNIQUE
);

INSERT INTO dim_payment_method VALUES (-1, NULL);

INSERT INTO dim_payment_method
SELECT ROW_NUMBER() OVER (ORDER BY method), method
FROM (
    SELECT DISTINCT method
    FROM raw.payment
    WHERE method IS NOT NULL
) AS valores;
