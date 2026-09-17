USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SHOW TABLES;

SELECT COUNT(*) AS grade_rows FROM ads_aqi_grade_distribution;
SELECT COUNT(*) AS rain_rows FROM ads_rain_aqi_compare;
SELECT COUNT(*) AS monthly_rows FROM stg_aqi_monthly_2020_2025;

SELECT city_name, COUNT(*) AS month_count,
       MIN(month_start) AS first_month,
       MAX(month_start) AS last_month
FROM stg_aqi_monthly_2020_2025
GROUP BY city_name
ORDER BY city_name;
