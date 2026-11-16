# Deploy Updated Edge Function

## Changes Made

1. **Changed from `.upsert()` to `.insert()`**
   - Old code had `onConflict: "client_id"` which may not be set up properly
   - New code uses simple `.insert()` which is more reliable

2. **Added better error logging**
   - Now logs measurement data when insert fails
   - Helps debug issues

## Deploy Steps

1. Go to https://supabase.com
2. Open project: oyqecdcpicvzwwvwaeka
3. Go to **Edge Functions** → **device-sync**
4. Click **Code** tab
5. Replace ALL the code with the updated version from:
   `supabase/functions/device-sync/index.ts`
6. Click **Deploy**

## Verify Deployment

```powershell
cd "c:\Users\Chetan\Documents\vitalstep_with_firmware-master"
powershell -ExecutionPolicy Bypass -File test_device_simple.ps1
```

Expected response: `"accepted": 2` (both measurements accepted)

## If Still Failing

Check Supabase logs:
1. Go to Edge Functions → device-sync
2. Click **Logs** tab
3. Look for error messages about measurements table
