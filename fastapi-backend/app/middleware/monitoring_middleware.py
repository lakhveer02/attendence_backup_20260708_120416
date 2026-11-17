"""
Monitoring Middleware
Automatically tracks all HTTP requests
"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.services.monitoring_service import monitoring_service
import time
import logging

logger = logging.getLogger(__name__)


class MonitoringMiddleware(BaseHTTPMiddleware):
    """
    Middleware to automatically track request metrics
    
    Tracks:
    - Request count by endpoint and method
    - Request duration
    - Response status codes
    - Concurrent requests
    """
    
    async def dispatch(self, request: Request, call_next):
        # Extract request details
        method = request.method
        endpoint = request.url.path
        
        # Skip metrics endpoint to avoid recursion
        if endpoint.startswith("/monitoring/metrics"):
            return await call_next(request)
        
        # Mark request start
        start_time = time.time()
        monitoring_service.start_request(method, endpoint)
        
        try:
            # Process request
            response = await call_next(request)
            
            # Calculate duration
            duration = time.time() - start_time
            
            # Track metrics
            monitoring_service.track_request(method, endpoint, response.status_code)
            monitoring_service.track_request_duration(method, endpoint, duration)
            
            # Log slow requests (> 1 second)
            if duration > 1.0:
                logger.warning(
                    f"Slow request detected: {method} {endpoint} took {duration:.2f}s"
                )
            
            return response
            
        except Exception as e:
            # Track failed requests
            duration = time.time() - start_time
            monitoring_service.track_request(method, endpoint, 500)
            monitoring_service.track_request_duration(method, endpoint, duration)
            
            logger.error(f"Request failed: {method} {endpoint} - {str(e)}")
            raise
            
        finally:
            # Always mark request end
            monitoring_service.end_request(method, endpoint)


class AuditLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware to automatically log requests for audit purposes
    
    Logs:
    - User identity
    - IP address
    - Request details
    - Timestamps
    """
    
    async def dispatch(self, request: Request, call_next):
        # Store request context for audit logging
        request.state.client_ip = request.client.host if request.client else "unknown"
        request.state.user_agent = request.headers.get("user-agent", "unknown")
        request.state.request_id = request.headers.get("x-request-id", "")
        
        # Process request
        response = await call_next(request)
        
        return response
