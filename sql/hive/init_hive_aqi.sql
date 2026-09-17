-- Hive 3.1.2：历史 AQI 数据库与表初始化脚本
-- 仅创建数据库和表，不删除已有对象或数据。

CREATE DATABASE IF NOT EXISTS weather_db
COMMENT '历史天气与空气质量实验数据库';

USE weather_db;

CREATE TABLE IF NOT EXISTS aqi (
    id BIGINT COMMENT '原 MySQL 数据编号',
    city_name STRING COMMENT '城市名称',
    source_city STRING COMMENT 'AQI 数据来源城市',
    `date` DATE COMMENT '日期',
    aqi_quality_grade STRING COMMENT '空气质量等级',
    aqi_index INT COMMENT 'AQI 指数',
    aqi_ranking_day INT COMMENT '当天排名',
    PM25 DECIMAL(10,2) COMMENT 'PM2.5',
    PM10 DECIMAL(10,2) COMMENT 'PM10',
    So2 DECIMAL(10,2) COMMENT 'SO2',
    No2 DECIMAL(10,2) COMMENT 'NO2',
    Co DECIMAL(10,2) COMMENT 'CO',
    O3 DECIMAL(10,2) COMMENT 'O3',
    created_at TIMESTAMP COMMENT '创建时间'
)
COMMENT '历史空气质量 AQI 数据表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;
