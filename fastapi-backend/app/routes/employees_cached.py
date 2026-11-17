"""
Example: Employee Routes with Redis Caching
This shows how to integrate cache service into existing endpoints
"""

from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Optional
import logging

from ..database_complete import db_complete as db
from ..services.cache_service import get_cache_service, CacheService
from ..auth.dependencies import get_current_user, CurrentUser

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/employees", tags=["Employees (Cached)"])


@router.get("/{employee_id}")
async def get_employee_cached(
    employee_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    cache: CacheService = Depends(get_cache_service)
):
    """
    Get employee by ID with caching
    
    Cache Strategy:
    - TTL: 1 hour
    - Invalidation: On employee update
    - Key: employee:{company_id}:{employee_id}
    """
    try:
        company_id = current_user.company_id
        
        # Step 1: Try cache first
        cached_employee = await cache.get_employee(company_id, employee_id)
        
        if cached_employee:
            logger.info(f"✅ Cache HIT: employee:{company_id}:{employee_id}")
            return {
                "success": True,
                "data": cached_employee,
                "cached": True
            }
        
        # Step 2: Cache miss - fetch from database
        logger.info(f"❌ Cache MISS: employee:{company_id}:{employee_id}")
        
        employee = await db.get_profile(employee_id)
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        # Verify employee belongs to user's company
        if employee.get('company_id') != company_id and current_user.role != 'super_admin':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        # Step 3: Store in cache for next time
        await cache.set_employee(company_id, employee_id, employee)
        
        return {
            "success": True,
            "data": employee,
            "cached": False
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting employee: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.put("/{employee_id}")
async def update_employee_cached(
    employee_id: str,
    updates: dict,
    current_user: CurrentUser = Depends(get_current_user),
    cache: CacheService = Depends(get_cache_service)
):
    """
    Update employee and invalidate cache
    
    Cache Strategy:
    - Invalidate cache after update
    - Ensures users always get fresh data after changes
    """
    try:
        company_id = current_user.company_id
        
        # Check permissions
        if current_user.role not in ['super_admin', 'company_admin', 'hr_manager']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        
        # Update in database
        updated_employee = await db.update_profile(employee_id, updates)
        
        # Invalidate cache
        await cache.invalidate_employee(company_id, employee_id)
        logger.info(f"🗑️ Cache invalidated: employee:{company_id}:{employee_id}")
        
        return {
            "success": True,
            "message": "Employee updated successfully",
            "data": updated_employee
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating employee: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/attendance/today/{employee_id}")
async def get_today_attendance_cached(
    employee_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    cache: CacheService = Depends(get_cache_service)
):
    """
    Get today's attendance with short-lived cache
    
    Cache Strategy:
    - TTL: 5 minutes (real-time data needs frequent updates)
    - Key: attendance:today:{company_id}:{employee_id}
    """
    try:
        company_id = current_user.company_id
        
        # Try cache (5 min TTL for near real-time)
        cached_attendance = await cache.get_today_attendance(company_id, employee_id)
        
        if cached_attendance:
            logger.info(f"✅ Cache HIT: attendance:today:{company_id}:{employee_id}")
            return {
                "success": True,
                "data": cached_attendance,
                "cached": True
            }
        
        # Fetch from database
        logger.info(f"❌ Cache MISS: attendance:today:{company_id}:{employee_id}")
        
        attendance = await db.get_todays_attendance(employee_id)
        
        # Store in cache (even if None, to prevent repeated DB queries)
        if attendance:
            await cache.set_today_attendance(company_id, employee_id, attendance)
        
        return {
            "success": True,
            "data": attendance,
            "cached": False
        }
        
    except Exception as e:
        logger.error(f"Error getting today's attendance: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/company/settings")
async def get_company_settings_cached(
    current_user: CurrentUser = Depends(get_current_user),
    cache: CacheService = Depends(get_cache_service)
):
    """
    Get company settings with long cache
    
    Cache Strategy:
    - TTL: 6 hours (settings don't change often)
    - Key: company:settings:{company_id}
    """
    try:
        company_id = current_user.company_id
        
        # Try cache
        cached_settings = await cache.get_company_settings(company_id)
        
        if cached_settings:
            logger.info(f"✅ Cache HIT: company:settings:{company_id}")
            return {
                "success": True,
                "data": cached_settings,
                "cached": True
            }
        
        # Fetch from database
        logger.info(f"❌ Cache MISS: company:settings:{company_id}")
        
        company = await db.get_company(company_id)
        
        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found"
            )
        
        settings = company.get('settings', {})
        
        # Cache for 6 hours
        await cache.set_company_settings(company_id, settings)
        
        return {
            "success": True,
            "data": settings,
            "cached": False
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting company settings: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# Cache monitoring endpoint
@router.get("/cache/stats")
async def get_cache_stats(
    current_user: CurrentUser = Depends(get_current_user),
    cache: CacheService = Depends(get_cache_service)
):
    """
    Get cache statistics
    Only accessible to admins
    """
    if current_user.role not in ['super_admin', 'company_admin']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        # Get Redis info
        info = await cache.redis.info()
        
        return {
            "success": True,
            "stats": {
                "connected_clients": info.get("connected_clients", 0),
                "used_memory_human": info.get("used_memory_human", "0"),
                "total_commands_processed": info.get("total_commands_processed", 0),
                "keyspace_hits": info.get("keyspace_hits", 0),
                "keyspace_misses": info.get("keyspace_misses", 0),
                "hit_rate": calculate_hit_rate(
                    info.get("keyspace_hits", 0),
                    info.get("keyspace_misses", 0)
                )
            }
        }
    except Exception as e:
        logger.error(f"Error getting cache stats: {e}")
        return {
            "success": False,
            "error": "Cache not available",
            "message": str(e)
        }


def calculate_hit_rate(hits: int, misses: int) -> float:
    """Calculate cache hit rate percentage"""
    total = hits + misses
    if total == 0:
        return 0.0
    return round((hits / total) * 100, 2)
