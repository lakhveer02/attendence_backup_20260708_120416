from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, Field
from typing import Optional
import logging
import math

from app.services.hrms_engine import AttendanceSummary, PayrollEngine, SalaryStructure
from app.auth.dependencies import get_current_user, CurrentUser
from app.database_complete import db_complete as db

router = APIRouter(prefix="/api/v1/hrms", tags=["HRMS"])
logger = logging.getLogger(__name__)


class GPSLocation(BaseModel):
    """GPS coordinates"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: Optional[float] = None


class CheckInRequest(BaseModel):
    """Attendance check-in request with GPS verification"""
    check_in_gps: GPSLocation
    verification_method: str = Field(..., description="biometric, face, manual")
    device_id: Optional[str] = None
    device_model: Optional[str] = None
    device_os: Optional[str] = None
    is_wfh: bool = False
    wfh_reason: Optional[str] = None
    notes: Optional[str] = None


class CheckOutRequest(BaseModel):
    """Attendance check-out request"""
    attendance_id: str
    check_out_gps: GPSLocation
    notes: Optional[str] = None


class PayrollRequest(BaseModel):
    basic_salary: float
    hra: float = 0.0
    allowances: float = 0.0
    bonus: float = 0.0
    incentives: float = 0.0
    deductions: float = 0.0
    pf: float = 0.0
    esi: float = 0.0
    tds: float = 0.0
    other_deductions: float = 0.0
    present_days: int = 0
    absent_days: int = 0
    half_days: int = 0
    overtime_hours: float = 0.0
    working_days: int = 22
    overtime_rate: float = 25.0
    late_penalty: float = 0.0
    early_leave_penalty: float = 0.0


class PayrollResponse(BaseModel):
    monthly_salary: float
    per_day_salary: float
    daily_earnings: float
    overtime_pay: float
    final_salary: float
    half_day_salary: float
    late_penalty: float
    early_leave_penalty: float


def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two GPS coordinates using Haversine formula
    Returns distance in meters
    """
    R = 6371000  # Earth radius in meters
    
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = (math.sin(delta_phi / 2) ** 2 +
         math.cos(phi1) * math.cos(phi2) *
         math.sin(delta_lambda / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


@router.post("/attendance/checkin")
async def check_in_attendance(
    request: CheckInRequest,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Check-in attendance with dynamic geofencing validation
    
    BUG FIX: Dynamically queries company location from database
    instead of using hardcoded coordinates
    """
    try:
        # BUG FIX #2: Get company location dynamically from database
        if not current_user.company_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User does not belong to a company"
            )
        
        # Fetch company details including office location
        company_result = await db.execute_query(
            """
            SELECT 
                id,
                name,
                office_latitude,
                office_longitude,
                geofence_radius_meters
            FROM companies
            WHERE id = $1 AND status = 'active'
            """,
            current_user.company_id
        )
        
        if not company_result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found or inactive"
            )
        
        company = company_result[0]
        
        # Validate geofencing if not WFH
        distance_from_office = None
        is_within_geofence = True
        
        if not request.is_wfh:
            if company['office_latitude'] and company['office_longitude']:
                # Calculate distance from office
                distance_from_office = calculate_distance(
                    company['office_latitude'],
                    company['office_longitude'],
                    request.check_in_gps.latitude,
                    request.check_in_gps.longitude
                )
                
                # Check geofence (default 100 meters if not set)
                geofence_radius = company['geofence_radius_meters'] or 100
                is_within_geofence = distance_from_office <= geofence_radius
                
                logger.info(
                    f"📍 Geofence check: Distance={distance_from_office:.2f}m, "
                    f"Radius={geofence_radius}m, "
                    f"Within={is_within_geofence}"
                )
                
                if not is_within_geofence:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Check-in location is {distance_from_office:.0f}m from office. "
                               f"Must be within {geofence_radius}m. Enable WFH if working remotely."
                    )
            else:
                logger.warning("⚠️ Company office location not configured")
        
        # Create attendance record
        from datetime import datetime
        
        attendance_data = {
            "company_id": current_user.company_id,
            "profile_id": current_user.profile_id,
            "check_in": datetime.utcnow(),
            "status": "present",
            "check_in_gps": {
                "latitude": request.check_in_gps.latitude,
                "longitude": request.check_in_gps.longitude,
                "accuracy": request.check_in_gps.accuracy
            },
            "distance_from_office": distance_from_office,
            "is_wfh": request.is_wfh,
            "verification_method": request.verification_method,
            "device_id": request.device_id,
            "device_model": request.device_model,
            "device_os": request.device_os,
            "notes": request.notes or request.wfh_reason
        }
        
        # Insert into database
        result = await db.execute_query(
            """
            INSERT INTO attendance (
                company_id, profile_id, check_in, status,
                check_in_gps, distance_from_office, is_wfh,
                verification_method, device_id, notes
            )
            VALUES ($1, $2, $3, $4, $5::jsonb, $6, $7, $8, $9, $10)
            RETURNING id, check_in, status
            """,
            attendance_data['company_id'],
            attendance_data['profile_id'],
            attendance_data['check_in'],
            attendance_data['status'],
            str(attendance_data['check_in_gps']).replace("'", '"'),
            attendance_data['distance_from_office'],
            attendance_data['is_wfh'],
            attendance_data['verification_method'],
            attendance_data['device_id'],
            attendance_data['notes']
        )
        
        logger.info(
            f"✅ Check-in successful: {current_user.email} at {company['name']}"
        )
        
        return {
            "success": True,
            "message": "Check-in successful",
            "attendance_id": str(result[0]['id']),
            "check_in_time": result[0]['check_in'],
            "status": result[0]['status'],
            "distance_from_office": distance_from_office,
            "is_wfh": request.is_wfh,
            "company_name": company['name']
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Check-in failed: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check in: {str(e)}"
        )


@router.post("/attendance/checkout")
async def check_out_attendance(
    request: CheckOutRequest,
    current_user: CurrentUser = Depends(get_current_user)
):
    """
    Check-out attendance
    """
    try:
        from datetime import datetime
        
        # Update attendance record
        result = await db.execute_query(
            """
            UPDATE attendance
            SET 
                check_out = $1,
                check_out_gps = $2::jsonb,
                total_hours = EXTRACT(EPOCH FROM ($1 - check_in)) / 3600,
                updated_at = NOW()
            WHERE id = $3 AND profile_id = $4
            RETURNING id, check_in, check_out, total_hours, status
            """,
            datetime.utcnow(),
            str({
                "latitude": request.check_out_gps.latitude,
                "longitude": request.check_out_gps.longitude,
                "accuracy": request.check_out_gps.accuracy
            }).replace("'", '"'),
            request.attendance_id,
            current_user.profile_id
        )
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Attendance record not found or unauthorized"
            )
        
        logger.info(f"✅ Check-out successful: {current_user.email}")
        
        return {
            "success": True,
            "message": "Check-out successful",
            "attendance_id": str(result[0]['id']),
            "check_in_time": result[0]['check_in'],
            "check_out_time": result[0]['check_out'],
            "total_hours": float(result[0]['total_hours']),
            "status": result[0]['status']
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Check-out failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check out: {str(e)}"
        )


@router.post("/payroll/calculate", response_model=PayrollResponse)
async def calculate_payroll(payload: PayrollRequest):
    try:
        salary_structure = SalaryStructure(
            basic_salary=payload.basic_salary,
            hra=payload.hra,
            allowances=payload.allowances,
            bonus=payload.bonus,
            incentives=payload.incentives,
            deductions=payload.deductions,
            pf=payload.pf,
            esi=payload.esi,
            tds=payload.tds,
            other_deductions=payload.other_deductions,
        )
        attendance_summary = AttendanceSummary(
            present_days=payload.present_days,
            absent_days=payload.absent_days,
            half_days=payload.half_days,
            overtime_hours=payload.overtime_hours,
            working_days=payload.working_days,
        )
        result = PayrollEngine.calculate_payroll(
            salary_structure=salary_structure,
            attendance_summary=attendance_summary,
            overtime_rate=payload.overtime_rate,
            late_penalty=payload.late_penalty,
            early_leave_penalty=payload.early_leave_penalty,
        )
        return PayrollResponse(**result.__dict__)
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc)) from exc
