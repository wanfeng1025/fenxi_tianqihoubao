USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    MONTH(`date`) AS month,
    COUNT(DISTINCT YEAR(`date`)) AS training_year_count,
    MIN(YEAR(`date`)) AS first_training_year,
    MAX(YEAR(`date`)) AS last_training_year
FROM aqi
WHERE YEAR(`date`) BETWEEN 2020 AND 2025
  AND city_name IS NOT NULL
  AND `date` IS NOT NULL
  AND aqi_index IS NOT NULL
GROUP BY city_name, MONTH(`date`)
ORDER BY city_name, month;
