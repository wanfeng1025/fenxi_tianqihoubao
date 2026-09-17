# 04_aqi_growth_rate

- Hive/MySQL 表：`aqi_growth_rate`
- 已核验记录数：36
- 指标说明：各城市年度平均 AQI 及相对上一年的增长率。
- 数据边界：训练型指标使用 2020—2025；2026 年为不完整年度，仅用于预测或观察，不作为完整年度对比。
- 对应 SQL：见 `sql/hive/analytics/` 下的指标脚本；对应 DataX：见 `datax/hdfs_to_mysql/`。
