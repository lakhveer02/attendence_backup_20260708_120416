"""
Enterprise FastAPI Dependencies - Complete RBAC Implementation
Dual-layered dependency injection: Authentication + Authorization
"""

from fastapi import Depends, HTTPException, status, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional, List, Dict, Any
import jwt as pyjwt
from .jwt_handler import jwt_handler

# Security scheme
security = HTTPBearer(
    scheme_name="JWT Bearer Token",
    description="Enter your JWT access token"
)


class CurrentUser:
    """Current authenticated user context"""
    
    def __init__(self, payload: Dict[str, Any]):
        # Handle both FastAPI tokens and Supabase tokens
        is_supabase = 'user_metadata' in payload
        
        if is_supabase:
            # Supabase token format
            user_metadata = payload.get("user_metadata", {})
            self.profile_id: str = payload.get("sub")
            self.email: str = payload.get("email")
            self.name: str = user_metadata.get("full_name", "")
            self.role: str = user_metadata.get("role", "employee")
            self.company_id: Optional[str] = user_metadata.get("company_id")
            self.company_name: Optional[str] = user_metadata.get("company_name")
            self.token_id: str = payload.get("session_id", payload.get("jti", ""))
            
            # Map role-based permissions for Supabase tokens
            self.permissions: List[str] = jwt_handler._get_role_permissions(self.role)
        else:
            # FastAPI token format
            self.profile_id: str = payload.get("sub")
            self.email: str = payload.get("email")
            self.name: str = payload.get("name")
            self.role: str = payload.get("role")
            self.permissions: List[str] = payload.get("permissions", [])
            self.company_id: Optional[str] = payload.get("company_id")
            self.company_name: Optional[str] = payload.get("company_name")
            self.token_id: str = payload.get("jti")
        
        self._payload = payload
    
    def has_permission(self, permission: str) -> bool:
        """Check if user has specific permission"""
        return jwt_handler.check_permission(self._payload, permission)
    
    def has_any_permission(self, permissions: List[str]) -> bool:
        """Check if user has any of the specified permissions"""
        return any(self.has_permission(p) for p in permissions)
    
    def has_all_permissions(self, permissions: List[str]) -> bool:
        """Check if user has all specified permissions"""
        return all(self.has_permission(p) for p in permissions)
    
    def is_super_admin(self) -> bool:
        """Check if user is super admin"""
        return self.role == "super_admin"
    
    def is_company_admin(self) -> bool:
        """Check if user is company admin"""
        return self.role in ["super_admin", "company_admin"]
    
    def is_hr_admin(self) -> bool:
        """Check if user is HR admin or higher"""
        return self.role in ["super_admin", "company_admin", "hr_manager"]
    
    def can_manage_company(self, company_id: str) -> bool:
        """Check if user can manage specific company"""
        if self.is_super_admin():
            return True
        return self.company_id == company_id and self.is_company_admin()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            "profile_id": self.profile_id,
            "email": self.email,
            "name": self.name,
            "role": self.role,
            "permissions": self.permissions,
            "company_id": self.company_id,
            "company_name": self.company_name
        }


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> CurrentUser:
    """
    Dependency: Extract and validate JWT token from Authorization header
    
    Usage in endpoint:
        @app.get("/protected")
        async def protected_route(current_user: CurrentUser = Depends(get_current_user)):
            return {"user": current_user.email}
    
    Raises:
        - HTTP 401: Missing, invalid, or expired token
        - HTTP 403: Token type mismatch
    """
    token = credentials.credentials
    
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    try:
        # Decode and validate token
        payload = jwt_handler.decode_token(token)
        
        # Verify token type
        if not jwt_handler.verify_token_type(payload, "access"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Invalid token type. Expected access token."
            )
        
        # Create user context
        return CurrentUser(payload)
        
    except pyjwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please login again.",
            headers={"WWW-Authenticate": "Bearer"}
        )
    except pyjwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"}
        )
    except Exception as e:
        # Log the actual error for debugging
        import traceback
        print(f"❌ Authentication error: {str(e)}")
        print(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Authentication failed: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"}
        )


class RoleChecker:
    """
    Dependency class for role-based access control
    
    Usage:
        @app.get("/admin-only")
        async def admin_route(
            current_user: CurrentUser = Depends(get_current_user),
            _: bool = Depends(RoleChecker(["super_admin", "company_admin"]))
        ):
            return {"message": "Admin access granted"}
    """
    
    def __init__(self, allowed_roles: List[str]):
        self.allowed_roles = allowed_roles
    
    def __call__(self, current_user: CurrentUser = Depends(get_current_user)) -> bool:
        """
        Check if current user has required role
        
        Raises:
            HTTP 403: User doesn't have required role
        """
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required roles: {', '.join(self.allowed_roles)}"
            )
        return True


class PermissionChecker:
    """
    Dependency class for permission-based access control
    
    Usage:
        @app.post("/create-employee")
        async def create_employee(
            current_user: CurrentUser = Depends(get_current_user),
            _: bool = Depends(PermissionChecker(["employees:create"]))
        ):
            return {"message": "Employee created"}
    """
    
    def __init__(
        self,
        required_permissions: List[str],
        require_all: bool = True
    ):
        """
        Args:
            required_permissions: List of permissions to check
            require_all: If True, user must have ALL permissions. If False, ANY permission is sufficient.
        """
        self.required_permissions = required_permissions
        self.require_all = require_all
    
    def __call__(self, current_user: CurrentUser = Depends(get_current_user)) -> bool:
        """
        Check if current user has required permissions
        
        Raises:
            HTTP 403: User doesn't have required permissions
        """
        if self.require_all:
            has_access = current_user.has_all_permissions(self.required_permissions)
        else:
            has_access = current_user.has_any_permission(self.required_permissions)
        
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required: {', '.join(self.required_permissions)}"
            )
        return True


class CompanyAccessChecker:
    """
    Dependency to check if user has access to specific company
    
    Usage:
        @app.get("/companies/{company_id}/employees")
        async def get_employees(
            company_id: str,
            current_user: CurrentUser = Depends(get_current_user),
            _: bool = Depends(CompanyAccessChecker())
        ):
            return {"company_id": company_id}
    """
    
    def __init__(self, allow_super_admin: bool = True):
        self.allow_super_admin = allow_super_admin
    
    def __call__(
        self,
        company_id: str,
        current_user: CurrentUser = Depends(get_current_user)
    ) -> bool:
        """
        Check if user can access specified company
        
        Raises:
            HTTP 403: User cannot access this company
        """
        # Super admin bypass
        if self.allow_super_admin and current_user.is_super_admin():
            return True
        
        # Check if user belongs to this company
        if current_user.company_id != company_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this company"
            )
        
        return True


async def get_optional_user(
    authorization: Optional[str] = Header(None)
) -> Optional[CurrentUser]:
    """
    Dependency: Get current user if token provided, otherwise None
    Useful for endpoints that work with or without authentication
    
    Usage:
        @app.get("/public-or-private")
        async def mixed_route(current_user: Optional[CurrentUser] = Depends(get_optional_user)):
            if current_user:
                return {"message": f"Hello {current_user.name}"}
            return {"message": "Hello Guest"}
    """
    if not authorization or not authorization.startswith("Bearer "):
        return None
    
    token = authorization.replace("Bearer ", "")
    
    try:
        payload = jwt_handler.decode_token(token)
        if jwt_handler.verify_token_type(payload, "access"):
            return CurrentUser(payload)
    except Exception:
        pass
    
    return None


# Convenience role checkers
RequireSuperAdmin = RoleChecker(["super_admin"])
RequireCompanyAdmin = RoleChecker(["super_admin", "company_admin"])
RequireHRAdmin = RoleChecker(["super_admin", "company_admin", "hr_manager"])
RequireManager = RoleChecker(["super_admin", "company_admin", "hr_manager", "manager"])


# Convenience permission checkers
RequireCompanyManage = PermissionChecker(["companies:update", "companies:delete"], require_all=False)
RequireEmployeeCreate = PermissionChecker(["employees:create"])
RequireAttendanceView = PermissionChecker(["attendance:read_all", "attendance:read_team", "attendance:read_own"], require_all=False)
RequireLeaveApprove = PermissionChecker(["leaves:approve", "leaves:approve_team"], require_all=False)
