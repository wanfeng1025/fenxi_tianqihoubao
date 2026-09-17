USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    max_temperature,
    min_temperature
FROM city_max_mintemp
ORDER BY city_name;

SELECT
    city_name,
    rainy_days
FROM city_rainy_days
ORDER BY rainy_days DESC, city_name;

SELECT
    city_name,
    `date`,
    aqi_quality_grade,
    aqi_index,
    PM25,
    PM10,
    city_rank
FROM city_best_aqi_top3
ORDER BY city_name, city_rank;
