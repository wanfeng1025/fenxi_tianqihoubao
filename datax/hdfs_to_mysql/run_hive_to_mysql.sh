#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATAX_BIN="/export/servers/datax/bin/datax.py"
LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$LOG_DIR"
cd "$SCRIPT_DIR"

run_job() {
    local job_file="$1"
    local log_file="$LOG_DIR/${job_file%.json}.log"
    echo "开始执行: $job_file"
    python "$DATAX_BIN" "$SCRIPT_DIR/$job_file" 2>&1 | tee "$log_file"
    echo "执行完成: $job_file"
}

run_job "Hive2MySQL_ads_aqi_grade_distribution.json"
run_job "Hive2MySQL_ads_aqi_prophet_forecast.json"
run_job "Hive2MySQL_ads_rain_aqi_compare.json"
run_job "Hive2MySQL_aqi_growth_rate.json"
run_job "Hive2MySQL_city_best_aqi_top3.json"
run_job "Hive2MySQL_city_max_mintemp.json"
run_job "Hive2MySQL_city_rainy_days.json"
run_job "Hive2MySQL_continuous_good_air.json"
run_job "Hive2MySQL_monthly_aqi_predict.json"
run_job "Hive2MySQL_stg_aqi_monthly_2020_2025.json"

echo "全部 Hive -> MySQL DataX 任务执行完成。"
