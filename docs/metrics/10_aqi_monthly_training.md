# 10_aqi_monthly_training

- Hive/MySQL 表：`stg_aqi_monthly_2020_2025`
- 已核验记录数：432
- 指标说明：六城市 2020—2025 月度 AQI 训练数据，共 72 个月/城市。
- 数据边界：训练型指标使用 2020—2025；2026 年为不完整年度，仅用于预测或观察，不作为完整年度对比。
- 对应 SQL：见 `sql/hive/analytics/` 下的指标脚本；对应 DataX：见 `datax/hdfs_to_mysql/`。
