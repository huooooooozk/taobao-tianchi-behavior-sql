-- 加载全量 1 亿行(把官方 UserBehavior.csv 放到 data/UserBehavior.csv)
-- 用法:duckdb taobao_full.db < scripts/load_full.sql

DROP TABLE IF EXISTS raw_user_behavior;
CREATE TABLE raw_user_behavior AS
SELECT
    column0 AS user_id,
    column1 AS item_id,
    column2 AS category_id,
    column3 AS behavior_type,
    column4 AS ts
FROM read_csv('data/UserBehavior.csv', header = false,
    columns = {
        'column0': 'BIGINT', 'column1': 'BIGINT', 'column2': 'BIGINT',
        'column3': 'VARCHAR', 'column4': 'BIGINT'
    });

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
