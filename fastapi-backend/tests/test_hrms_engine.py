from app.services.hrms_engine import PayrollEngine, SalaryStructure, AttendanceSummary


def test_payroll_engine_calculates_salary_and_overtime():
    structure = SalaryStructure(
        basic_salary=5000.0,
        hra=1000.0,
        allowances=500.0,
        bonus=200.0,
        incentives=100.0,
        deductions=50.0,
        pf=300.0,
        esi=100.0,
        tds=150.0,
    )
    summary = AttendanceSummary(
        present_days=20,
        absent_days=2,
        half_days=0,
        overtime_hours=4,
        working_days=22,
    )

    payroll = PayrollEngine.calculate_payroll(
        salary_structure=structure,
        attendance_summary=summary,
        overtime_rate=25.0,
        late_penalty=0.0,
        early_leave_penalty=0.0,
    )

    assert payroll.monthly_salary == 6200.0
    assert payroll.per_day_salary == 281.818182
    assert payroll.daily_earnings == 5636.363636
    assert payroll.overtime_pay == 100.0
    assert payroll.final_salary == 5736.363636
