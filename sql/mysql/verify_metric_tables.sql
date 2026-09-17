USE weather_db;

SELECT DATABASE() AS current_database;
SHOW TABLES;

SELECT 'ads_aqi_grade_distribution' AS table_name, COUNT(*) AS row_count FROM ads_aqi_grade_distribution
UNION ALL SELECT 'ads_aqi_prophet_forecast', COUNT(*) FROM ads_aqi_prophet_forecast
UNION ALL SELECT 'ads_rain_aqi_compare', COUNT(*) FROM ads_rain_aqi_compare
UNION ALL SELECT 'aqi_growth_rate', COUNT(*) FROM aqi_growth_rate
UNION ALL SELECT 'city_best_aqi_top3', COUNT(*) FROM city_best_aqi_top3
UNION ALL SELECT 'city_max_mintemp', COUNT(*) FROM city_max_mintemp
UNION ALL SELECT 'city_rainy_days', COUNT(*) FROM city_rainy_days
UNION ALL SELECT 'continuous_good_air', COUNT(*) FROM continuous_good_air
UNION ALL SELECT 'monthly_aqi_predict', COUNT(*) FROM monthly_aqi_predict
UNION ALL SELECT 'stg_aqi_monthly_2020_2025', COUNT(*) FROM stg_aqi_monthly_2020_2025;
