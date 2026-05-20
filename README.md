# taobao-behavior-sql

阿里天池 [UserBehavior](https://tianchi.aliyun.com/dataset/649) 数据集上的 SQL 练习,围绕电商用户行为分析的常见场景,覆盖 SQL 面试常考的窗口函数、CTE、`QUALIFY`、条件聚合、gaps-and-islands、会话切分等技术点。基于 [DuckDB](https://duckdb.org/),零配置、单文件、亿行秒级聚合。

仓库自带 30 万行抽样数据,clone 下来直接能跑;想上全量 1 亿行,把官方 CSV 放进 `data/` 即可。

## 快速开始

```bash
# 1. 装 DuckDB (单二进制,无依赖):https://duckdb.org/docs/installation/

# 2. 在项目根目录建库
duckdb taobao.db < sql/00_setup.sql

# 3. 自己写,或直接跑参考答案
duckdb taobao.db < solutions/10_data_cleaning.sql
```

进入交互式:`duckdb taobao.db`。

## 练习清单

| # | 文件 | 涉及技术 |
|---|---|---|
| 1 | `10_data_cleaning` | `FILTER` 条件聚合、`QUALIFY` 去重、`NULLIF` |
| 2 | `20_funnel` | `COUNT(DISTINCT ... FILTER)`、`LEFT JOIN USING` 求差集 |
| 3 | `30_retention` | cohort 自连接、`DATE + N`、条件聚合做留存矩阵透视 |
| 4 | `40_rfm` | `NTILE` 分桶、多维 `CASE`、占比窗口 `SUM() OVER ()` |
| 5 | `50_active_streak` | gaps & islands(`date - ROW_NUMBER` 技巧) |
| 6 | `60_topn_window` | `ROW_NUMBER` / `RANK` / `DENSE_RANK`、分组 TopN、`LAG`、running total |
| 7 | `70_anomaly_rules` | 多条件 `HAVING`、`RANGE BETWEEN ... FOLLOWING` 滑动窗口、布尔打分 |
| 8 | `80_sessionization` | `LAG` 求间隔 + 累计求和打 session 号 |

练习题在 `exercises/`,参考答案在 `solutions/`,文件名一一对应。

## 目录

```
.
├── sql/00_setup.sql        建表 + 清洗
├── exercises/              练习题(仅题面)
├── solutions/              参考答案(已在 DuckDB 上验证)
├── scripts/
│   ├── load_full.sql       全量建库
│   └── make_sample.sql     从全量重新抽样
└── data/
    ├── sample/             自带抽样数据
    └── README.md           数据说明
```

跑完 setup 后库里有两张表:

- `raw_user_behavior` — 原始数据,含脏行,练习 1 用
- `user_behavior` — 清洗后,带 `event_time` / `event_date` / `event_hour` 派生列,其余练习用

## License

代码 MIT。数据集版权归阿里天池所有,使用须遵循 [天池数据集协议](https://tianchi.aliyun.com/dataset/649)。
