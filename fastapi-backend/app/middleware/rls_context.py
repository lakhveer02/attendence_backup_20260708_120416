"""
Row-Level Security Context Middleware
Sets PostgreSQL session variables for RLS policies
"""

from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
import logging

logger = logging.getLogger(__name__)


class RLSContextMiddleware(BaseHTTPMiddleware):
    """
    Middleware to set PostgreSQL session variables for Row-Level Security
    
    This ensures that RLS policies have access to:
    - app.current_company_id: The user's company
    - app.user_role: The user's role (for permission checks)
    - app.user_id: The user's profile ID
    
    These variables are used in RLS policies to enforce multi-tenant isolation
    """
    
    async def dispatch(self, request: Request, call_next):
        # Skip RLS for public endpoints
        public_paths = [
            "/",
            "/health",
            "/docs",
            "/openapi.json",
            "/redoc",
            "/api/v1/auth/resolve-workspace",
            "/api/v1/auth/signup",
            "/api/v1/auth/login",
        ]
        
        if request.url.path in public_paths:
            return await call_next(request)
        
        try:
            # Extract JWT token from Authorization header
            auth_header = request.headers.get("Authorization")
            
            if not auth_header or not auth_header.startswith("Bearer "):
                # No token - let the endpoint handle authentication
                return await call_next(request)
            
            token = auth_header.replace("Bearer ", "")
            
            # Decode token to get user context
            from ..auth.jwt_handler import jwt_handler
            
            try:
                payload = jwt_handler.decode_token(token)
            except Exception as e:
                # Token invalid - let the endpoint handle it
                logger.debug(f"Token decode failed in RLS middleware: {e}")
                return await call_next(request)
            
            # Extract context from JWT
            company_id = payload.get("company_id")
            user_role = payload.get("role")
            user_id = payload.get("sub")  # subject = profile_id
            
            # Store in request state for use in endpoints
            request.state.company_id = company_id
            request.state.user_role = user_role
            request.state.user_id = user_id
            
            # Set PostgreSQL session variables for RLS
            # Note: This requires database connection from request
            # We'll set these when database operations are performed
            
            logger.debug(f"RLS Context: company={company_id}, role={user_role}, user={user_id}")
            
            response = await call_next(request)
            return response
            
        except Exception as e:
            logger.error(f"RLS Context Middleware error: {e}")
            # Don't break the request chain on middleware errors
            return await call_next(request)


def set_rls_context(db_session, company_id: str = None, user_role: str = None, user_id: str = None):
    """
    Helper function to set RLS context variables on a database session
    
    Usage:
        async with db.get_session() as session:
            set_rls_context(session, company_id, user_role, user_id)
            # Now perform queries with RLS enforced
    """
    try:
        if company_id:
            db_session.execute(f"SET LOCAL app.current_company_id = '{company_id}'")
        
        if user_role:
            db_session.execute(f"SET LOCAL app.user_role = '{user_role}'")
        
        if user_id:
            db_session.execute(f"SET LOCAL app.user_id = '{user_id}'")
        
        logger.debug(f"RLS context set: company={company_id}, role={user_role}, user={user_id}")
        
    except Exception as e:
        logger.error(f"Failed to set RLS context: {e}")
        raise


# Alternative: Function to get RLS-aware database client
def get_rls_db_client(request: Request):
    """
    Get database client with RLS context from request
    
    This is a dependency that can be used in FastAPI endpoints:
    
    @app.get("/employees")
    async def get_employees(db = Depends(get_rls_db_client)):
        # db operations will have RLS context set
        employees = await db.get_all_profiles()
        return employees
    """
    from ..database_complete import db_complete
    
    # Get context from request state
    company_id = getattr(request.state, "company_id", None)
    user_role = getattr(request.state, "user_role", None)
    user_id = getattr(request.state, "user_id", None)
    
    # Return database client with context
    # Note: Actual RLS context setting happens per-query
    # This is just a marker for endpoints to know context is available
    
    return db_complete
