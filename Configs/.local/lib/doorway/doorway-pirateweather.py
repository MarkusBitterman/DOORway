#!/usr/bin/env python3
"""DOORway PirateWeather fetch script.

Reads PIRATE_WEATHER_* environment variables (injected by the systemd
EnvironmentFile from the sops secret), geocodes the ZIP code via Nominatim
(result cached), calls the PirateWeather forecast API, and writes
~/.cache/doorway/weather.json for the Weather.qml singleton to watch.

Environment variables:
  PIRATE_WEATHER_API_KEY   — required, from sops EnvironmentFile
  PIRATE_WEATHER_ZIP       — US ZIP code (or postal code with COUNTRY set)
  PIRATE_WEATHER_COUNTRY   — ISO country code for geocoding (default: US)
  PIRATE_WEATHER_UNITS     — us | si | ca | uk2 (default: us)
  PIRATE_WEATHER_HOURS     — number of hourly rows to include (default: 12)
"""

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests


def get_with_retry(url: str, *, attempts: int = 3, backoff: int = 20, **kwargs) -> requests.Response:
    """requests.get with linear-backoff retries.

    The systemd unit is a oneshot on a 15-minute timer, so a transient DNS or
    network blip would otherwise silently cost a whole cycle (observed as
    hours-stale weather across outages).
    """
    for attempt in range(attempts):
        try:
            resp = requests.get(url, **kwargs)
            resp.raise_for_status()
            return resp
        except requests.RequestException:
            if attempt == attempts - 1:
                raise
            time.sleep(backoff * (attempt + 1))

ICON_MAP: dict[str, str] = {
    "clear-day": "clear_day",
    "clear-night": "clear_night",
    "rain": "rainy",
    "snow": "snowing",
    "sleet": "cloudy_snowing",
    "wind": "air",
    "fog": "foggy",
    "cloudy": "cloud",
    "partly-cloudy-day": "partly_cloudy_day",
    "partly-cloudy-night": "partly_cloudy_night",
}

WIND_DIRS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
WIND_UNITS: dict[str, str] = {"us": "mph", "ca": "km/h", "uk2": "mph", "si": "m/s"}


def bearing_to_dir(degrees: float) -> str:
    return WIND_DIRS[round(degrees / 45) % 8]


def fmt_temp(value: float, units: str) -> str:
    symbol = "°F" if units == "us" else "°C"
    return f"{round(value)}{symbol}"


def fmt_wind(speed: float, units: str) -> str:
    return f"{round(speed)} {WIND_UNITS.get(units, 'mph')}"


def fmt_visibility(value: float, units: str) -> str:
    label = "mi" if units == "us" else "km"
    return f"{value:.0f} {label}"


def fmt_precip(probability: float) -> str:
    return f"{round(probability * 100)}%"


def fmt_local_time(unix_ts: int, fmt: str) -> str:
    return datetime.fromtimestamp(unix_ts).strftime(fmt)


def geocode(zip_code: str, country: str, cache_path: Path) -> tuple[float, float]:
    """Return (lat, lon) for a postal code, using a local JSON cache."""
    if cache_path.exists():
        try:
            with open(cache_path) as f:
                cached = json.load(f)
            if cached.get("zip") == zip_code and cached.get("country") == country:
                return float(cached["lat"]), float(cached["lon"])
        except (json.JSONDecodeError, KeyError):
            pass

    url = "https://nominatim.openstreetmap.org/search"
    params = {"postalcode": zip_code, "country": country, "format": "json", "limit": 1}
    headers = {"User-Agent": "DOORway/1.0 (https://github.com/MarkusBitterman/DOORway)"}
    resp = get_with_retry(url, params=params, headers=headers, timeout=10)
    results = resp.json()
    if not results:
        raise ValueError(f"Nominatim returned no results for ZIP {zip_code!r}, country {country!r}")

    lat = float(results[0]["lat"])
    lon = float(results[0]["lon"])
    city = results[0].get("display_name", "").split(",")[0].strip()

    cache_path.parent.mkdir(parents=True, exist_ok=True)
    with open(cache_path, "w") as f:
        json.dump({"zip": zip_code, "country": country, "lat": lat, "lon": lon, "city": city}, f)

    return lat, lon


def city_from_cache(cache_path: Path) -> str:
    try:
        with open(cache_path) as f:
            return json.load(f).get("city", "")
    except Exception:
        return ""


def main() -> None:
    api_key = os.environ.get("PIRATE_WEATHER_API_KEY", "").strip()
    zip_code = os.environ.get("PIRATE_WEATHER_ZIP", "").strip()
    country = os.environ.get("PIRATE_WEATHER_COUNTRY", "US").strip()
    units = os.environ.get("PIRATE_WEATHER_UNITS", "us").strip()
    n_hours = int(os.environ.get("PIRATE_WEATHER_HOURS", "12"))

    if not api_key:
        print("doorway-pirateweather: PIRATE_WEATHER_API_KEY is not set", file=sys.stderr)
        sys.exit(1)
    if not zip_code:
        print("doorway-pirateweather: PIRATE_WEATHER_ZIP is not set", file=sys.stderr)
        sys.exit(1)

    cache_dir = Path.home() / ".cache" / "doorway"
    cache_dir.mkdir(parents=True, exist_ok=True)
    geocode_cache = cache_dir / "weather-location.json"
    output_path = cache_dir / "weather.json"

    lat, lon = geocode(zip_code, country, geocode_cache)
    city = city_from_cache(geocode_cache)

    url = f"https://api.pirateweather.net/forecast/{api_key}/{lat},{lon}"
    params = {"units": units, "extend": "hourly"}
    resp = get_with_retry(url, params=params, timeout=15)
    forecast = resp.json()

    cur = forecast.get("currently", {})
    # daily[0] has sunrise/sunset for today
    daily0 = forecast.get("daily", {}).get("data", [{}])[0]

    icon = ICON_MAP.get(cur.get("icon", ""), "cloud")
    sunrise_ts = daily0.get("sunriseTime", 0)
    sunset_ts = daily0.get("sunsetTime", 0)

    # Hourly: next n_hours starting from now (PirateWeather with extend=hourly gives 168h)
    now_ts = datetime.now(timezone.utc).timestamp()
    hourly_raw = forecast.get("hourly", {}).get("data", [])
    future = [h for h in hourly_raw if h.get("time", 0) >= now_ts][:n_hours]
    hourly = [
        {
            "time": fmt_local_time(h["time"], "%-I %p"),
            "icon": ICON_MAP.get(h.get("icon", ""), "cloud"),
            "temp": fmt_temp(h.get("temperature", 0), units),
            "precip": fmt_precip(h.get("precipProbability", 0)),
        }
        for h in future
    ]

    # Daily: the coming week (PirateWeather daily.data). The widget renders this as the
    # "weekly forecast" almanac; previously only daily[0] was used (for sunrise/sunset).
    daily_raw = forecast.get("daily", {}).get("data", [])[:7]
    daily = [
        {
            "day": fmt_local_time(d["time"], "%a"),
            "icon": ICON_MAP.get(d.get("icon", ""), "cloud"),
            "high": fmt_temp(d.get("temperatureHigh", d.get("temperatureMax", 0)), units),
            "low": fmt_temp(d.get("temperatureLow", d.get("temperatureMin", 0)), units),
            "precip": fmt_precip(d.get("precipProbability", 0)),
        }
        for d in daily_raw
    ]

    output = {
        "icon": icon,
        "temp": fmt_temp(cur.get("temperature", 0), units),
        "city": city,
        "tempFeelsLike": fmt_temp(cur.get("apparentTemperature", 0), units),
        "uv": str(round(cur.get("uvIndex", 0))),
        "windDir": bearing_to_dir(cur.get("windBearing", 0)),
        "wind": fmt_wind(cur.get("windSpeed", 0), units),
        "precip": fmt_precip(cur.get("precipProbability", 0)),
        "humidity": f"{round(cur.get('humidity', 0) * 100)}%",
        "visib": fmt_visibility(cur.get("visibility", 10), units),
        "press": f"{round(cur.get('pressure', 0))} hPa",
        "sunrise": fmt_local_time(sunrise_ts, "%-I:%M %p") if sunrise_ts else "--",
        "sunset": fmt_local_time(sunset_ts, "%-I:%M %p") if sunset_ts else "--",
        "sunriseHHMM": fmt_local_time(sunrise_ts, "%H:%M") if sunrise_ts else "06:30",
        "sunsetHHMM": fmt_local_time(sunset_ts, "%H:%M") if sunset_ts else "19:00",
        "summary": cur.get("summary", ""),
        "lastRefresh": datetime.now().strftime("%-I:%M %p"),
        "hourly": hourly,
        "daily": daily,
    }

    with open(output_path, "w") as f:
        json.dump(output, f)


if __name__ == "__main__":
    main()
