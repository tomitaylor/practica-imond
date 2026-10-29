CREATE TABLE dim_channel (
    channel_key INTEGER PRIMARY KEY,
    channel_id INTEGER NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL
);

INSERT INTO dim_channel
SELECT
    ROW_NUMBER() OVER (ORDER BY channel_id) AS channel_key,
    channel_id,
    code,
    name
FROM raw.channel;
