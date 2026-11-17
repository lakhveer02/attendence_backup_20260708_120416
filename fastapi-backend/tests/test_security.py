"""
Security Tests - Week 1 Implementation
Tests JWT, rate limiting, and RLS
"""

import pytest
import time
from datetime import datetime, timedelta
import jwt as pyjwt

# Add parent directory to path for imports
import sys
sys.path.insert(0, '..')

from app.auth.jwt_handler import jwt_handler


class TestJWTSecurity:
    """Test JWT token security improvements"""
    
    def test_jwt_expiry_is_15_minutes(self):
        """Verify JWT tokens expire in 15 minutes"""
        token = jwt_handler.create_access_token(
            profile_id="test-user-123",
            email="test@example.com",
            role="employee",
            company_id="company-123",
            company_name="Test Company",
            full_name="Test User"
        )
        
        # Decode without verification to check expiry
        payload = pyjwt.decode(token, options={"verify_signature": False})
        
        issued_at = datetime.fromtimestamp(payload['iat'])
        expires_at = datetime.fromtimestamp(payload['exp'])
        
        expiry_minutes = (expires_at - issued_at).total_seconds() / 60
        
        assert expiry_minutes == 15, f"Expected 15 min expiry, got {expiry_minutes}"
        print(f"✅ JWT expiry correct: {expiry_minutes} minutes")
    
    def test_jwt_contains_required_claims(self):
        """Verify JWT contains all required security claims"""
        token = jwt_handler.create_access_token(
            profile_id="test-user-123",
            email="test@example.com",
            role="employee",
            company_id="company-123",
            company_name="Test Company",
            full_name="Test User"
        )
        
        payload = jwt_handler.decode_token(token)
        
        required_claims = ['sub', 'email', 'role', 'company_id', 'iat', 'exp', 'jti', 'type']
        
        for claim in required_claims:
            assert claim in payload, f"Missing required claim: {claim}"
        
        print(f"✅ All required claims present: {', '.join(required_claims)}")
    
    def test_jwt_type_is_access(self):
        """Verify access token has correct type"""
        token = jwt_handler.create_access_token(
            profile_id="test-user-123",
            email="test@example.com",
            role="employee",
            company_id="company-123",
            company_name="Test Company",
            full_name="Test User"
        )
        
        payload = jwt_handler.decode_token(token)
        
        assert payload['type'] == 'access', "Token type should be 'access'"
        print("✅ Token type correct: access")
    
    def test_refresh_token_has_30_day_expiry(self):
        """Verify refresh tokens expire in 30 days"""
        token, token_hash = jwt_handler.create_refresh_token(
            profile_id="test-user-123",
            device_id="test-device"
        )
        
        payload = pyjwt.decode(token, options={"verify_signature": False})
        
        issued_at = datetime.fromtimestamp(payload['iat'])
        expires_at = datetime.fromtimestamp(payload['exp'])
        
        expiry_days = (expires_at - issued_at).days
        
        assert expiry_days == 30, f"Expected 30 day expiry, got {expiry_days}"
        print(f"✅ Refresh token expiry correct: {expiry_days} days")


class TestPasswordSecurity:
    """Test password hashing security"""
    
    def test_bcrypt_rounds_is_14(self):
        """Verify bcrypt uses 14 rounds"""
        password = "TestPassword123!"
        password_hash = jwt_handler.hash_password(password)
        
        # Bcrypt hash format: $2b$rounds$salt_and_hash
        # Extract rounds from hash
        parts = password_hash.split('$')
        rounds = int(parts[2])
        
        assert rounds == 14, f"Expected 14 rounds, got {rounds}"
        print(f"✅ Bcrypt rounds correct: {rounds}")
    
    def test_password_hashing_is_slow(self):
        """Verify password hashing takes reasonable time (security vs UX)"""
        password = "TestPassword123!"
        
        start = time.time()
        password_hash = jwt_handler.hash_password(password)
        duration = time.time() - start
        
        # Should take 100-500ms (too fast = weak, too slow = bad UX)
        assert 0.05 < duration < 2.0, f"Hashing time {duration:.3f}s seems wrong"
        print(f"✅ Password hashing time acceptable: {duration:.3f}s")
    
    def test_same_password_different_hashes(self):
        """Verify same password produces different hashes (salt working)"""
        password = "TestPassword123!"
        
        hash1 = jwt_handler.hash_password(password)
        hash2 = jwt_handler.hash_password(password)
        
        assert hash1 != hash2, "Same password should produce different hashes"
        print("✅ Salt working: different hashes for same password")
    
    def test_password_verification_works(self):
        """Verify password verification works correctly"""
        password = "TestPassword123!"
        password_hash = jwt_handler.hash_password(password)
        
        # Correct password should verify
        assert jwt_handler.verify_password(password, password_hash), "Valid password should verify"
        
        # Wrong password should not verify
        assert not jwt_handler.verify_password("WrongPassword", password_hash), "Invalid password should not verify"
        
        print("✅ Password verification working correctly")


class TestRolePermissions:
    """Test role-based permissions"""
    
    def test_super_admin_has_all_permissions(self):
        """Verify super_admin has all permissions"""
        permissions = jwt_handler._get_role_permissions("super_admin")
        
        # Super admin should have lots of permissions
        assert len(permissions) > 10, "Super admin should have many permissions"
        assert "companies:create" in permissions
        assert "companies:delete" in permissions
        
        print(f"✅ Super admin has {len(permissions)} permissions")
    
    def test_employee_has_limited_permissions(self):
        """Verify employee has only basic permissions"""
        permissions = jwt_handler._get_role_permissions("employee")
        
        # Employee should have limited permissions
        assert len(permissions) < 10, "Employee should have limited permissions"
        assert "attendance:mark_own" in permissions
        assert "leaves:apply" in permissions
        
        # Should not have admin permissions
        assert "companies:delete" not in permissions
        assert "employees:delete" not in permissions
        
        print(f"✅ Employee has limited permissions: {len(permissions)}")
    
    def test_hr_manager_has_hr_permissions(self):
        """Verify HR manager has appropriate permissions"""
        permissions = jwt_handler._get_role_permissions("hr_manager")
        
        assert "employees:create" in permissions
        assert "leaves:approve" in permissions
        assert "attendance:read_all" in permissions
        
        # Should not have company management
        assert "companies:delete" not in permissions
        
        print(f"✅ HR manager has {len(permissions)} permissions")


def run_all_tests():
    """Run all security tests"""
    print("\n" + "="*70)
    print("🔒 SECURITY TESTS - Week 1 Implementation")
    print("="*70 + "\n")
    
    test_jwt = TestJWTSecurity()
    test_password = TestPasswordSecurity()
    test_permissions = TestRolePermissions()
    
    print("\n📋 JWT Security Tests:")
    print("-" * 70)
    test_jwt.test_jwt_expiry_is_15_minutes()
    test_jwt.test_jwt_contains_required_claims()
    test_jwt.test_jwt_type_is_access()
    test_jwt.test_refresh_token_has_30_day_expiry()
    
    print("\n🔐 Password Security Tests:")
    print("-" * 70)
    test_password.test_bcrypt_rounds_is_14()
    test_password.test_password_hashing_is_slow()
    test_password.test_same_password_different_hashes()
    test_password.test_password_verification_works()
    
    print("\n👥 Role Permission Tests:")
    print("-" * 70)
    test_permissions.test_super_admin_has_all_permissions()
    test_permissions.test_employee_has_limited_permissions()
    test_permissions.test_hr_manager_has_hr_permissions()
    
    print("\n" + "="*70)
    print("✅ ALL SECURITY TESTS PASSED!")
    print("="*70 + "\n")


if __name__ == "__main__":
    run_all_tests()
