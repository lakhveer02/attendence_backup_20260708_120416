"""
Multi-Tenant Database Operations
Workspaces, Invitations, Branches, Subscriptions
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import secrets
import logging

logger = logging.getLogger(__name__)

class MultiTenantDatabase:
    def __init__(self, supabase_client):
        self.client = supabase_client
    
    # ==================== WORKSPACE OPERATIONS ====================
    
    async def create_workspace(self, workspace_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create new company workspace"""
        try:
            # Create company - only use fields that exist in the companies table
            # Based on actual schema, companies table has: name, industry, size, website, 
            # logo_url, address, city, country, timezone, status, etc.
            company_response = self.client.table("companies").insert({
                "name": workspace_data["name"],
                # slug doesn't exist in actual schema - skip it
                "industry": workspace_data.get("industry"),
                "size": workspace_data.get("size", "small"),
                "website": workspace_data.get("website"),
                "logo_url": workspace_data.get("logo_url"),
                "address": workspace_data.get("address"),
                "city": workspace_data.get("city"),
                "country": workspace_data.get("country"),
                "timezone": workspace_data.get("timezone", "UTC"),
                "office_latitude": workspace_data.get("office_latitude"),
                "office_longitude": workspace_data.get("office_longitude"),
                "status": "active",  # Set default status
            }).execute()
            
            company = company_response.data[0]
            logger.info(f"✅ Workspace created: {company['name']}")
            
            return company
        except Exception as e:
            logger.error(f"❌ Error creating workspace: {e}")
            raise
    
    async def create_workspace_owner(self, company_id: str, owner_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create owner profile and workspace membership"""
        try:
            # Create profile
            profile_response = self.client.table("profiles").insert({
                "company_id": company_id,
                "email": owner_data["email"],
                "full_name": owner_data["full_name"],
                "role": "admin",  # Database role
                "is_active": True,
            }).execute()
            
            profile = profile_response.data[0]
            
            # Create workspace membership
            workspace_response = self.client.table("user_workspaces").insert({
                "user_id": profile["id"],
                "company_id": company_id,
                "role": "owner",
                "is_owner": True,
                "is_active": True,
                "joined_at": datetime.now().isoformat(),
                "last_accessed": datetime.now().isoformat(),
            }).execute()
            
            # Update company owner_id
            self.client.table("companies").update({
                "owner_id": profile["id"]
            }).eq("id", company_id).execute()
            
            logger.info(f"✅ Workspace owner created: {owner_data['email']}")
            
            return profile
        except Exception as e:
            logger.error(f"❌ Error creating workspace owner: {e}")
            raise
    
    async def check_slug_availability(self, slug: str) -> bool:
        """Check if workspace name is available (slug field doesn't exist in schema)"""
        try:
            # Check by name instead of slug since slug field doesn't exist
            response = self.client.table("companies").select("id").eq("name", slug).execute()
            return len(response.data) == 0
        except Exception as e:
            logger.error(f"❌ Error checking name availability: {e}")
            return False
    
    async def get_user_workspaces(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all workspaces user belongs to"""
        try:
            response = self.client.rpc("get_user_workspaces", {"user_uuid": user_id}).execute()
            return response.data if response.data else []
        except Exception as e:
            logger.error(f"❌ Error getting user workspaces: {e}")
            return []
    
    async def switch_workspace(self, user_id: str, company_id: str) -> bool:
        """Update last accessed timestamp when user switches workspace"""
        try:
            self.client.table("user_workspaces").update({
                "last_accessed": datetime.now().isoformat()
            }).eq("user_id", user_id).eq("company_id", company_id).execute()
            
            logger.info(f"✅ User {user_id} switched to workspace {company_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Error switching workspace: {e}")
            return False
    
    # ==================== INVITATION OPERATIONS ====================
    
    async def create_invitation(self, invitation_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create invitation for user to join company"""
        try:
            # Generate invitation code
            invitation_code = secrets.token_urlsafe(16)
            
            invitation_response = self.client.table("company_invitations").insert({
                "company_id": invitation_data["company_id"],
                "invited_by": invitation_data["invited_by"],
                "email": invitation_data["email"],
                "phone_number": invitation_data.get("phone_number"),
                "role": invitation_data["role"],
                "invitation_code": invitation_code,
                "invitation_link": f"https://attendence.app/join/{invitation_code}",
                "status": "pending",
                "expires_at": (datetime.now() + timedelta(days=7)).isoformat(),
            }).execute()
            
            invitation = invitation_response.data[0]
            logger.info(f"✅ Invitation created: {invitation['email']} → {invitation['role']}")
            
            return invitation
        except Exception as e:
            logger.error(f"❌ Error creating invitation: {e}")
            raise
    
    async def get_invitation_by_code(self, code: str) -> Optional[Dict[str, Any]]:
        """Get invitation by code"""
        try:
            response = (
                self.client.table("company_invitations")
                .select("*, companies(name, logo_url)")
                .eq("invitation_code", code)
                .execute()
            )
            
            if response.data:
                invitation = response.data[0]
                # Flatten company data
                if invitation.get('companies'):
                    invitation['company_name'] = invitation['companies']['name']
                    invitation['company_logo'] = invitation['companies'].get('logo_url')
                    del invitation['companies']
                return invitation
            return None
        except Exception as e:
            logger.error(f"❌ Error getting invitation: {e}")
            return None
    
    async def accept_invitation(self, invitation_id: str) -> bool:
        """Mark invitation as accepted"""
        try:
            self.client.table("company_invitations").update({
                "status": "accepted",
                "accepted_at": datetime.now().isoformat()
            }).eq("id", invitation_id).execute()
            
            logger.info(f"✅ Invitation accepted: {invitation_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Error accepting invitation: {e}")
            return False
    
    async def get_company_invitations(self, company_id: str, status: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get all invitations for a company"""
        try:
            query = (
                self.client.table("company_invitations")
                .select("*, profiles!invited_by(full_name)")
                .eq("company_id", company_id)
                .order("created_at", desc=True)
            )
            
            if status:
                query = query.eq("status", status)
            
            response = query.execute()
            
            # Flatten inviter data
            invitations = []
            for inv in (response.data if response.data else []):
                if inv.get('profiles'):
                    inv['inviter_name'] = inv['profiles']['full_name']
                    del inv['profiles']
                invitations.append(inv)
            
            return invitations
        except Exception as e:
            logger.error(f"❌ Error getting company invitations: {e}")
            return []
    
    async def cancel_invitation(self, invitation_id: str) -> bool:
        """Cancel pending invitation"""
        try:
            self.client.table("company_invitations").update({
                "status": "cancelled"
            }).eq("id", invitation_id).execute()
            
            logger.info(f"✅ Invitation cancelled: {invitation_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Error cancelling invitation: {e}")
            return False
    
    # ==================== BRANCH OPERATIONS ====================
    
    async def create_branch(self, branch_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create new branch"""
        try:
            response = self.client.table("branches").insert(branch_data).execute()
            branch = response.data[0]
            logger.info(f"✅ Branch created: {branch['name']}")
            return branch
        except Exception as e:
            logger.error(f"❌ Error creating branch: {e}")
            raise
    
    async def get_company_branches(self, company_id: str) -> List[Dict[str, Any]]:
        """Get all branches for a company"""
        try:
            response = (
                self.client.table("branches")
                .select("*, profiles!manager_id(full_name)")
                .eq("company_id", company_id)
                .eq("is_active", True)
                .order("is_headquarters", desc=True)
                .order("name")
                .execute()
            )
            
            # Flatten manager data and add employee count
            branches = []
            for branch in (response.data if response.data else []):
                if branch.get('profiles'):
                    branch['manager_name'] = branch['profiles']['full_name']
                    del branch['profiles']
                
                # Get employee count for branch
                emp_response = (
                    self.client.table("profiles")
                    .select("id", count="exact")
                    .eq("company_id", company_id)
                    .execute()
                )
                branch['employee_count'] = emp_response.count if emp_response.count else 0
                
                branches.append(branch)
            
            return branches
        except Exception as e:
            logger.error(f"❌ Error getting company branches: {e}")
            return []
    
    async def update_branch(self, branch_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """Update branch"""
        try:
            response = self.client.table("branches").update(updates).eq("id", branch_id).execute()
            return response.data[0] if response.data else {}
        except Exception as e:
            logger.error(f"❌ Error updating branch: {e}")
            raise
    
    # ==================== SUBSCRIPTION OPERATIONS ====================
    
    async def get_subscription_plans(self) -> List[Dict[str, Any]]:
        """Get all active subscription plans"""
        try:
            response = (
                self.client.table("subscription_plans")
                .select("*")
                .eq("is_active", True)
                .order("sort_order")
                .execute()
            )
            return response.data if response.data else []
        except Exception as e:
            logger.error(f"❌ Error getting subscription plans: {e}")
            return []
    
    async def upgrade_subscription(self, company_id: str, plan_name: str) -> bool:
        """Upgrade company subscription"""
        try:
            # Get plan details
            plan_response = (
                self.client.table("subscription_plans")
                .select("*")
                .eq("name", plan_name)
                .execute()
            )
            
            if not plan_response.data:
                return False
            
            plan = plan_response.data[0]
            
            # Update company
            self.client.table("companies").update({
                "subscription_plan": plan_name,
                "subscription_status": "active",
                "max_employees": plan["max_employees"],
                "subscription_start_date": datetime.now().date().isoformat(),
                "subscription_end_date": (datetime.now() + timedelta(days=365)).date().isoformat(),
            }).eq("id", company_id).execute()
            
            logger.info(f"✅ Subscription upgraded: {company_id} → {plan_name}")
            return True
        except Exception as e:
            logger.error(f"❌ Error upgrading subscription: {e}")
            return False
    
    # ==================== PLATFORM ADMIN OPERATIONS ====================
    
    async def get_platform_stats(self) -> Dict[str, Any]:
        """Get platform-wide statistics"""
        try:
            # Total companies
            companies = self.client.table("companies").select("*", count="exact").execute()
            active_companies = self.client.table("companies").select("*", count="exact").eq("is_suspended", False).execute()
            trial_companies = self.client.table("companies").select("*", count="exact").eq("subscription_plan", "trial").execute()
            
            # Total users
            users = self.client.table("profiles").select("*", count="exact").execute()
            active_users = self.client.table("profiles").select("*", count="exact").eq("is_active", True).execute()
            
            return {
                "total_companies": companies.count or 0,
                "active_companies": active_companies.count or 0,
                "suspended_companies": (companies.count or 0) - (active_companies.count or 0),
                "trial_companies": trial_companies.count or 0,
                "total_users": users.count or 0,
                "active_users": active_users.count or 0,
                "total_revenue": 0.0,  # Calculate from billing_transactions
                "new_signups_today": 0,  # Calculate from today's data
                "avg_employees_per_company": (users.count or 0) / (companies.count or 1),
            }
        except Exception as e:
            logger.error(f"❌ Error getting platform stats: {e}")
            return {}
    
    async def verify_company(self, company_id: str) -> bool:
        """Verify company"""
        try:
            self.client.table("companies").update({
                "is_verified": True
            }).eq("id", company_id).execute()
            
            logger.info(f"✅ Company verified: {company_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Error verifying company: {e}")
            return False
    
    async def suspend_company(self, company_id: str, reason: Optional[str] = None) -> bool:
        """Suspend company"""
        try:
            self.client.table("companies").update({
                "is_suspended": True,
                "subscription_status": "suspended"
            }).eq("id", company_id).execute()
            
            # Log audit
            self.client.table("audit_logs").insert({
                "company_id": company_id,
                "action": "company_suspended",
                "resource_type": "company",
                "resource_id": company_id,
                "details": {"reason": reason} if reason else {}
            }).execute()
            
            logger.info(f"✅ Company suspended: {company_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Error suspending company: {e}")
            return False
