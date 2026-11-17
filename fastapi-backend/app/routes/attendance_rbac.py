"""
Attendance Routes with RBAC Enforcement
Example implementation of permission matrix for attendance features
"""

from fastapi import APIRouter, HTTPException, status, Depends, Query
from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
import logging

from ..auth.dependencies import get_current_user, CurrentUser
from ..auth.rbac import (
    Permission,
    require_permission,
    require_any_permission,
    check_team_access,
    can_access_resource,
)
from ..middleware import get_current_workspace_id
from ..database_complete import db_complete as db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/attendance-rbac", tags=["Attendance RBAC"])


# ==================== REQUEST/RESPONSE MODELS ====================

class AttendanceMarkRequest(BaseModel):
    """Request to mark attendance"""
    check_in_time: Optional[datetime] = None
    check_out_time: Optional[datetime] = None
    location_lat: Optional[float] = None
    location_long: Optional[float] = None
    notes: Optional[str] = None


# ==================== ATTENDANCE ENDPOINTS WITH RBAC ====================

@router.get("/my-attendance")
@require_permission(Permission.VIEW_OWN_ATTENDANCE)
async def get_my_attendance(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get current user's own attendance records
    
    Permission: VIEW_OWN_ATTENDANCE
    Roles: All (employee, manager, hr_manager, company_admin)
    Scope: Self only
    """
    try:
        workspace_id = get_current_workspace_id()
        
        query = """
            SELECT 
                a.id,
                a.profile_id,
                a.check_in,
                a.check_out,
                a.status,
                a.check_in_gps,
                a.check_out_gps,
                a.created_at
            FROM attendance a
            WHERE a.workspace_id = $1
              AND a.profile_id = $2
        """
        
        params = [workspace_id, current_user.user_id]
        param_count = 2
        
        if start_date:
            param_count += 1
            query += f" AND DATE(a.check_in) >= ${param_count}"
            params.append(start_date)
        
        if end_date:
            param_count += 1
            query += f" AND DATE(a.check_in) <= ${param_count}"
            params.append(end_date)
        
        query += " ORDER BY a.check_in DESC"
        
        records = await db.execute_query(query, *params)
        
        return {
            "success": True,
            "count": len(records),
            "records": [dict(r) for r in records]
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to get attendance: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/team-attendance")
@require_permission(Permission.VIEW_TEAM_ATTENDANCE)
async def get_team_attendance(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get attendance for manager's direct reports only
    
    Permission: VIEW_TEAM_ATTENDANCE
    Roles: manager
    Scope: Direct reports only (team-scoped)
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Get direct reports (users who report to current user)
        query = """
            SELECT 
                a.id,
                a.profile_id,
                p.full_name,
                p.email,
                a.check_in,
                a.check_out,
                a.status,
                a.check_in_gps,
                a.check_out_gps,
                a.created_at
            FROM attendance a
            INNER JOIN profiles p ON a.profile_id = p.id
            WHERE a.workspace_id = $1
              AND p.reporting_manager_id = $2
        """
        
        params = [workspace_id, current_user.user_id]
        param_count = 2
        
        if start_date:
            param_count += 1
            query += f" AND DATE(a.check_in) >= ${param_count}"
            params.append(start_date)
        
        if end_date:
            param_count += 1
            query += f" AND DATE(a.check_in) <= ${param_count}"
            params.append(end_date)
        
        query += " ORDER BY a.check_in DESC"
        
        records = await db.execute_query(query, *params)
        
        return {
            "success": True,
            "count": len(records),
            "scope": "team",
            "records": [dict(r) for r in records]
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to get team attendance: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/all-attendance")
@require_permission(Permission.VIEW_ALL_ATTENDANCE)
async def get_all_attendance(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    department_id: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get all attendance records in workspace
    
    Permission: VIEW_ALL_ATTENDANCE
    Roles: company_admin, hr_manager
    Scope: All users in workspace
    """
    try:
        workspace_id = get_current_workspace_id()
        
        query = """
            SELECT 
                a.id,
                a.profile_id,
                p.full_name,
                p.email,
                p.department_id,
                d.name as department_name,
                a.check_in,
                a.check_out,
                a.status,
                a.check_in_gps,
                a.check_out_gps,
                a.created_at
            FROM attendance a
            INNER JOIN profiles p ON a.profile_id = p.id
            LEFT JOIN departments d ON p.department_id = d.id
            WHERE a.workspace_id = $1
        """
        
        params = [workspace_id]
        param_count = 1
        
        if start_date:
            param_count += 1
            query += f" AND DATE(a.check_in) >= ${param_count}"
            params.append(start_date)
        
        if end_date:
            param_count += 1
            query += f" AND DATE(a.check_in) <= ${param_count}"
            params.append(end_date)
        
        if department_id:
            param_count += 1
            query += f" AND p.department_id = ${param_count}"
            params.append(department_id)
        
        query += " ORDER BY a.check_in DESC LIMIT 1000"
        
        records = await db.execute_query(query, *params)
        
        return {
            "success": True,
            "count": len(records),
            "scope": "all",
            "records": [dict(r) for r in records]
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to get all attendance: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/mark-attendance")
@require_permission(Permission.MARK_ATTENDANCE)
async def mark_attendance(
    request: AttendanceMarkRequest,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Mark attendance (check-in/check-out)
    
    Permission: MARK_ATTENDANCE
    Roles: All (employee, manager, hr_manager, company_admin)
    Scope: Self only
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Create attendance record
        attendance_data = {
            "workspace_id": workspace_id,
            "profile_id": current_user.user_id,
            "check_in": request.check_in_time or datetime.now(),
            "check_out": request.check_out_time,
            "status": "present",
            "check_in_gps": {
                "latitude": request.location_lat,
                "longitude": request.location_long
            } if request.location_lat else None,
            "notes": request.notes
        }
        
        # In production, this would call db.create_attendance()
        # For now, just return success
        
        logger.info(f"✅ Attendance marked by {current_user.email}")
        
        return {
            "success": True,
            "message": "Attendance marked successfully",
            "attendance": attendance_data
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to mark attendance: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/user/{user_id}/attendance")
async def get_user_attendance(
    user_id: str,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get specific user's attendance with team-scoped access check
    
    Access Rules:
    - Employee: Can only access own data
    - Manager: Can access direct reports + own data
    - HR Manager/Company Admin: Can access all users
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Check team access
        has_access = await check_team_access(current_user, user_id, db)
        
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied. You can only access your team members' data."
            )
        
        query = """
            SELECT 
                a.id,
                a.profile_id,
                a.check_in,
                a.check_out,
                a.status,
                a.check_in_gps,
                a.check_out_gps,
                a.created_at
            FROM attendance a
            WHERE a.workspace_id = $1
              AND a.profile_id = $2
        """
        
        params = [workspace_id, user_id]
        param_count = 2
        
        if start_date:
            param_count += 1
            query += f" AND DATE(a.check_in) >= ${param_count}"
            params.append(start_date)
        
        if end_date:
            param_count += 1
            query += f" AND DATE(a.check_in) <= ${param_count}"
            params.append(end_date)
        
        query += " ORDER BY a.check_in DESC"
        
        records = await db.execute_query(query, *params)
        
        return {
            "success": True,
            "user_id": user_id,
            "count": len(records),
            "records": [dict(r) for r in records]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to get user attendance: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/reports/summary")
@require_any_permission(Permission.VIEW_ALL_REPORTS, Permission.VIEW_TEAM_REPORTS)
async def get_attendance_summary(
    start_date: date,
    end_date: date,
    department_id: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get attendance summary report
    
    Permission: VIEW_ALL_REPORTS or VIEW_TEAM_REPORTS
    Roles: company_admin, hr_manager (all), manager (team only)
    Scope: Based on role
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Determine scope based on role
        if current_user.role in ["company_admin", "hr_manager"]:
            scope = "all"
            base_condition = "a.workspace_id = $1"
            params = [workspace_id]
        elif current_user.role == "manager":
            scope = "team"
            base_condition = "a.workspace_id = $1 AND p.reporting_manager_id = $2"
            params = [workspace_id, current_user.user_id]
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permission denied"
            )
        
        # Build query for summary
        query = f"""
            SELECT 
                COUNT(DISTINCT a.profile_id) as total_employees,
                COUNT(a.id) as total_attendance_records,
                COUNT(DISTINCT DATE(a.check_in)) as total_working_days,
                AVG(
                    CASE 
                        WHEN a.check_out IS NOT NULL 
                        THEN EXTRACT(EPOCH FROM (a.check_out - a.check_in)) / 3600
                        ELSE NULL
                    END
                ) as avg_hours_worked
            FROM attendance a
            INNER JOIN profiles p ON a.profile_id = p.id
            WHERE {base_condition}
              AND DATE(a.check_in) BETWEEN $3 AND $4
        """
        
        params.extend([start_date, end_date])
        
        if department_id:
            query += " AND p.department_id = $5"
            params.append(department_id)
        
        result = await db.execute_query(query, *params)
        summary = dict(result[0]) if result else {}
        
        return {
            "success": True,
            "scope": scope,
            "period": {
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat()
            },
            "summary": summary
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to get attendance summary: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# ==================== PERMISSION CHECK ENDPOINT ====================

@router.get("/check-permissions")
async def check_attendance_permissions(
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Check what attendance permissions the current user has
    Useful for frontend UI conditional rendering
    """
    permissions = {
        "can_view_own": can_access_resource(current_user.role, "attendance", "own"),
        "can_view_team": can_access_resource(current_user.role, "attendance", "team"),
        "can_view_all": can_access_resource(current_user.role, "attendance", "all"),
        "can_mark": current_user.role in ["employee", "manager", "hr_manager", "company_admin"],
        "can_approve": current_user.role in ["manager", "hr_manager", "company_admin"],
        "can_edit": current_user.role in ["hr_manager", "company_admin"],
    }
    
    return {
        "success": True,
        "role": current_user.role,
        "permissions": permissions
    }
