"""
Invite-Based Onboarding System
Implements secure invitation mechanism with company joining codes

Per Architecture Blueprint:
- Public signup forms are strictly forbidden
- Users can only onboard via explicit invite-based onboarding or administrative creation
- Only three routes exist on login gateway: login, forgot-password, join
"""

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime, timedelta
import logging

from ..auth.dependencies import get_current_user, CurrentUser
from ..auth.rbac import Permission, require_permission
from ..database_complete import db_complete as db
from ..utils.credential_generator import CredentialGenerator, CredentialDelivery
from ..middleware import get_current_workspace_id

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/invitations", tags=["Invitations"])


# ==================== REQUEST/RESPONSE MODELS ====================

class GenerateCompanyCodeRequest(BaseModel):
    """Request to generate a new company joining code"""
    expires_in_days: Optional[int] = Field(30, description="Code expiry in days (default 30)")
    max_uses: Optional[int] = Field(None, description="Maximum number of uses (None = unlimited)")


class CompanyCodeResponse(BaseModel):
    """Response with company joining code"""
    success: bool
    company_code: str
    workspace_slug: str
    company_name: str
    expires_at: Optional[datetime] = None
    max_uses: Optional[int] = None
    current_uses: int = 0
    share_url: str


class ValidateCodeRequest(BaseModel):
    """Request to validate a company/invitation code"""
    code: str = Field(..., min_length=8, max_length=8, description="8-character joining code")


class ValidateCodeResponse(BaseModel):
    """Response with code validation result"""
    valid: bool
    company_id: Optional[str] = None
    company_name: Optional[str] = None
    workspace_slug: Optional[str] = None
    message: str


class JoinWithCodeRequest(BaseModel):
    """Request to join company using code"""
    code: str = Field(..., min_length=8, max_length=8)
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    phone_number: Optional[str] = None
    password: str = Field(..., min_length=8, description="User-chosen password")


class InviteUserRequest(BaseModel):
    """Request to send direct email invitation"""
    email: EmailStr
    full_name: str
    role: str = Field("employee", description="Role to assign")
    department_id: Optional[str] = None
    send_email: bool = Field(True, description="Send invitation email")


class InvitationResponse(BaseModel):
    """Response for invitation creation"""
    success: bool
    message: str
    invitation_token: str
    expires_at: datetime
    join_url: str


# ==================== COMPANY JOINING CODE ENDPOINTS ====================

@router.post("/generate-company-code", response_model=CompanyCodeResponse)
@require_permission(Permission.EDIT_COMPANY_SETTINGS)
async def generate_company_code(
    request: GenerateCompanyCodeRequest,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Generate a new company joining code
    
    Permission: EDIT_COMPANY_SETTINGS
    Roles: company_admin only
    
    Use Cases:
    - Share code with potential employees for self-service signup
    - Create temporary codes for recruitment campaigns
    - Generate codes with expiry and usage limits
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Get company details
        company = await db.get_company(workspace_id)
        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found"
            )
        
        # Generate new joining code
        generator = CredentialGenerator()
        joining_code = generator.generate_company_joining_code()
        
        # Calculate expiry
        expires_at = None
        if request.expires_in_days:
            expires_at = datetime.now() + timedelta(days=request.expires_in_days)
        
        # Update company with new joining code
        # Store in separate table for better tracking
        await db.execute_query(
            """
            INSERT INTO company_joining_codes (
                workspace_id,
                code,
                created_by,
                expires_at,
                max_uses,
                current_uses,
                is_active
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (code) DO UPDATE
            SET 
                created_by = EXCLUDED.created_by,
                expires_at = EXCLUDED.expires_at,
                max_uses = EXCLUDED.max_uses,
                is_active = EXCLUDED.is_active,
                updated_at = NOW()
            """,
            workspace_id,
            joining_code,
            current_user.user_id,
            expires_at,
            request.max_uses,
            0,  # current_uses
            True  # is_active
        )
        
        # Also update company table for backward compatibility
        await db.execute_query(
            "UPDATE companies SET joining_token = $1, updated_at = NOW() WHERE id = $2",
            joining_code,
            workspace_id
        )
        
        workspace_slug = company.get('workspace_slug', workspace_id)
        share_url = f"https://app.yourhrms.com/join?code={joining_code}"
        
        logger.info(f"✅ Generated company code: {joining_code} for {company['name']}")
        
        return CompanyCodeResponse(
            success=True,
            company_code=joining_code,
            workspace_slug=workspace_slug,
            company_name=company['name'],
            expires_at=expires_at,
            max_uses=request.max_uses,
            current_uses=0,
            share_url=share_url
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to generate company code: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/validate-code", response_model=ValidateCodeResponse)
async def validate_joining_code(request: ValidateCodeRequest):
    """
    Validate a company joining code
    
    PUBLIC ENDPOINT - No authentication required
    
    Used by frontend before showing signup form
    Verifies code is valid, not expired, and within usage limits
    """
    try:
        code = request.code.upper().strip()
        
        # Look up code in database
        code_result = await db.execute_query(
            """
            SELECT 
                cjc.workspace_id,
                cjc.expires_at,
                cjc.max_uses,
                cjc.current_uses,
                cjc.is_active,
                c.name as company_name,
                c.workspace_slug,
                c.status as company_status
            FROM company_joining_codes cjc
            INNER JOIN companies c ON cjc.workspace_id = c.id
            WHERE cjc.code = $1
            """,
            code
        )
        
        if not code_result:
            # Also check companies.joining_token for backward compatibility
            company_result = await db.execute_query(
                """
                SELECT 
                    id as workspace_id,
                    name as company_name,
                    workspace_slug,
                    status as company_status
                FROM companies
                WHERE joining_token = $1
                """,
                code
            )
            
            if not company_result:
                return ValidateCodeResponse(
                    valid=False,
                    message="Invalid joining code"
                )
            
            code_data = company_result[0]
        else:
            code_data = code_result[0]
        
        # Check if company is active
        if code_data.get('company_status') != 'active':
            return ValidateCodeResponse(
                valid=False,
                message="Company is not active"
            )
        
        # Check if code is active
        if code_data.get('is_active') == False:
            return ValidateCodeResponse(
                valid=False,
                message="Joining code has been deactivated"
            )
        
        # Check expiry
        if code_data.get('expires_at'):
            if datetime.now() > code_data['expires_at']:
                return ValidateCodeResponse(
                    valid=False,
                    message="Joining code has expired"
                )
        
        # Check usage limits
        if code_data.get('max_uses'):
            if code_data.get('current_uses', 0) >= code_data['max_uses']:
                return ValidateCodeResponse(
                    valid=False,
                    message="Joining code has reached maximum uses"
                )
        
        logger.info(f"✅ Valid joining code: {code} for {code_data['company_name']}")
        
        return ValidateCodeResponse(
            valid=True,
            company_id=str(code_data['workspace_id']),
            company_name=code_data['company_name'],
            workspace_slug=code_data.get('workspace_slug'),
            message="Valid joining code"
        )
        
    except Exception as e:
        logger.error(f"❌ Failed to validate code: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/join-with-code")
async def join_company_with_code(request: JoinWithCodeRequest):
    """
    Join company using joining code (self-service signup)
    
    PUBLIC ENDPOINT - No authentication required
    
    Per Architecture Blueprint:
    - This is ONE OF THREE permitted login routes: /api/auth/join
    - Public signup forms forbidden - only invite-based
    - Creates employee account with user-provided password
    - Validates code before creating account
    """
    try:
        code = request.code.upper().strip()
        
        # Validate code first
        validation = await validate_joining_code(ValidateCodeRequest(code=code))
        
        if not validation.valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=validation.message
            )
        
        workspace_id = validation.company_id
        
        # Check if email already exists
        existing = await db.execute_query(
            "SELECT id FROM profiles WHERE email = $1 AND workspace_id = $2",
            request.email.lower(),
            workspace_id
        )
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered in this company"
            )
        
        # Validate password strength
        generator = CredentialGenerator()
        is_valid, errors = generator.validate_password_strength(request.password)
        
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Password does not meet requirements: {', '.join(errors)}"
            )
        
        # Generate employee ID
        employee_id_result = await db.execute_query(
            "SELECT generate_employee_id($1) as employee_id",
            workspace_id
        )
        employee_id = employee_id_result[0]['employee_id'] if employee_id_result else f"EMP-2026-{generator.generate_employee_id_component()[:3]}"
        
        # Create user in Supabase Auth
        try:
            auth_response = db.client.auth.sign_up({
                "email": request.email.lower(),
                "password": request.password,
                "options": {
                    "data": {
                        "full_name": request.full_name,
                        "role": "employee",  # Code-based signup always creates employee
                        "employee_id": employee_id,
                        "joined_via_code": code
                    }
                }
            })
            
            if not auth_response.user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to create account"
                )
            
            auth_user_id = auth_response.user.id
            
        except Exception as auth_error:
            logger.error(f"❌ Auth creation failed: {auth_error}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Account creation failed: {str(auth_error)}"
            )
        
        # Create profile
        profile_data = {
            "id": auth_user_id,
            "workspace_id": workspace_id,
            "company_id": workspace_id,
            "email": request.email.lower(),
            "full_name": request.full_name,
            "role": "employee",  # Code-based signup always creates employee
            "employee_id": employee_id,
            "phone_number": request.phone_number,
            "is_active": True,
        }
        
        profile = await db.create_profile(profile_data)
        
        # Increment code usage count
        await db.execute_query(
            """
            UPDATE company_joining_codes
            SET current_uses = current_uses + 1, updated_at = NOW()
            WHERE code = $1
            """,
            code
        )
        
        logger.info(f"✅ New employee joined via code: {request.email} ({employee_id})")
        
        return {
            "success": True,
            "message": "Account created successfully",
            "employee": {
                "id": str(profile['id']),
                "email": profile['email'],
                "full_name": profile['full_name'],
                "employee_id": employee_id,
                "role": "employee",
                "workspace_id": workspace_id,
                "company_name": validation.company_name
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to join with code: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# ==================== DIRECT EMAIL INVITATION ENDPOINTS ====================

@router.post("/send-invitation", response_model=InvitationResponse)
@require_permission(Permission.CREATE_EMPLOYEE)
async def send_direct_invitation(
    request: InviteUserRequest,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Send direct email invitation to specific user
    
    Permission: CREATE_EMPLOYEE (or higher)
    Roles: company_admin, hr_manager, manager
    
    Difference from create-employee:
    - User receives invitation link via email
    - User sets own password during onboarding
    - More self-service oriented
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Check if email already exists
        existing = await db.execute_query(
            "SELECT id FROM profiles WHERE email = $1 AND workspace_id = $2",
            request.email.lower(),
            workspace_id
        )
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User already exists in this workspace"
            )
        
        # Get company details
        company = await db.get_company(workspace_id)
        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found"
            )
        
        # Generate invitation token
        generator = CredentialGenerator()
        invitation_token = generator.generate_invitation_token()
        expires_at = datetime.now() + timedelta(days=7)  # 7-day expiry
        
        # Store invitation in database
        await db.execute_query(
            """
            INSERT INTO invitations (
                workspace_id,
                email,
                full_name,
                role,
                department_id,
                token,
                invited_by,
                expires_at,
                status
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            """,
            workspace_id,
            request.email.lower(),
            request.full_name,
            request.role,
            request.department_id,
            invitation_token,
            current_user.user_id,
            expires_at,
            "pending"
        )
        
        join_url = f"https://app.yourhrms.com/accept-invitation?token={invitation_token}"
        
        # Send invitation email if requested
        if request.send_email:
            delivery = CredentialDelivery()
            email_content = delivery.prepare_invitation_email(
                recipient_email=request.email,
                recipient_name=request.full_name,
                temporary_password="",  # User will set password
                company_name=company['name'],
                created_by_name=current_user.full_name or current_user.email,
                workspace_slug=company.get('workspace_slug', workspace_id),
                invitation_token=invitation_token
            )
            
            # TODO: Send email via email service
            logger.info(f"📧 Invitation email prepared for {request.email}")
        
        logger.info(f"✅ Invitation sent to {request.email}")
        
        return InvitationResponse(
            success=True,
            message=f"Invitation sent to {request.email}",
            invitation_token=invitation_token,
            expires_at=expires_at,
            join_url=join_url
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to send invitation: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/my-company-code")
@require_permission(Permission.VIEW_COMPANY_SETTINGS)
async def get_company_code(
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get current company's joining code
    
    Permission: VIEW_COMPANY_SETTINGS
    Roles: company_admin, hr_manager
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Get active joining codes
        codes = await db.execute_query(
            """
            SELECT 
                code,
                expires_at,
                max_uses,
                current_uses,
                is_active,
                created_at
            FROM company_joining_codes
            WHERE workspace_id = $1
              AND is_active = TRUE
            ORDER BY created_at DESC
            LIMIT 5
            """,
            workspace_id
        )
        
        company = await db.get_company(workspace_id)
        
        return {
            "success": True,
            "workspace_id": workspace_id,
            "company_name": company['name'] if company else None,
            "codes": [dict(c) for c in codes]
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to get company codes: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/revoke-code/{code}")
@require_permission(Permission.EDIT_COMPANY_SETTINGS)
async def revoke_joining_code(
    code: str,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Revoke/deactivate a joining code
    
    Permission: EDIT_COMPANY_SETTINGS
    Roles: company_admin only
    """
    try:
        workspace_id = get_current_workspace_id()
        
        # Deactivate code
        result = await db.execute_query(
            """
            UPDATE company_joining_codes
            SET is_active = FALSE, updated_at = NOW()
            WHERE code = $1 AND workspace_id = $2
            RETURNING code
            """,
            code.upper(),
            workspace_id
        )
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Code not found"
            )
        
        logger.info(f"✅ Revoked joining code: {code}")
        
        return {
            "success": True,
            "message": f"Code {code} has been revoked"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to revoke code: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
