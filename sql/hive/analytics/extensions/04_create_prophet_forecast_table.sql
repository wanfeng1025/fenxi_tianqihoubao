USE weather_db;

SET hive.compute.query.using.stats=false;
SET hive.exec.mode.local.auto=true;

DROP TABLE IF EXISTS ads_aqi_prophet_forecast;

CREATE TABLE ads_aqi_prophet_forecast (
    city_name STRING COMMENT '城市名称',
    forecast_month DATE COMMENT '预测月份',
    forecast_aqi DOUBLE COMMENT 'Prophet预测AQI',
    forecast_lower DOUBLE COMMENT '95%预测下界',
    forecast_upper DOUBLE COMMENT '95%预测上界',
    train_start DATE COMMENT '训练数据开始月份',
    train_end DATE COMMENT '训练数据结束月份',
    model_name STRING COMMENT '预测模型',
    generated_at TIMESTAMP COMMENT '预测生成时间'
)
COMMENT '各城市Prophet月度AQI预测结果'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH
'/path/to/aqi_prophet_forecast.tsv'
OVERWRITE INTO TABLE ads_aqi_prophet_forecast;
