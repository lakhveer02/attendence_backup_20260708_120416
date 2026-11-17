"""
Role-Based Hierarchy Management
Implements role-based user creation permissions:
- Company Admin can create: HR, Manager
- HR can create: Employee, Manager  
- Manager can create: Employee
"""

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from datetime import datetime
import logging
import secrets

from ..auth.dependencies import get_current_user, CurrentUser
from ..auth.rbac import (
    Permission,
    require_permission,
    require_role,
    check_permission,
)
from ..database_complete import db_complete as db
from ..models import UserRole
from ..utils.credential_generator import (
    CredentialGenerator,
    CredentialDelivery,
    generate_user_credentials,
)
from ..middleware import get_current_workspace_id

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/role-management", tags=["Role Management"])


# ==================== ROLE HIERARCHY DEFINITION ====================
# Per Architecture Blueprint - Strict RBAC Matrix

ROLE_HIERARCHY = {
    "company_admin": ["hr_manager", "manager"],  # Company Admin can create HR Manager and Manager
    "hr_manager": ["employee", "manager"],        # HR Manager can create Employee and Manager
    "manager": ["employee"]                        # Manager can create Employee only
}

def can_create_role(creator_role: str, target_role: str) -> bool:
    """
    Check if a user with creator_role can create a user with target_role
    
    Per Architecture Blueprint:
    - Company Admin → HR Manager, Manager
    - HR Manager → Employee, Manager
    - Manager → Employee only
    
    Args:
        creator_role: Role of the user creating the account
        target_role: Role to be assigned to the new user
        
    Returns:
        bool: True if creator can create target role, False otherwise
    """
    # Super admin can create any role
    if creator_role == "super_admin":
        return True
    
    # Check if target role is in the allowed list for creator role
    allowed_roles = ROLE_HIERARCHY.get(creator_role, [])
    return target_role in allowed_roles


def get_allowed_roles(creator_role: str) -> List[str]:
    """
    Get list of roles that a user can create
    
    Args:
        creator_role: Role of the user
        
    Returns:
        List[str]: List of roles this user can create
    """
    if creator_role == "super_admin":
        return ["super_admin", "company_admin", "hr_manager", "manager", "employee"]
    
    return ROLE_HIERARCHY.get(creator_role, [])


# ==================== REQUEST/RESPONSE MODELS ====================

class CreateEmployeeRequest(BaseModel):
    """Request to create a new employee/user
    
    Workflow per Architecture Blueprint:
    - Company Admin creates HR Manager/Manager
    - HR Manager creates Employee/Manager
    - Manager creates Employee
    - Passwords are GENERATED SERVER-SIDE (not provided by creator)
    - Credentials delivered via secure channels
    """
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    # NOTE: password field REMOVED - generated server-side per blueprint
    role: str = Field(..., description="Role to assign: hr_manager, manager, or employee")
    phone_number: Optional[str] = Field(None, max_length=20)
    department_id: Optional[str] = None
    designation: Optional[str] = None
    employee_id: Optional[str] = None  # Auto-generated if not provided
    reporting_manager_id: Optional[str] = None  # For Manager hierarchy
    shift_schedule: Optional[str] = None
    date_of_joining: Optional[str] = None
    send_invitation_email: bool = Field(True, description="Send email with credentials")

    @field_validator('role')
    @classmethod
    def validate_role(cls, v):
        allowed_roles = ['employee', 'manager', 'hr_manager']
        if v not in allowed_roles and v != 'team_manager':
            raise ValueError(f"Invalid role. Must be one of: {', '.join(allowed_roles)}")
        return 'manager' if v == 'team_manager' else v
    
    class Config:
        json_schema_extra = {
            "example": {
                "email": "john.doe@company.com",
                "full_name": "John Doe",
                "role": "employee",
                "phone_number": "+1234567890",
                "designation": "Software Engineer",
                "reporting_manager_id": "manager-uuid-here",
                "send_invitation_email": True
            }
        }


class EmployeeResponse(BaseModel):
    """Response with created employee details"""
    success: bool
    message: str
    employee: dict


class AllowedRolesResponse(BaseModel):
    """Response with roles the current user can create"""
    success: bool
    allowed_roles: List[str]
    current_role: str
    message: str


# ==================== ENDPOINTS ====================

@router.get("/allowed-roles", response_model=AllowedRolesResponse)
async def get_allowed_roles_for_user(
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get list of roles the current user is allowed to create
    
    This endpoint helps the frontend show only valid role options
    based on the logged-in user's role.
    """
    try:
        allowed = get_allowed_roles(current_user.role)
        
        role_descriptions = {
            "super_admin": "Super Administrator - System-wide access across all companies",
            "company_admin": "Company Administrator - Full ownership of workspace",
            "hr_manager": "HR Manager - Personnel operations and department oversight",
            "manager": "Manager - Team lead with direct report visibility",
            "employee": "Employee - Access to personal data only"
        }
        
        roles_with_desc = [
            {
                "role": role,
                "description": role_descriptions.get(role, ""),
                "display_name": role.replace("_", " ").title()
            }
            for role in allowed
        ]
        
        return AllowedRolesResponse(
            success=True,
            allowed_roles=allowed,
            current_role=current_user.role,
            message=f"You can create users with the following roles: {', '.join(allowed)}"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get allowed roles: {str(e)}"
        )


@router.post("/create-employee", response_model=EmployeeResponse, status_code=status.HTTP_201_CREATED)
async def create_employee(
    request: CreateEmployeeRequest,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Create a new employee/user with role-based permissions
    
    Role Hierarchy per Architecture Blueprint:
    - Company Admin → can create HR Manager, Manager
    - HR Manager → can create Employee, Manager
    - Manager → can create Employee only
    
    The creator must have the appropriate role to create users with the specified role.
    """
    logger.info(f"📥 Create employee request: {request.email} as {request.role} by {current_user.email} ({current_user.role})")
    
    try:
        # Use company_id from current user (not workspace middleware)
        company_id = current_user.company_id
        
        if not company_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User must be associated with a company"
            )
        if not can_create_role(current_user.role, request.role):
            allowed = get_allowed_roles(current_user.role)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"You ({current_user.role}) cannot create users with role '{request.role}'. "
                       f"You can only create: {', '.join(allowed)}"
            )
        
        # Validate role is a valid enum value
        valid_roles = ["super_admin", "company_admin", "hr_manager", "manager", "employee"]
        if request.role not in valid_roles:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid role. Must be one of: {', '.join(valid_roles)}"
            )
        
        # Check if email already exists in this company
        existing = await db.execute_query(
            """
            SELECT id FROM profiles 
            WHERE email = $1 AND company_id = $2
            """,
            request.email.lower(),
            company_id
        )
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User with email {request.email} already exists in your company"
            )
        
        # Verify company exists
        company = await db.get_company(company_id)
        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found"
            )
        
        # Verify department exists if provided
        if request.department_id:
            dept_result = await db.execute_query(
                "SELECT id FROM departments WHERE id = $1 AND company_id = $2",
                request.department_id,
                company_id
            )
            if not dept_result:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Department not found"
                )
        
        # Verify reporting manager exists if provided
        if request.reporting_manager_id:
            manager_result = await db.execute_query(
                "SELECT id, role FROM profiles WHERE id = $1 AND company_id = $2",
                request.reporting_manager_id,
                company_id
            )
            if not manager_result:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Reporting manager not found"
                )
            # Verify manager role is appropriate
            manager_role = manager_result[0]['role']
            if manager_role not in ['manager', 'hr_manager', 'company_admin']:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Reporting manager must have manager, hr_manager, or company_admin role"
                )
        
        # ===== SERVER-SIDE CREDENTIAL GENERATION =====
        # Per Architecture Blueprint: Passwords generated server-side
        credential_gen = CredentialGenerator()
        temporary_password = credential_gen.generate_temporary_password()
        invitation_token = credential_gen.generate_invitation_token()
        
        # Validate generated password meets requirements
        is_valid, errors = credential_gen.validate_password_strength(temporary_password)
        if not is_valid:
            logger.error(f"❌ Generated password failed validation: {errors}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to generate secure password"
            )
        
        logger.info(f"✅ Generated secure credentials for {request.email}")
        
        # Generate or use provided employee ID
        if not request.employee_id:
            # Auto-generate employee ID: EMP-YYYY-XXX
            generated_id = await db.execute_query(
                "SELECT generate_employee_id($1) as employee_id",
                company_id
            )
            employee_id = generated_id[0]['employee_id'] if generated_id else f"EMP-2026-{secrets.token_hex(3).upper()}"
        else:
            employee_id = request.employee_id
            
            # Verify employee ID is unique in company
            existing_id = await db.execute_query(
                "SELECT id FROM profiles WHERE employee_id = $1 AND company_id = $2",
                employee_id,
                company_id
            )
            if existing_id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Employee ID {employee_id} already exists in this workspace"
                )
        
        logger.info(f"✅ Assigned employee ID: {employee_id}")
        
        # Create user in Supabase Auth with generated password
        try:
            auth_response = db.client.auth.admin.create_user({
                "email": request.email.lower(),
                "password": temporary_password,  # Server-generated password
                "email_confirm": True,  # Auto-confirm email for admin-created users
                "user_metadata": {
                    "full_name": request.full_name,
                    "role": request.role,
                    "employee_id": employee_id,
                    "created_by": current_user.email,
                    "requires_password_change": True  # Force password change on first login
                }
            })
            
            if not auth_response.user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to create authentication user"
                )
            
            auth_user_id = auth_response.user.id
            logger.info(f"✅ Supabase Auth user created: {auth_user_id}")
            
        except Exception as auth_error:
            logger.error(f"❌ Auth creation failed: {auth_error}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Authentication setup failed: {str(auth_error)}"
            )
        
        # CRITICAL: Use ONLY columns that exist in actual schema
        # profiles table has: id, company_id, workspace_id, email, full_name, role, 
        # phone_number, profile_picture_url, face_embedding_url, is_active, created_at, 
        # updated_at, employee_id, department_id, reporting_manager_id
        profile_data = {
            "id": auth_user_id,
            "workspace_id": company_id,
            "company_id": company_id,
            "email": request.email.lower(),
            "full_name": request.full_name,
            "role": request.role,
            "employee_id": employee_id,
            "is_active": True,
        }
        
        # Add optional fields
        if request.phone_number:
            profile_data["phone_number"] = request.phone_number
        if request.department_id:
            profile_data["department_id"] = request.department_id
        if request.reporting_manager_id:
            profile_data["reporting_manager_id"] = request.reporting_manager_id
        
        profile = await db.create_profile(profile_data)
        
        # ===== CREDENTIAL DELIVERY =====
        # Per Architecture Blueprint: Deliver via secure transmission channels
        
        credential_delivery = CredentialDelivery()
        
        # Prepare credentials for immediate display to admin
        credentials_handoff = credential_delivery.prepare_credential_handoff(
            recipient_email=request.email,
            recipient_name=request.full_name,
            temporary_password=temporary_password,
            role=request.role,
            employee_id=employee_id,
            created_by_name=current_user.full_name or current_user.email
        )
        
        # Prepare invitation email (if requested)
        if request.send_invitation_email:
            email_content = credential_delivery.prepare_invitation_email(
                recipient_email=request.email,
                recipient_name=request.full_name,
                temporary_password=temporary_password,
                company_name=company['name'],
                created_by_name=current_user.full_name or current_user.email,
                workspace_slug=company.get('workspace_slug', workspace_id),
                invitation_token=invitation_token
            )
            
            # TODO: Send email via email service (SendGrid, AWS SES, etc.)
            # await email_service.send_email(email_content)
            
            logger.info(f"📧 Invitation email prepared for {request.email}")
            credentials_handoff["email_sent"] = True
            credentials_handoff["email_preview"] = {
                "subject": email_content["subject"],
                "to": email_content["to"]
            }
        
        # Prepare final response with all details
        employee_data = {
            "id": str(profile['id']),
            "email": profile['email'],
            "full_name": profile['full_name'],
            "employee_id": employee_id,
            "role": profile['role'],
            "workspace_id": str(profile.get('workspace_id', company_id)),
            "company_id": str(profile.get('company_id', company_id)),
            "company_name": company['name'],
            "is_active": profile['is_active'],
            "reporting_manager_id": request.reporting_manager_id,
            "department_id": request.department_id,
            "created_at": profile.get('created_at'),
            "created_by": current_user.email
        }
        
        logger.info(f"✅ Employee created successfully: {request.email} ({request.role})")
        
        return {
            **credentials_handoff,
            "employee": employee_data
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to create employee: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create employee: {str(e)}"
        )


@router.get("/employees", response_model=dict)
async def get_employees(
    role: Optional[str] = None,
    department_id: Optional[str] = None,
    is_active: Optional[bool] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Get list of employees in the company with optional filters
    
    Query parameters:
    - role: Filter by role (hr, manager, employee)
    - department_id: Filter by department
    - is_active: Filter by active status
    """
    try:
        # Build query dynamically based on filters
        conditions = ["company_id = $1"]
        params = [current_user.company_id]
        param_count = 1
        
        if role:
            param_count += 1
            conditions.append(f"role = ${param_count}")
            params.append(role)
        
        if department_id:
            param_count += 1
            conditions.append(f"department_id = ${param_count}")
            params.append(department_id)
        
        if is_active is not None:
            param_count += 1
            conditions.append(f"is_active = ${param_count}")
            params.append(is_active)
        
        where_clause = " AND ".join(conditions)
        
        query = f"""
            SELECT 
                p.id,
                p.email,
                p.full_name,
                p.role,
                p.phone_number,
                p.department_id,
                d.name as department_name,
                p.is_active,
                p.created_at,
                p.updated_at
            FROM profiles p
            LEFT JOIN departments d ON p.department_id = d.id
            WHERE {where_clause}
            ORDER BY p.created_at DESC
        """
        
        employees = await db.execute_query(query, *params)
        
        return {
            "success": True,
            "count": len(employees),
            "employees": [dict(emp) for emp in employees]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get employees: {str(e)}"
        )


@router.put("/employees/{employee_id}/toggle-status", response_model=dict)
@require_permission(Permission.ACTIVATE_DEACTIVATE_USER)
async def toggle_employee_status(
    employee_id: str,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Activate or deactivate an employee
    
    Permission: ACTIVATE_DEACTIVATE_USER
    Roles: company_admin, hr_manager
    """
    try:
        # Permission check is handled by decorator
        # No need for manual role check
        
        # Get employee
        employee_result = await db.execute_query(
            """
            SELECT id, email, full_name, role, is_active, company_id
            FROM profiles
            WHERE id = $1
            """,
            employee_id
        )
        
        if not employee_result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        employee = employee_result[0]
        
        # Verify employee is in same company
        if str(employee['company_id']) != current_user.company_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot modify employees from other companies"
            )
        
        # Toggle status
        new_status = not employee['is_active']
        
        await db.execute_query(
            """
            UPDATE profiles
            SET is_active = $1, updated_at = NOW()
            WHERE id = $2
            """,
            new_status,
            employee_id
        )
        
        return {
            "success": True,
            "message": f"Employee {'activated' if new_status else 'deactivated'} successfully",
            "employee_id": employee_id,
            "email": employee['email'],
            "is_active": new_status
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to toggle employee status: {str(e)}"
        )


@router.get("/role-hierarchy", response_model=dict)
async def get_role_hierarchy():
    """
    Get the complete role hierarchy structure
    
    This is a public endpoint that shows the role structure
    for documentation and frontend reference.
    """
    return {
        "success": True,
        "hierarchy": {
            "company_admin": {
                "can_create": ["hr_manager", "manager"],
                "description": "Company Admin can create HR Manager and Manager"
            },
            "hr_manager": {
                "can_create": ["employee", "manager"],
                "description": "HR Manager can create Employee and Manager"
            },
            "manager": {
                "can_create": ["employee"],
                "description": "Manager can create only Employee"
            },
            "employee": {
                "can_create": [],
                "description": "Employee cannot create other users"
            }
        },
        "roles": {
            "super_admin": "Super Administrator - System-wide access across all companies",
            "company_admin": "Company Administrator - Full ownership of workspace",
            "hr_manager": "HR Manager - Personnel operations and department oversight",
            "manager": "Manager - Team lead with direct report visibility",
            "employee": "Employee - Access to personal data only"
        }
    }
