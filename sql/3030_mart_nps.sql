CREATE TABLE mart_nps AS
SELECT
    n.nps_id,
    d.full_date AS fecha,
    c.code AS canal,
    n.score AS puntaje,
    n.segment AS segmento,
    n.nps_value
FROM fact_nps AS n
JOIN dim_date AS d ON d.date_key = n.date_key
JOIN dim_channel AS c ON c.channel_key = n.channel_key;