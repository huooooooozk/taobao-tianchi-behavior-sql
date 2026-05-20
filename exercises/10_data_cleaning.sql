-- 数据清洗:基于 raw_user_behavior

-- 1) 统计时间戳越界(不在北京时间 [2017-11-25, 2017-12-04) 内)行数与占比

-- 2) 校验 behavior_type 字段:列出所有取值及其行数,标注是否在 {pv,cart,fav,buy} 内

-- 3) pv 事件去重到 (user_id, item_id) 粒度,算重复浏览率

-- 4) CREATE TABLE AS 产出清洗后事实表 user_behavior_clean
