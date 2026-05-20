-- RFM

-- 1) R/F/M 原始值
SELECT
    user_id,
    DATE '2017-12-03' - max(event_date) AS recency_days,
    count(*)                            AS frequency,
    count(DISTINCT item_id)             AS monetary
FROM user_behavior
WHERE behavior_type = 'buy'
GROUP BY user_id
ORDER BY frequency DESC
LIMIT 20;

-- 2) 打分 + 分层
WITH rfm AS (
    SELECT
        user_id,
        DATE '2017-12-03' - max(event_date) AS recency_days,
        count(*)                            AS frequency,
        count(DISTINCT item_id)             AS monetary
    FROM user_behavior
    WHERE behavior_type = 'buy'
    GROUP BY user_id
),
scored AS (
    SELECT *,
        4 - ntile(3) OVER (ORDER BY recency_days) AS r_score,  -- recency 越小越好,反向
        ntile(3) OVER (ORDER BY frequency)        AS f_score,
        ntile(3) OVER (ORDER BY monetary)         AS m_score
    FROM rfm
)
SELECT
    user_id, recency_days, frequency, monetary,
    r_score, f_score, m_score,
    CASE
        WHEN r_score >= 2 AND f_score >= 2 AND m_score >= 2 THEN '重要价值'
        WHEN r_score >= 2 AND f_score <  2                  THEN '重要发展'
        WHEN r_score <  2 AND f_score >= 2                  THEN '重要挽留'
        WHEN r_score <  2 AND f_score <  2                  THEN '流失预警'
        ELSE '一般'
    END AS segment
FROM scored
ORDER BY r_score DESC, f_score DESC, m_score DESC
LIMIT 20;

-- 3) 分层规模
WITH rfm AS (
    SELECT
        user_id,
        DATE '2017-12-03' - max(event_date) AS recency_days,
        count(*)                            AS frequency,
        count(DISTINCT item_id)             AS monetary
    FROM user_behavior
    WHERE behavior_type = 'buy'
    GROUP BY user_id
),
labeled AS (
    SELECT
        CASE
            WHEN (4 - ntile(3) OVER (ORDER BY recency_days)) >= 2
                 AND ntile(3) OVER (ORDER BY frequency) >= 2
                 AND ntile(3) OVER (ORDER BY monetary)  >= 2 THEN '重要价值'
            WHEN (4 - ntile(3) OVER (ORDER BY recency_days)) >= 2
                 AND ntile(3) OVER (ORDER BY frequency) <  2 THEN '重要发展'
            WHEN (4 - ntile(3) OVER (ORDER BY recency_days)) <  2
                 AND ntile(3) OVER (ORDER BY frequency) >= 2 THEN '重要挽留'
            WHEN (4 - ntile(3) OVER (ORDER BY recency_days)) <  2
                 AND ntile(3) OVER (ORDER BY frequency) <  2 THEN '流失预警'
            ELSE '一般'
        END AS segment
    FROM rfm
)
SELECT segment, count(*) AS users,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pct
FROM labeled
GROUP BY segment
ORDER BY users DESC;
