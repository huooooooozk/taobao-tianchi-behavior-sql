# 数据

## sample/user_behavior_sample.csv

仓库自带的抽样子集,约 30 万行 / 11 MB,`sql/00_setup.sql` 默认就读它。

抽样规则:取 `user_id % 330 = 1` 的用户、保留其全部行为(含越界时间戳脏数据,供清洗练习用)。约 2996 个用户、4479 个类目。

## 全量

完整数据集约 1 亿行 / 3.67 GB,需自行从阿里天池下载:<https://tianchi.aliyun.com/dataset/649>。

把 `UserBehavior.csv`(无表头)放到本目录,然后:

```bash
duckdb taobao_full.db < scripts/load_full.sql        # 全量建库
duckdb < scripts/make_sample.sql                     # 或重新生成抽样
```

## 字段

| 列 | 含义 |
|---|---|
| user_id | 用户 ID(脱敏) |
| item_id | 商品 ID |
| category_id | 商品类目 ID |
| behavior_type | `pv` 点击 / `cart` 加购 / `fav` 收藏 / `buy` 购买 |
| ts | 行为时间戳(Unix 秒,UTC) |

时间范围:北京时间 2017-11-25 ~ 2017-12-03。
