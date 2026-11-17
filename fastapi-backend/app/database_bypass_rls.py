"""
Database layer that BYPASSES Supabase REST API RLS restrictions
Uses Auth Admin API only - no REST API calls
"""
import os
from typing import Optional, Dict, Any, List
from supabase import create_client, Client
from dotenv import load_dotenv
import logging
import uuid

load_dotenv()

logger = logging.getLogger(__name__)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

class SupabaseBypassRLS:
    """
    Database client that ONLY uses Auth Admin API
    Completely bypasses REST API and RLS restrictions
    """
    
    def __init__(self):
        self.client: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        logger.info("✅ Supabase Bypass RLS client initialized")
    
    async def get_profile_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get profile by email using Auth Admin API ONLY"""
        try:
            # Use Auth Admin API to list users (this bypasses RLS)
            response = self.client.auth.admin.list_users()
            
            if not response:
                return None
            
            # Find user by email
            for user in response:
                if user.email and user.email.lower() == email.lower():
                    # Return user data in profile format
                    return {
                        "id": user.id,
                        "email": user.email,
                        "full_name": user.user_metadata.get("full_name") if user.user_metadata else None,
                        "role": user.user_metadata.get("role") if user.user_metadata else "employee",
                        "company_id": user.user_metadata.get("company_id") if user.user_metadata else None,
                        "is_active": True
                    }
            
            return None
        except Exception as e:
            logger.error(f"Error getting profile by email: {e}")
            return None
    
    async def create_user_with_company(self, email: str, password: str, full_name: str, 
                                      role: str, company_name: str) -> Dict[str, Any]:
        """
        Create user and company using ONLY Auth Admin API
        This completely bypasses RLS
        """
        try:
            # Generate IDs
            company_id = str(uuid.uuid4())
            
            # Create user in Auth (this always works, bypasses RLS)
            auth_response = self.client.auth.admin.create_user({
                "email": email.lower(),
                "password": password,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": full_name,
                    "role": role,
                    "company_id": company_id,
                    "company_name": company_name
                }
            })
            
            if not auth_response.user:
                raise Exception("Failed to create auth user")
            
            logger.info(f"✅ User created in Auth: {email}")
            
            # Return success with user data
            return {
                "success": True,
                "user_id": auth_response.user.id,
                "email": email,
                "full_name": full_name,
                "role": role,
                "company_id": company_id,
                "company_name": company_name,
                "message": "User and company created successfully"
            }
            
        except Exception as e:
            logger.error(f"❌ Error creating user with company: {e}")
            raise Exception(f"Signup failed: {str(e)}")
    
    async def create_employee(self, email: str, password: str, full_name: str, 
                            role: str, company_id: str) -> Dict[str, Any]:
        """
        Create employee user (joining existing company)
        Uses ONLY Auth Admin API
        """
        try:
            # Create user in Auth
            auth_response = self.client.auth.admin.create_user({
                "email": email.lower(),
                "password": password,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": full_name,
                    "role": role,
                    "company_id": company_id
                }
            })
            
            if not auth_response.user:
                raise Exception("Failed to create auth user")
            
            logger.info(f"✅ Employee created: {email}")
            
            return {
                "success": True,
                "user_id": auth_response.user.id,
                "email": email,
                "full_name": full_name,
                "role": role,
                "company_id": company_id,
                "message": "Employee created successfully"
            }
            
        except Exception as e:
            logger.error(f"❌ Error creating employee: {e}")
            raise Exception(f"Employee creation failed: {str(e)}")
    
    async def authenticate_user(self, email: str, password: str) -> Dict[str, Any]:
        """
        Authenticate user using Auth API
        This bypasses REST API completely
        """
        try:
            # Sign in with Auth API
            response = self.client.auth.sign_in_with_password({
                "email": email.lower(),
                "password": password
            })
            
            if not response.user:
                raise Exception("Invalid credentials")
            
            # Get user metadata
            user_data = {
                "id": response.user.id,
                "email": response.user.email,
                "full_name": response.user.user_metadata.get("full_name") if response.user.user_metadata else None,
                "role": response.user.user_metadata.get("role") if response.user.user_metadata else "employee",
                "company_id": response.user.user_metadata.get("company_id") if response.user.user_metadata else None,
                "access_token": response.session.access_token if response.session else None,
                "refresh_token": response.session.refresh_token if response.session else None
            }
            
            return user_data
            
        except Exception as e:
            logger.error(f"❌ Authentication failed: {e}")
            raise Exception("Invalid email or password")
    
    async def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID using Auth Admin API"""
        try:
            response = self.client.auth.admin.get_user_by_id(user_id)
            
            if not response.user:
                return None
            
            return {
                "id": response.user.id,
                "email": response.user.email,
                "full_name": response.user.user_metadata.get("full_name") if response.user.user_metadata else None,
                "role": response.user.user_metadata.get("role") if response.user.user_metadata else "employee",
                "company_id": response.user.user_metadata.get("company_id") if response.user.user_metadata else None,
            }
        except Exception as e:
            logger.error(f"Error getting user by ID: {e}")
            return None
    
    async def list_company_users(self, company_id: str) -> List[Dict[str, Any]]:
        """List all users in a company using Auth Admin API"""
        try:
            response = self.client.auth.admin.list_users()
            
            if not response:
                return []
            
            # Filter by company_id
            company_users = []
            for user in response:
                user_company_id = user.user_metadata.get("company_id") if user.user_metadata else None
                if user_company_id == company_id:
                    company_users.append({
                        "id": user.id,
                        "email": user.email,
                        "full_name": user.user_metadata.get("full_name") if user.user_metadata else None,
                        "role": user.user_metadata.get("role") if user.user_metadata else "employee",
                        "company_id": user_company_id
                    })
            
            return company_users
        except Exception as e:
            logger.error(f"Error listing company users: {e}")
            return []


# Global instance
db_bypass = SupabaseBypassRLS()
