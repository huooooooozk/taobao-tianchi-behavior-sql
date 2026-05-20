-- 从全量重新生成抽样子集:取 user_id % 330 = 1 的全部行为(保留脏数据)
-- 用法:duckdb < scripts/make_sample.sql

COPY (
    SELECT column0 AS user_id, column1 AS item_id, column2 AS category_id,
           column3 AS behavior_type, column4 AS ts
    FROM read_csv('data/UserBehavior.csv', header = false,
        columns = {
            'column0': 'BIGINT', 'column1': 'BIGINT', 'column2': 'BIGINT',
            'column3': 'VARCHAR', 'column4': 'BIGINT'
        })
    WHERE column0 % 330 = 1
    ORDER BY column0, column4
) TO 'data/sample/user_behavior_sample.csv' (HEADER, DELIMITER ',');
