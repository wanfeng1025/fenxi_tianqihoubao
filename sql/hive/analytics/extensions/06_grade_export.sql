USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT *
FROM ads_aqi_grade_distribution
ORDER BY city_name, percentage DESC;
