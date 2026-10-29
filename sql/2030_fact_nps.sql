CREATE TABLE fact_nps (
    nps_id BIGINT PRIMARY KEY,
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 10),
    segment VARCHAR(10) NOT NULL,
    nps_value SMALLINT NOT NULL CHECK (nps_value IN (-1, 0, 1)),
    comment TEXT,
    responded_at TIMESTAMP NOT NULL
);

INSERT INTO fact_nps
SELECT
    n.nps_id,
    CAST(strftime(n.responded_at, '%Y%m%d') AS INTEGER),
    COALESCE(c.customer_key, -1),
    ch.channel_key,
    n.score,
    CASE
        WHEN n.score >= 9 THEN 'Promotor'
        WHEN n.score >= 7 THEN 'Pasivo'
        ELSE 'Detractor'
    END,
    CASE
        WHEN n.score >= 9 THEN 1
        WHEN n.score >= 7 THEN 0
        ELSE -1
    END,
    n.comment,
    n.responded_at
FROM raw.nps_response AS n
LEFT JOIN dim_customer AS c ON c.customer_id = n.customer_id
LEFT JOIN dim_channel AS ch ON ch.channel_id = n.channel_id;
