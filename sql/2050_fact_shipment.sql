CREATE TABLE fact_shipment (
    shipment_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    shipped_date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    delivered_date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    store_key INTEGER NOT NULL REFERENCES dim_store(store_key),
    province_key INTEGER NOT NULL REFERENCES dim_province(province_key),
    carrier_key INTEGER NOT NULL REFERENCES dim_carrier(carrier_key),
    tracking_number VARCHAR(60),
    shipment_status_key INTEGER NOT NULL REFERENCES dim_shipment_status(shipment_status_key),
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    delivery_days DECIMAL(12,4)
);

INSERT INTO fact_shipment
SELECT
    s.shipment_id,
    s.order_id,
    o.date_key,
    COALESCE(CAST(strftime(s.shipped_at, '%Y%m%d') AS INTEGER), -1),
    COALESCE(CAST(strftime(s.delivered_at, '%Y%m%d') AS INTEGER), -1),
    o.customer_key,
    o.channel_key,
    o.store_key,
    o.province_key,
    COALESCE(carrier.carrier_key, -1),
    s.tracking_number,
    COALESCE(shipment_status.shipment_status_key, -1),
    s.shipped_at,
    s.delivered_at,
    EXTRACT(EPOCH FROM (s.delivered_at - s.shipped_at)) / 86400.0
FROM raw.shipment AS s
JOIN fact_order AS o ON o.order_id = s.order_id
LEFT JOIN dim_shipment_status AS shipment_status ON shipment_status.status = s.status
LEFT JOIN dim_carrier AS carrier ON carrier.carrier = s.carrier;
