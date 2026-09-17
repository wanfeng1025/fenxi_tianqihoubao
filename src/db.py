"""MySQL 连接和幂等写入。每个采集任务独立获取并关闭连接。"""

from typing import Iterable, Mapping

import pymysql

from config import DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME


def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset="utf8mb4",
        autocommit=False,
        connect_timeout=10,
        read_timeout=30,
        write_timeout=30,
    )


def clear_tables() -> None:
    """仅由显式的 --clear 参数调用。"""
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("TRUNCATE TABLE history_weather")
            cursor.execute("TRUNCATE TABLE history_aqi")
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def upsert_weather(connection, rows: Iterable[Mapping]) -> int:
    sql = """
        INSERT INTO history_weather (
            city_name, `date`, day_weather_condition,
            night_weather_condition, max_temperature, min_temperature,
            day_wind_direction, night_wind_direction
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            day_weather_condition = VALUES(day_weather_condition),
            night_weather_condition = VALUES(night_weather_condition),
            max_temperature = VALUES(max_temperature),
            min_temperature = VALUES(min_temperature),
            day_wind_direction = VALUES(day_wind_direction),
            night_wind_direction = VALUES(night_wind_direction)
    """
    values = [
        (
            row["city_name"], row["date"], row.get("day_weather_condition"),
            row.get("night_weather_condition"), row.get("max_temperature"),
            row.get("min_temperature"), row.get("day_wind_direction"),
            row.get("night_wind_direction"),
        )
        for row in rows
    ]
    if not values:
        return 0
    try:
        with connection.cursor() as cursor:
            cursor.executemany(sql, values)
        connection.commit()
        return len(values)
    except Exception:
        connection.rollback()
        raise


def upsert_aqi(connection, rows: Iterable[Mapping]) -> int:
    sql = """
        INSERT INTO history_aqi (
            city_name, source_city, `date`, aqi_quality_grade, aqi_index,
            aqi_ranking_day, PM25, PM10, So2, No2, Co, O3
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            source_city = VALUES(source_city),
            aqi_quality_grade = VALUES(aqi_quality_grade),
            aqi_index = VALUES(aqi_index),
            aqi_ranking_day = VALUES(aqi_ranking_day),
            PM25 = VALUES(PM25),
            PM10 = VALUES(PM10),
            So2 = VALUES(So2),
            No2 = VALUES(No2),
            Co = VALUES(Co),
            O3 = VALUES(O3)
    """
    values = [
        (
            row["city_name"], row.get("source_city"), row["date"], row.get("aqi_quality_grade"),
            row.get("aqi_index"), row.get("aqi_ranking_day"),
            row.get("PM25"), row.get("PM10"), row.get("So2"),
            row.get("No2"), row.get("Co"), row.get("O3"),
        )
        for row in rows
    ]
    if not values:
        return 0
    try:
        with connection.cursor() as cursor:
            cursor.executemany(sql, values)
        connection.commit()
        return len(values)
    except Exception:
        connection.rollback()
        raise
