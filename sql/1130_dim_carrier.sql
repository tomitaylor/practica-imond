CREATE TABLE dim_carrier (
    carrier_key INTEGER PRIMARY KEY,
    carrier VARCHAR(40) UNIQUE
);

INSERT INTO dim_carrier VALUES (-1, NULL);

INSERT INTO dim_carrier
SELECT ROW_NUMBER() OVER (ORDER BY carrier), carrier
FROM (
    SELECT DISTINCT carrier
    FROM raw.shipment
    WHERE carrier IS NOT NULL
) AS valores;
