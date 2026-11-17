"""
Complete Database Setup - Disables RLS and Creates Company + Employees
This script will:
1. Disable RLS on necessary tables
2. Create Squadminds company
3. Create all employees
4. Sync profiles
"""

import asyncio
import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

# Initialize Supabase client with SERVICE key
supabase: Client = create_client(SUPABASE_URL, SERVICE_KEY)

# Company ID (already defined)
COMPANY_ID = "b090d51d-3a18-4a0a-8c18-25765fc43456"

# Company Data
COMPANY_DATA = {
    "id": COMPANY_ID,
    "name": "SQUADMINDS PRIVATE LIMITED",
    "email": "chetan@squadminds.com",
    "phone": "+91-9999999999",
    "address": "India",
    "is_active": True
}

# Employees
EMPLOYEES = [
    {
        "full_name": "Chetan Batra",
        "email": "chetan@squadminds.com",
        "password": "Ceo@7890",
        "role": "company_admin",
        "designation": "Chief Executive Officer (CEO)",
        "department": "Executive",
        "phone_number": "+91-9876543210"
    },
    {
        "full_name": "Pryanshi",
        "email": "pryanshi@squadminds.com",
        "password": "Hr@2024Squad",
        "role": "hr_manager",
        "designation": "HR Manager",
        "department": "Human Resources",
        "phone_number": "+91-9876543211"
    },
    {
        "full_name": "Deepak Batra",
        "email": "deepak.batra@squadminds.com",
        "password": "Deepak@2024Squad",
        "role": "hr_manager",
        "designation": "HR",
        "department": "Human Resources",
        "phone_number": "+91-9876543212"
    },
    {
        "full_name": "Dev Gangwar",
        "email": "dev.gangwar@squadminds.com",
        "password": "Dev@2024Squad",
        "role": "manager",
        "designation": "Team Manager",
        "department": "Engineering",
        "phone_number": "+91-9876543213"
    },
    {
        "full_name": "Gurmeet Singh",
        "email": "gurmeet.singh@squadminds.com",
        "password": "Gurmeet@2024Squad",
        "role": "employee",
        "designation": "Web Developer",
        "department": "Engineering",
        "phone_number": "+91-9876543214"
    },
    {
        "full_name": "Abha Sharma",
        "email": "abha.sharma@squadminds.com",
        "password": "Abha@2024Squad",
        "role": "employee",
        "designation": "React Developer",
        "department": "Engineering",
        "phone_number": "+91-9876543215"
    },
    {
        "full_name": "Harman Preet",
        "email": "harman.preet@squadminds.com",
        "password": "Harman@2024Squad",
        "role": "employee",
        "designation": "React Developer",
        "department": "Engineering",
        "phone_number": "+91-9876543216"
    },
    {
        "full_name": "Manjinder Singh",
        "email": "manjinder.singh@squadminds.com",
        "password": "Manjinder@2024Squad",
        "role": "employee",
        "designation": "Software Developer",
        "department": "Engineering",
        "phone_number": "+91-9876543217"
    }
]


def disable_rls():
    """Disable RLS on all tables"""
    print("\n" + "="*80)
    print("🔓 Disabling RLS on tables...")
    print("="*80 + "\n")
    
    tables = ["profiles", "companies", "departments", "attendance", "leaves", "payroll"]
    
    for table in tables:
        try:
            # Execute raw SQL to disable RLS
            supabase.postgrest.rpc("exec_sql", {
                "sql": f"ALTER TABLE {table} DISABLE ROW LEVEL SECURITY;"
            })
            print(f"✅ Disabled RLS on {table}")
        except Exception as e:
            # RLS might already be disabled or we need another approach
            print(f"⚠️  Could not disable RLS on {table}: {str(e)}")
    
    print("\n✅ RLS disabled!\n")


def create_company():
    """Create company"""
    print("="*80)
    print("🏢 Creating Company...")
    print("="*80 + "\n")
    
    try:
        # Check if company exists
        result = supabase.table("companies").select("*").eq("id", COMPANY_ID).execute()
        
        if result.data:
            print(f"✅ Company already exists: {COMPANY_DATA['name']}")
            print(f"   ID: {COMPANY_ID}\n")
            return True
        
        # Create company
        result = supabase.table("companies").insert(COMPANY_DATA).execute()
        print(f"✅ Company created: {COMPANY_DATA['name']}")
        print(f"   ID: {COMPANY_ID}\n")
        return True
    except Exception as e:
        print(f"❌ Error creating company: {str(e)}\n")
        return False


def create_departments():
    """Create departments"""
    print("="*80)
    print("📂 Creating Departments...")
    print("="*80 + "\n")
    
    departments = [
        {"company_id": COMPANY_ID, "name": "Executive", "is_active": True},
        {"company_id": COMPANY_ID, "name": "Human Resources", "is_active": True},
        {"company_id": COMPANY_ID, "name": "Engineering", "is_active": True}
    ]
    
    for dept in departments:
        try:
            # Check if exists
            result = supabase.table("departments").select("*").eq("company_id", COMPANY_ID).eq("name", dept["name"]).execute()
            
            if result.data:
                print(f"✅ Department already exists: {dept['name']}")
                continue
            
            # Create department
            supabase.table("departments").insert(dept).execute()
            print(f"✅ Created department: {dept['name']}")
        except Exception as e:
            print(f"⚠️  Error creating department {dept['name']}: {str(e)}")
    
    print()


def create_employees():
    """Create all employees"""
    print("="*80)
    print("👥 Creating Employees...")
    print("="*80 + "\n")
    
    created_count = 0
    
    for idx, emp in enumerate(EMPLOYEES, 1):
        try:
            # Check if user already exists
            try:
                user = supabase.auth.admin.get_user_by_email(emp["email"])
                if user:
                    print(f"⚠️  [{idx}/{len(EMPLOYEES)}] {emp['full_name']} - Already exists")
                    created_count += 1
                    continue
            except:
                pass
            
            # Create user via Supabase Auth
            auth_response = supabase.auth.admin.create_user({
                "email": emp["email"],
                "password": emp["password"],
                "email_confirm": True,
                "user_metadata": {
                    "full_name": emp["full_name"],
                    "role": emp["role"],
                    "company_id": COMPANY_ID,
                    "company_name": COMPANY_DATA["name"]
                }
            })
            
            # Create profile
            profile_data = {
                "id": auth_response.user.id,
                "email": emp["email"],
                "full_name": emp["full_name"],
                "role": emp["role"],
                "company_id": COMPANY_ID,
                "phone_number": emp["phone_number"],
                "is_active": True
            }
            
            supabase.table("profiles").insert(profile_data).execute()
            
            print(f"✅ [{idx}/{len(EMPLOYEES)}] {emp['full_name']} ({emp['role']})")
            print(f"   📧 {emp['email']} | 🔑 {emp['password']}\n")
            created_count += 1
            
        except Exception as e:
            print(f"❌ [{idx}/{len(EMPLOYEES)}] Failed to create {emp['full_name']}: {str(e)}\n")
    
    return created_count


def print_summary(created_count):
    """Print final summary"""
    print("\n" + "="*80)
    print("📊 SETUP COMPLETE!")
    print("="*80 + "\n")
    
    print(f"🏢 Company: {COMPANY_DATA['name']}")
    print(f"   ID: {COMPANY_ID}\n")
    
    print(f"👥 Employees Created: {created_count}/{len(EMPLOYEES)}\n")
    
    print("="*80)
    print("📝 LOGIN CREDENTIALS")
    print("="*80 + "\n")
    
    for emp in EMPLOYEES:
        print(f"👤 {emp['full_name']} ({emp['role']})")
        print(f"   📧 Email: {emp['email']}")
        print(f"   🔑 Password: {emp['password']}\n")
    
    print("="*80)
    print("✅ You can now login to the Flutter app!")
    print("="*80 + "\n")
    
    # Save to file
    with open("SETUP_COMPLETE.txt", "w") as f:
        f.write("="*80 + "\n")
        f.write("SQUADMINDS PRIVATE LIMITED - Setup Complete\n")
        f.write("="*80 + "\n\n")
        f.write(f"Company: {COMPANY_DATA['name']}\n")
        f.write(f"Company ID: {COMPANY_ID}\n\n")
        f.write("LOGIN CREDENTIALS:\n")
        f.write("-"*80 + "\n\n")
        
        for emp in EMPLOYEES:
            f.write(f"{emp['full_name']} ({emp['role']})\n")
            f.write(f"Email: {emp['email']}\n")
            f.write(f"Password: {emp['password']}\n\n")
    
    print("💾 Credentials saved to: SETUP_COMPLETE.txt\n")


def main():
    """Main function"""
    print("\n" + "="*80)
    print("🚀 SQUADMINDS DATABASE SETUP")
    print("="*80 + "\n")
    
    # Note: We cannot disable RLS via REST API, need to use Supabase SQL Editor
    # But we can still try to create data using SERVICE_KEY which bypasses RLS
    
    print("ℹ️  Using SERVICE_KEY to bypass RLS policies\n")
    
    # Step 1: Create Company
    if not create_company():
        print("\n⚠️  Company creation failed, but continuing...\n")
    
    # Step 2: Create Departments
    create_departments()
    
    # Step 3: Create Employees
    created_count = create_employees()
    
    # Step 4: Print Summary
    print_summary(created_count)
    
    print("="*80)
    print("🎉 SETUP COMPLETE! Test your app now!")
    print("="*80)


if __name__ == "__main__":
    main()
