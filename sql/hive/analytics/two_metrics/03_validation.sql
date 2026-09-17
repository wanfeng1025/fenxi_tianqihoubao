USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT *
FROM continuous_good_air
ORDER BY consecutive_days DESC, city_name;

SELECT COUNT(*) AS continuous_good_air_rows
FROM continuous_good_air;

SELECT
    city_name,
    start_date,
    end_date,
    consecutive_days,
    DATEDIFF(CAST(end_date AS DATE), CAST(start_date AS DATE)) + 1 AS calendar_days
FROM continuous_good_air
ORDER BY city_name;

SELECT *
FROM monthly_aqi_predict
ORDER BY city_name, month;

SELECT city_name, COUNT(*) AS month_count,
       MIN(month) AS min_month,
       MAX(month) AS max_month,
       MIN(predict_year) AS min_predict_year,
       MAX(predict_year) AS max_predict_year
FROM monthly_aqi_predict
GROUP BY city_name
ORDER BY city_name;

SELECT COUNT(*) AS null_prediction_rows
FROM monthly_aqi_predict
WHERE predict_avg_aqi IS NULL;

SELECT COUNT(*) AS invalid_month_rows
FROM monthly_aqi_predict
WHERE month < 1 OR month > 12;

SELECT COUNT(*) AS negative_prediction_rows
FROM monthly_aqi_predict
WHERE predict_avg_aqi < 0;

SELECT city_name,
       ROUND(AVG(predict_avg_aqi), 2) AS predict_2026_avg_aqi,
       ROUND(MIN(predict_avg_aqi), 2) AS min_predict_aqi,
       ROUND(MAX(predict_avg_aqi), 2) AS max_predict_aqi
FROM monthly_aqi_predict
GROUP BY city_name
ORDER BY predict_2026_avg_aqi;

SELECT city_name, month, predict_avg_aqi
FROM (
    SELECT city_name, month, predict_avg_aqi,
           ROW_NUMBER() OVER (
               PARTITION BY city_name
               ORDER BY predict_avg_aqi ASC, month ASC
           ) AS rn
    FROM monthly_aqi_predict
) t
WHERE rn = 1
ORDER BY city_name;

SELECT city_name, month, predict_avg_aqi
FROM (
    SELECT city_name, month, predict_avg_aqi,
           ROW_NUMBER() OVER (
               PARTITION BY city_name
               ORDER BY predict_avg_aqi DESC, month ASC
           ) AS rn
    FROM monthly_aqi_predict
) t
WHERE rn = 1
ORDER BY city_name;
