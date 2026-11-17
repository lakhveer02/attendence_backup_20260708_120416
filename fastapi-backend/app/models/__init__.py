"""
Models package for FastAPI backend
Exports all Pydantic schemas
"""

from .schemas import (
    # Enums
    UserRole,
    CompanySize,
    CompanyStatus,
    AttendanceStatus,
    VerificationMethod,
    LeaveType,
    LeaveStatus,
    EmploymentType,
    
    # Company
    CompanyBase,
    CompanyCreate,
    CompanyUpdate,
    CompanyResponse,
    
    # Authentication
    LoginRequest,
    SignupRequest,
    TokenResponse,
    AuthResponse,
    
    # User/Profile
    UserBase,
    UserCreate,
    UserUpdate,
    UserResponse,
    
    # Attendance
    GPSLocation,
    CheckInRequest,
    CheckOutRequest,
    AttendanceResponse,
    AttendanceSummary,
    
    # Leave
    LeaveRequest,
    LeaveApproval,
    LeaveResponse,
    LeaveBalance,
    
    # Department
    DepartmentCreate,
    DepartmentUpdate,
    DepartmentResponse,
    
    # Dashboard
    DashboardStats,
    CompanyDashboardStats,
    SuperAdminDashboardStats,
    
    # Face Recognition
    FaceEnrollRequest,
    FaceVerifyRequest,
    FaceVerificationResponse,
    
    # Notification
    NotificationCreate,
    NotificationResponse,
    
    # Generic
    SuccessResponse,
    ErrorResponse,
    PaginatedResponse,
)

__all__ = [
    # Enums
    "UserRole",
    "CompanySize",
    "CompanyStatus",
    "AttendanceStatus",
    "VerificationMethod",
    "LeaveType",
    "LeaveStatus",
    "EmploymentType",
    
    # Company
    "CompanyBase",
    "CompanyCreate",
    "CompanyUpdate",
    "CompanyResponse",
    
    # Authentication
    "LoginRequest",
    "SignupRequest",
    "TokenResponse",
    "AuthResponse",
    
    # User/Profile
    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserResponse",
    
    # Attendance
    "GPSLocation",
    "CheckInRequest",
    "CheckOutRequest",
    "AttendanceResponse",
    "AttendanceSummary",
    
    # Leave
    "LeaveRequest",
    "LeaveApproval",
    "LeaveResponse",
    "LeaveBalance",
    
    # Department
    "DepartmentCreate",
    "DepartmentUpdate",
    "DepartmentResponse",
    
    # Dashboard
    "DashboardStats",
    "CompanyDashboardStats",
    "SuperAdminDashboardStats",
    
    # Face Recognition
    "FaceEnrollRequest",
    "FaceVerifyRequest",
    "FaceVerificationResponse",
    
    # Notification
    "NotificationCreate",
    "NotificationResponse",
    
    # Generic
    "SuccessResponse",
    "ErrorResponse",
    "PaginatedResponse",
]
