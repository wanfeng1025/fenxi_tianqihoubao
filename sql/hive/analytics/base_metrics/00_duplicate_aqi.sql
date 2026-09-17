USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    `date`,
    COUNT(*) AS cnt
FROM aqi
GROUP BY city_name, `date`
HAVING COUNT(*) > 1
LIMIT 20;
