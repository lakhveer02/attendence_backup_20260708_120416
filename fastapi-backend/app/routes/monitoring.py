"""
Monitoring and Health Check Endpoints
"""

from fastapi import APIRouter, Depends
from fastapi.responses import PlainTextResponse
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from app.services.monitoring_service import monitoring_service
from app.auth.dependencies import get_current_user, CurrentUser
from typing import Dict, Any

router = APIRouter(prefix="/monitoring", tags=["monitoring"])


@router.get("/health", summary="Health check endpoint")
async def health_check() -> Dict[str, Any]:
    """
    Public health check endpoint for load balancers and monitoring
    
    Returns:
        - status: healthy/degraded/unhealthy
        - uptime: seconds since start
        - system: CPU, memory, disk metrics
    """
    return monitoring_service.get_health_status()


@router.get("/metrics", response_class=PlainTextResponse, summary="Prometheus metrics")
async def metrics():
    """
    Prometheus metrics endpoint
    
    Exposes all application metrics in Prometheus format
    Should be scraped by Prometheus server
    """
    # Update system metrics before exposing
    monitoring_service.update_system_metrics()
    
    return PlainTextResponse(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )


@router.get("/metrics/summary", summary="Metrics summary (requires auth)")
async def metrics_summary(current_user: CurrentUser = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Human-readable metrics summary
    
    Requires authentication
    Only accessible to admins
    """
    # Check if user is admin/company_admin
    user_role = current_user.role
    if user_role not in ["super_admin", "company_admin"]:
        return {"error": "Unauthorized. Admin access required."}
    
    return monitoring_service.get_metrics_summary()


@router.get("/ping", summary="Simple ping endpoint")
async def ping() -> Dict[str, str]:
    """
    Simplest possible health check
    Returns immediately with 200 OK
    """
    return {"status": "ok", "message": "pong"}
