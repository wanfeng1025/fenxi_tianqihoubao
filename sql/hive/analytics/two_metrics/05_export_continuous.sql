USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

SELECT *
FROM continuous_good_air
ORDER BY consecutive_days DESC, city_name;
