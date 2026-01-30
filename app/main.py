"""Application entrypoint for ArogyaKrishi backend.

This file initializes the FastAPI app object. Additional middleware, routers,
startup/shutdown handlers, and endpoints will be added in subsequent checklist
steps (one checkbox at a time).
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

APP_VERSION = "0.1.0"

app = FastAPI(title="ArogyaKrishi Backend", version=APP_VERSION)

# CORS configuration — keep permissive for development, tighten in production
ALLOWED_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup / shutdown handlers
import logging
from typing import Any

logger = logging.getLogger("arogyakrishi")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

@app.on_event("startup")
async def on_startup() -> None:
    """Run initialization tasks at application startup.

    - Load ML model (placeholder)
    - Initialize DB connections (placeholder)
    - Load remedy data (placeholder)
    """
    logger.info("Starting ArogyaKrishi backend (version=%s)", APP_VERSION)
    # record start time for uptime
    import time

    app.state.start_time = time.time()
    # TODO: load_model(), init_db(), load_remedies()

@app.on_event("shutdown")
async def on_shutdown() -> None:
    """Cleanup tasks at application shutdown."""
    logger.info("Shutting down ArogyaKrishi backend")

# Health and version endpoints
from fastapi import status
from fastapi.responses import JSONResponse
import time as _time


@app.get("/health", response_class=JSONResponse, status_code=status.HTTP_200_OK)
async def health() -> JSONResponse:
    """Simple health endpoint returning status and uptime (seconds)."""
    start = getattr(app.state, "start_time", None)
    uptime = None
    if start:
        uptime = round(_time.time() - start, 2)
    payload = {"status": "ok", "uptime_seconds": uptime}
    return JSONResponse(content=payload)


@app.get("/version", response_class=JSONResponse, status_code=status.HTTP_200_OK)
async def version() -> JSONResponse:
    """Return application version and description."""
    payload = {"version": APP_VERSION, "service": "ArogyaKrishi Backend"}
    return JSONResponse(content=payload)

# TODO: add routers per checklist items
__all__ = ["app"]
