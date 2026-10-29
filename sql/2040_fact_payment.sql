CREATE TABLE fact_payment (
    payment_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    paid_date_key INTEGER REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    store_key INTEGER NOT NULL REFERENCES dim_store(store_key),
    province_key INTEGER REFERENCES dim_province(province_key),
    method VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    paid_at TIMESTAMP,
    transaction_ref VARCHAR(80)
);

INSERT INTO fact_payment
SELECT
    p.payment_id,
    p.order_id,
    o.date_key,
    CAST(strftime(p.paid_at, '%Y%m%d') AS INTEGER),
    o.customer_key,
    o.channel_key,
    o.store_key,
    o.province_key,
    p.method,
    p.status,
    p.amount,
    p.paid_at,
    p.transaction_ref
FROM raw.payment AS p
JOIN fact_order AS o ON o.order_id = p.order_id;

