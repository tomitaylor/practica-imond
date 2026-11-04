CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    day INTEGER,
    day_of_week INTEGER
);

INSERT INTO dim_date
SELECT
    CAST(strftime(fecha, '%Y%m%d') AS INTEGER),
    CAST(fecha AS DATE),
    year(fecha),
    quarter(fecha),
    month(fecha),
    day(fecha),
    isodow(fecha)
FROM range(
    DATE '2024-01-01',
    DATE '2026-01-01',
    INTERVAL 1 DAY
) AS calendario(fecha);

INSERT INTO dim_date VALUES (-1, NULL, NULL, NULL, NULL, NULL, NULL);
