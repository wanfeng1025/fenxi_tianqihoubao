USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

DROP TABLE IF EXISTS ads_aqi_grade_distribution;

CREATE TABLE ads_aqi_grade_distribution
STORED AS TEXTFILE
AS
SELECT
    city_name,
    aqi_quality_grade,
    grade_count,
    SUM(grade_count) OVER (PARTITION BY city_name) AS total_count,
    ROUND(
        grade_count * 100.0 /
        SUM(grade_count) OVER (PARTITION BY city_name),
        2
    ) AS percentage
FROM (
    SELECT
        city_name,
        aqi_quality_grade,
        COUNT(*) AS grade_count
    FROM aqi
    WHERE city_name IS NOT NULL
      AND aqi_quality_grade IS NOT NULL
    GROUP BY city_name, aqi_quality_grade
) t;
