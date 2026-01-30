"""Application entrypoint for ArogyaKrishi backend.

FastAPI app with detection endpoints, database setup, ML model integration.
"""

from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import time as _time

from app.config import settings
from app.db.session import engine, Base
from sqlalchemy import text
from app.services.ml_service import load_models
from app.services.remedy_service import load_remedies
from app.api.detection import router as detection_router

APP_VERSION = "0.1.0"

app = FastAPI(title="ArogyaKrishi Backend", version=APP_VERSION)

# Logging setup
logger = logging.getLogger("arogyakrishi")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

# CORS configuration
ALLOWED_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
    "http://localhost:8000",
    "http://localhost:8001",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def on_startup() -> None:
    """Initialize application on startup."""
    logger.info("Starting ArogyaKrishi backend (version=%s)", APP_VERSION)
    
    # Record start time
    app.state.start_time = _time.time()
    
    # Create database tables
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
            await conn.execute(
                text("ALTER TABLE users ADD COLUMN IF NOT EXISTS language VARCHAR")
            )
        logger.info("Database initialized")
    except Exception as e:
        logger.error(f"Database initialization error: {e}")
    
    # Load ML models
    try:
        load_models()
        logger.info("ML models loaded")
    except Exception as e:
        logger.warning(f"ML model loading error: {e}")
    
    # Load remedies
    try:
        load_remedies()
        logger.info("Remedies loaded")
    except Exception as e:
        logger.warning(f"Remedies loading error: {e}")


@app.on_event("shutdown")
async def on_shutdown() -> None:
    """Cleanup on shutdown."""
    logger.info("Shutting down ArogyaKrishi backend")
    await engine.dispose()


@app.get("/health", response_class=JSONResponse, status_code=status.HTTP_200_OK)
async def health() -> JSONResponse:
    """Health check endpoint."""
    start = getattr(app.state, "start_time", None)
    uptime = None
    if start:
        uptime = round(_time.time() - start, 2)
    payload = {"status": "ok", "uptime_seconds": uptime}
    return JSONResponse(content=payload)


@app.get("/version", response_class=JSONResponse, status_code=status.HTTP_200_OK)
async def version() -> JSONResponse:
    """Return application version."""
    payload = {"version": APP_VERSION, "service": "ArogyaKrishi Backend"}
    return JSONResponse(content=payload)


# Include routers
app.include_router(detection_router)

__all__ = ["app"]
