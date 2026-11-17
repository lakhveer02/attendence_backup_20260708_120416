"""
Multi-Tenant SaaS Models
Workspace, Invitations, Branches, Subscriptions
"""

from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from enum import Enum

# ==================== ENUMS ====================

class WorkspaceRole(str, Enum):
    OWNER = "owner"
    ADMIN = "admin"
    HR = "hr"
    MANAGER = "manager"
    EMPLOYEE = "employee"

class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

class SubscriptionPlan(str, Enum):
    TRIAL = "trial"
    BASIC = "basic"
    PROFESSIONAL = "professional"
    ENTERPRISE = "enterprise"

class SubscriptionStatus(str, Enum):
    TRIAL = "trial"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

# ==================== WORKSPACE MODELS ====================

class WorkspaceCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    slug: str = Field(..., min_length=3, max_length=100, pattern="^[a-z0-9-]+$")
    industry: Optional[str] = None
    size: Optional[str] = None
    website: Optional[str] = None
    logo_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    timezone: str = "UTC"
    office_latitude: Optional[float] = None
    office_longitude: Optional[float] = None
    owner_email: EmailStr
    owner_full_name: str
    owner_password: str = Field(..., min_length=6)

class WorkspaceResponse(BaseModel):
    id: str
    name: str
    slug: Optional[str] = None  # Not in actual schema
    workspace_url: Optional[str] = None  # Not in actual schema
    logo_url: Optional[str] = None
    industry: Optional[str] = None
    size: Optional[str] = None
    subscription_plan: Optional[str] = None  # Not in actual schema
    subscription_status: Optional[str] = None  # Not in actual schema
    is_verified: Optional[bool] = None  # Not in actual schema
    is_suspended: Optional[bool] = None  # Not in actual schema
    max_employees: Optional[int] = None
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class UserWorkspaceResponse(BaseModel):
    workspace_id: str
    company_id: str
    company_name: str
    company_logo: Optional[str]
    user_role: str
    is_owner: bool
    joined_at: datetime
    last_accessed: Optional[datetime]
    
    class Config:
        from_attributes = True

class WorkspaceSwitchRequest(BaseModel):
    company_id: str

# ==================== INVITATION MODELS ====================

class InvitationCreate(BaseModel):
    company_id: str
    email: EmailStr
    phone_number: Optional[str] = None
    role: WorkspaceRole
    invited_by: str  # User ID of inviter
    custom_message: Optional[str] = None

class InvitationSendRequest(BaseModel):
    invitations: List[InvitationCreate]
    send_email: bool = True
    send_sms: bool = False

class InvitationResponse(BaseModel):
    id: str
    company_id: str
    company_name: Optional[str]
    email: str
    phone_number: Optional[str]
    role: str
    invitation_code: str
    invitation_link: str
    qr_code_url: Optional[str]
    status: str
    invited_by: str
    inviter_name: Optional[str]
    expires_at: datetime
    created_at: datetime
    accepted_at: Optional[datetime]
    
    class Config:
        from_attributes = True

class InvitationAcceptRequest(BaseModel):
    invitation_code: str
    full_name: str
    password: str = Field(..., min_length=6)
    profile_picture_url: Optional[str] = None

class InvitationValidateResponse(BaseModel):
    valid: bool
    invitation: Optional[InvitationResponse] = None
    message: str

# ==================== BRANCH MODELS ====================

class BranchCreate(BaseModel):
    company_id: str
    name: str = Field(..., min_length=2, max_length=200)
    code: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    geofence_radius_meters: int = Field(100, ge=10, le=5000)
    manager_id: Optional[str] = None
    is_headquarters: bool = False
    working_hours: Optional[Dict[str, Any]] = None

class BranchUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    code: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    geofence_radius_meters: Optional[int] = Field(None, ge=10, le=5000)
    manager_id: Optional[str] = None
    is_headquarters: Optional[bool] = None
    is_active: Optional[bool] = None
    working_hours: Optional[Dict[str, Any]] = None

class BranchResponse(BaseModel):
    id: str
    company_id: str
    name: str
    code: Optional[str]
    description: Optional[str]
    address: Optional[str]
    city: Optional[str]
    state: Optional[str]
    country: Optional[str]
    postal_code: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    geofence_radius_meters: int
    manager_id: Optional[str]
    manager_name: Optional[str]
    is_headquarters: bool
    is_active: bool
    employee_count: int = 0
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# ==================== SUBSCRIPTION MODELS ====================

class SubscriptionPlanResponse(BaseModel):
    id: str
    name: str
    display_name: str
    description: Optional[str]
    price_monthly: float
    price_yearly: float
    max_employees: Optional[int]
    max_branches: Optional[int]
    max_departments: Optional[int]
    features: Dict[str, Any]
    is_active: bool
    sort_order: int
    
    class Config:
        from_attributes = True

class SubscriptionUpgradeRequest(BaseModel):
    company_id: str
    plan_name: str
    billing_cycle: str = "monthly"  # 'monthly' or 'yearly'
    payment_method: str

class BillingTransactionResponse(BaseModel):
    id: str
    company_id: str
    plan_id: Optional[str]
    amount: float
    currency: str
    payment_method: Optional[str]
    transaction_id: Optional[str]
    status: str
    description: Optional[str]
    invoice_url: Optional[str]
    receipt_url: Optional[str]
    created_at: datetime
    processed_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# ==================== PLATFORM ADMIN MODELS ====================

class PlatformStatsResponse(BaseModel):
    total_companies: int
    active_companies: int
    suspended_companies: int
    trial_companies: int
    total_users: int
    active_users: int
    total_revenue: float
    new_signups_today: int
    avg_employees_per_company: float
    top_companies: List[Dict[str, Any]]

class CompanyManagementRequest(BaseModel):
    action: str  # 'verify', 'suspend', 'activate', 'delete'
    reason: Optional[str] = None

# ==================== SLUG CHECK ====================

class SlugCheckResponse(BaseModel):
    available: bool
    slug: str
    suggestion: Optional[str] = None
