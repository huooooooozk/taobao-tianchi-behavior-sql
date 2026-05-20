-- 转化漏斗

-- 1) 全站漏斗
SELECT
    count(DISTINCT user_id) FILTER (WHERE behavior_type = 'pv')   AS uv_pv,
    count(DISTINCT user_id) FILTER (WHERE behavior_type = 'fav')  AS uv_fav,
    count(DISTINCT user_id) FILTER (WHERE behavior_type = 'cart') AS uv_cart,
    count(DISTINCT user_id) FILTER (WHERE behavior_type = 'buy')  AS uv_buy,
    round(100.0 * count(DISTINCT user_id) FILTER (WHERE behavior_type = 'buy')
          / nullif(count(DISTINCT user_id) FILTER (WHERE behavior_type = 'pv'), 0), 2)
        AS pv_to_buy_pct
FROM user_behavior;

-- 2) 商品维度漏斗 Top 10
SELECT
    item_id,
    count(DISTINCT user_id) FILTER (WHERE behavior_type = 'pv')   AS pv_uv,
    count(DISTINCT user_id) FILTER (WHERE behavior_type = 'cart') AS cart_uv,
    count(DISTINCT user_id) FILTER (WHERE behavior_type = 'buy')  AS buy_uv,
    round(100.0 * count(DISTINCT user_id) FILTER (WHERE behavior_type = 'buy')
          / nullif(count(DISTINCT user_id) FILTER (WHERE behavior_type = 'pv'), 0), 2)
        AS pv_to_buy_pct
FROM user_behavior
GROUP BY item_id
ORDER BY buy_uv DESC, pv_uv DESC
LIMIT 10;

-- 3) 类目级加购未支付率
WITH cart_users AS (
    SELECT DISTINCT category_id, user_id FROM user_behavior WHERE behavior_type = 'cart'
),
buy_users AS (
    SELECT DISTINCT category_id, user_id FROM user_behavior WHERE behavior_type = 'buy'
)
SELECT
    c.category_id,
    count(*)                                       AS cart_uv,
    count(*) FILTER (WHERE b.user_id IS NULL)      AS cart_not_buy_uv,
    round(100.0 * count(*) FILTER (WHERE b.user_id IS NULL) / count(*), 2) AS abandon_pct
FROM cart_users c
LEFT JOIN buy_users b USING (category_id, user_id)
GROUP BY c.category_id
HAVING count(*) >= 20
ORDER BY abandon_pct DESC, cart_uv DESC
LIMIT 15;
