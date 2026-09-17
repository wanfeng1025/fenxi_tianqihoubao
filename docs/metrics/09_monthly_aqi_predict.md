# 09_monthly_aqi_predict

- Hive/MySQL 表：`monthly_aqi_predict`
- 已核验记录数：72
- 指标说明：按城市和月份预测 2026 年 AQI，并保留 trend_slope 趋势斜率。
- 数据边界：训练型指标使用 2020—2025；2026 年为不完整年度，仅用于预测或观察，不作为完整年度对比。
- 对应 SQL：见 `sql/hive/analytics/` 下的指标脚本；对应 DataX：见 `datax/hdfs_to_mysql/`。
