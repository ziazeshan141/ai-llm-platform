from typing import Any

import httpx


GEOCODING_URL = "https://geocoding-api.open-meteo.com/v1/search"
WEATHER_URL = "https://api.open-meteo.com/v1/forecast"


WEATHER_CODES = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Light freezing drizzle",
    57: "Dense freezing drizzle",
    61: "Slight rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Light freezing rain",
    67: "Heavy freezing rain",
    71: "Slight snowfall",
    73: "Moderate snowfall",
    75: "Heavy snowfall",
    77: "Snow grains",
    80: "Slight rain showers",
    81: "Moderate rain showers",
    82: "Violent rain showers",
    85: "Slight snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with slight hail",
    99: "Thunderstorm with heavy hail",
}


async def search_location(
    client: httpx.AsyncClient,
    query: str,
) -> dict[str, Any] | None:

    response = await client.get(
        GEOCODING_URL,
        params={
            "name": query,
            "count": 10,
            "language": "en",
            "format": "json",
        },
    )

    response.raise_for_status()

    results = response.json().get("results", [])

    if not results:
        return None

    return results[0]


async def get_weather(location: str) -> dict[str, Any]:
    original_location = location.strip()

    if not original_location:
        raise ValueError("Location is required.")

    async with httpx.AsyncClient(timeout=15.0) as client:

        # First try the complete location supplied by the LLM/user.
        resolved_location = await search_location(
            client,
            original_location,
        )

        # Some geocoders work better with just the city/town name.
        # Example:
        # "Riyadh Saudi Arabia" -> "Riyadh"
        if resolved_location is None:

            simplified_location = (
                original_location
                .replace(",", " ")
                .split()[0]
            )

            if simplified_location != original_location:
                resolved_location = await search_location(
                    client,
                    simplified_location,
                )

        if resolved_location is None:
            raise ValueError(
                f"Could not find location: {original_location}"
            )

        latitude = resolved_location["latitude"]
        longitude = resolved_location["longitude"]

        weather_response = await client.get(
            WEATHER_URL,
            params={
                "latitude": latitude,
                "longitude": longitude,
                "current": ",".join(
                    [
                        "temperature_2m",
                        "relative_humidity_2m",
                        "apparent_temperature",
                        "precipitation",
                        "weather_code",
                        "wind_speed_10m",
                    ]
                ),
                "timezone": "auto",
            },
        )

        weather_response.raise_for_status()

        weather_data = weather_response.json()

    current = weather_data.get("current", {})
    units = weather_data.get("current_units", {})

    weather_code = current.get("weather_code")

    return {
        "requested_location": original_location,
        "city": resolved_location.get("name"),
        "admin1": resolved_location.get("admin1"),
        "country": resolved_location.get("country"),
        "country_code": resolved_location.get("country_code"),
        "latitude": latitude,
        "longitude": longitude,
        "timezone": weather_data.get("timezone"),
        "time": current.get("time"),
        "temperature": current.get("temperature_2m"),
        "temperature_unit": units.get(
            "temperature_2m",
            "°C",
        ),
        "feels_like": current.get(
            "apparent_temperature"
        ),
        "humidity": current.get(
            "relative_humidity_2m"
        ),
        "humidity_unit": units.get(
            "relative_humidity_2m",
            "%",
        ),
        "precipitation": current.get(
            "precipitation"
        ),
        "precipitation_unit": units.get(
            "precipitation",
            "mm",
        ),
        "wind_speed": current.get(
            "wind_speed_10m"
        ),
        "wind_speed_unit": units.get(
            "wind_speed_10m",
            "km/h",
        ),
        "weather_code": weather_code,
        "condition": WEATHER_CODES.get(
            weather_code,
            "Unknown weather condition",
        ),
    }