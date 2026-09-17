USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

WITH aqi_daily AS (
    SELECT city_name, `date`, AVG(CAST(aqi_index AS DOUBLE)) AS daily_aqi
    FROM aqi
    WHERE city_name IS NOT NULL AND `date` IS NOT NULL AND aqi_index IS NOT NULL
    GROUP BY city_name, `date`
),
weather_daily AS (
    SELECT city_name, `date`,
           AVG(CAST(max_temperature AS DOUBLE)) AS max_temperature,
           AVG(CAST(min_temperature AS DOUBLE)) AS min_temperature
    FROM weather
    WHERE city_name IS NOT NULL AND `date` IS NOT NULL
      AND max_temperature IS NOT NULL AND min_temperature IS NOT NULL
    GROUP BY city_name, `date`
),
joined_daily AS (
    SELECT a.city_name, a.`date`, a.daily_aqi,
           (w.max_temperature + w.min_temperature) / 2.0 AS avg_temperature
    FROM aqi_daily a
    JOIN weather_daily w ON a.city_name = w.city_name AND a.`date` = w.`date`
),
good_days AS (
    SELECT city_name, `date`, avg_temperature,
           ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY `date`) AS rn
    FROM joined_daily
    WHERE daily_aqi <= 50
),
numbered_good_days AS (
    SELECT city_name, `date`, avg_temperature,
           date_sub(`date`, CAST(rn AS INT)) AS group_date
    FROM good_days
)
SELECT city_name, group_date,
       MIN(`date`) AS start_date,
       MAX(`date`) AS end_date,
       COUNT(*) AS consecutive_days,
       ROUND(AVG(avg_temperature), 1) AS avg_temperature
FROM numbered_good_days
GROUP BY city_name, group_date
LIMIT 20;
