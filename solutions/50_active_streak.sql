-- 连续活跃天数

-- 1) 每用户最长连续活跃天数
WITH days AS (SELECT DISTINCT user_id, event_date FROM user_behavior),
islands AS (
    SELECT user_id,
           event_date - CAST(row_number() OVER (PARTITION BY user_id ORDER BY event_date) AS INTEGER) AS grp
    FROM days
)
SELECT user_id, max(streak_len) AS longest_streak
FROM (SELECT user_id, grp, count(*) AS streak_len FROM islands GROUP BY user_id, grp)
GROUP BY user_id
ORDER BY longest_streak DESC, user_id
LIMIT 20;

-- 2) 9 天全勤
SELECT count(*) AS perfect_attendance_users
FROM (SELECT user_id FROM user_behavior GROUP BY user_id HAVING count(DISTINCT event_date) = 9);

-- 3) 活跃 >= 3 段
WITH days AS (SELECT DISTINCT user_id, event_date FROM user_behavior),
islands AS (
    SELECT user_id,
           event_date - CAST(row_number() OVER (PARTITION BY user_id ORDER BY event_date) AS INTEGER) AS grp
    FROM days
),
streaks AS (SELECT user_id, grp, count(*) AS streak_len FROM islands GROUP BY user_id, grp)
SELECT
    user_id,
    sum(streak_len) AS active_days,
    max(streak_len) AS longest_streak,
    count(*)        AS active_blocks
FROM streaks
GROUP BY user_id
HAVING count(*) >= 3
ORDER BY active_blocks DESC, active_days
LIMIT 20;
