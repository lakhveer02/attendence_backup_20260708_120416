"""
Supabase Database Service
Handles all database operations with proper error handling
"""

import os
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
# Use SERVICE_KEY to bypass RLS policies (for backend operations)
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", os.getenv("SUPABASE_ANON_KEY", ""))

class SupabaseDB:
    """Supabase database client wrapper"""
    
    def __init__(self):
        self.client: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # ==================== PROFILE OPERATIONS ====================
    
    async def get_profile(self, profile_id: str) -> Optional[Dict[str, Any]]:
        """Get profile by ID"""
        try:
            response = self.client.table("profiles").select("*").eq("id", profile_id).execute()
            return response.data[0] if response.data and len(response.data) > 0 else None
        except Exception:
            return None
    
    async def get_profile_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get profile by email"""
        try:
            response = self.client.table("profiles").select("*").eq("email", email).execute()
            return response.data[0] if response.data and len(response.data) > 0 else None
        except Exception:
            return None
    
    async def get_all_profiles(self) -> List[Dict[str, Any]]:
        """Get all profiles"""
        response = self.client.table("profiles").select("*").execute()
        return response.data if response.data else []
    
    async def create_profile(self, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create new profile"""
        response = self.client.table("profiles").insert(profile_data).execute()
        return response.data[0] if response.data else {}
    
    async def update_profile(self, profile_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """Update profile"""
        response = self.client.table("profiles").update(updates).eq("id", profile_id).execute()
        return response.data[0] if response.data else {}
    
    async def delete_profile(self, profile_id: str) -> bool:
        """Delete profile"""
        response = self.client.table("profiles").delete().eq("id", profile_id).execute()
        return bool(response.data)
    
    # ==================== ATTENDANCE OPERATIONS ====================
    
    async def create_attendance(self, attendance_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create attendance record"""
        response = self.client.table("attendance").insert(attendance_data).execute()
        return response.data[0] if response.data else {}
    
    async def get_attendance(self, attendance_id: str) -> Optional[Dict[str, Any]]:
        """Get attendance by ID"""
        response = self.client.table("attendance").select("*").eq("id", attendance_id).single().execute()
        return response.data if response.data else None
    
    async def get_attendance_by_profile(
        self, 
        profile_id: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None
    ) -> List[Dict[str, Any]]:
        """Get attendance records for a profile"""
        query = self.client.table("attendance").select("*").eq("profile_id", profile_id)
        
        if start_date:
            query = query.gte("check_in", start_date.isoformat())
        if end_date:
            query = query.lte("check_in", end_date.isoformat())
        
        query = query.order("check_in", desc=True)
        response = query.execute()
        return response.data if response.data else []
    
    async def get_todays_attendance(self, profile_id: str) -> Optional[Dict[str, Any]]:
        """Get today's attendance record for a profile"""
        try:
            today = datetime.now().date()
            response = (
                self.client.table("attendance")
                .select("*")
                .eq("profile_id", profile_id)
                .gte("check_in", today.isoformat())
                .execute()
            )
            return response.data[0] if response.data and len(response.data) > 0 else None
        except Exception:
            return None
    
    async def update_attendance(self, attendance_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """Update attendance record"""
        response = (
            self.client.table("attendance")
            .update(updates)
            .eq("id", attendance_id)
            .execute()
        )
        return response.data[0] if response.data else {}
    
    async def get_all_attendance_today(self) -> List[Dict[str, Any]]:
        """Get all attendance records for today"""
        today = datetime.now().date()
        response = (
            self.client.table("attendance")
            .select("*, profiles(full_name, email, department_id)")
            .gte("check_in", today.isoformat())
            .execute()
        )
        return response.data if response.data else []
    
    # ==================== LEAVE OPERATIONS ====================
    
    async def create_leave(self, leave_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create leave request"""
        response = self.client.table("leaves").insert(leave_data).execute()
        return response.data[0] if response.data else {}
    
    async def get_leave(self, leave_id: str) -> Optional[Dict[str, Any]]:
        """Get leave by ID"""
        response = self.client.table("leaves").select("*").eq("id", leave_id).single().execute()
        return response.data if response.data else None
    
    async def get_leaves_by_profile(self, profile_id: str) -> List[Dict[str, Any]]:
        """Get leave requests for a profile"""
        response = (
            self.client.table("leaves")
            .select("*")
            .eq("profile_id", profile_id)
            .order("created_at", desc=True)
            .execute()
        )
        return response.data if response.data else []
    
    async def get_pending_leaves(self) -> List[Dict[str, Any]]:
        """Get all pending leave requests"""
        response = (
            self.client.table("leaves")
            .select("*, profiles(full_name, email)")
            .eq("status", "pending")
            .order("created_at", desc=True)
            .execute()
        )
        return response.data if response.data else []
    
    async def update_leave(self, leave_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """Update leave request"""
        response = (
            self.client.table("leaves")
            .update(updates)
            .eq("id", leave_id)
            .execute()
        )
        return response.data[0] if response.data else {}
    
    async def delete_leave(self, leave_id: str) -> bool:
        """Delete leave request"""
        response = self.client.table("leaves").delete().eq("id", leave_id).execute()
        return bool(response.data)
    
    # ==================== DEPARTMENT OPERATIONS ====================
    
    async def get_all_departments(self) -> List[Dict[str, Any]]:
        """Get all departments"""
        response = self.client.table("departments").select("*").execute()
        return response.data if response.data else []
    
    async def get_department(self, department_id: str) -> Optional[Dict[str, Any]]:
        """Get department by ID"""
        response = self.client.table("departments").select("*").eq("id", department_id).single().execute()
        return response.data if response.data else None
    
    async def create_department(self, department_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create new department"""
        response = self.client.table("departments").insert(department_data).execute()
        return response.data[0] if response.data else {}
    
    async def update_department(self, department_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """Update department"""
        response = (
            self.client.table("departments")
            .update(updates)
            .eq("id", department_id)
            .execute()
        )
        return response.data[0] if response.data else {}
    
    # ==================== FACE EMBEDDING OPERATIONS ====================
    
    async def create_face_embedding(self, embedding_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create face embedding record"""
        response = self.client.table("face_embeddings").insert(embedding_data).execute()
        return response.data[0] if response.data else {}
    
    async def get_face_embedding(self, profile_id: str, is_primary: bool = True) -> Optional[Dict[str, Any]]:
        """Get face embedding for profile"""
        query = self.client.table("face_embeddings").select("*").eq("profile_id", profile_id)
        if is_primary:
            query = query.eq("is_primary", True)
        response = query.single().execute()
        return response.data if response.data else None
    
    async def update_face_embedding(self, embedding_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """Update face embedding"""
        response = (
            self.client.table("face_embeddings")
            .update(updates)
            .eq("id", embedding_id)
            .execute()
        )
        return response.data[0] if response.data else {}
    
    # ==================== DEVICE SECURITY OPERATIONS ====================
    
    async def create_device_log(self, log_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create device security log"""
        response = self.client.table("device_security_logs").insert(log_data).execute()
        return response.data[0] if response.data else {}
    
    async def get_device_logs(self, profile_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get device security logs for profile"""
        response = (
            self.client.table("device_security_logs")
            .select("*")
            .eq("profile_id", profile_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return response.data if response.data else []
    
    # ==================== NOTIFICATION OPERATIONS ====================
    
    async def create_notification(self, notification_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create notification"""
        response = self.client.table("notifications").insert(notification_data).execute()
        return response.data[0] if response.data else {}
    
    async def get_notifications(self, profile_id: str, unread_only: bool = False) -> List[Dict[str, Any]]:
        """Get notifications for profile"""
        query = self.client.table("notifications").select("*").eq("profile_id", profile_id)
        if unread_only:
            query = query.eq("is_read", False)
        response = query.order("created_at", desc=True).execute()
        return response.data if response.data else []
    
    async def mark_notification_read(self, notification_id: str) -> Dict[str, Any]:
        """Mark notification as read"""
        response = (
            self.client.table("notifications")
            .update({"is_read": True})
            .eq("id", notification_id)
            .execute()
        )
        return response.data[0] if response.data else {}
    
    # ==================== ANALYTICS OPERATIONS ====================
    
    async def get_attendance_summary(
        self,
        profile_id: Optional[str] = None,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """Get attendance summary statistics"""
        # Use the attendance_summary view created in migration
        query = self.client.table("attendance_summary").select("*")
        
        if profile_id:
            query = query.eq("profile_id", profile_id)
        
        response = query.execute()
        data = response.data[0] if response.data else {}
        
        return {
            "total_days": data.get("total_days", 0),
            "present_days": data.get("present_days", 0),
            "absent_days": data.get("absent_days", 0),
            "late_days": data.get("late_days", 0),
            "half_days": data.get("half_days", 0),
            "avg_hours_worked": data.get("avg_hours_worked"),
        }
    
    async def get_dashboard_stats(self) -> Dict[str, Any]:
        """Get dashboard statistics"""
        today = datetime.now().date()
        
        # Get total employees
        total_employees = len(await self.get_all_profiles())
        
        # Get today's attendance
        today_attendance = await self.get_all_attendance_today()
        present_today = len([a for a in today_attendance if a["status"] == "present"])
        late_today = len([a for a in today_attendance if a["status"] == "late"])
        absent_today = total_employees - len(today_attendance)
        
        # Get pending leaves
        pending_leaves = await self.get_pending_leaves()
        on_leave = len([l for l in pending_leaves if l["status"] == "approved"])
        
        return {
            "total_employees": total_employees,
            "present_today": present_today,
            "absent_today": absent_today,
            "on_leave": on_leave,
            "late_today": late_today,
            "pending_leave_requests": len(pending_leaves),
            "attendance_rate_today": (present_today / total_employees * 100) if total_employees > 0 else 0,
        }

# Global database instance
db = SupabaseDB()
