"""天启后报历史天气/AQI 页面请求、编码处理和容错解析。"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from pathlib import Path
import re
import threading
import time
from typing import Any, Iterable

import requests
from lxml import html

from config import (
    AQI_URL,
    BASE_DIR,
    INITIAL_RETRY_DELAY,
    MAX_RETRIES,
    REQUEST_DELAY,
    REQUEST_TIMEOUT,
    WEATHER_URL,
)


_local = threading.local()


class NoDataError(Exception):
    """页面明确表示目标月份不存在或暂无数据。"""


class ParseError(Exception):
    """页面存在但结构无法可靠解析。"""


@dataclass
class FetchResult:
    status: str
    text: str = ""
    url: str = ""
    http_status: int | None = None
    reason: str = ""


def get_session() -> requests.Session:
    session = getattr(_local, "session", None)
    if session is None:
        session = requests.Session()
        session.headers.update(
            {
                "User-Agent": (
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 Chrome/124.0 Safari/537.36"
                ),
                "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.5",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            }
        )
        _local.session = session
    return session


def _decode_response(response: requests.Response) -> str:
    content = response.content
    candidates: list[str] = []
    for encoding in (response.encoding, response.apparent_encoding, "gb18030", "utf-8"):
        if encoding and encoding.lower() not in {item.lower() for item in candidates}:
            candidates.append(encoding)

    def score(text: str) -> int:
        cjk = len(re.findall(r"[\u3400-\u9fff]", text))
        replacement = text.count("\ufffd")
        mojibake = sum(text.count(marker) for marker in ("Ã", "Â", "�"))
        return cjk * 3 - replacement * 20 - mojibake * 3

    decoded: list[tuple[int, str]] = []
    for encoding in candidates:
        try:
            text = content.decode(encoding, errors="strict")
        except (LookupError, UnicodeDecodeError):
            continue
        decoded.append((score(text), text))
    if decoded:
        return max(decoded, key=lambda item: item[0])[1]
    return content.decode("utf-8", errors="ignore")


def fetch_html(url: str, label: str, logger) -> FetchResult:
    session = get_session()
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = session.get(url, timeout=REQUEST_TIMEOUT)
            status = response.status_code
            if status in (404, 410):
                return FetchResult("SKIP", url=url, http_status=status, reason="页面不存在")
            if status != 200:
                retryable = status in {408, 425, 429, 500, 502, 503, 504}
                if not retryable or attempt >= MAX_RETRIES:
                    return FetchResult(
                        "FAILED", url=url, http_status=status,
                        reason=f"HTTP {status}",
                    )
                delay = INITIAL_RETRY_DELAY * (2 ** (attempt - 1))
                logger.warning("[重试] %s HTTP %s，第 %s/%s 次，等待 %.1f 秒", label, status, attempt, MAX_RETRIES, delay)
                time.sleep(delay)
                continue
            if not response.content:
                return FetchResult("SKIP", url=url, http_status=status, reason="空页面")
            time.sleep(REQUEST_DELAY)
            return FetchResult("OK", text=_decode_response(response), url=url, http_status=status)
        except requests.RequestException as exc:
            if attempt >= MAX_RETRIES:
                return FetchResult("FAILED", url=url, reason=f"{type(exc).__name__}: {exc}")
            delay = INITIAL_RETRY_DELAY * (2 ** (attempt - 1))
            logger.warning("[重试] %s %s，第 %s/%s 次，等待 %.1f 秒", label, type(exc).__name__, attempt, MAX_RETRIES, delay)
            time.sleep(delay)
    return FetchResult("FAILED", url=url, reason="请求未完成")


def weather_url(city: str, year: int, month: int) -> str:
    return WEATHER_URL.format(city=city, year=year, month=month)


def aqi_url(city: str, year: int, month: int) -> str:
    return AQI_URL.format(city=city, year=year, month=month)


def clean_text(value: Any) -> str:
    return " ".join(str(value).replace("\xa0", " ").split()).strip()


def parse_number(value: Any) -> int | float | None:
    text = clean_text(value)
    if not text or text in {"-", "--", "—", "暂无", "无", "N/A", "NA", "None"}:
        return None
    text = text.replace(",", "").replace("，", "")
    match = re.search(r"[-+]?\d+(?:\.\d+)?", text)
    if not match:
        return None
    number = match.group(0)
    try:
        return int(number) if "." not in number else float(number)
    except ValueError:
        return None


def parse_date(value: Any, expected_year: int, expected_month: int) -> date | None:
    text = clean_text(value)
    match = re.search(
        r"(?P<year>20\d{2})\s*(?:年|[-/.])\s*"
        r"(?P<month>\d{1,2})\s*(?:月|[-/.])\s*"
        r"(?P<day>\d{1,2})\s*日?",
        text,
    )
    if not match:
        match = re.search(r"(?P<month>\d{1,2})\s*月\s*(?P<day>\d{1,2})\s*日", text)
        if not match:
            match = re.search(r"(?P<month>\d{1,2})[-/.](?P<day>\d{1,2})", text)
        if not match:
            return None
        year = expected_year
    else:
        year = int(match.group("year"))
    month = int(match.group("month"))
    day = int(match.group("day"))
    if year != expected_year or month != expected_month:
        return None
    try:
        return date(year, month, day)
    except ValueError:
        return None


def _row_cells(row) -> list:
    return row.xpath("./th|./td")


def _cell_text(cell) -> str:
    return clean_text(" ".join(cell.itertext()))


def _split_day_night(cell) -> tuple[str | None, str | None]:
    span_values = [clean_text(" ".join(span.itertext())) for span in cell.xpath(".//span")]
    span_values = [value for value in span_values if value]
    if len(span_values) >= 2:
        return span_values[0], span_values[1]
    text = _cell_text(cell)
    parts = [part.strip() for part in re.split(r"\s*/\s*|\s*／\s*|\s*\|\s*", text) if part.strip()]
    if len(parts) >= 2:
        return parts[0], parts[1]
    return (text or None), (text or None)


def _find_tables(tree, preferred_xpath: str) -> list:
    preferred = tree.xpath(preferred_xpath)
    generic = tree.xpath("//table")
    seen: set[int] = set()
    result = []
    for table in preferred + generic:
        marker = id(table)
        if marker not in seen:
            seen.add(marker)
            result.append(table)
    return result


def _header_row(rows) -> tuple[list[str], list] | tuple[None, None]:
    for row in rows:
        cells = _row_cells(row)
        values = [_cell_text(cell) for cell in cells]
        joined = " ".join(values)
        if "日期" in joined and ("天气" in joined or "AQI" in joined.upper() or "PM" in joined.upper()):
            return values, cells
    return None, None


def _header_index(headers: list[str] | None, patterns: Iterable[str], default: int) -> int:
    if not headers:
        return default
    for index, header in enumerate(headers):
        value = re.sub(r"[\s_.·：:（）()\-]", "", header).lower()
        if any(pattern.lower() in value for pattern in patterns):
            return index
    return default


def _looks_like_no_data(text: str) -> bool:
    lowered = text.lower()
    return any(
        marker in lowered
        for marker in ("404", "页面不存在", "没有找到", "暂无数据", "无数据", "不存在该页面")
    )


def _is_current_or_future_month(year: int, month: int) -> bool:
    today = date.today()
    return (year, month) >= (today.year, today.month)


def _parse_tree(text: str, kind: str, city: str, year: int, month: int):
    try:
        tree = html.fromstring(text)
    except (ValueError, TypeError) as exc:
        raise ParseError(f"HTML 解析失败: {exc}") from exc
    title = clean_text(tree.xpath("string(//title)"))
    tables = tree.xpath("//table")
    preferred_xpath = (
        '//div[contains(concat(" ", normalize-space(@class), " "), " wdetail ")]//table'
        if kind == "weather"
        else '//table[contains(concat(" ", normalize-space(@class), " "), " b ")]'
    )
    candidate_tables = _find_tables(tree, preferred_xpath)
    if not candidate_tables:
        if _is_current_or_future_month(year, month) or _looks_like_no_data(text):
            raise NoDataError("目标月份尚无可用数据")
        raise ParseError(f"没有找到 table；页面标题: {title}; 找到 table 数量: {len(tables)}")
    return tree, title, tables, candidate_tables


def parse_weather(text: str, city_name: str, year: int, month: int) -> list[dict]:
    tree, title, tables, candidates = _parse_tree(text, "weather", city_name, year, month)
    selected_rows = None
    selected_headers = None
    for table in candidates:
        rows = table.xpath(".//tr")
        headers, _ = _header_row(rows)
        valid = [row for row in rows if len(_row_cells(row)) >= 3 and parse_date(_cell_text(_row_cells(row)[0]), year, month)]
        if valid and (headers or table in candidates[:2]):
            selected_rows, selected_headers = valid, headers
            break
    if not selected_rows:
        if _is_current_or_future_month(year, month) or _looks_like_no_data(text):
            raise NoDataError("页面明确表示暂无或不存在目标月份")
        tr_count = len(tree.xpath("//tr"))
        raise ParseError(f"页面标题: {title}; 找到 table 数量: {len(tables)}; 找到 tr 数量: {tr_count}")

    date_index = _header_index(selected_headers, ("日期",), 0)
    condition_index = _header_index(selected_headers, ("天气状况", "天气"), 1)
    temperature_index = _header_index(selected_headers, ("气温", "温度"), 2)
    wind_index = _header_index(selected_headers, ("风力风向", "风向", "风力"), 3)
    results = []
    for row in selected_rows:
        cells = _row_cells(row)
        if max(date_index, condition_index, temperature_index, wind_index) >= len(cells):
            continue
        parsed = parse_date(_cell_text(cells[date_index]), year, month)
        if parsed is None:
            continue
        day_weather, night_weather = _split_day_night(cells[condition_index])
        temperatures = re.findall(r"[-+]?\d+(?:\.\d+)?", _cell_text(cells[temperature_index]))
        max_temperature = parse_number(temperatures[0]) if temperatures else None
        min_temperature = parse_number(temperatures[1]) if len(temperatures) >= 2 else max_temperature
        day_wind, night_wind = _split_day_night(cells[wind_index])
        results.append(
            {
                "city_name": city_name,
                "date": parsed,
                "day_weather_condition": day_weather,
                "night_weather_condition": night_weather,
                "max_temperature": max_temperature,
                "min_temperature": min_temperature,
                "day_wind_direction": day_wind,
                "night_wind_direction": night_wind,
            }
        )
    if not results:
        if _is_current_or_future_month(year, month) or _looks_like_no_data(text):
            raise NoDataError("页面明确表示暂无或不存在目标月份")
        tr_count = len(tree.xpath("//tr"))
        raise ParseError(f"页面标题: {title}; 找到 table 数量: {len(tables)}; 找到 tr 数量: {tr_count}")
    return results


def parse_aqi(
    text: str,
    city_name: str,
    year: int,
    month: int,
    source_city_name: str | None = None,
) -> list[dict]:
    tree, title, tables, candidates = _parse_tree(text, "aqi", city_name, year, month)
    selected_rows = None
    selected_headers = None
    for table in candidates:
        rows = table.xpath(".//tr")
        headers, _ = _header_row(rows)
        valid = [row for row in rows if len(_row_cells(row)) >= 4 and parse_date(_cell_text(_row_cells(row)[0]), year, month)]
        if valid and headers:
            selected_rows, selected_headers = valid, headers
            break
    if not selected_rows:
        # 部分城市的 AQI 历史页面会返回 HTTP 200，但 HTML 只有表头。
        # 这表示网站没有提供该城市/月份数据，应记录为跳过而不是解析故障。
        only_header = any(len(table.xpath(".//tr")) <= 1 for table in candidates)
        if only_header:
            raise NoDataError("AQI 页面只有表头，无历史数据")
        if _is_current_or_future_month(year, month) or _looks_like_no_data(text):
            raise NoDataError("页面明确表示暂无或不存在目标月份")
        tr_count = len(tree.xpath("//tr"))
        raise ParseError(f"页面标题: {title}; 找到 table 数量: {len(tables)}; 找到 tr 数量: {tr_count}")

    date_index = _header_index(selected_headers, ("日期",), 0)
    grade_index = _header_index(selected_headers, ("质量等级", "质量", "等级"), 1)
    aqi_index = _header_index(selected_headers, ("aqi指数", "aqi"), 2)
    rank_index = _header_index(selected_headers, ("当天aqi排名", "排名"), 3)
    pm25_index = _header_index(selected_headers, ("pm2.5", "pm25"), 4)
    pm10_index = _header_index(selected_headers, ("pm10",), 5)
    so2_index = _header_index(selected_headers, ("so2", "二氧化硫"), 6)
    no2_index = _header_index(selected_headers, ("no2", "二氧化氮"), 7)
    co_index = _header_index(selected_headers, ("co", "一氧化碳"), 8)
    o3_index = _header_index(selected_headers, ("o3", "臭氧"), 9)
    indices = [date_index, grade_index, aqi_index, rank_index, pm25_index, pm10_index, so2_index, no2_index, co_index, o3_index]
    results = []
    for row in selected_rows:
        cells = _row_cells(row)
        parsed = parse_date(_cell_text(cells[date_index]), year, month) if date_index < len(cells) else None
        if parsed is None:
            continue

        def value_at(index: int) -> str:
            return _cell_text(cells[index]) if index < len(cells) else ""

        results.append(
            {
                "city_name": city_name,
                "source_city": source_city_name or city_name,
                "date": parsed,
                "aqi_quality_grade": value_at(grade_index) or None,
                "aqi_index": parse_number(value_at(aqi_index)),
                "aqi_ranking_day": parse_number(value_at(rank_index)),
                "PM25": parse_number(value_at(pm25_index)),
                "PM10": parse_number(value_at(pm10_index)),
                "So2": parse_number(value_at(so2_index)),
                "No2": parse_number(value_at(no2_index)),
                "Co": parse_number(value_at(co_index)),
                "O3": parse_number(value_at(o3_index)),
            }
        )
    if not results:
        if _is_current_or_future_month(year, month) or _looks_like_no_data(text):
            raise NoDataError("页面明确表示暂无或不存在目标月份")
        tr_count = len(tree.xpath("//tr"))
        raise ParseError(f"页面标题: {title}; 找到 table 数量: {len(tables)}; 找到 tr 数量: {tr_count}")
    return results


def save_debug_html(kind: str, city: str, year: int, month: int, text: str) -> Path:
    log_dir = BASE_DIR / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    safe_city = re.sub(r"[^0-9A-Za-z一-龥_-]", "_", city)
    path = log_dir / f"debug_{kind}_{safe_city}_{year}{month:02d}.html"
    path.write_text(text, encoding="utf-8")
    return path
