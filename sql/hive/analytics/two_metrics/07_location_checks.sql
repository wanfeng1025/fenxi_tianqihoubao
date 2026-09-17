USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;

DESCRIBE FORMATTED continuous_good_air;
DESCRIBE FORMATTED monthly_aqi_predict;
