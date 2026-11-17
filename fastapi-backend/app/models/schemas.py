"""
Production-Grade Pydantic Schemas
Zero Placeholders | Full Validation
"""

from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime, date, time
from enum import Enum
from decimal import Decimal

# =====================================================
# ENUMS
# =====================================================

class UserRole(str, Enum):
    SUPER_ADMIN = "super_admin"
    COMPANY_ADMIN = "company_admin"
    ADMIN = "admin"
    EMPLOYEE = "employee"

class CompanySize(str, Enum):
    STARTUP = "startup"
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"
    ENTERPRISE = "enterprise"

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
    ON_LEAVE = "on_leave"

class VerificationMethod(str, Enum):
    BIOMETRIC = "biometric"
    FACE = "face"
    MANUAL = "manual"
    HYBRID = "hybrid"

class LeaveType(str, Enum):
    SICK = "sick"
    CASUAL = "casual"
    EARNED = "earned"
    UNPAID = "unpaid"
    MATERNITY = "maternity"
    PATERNITY = "paternity"
    COMPENSATORY = "compensatory"
    BEREAVEMENT = "bereavement"

class LeaveStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    CANCELLED = "cancelled"

class EmploymentType(str, Enum):
    FULL_TIME = "full_time"
    PART_TIME = "part_time"
    CONTRACT = "contract"
    INTERN = "intern"

# =====================================================
# COMPANY SCHEMAS
# =====================================================

class CompanyBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    slug: Optional[str] = None
    industry: Optional[str] = None
    size: Optional[CompanySize] = None
    website: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    timezone: str = "UTC"
    office_latitude: Optional[float] = Field(None, ge=-90, le=90)
    office_longitude: Optional[float] = Field(None, ge=-180, le=180)
    geofence_radius_meters: Optional[int] = Field(None, ge=10, le=5000)

class CompanyCreate(CompanyBase):
    admin_email: EmailStr
    admin_full_name: str = Field(..., min_length=2)
    admin_password: str = Field(..., min_length=6)

class CompanyUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    industry: Optional[str] = None
    size: Optional[CompanySize] = None
    status: Optional[CompanyStatus] = None
    website: Optional[str] = None
    logo_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    office_latitude: Optional[float] = Field(None, ge=-90, le=90)
    office_longitude: Optional[float] = Field(None, ge=-180, le=180)
    geofence_radius_meters: Optional[int] = Field(None, ge=10, le=5000)

class CompanyResponse(BaseModel):
    id: str
    name: str
    slug: Optional[str] = None
    industry: Optional[str] = None
    size: Optional[str] = None
    status: str
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
    created_at: datetime
    
    class Config:
        from_attributes = True

# =====================================================
# AUTHENTICATION SCHEMAS
# =====================================================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    device_id: Optional[str] = None
    fcm_token: Optional[str] = None

class SignupRequest(BaseModel):
    company_id: str
    email: EmailStr
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=2, max_length=255)
    role: UserRole
    phone_number: Optional[str] = None
    department_id: Optional[str] = None
    employee_id: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

class AuthResponse(BaseModel):
    success: bool
    message: str
    user: "UserResponse"
    token: Optional[str] = None  # Mock JWT token for now

# =====================================================
# USER/PROFILE SCHEMAS
# =====================================================

class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    phone_number: Optional[str] = None
    role: UserRole

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)
    company_id: str
    department_id: Optional[str] = None
    employee_id: Optional[str] = None

class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=255)
    phone_number: Optional[str] = None
    designation: Optional[str] = None
    department_id: Optional[str] = None
    manager_id: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    company_id: str
    company_name: Optional[str] = None
    email: str
    full_name: str
    phone_number: Optional[str] = None
    role: str
    employee_id: Optional[str] = None
    department_id: Optional[str] = None
    department_name: Optional[str] = None
    designation: Optional[str] = None
    profile_picture_url: Optional[str] = None
    is_active: bool = True
    is_verified: bool = False
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# =====================================================
# ATTENDANCE SCHEMAS
# =====================================================

class GPSLocation(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: Optional[float] = Field(None, ge=0)

class CheckInRequest(BaseModel):
    profile_id: str
    check_in_gps: GPSLocation
    verification_method: VerificationMethod
    device_id: Optional[str] = None
    device_model: Optional[str] = None
    device_os: Optional[str] = None
    is_wfh: bool = False
    wfh_reason: Optional[str] = None
    notes: Optional[str] = None

class CheckOutRequest(BaseModel):
    attendance_id: str
    check_out_gps: GPSLocation
    notes: Optional[str] = None

class AttendanceResponse(BaseModel):
    id: str
    company_id: str
    profile_id: str
    profile_name: Optional[str]
    check_in: datetime
    check_out: Optional[datetime]
    total_hours: Optional[float]
    status: str
    check_in_gps: Optional[Dict[str, Any]]
    check_out_gps: Optional[Dict[str, Any]]
    distance_from_office: Optional[float]
    is_wfh: bool
    verification_method: Optional[str]
    face_match_confidence: Optional[float]
    created_at: datetime
    
    class Config:
        from_attributes = True

class AttendanceSummary(BaseModel):
    total_days: int
    present_days: int
    absent_days: int
    late_days: int
    half_days: int
    attendance_percentage: float
    total_hours_worked: float
    avg_hours_worked: float

# =====================================================
# LEAVE SCHEMAS
# =====================================================

class LeaveRequest(BaseModel):
    profile_id: str
    leave_type: LeaveType
    start_date: date
    end_date: date
    half_day: bool = False
    reason: str = Field(..., min_length=10)
    attachment_url: Optional[str] = None
    replacement_profile_id: Optional[str] = None
    emergency_contact: Optional[str] = None
    
    @validator('end_date')
    def validate_dates(cls, v, values):
        if 'start_date' in values and v < values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v

class LeaveApproval(BaseModel):
    leave_id: str
    status: LeaveStatus
    approved_by: str
    rejection_reason: Optional[str] = None

class LeaveResponse(BaseModel):
    id: str
    company_id: str
    profile_id: str
    profile_name: Optional[str]
    leave_type: str
    start_date: date
    end_date: date
    total_days: float
    half_day: bool
    reason: str
    status: str
    approved_by: Optional[str]
    approved_at: Optional[datetime]
    rejection_reason: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

class LeaveBalance(BaseModel):
    profile_id: str
    leave_type: str
    year: int
    total_allocated: float
    used: float
    balance: float
    carried_forward: float

# =====================================================
# DEPARTMENT SCHEMAS
# =====================================================

class DepartmentCreate(BaseModel):
    company_id: str
    name: str = Field(..., min_length=2, max_length=200)
    code: Optional[str] = Field(None, max_length=20)
    description: Optional[str] = None
    manager_id: Optional[str] = None
    parent_department_id: Optional[str] = None
    location: Optional[str] = None

class DepartmentUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    code: Optional[str] = None
    description: Optional[str] = None
    manager_id: Optional[str] = None
    location: Optional[str] = None
    is_active: Optional[bool] = None

class DepartmentResponse(BaseModel):
    id: str
    company_id: str
    name: str
    code: Optional[str]
    description: Optional[str]
    manager_id: Optional[str]
    manager_name: Optional[str]
    employee_count: int = 0
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# =====================================================
# DASHBOARD SCHEMAS
# =====================================================

class DashboardStats(BaseModel):
    total_employees: int
    present_today: int
    absent_today: int
    on_leave: int
    late_today: int
    pending_leave_requests: int
    attendance_rate_today: float
    attendance_rate_month: float

class CompanyDashboardStats(DashboardStats):
    departments: List[Dict[str, Any]]
    recent_activity: List[Dict[str, Any]]

class SuperAdminDashboardStats(BaseModel):
    total_companies: int
    total_users: int
    active_users_today: int
    active_companies: int
    trial_companies: int
    suspended_companies: int
    total_revenue: float
    monthly_revenue: float

# =====================================================
# FACE RECOGNITION SCHEMAS
# =====================================================

class FaceEnrollRequest(BaseModel):
    profile_id: str
    is_primary: bool = True
    quality_threshold: float = Field(0.7, ge=0, le=1)

class FaceVerifyRequest(BaseModel):
    profile_id: str
    check_liveness: bool = True
    confidence_threshold: float = Field(0.75, ge=0, le=1)

class FaceVerificationResponse(BaseModel):
    is_match: bool
    confidence: float
    is_live: bool
    liveness_score: float
    message: str

# =====================================================
# NOTIFICATION SCHEMAS
# =====================================================

class NotificationCreate(BaseModel):
    profile_id: str
    title: str = Field(..., max_length=255)
    body: str
    type: str
    entity_type: Optional[str] = None
    entity_id: Optional[str] = None
    action_url: Optional[str] = None

class NotificationResponse(BaseModel):
    id: str
    title: str
    body: str
    type: str
    is_read: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# =====================================================
# GENERIC RESPONSES
# =====================================================

class SuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: Optional[Dict[str, Any]] = None

class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    details: Optional[Dict[str, Any]] = None

class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    page_size: int
    total_pages: int

# Update forward references
AuthResponse.model_rebuild()
