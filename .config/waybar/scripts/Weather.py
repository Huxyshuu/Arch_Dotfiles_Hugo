#!/usr/bin/env python3
import requests
import json
import os
from datetime import datetime

# Weather icons mapping based on Open-Meteo weather codes
weather_icons = {
    "clear_day": "󰖙",
    "clear_night": "󰖔",
    "partly_cloudy_day": "",
    "partly_cloudy_night": "",
    "cloudy": "",
    "fog": "",
    "drizzle": "",
    "rain": "",
    "snow": "",
    "thunderstorm": "",
    "default": "",
}

# Weather code mapping: https://open-meteo.com/en/docs
def map_weather_code(code, is_day):
    mapping = {
        0: "clear_day" if is_day else "clear_night",
        1: "partly_cloudy_day" if is_day else "partly_cloudy_night",
        2: "partly_cloudy_day" if is_day else "partly_cloudy_night",
        3: "cloudy",
        45: "fog",
        48: "fog",
        51: "drizzle",
        53: "drizzle",
        55: "drizzle",
        56: "drizzle",
        57: "drizzle",
        61: "rain",
        63: "rain",
        65: "rain",
        66: "rain",
        67: "rain",
        71: "snow",
        73: "snow",
        75: "snow",
        77: "snow",
        80: "rain",
        81: "rain",
        82: "rain",
        85: "snow",
        86: "snow",
        95: "thunderstorm",
        96: "thunderstorm",
        99: "thunderstorm"
    }
    return mapping.get(code, "default")

# Get current location
def get_location():
    response = requests.get("https://ipinfo.io")
    data = response.json()
    loc = data["loc"].split(",")
    return float(loc[0]), float(loc[1])

latitude, longitude = get_location()

# Open-Meteo request
url = (
    f"https://api.open-meteo.com/v1/forecast?"
    f"latitude={latitude}&longitude={longitude}"
    "&current=temperature_2m,apparent_temperature,relative_humidity_2m,visibility,"
    "precipitation,weather_code,wind_speed_10m,is_day"
    "&hourly=precipitation_probability"
    "&daily=temperature_2m_max,temperature_2m_min"
    "&timezone=auto"
)

data = requests.get(url).json()

# Extract current data
current = data["current"]
temp = f"{current['temperature_2m']}°C"
temp_feel_text = f"Feels like {current['apparent_temperature']}°C"
humidity_text = f"  {current['relative_humidity_2m']}%"
visibility_text = f"  {round(current['visibility'] / 1000, 1)} km"
wind_text = f"  {current['wind_speed_10m']} km/h"
status_code = map_weather_code(current["weather_code"], current["is_day"])
icon = weather_icons.get(status_code, weather_icons["default"])

# Min/max temperature
temp_min = f"{data['daily']['temperature_2m_min'][0]}°C"
temp_max = f"{data['daily']['temperature_2m_max'][0]}°C"
temp_min_max = f"Min:   {temp_min}\t\tMax:   {temp_max}"

# Hourly precipitation probability
precip_probs = data["hourly"]["precipitation_probability"][:6]  # next 6 hours
prediction = "\n".join(f"{p}%" for p in precip_probs)
prediction = f"\n\n (hourly)\n{prediction}" if any(precip_probs) else ""

# Tooltip text
tooltip_text = str.format(
    "\t\t{}\t\t\n{}\n{}\n{}\n\n{}\n\n{}\n{}",
    f'<span size="xx-large">{temp}</span>',
    f"<big>{icon}</big>",
    f"<b>{status_code}</b>",
    f"<small>{temp_feel_text}</small>",
    f"<b>{temp_min_max}</b>",
    f"{wind_text}\t   {humidity_text}\t{visibility_text}",
    f"<i>{prediction}</i>",
)

# Output for Waybar
out_data = {
    "text": f"{icon}  {temp}",
    "alt": status_code,
    "tooltip": tooltip_text,
    "class": status_code,
}
print(json.dumps(out_data))

# Simple cache text
simple_weather = (
    f"{icon}  {status_code}\n"
    + f"  {temp} ({temp_feel_text})\n"
    + f"{wind_text} \n"
    + f"{humidity_text} \n"
    + f"{visibility_text}"
)

try:
    with open(os.path.expanduser("~/.cache/.weather_cache"), "w") as file:
        file.write(simple_weather)
except Exception as e:
    print(f"Error writing to cache: {e}")
