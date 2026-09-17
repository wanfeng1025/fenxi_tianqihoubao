USE weather_db;
SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;
SET hive.cli.print.header=true;

DESCRIBE ads_aqi_grade_distribution;
DESCRIBE ads_aqi_prophet_forecast;
DESCRIBE ads_rain_aqi_compare;
DESCRIBE aqi_growth_rate;
DESCRIBE city_best_aqi_top3;
DESCRIBE city_max_mintemp;
DESCRIBE city_rainy_days;
DESCRIBE continuous_good_air;
DESCRIBE monthly_aqi_predict;
DESCRIBE stg_aqi_monthly_2020_2025;

SELECT 'ads_aqi_grade_distribution' AS table_name, COUNT(*) AS row_count FROM ads_aqi_grade_distribution;
SELECT 'ads_aqi_prophet_forecast' AS table_name, COUNT(*) AS row_count FROM ads_aqi_prophet_forecast;
SELECT 'ads_rain_aqi_compare' AS table_name, COUNT(*) AS row_count FROM ads_rain_aqi_compare;
SELECT 'aqi_growth_rate' AS table_name, COUNT(*) AS row_count FROM aqi_growth_rate;
SELECT 'city_best_aqi_top3' AS table_name, COUNT(*) AS row_count FROM city_best_aqi_top3;
SELECT 'city_max_mintemp' AS table_name, COUNT(*) AS row_count FROM city_max_mintemp;
SELECT 'city_rainy_days' AS table_name, COUNT(*) AS row_count FROM city_rainy_days;
SELECT 'continuous_good_air' AS table_name, COUNT(*) AS row_count FROM continuous_good_air;
SELECT 'monthly_aqi_predict' AS table_name, COUNT(*) AS row_count FROM monthly_aqi_predict;
SELECT 'stg_aqi_monthly_2020_2025' AS table_name, COUNT(*) AS row_count FROM stg_aqi_monthly_2020_2025;
