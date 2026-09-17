-- Hive 3.1.2：历史天气表初始化
CREATE DATABASE IF NOT EXISTS weather_db COMMENT '历史天气与空气质量实验数据库';
USE weather_db;
CREATE TABLE IF NOT EXISTS weather (
    id BIGINT COMMENT '原 MySQL 数据编号',
    city_name STRING COMMENT '城市名称',
    `date` DATE COMMENT '日期',
    day_weather_condition STRING COMMENT '白天天气状况',
    night_weather_condition STRING COMMENT '夜间天气状况',
    max_temperature DECIMAL(5,1) COMMENT '最高温度',
    min_temperature DECIMAL(5,1) COMMENT '最低温度',
    day_wind_direction STRING COMMENT '白天风向',
    night_wind_direction STRING COMMENT '夜间风向',
    created_at TIMESTAMP COMMENT '创建时间'
)
COMMENT '历史天气数据表'
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;
