USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT COUNT(*) AS forecast_rows,
       COUNT(DISTINCT city_name) AS forecast_city_count,
       MIN(forecast_month) AS first_forecast_month,
       MAX(forecast_month) AS last_forecast_month
FROM ads_aqi_prophet_forecast;

SELECT COUNT(*) AS invalid_interval_rows
FROM ads_aqi_prophet_forecast
WHERE forecast_lower > forecast_aqi
   OR forecast_upper < forecast_aqi;

SELECT COUNT(*) AS null_count
FROM ads_aqi_prophet_forecast
WHERE city_name IS NULL
   OR forecast_month IS NULL
   OR forecast_aqi IS NULL
   OR forecast_lower IS NULL
   OR forecast_upper IS NULL;

SELECT city_name,
       COUNT(*) AS forecast_months,
       MIN(forecast_month) AS first_month,
       MAX(forecast_month) AS last_month
FROM ads_aqi_prophet_forecast
GROUP BY city_name
ORDER BY city_name;
