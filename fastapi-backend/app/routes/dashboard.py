"""
Dashboard Statistics Routes
Provides real-time statistics for admin dashboard
"""

from fastapi import APIRouter, HTTPException, status, Depends, Query
from typing import Optional
import logging
from datetime import datetime, timedelta

from ..auth.dependencies import get_current_user, CurrentUser
from ..database_complete import db_complete as db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/dashboard", tags=["Dashboard"])


@router.get("/stats")
async def get_dashboard_stats(
    company_id: Optional[str] = Query(None, description="Company ID"),
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get dashboard statistics for company admin
    
    Returns:
    - totalEmployees: Total active employees
    - presentToday: Employees present today
    - absentToday: Employees absent today
    - onLeaveToday: Employees on leave today
    - lateToday: Employees who came late today
    - attendanceRateToday: Attendance percentage for today
    - attendanceRateMonth: Attendance percentage for current month
    - pendingLeaveRequests: Leave requests awaiting approval
    - upcomingBirthdays: Birthdays in next 7 days
    """
    try:
        # Use current user's company if not super_admin
        target_company_id = company_id if current_user.role == 'super_admin' else current_user.company_id
        
        if not target_company_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Company ID is required"
            )
        
        logger.info(f"📊 Fetching dashboard stats for company: {target_company_id}")
        
        # Get total active employees - USE DIRECT METHOD
        total_employees = await db.get_company_employee_count(target_company_id)
        
        # Get today's date
        today = datetime.utcnow().date()
        
        # Get attendance stats for today
        # Check if attendance table exists
        try:
            attendance_today_result = await db.execute_query(
                """
                SELECT 
                    COUNT(DISTINCT employee_id) FILTER (WHERE status = 'present') as present,
                    COUNT(DISTINCT employee_id) FILTER (WHERE status = 'absent') as absent,
                    COUNT(DISTINCT employee_id) FILTER (WHERE status = 'late') as late
                FROM attendance
                WHERE company_id = $1 
                  AND DATE(check_in) = $2
                """,
                target_company_id,
                today
            )
            
            if attendance_today_result:
                present_today = attendance_today_result[0]['present'] or 0
                absent_today = attendance_today_result[0]['absent'] or 0
                late_today = attendance_today_result[0]['late'] or 0
            else:
                present_today = 0
                absent_today = 0
                late_today = 0
        except Exception as e:
            logger.warning(f"Attendance table not accessible: {e}")
            present_today = 0
            absent_today = 0
            late_today = 0
        
        # Get employees on leave today
        try:
            on_leave_result = await db.execute_query(
                """
                SELECT COUNT(DISTINCT employee_id) as count
                FROM leaves
                WHERE company_id = $1
                  AND status = 'approved'
                  AND start_date <= $2
                  AND end_date >= $2
                """,
                target_company_id,
                today
            )
            on_leave_today = on_leave_result[0]['count'] if on_leave_result else 0
        except Exception as e:
            logger.warning(f"Leaves table not accessible: {e}")
            on_leave_today = 0
        
        # Calculate attendance rate for today
        if total_employees > 0:
            attendance_rate_today = (present_today / total_employees) * 100
        else:
            attendance_rate_today = 0.0
        
        # Get attendance rate for current month
        month_start = datetime(today.year, today.month, 1).date()
        try:
            month_attendance_result = await db.execute_query(
                """
                SELECT 
                    COUNT(*) FILTER (WHERE status = 'present') as present_days,
                    COUNT(DISTINCT DATE(check_in)) as working_days,
                    COUNT(DISTINCT employee_id) as unique_employees
                FROM attendance
                WHERE company_id = $1
                  AND DATE(check_in) >= $2
                  AND DATE(check_in) <= $3
                """,
                target_company_id,
                month_start,
                today
            )
            
            if month_attendance_result and month_attendance_result[0]['working_days']:
                present_days = month_attendance_result[0]['present_days'] or 0
                working_days = month_attendance_result[0]['working_days'] or 1
                attendance_rate_month = (present_days / (total_employees * working_days)) * 100 if total_employees > 0 else 0.0
            else:
                attendance_rate_month = 0.0
        except Exception as e:
            logger.warning(f"Monthly attendance calculation error: {e}")
            attendance_rate_month = 0.0
        
        # Get pending leave requests
        try:
            pending_leaves_result = await db.execute_query(
                """
                SELECT COUNT(*) as count
                FROM leaves
                WHERE company_id = $1 AND status = 'pending'
                """,
                target_company_id
            )
            pending_leave_requests = pending_leaves_result[0]['count'] if pending_leaves_result else 0
        except Exception as e:
            logger.warning(f"Pending leaves calculation error: {e}")
            pending_leave_requests = 0
        
        # Get upcoming birthdays (next 7 days)
        # Note: This requires a date_of_birth column which may not exist
        upcoming_birthdays = []
        
        # Get department-wise attendance
        departments = []
        try:
            dept_stats = await db.execute_query(
                """
                SELECT 
                    d.id,
                    d.name,
                    COUNT(DISTINCT p.id) as employee_count,
                    COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.employee_id END) as present_today,
                    COUNT(DISTINCT CASE WHEN a.status = 'absent' THEN a.employee_id END) as absent_today
                FROM departments d
                LEFT JOIN profiles p ON p.department_id = d.id AND p.company_id = $1 AND p.is_active = true
                LEFT JOIN attendance a ON a.employee_id = p.id AND DATE(a.check_in) = $2
                WHERE d.company_id = $1
                GROUP BY d.id, d.name
                ORDER BY employee_count DESC
                """,
                target_company_id,
                today
            )
            departments = [
                {
                    "id": row['id'],
                    "name": row['name'],
                    "employeeCount": row['employee_count'] or 0,
                    "presentToday": row['present_today'] or 0,
                    "absentToday": row['absent_today'] or 0
                }
                for row in (dept_stats or [])
            ]
        except Exception as e:
            logger.warning(f"Department stats error: {e}")
        
        # Get recent check-ins
        recent_check_ins = []
        try:
            recent_data = await db.execute_query(
                """
                SELECT 
                    a.employee_id as profile_id,
                    p.full_name as profile_name,
                    a.check_in,
                    CASE 
                        WHEN a.check_in::time <= '09:15:00' THEN 'on_time'
                        WHEN a.check_in::time <= '10:00:00' THEN 'late'
                        ELSE 'very_late'
                    END as status,
                    p.profile_picture_url
                FROM attendance a
                JOIN profiles p ON p.id = a.employee_id
                WHERE a.company_id = $1 AND DATE(a.check_in) = $2
                ORDER BY a.check_in DESC
                LIMIT 10
                """,
                target_company_id,
                today
            )
            recent_check_ins = [
                {
                    "profileId": row['profile_id'],
                    "profileName": row['profile_name'],
                    "checkIn": row['check_in'].isoformat() if hasattr(row['check_in'], 'isoformat') else str(row['check_in']),
                    "status": row['status'],
                    "profilePictureUrl": row.get('profile_picture_url')
                }
                for row in (recent_data or [])
            ]
        except Exception as e:
            logger.warning(f"Recent check-ins error: {e}")
        
        stats = {
            "totalEmployees": total_employees,
            "presentToday": present_today,
            "absentToday": absent_today,
            "onLeave": on_leave_today,
            "lateToday": late_today,
            "attendanceRateToday": round(attendance_rate_today, 1),
            "attendanceRateMonth": round(attendance_rate_month, 1),
            "pendingLeaveRequests": pending_leave_requests,
            "departments": departments,
            "recentCheckIns": recent_check_ins,
            "upcomingBirthdays": upcoming_birthdays,
            "lastUpdated": datetime.utcnow().isoformat()
        }
        
        logger.info(f"✅ Dashboard stats: {total_employees} employees, {present_today} present today")
        
        return stats
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Dashboard stats error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch dashboard statistics: {str(e)}"
        )


@router.get("/recent-activity")
async def get_recent_activity(
    limit: int = Query(10, ge=1, le=50),
    current_user: CurrentUser = Depends(get_current_user)
):
    """Get recent activity feed for dashboard"""
    try:
        company_id = current_user.company_id
        
        if not company_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Company ID is required"
            )
        
        # Get recent activities from audit logs if table exists
        try:
            activities = await db.execute_query(
                """
                SELECT 
                    al.action,
                    al.entity_type,
                    al.created_at,
                    p.full_name as user_name,
                    p.email as user_email
                FROM audit_logs al
                LEFT JOIN profiles p ON al.profile_id = p.id
                WHERE al.company_id = $1
                ORDER BY al.created_at DESC
                LIMIT $2
                """,
                company_id,
                limit
            )
            
            return {
                "success": True,
                "activities": activities or []
            }
        except Exception as e:
            logger.warning(f"Audit logs not available: {e}")
            return {
                "success": True,
                "activities": []
            }
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Recent activity error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch recent activity: {str(e)}"
        )


@router.get("/employee-distribution")
async def get_employee_distribution(
    current_user: CurrentUser = Depends(get_current_user)
):
    """Get employee distribution by role and department"""
    try:
        company_id = current_user.company_id
        
        if not company_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Company ID is required"
            )
        
        # Distribution by role
        role_distribution = await db.execute_query(
            """
            SELECT role, COUNT(*) as count
            FROM profiles
            WHERE company_id = $1 AND is_active = true
            GROUP BY role
            ORDER BY count DESC
            """,
            company_id
        )
        
        # Distribution by department
        try:
            dept_distribution = await db.execute_query(
                """
                SELECT 
                    COALESCE(d.name, 'Unassigned') as department,
                    COUNT(p.id) as count
                FROM profiles p
                LEFT JOIN departments d ON p.department_id = d.id
                WHERE p.company_id = $1 AND p.is_active = true
                GROUP BY d.name
                ORDER BY count DESC
                """,
                company_id
            )
        except Exception as e:
            logger.warning(f"Department distribution error: {e}")
            dept_distribution = []
        
        return {
            "success": True,
            "byRole": role_distribution or [],
            "byDepartment": dept_distribution or []
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Employee distribution error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch employee distribution: {str(e)}"
        )
