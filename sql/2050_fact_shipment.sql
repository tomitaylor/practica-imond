CREATE TABLE fact_shipment (
    shipment_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    shipped_date_key INTEGER REFERENCES dim_date(date_key),
    delivered_date_key INTEGER REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    store_key INTEGER NOT NULL REFERENCES dim_store(store_key),
    province_key INTEGER REFERENCES dim_province(province_key),
    carrier VARCHAR(40),
    tracking_number VARCHAR(60),
    status VARCHAR(20) NOT NULL,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    delivery_days DECIMAL(12,4)
);

INSERT INTO fact_shipment
SELECT
    s.shipment_id,
    s.order_id,
    o.date_key,
    CAST(strftime(s.shipped_at, '%Y%m%d') AS INTEGER),
    CAST(strftime(s.delivered_at, '%Y%m%d') AS INTEGER),
    o.customer_key,
    o.channel_key,
    o.store_key,
    o.province_key,
    s.carrier,
    s.tracking_number,
    s.status,
    s.shipped_at,
    s.delivered_at,
    EXTRACT(EPOCH FROM (s.delivered_at - s.shipped_at)) / 86400.0
FROM raw.shipment AS s
JOIN fact_order AS o ON o.order_id = s.order_id;

