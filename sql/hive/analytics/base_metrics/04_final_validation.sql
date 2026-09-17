USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SHOW TABLES;

SELECT *
FROM city_max_mintemp
ORDER BY city_name;

SELECT *
FROM city_rainy_days
ORDER BY rainy_days DESC, city_name;

SELECT *
FROM city_best_aqi_top3
ORDER BY city_name, city_rank;

SELECT
    city_name,
    COUNT(*) AS top3_count
FROM city_best_aqi_top3
GROUP BY city_name
ORDER BY city_name;
