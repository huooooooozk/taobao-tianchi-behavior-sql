-- 窗口函数 / 分组 TopN

-- 1) 每类目 buy 数 Top 3
SELECT
    category_id, item_id,
    count(*) AS buy_cnt,
    row_number() OVER (PARTITION BY category_id ORDER BY count(*) DESC) AS rnk
FROM user_behavior
WHERE behavior_type = 'buy'
GROUP BY category_id, item_id
QUALIFY rnk <= 3
ORDER BY category_id, rnk
LIMIT 30;

-- 2) 每日 pv 冠军 + 环比
WITH daily AS (
    SELECT event_date, item_id, count(*) AS pv_cnt
    FROM user_behavior WHERE behavior_type = 'pv'
    GROUP BY event_date, item_id
),
top1 AS (
    SELECT event_date, item_id, pv_cnt FROM daily
    QUALIFY row_number() OVER (PARTITION BY event_date ORDER BY pv_cnt DESC) = 1
)
SELECT
    event_date, item_id, pv_cnt,
    lag(pv_cnt) OVER (ORDER BY event_date)            AS prev_day_top_pv,
    pv_cnt - lag(pv_cnt) OVER (ORDER BY event_date)   AS dod_diff
FROM top1
ORDER BY event_date;

-- 3) ROW_NUMBER vs RANK vs DENSE_RANK
--   并列时:row_number 1,2,3,4   rank 1,2,2,4   dense_rank 1,2,2,3
SELECT
    category_id, count(*) AS buy_cnt,
    row_number() OVER (ORDER BY count(*) DESC) AS rn,
    rank()       OVER (ORDER BY count(*) DESC) AS rk,
    dense_rank() OVER (ORDER BY count(*) DESC) AS dk
FROM user_behavior WHERE behavior_type = 'buy'
GROUP BY category_id
ORDER BY buy_cnt DESC
LIMIT 20;

-- 4) Top 5 商品的按日累计
WITH top_items AS (
    SELECT item_id FROM user_behavior WHERE behavior_type = 'buy'
    GROUP BY item_id ORDER BY count(*) DESC LIMIT 5
),
daily AS (
    SELECT item_id, event_date, count(*) AS buy_cnt
    FROM user_behavior
    WHERE behavior_type = 'buy' AND item_id IN (SELECT item_id FROM top_items)
    GROUP BY item_id, event_date
)
SELECT
    item_id, event_date, buy_cnt,
    sum(buy_cnt) OVER (PARTITION BY item_id ORDER BY event_date
                       ROWS UNBOUNDED PRECEDING) AS cum_buy
FROM daily
ORDER BY item_id, event_date;
