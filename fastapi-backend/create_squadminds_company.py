"""
Create SQUADMINDS PRIVATE LIMITED Company and All Employees
This script creates the company profile and all employee accounts
"""

import asyncio
import sys
import os
from datetime import datetime

# Add parent directory to path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database_complete import db_complete as db
from app.auth.jwt_handler import jwt_handler

# Company Information
COMPANY_DATA = {
    "name": "SQUADMINDS PRIVATE LIMITED",
    "status": "active",
    "timezone": "Asia/Kolkata"
}

# Employee Data with Organizational Structure
EMPLOYEES = [
    # CEO
    {
        "full_name": "Chantenbarta",
        "email": "chantenbarta@squadminds.com",
        "phone_number": "+91-9876543210",
        "role": "company_admin",
        "designation": "Chief Executive Officer (CEO)",
        "department": "Executive",
        "password": "Ceo@2024Squad",
        "reports_to": None  # CEO reports to no one
    },
    # HR Manager
    {
        "full_name": "Pryanshi",
        "email": "pryanshi@squadminds.com",
        "phone_number": "+91-9876543211",
        "role": "hr_manager",
        "designation": "HR Manager",
        "department": "Human Resources",
        "password": "Hr@2024Squad",
        "reports_to": "chantenbarta@squadminds.com"  # Reports to CEO
    },
    # HR Personnel
    {
        "full_name": "Deepak Batra",
        "email": "deepak.batra@squadminds.com",
        "phone_number": "+91-9876543212",
        "role": "hr_manager",
        "designation": "HR",
        "department": "Human Resources",
        "password": "Deepak@2024Squad",
        "reports_to": "pryanshi@squadminds.com"  # Reports to HR Manager
    },
    # Team Manager - BUG FIX #3: Changed role from 'team_manager' to 'manager'
    {
        "full_name": "Dev Gangwar",
        "email": "dev.gangwar@squadminds.com",
        "phone_number": "+91-9876543213",
        "role": "manager",  # FIXED: Was 'team_manager', now 'manager' for RBAC compatibility
        "designation": "Team Manager",
        "department": "Engineering",
        "password": "Dev@2024Squad",
        "reports_to": "chantenbarta@squadminds.com"  # Reports to CEO
    },
    # Development Team
    {
        "full_name": "Gurmeet Singh",
        "email": "gurmeet.singh@squadminds.com",
        "phone_number": "+91-9876543214",
        "role": "employee",
        "designation": "Web Developer",
        "department": "Engineering",
        "password": "Gurmeet@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"  # Reports to Team Manager
    },
    {
        "full_name": "Abha Sharma",
        "email": "abha.sharma@squadminds.com",
        "phone_number": "+91-9876543215",
        "role": "employee",
        "designation": "React Developer",
        "department": "Engineering",
        "password": "Abha@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"
    },
    {
        "full_name": "Harman Preet",
        "email": "harman.preet@squadminds.com",
        "phone_number": "+91-9876543216",
        "role": "employee",
        "designation": "React Developer",
        "department": "Engineering",
        "password": "Harman@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"
    },
    {
        "full_name": "Manjinder Singh",
        "email": "manjinder.singh@squadminds.com",
        "phone_number": "+91-9876543217",
        "role": "employee",
        "designation": "Software Developer",
        "department": "Engineering",
        "password": "Manjinder@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"
    },
    {
        "full_name": "Lakhveer Singh",
        "email": "lakhveer.singh@squadminds.com",
        "phone_number": "+91-9876543218",
        "role": "employee",
        "designation": "Mobile Application Developer",
        "department": "Engineering",
        "password": "Lakhveer@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"
    },
    {
        "full_name": "Himanshu Rana",
        "email": "himanshu.rana@squadminds.com",
        "phone_number": "+91-9876543219",
        "role": "employee",
        "designation": "React Native Developer",
        "department": "Engineering",
        "password": "Himanshu@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"
    },
    {
        "full_name": "Akwinder Kaur",
        "email": "akwinder.kaur@squadminds.com",
        "phone_number": "+91-9876543220",
        "role": "employee",
        "designation": "Ex Intern (Web Development)",
        "department": "Engineering",
        "password": "Akwinder@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"
    },
    {
        "full_name": "Prince Thakur",
        "email": "prince.thakur@squadminds.com",
        "phone_number": "+91-9876543221",
        "role": "employee",
        "designation": "React Native Developer",
        "department": "Engineering",
        "password": "Prince@2024Squad",
        "reports_to": "dev.gangwar@squadminds.com"
    }
]


async def create_department(company_id: str, name: str, code: str):
    """Create a department and return its ID"""
    try:
        result = await db.execute_query(
            """
            INSERT INTO departments (company_id, name, code, is_active)
            VALUES ($1, $2, $3, TRUE)
            RETURNING id, name
            """,
            company_id,
            name,
            code
        )
        
        if result:
            print(f"✅ Department created: {name}")
            return str(result[0]['id'])
        return None
    except Exception as e:
        print(f"⚠️  Department {name} may already exist: {str(e)}")
        # Try to fetch existing department
        try:
            result = await db.execute_query(
                "SELECT id FROM departments WHERE company_id = $1 AND name = $2",
                company_id,
                name
            )
            if result:
                return str(result[0]['id'])
        except:
            pass
        return None


async def create_company_and_employees():
    """Main function to create company and all employees"""
    print("\n" + "="*80)
    print("🏢 SQUADMINDS PRIVATE LIMITED - Company & Employee Setup")
    print("="*80 + "\n")
    
    try:
        # Step 1: Check if company already exists
        existing_company = await db.execute_query(
            "SELECT id, name FROM companies WHERE name = $1",
            COMPANY_DATA["name"]
        )
        
        if existing_company:
            company_id = str(existing_company[0]['id'])
            print(f"✅ Company already exists: {COMPANY_DATA['name']}")
            print(f"   Company ID: {company_id}\n")
        else:
            # Step 1: Create Company
            print("📝 Creating company...")
            company = await db.create_company(COMPANY_DATA)
            company_id = str(company['id'])
            print(f"✅ Company created: {COMPANY_DATA['name']}")
            print(f"   Company ID: {company_id}\n")
        
        # Step 2: Create Departments
        print("📂 Creating departments...")
        departments = {}
        
        dept_list = [
            ("Executive", "EXEC"),
            ("Human Resources", "HR"),
            ("Engineering", "ENG")
        ]
        
        for dept_name, dept_code in dept_list:
            dept_id = await create_department(company_id, dept_name, dept_code)
            if dept_id:
                departments[dept_name] = dept_id
        
        print()
        
        # Step 3: Create Employees
        print("👥 Creating employees...\n")
        
        # Store created profiles for manager assignment
        created_profiles = {}
        
        # First pass: Create all employees
        for idx, emp in enumerate(EMPLOYEES, 1):
            try:
                # Check if employee already exists
                existing = await db.execute_query(
                    "SELECT id, email FROM profiles WHERE email = $1 AND company_id = $2",
                    emp["email"],
                    company_id
                )
                
                if existing:
                    print(f"⚠️  [{idx}/{len(EMPLOYEES)}] {emp['full_name']} ({emp['email']}) - Already exists")
                    created_profiles[emp["email"]] = str(existing[0]['id'])
                    continue
                
                # Hash password
                password_hash = jwt_handler.hash_password(emp["password"])
                
                # Get department ID
                dept_id = departments.get(emp["department"])
                
                # Create Supabase Auth user
                try:
                    auth_response = db.client.auth.admin.create_user({
                        "email": emp["email"],
                        "password": emp["password"],
                        "email_confirm": True,
                        "user_metadata": {
                            "full_name": emp["full_name"],
                            "role": emp["role"]
                        }
                    })
                    
                    auth_user_id = auth_response.user.id
                except Exception as auth_error:
                    print(f"❌ [{idx}/{len(EMPLOYEES)}] Auth creation failed for {emp['full_name']}: {auth_error}")
                    continue
                
                # Create profile
                profile_data = {
                    "id": auth_user_id,
                    "company_id": company_id,
                    "workspace_id": company_id,
                    "email": emp["email"],
                    "full_name": emp["full_name"],
                    "phone_number": emp["phone_number"],
                    "role": emp["role"],
                    "department_id": dept_id,
                    "is_active": True
                }
                
                profile = await db.create_profile(profile_data)
                created_profiles[emp["email"]] = str(profile['id'])
                
                print(f"✅ [{idx}/{len(EMPLOYEES)}] {emp['full_name']} ({emp['role']}) - {emp['designation']}")
                print(f"   📧 {emp['email']}")
                print(f"   🔑 Password: {emp['password']}\n")
                
            except Exception as e:
                print(f"❌ [{idx}/{len(EMPLOYEES)}] Failed to create {emp['full_name']}: {str(e)}\n")
        
        # Second pass: Update manager assignments
        print("\n🔗 Setting up reporting structure...")
        for emp in EMPLOYEES:
            if emp["reports_to"] and emp["email"] in created_profiles:
                try:
                    if emp["reports_to"] in created_profiles:
                        manager_id = created_profiles[emp["reports_to"]]
                        employee_id = created_profiles[emp["email"]]
                        
                        await db.execute_query(
                            "UPDATE profiles SET reporting_manager_id = $1 WHERE id = $2",
                            manager_id,
                            employee_id
                        )
                        print(f"✅ {emp['full_name']} → Reports to {emp['reports_to']}")
                except Exception as e:
                    print(f"⚠️  Failed to set manager for {emp['full_name']}: {str(e)}")
        
        # Print Summary
        print("\n" + "="*80)
        print("📊 SETUP SUMMARY")
        print("="*80)
        print(f"\n🏢 Company: {COMPANY_DATA['name']}")
        print(f"   ID: {company_id}")
        print(f"\n📂 Departments: {len(departments)}")
        for dept_name, dept_id in departments.items():
            print(f"   - {dept_name} ({dept_id})")
        print(f"\n👥 Employees: {len(created_profiles)}/{len(EMPLOYEES)}")
        
        # Print organizational hierarchy
        print("\n🏗️  ORGANIZATIONAL STRUCTURE:")
        print("="*80)
        print("\n📊 CEO")
        print("└── Chantenbarta (CEO)")
        print("    ├── Pryanshi (HR Manager)")
        print("    │   └── Deepak Batra (HR)")
        print("    └── Dev Gangwar (Team Manager)")
        print("        ├── Gurmeet Singh (Web Developer)")
        print("        ├── Abha Sharma (React Developer)")
        print("        ├── Harman Preet (React Developer)")
        print("        ├── Manjinder Singh (Software Developer)")
        print("        ├── Lakhveer Singh (Mobile Application Developer)")
        print("        ├── Himanshu Rana (React Native Developer)")
        print("        ├── Akwinder Kaur (Ex Intern - Web Development)")
        print("        └── Prince Thakur (React Native Developer)")
        
        print("\n\n📝 LOGIN CREDENTIALS:")
        print("="*80)
        print(f"\n🏢 Company ID: {company_id}\n")
        
        for emp in EMPLOYEES:
            print(f"👤 {emp['full_name']} ({emp['designation']})")
            print(f"   📧 Email: {emp['email']}")
            print(f"   🔑 Password: {emp['password']}")
            print(f"   👔 Role: {emp['role']}")
            print()
        
        print("="*80)
        print("✅ Setup Complete!")
        print("="*80)
        
        # Save credentials to file
        credentials_file = "SQUADMINDS_CREDENTIALS.txt"
        with open(credentials_file, 'w') as f:
            f.write("="*80 + "\n")
            f.write("SQUADMINDS PRIVATE LIMITED - Login Credentials\n")
            f.write("="*80 + "\n\n")
            f.write(f"Company ID: {company_id}\n\n")
            
            for emp in EMPLOYEES:
                f.write(f"{emp['full_name']} ({emp['designation']})\n")
                f.write(f"Email: {emp['email']}\n")
                f.write(f"Password: {emp['password']}\n")
                f.write(f"Role: {emp['role']}\n")
                f.write("-" * 40 + "\n\n")
        
        print(f"\n💾 Credentials saved to: {credentials_file}")
        
    except Exception as e:
        print(f"\n❌ Fatal error: {str(e)}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(create_company_and_employees())
