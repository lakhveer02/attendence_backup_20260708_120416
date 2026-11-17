from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass
class SalaryStructure:
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

    @property
    def monthly_salary(self) -> float:
        return (
            self.basic_salary
            + self.hra
            + self.allowances
            + self.bonus
            + self.incentives
            - self.pf
            - self.esi
            - self.tds
            - self.deductions
            - self.other_deductions
        )


@dataclass
class AttendanceSummary:
    present_days: int = 0
    absent_days: int = 0
    half_days: int = 0
    overtime_hours: float = 0.0
    working_days: int = 22


@dataclass
class PayrollResult:
    monthly_salary: float
    per_day_salary: float
    daily_earnings: float
    overtime_pay: float
    final_salary: float
    half_day_salary: float
    late_penalty: float
    early_leave_penalty: float


class PayrollEngine:
    @staticmethod
    def calculate_payroll(
        salary_structure: SalaryStructure,
        attendance_summary: AttendanceSummary,
        overtime_rate: float = 25.0,
        late_penalty: float = 0.0,
        early_leave_penalty: float = 0.0,
    ) -> PayrollResult:
        monthly_salary = salary_structure.monthly_salary
        per_day_salary = monthly_salary / attendance_summary.working_days if attendance_summary.working_days else 0.0
        daily_earnings = per_day_salary * attendance_summary.present_days
        half_day_salary = per_day_salary * 0.5 * attendance_summary.half_days
        overtime_pay = attendance_summary.overtime_hours * overtime_rate
        final_salary = daily_earnings + half_day_salary + overtime_pay - late_penalty - early_leave_penalty

        return PayrollResult(
            monthly_salary=round(monthly_salary, 2),
            per_day_salary=round(per_day_salary, 6),
            daily_earnings=round(daily_earnings, 6),
            overtime_pay=round(overtime_pay, 2),
            final_salary=round(final_salary, 6),
            half_day_salary=round(half_day_salary, 2),
            late_penalty=round(late_penalty, 2),
            early_leave_penalty=round(early_leave_penalty, 2),
        )
