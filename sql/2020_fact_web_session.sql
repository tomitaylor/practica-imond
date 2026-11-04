CREATE TABLE fact_web_session (
    session_id BIGINT PRIMARY KEY,
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    visitor_key VARCHAR NOT NULL,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    traffic_source_key INTEGER NOT NULL REFERENCES dim_traffic_source(traffic_source_key),
    device_key INTEGER NOT NULL REFERENCES dim_device(device_key)
);

INSERT INTO fact_web_session
SELECT
    w.session_id,
    CAST(strftime(w.started_at, '%Y%m%d') AS INTEGER),
    COALESCE(c.customer_key, -1),
    CASE
        WHEN w.customer_id IS NOT NULL
            THEN 'customer_' || CAST(w.customer_id AS VARCHAR)
        ELSE 'session_' || CAST(w.session_id AS VARCHAR)
    END,
    w.started_at,
    w.ended_at,
    COALESCE(traffic_source.traffic_source_key, -1),
    COALESCE(device.device_key, -1)
FROM raw.web_session AS w
LEFT JOIN dim_customer AS c ON c.customer_id = w.customer_id
LEFT JOIN dim_traffic_source AS traffic_source ON traffic_source.source = w.source
LEFT JOIN dim_device AS device ON device.device = w.device;
