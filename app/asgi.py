"""ASGI entrypoint used as a stub when FastAPI can't be loaded.

This module tries to import the real FastAPI `app` from `app.main`.
If that import fails due to native build blockers (pydantic/pydantic-core issues
on Windows), it falls back to a minimal Starlette app that implements the
`/health` and `/version` endpoints so Uvicorn can be verified during dev.

Per project rules, this is a temporary stub and will be replaced with the
full FastAPI app once the runtime dependencies are available.
"""

try:
    # Prefer the real FastAPI app if import succeeds
    from .main import app  # type: ignore
except Exception:
    # Import failed (likely due to missing pydantic-core or other native deps).
    # Provide a minimal ASGI app using Starlette as a stub so the server can run.
    from starlette.applications import Starlette
    from starlette.responses import JSONResponse
    from starlette.routing import Route
    import time

    APP_VERSION = "0.1.0"

    async def health(request):
        start = getattr(request.app.state, "start_time", None)
        uptime = None
        if start:
            uptime = round(time.time() - start, 2)
        return JSONResponse({"status": "ok", "uptime_seconds": uptime})

    async def version(request):
        return JSONResponse({"version": APP_VERSION, "service": "ArogyaKrishi Backend (stub)"})

    routes = [Route("/health", health), Route("/version", version)]
    app = Starlette(routes=routes)
    # set a start time similar to the FastAPI startup handler
    app.state.start_time = time.time()

__all__ = ["app"]
