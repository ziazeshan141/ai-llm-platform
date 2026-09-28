import httpx

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings

from .metrics import setup_metrics


# ============================================================
# Configuration
# ============================================================

class Settings(BaseSettings):
    AUTH_SERVICE_URL: str = "http://localhost:8001"
    AI_SERVICE_URL: str = "http://localhost:8002"
    RAG_SERVICE_URL: str = "http://localhost:8003"


settings = Settings()


# ============================================================
# FastAPI Application
# ============================================================

app = FastAPI(
    title="API Gateway",
    version="2.0.0",
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:8088",
    ],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# Prometheus Metrics
# ============================================================

setup_metrics(
    app,
    service_name="api-gateway",
)


# ============================================================
# Health Check
# ============================================================

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "api-gateway",
    }


# ============================================================
# Generic Proxy
# ============================================================

async def proxy(
    request: Request,
    upstream_url: str,
):
    try:
        async with httpx.AsyncClient(
            timeout=120
        ) as client:

            response = await client.request(
                method=request.method,
                url=upstream_url,
                params=request.query_params,
                content=await request.body(),
                headers={
                    key: value
                    for key, value in request.headers.items()
                    if key.lower()
                    not in {
                        "host",
                        "content-length",
                    }
                },
            )

    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Upstream unavailable",
        )

    return Response(
        content=response.content,
        status_code=response.status_code,
        media_type=response.headers.get(
            "content-type"
        ),
    )


# ============================================================
# Auth Service Proxy
# ============================================================

@app.api_route(
    "/api/v1/auth/{path:path}",
    methods=[
        "GET",
        "POST",
        "PUT",
        "DELETE",
        "PATCH",
    ],
)
async def auth_proxy(
    path: str,
    request: Request,
):
    upstream_url = (
        f"{settings.AUTH_SERVICE_URL}"
        f"/api/v1/auth/{path}"
    )

    return await proxy(
        request,
        upstream_url,
    )


# ============================================================
# AI Service Proxy
# ============================================================

@app.api_route(
    "/api/v1/ai/{path:path}",
    methods=[
        "GET",
        "POST",
        "PUT",
        "DELETE",
        "PATCH",
    ],
)
async def ai_proxy(
    path: str,
    request: Request,
):
    upstream_url = (
        f"{settings.AI_SERVICE_URL}"
        f"/api/v1/ai/{path}"
    )

    return await proxy(
        request,
        upstream_url,
    )


# ============================================================
# RAG Service Proxy
# ============================================================

@app.api_route(
    "/api/v1/rag/{path:path}",
    methods=[
        "GET",
        "POST",
        "PUT",
        "DELETE",
        "PATCH",
    ],
)
async def rag_proxy(
    path: str,
    request: Request,
):
    upstream_url = (
        f"{settings.RAG_SERVICE_URL}"
        f"/api/v1/rag/{path}"
    )

    return await proxy(
        request,
        upstream_url,
    )