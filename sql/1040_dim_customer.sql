CREATE TABLE dim_customer (
    customer_key INTEGER PRIMARY KEY,
    customer_id INTEGER UNIQUE,
    email VARCHAR(120),
    first_name VARCHAR(80),
    last_name VARCHAR(80),
    phone VARCHAR(30),
    status CHAR(1) CHECK (status IN ('A', 'I')),
    created_at TIMESTAMP
);

INSERT INTO dim_customer
VALUES (
    -1, NULL, NULL, 'Desconocido', NULL, NULL, NULL, NULL
);

INSERT INTO dim_customer
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id),
    customer_id,
    email,
    first_name,
    last_name,
    phone,
    status,
    created_at
FROM raw.customer;