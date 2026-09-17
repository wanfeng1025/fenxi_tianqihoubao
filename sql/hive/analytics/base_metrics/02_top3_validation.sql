USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT
    city_name,
    COUNT(*) AS top3_count
FROM
(
    SELECT
        city_name,
        `date`,
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
WHERE rn <= 3
GROUP BY city_name
ORDER BY city_name;
