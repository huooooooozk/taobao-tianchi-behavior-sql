-- 异常行为模式

-- 1) 高频只浏览
SELECT
    user_id,
    count(*) FILTER (WHERE behavior_type = 'pv')  AS pv_cnt,
    count(*) FILTER (WHERE behavior_type = 'buy') AS buy_cnt
FROM user_behavior
GROUP BY user_id
HAVING count(*) FILTER (WHERE behavior_type = 'pv')  >= 300
   AND count(*) FILTER (WHERE behavior_type = 'buy') =  0
ORDER BY pv_cnt DESC;

-- 2) 60 秒 pv 爆发
WITH pv AS (
    SELECT
        user_id,
        count(*) OVER (
            PARTITION BY user_id
            ORDER BY epoch(event_time)
            RANGE BETWEEN CURRENT ROW AND 59 FOLLOWING
        ) AS pv_in_60s
    FROM user_behavior
    WHERE behavior_type = 'pv'
)
SELECT user_id, max(pv_in_60s) AS max_burst_60s
FROM pv
GROUP BY user_id
HAVING max(pv_in_60s) >= 10
ORDER BY max_burst_60s DESC;

-- 3) 加购囤货
SELECT
    user_id,
    count(*) FILTER (WHERE behavior_type = 'cart') AS cart_cnt,
    count(*) FILTER (WHERE behavior_type = 'buy')  AS buy_cnt
FROM user_behavior
GROUP BY user_id
HAVING count(*) FILTER (WHERE behavior_type = 'cart') >= 20
   AND count(*) FILTER (WHERE behavior_type = 'buy')  =  0
ORDER BY cart_cnt DESC;

-- 4) 凌晨集中
SELECT
    user_id,
    count(*) AS total,
    count(*) FILTER (WHERE event_hour BETWEEN 0 AND 5) AS night,
    round(100.0 * count(*) FILTER (WHERE event_hour BETWEEN 0 AND 5) / count(*), 1) AS night_pct
FROM user_behavior
GROUP BY user_id
HAVING count(*) >= 40
   AND count(*) FILTER (WHERE event_hour BETWEEN 0 AND 5) * 1.0 / count(*) >= 0.8
ORDER BY night_pct DESC, total DESC;

-- 5) 合成 anomaly_score
WITH u AS (
    SELECT
        user_id,
        count(*) AS total,
        count(*) FILTER (WHERE behavior_type = 'pv')        AS pv_cnt,
        count(*) FILTER (WHERE behavior_type = 'cart')      AS cart_cnt,
        count(*) FILTER (WHERE behavior_type = 'buy')       AS buy_cnt,
        count(*) FILTER (WHERE event_hour BETWEEN 0 AND 5)  AS night_cnt,
        count(DISTINCT event_date)                          AS active_days
    FROM user_behavior
    GROUP BY user_id
)
SELECT * FROM (
    SELECT
        user_id, total, pv_cnt, cart_cnt, buy_cnt, active_days,
        (pv_cnt   >= 300 AND buy_cnt = 0)::INT                                  AS hit_browse_no_buy,
        (cart_cnt >= 20  AND buy_cnt = 0)::INT                                  AS hit_cart_hoard,
        (total >= 40 AND night_cnt * 1.0 / total >= 0.8)::INT                    AS hit_night,
        (active_days <= 3)::INT                                                 AS hit_low_days,
          (pv_cnt   >= 300 AND buy_cnt = 0)::INT
        + (cart_cnt >= 20  AND buy_cnt = 0)::INT
        + (total >= 40 AND night_cnt * 1.0 / total >= 0.8)::INT
        + (active_days <= 3)::INT                                               AS anomaly_score
    FROM u
)
WHERE anomaly_score >= 1
ORDER BY anomaly_score DESC, total DESC
LIMIT 30;
