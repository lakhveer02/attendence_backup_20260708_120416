#!/usr/bin/env python3
"""
Cleanup script to find and remove orphaned companies
Orphaned companies are those created without any associated users

Usage: python cleanup_orphaned_companies.py [--dry-run] [--company-id=<id>]
"""
import asyncio
import sys
import os
from datetime import datetime

# Add the app directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database_complete import db_complete as db

async def find_orphaned_companies():
    """Find companies that have no associated profiles"""
    query = """
        SELECT 
            c.id,
            c.name,
            c.status,
            c.created_at,
            COUNT(p.id) as user_count
        FROM companies c
        LEFT JOIN profiles p ON c.id = p.company_id
        WHERE c.name != 'System Administration'  -- Don't touch system company
        GROUP BY c.id, c.name, c.status, c.created_at
        HAVING COUNT(p.id) = 0
        ORDER BY c.created_at DESC
    """
    
    try:
        results = await db.execute_query(query)
        return results if results else []
    except Exception as e:
        print(f"❌ Error finding orphaned companies: {e}")
        # Fallback to table-based query if raw SQL doesn't work
        try:
            # Get all companies
            companies = db.client.table("companies").select("id, name, status, created_at").execute()
            
            orphaned = []
            for company in companies.data:
                if company['name'] == 'System Administration':
                    continue
                    
                # Check if company has any profiles
                profiles = db.client.table("profiles").select("id").eq("company_id", company['id']).limit(1).execute()
                
                if not profiles.data:
                    orphaned.append({
                        'id': company['id'],
                        'name': company['name'],
                        'status': company['status'],
                        'created_at': company['created_at'],
                        'user_count': 0
                    })
            
            return orphaned
        except Exception as fallback_error:
            print(f"❌ Fallback query also failed: {fallback_error}")
            return []

async def delete_company(company_id: str, company_name: str, dry_run: bool = True):
    """Delete a company by ID"""
    if dry_run:
        print(f"   [DRY RUN] Would delete: {company_name} (ID: {company_id})")
        return True
    
    try:
        result = db.client.table("companies").delete().eq("id", company_id).execute()
        print(f"   ✅ Deleted: {company_name} (ID: {company_id})")
        return True
    except Exception as e:
        print(f"   ❌ Failed to delete {company_name}: {e}")
        return False

async def main():
    """Main cleanup logic"""
    # Parse arguments
    dry_run = "--dry-run" in sys.argv or "-n" in sys.argv
    specific_company_id = None
    
    for arg in sys.argv:
        if arg.startswith("--company-id="):
            specific_company_id = arg.split("=")[1]
    
    print("=" * 80)
    print("🔍 ORPHANED COMPANY CLEANUP")
    print("=" * 80)
    
    if dry_run:
        print("⚠️  DRY RUN MODE - No companies will be deleted")
    else:
        print("🚨 LIVE MODE - Companies will be permanently deleted!")
        response = input("\n   Are you sure you want to continue? (yes/no): ")
        if response.lower() != "yes":
            print("   Cancelled.")
            return
    
    print(f"\n📊 Scanning for orphaned companies...")
    
    orphaned = await find_orphaned_companies()
    
    if not orphaned:
        print("✅ No orphaned companies found!")
        return
    
    print(f"\n📋 Found {len(orphaned)} orphaned companies:\n")
    
    # Display orphaned companies
    for i, company in enumerate(orphaned, 1):
        created_date = company.get('created_at', 'Unknown')
        if isinstance(created_date, str):
            try:
                created_date = datetime.fromisoformat(created_date.replace('Z', '+00:00'))
                created_date = created_date.strftime('%Y-%m-%d %H:%M:%S')
            except:
                pass
        
        print(f"{i}. {company['name']}")
        print(f"   ID: {company['id']}")
        print(f"   Status: {company.get('status', 'N/A')}")
        print(f"   Created: {created_date}")
        print(f"   Users: {company.get('user_count', 0)}")
        print()
    
    # Filter if specific company ID provided
    if specific_company_id:
        orphaned = [c for c in orphaned if c['id'] == specific_company_id]
        if not orphaned:
            print(f"❌ Company ID {specific_company_id} not found in orphaned list")
            return
        print(f"🎯 Targeting specific company: {orphaned[0]['name']}\n")
    
    # Delete orphaned companies
    print(f"🗑️  {'[DRY RUN] Simulating deletion' if dry_run else 'Deleting companies'}...\n")
    
    deleted_count = 0
    for company in orphaned:
        success = await delete_company(company['id'], company['name'], dry_run=dry_run)
        if success:
            deleted_count += 1
    
    print("\n" + "=" * 80)
    print("📊 CLEANUP SUMMARY")
    print("=" * 80)
    print(f"Found: {len(orphaned)} orphaned companies")
    print(f"{'Would delete' if dry_run else 'Deleted'}: {deleted_count} companies")
    
    if dry_run:
        print("\n💡 To actually delete these companies, run without --dry-run flag:")
        print(f"   python {sys.argv[0]}")
    else:
        print("\n✅ Cleanup complete!")
    
    print()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
