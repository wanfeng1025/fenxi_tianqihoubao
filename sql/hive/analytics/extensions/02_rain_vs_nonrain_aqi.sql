USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

DROP TABLE IF EXISTS ads_rain_aqi_compare;

CREATE TABLE ads_rain_aqi_compare
STORED AS TEXTFILE
AS
WITH aqi_daily AS (
    SELECT
        city_name,
        `date`,
        AVG(CAST(aqi_index AS DOUBLE)) AS daily_aqi
    FROM aqi
    WHERE city_name IS NOT NULL
      AND `date` IS NOT NULL
      AND aqi_index IS NOT NULL
    GROUP BY city_name, `date`
),
weather_daily AS (
    SELECT
        city_name,
        `date`,
        MAX(
            CASE
                WHEN day_weather_condition LIKE '%雨%'
                  OR night_weather_condition LIKE '%雨%'
                THEN 1
                ELSE 0
            END
        ) AS is_rainy
    FROM weather
    WHERE city_name IS NOT NULL
      AND `date` IS NOT NULL
    GROUP BY city_name, `date`
),
joined_data AS (
    SELECT
        a.city_name,
        a.`date`,
        a.daily_aqi,
        w.is_rainy
    FROM aqi_daily a
    INNER JOIN weather_daily w
        ON a.city_name = w.city_name
       AND a.`date` = w.`date`
)
SELECT
    city_name,
    SUM(CASE WHEN is_rainy = 1 THEN 1 ELSE 0 END) AS rainy_days,
    ROUND(AVG(CASE WHEN is_rainy = 1 THEN daily_aqi END), 2) AS rainy_avg_aqi,
    SUM(CASE WHEN is_rainy = 0 THEN 1 ELSE 0 END) AS non_rainy_days,
    ROUND(AVG(CASE WHEN is_rainy = 0 THEN daily_aqi END), 2) AS non_rainy_avg_aqi,
    ROUND(
        AVG(CASE WHEN is_rainy = 0 THEN daily_aqi END)
        - AVG(CASE WHEN is_rainy = 1 THEN daily_aqi END),
        2
    ) AS aqi_difference,
    ROUND(
        (
            AVG(CASE WHEN is_rainy = 0 THEN daily_aqi END)
            - AVG(CASE WHEN is_rainy = 1 THEN daily_aqi END)
        ) * 100.0 /
        AVG(CASE WHEN is_rainy = 0 THEN daily_aqi END),
        2
    ) AS rainy_reduction_pct
FROM joined_data
GROUP BY city_name;
