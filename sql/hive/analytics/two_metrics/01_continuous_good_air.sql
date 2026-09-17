USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.auto.convert.join=false;
SET hive.cli.print.header=true;

DROP TABLE IF EXISTS wtm_aqi_daily;
DROP TABLE IF EXISTS wtm_weather_daily;
DROP TABLE IF EXISTS wtm_joined_good_days;
DROP TABLE IF EXISTS wtm_numbered_good_days;
DROP TABLE IF EXISTS wtm_good_segments;
DROP TABLE IF EXISTS continuous_good_air;

CREATE TABLE wtm_aqi_daily
STORED AS TEXTFILE
AS
SELECT
    city_name,
    `date`,
    AVG(CAST(aqi_index AS DOUBLE)) AS daily_aqi
FROM aqi
WHERE city_name IS NOT NULL
  AND `date` IS NOT NULL
  AND aqi_index IS NOT NULL
GROUP BY city_name, `date`;

CREATE TABLE wtm_weather_daily
STORED AS TEXTFILE
AS
SELECT
    city_name,
    `date`,
    AVG(CAST(max_temperature AS DOUBLE)) AS max_temperature,
    AVG(CAST(min_temperature AS DOUBLE)) AS min_temperature
FROM weather
WHERE city_name IS NOT NULL
  AND `date` IS NOT NULL
  AND max_temperature IS NOT NULL
  AND min_temperature IS NOT NULL
GROUP BY city_name, `date`;

CREATE TABLE wtm_joined_good_days
STORED AS TEXTFILE
AS
SELECT
    a.city_name,
    a.`date`,
    a.daily_aqi,
    (w.max_temperature + w.min_temperature) / 2.0 AS avg_temperature
FROM wtm_aqi_daily a
INNER JOIN wtm_weather_daily w
    ON a.city_name = w.city_name
   AND a.`date` = w.`date`
WHERE a.daily_aqi <= 50;

CREATE TABLE wtm_numbered_good_days
STORED AS TEXTFILE
AS
SELECT
    city_name,
    `date`,
    avg_temperature,
    DATEDIFF(`date`, CAST('2020-01-01' AS DATE))
        - CAST(ROW_NUMBER() OVER (
            PARTITION BY city_name
            ORDER BY `date`
          ) AS INT) AS group_key
FROM wtm_joined_good_days;

CREATE TABLE wtm_good_segments
STORED AS TEXTFILE
AS
SELECT
    city_name,
    MIN(`date`) AS start_date,
    MAX(`date`) AS end_date,
    CAST(COUNT(*) AS INT) AS consecutive_days,
    ROUND(AVG(avg_temperature), 1) AS avg_temperature
FROM wtm_numbered_good_days
GROUP BY city_name, group_key;

CREATE TABLE continuous_good_air (
    city_name STRING,
    start_date STRING,
    end_date STRING,
    consecutive_days INT,
    avg_temperature DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE continuous_good_air
SELECT
    city_name,
    CAST(start_date AS STRING) AS start_date,
    CAST(end_date AS STRING) AS end_date,
    consecutive_days,
    avg_temperature
FROM (
    SELECT
        city_name,
        start_date,
        end_date,
        consecutive_days,
        avg_temperature,
        ROW_NUMBER() OVER (
            PARTITION BY city_name
            ORDER BY consecutive_days DESC, start_date ASC
        ) AS rn
    FROM wtm_good_segments
) ranked
WHERE rn = 1;

DROP TABLE wtm_aqi_daily;
DROP TABLE wtm_weather_daily;
DROP TABLE wtm_joined_good_days;
DROP TABLE wtm_numbered_good_days;
DROP TABLE wtm_good_segments;
