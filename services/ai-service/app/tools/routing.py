from typing import Any

import httpx


GEOCODING_URL = "https://nominatim.openstreetmap.org/search"
ROUTING_URL = "https://router.project-osrm.org/route/v1/driving"


async def geocode_location(
    location: str,
) -> tuple[float, float]:

    headers = {
        "User-Agent": "ai-llm-platform/1.0"
    }

    params = {
        "q": location,
        "format": "json",
        "limit": 1,
    }

    async with httpx.AsyncClient(
        timeout=30.0
    ) as client:

        response = await client.get(
            GEOCODING_URL,
            params=params,
            headers=headers,
        )

        response.raise_for_status()

        results = response.json()

    if not results:
        raise ValueError(
            f"Location not found: {location}"
        )

    latitude = float(
        results[0]["lat"]
    )

    longitude = float(
        results[0]["lon"]
    )

    return latitude, longitude


async def get_driving_route(
    origin: str,
    destination: str,
) -> dict[str, Any]:

    origin_lat, origin_lon = await geocode_location(
        origin
    )

    destination_lat, destination_lon = await geocode_location(
        destination
    )

    url = (
        f"{ROUTING_URL}/"
        f"{origin_lon},{origin_lat};"
        f"{destination_lon},{destination_lat}"
    )

    params = {
        "overview": "false",
        "steps": "false",
    }

    async with httpx.AsyncClient(
        timeout=30.0
    ) as client:

        response = await client.get(
            url,
            params=params,
        )

        response.raise_for_status()

        data = response.json()

    routes = data.get(
        "routes",
        []
    )

    if not routes:
        raise ValueError(
            "No driving route was found."
        )

    route = routes[0]

    distance_km = round(
        route["distance"] / 1000,
        1,
    )

    duration_hours = round(
        route["duration"] / 3600,
        1,
    )

    return {
        "origin": origin,
        "destination": destination,
        "distance_km": distance_km,
        "duration_hours": duration_hours,
        "source": "OpenStreetMap / OSRM",
    }