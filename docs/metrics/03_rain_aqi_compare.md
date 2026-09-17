# 03_rain_aqi_compare

- Hive/MySQL 表：`ads_rain_aqi_compare`
- 已核验记录数：6
- 指标说明：比较各城市雨天与非雨天的平均 AQI。雨天定义为白天或夜间天气包含“雨”。
- 数据边界：训练型指标使用 2020—2025；2026 年为不完整年度，仅用于预测或观察，不作为完整年度对比。
- 对应 SQL：见 `sql/hive/analytics/` 下的指标脚本；对应 DataX：见 `datax/hdfs_to_mysql/`。
