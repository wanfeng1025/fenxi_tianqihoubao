USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT *
FROM ads_rain_aqi_compare
ORDER BY city_name;

SELECT COUNT(*) AS aqi_daily_rows
FROM (
    SELECT city_name, `date`
    FROM aqi
    WHERE city_name IS NOT NULL
      AND `date` IS NOT NULL
      AND aqi_index IS NOT NULL
    GROUP BY city_name, `date`
) t;

SELECT COUNT(*) AS joined_daily_rows
FROM (
    SELECT a.city_name, a.`date`
    FROM (
        SELECT city_name, `date`
        FROM aqi
        WHERE city_name IS NOT NULL
          AND `date` IS NOT NULL
          AND aqi_index IS NOT NULL
        GROUP BY city_name, `date`
    ) a
    INNER JOIN (
        SELECT city_name, `date`
        FROM weather
        WHERE city_name IS NOT NULL
          AND `date` IS NOT NULL
        GROUP BY city_name, `date`
    ) w
      ON a.city_name = w.city_name AND a.`date` = w.`date`
) t;
