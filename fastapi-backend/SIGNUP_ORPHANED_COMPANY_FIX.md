# Signup Orphaned Company Fix

## Problem Summary

When a user attempted to sign up as a `company_admin` with `create_company: true`, the following sequence occurred:

1. ✅ Company was created successfully in the database
2. ❌ User creation in Supabase Auth failed (email already registered)
3. ❌ Company was left orphaned in the database

This resulted in:
- Orphaned company records in the `companies` table
- Confusing error message for the user
- Database pollution with unused company records

## Root Cause

The signup flow was:
```
1. Create company (if requested)
2. Create user in Supabase Auth
3. Create profile in profiles table
4. Return success
```

If step 2 failed, step 1 was not rolled back, leaving an orphaned company.

## Solution Implemented

### Change 1: Early Email Validation (Primary Fix)
**File:** `fastapi-backend/app/auth/routes.py`
**Line:** ~278

```python
# ===== STEP 1: Check if user already exists in profiles table FIRST =====
# This prevents creating orphaned companies
existing_profile = await db.get_profile_by_email(signup_data.email.lower())
if existing_profile:
    # User exists - check context
    if signup_data.create_company:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    elif signup_data.company_id and existing_profile.get('company_id') == signup_data.company_id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered in this company"
        )
```

**Impact:** This prevents ANY company creation if the email is already registered, solving the root cause.

### Change 2: Rollback Mechanism (Safety Net)
**File:** `fastapi-backend/app/auth/routes.py`
**Line:** ~274 (variable tracking), ~530 (exception handlers)

```python
# Track newly created company for rollback if needed
created_company_id = None

# ... later when creating company ...
new_company = await db.create_company(company_data)
company_id = str(new_company['id'])
created_company_id = company_id  # Track for potential rollback

# ... in exception handlers ...
except HTTPException as http_exc:
    # Rollback: Delete orphaned company if it was created during this request
    if created_company_id:
        try:
            logger.warning(f"🔄 Rolling back company creation: {created_company_id}")
            db.client.table("companies").delete().eq("id", created_company_id).execute()
            logger.info(f"✅ Successfully deleted orphaned company: {created_company_id}")
        except Exception as rollback_error:
            logger.error(f"❌ Failed to rollback company creation: {rollback_error}")
    raise http_exc
```

**Impact:** If any unexpected error occurs after company creation, the company is automatically deleted.

## New Signup Flow

```
1. ✅ Check if email already exists (EARLY CHECK)
   └─ If exists → Return 409 immediately, no resources created
2. ✅ Create company (if requested)
3. ✅ Create user in Supabase Auth
   └─ If fails → Rollback company (safety net)
4. ✅ Create profile in profiles table
   └─ If fails → Rollback company (safety net)
5. ✅ Generate tokens and return success
```

## Testing

### Test 1: Duplicate Email (Should Fail Early)
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d @test_duplicate_signup.json
```

**Expected Result:**
- HTTP Status: `409 Conflict`
- Response: `{"detail":"Email already registered"}`
- **No company created** (verified in logs)

✅ **Verified: No orphaned companies created**

### Test 2: New Email (Should Succeed)
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "Test@12345",
    "full_name": "New User",
    "role": "company_admin",
    "create_company": true,
    "company_name": "New Company"
  }'
```

**Expected Result:**
- HTTP Status: `201 Created`
- Response includes `access_token`, `refresh_token`, user details
- Company and user both created successfully

## Benefits

1. **Prevents Orphaned Records:** Email check happens before any resource creation
2. **Database Integrity:** Rollback mechanism ensures consistency even if unexpected errors occur
3. **Better UX:** Users get immediate feedback if email is already registered
4. **Multi-Tenant Safe:** Respects company context in multi-tenant scenarios
5. **Resource Efficient:** No wasted company records in the database

## Monitoring

Check backend logs for these patterns:

### Success Case (Early Detection)
```
⚠️ Email already registered: rahul8@yopmail.com
INFO:     38.137.51.137:0 - "POST /api/v1/auth/signup HTTP/1.1" 409 Conflict
```

### Success Case (Rollback Triggered - shouldn't happen often)
```
🔄 Rolling back company creation: <company_id>
✅ Successfully deleted orphaned company: <company_id>
```

### Error Case (Rollback Failed - investigate immediately)
```
❌ Failed to rollback company creation: <error>
```

## Deployment Notes

1. **No Database Migrations Required:** All changes are in application logic
2. **Backward Compatible:** Does not affect existing signups or users
3. **No Downtime:** Can be deployed via hot-reload with watchfiles
4. **Auto-Reload:** Backend will automatically reload when `app/auth/routes.py` is saved

## Files Modified

- `fastapi-backend/app/auth/routes.py` (signup endpoint)

## Related Issues

- Fixes orphaned company creation when user already exists
- Improves error handling for duplicate signups
- Adds defensive rollback mechanism for unexpected errors

## Future Enhancements

1. Add database transaction support for atomic operations
2. Add cleanup job to find and remove existing orphaned companies
3. Add metrics/alerts for rollback occurrences
4. Consider moving to a database-level constraint or trigger

---

**Status:** ✅ Implemented and Tested
**Date:** 2026-06-26
**Author:** Kiro AI Assistant
