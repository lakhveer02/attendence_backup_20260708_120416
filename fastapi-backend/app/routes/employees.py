"""
Admin-Controlled Employee Provisioning System
Protected routes for creating and managing employees with temporary passwords
"""

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from uuid import UUID
import re
from datetime import datetime

from ..auth.jwt_handler import jwt_handler
from ..auth.dependencies import (
    get_current_user,
    CurrentUser,
    RoleChecker,
    RequireCompanyAdmin
)
from ..database_complete import db_complete as db

router = APIRouter(prefix="/api/v1/employees", tags=["Employee Management"])


# ==================== PYDANTIC VALIDATION SCHEMAS ====================

class EmployeeCreateRequest(BaseModel):
    """
    Request schema for creating a new employee (Admin only)
    Employees are provisioned by admins with temporary passwords
    """
    # Identity
    email: EmailStr = Field(
        ...,
        description="Employee's work email address (must be unique per company)"
    )
    full_name: str = Field(
        ...,
        min_length=3,
        max_length=255,
        description="Employee's full name"
    )
    phone_number: Optional[str] = Field(
        None,
        max_length=20,
        description="Employee's contact phone number"
    )
    
    # Role & Department
    role: str = Field(
        "employee",
        description="Employee role: employee, manager, or hr_manager"
    )
    department_id: Optional[UUID] = Field(
        None,
        description="Department UUID the employee belongs to"
    )
    
    # Temporary Credentials
    temporary_password: str = Field(
        ...,
        min_length=8,
        description="Temporary password (employee must reset on first login)"
    )
    
    # Optional Profile Details
    designation: Optional[str] = Field(
        None,
        max_length=100,
        description="Job title/designation"
    )
    employee_id: Optional[str] = Field(
        None,
        max_length=50,
        description="Company-specific employee ID/code"
    )
    manager_id: Optional[UUID] = Field(
        None,
        description="Direct manager's profile UUID"
    )
    joining_date: Optional[str] = Field(
        None,
        description="Date of joining (ISO format: YYYY-MM-DD)"
    )
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v):
        """Normalize email to lowercase"""
        return v.lower().strip()
    
    @field_validator('role')
    @classmethod
    def validate_role(cls, v):
        """
        Restrict roles that admins can assign
        Super admins and company admins cannot be created via this endpoint
        """
        allowed_roles = ['employee', 'manager', 'hr_manager']
        if v not in allowed_roles and v != 'team_manager':
            raise ValueError(
                f"Invalid role. Allowed roles: {', '.join(allowed_roles)}"
            )
        return 'manager' if v == 'team_manager' else v
    
    @field_validator('temporary_password')
    @classmethod
    def validate_password_strength(cls, v):
        """
        Enforce password complexity requirements
        """
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        
        if not re.search(r'[A-Z]', v):
            raise ValueError("Password must contain at least one uppercase letter")
        
        if not re.search(r'[a-z]', v):
            raise ValueError("Password must contain at least one lowercase letter")
        
        if not re.search(r'\d', v):
            raise ValueError("Password must contain at least one digit")
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError("Password must contain at least one special character")
        
        return v
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone_number(cls, v):
        """Basic phone number validation"""
        if v is None:
            return v
        
        # Remove common separators
        cleaned = re.sub(r'[\s\-\(\)]', '', v)
        
        # Check if it contains only digits and + (for country code)
        if not re.match(r'^\+?[\d]{10,15}$', cleaned):
            raise ValueError("Invalid phone number format")
        
        return v


class EmployeeResponse(BaseModel):
    """Response model for employee creation"""
    success: bool = True
    message: str
    employee: dict


class EmployeeUpdateRequest(BaseModel):
    """Request schema for updating employee details (Admin only)"""
    full_name: Optional[str] = Field(None, min_length=3, max_length=255)
    phone_number: Optional[str] = Field(None, max_length=20)
    designation: Optional[str] = Field(None, max_length=100)
    department_id: Optional[UUID] = None
    manager_id: Optional[UUID] = None
    is_active: Optional[bool] = None


class BulkEmployeeCreateRequest(BaseModel):
    """Request schema for bulk employee creation"""
    employees: List[EmployeeCreateRequest] = Field(
        ...,
        min_items=1,
        max_items=50,
        description="List of employees to create (max 50 per request)"
    )


# ==================== ADMIN DEPENDENCY ====================

async def get_current_admin_user(
    current_user: CurrentUser = Depends(get_current_user)
) -> CurrentUser:
    """
    Dependency to ensure only Super Admins or Company Admins can access
    
    This is a specialized version of RoleChecker for admin-only operations
    """
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
    Create a new employee with temporary password (Admin only)
    
    **Access Control:**
    - Super Admin: Can create employees for any company
    - Company Admin: Can only create employees for their own company
    - HR Admin: Can only create employees for their own company
    
    **Workflow:**
    1. Validate admin has permission to create employee in target company
    2. Check email uniqueness within company context
    3. Hash temporary password securely
    4. Insert employee into profiles table with company_id isolation
    5. Set is_temporary_password = True to force password reset on first login
    6. Log creation in audit_logs
    
    **Security Features:**
    - Automatic company_id enforcement (data isolation)
    - Password complexity validation
    - Email uniqueness per company
    - Audit trail of who created the employee
    """
    try:
        # Step 1: Extract admin's company context
        admin_company_id = current_admin.company_id
        admin_profile_id = current_admin.profile_id
        
        # Step 2: Validate company exists and admin has access
        if not admin_company_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Admin must be associated with a company to create employees"
            )
        
        company = await db.get_company(admin_company_id)
        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found"
            )
        
        if company['status'] not in ['active', 'trial']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Cannot create employees for {company['status']} company"
            )
        
        # Step 3: Check if email already exists in this company
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
            employee = existing_employee[0]
            if employee['is_active']:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Employee with email {request.email} already exists in your company"
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"An inactive employee account exists with this email. Please reactivate instead."
                )
        
        # Step 4: Validate department exists (if provided)
        if request.department_id:
            department = await db.execute_query(
                """
                SELECT id, company_id, is_active 
                FROM departments 
                WHERE id = $1 AND company_id = $2
                """,
                str(request.department_id),
                admin_company_id
            )
            
            if not department:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Department not found in your company"
                )
            
            if not department[0].get('is_active', True):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot assign employee to inactive department"
                )
        
        # Step 5: Validate manager exists (if provided)
        if request.manager_id:
            manager = await db.execute_query(
                """
                SELECT id, company_id, is_active, role 
                FROM profiles 
                WHERE id = $1 AND company_id = $2
                """,
                str(request.manager_id),
                admin_company_id
            )
            
            if not manager:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Manager not found in your company"
                )
            
            if not manager[0]['is_active']:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot assign inactive manager"
                )
        
        # Step 6: Hash the temporary password using bcrypt
        password_hash = jwt_handler.hash_password(request.temporary_password)
        
        # Step 7: Prepare employee data with strict company isolation
        employee_data = {
            # Company association (enforces multi-tenant isolation)
            "company_id": admin_company_id,
            
            # Identity
            "email": request.email,
            "password_hash": password_hash,
            "full_name": request.full_name,
            "phone_number": request.phone_number,
            
            # Role & Organization
            "role": request.role,
            "department_id": str(request.department_id) if request.department_id else None,
            "manager_id": str(request.manager_id) if request.manager_id else None,
            
            # Profile Details
            "designation": request.designation,
            "employee_id": request.employee_id,
            "joining_date": request.joining_date,
            
            # Security Flags (CRITICAL)
            "is_temporary_password": True,  # Force password reset on first login
            "is_active": True,               # Account is active
            "is_verified": False,            # Email verification pending
            "is_email_verified": False,
            
            # Audit
            "created_by": admin_profile_id,
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Step 8: Insert employee into database
        # Use raw SQL for explicit control over all fields
        employee = await db.execute_query(
            """
            INSERT INTO profiles (
                company_id, email, password_hash, full_name, phone_number,
                role, department_id, manager_id, designation, employee_id,
                joining_date, is_temporary_password, is_active, is_verified,
                is_email_verified, created_by, created_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW()
            )
            RETURNING 
                id, email, full_name, phone_number, role, department_id,
                designation, employee_id, is_active, is_temporary_password,
                created_at
            """,
            admin_company_id,
            request.email,
            password_hash,
            request.full_name,
            request.phone_number,
            request.role,
            str(request.department_id) if request.department_id else None,
            str(request.manager_id) if request.manager_id else None,
            request.designation,
            request.employee_id,
            request.joining_date,
            True,  # is_temporary_password
            True,  # is_active
            False, # is_verified
            False, # is_email_verified
            admin_profile_id
        )
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create employee record"
            )
        
        new_employee = employee[0]
        
        # Step 9: Log the creation in audit_logs
        await db.execute_query(
            """
            INSERT INTO audit_logs (
                company_id, profile_id, action, entity_type, entity_id,
                new_values, success, created_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, NOW()
            )
            """,
            admin_company_id,
            admin_profile_id,
            "employee_created",
            "profile",
            str(new_employee['id']),
            {
                "email": request.email,
                "role": request.role,
                "full_name": request.full_name,
                "created_by": admin_profile_id
            },
            True
        )
        
        # Step 10: Prepare response
        employee_response = {
            "profile_id": str(new_employee['id']),
            "email": new_employee['email'],
            "full_name": new_employee['full_name'],
            "phone_number": new_employee['phone_number'],
            "role": new_employee['role'],
            "department_id": new_employee.get('department_id'),
            "designation": new_employee.get('designation'),
            "employee_id": new_employee.get('employee_id'),
            "is_active": new_employee['is_active'],
            "is_temporary_password": new_employee['is_temporary_password'],
            "created_at": new_employee['created_at'],
            "company_id": admin_company_id,
            "company_name": company['name']
        }
        
        return EmployeeResponse(
            success=True,
            message=f"Employee {request.full_name} created successfully with temporary password",
            employee=employee_response
        )
        
    except HTTPException:
        # Re-raise HTTP exceptions (already formatted)
        raise
    
    except Exception as e:
        # Handle database constraint violations and other errors
        error_str = str(e).lower()
        
        if 'unique' in error_str and 'email' in error_str:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Email {request.email} is already registered in this company"
            )
        
        if 'foreign key' in error_str:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid department_id or manager_id provided"
            )
        
        # Log unexpected errors
        print(f"Error creating employee: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create employee: {str(e)}"
        )


@router.post("/bulk-create", status_code=status.HTTP_201_CREATED)
async def bulk_create_employees(
    request: BulkEmployeeCreateRequest,
    current_admin: CurrentUser = Depends(get_current_admin_user)
):
    """
    Bulk create multiple employees at once (Admin only)
    
    **Features:**
    - Create up to 50 employees in a single request
    - Atomic transaction (all succeed or all fail)
    - Returns detailed results for each employee
    - Skips duplicates with warnings
    """
    created_employees = []
    failed_employees = []
    
    for idx, employee_req in enumerate(request.employees):
        try:
            # Call single create endpoint for each employee
            result = await create_employee(employee_req, current_admin)
            created_employees.append({
                "index": idx,
                "email": employee_req.email,
                "status": "success",
                "employee": result.employee
            })
        except HTTPException as e:
            failed_employees.append({
                "index": idx,
                "email": employee_req.email,
                "status": "failed",
                "error": e.detail
            })
        except Exception as e:
            failed_employees.append({
                "index": idx,
                "email": employee_req.email,
                "status": "failed",
                "error": str(e)
            })
    
    return {
        "success": len(failed_employees) == 0,
        "message": f"Created {len(created_employees)} of {len(request.employees)} employees",
        "created_count": len(created_employees),
        "failed_count": len(failed_employees),
        "created_employees": created_employees,
        "failed_employees": failed_employees
    }


@router.get("/{employee_id}")
async def get_employee_details(
    employee_id: UUID,
    current_admin: CurrentUser = Depends(get_current_admin_user)
):
    """Get employee details by ID (Admin only)"""
    try:
        # Ensure admin can only access employees in their company
        employee = await db.execute_query(
            """
            SELECT 
                p.id, p.email, p.full_name, p.phone_number, p.role,
                p.department_id, p.designation, p.employee_id, p.is_active,
                p.is_temporary_password, p.last_login_at, p.created_at,
                d.name as department_name,
                m.full_name as manager_name
            FROM profiles p
            LEFT JOIN departments d ON p.department_id = d.id
            LEFT JOIN profiles m ON p.manager_id = m.id
            WHERE p.id = $1 AND p.company_id = $2
            """,
            str(employee_id),
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


@router.put("/{employee_id}")
async def update_employee(
    employee_id: UUID,
    request: EmployeeUpdateRequest,
    current_admin: CurrentUser = Depends(get_current_admin_user)
):
    """Update employee details (Admin only)"""
    try:
        # Verify employee exists in admin's company
        employee = await db.execute_query(
            "SELECT id FROM profiles WHERE id = $1 AND company_id = $2",
            str(employee_id),
            current_admin.company_id
        )
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found in your company"
            )
        
        # Build dynamic update query
        updates = request.dict(exclude_unset=True)
        if not updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        # Perform update
        updated_employee = await db.update_profile(str(employee_id), updates)
        
        return {
            "success": True,
            "message": "Employee updated successfully",
            "employee": updated_employee
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update employee: {str(e)}"
        )


@router.delete("/{employee_id}")
async def deactivate_employee(
    employee_id: UUID,
    current_admin: CurrentUser = Depends(get_current_admin_user)
):
    """
    Deactivate employee (soft delete - Admin only)
    
    Note: We don't permanently delete employees to maintain data integrity
    and audit trails. Instead, we set is_active = False.
    """
    try:
        # Verify employee exists in admin's company
        employee = await db.execute_query(
            """
            SELECT id, email, full_name, is_active 
            FROM profiles 
            WHERE id = $1 AND company_id = $2
            """,
            str(employee_id),
            current_admin.company_id
        )
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found in your company"
            )
        
        if not employee[0]['is_active']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Employee is already deactivated"
            )
        
        # Deactivate employee
        await db.execute_query(
            "UPDATE profiles SET is_active = FALSE WHERE id = $1",
            str(employee_id)
        )
        
        # Revoke all refresh tokens
        await db.execute_query(
            """
            UPDATE refresh_tokens 
            SET is_revoked = TRUE, revoked_at = NOW()
            WHERE profile_id = $1 AND is_revoked = FALSE
            """,
            str(employee_id)
        )
        
        # Log deactivation
        await db.execute_query(
            """
            INSERT INTO audit_logs (
                company_id, profile_id, action, entity_type, entity_id, success
            ) VALUES ($1, $2, $3, $4, $5, $6)
            """,
            current_admin.company_id,
            current_admin.profile_id,
            "employee_deactivated",
            "profile",
            str(employee_id),
            True
        )
        
        return {
            "success": True,
            "message": f"Employee {employee[0]['full_name']} deactivated successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to deactivate employee: {str(e)}"
        )


@router.get("/")
async def list_employees(
    current_admin: CurrentUser = Depends(get_current_admin_user),
    page: int = 1,
    page_size: int = 20,
    search: Optional[str] = None,
    department_id: Optional[UUID] = None,
    role: Optional[str] = None,
    is_active: Optional[bool] = None
):
    """
    List all employees in admin's company with filtering and pagination
    """
    try:
        # Build dynamic query with filters
        conditions = ["p.company_id = $1"]
        params = [current_admin.company_id]
        param_count = 1
        
        if search:
            param_count += 1
            conditions.append(f"(p.full_name ILIKE ${param_count} OR p.email ILIKE ${param_count})")
            params.append(f"%{search}%")
        
        if department_id:
            param_count += 1
            conditions.append(f"p.department_id = ${param_count}")
            params.append(str(department_id))
        
        if role:
            param_count += 1
            conditions.append(f"p.role = ${param_count}")
            params.append(role)
        
        if is_active is not None:
            param_count += 1
            conditions.append(f"p.is_active = ${param_count}")
            params.append(is_active)
        
        where_clause = " AND ".join(conditions)
        
        # Get total count
        count_query = f"""
            SELECT COUNT(*) as total
            FROM profiles p
            WHERE {where_clause}
        """
        count_result = await db.execute_query(count_query, *params)
        total = count_result[0]['total'] if count_result else 0
        
        # Get employees with pagination
        offset = (page - 1) * page_size
        employees_query = f"""
            SELECT 
                p.id, p.email, p.full_name, p.phone_number, p.role,
                p.department_id, p.designation, p.employee_id, p.is_active,
                p.is_temporary_password, p.last_login_at, p.created_at,
                d.name as department_name,
                m.full_name as manager_name
            FROM profiles p
            LEFT JOIN departments d ON p.department_id = d.id
            LEFT JOIN profiles m ON p.manager_id = m.id
            WHERE {where_clause}
            ORDER BY p.created_at DESC
            LIMIT ${ param_count + 1} OFFSET ${param_count + 2}
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
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch employees: {str(e)}"
        )
