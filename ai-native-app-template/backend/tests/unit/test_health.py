"""Health endpoint tests — always present, always passing."""

import pytest
from httpx import AsyncClient


async def test_health_returns_200(client: AsyncClient):
    """Health endpoint must return 200 so load balancers and Podman HEALTHCHECK pass."""
    response = await client.get("/health")
    assert response.status_code == 200


async def test_health_returns_status_ok(client: AsyncClient):
    response = await client.get("/health")
    body = response.json()
    assert body["status"] == "ok"


async def test_health_returns_version(client: AsyncClient):
    """Version field lets ops-agent confirm which build is running."""
    response = await client.get("/health")
    assert "version" in response.json()


async def test_metrics_endpoint_accessible(client: AsyncClient):
    """Prometheus scraper must be able to reach /metrics."""
    response = await client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
