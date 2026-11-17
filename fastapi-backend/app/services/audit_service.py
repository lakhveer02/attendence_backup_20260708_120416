"""
Enterprise Audit Logging Service
Tracks all critical operations for security and compliance
"""

from datetime import datetime, timezone
from typing import Optional, Dict, Any
from enum import Enum
import json
import logging
from supabase import Client

logger = logging.getLogger(__name__)


class AuditAction(str, Enum):
    """Comprehensive audit action types"""
    # Authentication
    LOGIN_SUCCESS = "login_success"
    LOGIN_FAILED = "login_failed"
    LOGOUT = "logout"
    TOKEN_REFRESH = "token_refresh"
    PASSWORD_RESET = "password_reset"
    PASSWORD_CHANGE = "password_change"
    
    # User Management
    USER_CREATED = "user_created"
    USER_UPDATED = "user_updated"
    USER_DELETED = "user_deleted"
    USER_ACTIVATED = "user_activated"
    USER_DEACTIVATED = "user_deactivated"
    
    # Attendance
    ATTENDANCE_CHECKIN = "attendance_checkin"
    ATTENDANCE_CHECKOUT = "attendance_checkout"
    ATTENDANCE_CORRECTED = "attendance_corrected"
    ATTENDANCE_APPROVED = "attendance_approved"
    
    # Leave
    LEAVE_REQUESTED = "leave_requested"
    LEAVE_APPROVED = "leave_approved"
    LEAVE_REJECTED = "leave_rejected"
    LEAVE_CANCELLED = "leave_cancelled"
    
    # Company
    COMPANY_CREATED = "company_created"
    COMPANY_UPDATED = "company_updated"
    COMPANY_SETTINGS_CHANGED = "company_settings_changed"
    
    # Department
    DEPARTMENT_CREATED = "department_created"
    DEPARTMENT_UPDATED = "department_updated"
    DEPARTMENT_DELETED = "department_deleted"
    
    # Role & Permissions
    ROLE_ASSIGNED = "role_assigned"
    ROLE_REVOKED = "role_revoked"
    PERMISSION_GRANTED = "permission_granted"
    PERMISSION_REVOKED = "permission_revoked"
    
    # Security
    UNAUTHORIZED_ACCESS = "unauthorized_access"
    PERMISSION_DENIED = "permission_denied"
    SUSPICIOUS_ACTIVITY = "suspicious_activity"
    DATA_EXPORT = "data_export"
    
    # System
    SYSTEM_BACKUP = "system_backup"
    SYSTEM_RESTORE = "system_restore"


class AuditSeverity(str, Enum):
    """Audit event severity levels"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class AuditService:
    """
    Enterprise-grade audit logging service
    
    Features:
    - Comprehensive action tracking
    - Immutable audit trail
    - Structured logging
    - Compliance-ready
    - Performance optimized
    """
    
    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client
    
    async def log(
        self,
        action: AuditAction,
        user_id: Optional[str],
        company_id: Optional[str],
        severity: AuditSeverity = AuditSeverity.INFO,
        resource_type: Optional[str] = None,
        resource_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        success: bool = True,
        error_message: Optional[str] = None
    ) -> bool:
        """
        Log an audit event
        
        Args:
            action: Type of action performed
            user_id: ID of user performing action
            company_id: Company context
            severity: Event severity level
            resource_type: Type of resource affected (user, attendance, leave, etc.)
            resource_id: ID of affected resource
            details: Additional structured data
            ip_address: Client IP address
            user_agent: Client user agent
            success: Whether action succeeded
            error_message: Error details if failed
        
        Returns:
            bool: True if logged successfully
        """
        try:
            audit_entry = {
                "action": action.value,
                "user_id": user_id,
                "company_id": company_id,
                "severity": severity.value,
                "resource_type": resource_type,
                "resource_id": resource_id,
                "details": json.dumps(details) if details else None,
                "ip_address": ip_address,
                "user_agent": user_agent,
                "success": success,
                "error_message": error_message,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            # Insert into audit_logs table
            result = self.supabase.table("audit_logs").insert(audit_entry).execute()
            
            # Also log to application logs for immediate monitoring
            log_level = {
                AuditSeverity.INFO: logging.INFO,
                AuditSeverity.WARNING: logging.WARNING,
                AuditSeverity.ERROR: logging.ERROR,
                AuditSeverity.CRITICAL: logging.CRITICAL
            }.get(severity, logging.INFO)
            
            logger.log(
                log_level,
                f"AUDIT: {action.value} | User: {user_id} | Company: {company_id} | Success: {success}"
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to log audit event: {str(e)}", exc_info=True)
            # Never fail the main operation due to audit logging failure
            return False
    
    async def log_authentication(
        self,
        action: AuditAction,
        user_id: Optional[str],
        company_id: Optional[str],
        ip_address: str,
        user_agent: str,
        success: bool,
        details: Optional[Dict[str, Any]] = None,
        error_message: Optional[str] = None
    ) -> bool:
        """Log authentication events"""
        return await self.log(
            action=action,
            user_id=user_id,
            company_id=company_id,
            severity=AuditSeverity.WARNING if not success else AuditSeverity.INFO,
            resource_type="authentication",
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
            success=success,
            error_message=error_message
        )
    
    async def log_data_access(
        self,
        action: AuditAction,
        user_id: str,
        company_id: str,
        resource_type: str,
        resource_id: str,
        ip_address: str,
        details: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Log data access events"""
        return await self.log(
            action=action,
            user_id=user_id,
            company_id=company_id,
            severity=AuditSeverity.INFO,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            ip_address=ip_address,
            success=True
        )
    
    async def log_security_event(
        self,
        action: AuditAction,
        user_id: Optional[str],
        company_id: Optional[str],
        ip_address: str,
        user_agent: str,
        details: Dict[str, Any],
        severity: AuditSeverity = AuditSeverity.WARNING
    ) -> bool:
        """Log security-related events"""
        return await self.log(
            action=action,
            user_id=user_id,
            company_id=company_id,
            severity=severity,
            resource_type="security",
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
            success=False
        )
    
    async def get_user_audit_trail(
        self,
        user_id: str,
        company_id: str,
        limit: int = 100,
        offset: int = 0
    ) -> list:
        """Get audit trail for a specific user"""
        try:
            result = (
                self.supabase.table("audit_logs")
                .select("*")
                .eq("user_id", user_id)
                .eq("company_id", company_id)
                .order("timestamp", desc=True)
                .limit(limit)
                .offset(offset)
                .execute()
            )
            return result.data
        except Exception as e:
            logger.error(f"Failed to retrieve audit trail: {str(e)}")
            return []
    
    async def get_company_audit_trail(
        self,
        company_id: str,
        action: Optional[AuditAction] = None,
        severity: Optional[AuditSeverity] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 100,
        offset: int = 0
    ) -> list:
        """Get audit trail for entire company with filters"""
        try:
            query = (
                self.supabase.table("audit_logs")
                .select("*")
                .eq("company_id", company_id)
            )
            
            if action:
                query = query.eq("action", action.value)
            
            if severity:
                query = query.eq("severity", severity.value)
            
            if start_date:
                query = query.gte("timestamp", start_date.isoformat())
            
            if end_date:
                query = query.lte("timestamp", end_date.isoformat())
            
            result = (
                query
                .order("timestamp", desc=True)
                .limit(limit)
                .offset(offset)
                .execute()
            )
            return result.data
        except Exception as e:
            logger.error(f"Failed to retrieve company audit trail: {str(e)}")
            return []
    
    async def get_security_events(
        self,
        company_id: str,
        severity: AuditSeverity = AuditSeverity.WARNING,
        hours: int = 24,
        limit: int = 100
    ) -> list:
        """Get recent security events"""
        try:
            cutoff_time = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
            
            result = (
                self.supabase.table("audit_logs")
                .select("*")
                .eq("company_id", company_id)
                .eq("resource_type", "security")
                .gte("timestamp", cutoff_time.isoformat())
                .order("timestamp", desc=True)
                .limit(limit)
                .execute()
            )
            return result.data
        except Exception as e:
            logger.error(f"Failed to retrieve security events: {str(e)}")
            return []
    
    async def get_audit_statistics(
        self,
        company_id: str,
        days: int = 30
    ) -> Dict[str, Any]:
        """Get audit statistics for dashboard"""
        try:
            # This would typically use PostgreSQL aggregate queries
            # For now, returning structure for implementation
            return {
                "total_events": 0,
                "events_by_action": {},
                "events_by_severity": {},
                "events_by_day": {},
                "top_users": [],
                "security_events": 0,
                "failed_logins": 0
            }
        except Exception as e:
            logger.error(f"Failed to get audit statistics: {str(e)}")
            return {}


# Example usage in endpoints:
"""
from fastapi import Request

audit_service = AuditService(supabase)

# Log successful login
await audit_service.log_authentication(
    action=AuditAction.LOGIN_SUCCESS,
    user_id=user.id,
    company_id=user.company_id,
    ip_address=request.client.host,
    user_agent=request.headers.get("user-agent"),
    success=True,
    details={"method": "password"}
)

# Log failed access attempt
await audit_service.log_security_event(
    action=AuditAction.UNAUTHORIZED_ACCESS,
    user_id=current_user.id,
    company_id=company_id,
    ip_address=request.client.host,
    user_agent=request.headers.get("user-agent"),
    details={"resource": "payroll", "reason": "insufficient_permissions"},
    severity=AuditSeverity.WARNING
)

# Log data modification
await audit_service.log(
    action=AuditAction.USER_UPDATED,
    user_id=current_user.id,
    company_id=company_id,
    resource_type="user",
    resource_id=target_user_id,
    ip_address=request.client.host,
    details={"changed_fields": ["email", "role"]},
    success=True
)
"""
