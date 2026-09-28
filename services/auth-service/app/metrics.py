import time

from fastapi import FastAPI, Request, Response
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)


HTTP_REQUESTS = Counter(
    "http_requests_total",
    "Total number of HTTP requests",
    ["service", "method", "path", "status"],
)

HTTP_REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["service", "method", "path"],
)

HTTP_REQUESTS_IN_PROGRESS = Gauge(
    "http_requests_in_progress",
    "Number of HTTP requests currently being processed",
    ["service", "method", "path"],
)


def setup_metrics(
    app: FastAPI,
    service_name: str,
) -> None:

    @app.middleware("http")
    async def prometheus_middleware(
        request: Request,
        call_next,
    ):
        if request.url.path == "/metrics":
            return await call_next(request)

        method = request.method
        path = request.url.path

        HTTP_REQUESTS_IN_PROGRESS.labels(
            service=service_name,
            method=method,
            path=path,
        ).inc()

        start_time = time.perf_counter()
        status = "500"

        try:
            response = await call_next(request)
            status = str(response.status_code)
            return response

        finally:
            duration = time.perf_counter() - start_time

            HTTP_REQUESTS.labels(
                service=service_name,
                method=method,
                path=path,
                status=status,
            ).inc()

            HTTP_REQUEST_DURATION.labels(
                service=service_name,
                method=method,
                path=path,
            ).observe(duration)

            HTTP_REQUESTS_IN_PROGRESS.labels(
                service=service_name,
                method=method,
                path=path,
            ).dec()

    @app.get(
        "/metrics",
        include_in_schema=False,
    )
    def metrics():
        return Response(
            content=generate_latest(),
            media_type=CONTENT_TYPE_LATEST,
        )