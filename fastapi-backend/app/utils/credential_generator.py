"""
Credential Generation Utilities
Server-side password generation for administrative user provisioning
Per Architecture Blueprint: Passwords are generated server-side and delivered securely
"""

import secrets
import string
from typing import Tuple
import hashlib
import logging

logger = logging.getLogger(__name__)


class CredentialGenerator:
    """
    Generates secure credentials for administrative user provisioning
    
    Per Architecture Blueprint:
    - Passwords generated server-side during administrative creation
    - Delivered via secure transmission channels
    - Meet security requirements: 8+ chars, uppercase, lowercase, digit, special char
    """
    
    @staticmethod
    def generate_secure_password(length: int = 12) -> str:
        """
        Generate a cryptographically secure random password
        
        Password Requirements:
        - Minimum 8 characters (default 12 for extra security)
        - At least 1 uppercase letter
        - At least 1 lowercase letter
        - At least 1 digit
        - At least 1 special character
        
        Args:
            length: Password length (minimum 8, recommended 12+)
            
        Returns:
            str: Generated password meeting all requirements
        """
        if length < 8:
            length = 8
        
        # Character sets
        uppercase = string.ascii_uppercase
        lowercase = string.ascii_lowercase
        digits = string.digits
        special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
        
        # Ensure at least one character from each required set
        password_chars = [
            secrets.choice(uppercase),
            secrets.choice(lowercase),
            secrets.choice(digits),
            secrets.choice(special),
        ]
        
        # Fill remaining length with random characters from all sets
        all_chars = uppercase + lowercase + digits + special
        for _ in range(length - 4):
            password_chars.append(secrets.choice(all_chars))
        
        # Shuffle to avoid predictable pattern
        secrets.SystemRandom().shuffle(password_chars)
        
        password = ''.join(password_chars)
        
        logger.info(f"✅ Generated secure password (length: {len(password)})")
        
        return password
    
    @staticmethod
    def generate_temporary_password() -> str:
        """
        Generate a temporary password for first-time login
        User will be prompted to change on first login
        
        Returns:
            str: Temporary password (12 characters)
        """
        return CredentialGenerator.generate_secure_password(12)
    
    @staticmethod
    def generate_employee_id_component() -> str:
        """
        Generate random component for employee ID
        Format: 6 random uppercase alphanumeric characters
        
        Returns:
            str: Random ID component (e.g., "A7K9M2")
        """
        chars = string.ascii_uppercase + string.digits
        return ''.join(secrets.choice(chars) for _ in range(6))
    
    @staticmethod
    def generate_invitation_token(length: int = 32) -> str:
        """
        Generate secure invitation token for email links
        
        Args:
            length: Token length (default 32 bytes = 64 hex chars)
            
        Returns:
            str: Hex-encoded secure random token
        """
        return secrets.token_hex(length)
    
    @staticmethod
    def generate_company_joining_code() -> str:
        """
        Generate 8-character company joining code (alphanumeric uppercase)
        Format: XXXXYYYY where X and Y are random uppercase letters/digits
        
        Per Architecture Blueprint:
        - Used for invite-based onboarding
        - 8 character alphanumeric code
        - Easy to communicate verbally or via text
        
        Returns:
            str: 8-character joining code (e.g., "ABC12XYZ")
        """
        chars = string.ascii_uppercase + string.digits
        code = ''.join(secrets.choice(chars) for _ in range(8))
        
        logger.info(f"✅ Generated company joining code")
        
        return code
    
    @staticmethod
    def generate_otp(length: int = 6) -> str:
        """
        Generate numeric OTP for 2FA
        
        Args:
            length: OTP length (default 6 digits)
            
        Returns:
            str: Numeric OTP
        """
        return ''.join(secrets.choice(string.digits) for _ in range(length))
    
    @staticmethod
    def hash_credential(credential: str) -> str:
        """
        Hash a credential (password, token, etc.) for storage
        Uses SHA-256 for non-password hashing (use bcrypt for passwords)
        
        Args:
            credential: Credential to hash
            
        Returns:
            str: Hex-encoded hash
        """
        return hashlib.sha256(credential.encode()).hexdigest()
    
    @staticmethod
    def validate_password_strength(password: str) -> Tuple[bool, list]:
        """
        Validate password meets security requirements
        
        Requirements:
        - Minimum 8 characters
        - At least 1 uppercase letter
        - At least 1 lowercase letter
        - At least 1 digit
        - At least 1 special character (optional but recommended)
        
        Args:
            password: Password to validate
            
        Returns:
            Tuple[bool, list]: (is_valid, list_of_errors)
        """
        errors = []
        
        if len(password) < 8:
            errors.append("Password must be at least 8 characters long")
        
        if not any(c.isupper() for c in password):
            errors.append("Password must contain at least one uppercase letter")
        
        if not any(c.islower() for c in password):
            errors.append("Password must contain at least one lowercase letter")
        
        if not any(c.isdigit() for c in password):
            errors.append("Password must contain at least one digit")
        
        # Check for special characters (recommended)
        special_chars = "!@#$%^&*()-_=+[]{}|;:,.<>?"
        if not any(c in special_chars for c in password):
            # This is a warning, not a hard requirement
            pass
        
        is_valid = len(errors) == 0
        
        return is_valid, errors


class CredentialDelivery:
    """
    Handles secure delivery of credentials to users
    
    Delivery Methods:
    1. Email invitation with secure link
    2. SMS (for OTP)
    3. Admin dashboard display (for immediate handoff)
    """
    
    @staticmethod
    def prepare_invitation_email(
        recipient_email: str,
        recipient_name: str,
        temporary_password: str,
        company_name: str,
        created_by_name: str,
        workspace_slug: str,
        invitation_token: str
    ) -> dict:
        """
        Prepare invitation email content
        
        Args:
            recipient_email: New user's email
            recipient_name: New user's full name
            temporary_password: Generated password
            company_name: Company/workspace name
            created_by_name: Name of admin who created the account
            workspace_slug: Company workspace slug for login
            invitation_token: Secure invitation token
            
        Returns:
            dict: Email content with subject, body, and metadata
        """
        login_url = f"https://app.yourhrms.com/join/{invitation_token}"
        
        email_subject = f"Welcome to {company_name} - Your Account Credentials"
        
        email_body_html = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; }}
                .content {{ background-color: #f9f9f9; padding: 20px; border: 1px solid #ddd; }}
                .credentials {{ background-color: #fff; padding: 15px; border-left: 4px solid #4CAF50; margin: 20px 0; }}
                .button {{ display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                .footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #666; }}
                .warning {{ background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 15px 0; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to {company_name}!</h1>
                </div>
                
                <div class="content">
                    <p>Hi {recipient_name},</p>
                    
                    <p>{created_by_name} has created an account for you in {company_name}'s workspace.</p>
                    
                    <div class="credentials">
                        <h3>Your Login Credentials:</h3>
                        <p><strong>Email:</strong> {recipient_email}</p>
                        <p><strong>Temporary Password:</strong> <code>{temporary_password}</code></p>
                        <p><strong>Workspace:</strong> {workspace_slug}</p>
                    </div>
                    
                    <div class="warning">
                        <strong>⚠️ Important Security Information:</strong>
                        <ul>
                            <li>This is a temporary password. You will be prompted to change it on first login.</li>
                            <li>Keep your credentials secure and do not share them with anyone.</li>
                            <li>This invitation link expires in 7 days.</li>
                        </ul>
                    </div>
                    
                    <center>
                        <a href="{login_url}" class="button">Accept Invitation & Login</a>
                    </center>
                    
                    <p>Or copy and paste this URL into your browser:</p>
                    <p><code>{login_url}</code></p>
                    
                    <p>If you did not expect this invitation, please ignore this email or contact {created_by_name}.</p>
                </div>
                
                <div class="footer">
                    <p>© 2026 {company_name}. All rights reserved.</p>
                    <p>This is an automated message. Please do not reply to this email.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        email_body_text = f"""
        Welcome to {company_name}!
        
        Hi {recipient_name},
        
        {created_by_name} has created an account for you in {company_name}'s workspace.
        
        YOUR LOGIN CREDENTIALS:
        Email: {recipient_email}
        Temporary Password: {temporary_password}
        Workspace: {workspace_slug}
        
        IMPORTANT SECURITY INFORMATION:
        - This is a temporary password. You will be prompted to change it on first login.
        - Keep your credentials secure and do not share them with anyone.
        - This invitation link expires in 7 days.
        
        To accept your invitation and login, visit:
        {login_url}
        
        If you did not expect this invitation, please ignore this email or contact {created_by_name}.
        
        ---
        © 2026 {company_name}. All rights reserved.
        This is an automated message. Please do not reply to this email.
        """
        
        return {
            "to": recipient_email,
            "subject": email_subject,
            "body_html": email_body_html,
            "body_text": email_body_text,
            "metadata": {
                "recipient_name": recipient_name,
                "company_name": company_name,
                "invitation_token": invitation_token,
                "created_by": created_by_name
            }
        }
    
    @staticmethod
    def prepare_credential_handoff(
        recipient_email: str,
        recipient_name: str,
        temporary_password: str,
        role: str,
        employee_id: str,
        created_by_name: str
    ) -> dict:
        """
        Prepare credentials for immediate handoff (displayed to admin)
        Used when admin creates account and immediately shares credentials
        
        Args:
            recipient_email: New user's email
            recipient_name: New user's full name
            temporary_password: Generated password
            role: User's role
            employee_id: Generated employee ID
            created_by_name: Admin who created the account
            
        Returns:
            dict: Formatted credentials for display
        """
        return {
            "success": True,
            "message": f"User account created successfully for {recipient_name}",
            "credentials": {
                "full_name": recipient_name,
                "email": recipient_email,
                "temporary_password": temporary_password,
                "employee_id": employee_id,
                "role": role,
                "created_by": created_by_name,
                "created_at": "now"
            },
            "instructions": [
                "Please provide these credentials to the user securely",
                "User will be prompted to change password on first login",
                "Credentials should be transmitted via secure channel (encrypted email, secure messaging)",
                "Do not share credentials via plain SMS or unencrypted email"
            ]
        }


# Convenience functions
def generate_user_credentials(role: str = "employee") -> dict:
    """
    Generate complete user credentials for provisioning
    
    Args:
        role: User role
        
    Returns:
        dict: Generated credentials
    """
    generator = CredentialGenerator()
    
    return {
        "temporary_password": generator.generate_temporary_password(),
        "invitation_token": generator.generate_invitation_token(),
    }
