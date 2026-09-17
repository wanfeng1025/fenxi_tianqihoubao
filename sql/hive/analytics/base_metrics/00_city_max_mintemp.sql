USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

CREATE TABLE IF NOT EXISTS city_max_mintemp (
    city_name STRING,
    max_temperature INT,
    min_temperature INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE city_max_mintemp
SELECT
    city_name,
    MAX(CAST(max_temperature AS INT)) AS max_temperature,
    MIN(CAST(min_temperature AS INT)) AS min_temperature
FROM weather
WHERE city_name IS NOT NULL
GROUP BY city_name;

SELECT *
FROM city_max_mintemp
ORDER BY city_name;
