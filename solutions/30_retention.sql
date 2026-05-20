-- 留存

-- 1) 11-25 → 11-26 次日留存
WITH d0 AS (SELECT DISTINCT user_id FROM user_behavior WHERE event_date = DATE '2017-11-25'),
     d1 AS (SELECT DISTINCT user_id FROM user_behavior WHERE event_date = DATE '2017-11-26')
SELECT
    (SELECT count(*) FROM d0) AS day0_users,
    count(*)                  AS retained,
    round(100.0 * count(*) / (SELECT count(*) FROM d0), 2) AS d1_retention_pct
FROM d0 JOIN d1 USING (user_id);

-- 2) cohort 次日留存
WITH first_day AS (
    SELECT user_id, min(event_date) AS cohort_date FROM user_behavior GROUP BY user_id
),
activity AS (SELECT DISTINCT user_id, event_date FROM user_behavior)
SELECT
    f.cohort_date,
    count(DISTINCT f.user_id) AS cohort_size,
    count(DISTINCT a.user_id) AS d1_retained,
    round(100.0 * count(DISTINCT a.user_id) / count(DISTINCT f.user_id), 2) AS d1_pct
FROM first_day f
LEFT JOIN activity a
       ON a.user_id = f.user_id
      AND a.event_date = f.cohort_date + 1
GROUP BY f.cohort_date
ORDER BY f.cohort_date;

-- 3) cohort × D1/D3/D7 留存矩阵
WITH first_day AS (
    SELECT user_id, min(event_date) AS cohort_date FROM user_behavior GROUP BY user_id
),
activity AS (SELECT DISTINCT user_id, event_date FROM user_behavior)
SELECT
    f.cohort_date,
    count(DISTINCT f.user_id) AS cohort_size,
    count(DISTINCT a.user_id) FILTER (WHERE a.event_date = f.cohort_date + 1) AS d1,
    count(DISTINCT a.user_id) FILTER (WHERE a.event_date = f.cohort_date + 3) AS d3,
    count(DISTINCT a.user_id) FILTER (WHERE a.event_date = f.cohort_date + 7) AS d7
FROM first_day f
LEFT JOIN activity a ON a.user_id = f.user_id
GROUP BY f.cohort_date
ORDER BY f.cohort_date;
