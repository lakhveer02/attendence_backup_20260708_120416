"""
Workspace API Routes
Multi-tenant workspace management endpoints
"""

from fastapi import APIRouter, HTTPException, status, Depends
from typing import List, Optional
import secrets
import logging

from app.models.multi_tenant import (
    WorkspaceCreate, WorkspaceResponse, UserWorkspaceResponse,
    WorkspaceSwitchRequest, SlugCheckResponse
)
from app.database_multi_tenant import MultiTenantDatabase
from app.database_complete import db_complete

router = APIRouter(prefix="/api/v1/workspace", tags=["Workspace"])
logger = logging.getLogger(__name__)

# Initialize multi-tenant database
mt_db = MultiTenantDatabase(db_complete.client)

# ==================== WORKSPACE CREATION ====================

@router.post("/create", response_model=WorkspaceResponse, status_code=status.HTTP_201_CREATED)
async def create_workspace(request: WorkspaceCreate):
    """
    Create new company workspace (like creating a Slack workspace)
    
    This endpoint creates:
    1. A new company record
    2. An owner profile in Supabase Auth
    3. A profile record linked to the company
    4. A workspace membership record
    """
    try:
        logger.info(f"🏢 Creating workspace: {request.name} (slug: {request.slug})")
        
        # Check slug availability
        slug_available = await mt_db.check_slug_availability(request.slug)
        if not slug_available:
            logger.warning(f"⚠️ Slug already taken: {request.slug}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Workspace slug '{request.slug}' is already taken"
            )
        
        # Check if owner email already exists
        from app.database_complete import db_complete
        existing_profile = await db_complete.get_profile_by_email(request.owner_email)
        if existing_profile:
            logger.warning(f"⚠️ Email already registered: {request.owner_email}")
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )
        
        # Create company workspace
        workspace_data = {
            "name": request.name,
            "slug": request.slug,
            "industry": request.industry,
            "size": request.size,
            "website": request.website,
            "logo_url": request.logo_url,
            "address": request.address,
            "city": request.city,
            "country": request.country,
            "timezone": request.timezone,
            "office_latitude": request.office_latitude,
            "office_longitude": request.office_longitude,
        }
        
        company = await mt_db.create_workspace(workspace_data)
        logger.info(f"✅ Company created: {company['id']}")
        
        # Create owner in Supabase Auth
        try:
            auth_response = db_complete.client.auth.admin.create_user({
                "email": request.owner_email,
                "password": request.owner_password,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": request.owner_full_name,
                    "role": "company_admin"
                }
            })
            
            if not auth_response.user:
                raise Exception("Failed to create auth user")
            
            auth_user_id = auth_response.user.id
            logger.info(f"✅ Auth user created: {auth_user_id}")
            
        except Exception as auth_error:
            # Rollback company creation
            logger.error(f"❌ Auth creation failed, rolling back company: {auth_error}")
            try:
                db_complete.client.table("companies").delete().eq("id", company["id"]).execute()
            except:
                pass
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create authentication user: {str(auth_error)}"
            )
        
        # Create owner profile
        owner_data = {
            "id": auth_user_id,
            "company_id": company["id"],
            "workspace_id": company["id"],
            "email": request.owner_email,
            "full_name": request.owner_full_name,
            "role": "company_admin",
            "is_active": True,
        }
        
        try:
            owner = await db_complete.create_profile(owner_data)
            logger.info(f"✅ Owner profile created: {owner['id']}")
        except Exception as profile_error:
            # Rollback company and auth user
            logger.error(f"❌ Profile creation failed, rolling back: {profile_error}")
            try:
                db_complete.client.auth.admin.delete_user(auth_user_id)
                db_complete.client.table("companies").delete().eq("id", company["id"]).execute()
            except:
                pass
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create owner profile: {str(profile_error)}"
            )
        
        logger.info(f"✅ Workspace created successfully: {company['name']}")
        
        return WorkspaceResponse(**company)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error creating workspace: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/check-slug", response_model=SlugCheckResponse)
async def check_slug_availability(slug: str):
    """
    Check if workspace slug is available
    """
    try:
        available = await mt_db.check_slug_availability(slug)
        
        response = SlugCheckResponse(
            available=available,
            slug=slug
        )
        
        if not available:
            # Suggest alternative
            suggestion = f"{slug}-{secrets.token_hex(2)}"
            response.suggestion = suggestion
        
        return response
        
    except Exception as e:
        logger.error(f"❌ Error checking slug: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# ==================== USER WORKSPACES ====================

@router.get("/user/{user_id}/workspaces", response_model=List[UserWorkspaceResponse])
async def get_user_workspaces(user_id: str):
    """
    Get all workspaces user belongs to (like Slack workspace list)
    """
    try:
        workspaces = await mt_db.get_user_workspaces(user_id)
        return [UserWorkspaceResponse(**w) for w in workspaces]
        
    except Exception as e:
        logger.error(f"❌ Error getting user workspaces: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/switch")
async def switch_workspace(request: WorkspaceSwitchRequest, user_id: str):
    """
    Switch user's active workspace
    """
    try:
        success = await mt_db.switch_workspace(user_id, request.company_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to switch workspace"
            )
        
        return {
            "success": True,
            "message": "Workspace switched successfully",
            "active_company_id": request.company_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error switching workspace: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{company_id}/details", response_model=WorkspaceResponse)
async def get_workspace_details(company_id: str):
    """
    Get workspace details
    """
    try:
        company = await db_complete.get_company(company_id)
        
        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workspace not found"
            )
        
        return WorkspaceResponse(**company)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting workspace details: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/{company_id}/leave")
async def leave_workspace(company_id: str, user_id: str):
    """
    Leave a workspace (remove user from company)
    """
    try:
        # Check if user is owner
        workspaces = await mt_db.get_user_workspaces(user_id)
        current_workspace = next((w for w in workspaces if w["company_id"] == company_id), None)
        
        if not current_workspace:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="You are not a member of this workspace"
            )
        
        if current_workspace.get("is_owner"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Workspace owner cannot leave. Transfer ownership first."
            )
        
        # Remove from workspace
        db_complete.client.table("user_workspaces").delete()\
            .eq("user_id", user_id)\
            .eq("company_id", company_id)\
            .execute()
        
        logger.info(f"✅ User {user_id} left workspace {company_id}")
        
        return {
            "success": True,
            "message": "You have left the workspace"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error leaving workspace: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
