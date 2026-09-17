USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

DESCRIBE ads_aqi_prophet_forecast;

SELECT *
FROM ads_aqi_prophet_forecast
ORDER BY city_name, forecast_month;

SELECT
    city_name,
    COUNT(*) AS forecast_months,
    MIN(forecast_month) AS first_month,
    MAX(forecast_month) AS last_month,
    ROUND(MIN(forecast_aqi), 2) AS min_forecast_aqi,
    ROUND(MAX(forecast_aqi), 2) AS max_forecast_aqi,
    ROUND(AVG(forecast_aqi), 2) AS avg_forecast_aqi
FROM ads_aqi_prophet_forecast
GROUP BY city_name
ORDER BY city_name;

SELECT *
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
