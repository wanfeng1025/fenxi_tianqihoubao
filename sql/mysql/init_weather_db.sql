-- 历史天气与空气质量实验数据库初始化脚本
-- 可重复执行；不会删除已有数据。

CREATE DATABASE IF NOT EXISTS weather_db
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE weather_db;

CREATE TABLE IF NOT EXISTS history_weather (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    `date` DATE NOT NULL,
    day_weather_condition VARCHAR(50) NULL,
    night_weather_condition VARCHAR(50) NULL,
    max_temperature DECIMAL(5,1) NULL,
    min_temperature DECIMAL(5,1) NULL,
    day_wind_direction VARCHAR(100) NULL,
    night_wind_direction VARCHAR(100) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_weather_city_date (city_name, `date`),
    KEY idx_weather_date (`date`),
    KEY idx_weather_city (city_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS history_aqi (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    source_city VARCHAR(50) NULL,
    `date` DATE NOT NULL,
    aqi_quality_grade VARCHAR(30) NULL,
    aqi_index INT NULL,
    aqi_ranking_day INT NULL,
    PM25 DECIMAL(10,2) NULL,
    PM10 DECIMAL(10,2) NULL,
    So2 DECIMAL(10,2) NULL,
    No2 DECIMAL(10,2) NULL,
    Co DECIMAL(10,2) NULL,
    O3 DECIMAL(10,2) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_aqi_city_date (city_name, `date`),
    KEY idx_aqi_date (`date`),
    KEY idx_aqi_city (city_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 兼容 MySQL 8.0.44：仅在字段不存在时补充来源字段。
SET @source_city_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'history_aqi'
      AND COLUMN_NAME = 'source_city'
);
SET @add_source_city_sql := IF(
    @source_city_exists = 0,
    'ALTER TABLE history_aqi ADD COLUMN source_city VARCHAR(50) NULL AFTER city_name',
    'SELECT 1'
);
PREPARE add_source_city_stmt FROM @add_source_city_sql;
EXECUTE add_source_city_stmt;
DEALLOCATE PREPARE add_source_city_stmt;
