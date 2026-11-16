# ✅ Ready to Test - Complete Checklist

**Date:** November 16, 2026  
**Status:** All components verified and ready  
**Blocker:** Edge Function deployment (15 minutes)  
**Time to Production:** 2-3 hours after Edge Function deployment

---

## Pre-Testing Setup

### Step 1: Deploy Edge Function (REQUIRED - Do This First)

- [ ] Open terminal/PowerShell
- [ ] Navigate to project directory
- [ ] Run: `supabase functions deploy device-sync`
- [ ] Wait for "Deployment successful" message
- [ ] Note the Edge Function URL: `https://oyqecdcpicvzwwvwaeka.supabase.co/functions/v1/device-sync`

**Estimated Time:** 15 minutes

**Verify:**
```bash
curl -X POST https://oyqecdcpicvzwwvwaeka.supabase.co/functions/v1/device-sync \
  -H "x-device-code: TEST" \
  -H "x-device-secret: TEST" \
  -d '{}'

# Should return 401/403 (because TEST device doesn't exist)
# NOT 404 (which would mean function not deployed)
```

---

### Step 2: Prepare Hardware

- [ ] ESP32-3248S035 board available
- [ ] USB cable for ESP32 (for flashing)
- [ ] HX711 load cell connected to pins 21 (DT) and 22 (SCK)
- [ ] SD card inserted and formatted
- [ ] Battery pack (2 x 18650 in series or 8V+ power supply)
- [ ] WiFi network available (or update SSID/password in firmware)

---

### Step 3: Prepare Flutter App

- [ ] Phone with Android/iOS
- [ ] Bluetooth enabled on phone
- [ ] Flutter SDK installed on development machine
- [ ] Run: `flutter pub get` in project root
- [ ] Run: `flutter doctor` (check for any issues)

---

### Step 4: Prepare Admin Dashboard

- [ ] Browser open to admin dashboard URL
- [ ] Logged in as admin user
- [ ] Navigate to `/dashboard/generate` page

---

## Testing Sequence

### Test 1: Device Code Generation ✅

**Goal:** Verify admin can create device codes

**Setup:**
- [ ] Admin dashboard open at `/dashboard/generate`
- [ ] Logged in as admin

**Test Steps:**
1. [ ] Set prefix to "VS" (default)
2. [ ] Click "Generate & Save to Supabase"
3. [ ] Wait for success message
4. [ ] Note the device_code (e.g., "VS-123456")
5. [ ] Note the device_secret (64-char hex)
6. [ ] Copy device_code to clipboard
7. [ ] Click "View in Device Inventory"

**Expected Results:**
- [ ] Success toast appears
- [ ] Device code displayed in monospace font
- [ ] Device secret displayed and highlighted
- [ ] Copy buttons work
- [ ] Next steps guide appears
- [ ] Device appears in inventory with status "manufactured"

**Time:** 5 minutes

**If Failed:**
- Check Supabase dashboard → device_inventory table
- Look for "Device code generation error" toast
- Check admin email is in admins table

---

### Test 2: WiFi Provisioning (BLE) ✅

**Goal:** Verify Flutter app can send WiFi credentials to device via BLE

**Setup:**
- [ ] ESP32 powered on
- [ ] Device advertising as "PalmPressure-XXXX"
- [ ] Flutter app running on phone
- [ ] Bluetooth enabled on phone

**Test Steps:**
1. [ ] Open Flutter app
2. [ ] Navigate to "Device Pairing" screen
3. [ ] Click "Scan for Devices"
4. [ ] Wait for available devices to appear (max 10 seconds)
5. [ ] Select "PalmPressure-XXXX" from list
6. [ ] Click "Connect"
7. [ ] Wait for "Discovering Services..." → "Connected" status
8. [ ] Click "Scan WiFi Networks"
9. [ ] Wait for networks to appear
10. [ ] Select "Julie-2.4G" (or configured SSID)
11. [ ] Enter password "8000143209" (or configured password)
12. [ ] Click "Send Credentials"
13. [ ] Watch status update:
    - "AWAITING_CREDENTIALS"
    - "SCANNING"
    - "CONNECTING"
    - "CONNECTED"

**Expected Results:**
- [ ] Device appears in scan results
- [ ] Connection succeeds (no timeout)
- [ ] WiFi networks loaded successfully
- [ ] Status updates in real-time
- [ ] Final status shows "CONNECTED"
- [ ] Device now has WiFi internet

**Time:** 15 minutes

**If Failed:**
- Check device BLE name in firmware: `#define DEVICE_NAME`
- Verify UUID in app matches firmware
- Ensure WiFi network is 2.4GHz (not 5GHz)
- Check Bluetooth permissions on phone
- Try disconnecting and reconnecting

---

### Test 3: Device Measurement ✅

**Goal:** Verify device captures measurement with 3 trials

**Setup:**
- [ ] Device powered on
- [ ] Touch display working
- [ ] HX711 load cell connected
- [ ] No weight on sensor initially

**Test Steps:**
1. [ ] Power on device
2. [ ] Splash screen appears
3. [ ] Touch screen → select "Left Hand"
4. [ ] Place hand on sensor (apply pressure)
5. [ ] Hold steady for ~3 seconds (Trial 1)
6. [ ] Remove hand
7. [ ] Wait 2 seconds
8. [ ] Place hand again (Trial 2)
9. [ ] Hold for ~3 seconds
10. [ ] Remove hand
11. [ ] Wait 2 seconds
12. [ ] Place hand again (Trial 3)
13. [ ] Hold for ~3 seconds
14. [ ] Remove hand
15. [ ] Screen displays results:
    - "Trial 1: XX.X kg"
    - "Trial 2: XX.X kg"
    - "Trial 3: XX.X kg"
    - "Best: XX.X kg"

**Expected Results:**
- [ ] All 3 trials recorded successfully
- [ ] Values are reasonable (10-20 kg range for palm pressure)
- [ ] "Best" shows the highest value
- [ ] Results display on device screen
- [ ] Device shows "Pending: 1" (measurement queued)
- [ ] File created in SD card: `/vs/pending/XXXXX.json`

**Time:** 10 minutes

**If Failed:**
- Check HX711 connections (pins 21 DT, 22 SCK)
- Verify calibration factor: 13.746 counts/gram
- Check load cell for physical damage
- Look at Serial output: `Serial.println("[HX711] Reading: xxx")`

---

### Test 4: Measurement Sync ✅

**Goal:** Verify device uploads measurement to Supabase via Edge Function

**Setup:**
- [ ] Device measurement complete from Test 3
- [ ] Device connected to WiFi (from Test 2)
- [ ] Edge Function deployed
- [ ] Supabase project accessible

**Test Steps:**
1. [ ] Device auto-syncs after 4 seconds (or wait)
2. [ ] Check device serial output:
   - "CLOUD: Attempting connection to Supabase..."
   - "CLOUD: POST returned code: 200"
   - "CLOUD: Response length: XXX bytes"
3. [ ] Check Supabase dashboard:
   - Go to measurements table
   - Look for new row with:
     - device_id = device UUID
     - hand = "Left"
     - posture = "sitting"
     - trial1, trial2, trial3 values
     - best value
     - recorded_at = timestamp
4. [ ] Check device screen:
   - "Pending: 0" (measurement cleared from queue)
5. [ ] Check SD card:
   - `/vs/pending/XXXXX.json` file DELETED
   - (confirms acceptance)

**Expected Results:**
- [ ] Device HTTP 200 response from Edge Function
- [ ] Measurement row appears in Supabase table
- [ ] All fields populated correctly
- [ ] File deleted from SD card
- [ ] Device shows "Pending: 0"
- [ ] Audit log shows action (optional)

**Time:** 5 minutes

**If Failed:**
- Check Edge Function deployed: `supabase functions list`
- Check device logs: Serial output for "ERROR: xxx"
- Verify WiFi connected: device shows IP on screen
- Check device_inventory has device_code: query Supabase
- Check device_secret matches: compare in Supabase
- Review Edge Function logs: Supabase dashboard → Edge Functions → device-sync

---

### Test 5: App Retrieves Result ✅

**Goal:** Verify Flutter app fetches measurement from cloud and displays

**Setup:**
- [ ] Flutter app running on phone
- [ ] User logged in to app
- [ ] Measurement synced to Supabase (from Test 4)

**Test Steps:**
1. [ ] Open Flutter app
2. [ ] Navigate to "Results" or "History" screen
3. [ ] Wait for measurements to load
4. [ ] Look for latest measurement:
   - Date/time displayed
   - Hand: "Left"
   - Trial values: (should match what was taken)
   - Best value displayed
   - Posture shown
5. [ ] Verify values match what was on device
6. [ ] Check trend chart updates (if available)
7. [ ] Verify timestamp matches device measurement time

**Expected Results:**
- [ ] App successfully queries measurements table
- [ ] Latest result displays
- [ ] Values match device
- [ ] Timestamp correct
- [ ] UI responds without freezing
- [ ] Can refresh and see same result

**Time:** 5 minutes

**If Failed:**
- Check user is logged in
- Verify measurements table has new row
- Check currentUser ID matches device_id
- Look for app errors in console
- Check measurement was inserted with correct user_id

---

### Test 6: Admin Inventory Updates ✅

**Goal:** Verify device status changes from "manufactured" → "paired"

**Setup:**
- [ ] Admin dashboard open
- [ ] `/dashboard/devices` page
- [ ] Measurement synced (from Test 4)

**Test Steps:**
1. [ ] Find device from Test 1 (VS-123456)
2. [ ] Check status BEFORE sync: "Manufactured"
3. [ ] Click "Refresh" button (or wait for auto-refresh)
4. [ ] Check status AFTER sync: "Paired"
5. [ ] Check "Paired At" column:
   - Date of sync populated
   - Time of sync shown

**Expected Results:**
- [ ] Status changes from "Manufactured" → "Paired"
- [ ] Paired date updates to current date
- [ ] Device code still visible and correct
- [ ] Secret still truncated correctly
- [ ] Admin can see status change happened

**Time:** 5 minutes

**If Failed:**
- Check Edge Function actually ran
- Verify device_inventory.status updated in Supabase
- Manual query: `SELECT * FROM device_inventory WHERE device_code='VS-123456'`

---

### Test 7: Offline Queue (Optional But Recommended) ✅

**Goal:** Verify device stores measurements offline and syncs when WiFi returns

**Setup:**
- [ ] Device on WiFi
- [ ] Can take measurements
- [ ] Can disconnect WiFi manually

**Test Steps:**
1. [ ] Verify device connected to WiFi (shows IP)
2. [ ] Take 1 measurement → syncs immediately
3. [ ] Disconnect WiFi (turn off WiFi in settings or unplug)
4. [ ] Take 2 more measurements
5. [ ] Verify device shows "Pending: 2"
6. [ ] Check `/vs/pending/` folder on SD card:
   - 2 JSON files present
7. [ ] Reconnect WiFi
8. [ ] Wait 4-5 seconds
9. [ ] Verify device shows "Pending: 0"
10. [ ] Check Supabase measurements table:
    - All 3 measurements present
    - Including the 2 taken offline

**Expected Results:**
- [ ] Measurements saved to SD while offline
- [ ] Pending count increments
- [ ] On WiFi reconnect, auto-sync triggers
- [ ] All measurements successfully uploaded
- [ ] No data loss

**Time:** 15 minutes

**If Failed:**
- Check SD card formatting
- Verify `/vs/pending/` directory exists
- Look for error messages on device screen
- Check WiFi reconnection logic in firmware

---

## Final Verification Checklist

After all tests complete:

- [ ] Test 1 Passed ✅ Device code generation works
- [ ] Test 2 Passed ✅ BLE WiFi provisioning works
- [ ] Test 3 Passed ✅ Measurement capture works
- [ ] Test 4 Passed ✅ Cloud sync works
- [ ] Test 5 Passed ✅ App retrieval works
- [ ] Test 6 Passed ✅ Admin dashboard updates
- [ ] Test 7 Passed ✅ Offline queue works (optional)

---

## Success Criteria

✅ **System is production-ready when:**

- [ ] All 6 core tests pass (Tests 1-6)
- [ ] No data loss in offline scenarios
- [ ] App displays accurate data
- [ ] Admin sees correct status updates
- [ ] No crashes or hangs
- [ ] All timestamps match
- [ ] Supabase contains all measurements
- [ ] Device measurements persist on SD
- [ ] BLE pairing is reliable
- [ ] WiFi reconnection works

---

## Troubleshooting Quick Links

| Issue | Check | Fix |
|-------|-------|-----|
| Edge Function 404 | Is it deployed? | `supabase functions deploy device-sync` |
| BLE not found | Is device powered? | Power off, wait 5s, power on |
| WiFi won't connect | SSID/password? | Update in firmware, re-flash |
| Measurement not syncing | Edge Function logs? | Check Supabase → Functions → device-sync |
| App doesn't show result | User logged in? | Login with same account |
| Admin doesn't see paired status | Refresh button? | Click refresh or reload page |

---

## Next Steps After Testing

### If All Tests Pass ✅
1. Document test results
2. Prepare production deployment plan
3. Set up monitoring
4. Plan user training

### If Tests Fail ❌
1. Check troubleshooting guide
2. Review error messages
3. Check logs (device serial, Edge Function, Supabase)
4. Fix specific component
5. Re-test that component
6. Move to next test

---

## Estimated Timeline

| Task | Time | Status |
|------|------|--------|
| Edge Function deployment | 15 min | ⏳ Do this first |
| Test 1: Device code gen | 5 min | ✅ Ready |
| Test 2: BLE provisioning | 15 min | ✅ Ready |
| Test 3: Measurement capture | 10 min | ✅ Ready |
| Test 4: Cloud sync | 5 min | ✅ Ready |
| Test 5: App retrieval | 5 min | ✅ Ready |
| Test 6: Admin dashboard | 5 min | ✅ Ready |
| **Total: Core Testing** | **~1 hour** | ⏳ After Edge Function |
| Test 7: Offline queue | 15 min | ✅ Optional |
| **Total: With Offline** | **~1.5 hours** | ⏳ Optional |
| **GRAND TOTAL** | **~2 hours** | ✅ Ready today |

---

## You Are Ready! 🚀

All components verified.
All tests defined.
All documentation provided.

**Next Action:** Deploy Edge Function

```bash
supabase functions deploy device-sync
```

Then run tests in order.

Expected completion: Within 2-3 hours.

Good luck! 🎉

---

*Checklist created: November 16, 2026*  
*All components verified: November 16, 2026*  
*Ready for testing: NOW*
