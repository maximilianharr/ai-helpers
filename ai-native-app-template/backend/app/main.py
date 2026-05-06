"""
AI-Native FastAPI Application
==============================
Entry point. Structured for AI agent modification:
- Every section is clearly labeled
- Config is 100% env-var driven
- Health + metrics endpoints always present
- Structured JSON logging from startup
"""

from __future__ import annotations

import logging
import os
import time
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from prometheus_fastapi_instrumentator import Instrumentator

# ─── Logging Setup (structured JSON) ─────────────────────────────────────────
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ]
)
log = structlog.get_logger()

# ─── App Lifespan (startup / shutdown) ───────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info("startup", environment=os.getenv("APP_ENV", "development"))
    # TODO: initialize DB connection pool, Redis, etc.
    yield
    log.info("shutdown")


# ─── Application ─────────────────────────────────────────────────────────────
app = FastAPI(
    title=os.getenv("APP_NAME", "AI-Native App"),
    version=os.getenv("APP_VERSION", "0.0.1"),
    docs_url="/api/docs" if os.getenv("APP_ENV") != "production" else None,
    redoc_url=None,
    lifespan=lifespan,
)

# ─── Middleware ───────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "http://localhost").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Prometheus Metrics ───────────────────────────────────────────────────────
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


# ─── Request Logging Middleware ───────────────────────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = (time.perf_counter() - start) * 1000
    log.info(
        "request",
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        duration_ms=round(duration_ms, 2),
    )
    return response


# ─── Health Endpoint (required by all containers) ────────────────────────────
@app.get("/health", tags=["ops"])
async def health():
    return {"status": "ok", "version": os.getenv("APP_VERSION", "0.0.1")}


# ─── API Routers (add as features are implemented) ───────────────────────────
# from app.api import auth, users, items
# app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
# app.include_router(users.router, prefix="/api/users", tags=["users"])


# ─── Global Exception Handler ────────────────────────────────────────────────
@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    log.error(
        "unhandled_exception",
        path=request.url.path,
        error=str(exc),
        exc_info=True,
    )
    return JSONResponse(
        status_code=500,
        content={"error": "internal_server_error", "detail": "An unexpected error occurred."},
    )
