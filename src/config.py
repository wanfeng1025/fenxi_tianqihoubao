"""Runtime configuration; credentials must come from environment variables."""

from pathlib import Path
import os


BASE_DIR = Path(__file__).resolve().parent
LOG_DIR = BASE_DIR / "logs"
SCREENSHOT_DIR = BASE_DIR / "screenshots"

DB_HOST = os.getenv("WEATHER_DB_HOST", "localhost")
DB_PORT = int(os.getenv("WEATHER_DB_PORT", "3306"))
DB_USER = os.getenv("WEATHER_DB_USER", "")
DB_PASSWORD = os.getenv("WEATHER_DB_PASSWORD", "")
DB_NAME = os.getenv("WEATHER_DB_NAME", "weather_db")

CITY_NAME_MAP = {
    "nanjing": "南京",
    "hefei": "合肥",
    "hangzhou": "杭州",
    "bozhou": "亳州",
    "huainan": "淮南",
    "tongling": "铜陵",
}

AQI_SOURCE_CITY_MAP = {city: city for city in CITY_NAME_MAP}
YEARS = tuple(range(2020, 2027))
MONTHS = tuple(range(1, 13))
MAX_WORKERS = int(os.getenv("WEATHER_MAX_WORKERS", "4"))
REQUEST_DELAY = float(os.getenv("WEATHER_REQUEST_DELAY", "1.0"))
REQUEST_TIMEOUT = int(os.getenv("WEATHER_REQUEST_TIMEOUT", "25"))
MAX_RETRIES = int(os.getenv("WEATHER_MAX_RETRIES", "3"))
INITIAL_RETRY_DELAY = float(os.getenv("WEATHER_INITIAL_RETRY_DELAY", "5"))
WEATHER_URL = "https://www.tianqihoubao.com/lishi/{city}/month/{year}{month:02d}.html"
AQI_URL = "https://www.tianqihoubao.com/aqi/{city}-{year}{month:02d}.html"
