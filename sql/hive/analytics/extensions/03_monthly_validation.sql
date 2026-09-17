USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    COUNT(*) AS month_count,
    MIN(month_start) AS first_month,
    MAX(month_start) AS last_month,
    MIN(avg_aqi) AS min_avg_aqi,
    MAX(avg_aqi) AS max_avg_aqi
FROM stg_aqi_monthly_2020_2025
GROUP BY city_name
ORDER BY city_name;

SELECT *
FROM stg_aqi_monthly_2020_2025
ORDER BY city_name, month_start;
