"""
Workspace Isolation Middleware
Enforces strict multi-tenant data isolation at the database layer.
Every query MUST be filtered by workspace_id to prevent cross-tenant data leaks.
"""

from fastapi import Request, HTTPException, status
from typing import Optional, Callable
import logging

logger = logging.getLogger(__name__)


class WorkspaceContext:
    """Thread-local workspace context for request scope"""
    def __init__(self):
        self.workspace_id: Optional[str] = None
        self.user_id: Optional[str] = None
        self.user_role: Optional[str] = None


# Global context instance
workspace_context = WorkspaceContext()


def get_current_workspace_id() -> str:
    """Get current workspace ID from context"""
    if not workspace_context.workspace_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Workspace context not set. This is a critical security violation."
        )
    return workspace_context.workspace_id


def get_current_user_id() -> str:
    """Get current user ID from context"""
    if not workspace_context.user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User context not set"
        )
    return workspace_context.user_id


def get_current_user_role() -> str:
    """Get current user role from context"""
    if not workspace_context.user_role:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User role not set"
        )
    return workspace_context.user_role


async def workspace_isolation_middleware(request: Request, call_next: Callable):
    """
    Middleware to extract and validate workspace context from JWT token.
    Sets workspace_id in thread-local context for automatic query filtering.
    
    CRITICAL SECURITY RULES:
    1. All authenticated requests MUST have workspace_id in token
    2. workspace_id is automatically injected into all DB queries
    3. Cross-tenant data access is FORBIDDEN
    """
    
    # Skip for public endpoints
    public_paths = [
        "/docs",
        "/openapi.json",
        "/health",
        "/api/v1/auth/login",
        "/api/v1/auth/forgot-password",
        "/api/v1/auth/join",
        "/api/v1/auth/resolve-workspace",
        "/api/v1/role-management/role-hierarchy",
    ]
    
    if any(request.url.path.startswith(path) for path in public_paths):
        return await call_next(request)
    
    # Extract workspace_id from JWT token in Authorization header
    auth_header = request.headers.get("Authorization")
    
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.split(" ")[1]
        
        try:
            # Decode JWT and extract workspace_id
            from ..auth.jwt_handler import jwt_handler
            payload = jwt_handler.decode_token(token)
            
            workspace_id = payload.get("company_id")
            user_id = payload.get("sub")
            user_role = payload.get("role")
            
            # Set context for this request
            workspace_context.workspace_id = workspace_id
            workspace_context.user_id = user_id
            workspace_context.user_role = user_role
            
            logger.debug(f"🔐 Workspace context set: workspace={workspace_id}, user={user_id}, role={user_role}")
            
        except Exception as e:
            logger.error(f"❌ Failed to extract workspace context: {e}")
            # Continue without setting context - will fail on protected endpoints
    
    try:
        response = await call_next(request)
        return response
    finally:
        # Clear context after request
        workspace_context.workspace_id = None
        workspace_context.user_id = None
        workspace_context.user_role = None


class WorkspaceFilter:
    """
    Database query filter to automatically inject workspace_id.
    MUST be used for ALL queries to prevent cross-tenant data leaks.
    """
    
    @staticmethod
    def add_workspace_filter(base_query: str, table_alias: str = None) -> str:
        """
        Add workspace_id filter to SQL query.
        
        Args:
            base_query: Original SQL query
            table_alias: Optional table alias (e.g., 'p' for 'profiles p')
            
        Returns:
            Modified query with workspace filter
        """
        workspace_id = get_current_workspace_id()
        
        prefix = f"{table_alias}." if table_alias else ""
        filter_clause = f"{prefix}workspace_id = '{workspace_id}'"
        
        # Add WHERE or AND based on existing query
        if "WHERE" in base_query.upper():
            return f"{base_query} AND {filter_clause}"
        else:
            return f"{base_query} WHERE {filter_clause}"
    
    @staticmethod
    def get_workspace_condition(table_alias: str = None) -> dict:
        """
        Get workspace filter as dict for ORM queries.
        
        Returns:
            {'workspace_id': 'current-workspace-id'}
        """
        return {"workspace_id": get_current_workspace_id()}
    
    @staticmethod
    def validate_workspace_access(resource_workspace_id: str):
        """
        Validate that resource belongs to current workspace.
        Raises exception if workspace mismatch (potential security breach).
        
        Args:
            resource_workspace_id: The workspace_id of the resource being accessed
        """
        current_workspace = get_current_workspace_id()
        
        if resource_workspace_id != current_workspace:
            logger.critical(
                f"🚨 SECURITY VIOLATION: Cross-tenant access attempt! "
                f"Current workspace: {current_workspace}, "
                f"Requested resource workspace: {resource_workspace_id}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied. Resource does not belong to your workspace."
            )


# Convenience functions for common use cases
def ensure_workspace_scoped_query(query: str, table_alias: str = None) -> str:
    """Wrapper to ensure query is workspace-scoped"""
    return WorkspaceFilter.add_workspace_filter(query, table_alias)


def get_workspace_filter() -> dict:
    """Get workspace filter dict for ORM"""
    return WorkspaceFilter.get_workspace_condition()


def validate_resource_access(resource_workspace_id: str):
    """Validate resource belongs to current workspace"""
    WorkspaceFilter.validate_workspace_access(resource_workspace_id)
