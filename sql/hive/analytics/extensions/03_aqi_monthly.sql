USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

DROP TABLE IF EXISTS stg_aqi_monthly_2020_2025;

CREATE TABLE stg_aqi_monthly_2020_2025
STORED AS TEXTFILE
AS
SELECT
    city_name,
    CONCAT(
        SUBSTR(CAST(`date` AS STRING), 1, 7),
        '-01'
    ) AS month_start,
    ROUND(AVG(CAST(aqi_index AS DOUBLE)), 4) AS avg_aqi,
    COUNT(*) AS observation_count
FROM aqi
WHERE city_name IS NOT NULL
  AND `date` IS NOT NULL
  AND aqi_index IS NOT NULL
  AND `date` >= '2020-01-01'
  AND `date` < '2026-01-01'
GROUP BY
    city_name,
    CONCAT(SUBSTR(CAST(`date` AS STRING), 1, 7), '-01');
