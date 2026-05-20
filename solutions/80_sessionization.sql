-- Session 切分

-- 1) 给每条行为打 session 序号
WITH marked AS (
    SELECT
        user_id, item_id, behavior_type, event_time,
        CASE
            WHEN lag(event_time) OVER w IS NULL
              OR event_time - lag(event_time) OVER w > INTERVAL 30 MINUTE
            THEN 1 ELSE 0
        END AS is_new
    FROM user_behavior
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time)
)
SELECT
    user_id, behavior_type, event_time,
    sum(is_new) OVER (PARTITION BY user_id ORDER BY event_time
                      ROWS UNBOUNDED PRECEDING) AS session_seq
FROM marked
WHERE user_id = (SELECT min(user_id) FROM user_behavior)
ORDER BY event_time
LIMIT 30;

-- 2) session 聚合
WITH marked AS (
    SELECT user_id, behavior_type, event_time,
        CASE WHEN lag(event_time) OVER w IS NULL
                  OR event_time - lag(event_time) OVER w > INTERVAL 30 MINUTE
             THEN 1 ELSE 0 END AS is_new
    FROM user_behavior
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time)
),
sessioned AS (
    SELECT *,
        sum(is_new) OVER (PARTITION BY user_id ORDER BY event_time
                          ROWS UNBOUNDED PRECEDING) AS session_seq
    FROM marked
)
SELECT
    user_id, session_seq,
    count(*)                                       AS events,
    epoch(max(event_time) - min(event_time))       AS duration_sec,
    count(*) FILTER (WHERE behavior_type = 'pv')   AS pv_cnt,
    count(*) FILTER (WHERE behavior_type = 'buy')  AS buy_cnt
FROM sessioned
GROUP BY user_id, session_seq
ORDER BY events DESC
LIMIT 20;

-- 3) buy 无 pv 的 session
WITH marked AS (
    SELECT user_id, behavior_type, event_time,
        CASE WHEN lag(event_time) OVER w IS NULL
                  OR event_time - lag(event_time) OVER w > INTERVAL 30 MINUTE
             THEN 1 ELSE 0 END AS is_new
    FROM user_behavior
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time)
),
sessioned AS (
    SELECT *,
        sum(is_new) OVER (PARTITION BY user_id ORDER BY event_time
                          ROWS UNBOUNDED PRECEDING) AS session_seq
    FROM marked
),
s AS (
    SELECT user_id, session_seq,
           count(*) AS events,
           count(*) FILTER (WHERE behavior_type = 'pv')  AS pv_cnt,
           count(*) FILTER (WHERE behavior_type = 'buy') AS buy_cnt
    FROM sessioned GROUP BY user_id, session_seq
)
SELECT user_id, session_seq, events, pv_cnt, buy_cnt
FROM s
WHERE buy_cnt > 0 AND pv_cnt = 0
ORDER BY buy_cnt DESC, events DESC
LIMIT 20;

-- 4) 整体会话指标
WITH marked AS (
    SELECT user_id, event_time,
        CASE WHEN lag(event_time) OVER w IS NULL
                  OR event_time - lag(event_time) OVER w > INTERVAL 30 MINUTE
             THEN 1 ELSE 0 END AS is_new
    FROM user_behavior
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time)
),
sessioned AS (
    SELECT *,
        sum(is_new) OVER (PARTITION BY user_id ORDER BY event_time
                          ROWS UNBOUNDED PRECEDING) AS session_seq
    FROM marked
),
s AS (
    SELECT user_id, session_seq,
           epoch(max(event_time) - min(event_time)) AS duration_sec
    FROM sessioned GROUP BY user_id, session_seq
)
SELECT
    count(*)                                          AS total_sessions,
    count(DISTINCT user_id)                           AS users,
    round(count(*) * 1.0 / count(DISTINCT user_id), 2) AS avg_sessions_per_user,
    round(avg(duration_sec), 1)                       AS avg_session_sec
FROM s;
