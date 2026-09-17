# 02_aqi_prophet_forecast

- Hive/MySQL 表：`ads_aqi_prophet_forecast`
- 已核验记录数：72
- 指标说明：基于 2020—2025 月度数据的 2026 月度 Prophet 预测，保留 95% 区间。
- 数据边界：训练型指标使用 2020—2025；2026 年为不完整年度，仅用于预测或观察，不作为完整年度对比。
- 对应 SQL：见 `sql/hive/analytics/` 下的指标脚本；对应 DataX：见 `datax/hdfs_to_mysql/`。
