"""
Payroll & Finance Routes
Handles salary, payslips, expenses, and financial management
"""

from fastapi import APIRouter, HTTPException, status
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

router = APIRouter(prefix="/api/payroll", tags=["Payroll & Finance"])

# ==================== MODELS ====================

class PayslipGenerate(BaseModel):
    employee_id: str
    month: str
    year: int

class PayslipResponse(BaseModel):
    id: str
    employee_id: str
    month: str
    year: int
    basic_salary: float
    allowances: float
    bonuses: float
    deductions: float
    tax: float
    net_salary: float
    generated_date: datetime
    status: str

class ExpenseCreate(BaseModel):
    employee_id: str
    category: str
    description: str
    amount: float
    currency: str = "USD"
    expense_date: datetime
    receipt_url: Optional[str] = None

class ExpenseResponse(BaseModel):
    id: str
    employee_id: str
    category: str
    description: str
    amount: float
    currency: str
    expense_date: datetime
    receipt_url: Optional[str] = None
    status: str
    submitted_date: datetime

# ==================== SALARY ====================

@router.get("/salary/{employee_id}")
async def get_salary_info(employee_id: str):
    """Get employee salary information"""
    try:
        return {
            "employee_id": employee_id,
            "basic_salary": 5000.0,
            "monthly_allowances": 1000.0,
            "year_to_date_earnings": 72000.0,
            "year_to_date_tax": 14400.0,
            "payment_method": "Bank Transfer",
            "bank_account": "****1234"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== PAYSLIPS ====================

@router.post("/payslips/generate", response_model=PayslipResponse)
async def generate_payslip(request: PayslipGenerate):
    """Generate payslip for employee"""
    try:
        # TODO: Calculate salary components
        payslip_data = {
            "id": f"pay_{datetime.now().timestamp()}",
            **request.model_dump(),
            "basic_salary": 5000.0,
            "allowances": 1000.0,
            "bonuses": 500.0,
            "deductions": 200.0,
            "tax": 1100.0,
            "net_salary": 5200.0,
            "generated_date": datetime.now(),
            "status": "generated",
        }
        return PayslipResponse(**payslip_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/payslips/{employee_id}", response_model=List[PayslipResponse])
async def get_employee_payslips(employee_id: str, year: Optional[int] = None):
    """Get employee payslips"""
    try:
        # TODO: Database integration
        return []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/payslips/download/{payslip_id}")
async def download_payslip(payslip_id: str):
    """Download payslip PDF"""
    try:
        # TODO: Generate and return PDF
        return {
            "success": True,
            "download_url": f"https://storage.example.com/payslips/{payslip_id}.pdf"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== EXPENSES ====================

@router.post("/expenses", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def submit_expense(expense: ExpenseCreate):
    """Submit expense claim"""
    try:
        expense_data = {
            "id": f"exp_{datetime.now().timestamp()}",
            **expense.model_dump(),
            "status": "pending",
            "submitted_date": datetime.now(),
        }
        return ExpenseResponse(**expense_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/expenses/{employee_id}", response_model=List[ExpenseResponse])
async def get_employee_expenses(employee_id: str, status: Optional[str] = None):
    """Get employee expenses"""
    try:
        # TODO: Database integration
        return []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/expenses/{expense_id}/approve")
async def approve_expense(expense_id: str):
    """Approve expense claim"""
    try:
        # TODO: Database integration
        return {"success": True, "expense_id": expense_id, "status": "approved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/expenses/{expense_id}/reject")
async def reject_expense(expense_id: str, reason: str):
    """Reject expense claim"""
    try:
        # TODO: Database integration
        return {"success": True, "expense_id": expense_id, "status": "rejected", "reason": reason}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== BONUSES ====================

@router.post("/bonuses")
async def award_bonus(employee_id: str, amount: float, reason: str):
    """Award bonus to employee"""
    try:
        return {
            "success": True,
            "bonus_id": f"bonus_{datetime.now().timestamp()}",
            "employee_id": employee_id,
            "amount": amount,
            "reason": reason,
            "date": datetime.now()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== ANALYTICS ====================

@router.get("/analytics")
async def get_payroll_analytics(month: Optional[str] = None, year: Optional[int] = None):
    """Get payroll analytics"""
    try:
        return {
            "total_payroll": 125000.0,
            "total_employees": 25,
            "average_salary": 5000.0,
            "total_bonuses": 12500.0,
            "total_deductions": 3750.0,
            "total_tax": 27500.0,
            "pending_expenses": 15,
            "approved_expenses": 42,
            "total_expense_amount": 8500.0,
            "department_breakdown": [
                {"department": "Engineering", "total": 45000.0},
                {"department": "Sales", "total": 35000.0},
                {"department": "Marketing", "total": 25000.0},
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
