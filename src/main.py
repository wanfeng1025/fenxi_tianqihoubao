"""历史天气 + AQI 数据采集入口。"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime
import logging
from pathlib import Path
import sys
import time

from config import AQI_SOURCE_CITY_MAP, CITY_NAME_MAP, LOG_DIR, MAX_WORKERS, MONTHS, YEARS
from crawler import (
    NoDataError,
    ParseError,
    aqi_url,
    fetch_html,
    parse_aqi,
    parse_weather,
    save_debug_html,
    weather_url,
)
from db import clear_tables, get_connection, upsert_aqi, upsert_weather


@dataclass(frozen=True)
class Task:
    city: str
    city_name: str
    year: int
    month: int


def build_tasks(test: bool, small_test: bool) -> list[Task]:
    if test:
        return [Task("nanjing", "南京", 2024, 6)]
    if small_test:
        return [
            Task(city, CITY_NAME_MAP[city], year, month)
            for city in ("nanjing", "hefei")
            for year, month in ((2024, 6), (2024, 7))
        ]
    return [
        Task(city, city_name, year, month)
        for city, city_name in CITY_NAME_MAP.items()
        for year in YEARS
        for month in MONTHS
    ]


def setup_logging() -> tuple[logging.Logger, Path]:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOG_DIR / f"crawler_{datetime.now():%Y%m%d_%H%M%S}.log"
    logger = logging.getLogger("weather_crawler")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    formatter = logging.Formatter("%(message)s")
    console = logging.StreamHandler(sys.stdout)
    console.setFormatter(formatter)
    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_handler.setFormatter(formatter)
    logger.addHandler(console)
    logger.addHandler(file_handler)
    logger.propagate = False
    return logger, log_path


def _process_category(task: Task, kind: str, connection, logger) -> tuple[str, int, str]:
    source_city = AQI_SOURCE_CITY_MAP.get(task.city, task.city)
    source_name = CITY_NAME_MAP.get(source_city, source_city)
    category_name = "历史天气" if kind == "weather" else "AQI"
    source_note = f"（来源：{source_name}）" if kind == "aqi" and source_name != task.city_name else ""
    label = f"{task.city_name} {task.year}-{task.month:02d} {category_name}{source_note}"
    logger.info("[开始] %s", label)
    url = weather_url(task.city, task.year, task.month) if kind == "weather" else aqi_url(source_city, task.year, task.month)
    fetched = fetch_html(url, label, logger)
    if fetched.status == "SKIP":
        logger.info("[跳过] %s：%s", label, fetched.reason)
        return kind, 0, "skip"
    if fetched.status != "OK":
        logger.error("[失败] %s：%s URL=%s", label, fetched.reason, url)
        return kind, 0, "failed"
    try:
        rows = (
            parse_weather(fetched.text, task.city_name, task.year, task.month)
            if kind == "weather"
            else parse_aqi(fetched.text, task.city_name, task.year, task.month, source_name)
        )
    except NoDataError as exc:
        logger.info("[跳过] %s：%s", label, exc)
        return kind, 0, "skip"
    except ParseError as exc:
        debug_path = save_debug_html(kind, task.city, task.year, task.month, fetched.text)
        logger.error("[解析失败] %s：%s URL=%s 调试文件=%s", label, exc, url, debug_path)
        return kind, 0, "failed"
    try:
        count = upsert_weather(connection, rows) if kind == "weather" else upsert_aqi(connection, rows)
        logger.info("[成功] %s 数据存储完成，共 %s 条", label, count)
        return kind, count, "success"
    except Exception as exc:
        logger.exception("[失败] %s 写入 MySQL 失败：%s", label, exc)
        return kind, 0, "failed"


def process_task(task: Task, logger) -> dict:
    result = {
        "weather_status": "failed", "aqi_status": "failed",
        "weather_count": 0, "aqi_count": 0,
    }
    connection = None
    try:
        connection = get_connection()
        for kind in ("weather", "aqi"):
            category, count, status = _process_category(task, kind, connection, logger)
            result[f"{category}_status"] = status
            result[f"{category}_count"] = count
    except Exception as exc:
        logger.exception("[失败] %s %s 获取数据库连接或执行任务失败：%s", task.city_name, f"{task.year}-{task.month:02d}", exc)
    finally:
        if connection is not None:
            connection.close()
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="历史天气与 AQI 多线程采集器")
    parser.add_argument("--test", action="store_true", help="只采集南京 2024-06")
    parser.add_argument("--small-test", action="store_true", help="采集南京/合肥 2024-06、2024-07")
    parser.add_argument("--workers", type=int, default=MAX_WORKERS, help="线程数，建议 4-6")
    parser.add_argument("--clear", action="store_true", help="显式清空两张数据表后再采集")
    args = parser.parse_args()
    if args.test and args.small_test:
        parser.error("--test 与 --small-test 不能同时使用")
    if not 1 <= args.workers <= 6:
        parser.error("--workers 必须在 1 到 6 之间")
    return args


def main() -> int:
    args = parse_args()
    logger, log_path = setup_logging()
    tasks = build_tasks(args.test, args.small_test)
    start = time.perf_counter()
    if args.clear:
        logger.warning("[清空] 收到 --clear，正在清空 history_weather/history_aqi")
        clear_tables()
        logger.info("[清空] 完成")

    logger.info("[启动] 历史天气/AQI 数据采集程序")
    logger.info("[配置] 城市数: %s", len(CITY_NAME_MAP) if not (args.test or args.small_test) else (1 if args.test else 2))
    logger.info("[配置] 年份: %s-%s", YEARS[0], YEARS[-1])
    logger.info("[线程池] workers=%s", args.workers)
    logger.info("[启动] 总任务数: %s", len(tasks))

    summary = {
        "weather_success": 0, "weather_skip": 0, "weather_failed": 0, "weather_count": 0,
        "aqi_success": 0, "aqi_skip": 0, "aqi_failed": 0, "aqi_count": 0,
    }
    with ThreadPoolExecutor(max_workers=args.workers, thread_name_prefix="crawler") as executor:
        futures = {executor.submit(process_task, task, logger): task for task in tasks}
        for completed, future in enumerate(as_completed(futures), start=1):
            task = futures[future]
            try:
                result = future.result()
            except Exception as exc:
                logger.exception("[失败] 任务 %s %s 未处理异常：%s", task.city_name, f"{task.year}-{task.month:02d}", exc)
                result = {"weather_status": "failed", "aqi_status": "failed", "weather_count": 0, "aqi_count": 0}
            for kind in ("weather", "aqi"):
                status = result[f"{kind}_status"]
                summary[f"{kind}_{status}"] += 1
                summary[f"{kind}_count"] += result[f"{kind}_count"]
            logger.info("[进度] %s/%s", completed, len(tasks))

    elapsed = time.perf_counter() - start
    logger.info("========== 任务完成 ==========")
    logger.info("天气：成功月份=%s，跳过月份=%s，失败月份=%s，新增/更新记录=%s", summary["weather_success"], summary["weather_skip"], summary["weather_failed"], summary["weather_count"])
    logger.info("AQI：成功月份=%s，跳过月份=%s，失败月份=%s，新增/更新记录=%s", summary["aqi_success"], summary["aqi_skip"], summary["aqi_failed"], summary["aqi_count"])
    logger.info("总耗时：%.2f 秒；线程数：%s", elapsed, args.workers)
    logger.info("[日志] %s", log_path)
    return 1 if (summary["weather_failed"] or summary["aqi_failed"]) else 0


if __name__ == "__main__":
    raise SystemExit(main())
