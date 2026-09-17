USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

DROP TABLE IF EXISTS monthly_aqi_predict;

CREATE TABLE monthly_aqi_predict (
    city_name STRING,
    month INT,
    predict_year INT,
    predict_avg_aqi DOUBLE,
    trend_slope DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

WITH yearly_monthly AS (
    SELECT
        city_name,
        MONTH(`date`) AS month,
        YEAR(`date`) AS x,
        ROUND(AVG(CAST(aqi_index AS DOUBLE)), 2) AS y
    FROM aqi
    WHERE YEAR(`date`) BETWEEN 2020 AND 2025
      AND city_name IS NOT NULL
      AND `date` IS NOT NULL
      AND aqi_index IS NOT NULL
    GROUP BY city_name, MONTH(`date`), YEAR(`date`)
),
regression_stats AS (
    SELECT
        city_name,
        month,
        COUNT(*) AS n,
        SUM(CAST(x AS DOUBLE)) AS sx,
        SUM(y) AS sy,
        SUM(CAST(x AS DOUBLE) * CAST(x AS DOUBLE)) AS sxx,
        SUM(CAST(x AS DOUBLE) * y) AS sxy
    FROM yearly_monthly
    GROUP BY city_name, month
    HAVING COUNT(*) >= 2
),
regression_values AS (
    SELECT
        city_name,
        month,
        n,
        (n * sxx - sx * sx) AS denominator,
        (n * sxy - sx * sy) / (n * sxx - sx * sx) AS slope,
        (sy * sxx - sx * sxy) / (n * sxx - sx * sx) AS intercept
    FROM regression_stats
    WHERE (n * sxx - sx * sx) <> 0
)
INSERT OVERWRITE TABLE monthly_aqi_predict
SELECT
    city_name,
    month,
    2026 AS predict_year,
    ROUND(intercept + slope * 2026, 2) AS predict_avg_aqi,
    ROUND(slope, 6) AS trend_slope
FROM regression_values;
