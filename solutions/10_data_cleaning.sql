-- 数据清洗

-- 1) 时间戳越界占比
SELECT
    count(*) FILTER (
        WHERE epoch_ms(ts * 1000) + INTERVAL 8 HOUR <  TIMESTAMP '2017-11-25 00:00:00'
           OR epoch_ms(ts * 1000) + INTERVAL 8 HOUR >= TIMESTAMP '2017-12-04 00:00:00'
    ) AS noise_rows,
    count(*) AS total_rows,
    round(100.0 * count(*) FILTER (
        WHERE epoch_ms(ts * 1000) + INTERVAL 8 HOUR <  TIMESTAMP '2017-11-25 00:00:00'
           OR epoch_ms(ts * 1000) + INTERVAL 8 HOUR >= TIMESTAMP '2017-12-04 00:00:00'
    ) / count(*), 4) AS noise_pct
FROM raw_user_behavior;

-- 2) behavior_type 取值校验
SELECT
    behavior_type,
    count(*) AS cnt,
    behavior_type IN ('pv', 'cart', 'fav', 'buy') AS is_valid
FROM raw_user_behavior
GROUP BY behavior_type
ORDER BY cnt DESC;

-- 3) pv 去重到 (user, item) 粒度
SELECT
    count(*)                            AS pv_events,
    count(DISTINCT (user_id, item_id))  AS distinct_user_item,
    round(100.0 * (1 - count(DISTINCT (user_id, item_id)) * 1.0
          / nullif(count(*), 0)), 2)    AS repeat_view_pct
FROM raw_user_behavior
WHERE behavior_type = 'pv';

-- 用 QUALIFY 保留每个 (user, item) 的首次 pv
SELECT user_id, item_id, event_time
FROM user_behavior
WHERE behavior_type = 'pv'
QUALIFY row_number() OVER (PARTITION BY user_id, item_id ORDER BY ts) = 1
LIMIT 10;

-- 4) 复现清洗逻辑
CREATE OR REPLACE TABLE user_behavior_clean AS
SELECT
    user_id, item_id, category_id, behavior_type, ts,
    epoch_ms(ts * 1000) + INTERVAL 8 HOUR                    AS event_time,
    CAST(epoch_ms(ts * 1000) + INTERVAL 8 HOUR AS DATE)      AS event_date,
    EXTRACT(HOUR FROM epoch_ms(ts * 1000) + INTERVAL 8 HOUR) AS event_hour
FROM raw_user_behavior
WHERE behavior_type IN ('pv', 'cart', 'fav', 'buy')
  AND epoch_ms(ts * 1000) + INTERVAL 8 HOUR >= TIMESTAMP '2017-11-25 00:00:00'
  AND epoch_ms(ts * 1000) + INTERVAL 8 HOUR <  TIMESTAMP '2017-12-04 00:00:00';

SELECT count(*) AS clean_rows FROM user_behavior_clean;
