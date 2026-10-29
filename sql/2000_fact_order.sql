-- =====================================================================
-- 02_hechos.sql — Tablas de HECHOS del modelo estrella
-- =====================================================================
-- Este archivo se ejecuta después de 01_dimensiones.sql porque los hechos
-- apuntan a las dimensiones con FOREIGN KEY (REFERENCES).
--
-- Para cada tabla de hechos:
--   1. Definí el GRANO: ¿qué representa UNA fila?
--      (ej.: un producto dentro de un pedido, una sesión web, una respuesta NPS)
--   2. CREATE TABLE con:
--        - PRIMARY KEY
--        - una FOREIGN KEY por cada dimensión:  product_key INTEGER REFERENCES dim_product (product_key)
--        - las métricas (cantidades, importes, puntajes...)
--   3. INSERT INTO ... SELECT uniendo las tablas de origen (raw.) con las dimensiones
--      para obtener las claves.
--
-- Patrón para obtener la clave de una dimensión:
--
--   SELECT i.order_item_id, p.product_key, i.quantity, i.line_total
--   FROM raw.sales_order_item AS i
--   JOIN dim_product AS p ON p.product_id = i.product_id
--
-- Si una FOREIGN KEY apunta a una clave que no existe en la dimensión,
-- DuckDB rechaza la carga y run_sql.py te muestra el error.
-- =====================================================================


-- TU TURNO: creá acá las tablas de hechos.

CREATE TABLE fact_order (
    order_id BIGINT PRIMARY KEY,
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    store_key INTEGER NOT NULL REFERENCES dim_store(store_key),
    province_key INTEGER REFERENCES dim_province(province_key),
    billing_address_key INTEGER NOT NULL REFERENCES dim_address(address_key),
    shipping_address_key INTEGER NOT NULL REFERENCES dim_address(address_key),
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL,
    shipping_fee DECIMAL(12,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL
);

INSERT INTO fact_order
SELECT
    o.order_id,
    CAST(strftime(o.order_date, '%Y%m%d') AS INTEGER),
    COALESCE(c.customer_key, -1),
    ch.channel_key,
    COALESCE(s.store_key, -1),
    p.province_key,
    COALESCE(ba.address_key, -1),
    COALESCE(sa.address_key, -1),
    o.order_date,
    o.status,
    o.currency_code,
    o.subtotal,
    o.tax_amount,
    o.shipping_fee,
    o.total_amount
FROM raw.sales_order AS o
LEFT JOIN dim_customer AS c ON c.customer_id = o.customer_id
LEFT JOIN dim_channel AS ch ON ch.channel_id = o.channel_id
LEFT JOIN dim_store AS s ON s.store_id = o.store_id
LEFT JOIN raw.address AS a ON a.address_id = o.shipping_address_id
LEFT JOIN dim_province AS p ON p.province_id = a.province_id
LEFT JOIN dim_address AS ba ON ba.address_id = o.billing_address_id
LEFT JOIN dim_address AS sa ON sa.address_id = o.shipping_address_id;





