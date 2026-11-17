"""
Check Current Database Status
This script shows what's currently in the database
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SERVICE_KEY)


def check_auth_users():
    """Check auth.users table"""
    print("="*80)
    print("👤 AUTH USERS (in auth.users table)")
    print("="*80)
    
    try:
        # List all users via Admin API
        response = supabase.auth.admin.list_users()
        
        if not response:
            print("❌ No users found in auth.users\n")
            return 0
        
        count = len(response)
        print(f"✅ Found {count} user(s):\n")
        
        for idx, user in enumerate(response, 1):
            metadata = user.user_metadata or {}
            print(f"[{idx}] {user.email}")
            print(f"    ID: {user.id}")
            print(f"    Name: {metadata.get('full_name', 'N/A')}")
            print(f"    Role: {metadata.get('role', 'N/A')}")
            print(f"    Created: {user.created_at}")
            print()
        
        return count
    except Exception as e:
        print(f"❌ Error checking auth users: {str(e)}\n")
        return 0


def check_profiles():
    """Check profiles table"""
    print("="*80)
    print("📋 PROFILES (in profiles table)")
    print("="*80)
    
    try:
        response = supabase.table("profiles").select("*").execute()
        
        if not response.data:
            print("❌ No profiles found in profiles table\n")
            print("⚠️  This means auth.users are NOT synced to profiles!\n")
            return 0
        
        count = len(response.data)
        print(f"✅ Found {count} profile(s):\n")
        
        for idx, profile in enumerate(response.data, 1):
            print(f"[{idx}] {profile.get('email')}")
            print(f"    ID: {profile.get('id')}")
            print(f"    Name: {profile.get('full_name')}")
            print(f"    Role: {profile.get('role')}")
            print(f"    Company ID: {profile.get('company_id')}")
            print(f"    Active: {profile.get('is_active')}")
            print()
        
        return count
    except Exception as e:
        print(f"❌ Error checking profiles: {str(e)}\n")
        return 0


def check_companies():
    """Check companies table"""
    print("="*80)
    print("🏢 COMPANIES (in companies table)")
    print("="*80)
    
    try:
        response = supabase.table("companies").select("*").execute()
        
        if not response.data:
            print("❌ No companies found\n")
            return 0
        
        count = len(response.data)
        print(f"✅ Found {count} company(ies):\n")
        
        for idx, company in enumerate(response.data, 1):
            print(f"[{idx}] {company.get('name')}")
            print(f"    ID: {company.get('id')}")
            print(f"    Email: {company.get('email')}")
            print(f"    Phone: {company.get('phone')}")
            print(f"    Active: {company.get('is_active')}")
            print()
        
        return count
    except Exception as e:
        print(f"❌ Error checking companies: {str(e)}\n")
        return 0


def check_departments():
    """Check departments table"""
    print("="*80)
    print("📂 DEPARTMENTS (in departments table)")
    print("="*80)
    
    try:
        response = supabase.table("departments").select("*, companies(name)").execute()
        
        if not response.data:
            print("❌ No departments found\n")
            return 0
        
        count = len(response.data)
        print(f"✅ Found {count} department(s):\n")
        
        for idx, dept in enumerate(response.data, 1):
            company = dept.get('companies', {})
            company_name = company.get('name', 'Unknown') if company else 'Unknown'
            
            print(f"[{idx}] {dept.get('name')}")
            print(f"    ID: {dept.get('id')}")
            print(f"    Company: {company_name}")
            print(f"    Active: {dept.get('is_active')}")
            print()
        
        return count
    except Exception as e:
        print(f"❌ Error checking departments: {str(e)}\n")
        return 0


def check_rls_status():
    """Check RLS status"""
    print("="*80)
    print("🔒 RLS (Row Level Security) STATUS")
    print("="*80)
    
    try:
        # This query might not work via REST API, but let's try
        response = supabase.rpc("exec_sql", {
            "sql": """
                SELECT 
                  tablename,
                  CASE 
                    WHEN rowsecurity THEN 'ENABLED'
                    ELSE 'DISABLED'
                  END as rls_status
                FROM pg_tables
                WHERE schemaname = 'public'
                AND tablename IN ('profiles', 'companies', 'departments', 'attendance', 'leaves', 'payroll')
                ORDER BY tablename;
            """
        }).execute()
        
        if response.data:
            print("\nTable               | RLS Status")
            print("-" * 40)
            for row in response.data:
                status = "🔒 ENABLED" if row["rls_status"] == "ENABLED" else "✅ DISABLED"
                print(f"{row['tablename']:<20} | {status}")
        else:
            print("\n⚠️  Cannot check RLS status via API")
            print("   Use Supabase Dashboard → SQL Editor to check")
        
        print()
    except Exception as e:
        print(f"\n⚠️  Cannot check RLS status: {str(e)}")
        print("   This is normal - use Supabase Dashboard to check RLS\n")


def print_summary(auth_count, profile_count, company_count, dept_count):
    """Print summary"""
    print("\n" + "="*80)
    print("📊 DATABASE STATUS SUMMARY")
    print("="*80)
    
    print(f"\n✅ Auth Users:  {auth_count}")
    print(f"✅ Profiles:    {profile_count}")
    print(f"✅ Companies:   {company_count}")
    print(f"✅ Departments: {dept_count}")
    
    print("\n" + "="*80)
    print("🔍 DIAGNOSIS")
    print("="*80 + "\n")
    
    if auth_count > 0 and profile_count == 0:
        print("⚠️  ISSUE DETECTED:")
        print("   - Auth users exist but profiles table is empty")
        print("   - Users are NOT synced to profiles table")
        print("\n💡 SOLUTION:")
        print("   Run the SQL scripts in URGENT_DATABASE_FIX.md")
        print("   This will sync auth.users → profiles\n")
    elif auth_count > 0 and profile_count > 0:
        print("✅ GOOD:")
        print("   - Auth users exist and profiles are synced\n")
    else:
        print("⚠️  WARNING:")
        print("   - No users found in database")
        print("   - Need to create users first\n")
    
    if company_count == 0:
        print("⚠️  ISSUE DETECTED:")
        print("   - No companies in database")
        print("\n💡 SOLUTION:")
        print("   Run the SQL scripts in URGENT_DATABASE_FIX.md")
        print("   This will create SQUADMINDS company\n")
    else:
        print("✅ GOOD:")
        print("   - Company data exists\n")
    
    if dept_count == 0:
        print("⚠️  ISSUE DETECTED:")
        print("   - No departments in database")
        print("\n💡 SOLUTION:")
        print("   Run the SQL scripts in URGENT_DATABASE_FIX.md")
        print("   This will create departments\n")
    else:
        print("✅ GOOD:")
        print("   - Department data exists\n")
    
    print("="*80)
    print("📖 NEXT STEPS")
    print("="*80 + "\n")
    
    if profile_count == 0 or company_count == 0 or dept_count == 0:
        print("1. Open: URGENT_DATABASE_FIX.md")
        print("2. Follow the instructions to run SQL scripts")
        print("3. Run this script again to verify")
        print("4. Test your Flutter app\n")
    else:
        print("✅ Database looks good!")
        print("   You can now test your Flutter app\n")
        print("   Login with: chetan@squadminds.com / Ceo@7890\n")


def main():
    """Main function"""
    print("\n" + "="*80)
    print("🔍 DATABASE STATUS CHECK")
    print("="*80 + "\n")
    
    # Check all tables
    auth_count = check_auth_users()
    profile_count = check_profiles()
    company_count = check_companies()
    dept_count = check_departments()
    check_rls_status()
    
    # Print summary and diagnosis
    print_summary(auth_count, profile_count, company_count, dept_count)


if __name__ == "__main__":
    main()
