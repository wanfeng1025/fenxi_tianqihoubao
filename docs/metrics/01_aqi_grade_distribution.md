# 01_aqi_grade_distribution

- Hive/MySQL 表：`ads_aqi_grade_distribution`
- 已核验记录数：34
- 指标说明：城市 AQI 等级分布；统计各等级记录数及占比。
- 数据边界：训练型指标使用 2020—2025；2026 年为不完整年度，仅用于预测或观察，不作为完整年度对比。
- 对应 SQL：见 `sql/hive/analytics/` 下的指标脚本；对应 DataX：见 `datax/hdfs_to_mysql/`。
