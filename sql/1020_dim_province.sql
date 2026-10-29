CREATE TABLE dim_province (
    province_key INTEGER PRIMARY KEY,
    province_id INTEGER NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(10) UNIQUE
);

INSERT INTO dim_province
SELECT
    ROW_NUMBER() OVER (ORDER BY province_id) AS province_key,
    province_id,
    name,
    code
FROM raw.province;