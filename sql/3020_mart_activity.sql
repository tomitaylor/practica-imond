CREATE TABLE mart_activity AS
SELECT
    w.session_id,
    d.full_date AS fecha,
    w.visitor_key,
    w.source AS fuente,
    w.device AS dispositivo
FROM fact_web_session AS w
JOIN dim_date AS d ON d.date_key = w.date_key;