CREATE TABLE dim_shipment_status (
    shipment_status_key INTEGER PRIMARY KEY,
    status VARCHAR(20) UNIQUE
);

INSERT INTO dim_shipment_status VALUES (-1, NULL);

INSERT INTO dim_shipment_status
SELECT ROW_NUMBER() OVER (ORDER BY status), status
FROM (
    SELECT DISTINCT status
    FROM raw.shipment
    WHERE status IS NOT NULL
) AS valores;
