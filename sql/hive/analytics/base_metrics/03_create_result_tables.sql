USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;

DROP TABLE IF EXISTS city_rainy_days;

CREATE TABLE city_rainy_days
STORED AS TEXTFILE
AS
SELECT
    city_name,
    COUNT(DISTINCT `date`) AS rainy_days
FROM weather
WHERE city_name IS NOT NULL
  AND `date` IS NOT NULL
  AND (
        day_weather_condition LIKE '%雨%'
        OR night_weather_condition LIKE '%雨%'
      )
GROUP BY city_name;

DROP TABLE IF EXISTS city_best_aqi_top3;

CREATE TABLE city_best_aqi_top3
STORED AS TEXTFILE
AS
SELECT
    city_name,
    `date`,
    aqi_quality_grade,
    aqi_index,
    PM25,
    PM10,
    rn AS city_rank
FROM
(
    SELECT
        city_name,
        `date`,
        aqi_quality_grade,
        aqi_index,
        PM25,
        PM10,
        ROW_NUMBER() OVER (
            PARTITION BY city_name
            ORDER BY
                aqi_index ASC,
                PM25 ASC,
                PM10 ASC,
                `date` ASC
        ) AS rn
    FROM aqi
    WHERE city_name IS NOT NULL
      AND `date` IS NOT NULL
      AND aqi_index IS NOT NULL
) t
WHERE rn <= 3;
