CREATE DATABASE IF NOT EXISTS weather_db
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE weather_db;

CREATE TABLE IF NOT EXISTS ads_aqi_grade_distribution (
    city_name          VARCHAR(32) NOT NULL,
    aqi_quality_grade  VARCHAR(32) NOT NULL,
    grade_count        BIGINT NOT NULL,
    total_count        BIGINT NOT NULL,
    percentage         DECIMAL(26,2) NOT NULL,
    KEY idx_grade_city (city_name),
    KEY idx_grade_name (aqi_quality_grade)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ads_aqi_prophet_forecast (
    city_name       VARCHAR(32) NOT NULL,
    forecast_month  DATE NOT NULL,
    forecast_aqi    DOUBLE NULL,
    forecast_lower  DOUBLE NULL,
    forecast_upper  DOUBLE NULL,
    train_start     DATE NOT NULL,
    train_end       DATE NOT NULL,
    model_name      VARCHAR(32) NOT NULL,
    generated_at    DATETIME NULL,
    KEY idx_prophet_city_month (city_name, forecast_month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ads_rain_aqi_compare (
    city_name           VARCHAR(32) NOT NULL,
    rainy_days          BIGINT NOT NULL,
    rainy_avg_aqi       DOUBLE NULL,
    non_rainy_days      BIGINT NOT NULL,
    non_rainy_avg_aqi   DOUBLE NULL,
    aqi_difference      DOUBLE NULL,
    rainy_reduction_pct DOUBLE NULL,
    UNIQUE KEY uk_rain_city (city_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aqi_growth_rate (
    city_name         VARCHAR(32) NOT NULL,
    `year`            INT NOT NULL,
    current_avg_aqi   DOUBLE NULL,
    aqi_growth_rate   DOUBLE NULL,
    UNIQUE KEY uk_growth_city_year (city_name, `year`),
    KEY idx_growth_year (`year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS city_best_aqi_top3 (
    city_name          VARCHAR(32) NOT NULL,
    `date`             DATE NOT NULL,
    aqi_quality_grade  VARCHAR(32) NULL,
    aqi_index          INT NULL,
    pm25               DECIMAL(10,2) NULL,
    pm10               DECIMAL(10,2) NULL,
    city_rank          INT NOT NULL,
    UNIQUE KEY uk_best_aqi_city_date (city_name, `date`),
    KEY idx_best_aqi_rank (city_name, city_rank)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS city_max_mintemp (
    city_name       VARCHAR(32) NOT NULL,
    max_temperature INT NULL,
    min_temperature INT NULL,
    UNIQUE KEY uk_temp_city (city_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS city_rainy_days (
    city_name  VARCHAR(32) NOT NULL,
    rainy_days BIGINT NOT NULL,
    UNIQUE KEY uk_rainy_days_city (city_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS continuous_good_air (
    city_name        VARCHAR(32) NOT NULL,
    start_date       VARCHAR(10) NOT NULL,
    end_date         VARCHAR(10) NOT NULL,
    consecutive_days INT NOT NULL,
    avg_temperature  DOUBLE NULL,
    UNIQUE KEY uk_good_air_city_period (city_name, start_date, end_date),
    KEY idx_good_air_days (consecutive_days)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS monthly_aqi_predict (
    city_name        VARCHAR(32) NOT NULL,
    `month`          INT NOT NULL,
    predict_year     INT NOT NULL,
    predict_avg_aqi  DOUBLE NULL,
    trend_slope      DOUBLE NULL,
    UNIQUE KEY uk_predict_city_month_year (city_name, `month`, predict_year),
    KEY idx_predict_year (predict_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stg_aqi_monthly_2020_2025 (
    city_name         VARCHAR(32) NOT NULL,
    month_start       VARCHAR(10) NOT NULL,
    avg_aqi           DOUBLE NULL,
    observation_count BIGINT NOT NULL,
    UNIQUE KEY uk_monthly_city_month (city_name, month_start),
    KEY idx_monthly_month (month_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
