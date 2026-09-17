USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    COUNT(DISTINCT `date`) AS rainy_days
FROM weather
WHERE city_name IS NOT NULL
  AND `date` IS NOT NULL
  AND (
        day_weather_condition LIKE '%雨%'
        OR night_weather_condition LIKE '%雨%'
      )
GROUP BY city_name
ORDER BY rainy_days DESC, city_name;
