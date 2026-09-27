import json
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pydantic_settings import BaseSettings

from app.tools.weather import get_weather


# ============================================================
# Settings
# ============================================================


class Settings(BaseSettings):
    LLM_BASE_URL: str = "http://localhost:11434/v1"
    LLM_API_KEY: str = "local-vllm"
    LLM_MODEL: str = "llama3.2:3b"


settings = Settings()


# ============================================================
# FastAPI application
# ============================================================


app = FastAPI(
    title="AI Service",
    version="2.1.0",
)


class ChatRequest(BaseModel):
    message: str


# ============================================================
# Weather tool definition
# ============================================================


WEATHER_TOOL = {
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": (
            "Get current live weather information for a location. "
            "Use this tool only when the user asks about current "
            "weather, temperature, humidity, rain, precipitation, "
            "snow, or wind."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": (
                        "City, town, region, or location. "
                        "Examples: Riyadh, Tokyo, New York, "
                        "Sherghati Bihar India, London UK."
                    ),
                }
            },
            "required": ["location"],
        },
    },
}


# ============================================================
# Health endpoint
# ============================================================


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "ai-service",
        "model": settings.LLM_MODEL,
        "tools": ["get_weather"],
    }


# ============================================================
# Detect weather requests
# ============================================================


def is_weather_request(message: str) -> bool:
    text = message.lower()

    weather_keywords = [
        "weather",
        "temperature",
        "forecast",
        "humidity",
        "rain",
        "raining",
        "rainy",
        "snow",
        "snowing",
        "wind",
        "wind speed",
        "precipitation",
        "feels like",
        "hot outside",
        "cold outside",
    ]

    return any(
        keyword in text
        for keyword in weather_keywords
    )


# ============================================================
# Call Llama / Ollama
# ============================================================


async def call_llm(
    messages: list[dict[str, Any]],
    use_tools: bool = False,
) -> dict[str, Any]:

    payload: dict[str, Any] = {
        "model": settings.LLM_MODEL,
        "messages": messages,
    }

    if use_tools:
        payload["tools"] = [WEATHER_TOOL]
        payload["tool_choice"] = "auto"

    headers = {
        "Authorization": f"Bearer {settings.LLM_API_KEY}",
        "Content-Type": "application/json",
    }

    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            f"{settings.LLM_BASE_URL}/chat/completions",
            json=payload,
            headers=headers,
        )

    response.raise_for_status()

    return response.json()


# ============================================================
# Execute tools
# ============================================================


async def execute_tool(
    tool_name: str,
    arguments: dict[str, Any],
) -> dict[str, Any]:

    if tool_name == "get_weather":

        location = arguments.get("location")

        if not location:
            raise ValueError(
                "The get_weather tool requires a location."
            )

        return await get_weather(location)

    raise ValueError(
        f"Unknown tool: {tool_name}"
    )


# ============================================================
# Format trusted weather result
# ============================================================


def format_weather(
    data: dict[str, Any],
) -> str:

    location_parts = [
        data.get("city"),
        data.get("admin1"),
        data.get("country"),
    ]

    location_name = ", ".join(
        str(part)
        for part in location_parts
        if part
    )

    if not location_name:
        location_name = str(
            data.get(
                "requested_location",
                "the requested location",
            )
        )

    condition = data.get(
        "condition",
        "Unknown weather condition",
    )

    temperature = data.get("temperature")
    temperature_unit = data.get(
        "temperature_unit",
        "°C",
    )

    feels_like = data.get("feels_like")

    humidity = data.get("humidity")
    humidity_unit = data.get(
        "humidity_unit",
        "%",
    )

    precipitation = data.get("precipitation")
    precipitation_unit = data.get(
        "precipitation_unit",
        "mm",
    )

    wind_speed = data.get("wind_speed")
    wind_speed_unit = data.get(
        "wind_speed_unit",
        "km/h",
    )

    parts = [
        f"Current weather in {location_name}: {condition}."
    ]

    if temperature is not None:
        parts.append(
            f"Temperature: {temperature}{temperature_unit}."
        )

    if feels_like is not None:
        parts.append(
            f"Feels like: {feels_like}{temperature_unit}."
        )

    if humidity is not None:
        parts.append(
            f"Humidity: {humidity}{humidity_unit}."
        )

    if precipitation is not None:
        parts.append(
            "Precipitation: "
            f"{precipitation} {precipitation_unit}."
        )

    if wind_speed is not None:
        parts.append(
            "Wind speed: "
            f"{wind_speed} {wind_speed_unit}."
        )

    return " ".join(parts)


# ============================================================
# Chat endpoint
# ============================================================


@app.post("/api/v1/ai/chat")
async def chat(
    request: ChatRequest,
):

    user_message = request.message.strip()

    if not user_message:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty.",
        )

    weather_request = is_weather_request(
        user_message
    )

    # --------------------------------------------------------
    # System prompt
    # --------------------------------------------------------

    if weather_request:

        system_prompt = (
            "You are a helpful AI assistant. "
            "The user is asking about weather. "
            "Use the get_weather tool to obtain live weather data. "
            "Extract the location from the user's question and pass "
            "it to the tool using the location argument. "
            "Do not invent weather information."
        )

    else:

        system_prompt = (
            "You are a helpful general-purpose AI assistant. "
            "Answer the user's question normally and concisely. "
            "Do not discuss weather unless the user asks about it."
        )

    messages: list[dict[str, Any]] = [
        {
            "role": "system",
            "content": system_prompt,
        },
        {
            "role": "user",
            "content": user_message,
        },
    ]

    try:

        # ----------------------------------------------------
        # Normal conversation
        # ----------------------------------------------------

        if not weather_request:

            response = await call_llm(
                messages=messages,
                use_tools=False,
            )

            assistant_message = (
                response["choices"][0]["message"]
            )

            return {
                "model": settings.LLM_MODEL,
                "answer": assistant_message.get(
                    "content",
                    "",
                ),
                "tool_used": None,
            }

        # ----------------------------------------------------
        # Weather request
        #
        # Llama is used only to determine the location/tool
        # arguments.
        # ----------------------------------------------------

        response = await call_llm(
            messages=messages,
            use_tools=True,
        )

        assistant_message = (
            response["choices"][0]["message"]
        )

        tool_calls = assistant_message.get(
            "tool_calls",
            [],
        )

        # ----------------------------------------------------
        # Llama failed to call weather tool
        # ----------------------------------------------------

        if not tool_calls:

            return {
                "model": settings.LLM_MODEL,
                "answer": (
                    "I understood this as a weather question, "
                    "but I could not determine the location. "
                    "Please include a city or location, for "
                    "example: 'What is the weather in Riyadh?'"
                ),
                "tool_used": None,
            }

        # ----------------------------------------------------
        # Execute weather tool
        # ----------------------------------------------------

        tool_call = tool_calls[0]

        function = tool_call.get(
            "function",
            {},
        )

        tool_name = function.get("name")

        raw_arguments = function.get(
            "arguments",
            "{}",
        )

        if isinstance(
            raw_arguments,
            str,
        ):
            arguments = json.loads(
                raw_arguments
            )
        else:
            arguments = raw_arguments

        tool_result = await execute_tool(
            tool_name,
            arguments,
        )

        # ----------------------------------------------------
        # IMPORTANT:
        #
        # Do NOT send weather data back through Llama.
        #
        # Open-Meteo is the authoritative source.
        # Formatting it directly prevents the model from
        # claiming it has no real-time access or inventing
        # different weather values.
        # ----------------------------------------------------

        answer = format_weather(
            tool_result
        )

        return {
            "model": settings.LLM_MODEL,
            "answer": answer,
            "tool_used": [
                {
                    "name": tool_name,
                    "arguments": arguments,
                }
            ],
            "data": tool_result,
        }

    # ========================================================
    # Error handling
    # ========================================================

    except json.JSONDecodeError as exc:

        raise HTTPException(
            status_code=502,
            detail=(
                "Invalid tool arguments returned "
                f"by LLM: {exc}"
            ),
        )

    except ValueError as exc:

        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )

    except httpx.HTTPStatusError as exc:

        raise HTTPException(
            status_code=503,
            detail=(
                "LLM or weather provider returned "
                f"HTTP {exc.response.status_code}"
            ),
        )

    except httpx.RequestError as exc:

        raise HTTPException(
            status_code=503,
            detail=(
                "External service unavailable: "
                f"{type(exc).__name__}: {str(exc)}"
            ),
        )

    except Exception as exc:

        raise HTTPException(
            status_code=503,
            detail=(
                "AI service unavailable: "
                f"{type(exc).__name__}: {str(exc)}"
            ),
        )