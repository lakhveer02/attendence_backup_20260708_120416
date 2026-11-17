# ✅ Test Checklist - Verify Everything Works

## 🎯 Pre-Testing Setup

### ⚠️ CRITICAL: Fix Database First
- [ ] Opened Supabase Dashboard (https://zkwlkfplelpsfrvvlfka.supabase.co)
- [ ] Clicked SQL Editor
- [ ] Ran `FIX_RLS_PERMISSIONS.sql`
- [ ] Verified query returned `employee_count: 12`

### Device Requirements
- [ ] Using **REAL PHYSICAL DEVICE** (not emulator)
- [ ] Device has fingerprint or face recognition enrolled
- [ ] Device has internet connection
- [ ] Device allows app installations

---

## 🔧 Backend Tests

### Start Backend
```bash
cd fastapi-backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- [ ] Backend starts without errors
- [ ] See: `INFO:     Uvicorn running on http://0.0.0.0:8000`
- [ ] No "permission denied" errors in logs

### Test All Logins
```bash
cd fastapi-backend
source venv/bin/activate
python test_all_employee_logins.py
```

**Expected Results:**
- [ ] ✅ Successful Logins: 12/12
- [ ] ✅ Dashboard shows 12 employees
- [ ] 🎉 ALL TESTS PASSED!

**If Failed:**
- Check RLS SQL was run
- Verify backend `.env` has correct Supabase keys
- Restart backend

---

## 📱 App Tests

### Build & Run
```bash
cd /Users/squad-mac/Desktop/Flutter/attendence
flutter run
```

- [ ] App builds without errors
- [ ] App installs on device
- [ ] Login screen appears
- [ ] Purple "Test Biometric" button visible (bottom-right)

### Test Screen Access
- [ ] Click purple "Test Biometric" FAB
- [ ] Test screen opens
- [ ] All sections visible (Biometric, Permissions, Notifications)

---

## 🔐 Biometric Tests

### Device Capabilities
- [ ] Shows "Has Biometrics: Yes ✅" (or "No ❌" if no hardware)
- [ ] Shows correct device model and OS version
- [ ] Shows available biometric types (Fingerprint/Face/Iris)

### Fingerprint Test (if available)
- [ ] Click "Test Biometric Authentication"
- [ ] Fingerprint prompt appears
- [ ] Place finger on sensor
- [ ] Success dialog: "Success! ✅"
- [ ] Shows biometric type used

### Face Recognition Test (if available)
- [ ] Click "Test Face Recognition Only"
- [ ] Face scan prompt appears (iPhone: Face ID, Android: Face Unlock)
- [ ] Look at camera
- [ ] Success dialog: "Success! ✅"

### Expected Failures
- [ ] Wrong finger = "Not recognized. Try again."
- [ ] Cancel = "Authentication failed or cancelled"
- [ ] No biometric enrolled = "No biometrics enrolled" message

**If No Biometric Hardware:**
- Shows "⚠️ No biometric hardware detected"
- Message: "Testing on emulator? Use a real device."
- This is NORMAL on emulators

---

## 🔒 Permission Tests

### Location Permission
- [ ] Click "Request Location Permission"
- [ ] System permission dialog appears
- [ ] Grant permission (select "Allow" or "While Using App")
- [ ] Status changes to "Granted ✅"
- [ ] Success dialog appears

### Camera Permission
- [ ] Click "Request Camera Permission"
- [ ] System permission dialog appears
- [ ] Grant permission
- [ ] Status changes to "Granted ✅"
- [ ] Success dialog appears

### Notification Permission
- [ ] Click "Request Notification Permission"
- [ ] System permission dialog appears
- [ ] Grant permission
- [ ] Status changes to "Granted ✅"
- [ ] Success dialog appears

### Request All Permissions
- [ ] Click "Request All Permissions"
- [ ] All permission dialogs appear sequentially
- [ ] Grant all permissions
- [ ] Summary dialog shows:
  - Location: ✅
  - Camera: ✅
  - Notifications: ✅

**If Permission Denied:**
- Status shows "Denied ❌" (orange)
- Click request button again to retry
- If "Permanently Denied ⛔" (red), must go to device settings

---

## 🔔 Notification Tests

### Immediate Notification
- [ ] Click "Send Test Notification"
- [ ] Green snackbar: "Test notification sent!"
- [ ] **Check notification bar** on device
- [ ] See notification: "Test Notification"
- [ ] Notification shows current time

### Check-in Reminder
- [ ] Click "Send Check-in Reminder"
- [ ] Green snackbar: "Check-in reminder sent!"
- [ ] **Check notification bar**
- [ ] See: "Check-in Reminder"
- [ ] Body mentions "Test User"

### Scheduled Notification
- [ ] Click "Schedule Notification (5 sec)"
- [ ] Green snackbar: "Notification scheduled for 5 seconds from now!"
- [ ] **Wait 5 seconds**
- [ ] **Check notification bar**
- [ ] See: "Scheduled Test"
- [ ] Body: "This notification was scheduled 5 seconds ago!"

**If Notifications Don't Appear:**
- Verify notification permission granted
- Check device Do Not Disturb is OFF
- Check device notification settings for app
- Try sending test notification again

---

## 🎭 Login Tests

### CEO Login
- [ ] Go back to login screen
- [ ] Enter email: `chanten.batra@company.com`
- [ ] Enter password: `Ceo@1234`
- [ ] Click "Sign In"
- [ ] Login successful
- [ ] Redirects to Admin Dashboard
- [ ] Dashboard shows **"Total Employees: 12"**

**If Dashboard Shows 0:**
- ⚠️ RLS SQL fix not applied
- Run `FIX_RLS_PERMISSIONS.sql` in Supabase
- Restart backend
- Login again

### HR Manager Login
- [ ] Logout (if needed)
- [ ] Enter email: `deepak.batra@company.com`
- [ ] Enter password: `Hr@1234`
- [ ] Click "Sign In"
- [ ] Login successful
- [ ] Shows HR dashboard/view

### Developer Login
- [ ] Logout (if needed)
- [ ] Enter email: `gurmeet.singh@company.com`
- [ ] Enter password: `Dev@1234`
- [ ] Click "Sign In"
- [ ] Login successful
- [ ] Shows employee dashboard

---

## 📊 Final Verification

### Backend Health
- [ ] No errors in backend console
- [ ] All API endpoints responding
- [ ] Database queries working
- [ ] Logs show successful operations

### App Health
- [ ] No errors in Flutter console
- [ ] All screens navigating correctly
- [ ] UI rendering properly
- [ ] No crashes or freezes

### Feature Integration
- [ ] Biometric service accessible from app
- [ ] Permissions requested when needed
- [ ] Notifications sending correctly
- [ ] Login/logout working
- [ ] Dashboard displaying data

---

## 🎯 Success Criteria

**Minimum Requirements:**
- ✅ Backend runs without errors
- ✅ At least CEO login works
- ✅ Biometric test screen accessible
- ✅ Permissions can be requested
- ✅ Test notification sends

**Full Success:**
- ✅ All 12 employees can login
- ✅ Dashboard shows 12 employees
- ✅ Biometric authentication works
- ✅ All permissions grant successfully
- ✅ All notifications arrive
- ✅ No errors in logs
- ✅ All features functional

---

## 🐛 Common Issues & Quick Fixes

### "Permission Denied" in Backend
**Fix:** Run `FIX_RLS_PERMISSIONS.sql` in Supabase SQL Editor

### Dashboard Shows 0 Employees
**Fix:** Same as above + restart backend

### Biometric Not Working
**Fix:** Test on real device with enrolled biometric

### Permissions Not Showing
**Fix:** Run `flutter clean && flutter pub get`

### Notifications Not Appearing
**Fix:** Check notification permission granted + device settings

### Login Fails
**Fix:** Check backend is running + correct credentials used

---

## 📝 Test Results Template

Copy and fill out:

```
## Test Results - [Date]

### Backend
- Backend Started: [ ] Yes / [ ] No
- All Logins Work: [ ] Yes / [ ] No (___/12)
- Dashboard Correct: [ ] Yes / [ ] No (Shows ___ employees)

### App
- App Installed: [ ] Yes / [ ] No
- Test Screen Opens: [ ] Yes / [ ] No
- Biometric Works: [ ] Yes / [ ] No / [ ] N/A (no hardware)
- Permissions Work: [ ] Yes / [ ] No (___/3 granted)
- Notifications Work: [ ] Yes / [ ] No (___/3 received)

### Overall Status
- [ ] ✅ All tests passed - READY FOR USE
- [ ] ⚠️ Some issues - needs fixes
- [ ] ❌ Major issues - needs debugging

### Notes:
[Add any observations, errors, or issues here]
```

---

## 🎉 When All Tests Pass

**Congratulations! Your attendance system is:**
- ✅ Fully functional
- ✅ Production-ready
- ✅ Tested and verified
- ✅ Ready for real users

**Next steps:**
1. Deploy backend to production server
2. Build release APK/IPA
3. Distribute to employees
4. Monitor for issues
5. Gather user feedback

---

**Happy Testing! 🚀**
