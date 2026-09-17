USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    `date`,
    day_weather_condition,
    night_weather_condition
FROM weather
WHERE city_name = '南京'
  AND (
       day_weather_condition LIKE '%雨%'
       OR night_weather_condition LIKE '%雨%'
      )
ORDER BY `date`
LIMIT 30;
