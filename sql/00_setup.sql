-- 建库 + 清洗。在项目根目录执行:duckdb taobao.db < sql/00_setup.sql

DROP TABLE IF EXISTS raw_user_behavior;
CREATE TABLE raw_user_behavior (
    user_id       BIGINT,
    item_id       BIGINT,
    category_id   BIGINT,
    behavior_type VARCHAR,
    ts            BIGINT
);
COPY raw_user_behavior FROM 'data/sample/user_behavior_sample.csv' (HEADER, DELIMITER ',');

-- ts 是 UTC 秒,加 8 小时换成北京时间;过滤掉官方区间外的脏数据
DROP TABLE IF EXISTS user_behavior;
CREATE TABLE user_behavior AS
SELECT
    user_id, item_id, category_id, behavior_type, ts,
    epoch_ms(ts * 1000) + INTERVAL 8 HOUR                    AS event_time,
    CAST(epoch_ms(ts * 1000) + INTERVAL 8 HOUR AS DATE)      AS event_date,
    EXTRACT(HOUR FROM epoch_ms(ts * 1000) + INTERVAL 8 HOUR) AS event_hour
FROM raw_user_behavior
WHERE behavior_type IN ('pv', 'cart', 'fav', 'buy')
  AND epoch_ms(ts * 1000) + INTERVAL 8 HOUR >= TIMESTAMP '2017-11-25 00:00:00'
  AND epoch_ms(ts * 1000) + INTERVAL 8 HOUR <  TIMESTAMP '2017-12-04 00:00:00';

SELECT 'raw_user_behavior' AS tbl, count(*) AS rows FROM raw_user_behavior
UNION ALL SELECT 'user_behavior', count(*) FROM user_behavior;
