USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=false;

SELECT city_name, month_start, avg_aqi, observation_count
FROM stg_aqi_monthly_2020_2025
ORDER BY city_name, month_start;
