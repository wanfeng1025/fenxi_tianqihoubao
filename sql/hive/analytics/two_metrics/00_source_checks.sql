USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SHOW TABLES;
DESCRIBE aqi;
DESCRIBE weather;

SELECT COUNT(*) AS aqi_count FROM aqi;
SELECT COUNT(*) AS weather_count FROM weather;

SELECT MIN(`date`) AS min_date, MAX(`date`) AS max_date FROM aqi;
SELECT MIN(`date`) AS min_date, MAX(`date`) AS max_date FROM weather;

SELECT DISTINCT city_name FROM aqi ORDER BY city_name;
SELECT DISTINCT city_name FROM weather ORDER BY city_name;

SELECT city_name, `date`, COUNT(*) AS cnt
FROM aqi
GROUP BY city_name, `date`
HAVING COUNT(*) > 1
LIMIT 30;

SELECT city_name, `date`, COUNT(*) AS cnt
FROM weather
GROUP BY city_name, `date`
HAVING COUNT(*) > 1
LIMIT 30;

SELECT
    SUM(CASE WHEN max_temperature IS NULL OR min_temperature IS NULL THEN 1 ELSE 0 END) AS null_temperature_rows,
    COUNT(*) AS weather_rows
FROM weather;
