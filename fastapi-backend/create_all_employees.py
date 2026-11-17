#!/usr/bin/env python3
"""
Create All Employees for Company Testing
Creates the complete employee roster with proper hierarchy
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv
from datetime import datetime
import uuid
import random
import string

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", os.getenv("SUPABASE_ANON_KEY"))

# Employee Data Based on Provided List
EMPLOYEES = [
    # CEO
    {
        "full_name": "Chanten Batra",
        "email": "chanten.batra@company.com",
        "role": "company_admin",
        "designation": "Chief Executive Officer",
        "phone_number": "+91-9876543201",
        "password": "Ceo@1234"
    },
    
    # HR Team
    {
        "full_name": "Deepak Batra",
        "email": "deepak.batra@company.com",
        "role": "hr_manager",
        "designation": "HR Manager",
        "phone_number": "+91-9876543202",
        "password": "Hr@1234"
    },
    {
        "full_name": "Paryanshi",
        "email": "paryanshi@company.com",
        "role": "hr_manager",
        "designation": "HR Executive",
        "phone_number": "+91-9876543203",
        "password": "Hr@1234"
    },
    
    # Team Manager
    {
        "full_name": "Dev Gangwar",
        "email": "dev.gangwar@company.com",
        "role": "manager",
        "designation": "Team Manager",
        "phone_number": "+91-9876543204",
        "password": "Manager@1234"
    },
    
    # Developers - From the provided list
    {
        "full_name": "Gurmeet Singh",
        "email": "gurmeet.singh@company.com",
        "role": "employee",
        "designation": "Web Developer",
        "phone_number": "+91-9876543210",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    },
    {
        "full_name": "Abha Sharma",
        "email": "abha.sharma@company.com",
        "role": "employee",
        "designation": "React Developer",
        "phone_number": "+91-9876543211",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    },
    {
        "full_name": "Harman Preet",
        "email": "harman.preet@company.com",
        "role": "employee",
        "designation": "React Developer",
        "phone_number": "+91-9876543212",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    },
    {
        "full_name": "Manjinder Singh",
        "email": "manjinder.singh@company.com",
        "role": "employee",
        "designation": "Software Developer",
        "phone_number": "+91-9876543213",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    },
    {
        "full_name": "Lakhveer Singh",
        "email": "lakhveer.singh@company.com",
        "role": "employee",
        "designation": "Mobile Application Developer",
        "phone_number": "+91-9876543214",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    },
    {
        "full_name": "Himanshu Rana",
        "email": "himanshu.rana@company.com",
        "role": "employee",
        "designation": "React Native Developer",
        "phone_number": "+91-9876543215",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    },
    {
        "full_name": "Akwinder Kaur",
        "email": "akwinder.kaur@company.com",
        "role": "employee",
        "designation": "Ex Intern (Web Development)",
        "phone_number": "+91-9876543216",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    },
    {
        "full_name": "Prince Thakur",
        "email": "prince.thakur@company.com",
        "role": "employee",
        "designation": "React Native Developer",
        "phone_number": "+91-9876543217",
        "location": "India, Maharashtra, Mane Mohali",
        "password": "Dev@1234"
    }
]


def create_company(supabase, company_name="Squad Tech Solutions"):
    """Create or get the main company"""
    print(f"🏢 Setting up company: {company_name}")
    
    # Check if company exists
    existing = supabase.table('companies').select('*').eq('name', company_name).execute()
    
    if existing.data and len(existing.data) > 0:
        company = existing.data[0]
        print(f"✅ Company already exists: {company['id']}")
        return company
    
    # Generate workspace slug
    workspace_slug = company_name.lower().replace(' ', '-')
    
    # Generate joining token
    joining_token = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    
    # Create company
    company_data = {
        'name': company_name,
        'status': 'active',
        'timezone': 'Asia/Kolkata',
    }
    
    result = supabase.table('companies').insert(company_data).execute()
    
    if result.data and len(result.data) > 0:
        company = result.data[0]
        print(f"✅ Company created: {company['id']}")
        print(f"   Workspace: {workspace_slug}")
        print(f"   Token: {joining_token}")
        return company
    
    raise Exception("Failed to create company")


def create_department(supabase, company_id, dept_name, manager_id=None):
    """Create or get a department"""
    print(f"📁 Setting up department: {dept_name}")
    
    # Check if department exists
    existing = supabase.table('departments').select('*').eq('company_id', company_id).eq('name', dept_name).execute()
    
    if existing.data and len(existing.data) > 0:
        dept = existing.data[0]
        print(f"✅ Department already exists: {dept['id']}")
        return dept
    
    # Create department
    dept_data = {
        'company_id': company_id,
        'workspace_id': company_id,  # Use company_id as workspace_id
        'name': dept_name,
    }
    
    if manager_id:
        dept_data['manager_id'] = manager_id
    
    result = supabase.table('departments').insert(dept_data).execute()
    
    if result.data and len(result.data) > 0:
        dept = result.data[0]
        print(f"✅ Department created: {dept['id']}")
        return dept
    
    raise Exception(f"Failed to create department: {dept_name}")


def create_employee(supabase, company_id, employee_data, department_id=None):
    """Create an employee with Supabase Auth and Profile"""
    email = employee_data['email']
    print(f"👤 Creating employee: {employee_data['full_name']} ({email})")
    
    try:
        # Check if user already exists in profiles
        existing_profile = supabase.table('profiles').select('*').eq('email', email).execute()
        
        if existing_profile.data and len(existing_profile.data) > 0:
            print(f"⚠️  Employee already exists: {email}")
            return existing_profile.data[0]
        
        # Create Supabase Auth user
        auth_response = supabase.auth.admin.create_user({
            "email": email,
            "password": employee_data['password'],
            "email_confirm": True,
            "user_metadata": {
                "full_name": employee_data['full_name'],
                "role": employee_data['role']
            }
        })
        
        if not auth_response.user:
            raise Exception(f"Failed to create auth user for {email}")
        
        auth_user_id = auth_response.user.id
        print(f"   ✅ Auth user created: {auth_user_id}")
        
        # Create profile record
        profile_data = {
            "id": auth_user_id,
            "company_id": company_id,
            "workspace_id": company_id,
            "email": email,
            "full_name": employee_data['full_name'],
            "role": employee_data['role'],
            "phone_number": employee_data.get('phone_number'),
            "is_active": True,
        }
        
        if department_id:
            profile_data['department_id'] = department_id
        
        profile_result = supabase.table('profiles').insert(profile_data).execute()
        
        if profile_result.data and len(profile_result.data) > 0:
            profile = profile_result.data[0]
            print(f"   ✅ Profile created: {profile['id']}")
            return profile
        
        raise Exception(f"Failed to create profile for {email}")
        
    except Exception as e:
        error_msg = str(e).lower()
        
        # If user already exists in auth, try to get their profile
        if "already" in error_msg or "exists" in error_msg or "duplicate" in error_msg:
            print(f"   ⚠️  User already exists in auth, checking profile...")
            existing = supabase.table('profiles').select('*').eq('email', email).execute()
            if existing.data and len(existing.data) > 0:
                print(f"   ✅ Found existing profile")
                return existing.data[0]
        
        print(f"   ❌ Error creating employee: {e}")
        return None


def main():
    """Main execution"""
    try:
        print("=" * 70)
        print("🚀 EMPLOYEE ROSTER CREATION SCRIPT")
        print("=" * 70)
        print()
        
        # Validate environment
        if not SUPABASE_URL or not SUPABASE_KEY:
            print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
            sys.exit(1)
        
        # Connect to Supabase
        print(f"📡 Connecting to Supabase...")
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Connected successfully")
        print()
        
        # Create company
        company = create_company(supabase, "Squad Tech Solutions")
        company_id = company['id']
        print()
        
        # Create departments
        print("=" * 70)
        print("Creating Departments")
        print("=" * 70)
        
        dev_dept = create_department(supabase, company_id, "Development")
        hr_dept = create_department(supabase, company_id, "Human Resources")
        mgmt_dept = create_department(supabase, company_id, "Management")
        
        print()
        
        # Create employees
        print("=" * 70)
        print("Creating Employees")
        print("=" * 70)
        print()
        
        created_employees = {}
        
        for emp_data in EMPLOYEES:
            # Determine department
            dept_id = None
            if emp_data['role'] == 'hr_manager':
                dept_id = hr_dept['id']
            elif emp_data['role'] == 'manager' or emp_data['role'] == 'company_admin':
                dept_id = mgmt_dept['id']
            else:
                dept_id = dev_dept['id']
            
            employee = create_employee(supabase, company_id, emp_data, dept_id)
            if employee:
                created_employees[emp_data['email']] = employee
            print()
        
        # Summary
        print("=" * 70)
        print("✅ EMPLOYEE ROSTER CREATION COMPLETE")
        print("=" * 70)
        print()
        print(f"📊 Summary:")
        print(f"   Company: {company['name']}")
        print(f"   Company ID: {company_id}")
        print(f"   Total Employees Created: {len(created_employees)}")
        print()
        
        print("👥 Employee Login Credentials:")
        print("-" * 70)
        print()
        
        # Group by role
        roles = {
            'company_admin': 'CEO / Company Admin',
            'hr_manager': 'HR Managers',
            'manager': 'Team Managers',
            'employee': 'Developers'
        }
        
        for role_key, role_label in roles.items():
            role_employees = [emp for emp in EMPLOYEES if emp['role'] == role_key]
            if role_employees:
                print(f"📌 {role_label}:")
                for emp in role_employees:
                    print(f"   • {emp['full_name']}")
                    print(f"     Email: {emp['email']}")
                    print(f"     Password: {emp['password']}")
                    print(f"     Role: {emp['role']}")
                    print(f"     Designation: {emp['designation']}")
                    print()
        
        print("=" * 70)
        print("🎯 NEXT STEPS:")
        print("=" * 70)
        print()
        print("1. Open your Flutter app")
        print("2. Go to Login screen")
        print("3. Use any of the credentials above")
        print(f"4. Company ID: {company_id}")
        print()
        print("✅ All employees are ready for testing!")
        print()
        
    except Exception as e:
        print(f"❌ Fatal Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
