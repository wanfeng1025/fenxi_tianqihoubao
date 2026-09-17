USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    COUNT(DISTINCT `date`) AS total_days
FROM weather
GROUP BY city_name
ORDER BY city_name;
