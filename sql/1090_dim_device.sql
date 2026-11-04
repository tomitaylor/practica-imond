CREATE TABLE dim_device (
    device_key INTEGER PRIMARY KEY,
    device VARCHAR(30) UNIQUE
);

INSERT INTO dim_device VALUES (-1, NULL);

INSERT INTO dim_device
SELECT ROW_NUMBER() OVER (ORDER BY device), device
FROM (
    SELECT DISTINCT device
    FROM raw.web_session
    WHERE device IS NOT NULL
) AS valores;
