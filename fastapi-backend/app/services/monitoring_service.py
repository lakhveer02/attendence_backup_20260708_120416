"""
Enterprise Monitoring and Metrics Service
Prometheus metrics integration for production monitoring
"""

from prometheus_client import Counter, Histogram, Gauge, Info
from typing import Dict, Any
import time
import psutil
import logging

logger = logging.getLogger(__name__)


# ============================================================================
# REQUEST METRICS
# ============================================================================

# HTTP request counter
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

# HTTP request duration
http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0)
)

# Active requests
http_requests_in_progress = Gauge(
    'http_requests_in_progress',
    'Number of HTTP requests in progress',
    ['method', 'endpoint']
)


# ============================================================================
# AUTHENTICATION METRICS
# ============================================================================

# Login attempts
login_attempts_total = Counter(
    'login_attempts_total',
    'Total login attempts',
    ['status', 'method']
)

# Token operations
token_operations_total = Counter(
    'token_operations_total',
    'Total token operations',
    ['operation', 'status']
)

# Session duration
session_duration_seconds = Histogram(
    'session_duration_seconds',
    'User session duration in seconds',
    buckets=(60, 300, 600, 1800, 3600, 7200, 14400, 28800)
)


# ============================================================================
# ATTENDANCE METRICS
# ============================================================================

# Attendance operations
attendance_operations_total = Counter(
    'attendance_operations_total',
    'Total attendance operations',
    ['operation', 'status']
)

# Face recognition operations
face_recognition_operations_total = Counter(
    'face_recognition_operations_total',
    'Total face recognition operations',
    ['operation', 'status']
)

# Face recognition duration
face_recognition_duration_seconds = Histogram(
    'face_recognition_duration_seconds',
    'Face recognition processing time',
    ['operation'],
    buckets=(0.1, 0.25, 0.5, 1.0, 2.0, 3.0, 5.0, 10.0)
)


# ============================================================================
# DATABASE METRICS
# ============================================================================

# Database queries
db_queries_total = Counter(
    'db_queries_total',
    'Total database queries',
    ['table', 'operation', 'status']
)

# Query duration
db_query_duration_seconds = Histogram(
    'db_query_duration_seconds',
    'Database query duration in seconds',
    ['table', 'operation'],
    buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0)
)

# Connection pool
db_connections_active = Gauge(
    'db_connections_active',
    'Number of active database connections'
)


# ============================================================================
# CACHE METRICS
# ============================================================================

# Cache operations
cache_operations_total = Counter(
    'cache_operations_total',
    'Total cache operations',
    ['operation', 'status']
)

# Cache hit rate
cache_hits_total = Counter(
    'cache_hits_total',
    'Total cache hits'
)

cache_misses_total = Counter(
    'cache_misses_total',
    'Total cache misses'
)

# Cache operation duration
cache_operation_duration_seconds = Histogram(
    'cache_operation_duration_seconds',
    'Cache operation duration',
    ['operation'],
    buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1)
)


# ============================================================================
# BUSINESS METRICS
# ============================================================================

# Active users
active_users = Gauge(
    'active_users',
    'Number of active users',
    ['company_id']
)

# Active companies
active_companies = Gauge(
    'active_companies',
    'Number of active companies'
)

# Attendance today
attendance_today_total = Gauge(
    'attendance_today_total',
    'Number of attendance records today',
    ['company_id']
)

# Leave requests pending
leave_requests_pending = Gauge(
    'leave_requests_pending',
    'Number of pending leave requests',
    ['company_id']
)


# ============================================================================
# SYSTEM METRICS
# ============================================================================

# Application info
app_info = Info(
    'app_info',
    'Application information'
)

# System resources
system_cpu_usage_percent = Gauge(
    'system_cpu_usage_percent',
    'System CPU usage percentage'
)

system_memory_usage_percent = Gauge(
    'system_memory_usage_percent',
    'System memory usage percentage'
)

system_disk_usage_percent = Gauge(
    'system_disk_usage_percent',
    'System disk usage percentage'
)


# ============================================================================
# MONITORING SERVICE CLASS
# ============================================================================

class MonitoringService:
    """
    Enterprise monitoring service for metrics collection and observability
    
    Features:
    - Prometheus metrics integration
    - Request tracking
    - Performance monitoring
    - Business metrics
    - System health
    """
    
    def __init__(self):
        self.start_time = time.time()
        logger.info("Monitoring service initialized")
    
    # ------------------------------------------------------------------------
    # REQUEST TRACKING
    # ------------------------------------------------------------------------
    
    def track_request(self, method: str, endpoint: str, status_code: int):
        """Track HTTP request"""
        http_requests_total.labels(
            method=method,
            endpoint=endpoint,
            status=status_code
        ).inc()
    
    def track_request_duration(self, method: str, endpoint: str, duration: float):
        """Track request duration"""
        http_request_duration_seconds.labels(
            method=method,
            endpoint=endpoint
        ).observe(duration)
    
    def start_request(self, method: str, endpoint: str):
        """Mark request start"""
        http_requests_in_progress.labels(
            method=method,
            endpoint=endpoint
        ).inc()
    
    def end_request(self, method: str, endpoint: str):
        """Mark request end"""
        http_requests_in_progress.labels(
            method=method,
            endpoint=endpoint
        ).dec()
    
    # ------------------------------------------------------------------------
    # AUTHENTICATION TRACKING
    # ------------------------------------------------------------------------
    
    def track_login(self, success: bool, method: str = "password"):
        """Track login attempt"""
        status = "success" if success else "failed"
        login_attempts_total.labels(status=status, method=method).inc()
    
    def track_token_operation(self, operation: str, success: bool):
        """Track token operation (refresh, validate, revoke)"""
        status = "success" if success else "failed"
        token_operations_total.labels(operation=operation, status=status).inc()
    
    def track_session_duration(self, duration_seconds: float):
        """Track session duration"""
        session_duration_seconds.observe(duration_seconds)
    
    # ------------------------------------------------------------------------
    # ATTENDANCE TRACKING
    # ------------------------------------------------------------------------
    
    def track_attendance_operation(self, operation: str, success: bool):
        """Track attendance operation (checkin, checkout, correction)"""
        status = "success" if success else "failed"
        attendance_operations_total.labels(operation=operation, status=status).inc()
    
    def track_face_recognition(self, operation: str, success: bool, duration: float):
        """Track face recognition operation"""
        status = "success" if success else "failed"
        face_recognition_operations_total.labels(operation=operation, status=status).inc()
        face_recognition_duration_seconds.labels(operation=operation).observe(duration)
    
    # ------------------------------------------------------------------------
    # DATABASE TRACKING
    # ------------------------------------------------------------------------
    
    def track_db_query(self, table: str, operation: str, success: bool, duration: float):
        """Track database query"""
        status = "success" if success else "failed"
        db_queries_total.labels(table=table, operation=operation, status=status).inc()
        db_query_duration_seconds.labels(table=table, operation=operation).observe(duration)
    
    def update_db_connections(self, count: int):
        """Update active database connections count"""
        db_connections_active.set(count)
    
    # ------------------------------------------------------------------------
    # CACHE TRACKING
    # ------------------------------------------------------------------------
    
    def track_cache_hit(self):
        """Track cache hit"""
        cache_hits_total.inc()
        cache_operations_total.labels(operation="get", status="hit").inc()
    
    def track_cache_miss(self):
        """Track cache miss"""
        cache_misses_total.inc()
        cache_operations_total.labels(operation="get", status="miss").inc()
    
    def track_cache_operation(self, operation: str, duration: float):
        """Track cache operation duration"""
        cache_operation_duration_seconds.labels(operation=operation).observe(duration)
    
    def get_cache_hit_rate(self) -> float:
        """Calculate cache hit rate"""
        try:
            hits = cache_hits_total._value.get()
            misses = cache_misses_total._value.get()
            total = hits + misses
            return (hits / total * 100) if total > 0 else 0.0
        except Exception as e:
            logger.error(f"Error calculating cache hit rate: {e}")
            return 0.0
    
    # ------------------------------------------------------------------------
    # BUSINESS METRICS
    # ------------------------------------------------------------------------
    
    def update_active_users(self, company_id: str, count: int):
        """Update active users count for company"""
        active_users.labels(company_id=company_id).set(count)
    
    def update_active_companies(self, count: int):
        """Update total active companies"""
        active_companies.set(count)
    
    def update_attendance_today(self, company_id: str, count: int):
        """Update today's attendance count"""
        attendance_today_total.labels(company_id=company_id).set(count)
    
    def update_pending_leave_requests(self, company_id: str, count: int):
        """Update pending leave requests"""
        leave_requests_pending.labels(company_id=company_id).set(count)
    
    # ------------------------------------------------------------------------
    # SYSTEM HEALTH
    # ------------------------------------------------------------------------
    
    def update_system_metrics(self):
        """Update system resource metrics"""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            system_cpu_usage_percent.set(cpu_percent)
            
            # Memory usage
            memory = psutil.virtual_memory()
            system_memory_usage_percent.set(memory.percent)
            
            # Disk usage
            disk = psutil.disk_usage('/')
            system_disk_usage_percent.set(disk.percent)
            
        except Exception as e:
            logger.error(f"Error updating system metrics: {e}")
    
    def set_app_info(self, version: str, environment: str):
        """Set application information"""
        app_info.info({
            'version': version,
            'environment': environment,
            'uptime_seconds': str(int(time.time() - self.start_time))
        })
    
    # ------------------------------------------------------------------------
    # HEALTH CHECK
    # ------------------------------------------------------------------------
    
    def get_health_status(self) -> Dict[str, Any]:
        """Get current health status"""
        try:
            cpu = psutil.cpu_percent(interval=0.1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            return {
                "status": "healthy",
                "uptime_seconds": int(time.time() - self.start_time),
                "system": {
                    "cpu_percent": cpu,
                    "memory_percent": memory.percent,
                    "memory_available_gb": round(memory.available / (1024**3), 2),
                    "disk_percent": disk.percent,
                    "disk_free_gb": round(disk.free / (1024**3), 2)
                },
                "cache_hit_rate_percent": round(self.get_cache_hit_rate(), 2)
            }
        except Exception as e:
            logger.error(f"Error getting health status: {e}")
            return {
                "status": "degraded",
                "error": str(e)
            }
    
    def get_metrics_summary(self) -> Dict[str, Any]:
        """Get summary of key metrics"""
        return {
            "requests": {
                "total": http_requests_total._metrics,
                "in_progress": http_requests_in_progress._metrics
            },
            "authentication": {
                "login_attempts": login_attempts_total._metrics,
                "token_operations": token_operations_total._metrics
            },
            "cache": {
                "hit_rate_percent": round(self.get_cache_hit_rate(), 2),
                "hits": cache_hits_total._value.get(),
                "misses": cache_misses_total._value.get()
            },
            "system": self.get_health_status()
        }


# Global monitoring service instance
monitoring_service = MonitoringService()


# Middleware for automatic request tracking
"""
Example usage in FastAPI middleware:

from app.services.monitoring_service import monitoring_service
import time

@app.middleware("http")
async def monitoring_middleware(request: Request, call_next):
    start_time = time.time()
    
    method = request.method
    endpoint = request.url.path
    
    monitoring_service.start_request(method, endpoint)
    
    try:
        response = await call_next(request)
        
        duration = time.time() - start_time
        monitoring_service.track_request(method, endpoint, response.status_code)
        monitoring_service.track_request_duration(method, endpoint, duration)
        
        return response
    finally:
        monitoring_service.end_request(method, endpoint)
"""
