USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT *
FROM ads_aqi_grade_distribution
ORDER BY city_name, percentage DESC;

SELECT city_name, ROUND(SUM(percentage), 2) AS total_percentage
FROM ads_aqi_grade_distribution
GROUP BY city_name
ORDER BY city_name;
