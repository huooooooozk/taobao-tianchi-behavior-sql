-- 异常行为模式探索(阈值针对抽样子集校准;全量需重定)

-- 1) pv >= 300 且 buy = 0 的用户(高频只浏览)

-- 2) 任意 60 秒内 pv 数 >= 10 的用户(秒级爆发点击)
--    提示:RANGE BETWEEN CURRENT ROW AND 59 FOLLOWING, ORDER BY epoch(event_time)

-- 3) cart >= 20 且 buy = 0 的用户(加购囤货不下单)

-- 4) total >= 40 且 0~5 点占比 >= 80% 的用户(凌晨集中活跃)

-- 5) 综合候选集:把 1) 2) 3) 4) 各计 1 分(其中 4 改为 active_days <= 3),
--    合成 anomaly_score,输出命中明细
