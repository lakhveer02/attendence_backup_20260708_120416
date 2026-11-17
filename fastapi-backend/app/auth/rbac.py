"""
Role-Based Access Control (RBAC) Permission Matrix
Implements the definitive permission matrix from Architecture Blueprint

Permission Matrix:
┌─────────────────────────┬──────────────┬────────────┬─────────┬──────────┐
│ Feature                 │ Company Admin│ HR Manager │ Manager │ Employee │
├─────────────────────────┼──────────────┼────────────┼─────────┼──────────┤
│ Create HR Manager       │      ✅      │     ❌     │    ❌   │    ❌    │
│ Create Manager          │      ✅      │     ✅     │    ❌   │    ❌    │
│ Create Employee         │      ✅      │     ✅     │    ✅   │    ❌    │
│ Attendance Reports      │  ✅ (All)    │  ✅ (All)  │ ✅ (Team)│ ❌ (Own) │
│ Payroll                 │  ✅ (All)    │  ✅ (All)  │    ❌   │ ✅ (View)│
│ Leave Approval          │  ✅ (All)    │  ✅ (All)  │ ✅ (Team)│    ❌    │
│ Department Creation     │      ✅      │     ✅     │    ❌   │    ❌    │
│ Task Assignment         │      ✅      │     ✅     │    ✅   │    ❌    │
│ Company Settings        │      ✅      │     ❌     │    ❌   │    ❌    │
└─────────────────────────┴──────────────┴────────────┴─────────┴──────────┘
"""

from functools import wraps
from fastapi import HTTPException, status, Depends
from typing import List, Callable, Optional
import logging

from .dependencies import get_current_user, CurrentUser

logger = logging.getLogger(__name__)


# ==================== PERMISSION DEFINITIONS ====================

class Permission:
    """Permission constants for RBAC checks"""
    
    # User Management
    CREATE_HR_MANAGER = "create_hr_manager"
    CREATE_MANAGER = "create_manager"
    CREATE_EMPLOYEE = "create_employee"
    VIEW_ALL_USERS = "view_all_users"
    VIEW_TEAM_USERS = "view_team_users"
    EDIT_USER = "edit_user"
    DELETE_USER = "delete_user"
    ACTIVATE_DEACTIVATE_USER = "activate_deactivate_user"
    
    # Attendance
    VIEW_ALL_ATTENDANCE = "view_all_attendance"
    VIEW_TEAM_ATTENDANCE = "view_team_attendance"
    VIEW_OWN_ATTENDANCE = "view_own_attendance"
    MARK_ATTENDANCE = "mark_attendance"
    EDIT_ATTENDANCE = "edit_attendance"
    APPROVE_ATTENDANCE = "approve_attendance"
    
    # Leave Management
    VIEW_ALL_LEAVES = "view_all_leaves"
    VIEW_TEAM_LEAVES = "view_team_leaves"
    VIEW_OWN_LEAVES = "view_own_leaves"
    REQUEST_LEAVE = "request_leave"
    APPROVE_LEAVE = "approve_leave"
    REJECT_LEAVE = "reject_leave"
    CANCEL_LEAVE = "cancel_leave"
    
    # Payroll
    VIEW_ALL_PAYROLL = "view_all_payroll"
    VIEW_OWN_PAYROLL = "view_own_payroll"
    PROCESS_PAYROLL = "process_payroll"
    EDIT_PAYROLL = "edit_payroll"
    
    # Departments
    CREATE_DEPARTMENT = "create_department"
    EDIT_DEPARTMENT = "edit_department"
    DELETE_DEPARTMENT = "delete_department"
    VIEW_DEPARTMENTS = "view_departments"
    
    # Tasks & Projects
    CREATE_TASK = "create_task"
    ASSIGN_TASK = "assign_task"
    VIEW_ALL_TASKS = "view_all_tasks"
    VIEW_TEAM_TASKS = "view_team_tasks"
    VIEW_OWN_TASKS = "view_own_tasks"
    EDIT_TASK = "edit_task"
    DELETE_TASK = "delete_task"
    
    # Reports & Analytics
    VIEW_ALL_REPORTS = "view_all_reports"
    VIEW_TEAM_REPORTS = "view_team_reports"
    EXPORT_REPORTS = "export_reports"
    
    # Company Settings
    EDIT_COMPANY_SETTINGS = "edit_company_settings"
    VIEW_COMPANY_SETTINGS = "view_company_settings"
    MANAGE_SUBSCRIPTIONS = "manage_subscriptions"
    VIEW_AUDIT_LOGS = "view_audit_logs"
    
    # Recruitment (ATS)
    CREATE_JOB_POSTING = "create_job_posting"
    VIEW_APPLICATIONS = "view_applications"
    SCREEN_CANDIDATES = "screen_candidates"
    
    # Learning Management (LMS)
    CREATE_COURSE = "create_course"
    ASSIGN_COURSE = "assign_course"
    VIEW_COURSE_PROGRESS = "view_course_progress"


# ==================== ROLE-PERMISSION MAPPING ====================

ROLE_PERMISSIONS = {
    "super_admin": [
        # Super admin has all permissions
        "*"
    ],
    
    "company_admin": [
        # User Management
        Permission.CREATE_HR_MANAGER,
        Permission.CREATE_MANAGER,
        Permission.CREATE_EMPLOYEE,
        Permission.VIEW_ALL_USERS,
        Permission.EDIT_USER,
        Permission.DELETE_USER,
        Permission.ACTIVATE_DEACTIVATE_USER,
        
        # Attendance
        Permission.VIEW_ALL_ATTENDANCE,
        Permission.MARK_ATTENDANCE,
        Permission.EDIT_ATTENDANCE,
        Permission.APPROVE_ATTENDANCE,
        
        # Leave Management
        Permission.VIEW_ALL_LEAVES,
        Permission.REQUEST_LEAVE,
        Permission.APPROVE_LEAVE,
        Permission.REJECT_LEAVE,
        Permission.CANCEL_LEAVE,
        
        # Payroll
        Permission.VIEW_ALL_PAYROLL,
        Permission.PROCESS_PAYROLL,
        Permission.EDIT_PAYROLL,
        
        # Departments
        Permission.CREATE_DEPARTMENT,
        Permission.EDIT_DEPARTMENT,
        Permission.DELETE_DEPARTMENT,
        Permission.VIEW_DEPARTMENTS,
        
        # Tasks
        Permission.CREATE_TASK,
        Permission.ASSIGN_TASK,
        Permission.VIEW_ALL_TASKS,
        Permission.EDIT_TASK,
        Permission.DELETE_TASK,
        
        # Reports
        Permission.VIEW_ALL_REPORTS,
        Permission.EXPORT_REPORTS,
        
        # Company Settings
        Permission.EDIT_COMPANY_SETTINGS,
        Permission.VIEW_COMPANY_SETTINGS,
        Permission.MANAGE_SUBSCRIPTIONS,
        Permission.VIEW_AUDIT_LOGS,
        
        # Recruitment & LMS
        Permission.CREATE_JOB_POSTING,
        Permission.VIEW_APPLICATIONS,
        Permission.SCREEN_CANDIDATES,
        Permission.CREATE_COURSE,
        Permission.ASSIGN_COURSE,
        Permission.VIEW_COURSE_PROGRESS,
    ],
    
    "hr_manager": [
        # User Management
        Permission.CREATE_MANAGER,
        Permission.CREATE_EMPLOYEE,
        Permission.VIEW_ALL_USERS,
        Permission.EDIT_USER,
        Permission.ACTIVATE_DEACTIVATE_USER,
        
        # Attendance
        Permission.VIEW_ALL_ATTENDANCE,
        Permission.MARK_ATTENDANCE,
        Permission.APPROVE_ATTENDANCE,
        
        # Leave Management
        Permission.VIEW_ALL_LEAVES,
        Permission.REQUEST_LEAVE,
        Permission.APPROVE_LEAVE,
        Permission.REJECT_LEAVE,
        
        # Payroll
        Permission.VIEW_ALL_PAYROLL,
        Permission.PROCESS_PAYROLL,
        Permission.EDIT_PAYROLL,
        
        # Departments
        Permission.CREATE_DEPARTMENT,
        Permission.EDIT_DEPARTMENT,
        Permission.VIEW_DEPARTMENTS,
        
        # Tasks
        Permission.CREATE_TASK,
        Permission.ASSIGN_TASK,
        Permission.VIEW_ALL_TASKS,
        Permission.EDIT_TASK,
        
        # Reports
        Permission.VIEW_ALL_REPORTS,
        Permission.EXPORT_REPORTS,
        
        # Recruitment & LMS
        Permission.CREATE_JOB_POSTING,
        Permission.VIEW_APPLICATIONS,
        Permission.SCREEN_CANDIDATES,
        Permission.CREATE_COURSE,
        Permission.ASSIGN_COURSE,
        Permission.VIEW_COURSE_PROGRESS,
    ],
    
    "manager": [
        # User Management (Team only)
        Permission.CREATE_EMPLOYEE,
        Permission.VIEW_TEAM_USERS,
        
        # Attendance (Team only)
        Permission.VIEW_TEAM_ATTENDANCE,
        Permission.MARK_ATTENDANCE,
        
        # Leave Management (Team only)
        Permission.VIEW_TEAM_LEAVES,
        Permission.REQUEST_LEAVE,
        Permission.APPROVE_LEAVE,  # For direct reports only
        
        # Tasks (Team only)
        Permission.CREATE_TASK,
        Permission.ASSIGN_TASK,
        Permission.VIEW_TEAM_TASKS,
        Permission.EDIT_TASK,
        
        # Reports (Team only)
        Permission.VIEW_TEAM_REPORTS,
        
        # Departments (View only)
        Permission.VIEW_DEPARTMENTS,
    ],
    
    "employee": [
        # Self-service only
        Permission.VIEW_OWN_ATTENDANCE,
        Permission.MARK_ATTENDANCE,
        Permission.VIEW_OWN_LEAVES,
        Permission.REQUEST_LEAVE,
        Permission.CANCEL_LEAVE,  # Own leaves only
        Permission.VIEW_OWN_PAYROLL,
        Permission.VIEW_OWN_TASKS,
        Permission.VIEW_DEPARTMENTS,
    ],
}


# ==================== PERMISSION CHECK FUNCTIONS ====================

def has_permission(user_role: str, permission: str) -> bool:
    """
    Check if a role has a specific permission
    
    Args:
        user_role: Role of the user (e.g., 'company_admin')
        permission: Permission to check (e.g., Permission.CREATE_EMPLOYEE)
        
    Returns:
        bool: True if role has permission
    """
    # Super admin has all permissions
    if user_role == "super_admin":
        return True
    
    permissions = ROLE_PERMISSIONS.get(user_role, [])
    
    # Check for wildcard or specific permission
    return "*" in permissions or permission in permissions


def check_permission(user: CurrentUser, permission: str):
    """
    Check permission and raise exception if denied
    
    Args:
        user: Current authenticated user
        permission: Permission to check
        
    Raises:
        HTTPException: 403 Forbidden if permission denied
    """
    if not has_permission(user.role, permission):
        logger.warning(
            f"🚫 Permission denied: {user.email} ({user.role}) attempted {permission}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Permission denied. Required permission: {permission}"
        )


def check_any_permission(user: CurrentUser, permissions: List[str]):
    """
    Check if user has ANY of the specified permissions
    
    Args:
        user: Current authenticated user
        permissions: List of permissions to check
        
    Raises:
        HTTPException: 403 Forbidden if all permissions denied
    """
    if any(has_permission(user.role, perm) for perm in permissions):
        return
    
    logger.warning(
        f"🚫 Permission denied: {user.email} ({user.role}) needs one of {permissions}"
    )
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=f"Permission denied. Required one of: {', '.join(permissions)}"
    )


def check_all_permissions(user: CurrentUser, permissions: List[str]):
    """
    Check if user has ALL of the specified permissions
    
    Args:
        user: Current authenticated user
        permissions: List of permissions to check
        
    Raises:
        HTTPException: 403 Forbidden if any permission denied
    """
    for perm in permissions:
        if not has_permission(user.role, perm):
            logger.warning(
                f"🚫 Permission denied: {user.email} ({user.role}) missing {perm}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied. Required permission: {perm}"
            )


# ==================== PERMISSION DECORATORS ====================

def require_permission(permission: str):
    """
    Decorator to require a specific permission for an endpoint
    
    Usage:
        @router.get("/sensitive-data")
        @require_permission(Permission.VIEW_ALL_REPORTS)
        async def get_sensitive_data(user: CurrentUser = Depends(get_current_user)):
            ...
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, current_user: CurrentUser = Depends(get_current_user), **kwargs):
            check_permission(current_user, permission)
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator


def require_any_permission(*permissions: str):
    """
    Decorator to require ANY of the specified permissions
    
    Usage:
        @router.get("/data")
        @require_any_permission(Permission.VIEW_ALL_REPORTS, Permission.VIEW_TEAM_REPORTS)
        async def get_data(user: CurrentUser = Depends(get_current_user)):
            ...
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, current_user: CurrentUser = Depends(get_current_user), **kwargs):
            check_any_permission(current_user, list(permissions))
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator


def require_all_permissions(*permissions: str):
    """
    Decorator to require ALL of the specified permissions
    
    Usage:
        @router.post("/critical-action")
        @require_all_permissions(Permission.EDIT_PAYROLL, Permission.PROCESS_PAYROLL)
        async def critical_action(user: CurrentUser = Depends(get_current_user)):
            ...
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, current_user: CurrentUser = Depends(get_current_user), **kwargs):
            check_all_permissions(current_user, list(permissions))
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator


def require_role(*roles: str):
    """
    Decorator to require specific role(s)
    
    Usage:
        @router.post("/admin-action")
        @require_role("company_admin", "hr_manager")
        async def admin_action(user: CurrentUser = Depends(get_current_user)):
            ...
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, current_user: CurrentUser = Depends(get_current_user), **kwargs):
            if current_user.role not in roles and current_user.role != "super_admin":
                logger.warning(
                    f"🚫 Role check failed: {current_user.email} ({current_user.role}) "
                    f"needs one of {roles}"
                )
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Access denied. Required role: {' or '.join(roles)}"
                )
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator


# ==================== TEAM-SCOPED PERMISSION CHECKS ====================

async def check_team_access(current_user: CurrentUser, target_user_id: str, db) -> bool:
    """
    Check if current user has access to target user's data based on team hierarchy
    
    For Managers: Can only access direct reports
    For HR/Admin: Can access all users in workspace
    For Employee: Can only access own data
    
    Args:
        current_user: Current authenticated user
        target_user_id: ID of user whose data is being accessed
        db: Database instance
        
    Returns:
        bool: True if access allowed
    """
    # Self-access always allowed
    if current_user.user_id == target_user_id:
        return True
    
    # Super admin, company admin, hr_manager have all access
    if current_user.role in ["super_admin", "company_admin", "hr_manager"]:
        return True
    
    # Manager can only access direct reports
    if current_user.role == "manager":
        # Check if target user reports to current user
        target_user = await db.execute_query(
            """
            SELECT reporting_manager_id, workspace_id
            FROM profiles
            WHERE id = $1
            """,
            target_user_id
        )
        
        if target_user and target_user[0]['reporting_manager_id'] == current_user.user_id:
            # Also verify same workspace
            if target_user[0]['workspace_id'] == current_user.company_id:
                return True
    
    # Employee has no access to other users
    return False


def require_team_access(db):
    """
    Decorator to check team-based access for an endpoint
    
    Usage:
        @router.get("/users/{user_id}/attendance")
        @require_team_access(db)
        async def get_user_attendance(
            user_id: str,
            current_user: CurrentUser = Depends(get_current_user)
        ):
            ...
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, user_id: str, current_user: CurrentUser = Depends(get_current_user), **kwargs):
            has_access = await check_team_access(current_user, user_id, db)
            
            if not has_access:
                logger.warning(
                    f"🚫 Team access denied: {current_user.email} ({current_user.role}) "
                    f"attempted to access user {user_id}"
                )
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Access denied. You can only access your team members' data."
                )
            
            return await func(*args, user_id=user_id, current_user=current_user, **kwargs)
        return wrapper
    return decorator


# ==================== PERMISSION QUERY HELPERS ====================

def get_user_permissions(role: str) -> List[str]:
    """Get all permissions for a role"""
    if role == "super_admin":
        return ["*"]
    return ROLE_PERMISSIONS.get(role, [])


def can_access_resource(user_role: str, resource_type: str, scope: str = "all") -> bool:
    """
    Check if user can access a resource type with specific scope
    
    Args:
        user_role: User's role
        resource_type: Type of resource (attendance, leave, payroll, etc.)
        scope: Access scope (all, team, own)
        
    Returns:
        bool: True if access allowed
    """
    permission_map = {
        "attendance": {
            "all": Permission.VIEW_ALL_ATTENDANCE,
            "team": Permission.VIEW_TEAM_ATTENDANCE,
            "own": Permission.VIEW_OWN_ATTENDANCE,
        },
        "leave": {
            "all": Permission.VIEW_ALL_LEAVES,
            "team": Permission.VIEW_TEAM_LEAVES,
            "own": Permission.VIEW_OWN_LEAVES,
        },
        "task": {
            "all": Permission.VIEW_ALL_TASKS,
            "team": Permission.VIEW_TEAM_TASKS,
            "own": Permission.VIEW_OWN_TASKS,
        },
    }
    
    permission = permission_map.get(resource_type, {}).get(scope)
    if not permission:
        return False
    
    return has_permission(user_role, permission)
