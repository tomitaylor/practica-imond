
CREATE TABLE dim_address (
    address_key INTEGER PRIMARY KEY,
    address_id INTEGER UNIQUE,
    line1 VARCHAR(120),
    line2 VARCHAR(120),
    city VARCHAR(80),
    province_id INTEGER,
    province_name VARCHAR(50),
    province_code VARCHAR(10),
    postal_code VARCHAR(20),
    country_code CHAR(2),
    created_at TIMESTAMP
);

INSERT INTO dim_address
VALUES (
    -1, NULL, NULL, NULL, 'Desconocido',
    NULL, NULL, NULL, NULL, NULL, NULL
);

INSERT INTO dim_address
SELECT
    ROW_NUMBER() OVER (ORDER BY a.address_id),
    a.address_id,
    a.line1,
    a.line2,
    a.city,
    a.province_id,
    p.name,
    p.code,
    a.postal_code,
    a.country_code,
    a.created_at
FROM raw.address AS a
LEFT JOIN raw.province AS p ON p.province_id = a.province_id;