CREATE VIEW reporte_periodos AS
WITH limites AS (
    SELECT DATE_TRUNC('month', MIN(order_date))::DATE AS primero,
           DATE_TRUNC('month', MAX(order_date))::DATE AS ultimo
    FROM fact_order
), meses AS (
    SELECT full_date AS mes
    FROM dim_date, limites
    WHERE day = 1 AND full_date BETWEEN primero AND ultimo
)
SELECT STRFTIME(a.mes, '%Y-%m') AS desde,
       STRFTIME(b.mes, '%Y-%m') AS hasta,
       a.mes AS fecha_desde,
       LAST_DAY(b.mes) AS fecha_hasta
FROM meses AS a
JOIN meses AS b ON b.mes >= a.mes
ORDER BY desde, hasta;

CREATE TABLE mart_periods AS
SELECT * FROM reporte_periodos ORDER BY desde, hasta;

CREATE TABLE mart_filters AS
SELECT 'mes' AS tipo, desde AS valor, desde AS etiqueta
FROM reporte_periodos
WHERE desde = hasta
UNION ALL
SELECT 'canal', code, code FROM dim_channel
UNION ALL
SELECT 'provincia', name, name FROM dim_province WHERE province_key <> -1
UNION ALL
SELECT 'producto', CAST(product_id AS VARCHAR), name FROM dim_product
ORDER BY tipo, valor;

CREATE VIEW reporte_canales AS
SELECT '' AS canal UNION ALL SELECT code FROM dim_channel;

CREATE VIEW reporte_provincias AS
SELECT '' AS provincia
UNION ALL
SELECT name FROM dim_province WHERE province_key <> -1
UNION ALL
SELECT DISTINCT 'Sin provincia' FROM fact_order WHERE province_key = -1;
