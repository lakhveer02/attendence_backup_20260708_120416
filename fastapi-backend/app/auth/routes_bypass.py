"""
Authentication routes that BYPASS Supabase REST API RLS
Uses Auth Admin API only - guaranteed to work
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr
from typing import Optional
import logging

from ..database_bypass_rls import db_bypass

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/auth-bypass", tags=["Authentication (RLS Bypass)"])


class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    role: str = "employee"
    create_company: bool = False
    company_name: Optional[str] = None
    company_id: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_id: str = "web-browser"
    device_name: Optional[str] = None


class AuthResponse(BaseModel):
    success: bool
    message: str
    user: dict
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def signup_bypass(request: SignupRequest):
    """
    Signup endpoint that BYPASSES Supabase REST API RLS
    Uses Auth Admin API only - always works
    """
    try:
        logger.info(f"📥 Bypass Signup request: {request.email}, role={request.role}")
        
        # Check if user already exists
        existing_user = await db_bypass.get_profile_by_email(request.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Create user
        if request.create_company and request.company_name:
            # Create company admin with new company
            result = await db_bypass.create_user_with_company(
                email=request.email,
                password=request.password,
                full_name=request.full_name,
                role=request.role,
                company_name=request.company_name
            )
        elif request.company_id:
            # Create employee for existing company
            result = await db_bypass.create_employee(
                email=request.email,
                password=request.password,
                full_name=request.full_name,
                role=request.role,
                company_id=request.company_id
            )
        else:
            # Create standalone user (will need company later)
            result = await db_bypass.create_user_with_company(
                email=request.email,
                password=request.password,
                full_name=request.full_name,
                role=request.role,
                company_name=f"{request.full_name}'s Company"
            )
        
        logger.info(f"✅ Bypass Signup successful: {request.email}")
        
        return AuthResponse(
            success=True,
            message="Account created successfully",
            user={
                "id": result["user_id"],
                "email": request.email,
                "full_name": request.full_name,
                "role": request.role,
                "company_id": result.get("company_id")
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Bypass Signup error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/login", response_model=AuthResponse)
async def login_bypass(request: LoginRequest):
    """
    Login endpoint that BYPASSES Supabase REST API RLS
    Uses Auth API only - always works
    """
    try:
        logger.info(f"📥 Bypass Login request: {request.email}")
        
        # Authenticate using Auth API
        user_data = await db_bypass.authenticate_user(request.email, request.password)
        
        logger.info(f"✅ Bypass Login successful: {request.email}")
        
        return AuthResponse(
            success=True,
            message="Login successful",
            user={
                "id": user_data["id"],
                "email": user_data["email"],
                "full_name": user_data["full_name"],
                "role": user_data["role"],
                "company_id": user_data.get("company_id")
            },
            access_token=user_data.get("access_token"),
            refresh_token=user_data.get("refresh_token")
        )
        
    except Exception as e:
        logger.error(f"❌ Bypass Login error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )


@router.get("/me")
async def get_current_user_bypass(user_id: str):
    """
    Get current user using Auth Admin API - bypasses RLS
    """
    try:
        user = await db_bypass.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return {
            "success": True,
            "user": user
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
