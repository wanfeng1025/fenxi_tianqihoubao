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

SELECT city_name, COUNT(*) AS cnt
FROM aqi
GROUP BY city_name
ORDER BY city_name;

SELECT city_name, COUNT(*) AS cnt
FROM weather
GROUP BY city_name
ORDER BY city_name;

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

SELECT aqi_quality_grade, COUNT(*) AS cnt
FROM aqi
WHERE aqi_quality_grade IS NOT NULL
GROUP BY aqi_quality_grade
ORDER BY cnt DESC;

SELECT day_weather_condition, COUNT(*) AS cnt
FROM weather
GROUP BY day_weather_condition
ORDER BY cnt DESC;

SELECT night_weather_condition, COUNT(*) AS cnt
FROM weather
GROUP BY night_weather_condition
ORDER BY cnt DESC;
