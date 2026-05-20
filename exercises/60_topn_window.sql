-- 窗口函数 / 分组 TopN

-- 1) 每类目 buy 数 Top 3 商品(用 QUALIFY,不要再套子查询)

-- 2) 每天 pv 最高的商品,用 LAG 算环比

-- 3) 同一查询里把 ROW_NUMBER / RANK / DENSE_RANK 三列并排,对比并列情况

-- 4) 销量 Top 5 商品的按日 buy 数与累计 buy 数(running total)
