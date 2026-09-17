USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

CREATE TABLE IF NOT EXISTS aqi_growth_rate (
    city_name       STRING,
    `year`          INT,
    current_avg_aqi DOUBLE,
    aqi_growth_rate DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

WITH filtered_aqi AS (
    SELECT
        city_name,
        CAST(`date` AS DATE) AS aqi_date,
        CAST(aqi_index AS DOUBLE) AS aqi_value
    FROM aqi
    WHERE YEAR(CAST(`date` AS DATE)) BETWEEN 2020 AND 2025
),
yearly_avg AS (
    SELECT
        city_name,
        YEAR(aqi_date) AS `year`,
        ROUND(AVG(aqi_value), 2) AS current_avg_aqi
    FROM filtered_aqi
    GROUP BY city_name, YEAR(aqi_date)
),
yearly_with_prev AS (
    SELECT
        city_name,
        `year`,
        current_avg_aqi,
        LAG(current_avg_aqi, 1, NULL)
            OVER (
                PARTITION BY city_name
                ORDER BY `year`
            ) AS prev_avg_aqi
    FROM yearly_avg
)
INSERT OVERWRITE TABLE aqi_growth_rate
SELECT
    city_name,
    `year`,
    current_avg_aqi,
    CASE
        WHEN prev_avg_aqi IS NULL OR prev_avg_aqi = 0 THEN NULL
        ELSE ROUND(
            ((current_avg_aqi - prev_avg_aqi) / prev_avg_aqi) * 100,
            2
        )
    END AS aqi_growth_rate
FROM yearly_with_prev;

SELECT
    city_name,
    `year`,
    current_avg_aqi,
    aqi_growth_rate
FROM aqi_growth_rate
ORDER BY city_name, `year`;
