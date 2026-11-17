"""
FIXED Employee Management Routes - Compatible with Actual Supabase Schema
Works with profiles table columns: id, company_id, workspace_id, email, full_name, role, 
phone_number, profile_picture_url, face_embedding_url, is_active, created_at, updated_at, 
employee_id, department_id, reporting_manager_id
"""

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from uuid import UUID
import re
import logging
import secrets
from datetime import datetime

from ..auth.jwt_handler import jwt_handler
from ..auth.dependencies import get_current_user, CurrentUser
from ..database_complete import db_complete as db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/employees", tags=["Employee Management"])


# ==================== PYDANTIC VALIDATION SCHEMAS ====================

class EmployeeCreateRequest(BaseModel):
    """Request schema for creating a new employee"""
    email: EmailStr = Field(..., description="Employee's work email address")
    full_name: str = Field(..., min_length=3, max_length=255)
    phone_number: Optional[str] = Field(None, max_length=20)
    role: str = Field("employee", description="Role: employee, manager, or hr_manager")
    department_id: Optional[str] = None
    reporting_manager_id: Optional[str] = None
    employee_id: Optional[str] = Field(None, description="Company-specific employee ID")
    temporary_password: str = Field(..., min_length=8, description="Temporary password")
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v):
        return v.lower().strip()
    
    @field_validator('role')
    @classmethod
    def validate_role(cls, v):
        allowed_roles = ['employee', 'manager', 'hr_manager']
        if v not in allowed_roles and v != 'team_manager':
            raise ValueError(f"Invalid role. Allowed: {', '.join(allowed_roles)}")
        return 'manager' if v == 'team_manager' else v
    
    @field_validator('temporary_password')
    @classmethod
    def validate_password_strength(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not re.search(r'[A-Z]', v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r'[a-z]', v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r'\d', v):
            raise ValueError("Password must contain at least one digit")
        return v


class EmployeeResponse(BaseModel):
    """Response model for employee creation"""
    success: bool = True
    message: str
    employee: dict


# ==================== ADMIN DEPENDENCY ====================

async def get_current_admin_user(current_user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    """Ensure only admins can access"""
    if current_user.role not in ['super_admin', 'company_admin', 'hr_manager']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Only administrators can create employees."
        )
    return current_user


# ==================== EMPLOYEE CREATION ROUTES ====================

@router.post("/create", response_model=EmployeeResponse, status_code=status.HTTP_201_CREATED)
async def create_employee(
    request: EmployeeCreateRequest,
    current_admin: CurrentUser = Depends(get_current_admin_user)
):
    """
    Create a new employee (Admin only) - FIXED VERSION
    Compatible with actual Supabase schema
    """
    logger.info(f"📥 Create employee: {request.email} as {request.role}")
    
    try:
        # Extract admin's company context
        admin_company_id = current_admin.company_id
        admin_profile_id = current_admin.profile_id
        
        if not admin_company_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Admin must be associated with a company"
            )
        
        # Validate company exists and is active
        company = await db.get_company(admin_company_id)
        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found. Please create a company first from the Companies screen and ensure your account is linked to that company."
            )
        
        if company['status'] not in ['active', 'trial']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Cannot create employees for {company['status']} company"
            )
        
        # Check if email already exists in this company
        existing_employee = await db.execute_query(
            """
            SELECT id, email, is_active 
            FROM profiles 
            WHERE email = $1 AND company_id = $2
            """,
            request.email,
            admin_company_id
        )
        
        if existing_employee:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Employee with email {request.email} already exists in your company"
            )
        
        # Validate department exists (if provided)
        if request.department_id:
            department = await db.execute_query(
                """
                SELECT id FROM departments 
                WHERE id = $1 AND company_id = $2
                """,
                request.department_id,
                admin_company_id
            )
            
            if not department:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Department not found in your company"
                )
        
        # Validate reporting manager exists (if provided)
        if request.reporting_manager_id:
            manager = await db.execute_query(
                """
                SELECT id, is_active, role 
                FROM profiles 
                WHERE id = $1 AND company_id = $2
                """,
                request.reporting_manager_id,
                admin_company_id
            )
            
            if not manager:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Reporting manager not found in your company"
                )
            
            if not manager[0]['is_active']:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot assign inactive manager"
                )
        
        # Generate employee_id if not provided
        if not request.employee_id:
            # Auto-generate: EMP-{timestamp}-{random}
            timestamp = datetime.utcnow().strftime("%Y%m")
            random_suffix = secrets.token_hex(2).upper()
            employee_id = f"EMP-{timestamp}-{random_suffix}"
        else:
            employee_id = request.employee_id
            
            # Check uniqueness
            existing_id = await db.execute_query(
                "SELECT id FROM profiles WHERE employee_id = $1 AND company_id = $2",
                employee_id,
                admin_company_id
            )
            if existing_id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Employee ID {employee_id} already exists"
                )
        
        # Create user in Supabase Auth
        try:
            auth_response = db.client.auth.admin.create_user({
                "email": request.email.lower(),
                "password": request.temporary_password,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": request.full_name,
                    "role": request.role,
                    "employee_id": employee_id,
                    "created_by": admin_profile_id
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
            error_msg = str(auth_error)
            if "email" in error_msg.lower() and "already" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already registered"
                )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Authentication setup failed: {str(auth_error)}"
            )
        
        # CRITICAL: Use ONLY columns that exist in actual schema
        profile_data = {
            "id": auth_user_id,
            "company_id": admin_company_id,
            "workspace_id": admin_company_id,  # Use company_id as workspace_id
            "email": request.email.lower(),
            "full_name": request.full_name,
            "role": request.role,
            "is_active": True,
            "employee_id": employee_id,
        }
        
        # Add optional fields only if provided
        if request.phone_number:
            profile_data["phone_number"] = request.phone_number
        
        if request.department_id:
            profile_data["department_id"] = request.department_id
        
        if request.reporting_manager_id:
            profile_data["reporting_manager_id"] = request.reporting_manager_id
        
        # Create profile using Supabase client (not raw SQL)
        profile = await db.create_profile(profile_data)
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create employee record"
            )
        
        logger.info(f"✅ Profile created: {profile['id']}")
        
        # Prepare response
        employee_response = {
            "profile_id": str(profile['id']),
            "id": str(profile['id']),
            "email": profile['email'],
            "full_name": profile['full_name'],
            "phone_number": profile.get('phone_number'),
            "role": profile['role'],
            "department_id": profile.get('department_id'),
            "reporting_manager_id": profile.get('reporting_manager_id'),
            "employee_id": profile.get('employee_id'),
            "is_active": profile['is_active'],
            "created_at": profile.get('created_at'),
            "company_id": admin_company_id,
            "company_name": company['name']
        }
        
        logger.info(f"✅ Employee {request.full_name} created successfully")
        
        return EmployeeResponse(
            success=True,
            message=f"Employee {request.full_name} created successfully",
            employee=employee_response
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Employee creation error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        error_str = str(e).lower()
        if 'unique' in error_str and 'email' in error_str:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Email {request.email} is already registered"
            )
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create employee: {str(e)}"
        )


@router.get("/")
async def list_employees(
    current_admin: CurrentUser = Depends(get_current_admin_user),
    page: int = 1,
    page_size: int = 20,
    search: Optional[str] = None,
    department_id: Optional[str] = None,
    role: Optional[str] = None,
    is_active: Optional[bool] = None
):
    """List all employees in admin's company with filtering"""
    try:
        # Build dynamic query
        conditions = ["company_id = $1"]
        params = [current_admin.company_id]
        param_count = 1
        
        if search:
            param_count += 1
            conditions.append(f"(full_name ILIKE ${param_count} OR email ILIKE ${param_count})")
            params.append(f"%{search}%")
        
        if department_id:
            param_count += 1
            conditions.append(f"department_id = ${param_count}")
            params.append(department_id)
        
        if role:
            param_count += 1
            conditions.append(f"role = ${param_count}")
            params.append(role)
        
        if is_active is not None:
            param_count += 1
            conditions.append(f"is_active = ${param_count}")
            params.append(is_active)
        
        where_clause = " AND ".join(conditions)
        
        # Get total count
        count_query = f"SELECT COUNT(*) as total FROM profiles WHERE {where_clause}"
        count_result = await db.execute_query(count_query, *params)
        total = count_result[0]['total'] if count_result else 0
        
        # Get employees with pagination
        offset = (page - 1) * page_size
        employees_query = f"""
            SELECT 
                p.id, p.email, p.full_name, p.phone_number, p.role,
                p.department_id, p.employee_id, p.is_active, p.created_at, p.updated_at,
                p.reporting_manager_id, p.profile_picture_url
            FROM profiles p
            WHERE {where_clause}
            ORDER BY p.created_at DESC
            LIMIT ${param_count + 1} OFFSET ${param_count + 2}
        """
        params.extend([page_size, offset])
        
        employees = await db.execute_query(employees_query, *params)
        
        return {
            "success": True,
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size,
            "employees": employees or []
        }
        
    except Exception as e:
        logger.error(f"❌ List employees error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch employees: {str(e)}"
        )


@router.get("/{employee_id}")
async def get_employee_details(
    employee_id: str,
    current_admin: CurrentUser = Depends(get_current_admin_user)
):
    """Get employee details by ID"""
    try:
        employee = await db.execute_query(
            """
            SELECT 
                p.id, p.email, p.full_name, p.phone_number, p.role,
                p.department_id, p.employee_id, p.is_active,
                p.created_at, p.updated_at, p.reporting_manager_id,
                p.profile_picture_url
            FROM profiles p
            WHERE p.id = $1 AND p.company_id = $2
            """,
            employee_id,
            current_admin.company_id
        )
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found in your company"
            )
        
        return {
            "success": True,
            "employee": employee[0]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch employee: {str(e)}"
        )
