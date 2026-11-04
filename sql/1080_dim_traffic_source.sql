CREATE TABLE dim_traffic_source (
    traffic_source_key INTEGER PRIMARY KEY,
    source VARCHAR(50) UNIQUE
);

INSERT INTO dim_traffic_source VALUES (-1, NULL);

INSERT INTO dim_traffic_source
SELECT ROW_NUMBER() OVER (ORDER BY source), source
FROM (
    SELECT DISTINCT source
    FROM raw.web_session
    WHERE source IS NOT NULL
) AS valores;
