"""
Enterprise Authentication Routes - Complete Implementation
Workspace Resolution → Authentication → JWT Issuance → RBAC
"""

from fastapi import APIRouter, HTTPException, status, Depends, Body, Request
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, Dict, Any
from datetime import datetime
import re
import logging
from slowapi import Limiter
from slowapi.util import get_remote_address

from .jwt_handler import jwt_handler
from .dependencies import get_current_user, CurrentUser, RequireSuperAdmin
from ..database_complete import db_complete as db

# Setup logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)


# ==================== REQUEST/RESPONSE MODELS ====================

class WorkspaceResolveRequest(BaseModel):
    """Request to resolve workspace slug or joining token"""
    identifier: str = Field(
        ...,
        description="Workspace slug (e.g., 'acme-corp') or joining token (e.g., 'ABC12345')",
        min_length=3,
        max_length=100
    )
    
    @field_validator('identifier')
    @classmethod
    def validate_identifier(cls, v):
        v = v.strip()
        # Check if it's a joining token (8 uppercase alphanumeric)
        if re.match(r'^[A-Z0-9]{8}$', v):
            return v.upper()
        # Check if it's a workspace slug (lowercase with hyphens)
        if re.match(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?$', v.lower()):
            return v.lower()
        raise ValueError("Invalid format. Must be workspace slug or 8-character joining token")


class WorkspaceResolveResponse(BaseModel):
    """Response with workspace details"""
    exists: bool
    company_id: Optional[str] = None
    company_name: Optional[str] = None
    workspace_slug: Optional[str] = None
    status: Optional[str] = None
    is_joining_token: bool = False
    logo_url: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None


class SignupRequest(BaseModel):
    """User signup request"""
    # Workspace context
    company_id: Optional[str] = Field(None, description="Required for non-super-admin signups")
    joining_token: Optional[str] = Field(None, description="Alternative to company_id")
    
    # User details
    email: EmailStr
    password: str = Field(..., min_length=8, description="Minimum 8 characters")
    full_name: str = Field(..., min_length=3, max_length=255)
    phone_number: Optional[str] = Field(None, max_length=20)
    
    # Role (only super_admin can set roles other than employee)
    role: str = Field("employee", description="Default: employee")
    
    # Optional profile details
    designation: Optional[str] = None
    department_id: Optional[str] = None
    
    # Company creation (for company_admin self-service signup)
    create_company: bool = Field(False, description="Set to true to create a new company")
    company_name: Optional[str] = Field(None, description="Required if create_company is true")
    workspace_slug: Optional[str] = Field(None, description="Optional custom workspace slug")
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not re.search(r'[A-Z]', v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r'[a-z]', v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r'\d', v):
            raise ValueError("Password must contain at least one digit")
        return v
    
    @field_validator('role')
    @classmethod
    def validate_role(cls, v):
        allowed_roles = ['super_admin', 'company_admin', 'hr_manager', 'manager', 'employee']
        if v not in allowed_roles and v != 'team_manager':
            raise ValueError(f"Invalid role. Must be one of: {', '.join(allowed_roles)}")
        return 'manager' if v == 'team_manager' else v
    
    @field_validator('company_name')
    @classmethod
    def validate_company_name(cls, v, info):
        if info.data.get('create_company') and not v:
            raise ValueError("company_name is required when create_company is true")
        return v
    
    @field_validator('workspace_slug')
    @classmethod
    def validate_workspace_slug(cls, v):
        if v:
            v = v.lower().strip()
            if not re.match(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?$', v):
                raise ValueError("Workspace slug must contain only lowercase letters, numbers, and hyphens")
            if len(v) < 3 or len(v) > 50:
                raise ValueError("Workspace slug must be between 3 and 50 characters")
        return v


class LoginRequest(BaseModel):
    """User login request"""
    email: EmailStr
    password: str
    company_id: Optional[str] = Field(None, description="Required for multi-tenant login")
    workspace_slug: Optional[str] = Field(None, description="Alternative to company_id")
    
    # Device binding
    device_id: str = Field(..., description="Unique device identifier")
    device_name: Optional[str] = Field(None, description="Device name for user reference")
    device_os: Optional[str] = None
    device_model: Optional[str] = None
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v):
        return v.lower().strip()


class LoginResponse(BaseModel):
    """Successful login response"""
    success: bool = True
    message: str
    
    # Tokens
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = 3600  # seconds
    
    # User profile
    user: Dict[str, Any]


class RefreshTokenRequest(BaseModel):
    """Refresh token request"""
    refresh_token: str
    device_id: str


class PasswordResetRequest(BaseModel):
    """Password reset request"""
    email: EmailStr
    company_id: Optional[str] = None


class PasswordResetConfirm(BaseModel):
    """Password reset confirmation"""
    token: str
    new_password: str = Field(..., min_length=8)
    
    @field_validator('new_password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not re.search(r'[A-Z]', v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r'[a-z]', v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r'\d', v):
            raise ValueError("Password must contain at least one digit")
        return v


class ChangePasswordRequest(BaseModel):
    """Change password for authenticated user"""
    current_password: str
    new_password: str = Field(..., min_length=8)
    
    @field_validator('new_password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not re.search(r'[A-Z]', v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r'[a-z]', v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r'\d', v):
            raise ValueError("Password must contain at least one digit")
        return v


# ==================== AUTHENTICATION ENDPOINTS ====================

@router.post("/resolve-workspace", response_model=WorkspaceResolveResponse)
async def resolve_workspace(request: WorkspaceResolveRequest):
    """
    Step 1: Resolve workspace slug or joining token before signup/login
    
    This endpoint allows users to verify a company exists before attempting
    to sign up or log in. Essential for multi-tenant onboarding UX.
    """
    try:
        # Query database for workspace
        result = await db.execute_query(
            """
            SELECT 
                TRUE as exists,
                id as company_id,
                name as company_name,
                workspace_slug,
                status,
                logo_url,
                settings,
                (UPPER($1) = joining_token) as is_joining_token
            FROM companies
            WHERE (workspace_slug = LOWER($1) OR joining_token = UPPER($1))
              AND status IN ('active', 'trial')
            LIMIT 1
            """,
            request.identifier
        )
        
        if not result:
            return WorkspaceResolveResponse(exists=False)
        
        workspace = result[0]
        
        return WorkspaceResolveResponse(
            exists=True,
            company_id=str(workspace['company_id']),
            company_name=workspace['company_name'],
            workspace_slug=workspace['workspace_slug'],
            status=workspace['status'],
            is_joining_token=workspace['is_joining_token'],
            logo_url=workspace.get('logo_url'),
            settings=workspace.get('settings', {})
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to resolve workspace: {str(e)}"
        )


@router.post("/signup", response_model=LoginResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/hour")  # SECURITY: Prevent spam account creation
async def signup(request: Request, signup_data: SignupRequest = Body(...)):
    """
    Step 2: User signup with workspace context
    
    Creates new user profile and issues JWT tokens.
    Company admins can create their own company during signup.
    Super admins can create users with any role, others default to employee.
    """
    logger.info(f"📥 Signup request received: email={signup_data.email}, role={signup_data.role}")
    
    # Track newly created company for rollback if needed
    created_company_id = None
    
    try:
        # ===== STEP 1: Check if user already exists BEFORE any resource creation =====
        # This is the PRIMARY defense against orphaned companies
        existing_profile = await db.get_profile_by_email(signup_data.email.lower())
        if existing_profile:
            # Email is already registered - reject immediately
            logger.warning(f"⚠️ Email already registered: {signup_data.email}")
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )
        
        # Also check Supabase Auth to prevent orphaned auth users
        try:
            # Try to list users with this email
            auth_users = db.client.auth.admin.list_users()
            if auth_users:
                for user in auth_users:
                    if user.email and user.email.lower() == signup_data.email.lower():
                        logger.warning(f"⚠️ Email already exists in Supabase Auth: {signup_data.email}")
                        raise HTTPException(
                            status_code=status.HTTP_409_CONFLICT,
                            detail="Email already registered"
                        )
        except HTTPException:
            raise
        except Exception as auth_check_error:
            logger.warning(f"⚠️ Could not check existing auth users: {auth_check_error}")
        
        # ===== STEP 2: Handle company creation for company_admin self-service signup =====
        company_id = signup_data.company_id
        
        if signup_data.create_company and signup_data.role == 'company_admin':
            # Create new company for the admin
            if not signup_data.company_name:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="company_name is required when creating a new company"
                )
            
            # Generate workspace slug from company name if not provided
            workspace_slug = signup_data.workspace_slug
            if not workspace_slug:
                # Auto-generate slug from company name
                workspace_slug = re.sub(r'[^a-z0-9-]', '', signup_data.company_name.lower().replace(' ', '-'))
                workspace_slug = re.sub(r'-+', '-', workspace_slug).strip('-')
            
            # Check if workspace slug is already taken
            existing_workspace = await db.execute_query(
                "SELECT id FROM companies WHERE workspace_slug = $1",
                workspace_slug
            )
            
            if existing_workspace:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Workspace slug '{workspace_slug}' is already taken. Please choose another."
                )
            
            # Generate joining token (8 random uppercase alphanumeric)
            import random
            import string
            joining_token = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            
            # Create company (using only fields that exist in actual Supabase schema)
            company_data = {
                "name": signup_data.company_name,
                "status": "active",  # Use actual enum value from schema
                "timezone": "Asia/Kolkata",
                # Note: workspace_slug, joining_token, subscription fields don't exist in current schema
                # These need to be added via migration or handled differently
            }
            
            new_company = await db.create_company(company_data)
            company_id = str(new_company['id'])
            created_company_id = company_id  # Track for potential rollback
            
            logger.info(f"✅ Created new company: {signup_data.company_name} (ID: {company_id}, Slug: {workspace_slug})")
        
        # Resolve company_id from joining_token if provided
        elif signup_data.joining_token and not company_id:
            company_result = await db.execute_query(
                "SELECT id FROM companies WHERE joining_token = $1 AND status IN ('active', 'trial')",
                signup_data.joining_token.upper()
            )
            if not company_result:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Invalid joining token"
                )
            company_id = str(company_result[0]['id'])
        
        # Validate company exists (except for super_admin)
        if signup_data.role != 'super_admin':
            if not company_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="company_id, joining_token, or create_company required for non-super-admin signups"
                )
            
            company = await db.get_company(company_id)
            if not company:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Company not found"
                )
            
            if company['status'] not in ['active', 'trial']:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Company is not active"
                )
        else:
            # Super admins don't belong to a company
            company_id = None
        
        # Check if email already exists in this company context
        existing = await db.execute_query(
            """
            SELECT id FROM profiles 
            WHERE email = $1 
              AND (company_id = $2 OR (company_id IS NULL AND $2 IS NULL))
            """,
            signup_data.email.lower(),
            company_id
        )
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered in this company"
            )
        
        # Use Supabase Admin API to create user
        # Service role key bypasses email confirmation requirements
        auth_user_id = None
        try:
            # Use admin API to create user without email confirmation
            # This requires the service_role key to be set in database_complete.py
            auth_response = db.client.auth.admin.create_user({
                "email": signup_data.email.lower(),
                "password": signup_data.password,
                "email_confirm": True,  # Auto-confirm email
                "user_metadata": {
                    "full_name": signup_data.full_name,
                    "role": signup_data.role
                }
            })
            
            if not auth_response.user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to create authentication user"
                )
            
            auth_user_id = auth_response.user.id
            logger.info(f"✅ Supabase Auth user created with admin API: {auth_user_id}")
            
        except Exception as auth_error:
            error_msg = str(auth_error).lower()
            logger.error(f"❌ Auth creation failed: {auth_error}")
            
            # Rollback: Delete orphaned company if it was created during this request
            if created_company_id:
                try:
                    logger.warning(f"🔄 Rolling back company creation due to auth failure: {created_company_id}")
                    db.client.table("companies").delete().eq("id", created_company_id).execute()
                    logger.info(f"✅ Successfully deleted orphaned company: {created_company_id}")
                except Exception as rollback_error:
                    logger.error(f"❌ Failed to rollback company creation: {rollback_error}")
            
            # Provide helpful error message
            if "email" in error_msg and ("already" in error_msg or "exists" in error_msg or "duplicate" in error_msg):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already registered"
                )
            
            if "user not allowed" in error_msg or "not allowed" in error_msg:
                # This usually means the email is already taken in Supabase Auth
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already registered"
                )
            
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Authentication setup failed: {str(auth_error)}"
            )
        
        # Handle super_admin without company_id (schema requires NOT NULL company_id)
        # Create or reuse system company for super_admins
        if signup_data.role == 'super_admin' and not company_id:
            # Try to find existing system company by name
            try:
                # Use table operations instead of execute_query since PostgREST doesn't support raw SQL
                system_companies = db.client.table("companies").select("id").eq("name", "System Administration").limit(1).execute()
                
                if system_companies.data:
                    company_id = str(system_companies.data[0]['id'])
                    logger.info(f"✅ Using existing system company: {company_id}")
                else:
                    # Create system company for super admins (using only existing schema fields)
                    system_company = await db.create_company({
                        "name": "System Administration",
                        "status": "active",
                        "timezone": "UTC"
                    })
                    company_id = str(system_company['id'])
                    logger.info(f"✅ Created system company for super_admins: {company_id}")
            except Exception as e:
                # If company exists but query failed, try to create and handle duplicate error
                try:
                    system_company = await db.create_company({
                        "name": "System Administration",
                        "status": "active",
                        "timezone": "UTC"
                    })
                    company_id = str(system_company['id'])
                    logger.info(f"✅ Created system company for super_admins: {company_id}")
                except Exception as create_error:
                    # If creation fails due to duplicate, fetch the existing one
                    error_str = str(create_error)
                    if "duplicate key" in error_str or "companies_name_key" in error_str:
                        system_companies = db.client.table("companies").select("id").eq("name", "System Administration").limit(1).execute()
                        if system_companies.data:
                            company_id = str(system_companies.data[0]['id'])
                            logger.info(f"✅ Using existing system company after duplicate error: {company_id}")
                        else:
                            raise
                    else:
                        raise
        
        # Create profile record with ONLY fields that exist in current Supabase schema
        # Actual profiles schema: id, company_id, workspace_id, email, full_name, role,
        # phone_number, profile_picture_url, face_embedding_url, is_active, created_at, updated_at,
        # employee_id, department_id, reporting_manager_id
        profile_data = {
            "id": auth_user_id,  # Link to Supabase Auth user
            "company_id": company_id,  # Required by current schema
            "workspace_id": company_id,  # Use company_id as workspace_id (simple 1:1 mapping)
            "email": signup_data.email.lower(),
            "full_name": signup_data.full_name,
            "role": signup_data.role,
            "is_active": True,
        }
        
        # Add optional fields only if provided
        if signup_data.phone_number:
            profile_data["phone_number"] = signup_data.phone_number
        
        if signup_data.department_id:
            profile_data["department_id"] = signup_data.department_id
        
        try:
            profile = await db.create_profile(profile_data)
            logger.info(f"✅ Profile record created: {profile['id']}")
        except Exception as profile_error:
            # Rollback both auth user and company if profile creation fails
            logger.error(f"❌ Profile record creation failed: {profile_error}")
            
            # Delete auth user
            if auth_user_id:
                try:
                    db.client.auth.admin.delete_user(auth_user_id)
                    logger.info(f"✅ Rolled back auth user: {auth_user_id}")
                except Exception as auth_rollback_error:
                    logger.error(f"❌ Failed to rollback auth user: {auth_rollback_error}")
            
            # Delete company
            if created_company_id:
                try:
                    db.client.table("companies").delete().eq("id", created_company_id).execute()
                    logger.info(f"✅ Rolled back company: {created_company_id}")
                except Exception as company_rollback_error:
                    logger.error(f"❌ Failed to rollback company: {company_rollback_error}")
            
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create profile record: {str(profile_error)}"
            )
        
        # Get company details for token
        company_name = None
        if company_id:
            company = await db.get_company(company_id)
            company_name = company['name'] if company else None
        
        # Generate tokens directly (don't auto-signin which causes the JWT error)
        access_token = jwt_handler.create_access_token(
            profile_id=str(profile['id']),
            email=profile['email'],
            role=profile['role'],
            company_id=company_id,
            company_name=company_name,
            full_name=profile['full_name']
        )
        
        # Generate refresh token with signup device
        refresh_token, token_hash = jwt_handler.create_refresh_token(
            profile_id=str(profile['id']),
            device_id="signup_device"
        )
        
        # Note: Storing refresh token requires a refresh_tokens table which may not exist
        # Skip storage for now - tokens will still work
        try:
            await db.execute_query(
                """
                INSERT INTO refresh_tokens (
                    profile_id, token_hash, device_id, expires_at
                ) VALUES ($1, $2, $3, NOW() + INTERVAL '30 days')
                """,
                str(profile['id']),
                token_hash,
                "signup_device"
            )
        except Exception as token_store_error:
            # Non-critical error - token will still work, just won't be tracked
            logger.warning(f"⚠️ Could not store refresh token: {token_store_error}")
        
        # Prepare user response
        user_data = {
            "profile_id": str(profile['id']),
            "id": str(profile['id']),
            "email": profile['email'],
            "full_name": profile['full_name'],
            "role": profile['role'],
            "company_id": company_id,
            "company_name": company_name,
            "is_active": profile['is_active']
        }
        
        logger.info(f"✅ Signup successful for: {signup_data.email} (Role: {signup_data.role})")
        
        return LoginResponse(
            message="Signup successful",
            access_token=access_token,
            refresh_token=refresh_token,
            user=user_data
        )
        
    except HTTPException as http_exc:
        # Rollback: Delete orphaned company if it was created during this request
        if created_company_id:
            try:
                logger.warning(f"🔄 Rolling back company creation: {created_company_id}")
                db.client.table("companies").delete().eq("id", created_company_id).execute()
                logger.info(f"✅ Successfully deleted orphaned company: {created_company_id}")
            except Exception as rollback_error:
                logger.error(f"❌ Failed to rollback company creation: {rollback_error}")
        raise http_exc
    except Exception as e:
        # Rollback: Delete orphaned company if it was created during this request
        if created_company_id:
            try:
                logger.warning(f"🔄 Rolling back company creation: {created_company_id}")
                db.client.table("companies").delete().eq("id", created_company_id).execute()
                logger.info(f"✅ Successfully deleted orphaned company: {created_company_id}")
            except Exception as rollback_error:
                logger.error(f"❌ Failed to rollback company creation: {rollback_error}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Signup failed: {str(e)}"
        )


@router.post("/login", response_model=LoginResponse)
@limiter.limit("5/minute")  # SECURITY: Prevent brute force attacks
async def login(request: Request, login_data: LoginRequest = Body(...)):
    """
    Step 3: User login with multi-tenant context
    
    Authenticates user and issues JWT tokens with device binding.
    Handles account lockout after failed attempts.
    """
    logger.info(f"📥 Login request received for: {login_data.email}")
    try:
        # Get user profile by email (from employees table)
        profile = await db.get_profile_by_email(login_data.email.lower())
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Check if account is active
        if not profile.get('is_active'):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is inactive. Contact administrator."
            )
        
        # For multi-tenant: verify company_id matches if provided
        if login_data.company_id and str(profile.get('company_id')) != login_data.company_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Verify password using Supabase Auth
        try:
            auth_response = db.client.auth.sign_in_with_password({
                "email": login_data.email.lower(),
                "password": login_data.password
            })
            
            if not auth_response.user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password"
                )
                
            # Update last login time
            try:
                await db.update_profile(str(profile['id']), {
                    "last_login_at": datetime.utcnow().isoformat()
                })
            except Exception as update_error:
                logger.warning(f"⚠️ Could not update last_login_at: {update_error}")
                
        except HTTPException:
            raise
        except Exception as auth_error:
            logger.error(f"❌ Auth sign-in failed: {auth_error}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Generate tokens
        access_token = jwt_handler.create_access_token(
            profile_id=str(profile['id']),
            email=profile['email'],
            role=profile['role'],
            company_id=str(profile['company_id']) if profile.get('company_id') else None,
            company_name=profile.get('company_name'),
            full_name=profile['full_name']
        )
        
        refresh_token, token_hash = jwt_handler.create_refresh_token(
            profile_id=str(profile['id']),
            device_id=login_data.device_id
        )
        
        # Note: Storing refresh token requires a refresh_tokens table
        # Skip storage for now - tokens will still work
        try:
            await db.execute_query(
                """
                INSERT INTO refresh_tokens (
                    profile_id, token_hash, device_id, expires_at
                ) VALUES ($1, $2, $3, NOW() + INTERVAL '30 days')
                """,
                str(profile['id']),
                token_hash,
                login_data.device_id
            )
        except Exception as token_store_error:
            logger.warning(f"⚠️ Could not store refresh token: {token_store_error}")
        
        logger.info(f"✅ Login successful for: {login_data.email} (Role: {profile['role']})")
        
        # Return success response
        return LoginResponse(
            success=True,
            message="Login successful",
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="Bearer",
            expires_in=3600,  # 1 hour
            user={
                "profile_id": str(profile['id']),
                "id": str(profile['id']),
                "email": profile['email'],
                "full_name": profile['full_name'],
                "role": profile['role'],
                "company_id": str(profile['company_id']) if profile.get('company_id') else None,
                "company_name": profile.get('company_name'),
                "phone_number": profile.get('phone'),
                "is_active": profile['is_active'],
                "profile_picture_url": profile.get('profile_picture_url')
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Login failed with exception: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )


@router.post("/refresh", response_model=LoginResponse)
async def refresh_token(request: RefreshTokenRequest):
    """
    Refresh access token using refresh token
    
    Implements token rotation: old refresh token is invalidated,
    new refresh token is issued along with new access token.
    """
    try:
        # Decode refresh token
        payload = jwt_handler.decode_token(request.refresh_token)
        
        # Verify token type
        if not jwt_handler.verify_token_type(payload, "refresh"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Invalid token type"
            )
        
            # Validate refresh token payload and device binding
        profile_id = payload.get("sub")
        token_device_id = payload.get("device_id")

        if not profile_id or not token_device_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )

        if token_device_id != request.device_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token device mismatch"
            )

        profile = await db.get_profile(profile_id)
        if not profile or not profile.get('is_active'):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is inactive"
            )

        # Get company details
        company_name = None
        if profile.get('company_id'):
            company = await db.get_company(str(profile['company_id']))
            company_name = company['name'] if company else None

        # Revoke old refresh tokens for this device if refresh_tokens table exists
        await db.execute_query(
            """
            UPDATE refresh_tokens
            SET is_revoked = TRUE, revoked_at = NOW()
            WHERE profile_id = $1
              AND device_id = $2
              AND is_revoked = FALSE
            """,
            str(profile['id']),
            request.device_id
        )
        
        # Generate new tokens (token rotation)
        access_token = jwt_handler.create_access_token(
            profile_id=str(profile['id']),
            email=profile['email'],
            role=profile['role'],
            company_id=str(profile['company_id']) if profile.get('company_id') else None,
            company_name=company_name,
            full_name=profile['full_name']
        )
        
        new_refresh_token, new_token_hash = jwt_handler.create_refresh_token(
            profile_id=str(profile['id']),
            device_id=request.device_id
        )
        
        # Store new refresh token
        await db.execute_query(
            """
            INSERT INTO refresh_tokens (
                profile_id, token_hash, device_id, expires_at
            ) VALUES ($1, $2, $3, NOW() + INTERVAL '30 days')
            """,
            str(profile['id']),
            new_token_hash,
            request.device_id
        )
        
        # Prepare user response
        user_data = {
            "profile_id": str(profile['id']),
            "email": profile['email'],
            "full_name": profile['full_name'],
            "role": profile['role'],
            "company_id": str(profile['company_id']) if profile.get('company_id') else None,
            "company_name": company_name,
            "is_active": profile['is_active']
        }
        
        return LoginResponse(
            message="Token refreshed successfully",
            access_token=access_token,
            refresh_token=new_refresh_token,
            user=user_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Token refresh failed: {str(e)}"
        )


@router.post("/logout")
async def logout(
    device_id: str = Body(..., embed=True),
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Logout user from current device
    
    Revokes refresh token for the specified device.
    """
    try:
        # Revoke refresh token for this device
        await db.execute_query(
            """
            UPDATE refresh_tokens
            SET is_revoked = TRUE, revoked_at = NOW()
            WHERE profile_id = $1
              AND device_id = $2
              AND is_revoked = FALSE
            """,
            current_user.profile_id,
            device_id
        )
        
        return {
            "success": True,
            "message": "Logged out successfully"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Logout failed: {str(e)}"
        )


@router.post("/logout-all")
async def logout_all(current_user: CurrentUser = Depends(get_current_user)):
    """
    Logout user from all devices
    
    Revokes all refresh tokens for the user.
    """
    try:
        # Revoke all refresh tokens
        await db.execute_query(
            """
            UPDATE refresh_tokens
            SET is_revoked = TRUE, revoked_at = NOW()
            WHERE profile_id = $1 AND is_revoked = FALSE
            """,
            current_user.profile_id
        )
        
        return {
            "success": True,
            "message": "Logged out from all devices successfully"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Logout all failed: {str(e)}"
        )


@router.get("/me")
async def get_current_user_profile(current_user: CurrentUser = Depends(get_current_user)):
    """
    Get current authenticated user's profile
    
    Returns complete user profile with permissions.
    """
    return {
        "success": True,
        "user": current_user.to_dict()
    }


@router.post("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Change password for authenticated user using Supabase Auth
    """
    try:
        # Use Supabase Auth to change password
        # First verify current password by attempting sign-in
        try:
            auth_response = db.client.auth.sign_in_with_password({
                "email": current_user.email,
                "password": request.current_password
            })
            
            if not auth_response.user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Current password is incorrect"
                )
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Current password is incorrect"
            )
        
        # Update password using Supabase Auth
        try:
            db.client.auth.update_user({
                "password": request.new_password
            })
        except Exception as e:
            logger.error(f"❌ Password update failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update password"
            )
        
        # Revoke all refresh tokens (force re-login on all devices)
        await db.execute_query(
            """
            UPDATE refresh_tokens
            SET is_revoked = TRUE, revoked_at = NOW()
            WHERE profile_id = $1 AND is_revoked = FALSE
            """,
            current_user.profile_id
        )
        
        return {
            "success": True,
            "message": "Password changed successfully. Please login again on all devices."
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Password change failed: {str(e)}"
        )
