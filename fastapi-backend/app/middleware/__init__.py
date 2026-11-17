"""
Middleware Package
Contains FastAPI middleware for security and performance
"""

from .rls_context import RLSContextMiddleware, set_rls_context, get_rls_db_client
from .monitoring_middleware import MonitoringMiddleware, AuditLoggingMiddleware
from .workspace_isolation import workspace_isolation_middleware

# Workspace context helper
def get_current_workspace_id():
    """
    Get current workspace ID from context
    For now, returns None and relies on company_id from JWT
    """
    return None

__all__ = [
    "RLSContextMiddleware",
    "set_rls_context",
    "get_rls_db_client",
    "MonitoringMiddleware",
    "AuditLoggingMiddleware",
    "workspace_isolation_middleware",
    "get_current_workspace_id",
]
