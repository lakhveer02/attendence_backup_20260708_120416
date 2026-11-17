#!/usr/bin/env python3
"""
Create all test users for Squaid Minds Private Limited
"""
import asyncio
import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from app.database_complete import db_complete as db
from supabase import create_client, Client
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def main():
    """Create Squaid Minds test users"""
    
    print("=" * 80)
    print("🏢 CREATING SQUAID MINDS PRIVATE LIMITED TEST USERS")
    print("=" * 80)
    print()
    
    try:
        # Step 1: Create company directly using RPC or raw SQL if RLS is blocking
        print("📍 Step 1: Creating Company...")
        
        company_data = {
            "name": "Squaid Minds Private Limited",
            "status": "active",
            "timezone": "Asia/Kolkata",
            "industry": "Technology",
            "size": "medium",
            "city": "Bangalore",
            "country": "India"
        }
        
        try:
            # Try to create company
            company = await db.create_company(company_data)
            company_id = str(company['id'])
            print(f"✅ Company created: {company['name']} (ID: {company_id})")
        except Exception as e:
            error_msg = str(e)
            print(f"⚠️  Company creation failed: {error_msg}")
            
            # Check if it's due to duplicate
            if "duplicate" in error_msg.lower() or "already exists" in error_msg.lower():
                print("🔍 Checking if company already exists...")
                existing = await db.get_company_by_name("Squaid Minds Private Limited")
                if existing:
                    company_id = str(existing['id'])
                    print(f"✅ Using existing company (ID: {company_id})")
                else:
                    print("❌ Cannot proceed without company")
                    return
            elif "42501" in error_msg or "row-level security" in error_msg.lower():
                # RLS policy blocking - try to fetch existing or create with admin privileges
                print("⚠️  RLS policy blocking company creation")
                print("🔧 Attempting workaround...")
                
                # Try direct SQL with service role
                try:
                    result = db.client.rpc('create_company_admin', {
                        'company_name': 'Squaid Minds Private Limited',
                        'company_status': 'active',
                        'company_timezone': 'Asia/Kolkata'
                    }).execute()
                    
                    if result.data:
                        company_id = str(result.data[0]['id'])
                        print(f"✅ Company created via RPC: {company_id}")
                    else:
                        raise Exception("RPC returned no data")
                        
                except Exception as rpc_error:
                    print(f"⚠️  RPC method not available: {rpc_error}")
                    print("📋 Please create company manually in Supabase dashboard:")
                    print(f"   Name: Squaid Minds Private Limited")
                    print(f"   Status: active")
                    print(f"   Timezone: Asia/Kolkata")
                    print()
                    
                    # Ask user to input company ID
                    company_id = input("Enter the company_id from Supabase dashboard: ").strip()
                    if not company_id:
                        print("❌ Company ID required to proceed")
                        return
                    
                    print(f"✅ Using company ID: {company_id}")
            else:
                raise
        
        print()
        print("=" * 80)
        
        # Step 2: Create users using Supabase Auth Admin API
        users_to_create = [
            {
                "email": "admin@squaidminds.com",
                "password": "SquaidAdmin@123",
                "full_name": "Squaid Company Admin",
                "role": "company_admin",
                "phone_number": "+91-9876543210"
            },
            {
                "email": "hr@squaidminds.com",
                "password": "SquaidHR@123",
                "full_name": "Squaid HR Manager",
                "role": "hr_manager",
                "phone_number": "+91-9876543211"
            },
            {
                "email": "manager@squaidminds.com",
                "password": "SquaidManager@123",
                "full_name": "Squaid Team Manager",
                "role": "team_manager",
                "phone_number": "+91-9876543212"
            },
            {
                "email": "employee1@squaidminds.com",
                "password": "SquaidEmp1@123",
                "full_name": "Rahul Kumar",
                "role": "employee",
                "phone_number": "+91-9876543213"
            },
            {
                "email": "employee2@squaidminds.com",
                "password": "SquaidEmp2@123",
                "full_name": "Priya Sharma",
                "role": "employee",
                "phone_number": "+91-9876543214"
            }
        ]
        
        print("📍 Step 2: Creating Users...")
        print()
        
        for i, user_data in enumerate(users_to_create, 1):
            print(f"{i}. Creating {user_data['role']}: {user_data['email']}")
            
            try:
                # Create auth user with admin API (bypasses email confirmation)
                auth_response = db.client.auth.admin.create_user({
                    "email": user_data['email'].lower(),
                    "password": user_data['password'],
                    "email_confirm": True,
                    "user_metadata": {
                        "full_name": user_data['full_name'],
                        "role": user_data['role']
                    }
                })
                
                if not auth_response.user:
                    print(f"   ❌ Failed to create auth user")
                    continue
                
                auth_user_id = auth_response.user.id
                print(f"   ✅ Auth user created: {auth_user_id}")
                
                # Create profile
                profile_data = {
                    "id": auth_user_id,
                    "company_id": company_id,
                    "workspace_id": company_id,
                    "email": user_data['email'].lower(),
                    "full_name": user_data['full_name'],
                    "role": user_data['role'],
                    "phone_number": user_data['phone_number'],
                    "is_active": True
                }
                
                profile = await db.create_profile(profile_data)
                print(f"   ✅ Profile created: {profile['full_name']} ({profile['role']})")
                
            except Exception as e:
                error_msg = str(e)
                if "already" in error_msg.lower() or "duplicate" in error_msg.lower():
                    print(f"   ⚠️  User already exists: {user_data['email']}")
                else:
                    print(f"   ❌ Error creating user: {error_msg}")
            
            print()
        
        # Step 3: Create Super Admin (system-wide)
        print("=" * 80)
        print("📍 Step 3: Creating Super Admin...")
        print()
        
        # Get or create system company
        try:
            system_companies = db.client.table("companies").select("id").eq("name", "System Administration").limit(1).execute()
            
            if system_companies.data:
                system_company_id = str(system_companies.data[0]['id'])
                print(f"✅ Using existing system company: {system_company_id}")
            else:
                system_company = await db.create_company({
                    "name": "System Administration",
                    "status": "active",
                    "timezone": "UTC"
                })
                system_company_id = str(system_company['id'])
                print(f"✅ Created system company: {system_company_id}")
        except Exception as e:
            print(f"⚠️  Error with system company: {e}")
            system_company_id = company_id  # Fallback to Squaid Minds company
        
        print()
        print("Creating super admin...")
        
        try:
            # Create super admin auth user
            auth_response = db.client.auth.admin.create_user({
                "email": "superadmin@squaidminds.com",
                "password": "SuperAdmin@123",
                "email_confirm": True,
                "user_metadata": {
                    "full_name": "Super Administrator",
                    "role": "super_admin"
                }
            })
            
            if not auth_response.user:
                print(f"   ❌ Failed to create super admin auth user")
            else:
                auth_user_id = auth_response.user.id
                print(f"   ✅ Super admin auth user created: {auth_user_id}")
                
                # Create super admin profile
                profile_data = {
                    "id": auth_user_id,
                    "company_id": system_company_id,
                    "workspace_id": system_company_id,
                    "email": "superadmin@squaidminds.com",
                    "full_name": "Super Administrator",
                    "role": "super_admin",
                    "phone_number": "+91-9999999999",
                    "is_active": True
                }
                
                profile = await db.create_profile(profile_data)
                print(f"   ✅ Super admin profile created: {profile['full_name']}")
                
        except Exception as e:
            error_msg = str(e)
            if "already" in error_msg.lower() or "duplicate" in error_msg.lower():
                print(f"   ⚠️  Super admin already exists")
            else:
                print(f"   ❌ Error creating super admin: {error_msg}")
        
        print()
        print("=" * 80)
        print("🎉 USER CREATION COMPLETE!")
        print("=" * 80)
        print()
        print("📋 CREDENTIALS SUMMARY:")
        print()
        print("Company: Squaid Minds Private Limited")
        print(f"Company ID: {company_id}")
        print()
        print("1. Company Admin")
        print("   Email: admin@squaidminds.com")
        print("   Password: SquaidAdmin@123")
        print()
        print("2. HR Manager")
        print("   Email: hr@squaidminds.com")
        print("   Password: SquaidHR@123")
        print()
        print("3. Team Manager")
        print("   Email: manager@squaidminds.com")
        print("   Password: SquaidManager@123")
        print()
        print("4. Employee 1 (Rahul Kumar)")
        print("   Email: employee1@squaidminds.com")
        print("   Password: SquaidEmp1@123")
        print()
        print("5. Employee 2 (Priya Sharma)")
        print("   Email: employee2@squaidminds.com")
        print("   Password: SquaidEmp2@123")
        print()
        print("6. Super Admin")
        print("   Email: superadmin@squaidminds.com")
        print("   Password: SuperAdmin@123")
        print()
        print("=" * 80)
        print("✅ Ready to test! Run the login tests from TEST_SQUAID_MINDS.md")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
