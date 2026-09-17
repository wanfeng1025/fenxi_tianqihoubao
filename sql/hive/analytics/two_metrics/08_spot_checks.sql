USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    r.city_name,
    r.start_date,
    r.end_date,
    r.consecutive_days,
    DATEDIFF(CAST(r.end_date AS DATE), CAST(r.start_date AS DATE)) + 1 AS calendar_days,
    COUNT(DISTINCT a.`date`) AS source_days,
    MIN(a.aqi_index) AS min_source_aqi,
    MAX(a.aqi_index) AS max_source_aqi
FROM continuous_good_air r
INNER JOIN aqi a
    ON a.city_name = r.city_name
   AND a.`date` BETWEEN CAST(r.start_date AS DATE) AND CAST(r.end_date AS DATE)
GROUP BY r.city_name, r.start_date, r.end_date, r.consecutive_days
ORDER BY r.city_name;

SELECT
    r.city_name,
    r.start_date,
    r.end_date,
    COUNT(DISTINCT a.`date`) AS source_days,
    MAX(a.aqi_index) AS max_source_aqi
FROM continuous_good_air r
INNER JOIN aqi a
    ON a.city_name = r.city_name
   AND a.`date` BETWEEN CAST(r.start_date AS DATE) AND CAST(r.end_date AS DATE)
WHERE r.city_name IN ('南京', '铜陵')
GROUP BY r.city_name, r.start_date, r.end_date
ORDER BY r.city_name;
