CREATE TABLE dim_store (
    store_key INTEGER PRIMARY KEY,
    store_id INTEGER UNIQUE,
    name VARCHAR(80) NOT NULL,
    city VARCHAR(80),
    province VARCHAR(50),
    postal_code VARCHAR(20),
    country_code CHAR(2)
);

INSERT INTO dim_store
VALUES (
    -1, NULL, 'No aplica', NULL, NULL, NULL, NULL
);

INSERT INTO dim_store
SELECT
    ROW_NUMBER() OVER (ORDER BY s.store_id),
    s.store_id,
    s.name,
    a.city,
    p.name,
    a.postal_code,
    a.country_code
FROM raw.store AS s
JOIN raw.address AS a ON a.address_id = s.address_id
JOIN raw.province AS p ON p.province_id = a.province_id;
