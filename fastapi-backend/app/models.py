"""
Pydantic V2 Models for FastAPI
Complete type-safe request/response schemas
"""

from pydantic import BaseModel, Field, EmailStr, field_validator
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime, date
from enum import Enum

# ==================== ENUMS ====================

class UserRole(str, Enum):
    """
    Definitive Role Hierarchy per Architecture Blueprint
    
    1. SUPER_ADMIN: Platform owner - System-wide monitoring, global billing, multi-tenant management
    2. COMPANY_ADMIN: Tenant owner - Full ownership of a single workspace/company
    3. HR_MANAGER: Workspace management - Personnel operations, department oversight
    4. MANAGER: Mid-level team lead - Visibility bounded to direct reports only
    5. EMPLOYEE: End-user - Access restricted to personal data records only
    """
    SUPER_ADMIN = "super_admin"
    COMPANY_ADMIN = "company_admin"
    HR_MANAGER = "hr_manager"  # Changed from 'hr' to match blueprint
    MANAGER = "manager"
    EMPLOYEE = "employee"

class CompanySize(str, Enum):
    SMALL = "small"  # 1-50 employees
    MEDIUM = "medium"  # 51-500 employees
    LARGE = "large"  # 501+ employees
    ENTERPRISE = "enterprise"  # 5000+ employees

class CompanyStatus(str, Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    TRIAL = "trial"
    INACTIVE = "inactive"

class AttendanceStatus(str, Enum):
    PRESENT = "present"
    ABSENT = "absent"
    LATE = "late"
    HALF_DAY = "half_day"

class LeaveType(str, Enum):
    SICK = "sick"
    CASUAL = "casual"
    EARNED = "earned"
    UNPAID = "unpaid"
    MATERNITY = "maternity"
    PATERNITY = "paternity"

class LeaveStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class VerificationMethod(str, Enum):
    BIOMETRIC = "biometric"
    FACE = "face"
    HYBRID = "hybrid"

# ==================== COMPANY MODELS ====================

class CompanyRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    description: Optional[str] = None
    industry: Optional[str] = None
    size: CompanySize
    website: Optional[str] = None
    logo_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    timezone: str = "UTC"
    # Admin details for first user
    admin_email: EmailStr
    admin_password: str = Field(min_length=6)
    admin_full_name: str

class CompanyResponse(BaseModel):
    id: str
    name: str
    slug: Optional[str] = None
    description: Optional[str] = None
    industry: Optional[str] = None
    size: CompanySize
    status: CompanyStatus
    website: Optional[str] = None
    logo_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    timezone: str
    office_latitude: Optional[float] = None
    office_longitude: Optional[float] = None
    geofence_radius_meters: Optional[int] = None
    subscription_plan: Optional[str] = None
    subscription_status: Optional[str] = None
    max_employees: Optional[int] = None
    employee_count: int = 0
    created_at: datetime
    updated_at: datetime

class CompanyUpdateRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    industry: Optional[str] = None
    size: Optional[CompanySize] = None
    website: Optional[str] = None
    logo_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    timezone: Optional[str] = None

# ==================== AUTH MODELS ====================
# Note: SignupRequest and LoginRequest are defined in app/auth/routes.py
# to avoid conflicts with the auth router. Do not redefine them here.

class UserResponse(BaseModel):
    id: str
    company_id: Optional[str] = None  # Optional for super_admin
    company_name: Optional[str] = None
    email: str
    full_name: str
    role: UserRole
    phone_number: Optional[str] = None
    department_id: Optional[str] = None
    department_name: Optional[str] = None
    profile_picture_url: Optional[str] = None
    face_embedding_url: Optional[str] = None
    is_active: bool = True
    created_at: datetime
    updated_at: datetime

class AuthResponse(BaseModel):
    success: bool
    message: str
    user: Optional[UserResponse] = None
    token: Optional[str] = None

# ==================== ATTENDANCE MODELS ====================

class GeoCoordinates(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)

class CheckInRequest(BaseModel):
    profile_id: str
    check_in_gps: GeoCoordinates
    is_wfh: bool = False
    verification_method: VerificationMethod
    device_id: str
    notes: Optional[str] = None

class CheckOutRequest(BaseModel):
    attendance_id: str
    check_out_gps: GeoCoordinates
    notes: Optional[str] = None

class AttendanceResponse(BaseModel):
    id: str
    profile_id: str
    profile_name: Optional[str] = None
    check_in: datetime
    check_out: Optional[datetime] = None
    status: AttendanceStatus
    check_in_gps: Optional[GeoCoordinates] = None
    check_out_gps: Optional[GeoCoordinates] = None
    is_wfh: bool = False
    verification_method: Optional[VerificationMethod] = None
    check_in_photo_url: Optional[str] = None
    check_out_photo_url: Optional[str] = None
    face_match_confidence: Optional[float] = None
    device_id: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class AttendanceSummaryResponse(BaseModel):
    total_days: int
    present_days: int
    absent_days: int
    late_days: int
    half_days: int
    attendance_percentage: float
    avg_hours_worked: Optional[float] = None
    total_hours_worked: Optional[float] = None
    additional_stats: Dict[str, Any] = {}

# ==================== LEAVE MODELS ====================

class LeaveRequest(BaseModel):
    profile_id: str
    leave_type: LeaveType
    start_date: date
    end_date: date
    reason: str
    attachment_url: Optional[str] = None

    @field_validator('end_date')
    @classmethod
    def validate_dates(cls, v, info):
        if 'start_date' in info.data and v < info.data['start_date']:
            raise ValueError('end_date must be after or equal to start_date')
        return v

class LeaveApprovalRequest(BaseModel):
    leave_id: str
    status: Literal[LeaveStatus.APPROVED, LeaveStatus.REJECTED]
    approved_by: str
    rejection_reason: Optional[str] = None

class LeaveResponse(BaseModel):
    id: str
    profile_id: str
    profile_name: Optional[str] = None
    leave_type: LeaveType
    start_date: date
    end_date: date
    status: LeaveStatus
    reason: str
    attachment_url: Optional[str] = None
    rejection_reason: Optional[str] = None
    approved_by: Optional[str] = None
    approver_name: Optional[str] = None
    approved_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

# ==================== FACE VERIFICATION MODELS ====================

class FaceEnrollmentRequest(BaseModel):
    profile_id: str
    is_primary: bool = True

class FaceVerificationRequest(BaseModel):
    profile_id: str
    check_liveness: bool = True

class FaceVerificationResponse(BaseModel):
    is_match: bool
    confidence: float = Field(ge=0.0, le=1.0)
    is_live: bool
    liveness_score: float = Field(ge=0.0, le=1.0)
    message: Optional[str] = None
    face_detected: bool = True
    embedding_generated: bool = True

class LivenessResponse(BaseModel):
    is_live: bool
    score: float = Field(ge=0.0, le=1.0)
    details: Optional[Dict[str, Any]] = None

class FaceEmbeddingResponse(BaseModel):
    id: str
    profile_id: str
    photo_url: str
    is_primary: bool
    quality_score: Optional[float] = None
    created_at: datetime

# ==================== DEVICE SECURITY MODELS ====================

class DeviceSecurityRequest(BaseModel):
    device_id: str
    device_model: str
    os_version: str
    platform: Literal["android", "ios"]
    security_checks: Dict[str, Any]

class DeviceRegistrationRequest(BaseModel):
    profile_id: str
    device_id: str
    device_info: Dict[str, Any]

class DeviceBindingRequest(BaseModel):
    profile_id: str
    device_id: str

class MockLocationRequest(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    location_metadata: Dict[str, Any]

class DeviceSecurityResponse(BaseModel):
    is_secure: bool
    violations: List[str]
    device_id: str
    device_info: Dict[str, Any]
    risk_level: Literal["low", "medium", "high"]

class DeviceBindingResponse(BaseModel):
    is_valid: bool
    message: Optional[str] = None

class MockLocationResponse(BaseModel):
    is_mock: bool
    confidence: float = Field(ge=0.0, le=1.0)
    indicators: Optional[List[str]] = None

# ==================== DEPARTMENT MODELS ====================

class DepartmentRequest(BaseModel):
    name: str = Field(min_length=2)
    description: Optional[str] = None
    manager_id: Optional[str] = None

class DepartmentResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    manager_id: Optional[str] = None
    manager_name: Optional[str] = None
    employee_count: int = 0
    created_at: datetime
    updated_at: datetime

# ==================== NOTIFICATION MODELS ====================

class NotificationRequest(BaseModel):
    profile_id: str
    title: str
    message: str
    type: Literal["attendance", "leave", "announcement", "alert", "approval"]
    action_url: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class NotificationResponse(BaseModel):
    id: str
    profile_id: str
    title: str
    message: str
    type: str
    is_read: bool = False
    action_url: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    created_at: datetime

# ==================== REPORT MODELS ====================

class ReportRequest(BaseModel):
    profile_id: Optional[str] = None
    department_id: Optional[str] = None
    start_date: date
    end_date: date
    report_type: Literal["attendance", "payroll", "leave", "department"]

class PayrollReportResponse(BaseModel):
    profile_id: str
    profile_name: str
    total_days_worked: int
    total_hours_worked: float
    regular_hours: float
    overtime_hours: float
    late_deductions: float
    gross_salary: float
    net_salary: float
    period: Dict[str, Any]

class DepartmentReportResponse(BaseModel):
    department_id: str
    department_name: str
    total_employees: int
    present_today: int
    absent_today: int
    on_leave: int
    average_attendance_rate: float
    total_hours_worked: float

# ==================== ANALYTICS MODELS ====================

class DashboardStatsResponse(BaseModel):
    total_employees: int
    present_today: int
    absent_today: int
    on_leave: int
    late_today: int
    pending_leave_requests: int
    attendance_rate_today: float
    attendance_rate_month: float
    departments: List[Dict[str, Any]]
    recent_check_ins: List[Dict[str, Any]]

# ==================== COMMON RESPONSES ====================

class SuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: Optional[Dict[str, Any]] = None

class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    error: Optional[str] = None
    details: Optional[Dict[str, Any]] = None

class PaginatedResponse(BaseModel):
    data: List[Any]
    total: int
    page: int
    page_size: int
    total_pages: int
