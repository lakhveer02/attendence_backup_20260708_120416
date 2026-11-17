"""
Branch API Routes  
Company branch/office management
"""

from fastapi import APIRouter, HTTPException, status
from typing import List
import logging

from app.models.multi_tenant import (
    BranchCreate, BranchUpdate, BranchResponse
)
from app.database_multi_tenant import MultiTenantDatabase
from app.database_complete import db_complete

router = APIRouter(prefix="/api/v1/branches", tags=["Branches"])
logger = logging.getLogger(__name__)

# Initialize multi-tenant database
mt_db = MultiTenantDatabase(db_complete.client)

# ==================== CREATE BRANCH ====================

@router.post("", response_model=BranchResponse, status_code=status.HTTP_201_CREATED)
async def create_branch(request: BranchCreate):
    """
    Create new branch/office location
    """
    try:
        branch_data = request.dict()
        branch = await mt_db.create_branch(branch_data)
        
        logger.info(f"✅ Branch created: {branch['name']} for company {request.company_id}")
        
        return BranchResponse(**branch)
        
    except Exception as e:
        logger.error(f"❌ Error creating branch: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# ==================== GET COMPANY BRANCHES ====================

@router.get("/company/{company_id}", response_model=List[BranchResponse])
async def get_company_branches(company_id: str):
    """
    Get all branches for a company
    """
    try:
        branches = await mt_db.get_company_branches(company_id)
        return [BranchResponse(**branch) for branch in branches]
        
    except Exception as e:
        logger.error(f"❌ Error getting company branches: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# ==================== GET BRANCH DETAILS ====================

@router.get("/{branch_id}", response_model=BranchResponse)
async def get_branch(branch_id: str):
    """
    Get branch details by ID
    """
    try:
        response = db_complete.client.table("branches")\
            .select("*, profiles!manager_id(full_name)")\
            .eq("id", branch_id)\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Branch not found"
            )
        
        branch = response.data[0]
        
        # Flatten manager data
        if branch.get('profiles'):
            branch['manager_name'] = branch['profiles']['full_name']
            del branch['profiles']
        
        # Get employee count
        emp_response = db_complete.client.table("profiles")\
            .select("id", count="exact")\
            .eq("company_id", branch["company_id"])\
            .execute()
        branch['employee_count'] = emp_response.count if emp_response.count else 0
        
        return BranchResponse(**branch)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting branch: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# ==================== UPDATE BRANCH ====================

@router.put("/{branch_id}", response_model=BranchResponse)
async def update_branch(branch_id: str, request: BranchUpdate):
    """
    Update branch details
    """
    try:
        # Get current branch
        current_response = db_complete.client.table("branches")\
            .select("*")\
            .eq("id", branch_id)\
            .execute()
        
        if not current_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Branch not found"
            )
        
        # Update only provided fields
        updates = request.dict(exclude_unset=True)
        
        if not updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        branch = await mt_db.update_branch(branch_id, updates)
        
        logger.info(f"✅ Branch updated: {branch_id}")
        
        # Fetch full details
        return await get_branch(branch_id)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating branch: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# ==================== DELETE BRANCH ====================

@router.delete("/{branch_id}")
async def delete_branch(branch_id: str):
    """
    Delete (deactivate) branch
    """
    try:
        db_complete.client.table("branches").update({
            "is_active": False
        }).eq("id", branch_id).execute()
        
        logger.info(f"✅ Branch deactivated: {branch_id}")
        
        return {
            "success": True,
            "message": "Branch deactivated successfully"
        }
        
    except Exception as e:
        logger.error(f"❌ Error deleting branch: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# ==================== GET BRANCH EMPLOYEES ====================

@router.get("/{branch_id}/employees")
async def get_branch_employees(branch_id: str):
    """
    Get all employees in a branch
    """
    try:
        # Get branch to get company_id
        branch_response = db_complete.client.table("branches")\
            .select("company_id")\
            .eq("id", branch_id)\
            .execute()
        
        if not branch_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Branch not found"
            )
        
        company_id = branch_response.data[0]["company_id"]
        
        # Get all employees for this company
        # TODO: Add branch filtering when employees are assigned to branches
        employees_response = db_complete.client.table("profiles")\
            .select("*")\
            .eq("company_id", company_id)\
            .eq("is_active", True)\
            .execute()
        
        return {
            "branch_id": branch_id,
            "employees": employees_response.data if employees_response.data else [],
            "total_count": len(employees_response.data) if employees_response.data else 0
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting branch employees: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
