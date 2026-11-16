# 🔄 CODE MIGRATION PLAN - Old Digital Ocean → New Supabase

## Overview

You have a working Flutter app connected to old Digital Ocean database. We need to:

1. **Identify all features** from old codebase
2. **Reuse existing code** (screens, services, models)
3. **Update Supabase schema** (if needed) to match your features
4. **Adapt services** to work with new Supabase backend
5. **Keep all existing features** (nothing removed)

---

## 📋 STEP 1: Analyze Old Repository

**Old Repo**: https://github.com/chetan0021/Multivitalstep-ML-Trained

**Your Task**: Clone/examine this repo to identify:
- [ ] What tables are used in old database?
- [ ] What UI screens exist?
- [ ] What services/providers are implemented?
- [ ] What features are critical?

**I Cannot Access**: Can't fetch the old repo directly due to network restrictions.

**What I Need From You**:
1. Tell me the structure of old database (table names, columns)
2. List the main screens/features in old app
3. Tell me which services handle data (auth, measurements, assessments, etc.)

---

## ✅ STEP 2: Current App Structure (What Exists)

### Flutter App - Confirmed Present:

**Location**: `lib/` directory

**Main Components**:
- ✅ `main.dart` - Entry point with Supabase init
- ✅ `app/` - Stacked MVVM setup (router, dialogs, locator)
- ✅ `services/` - Business logic layer
- ✅ `ui/` - Flutter screens
- ✅ `Model/` - Data models
- ✅ `supabase_service.dart` - Supabase integration

**Existing Services** (from `main.dart`):
- ✅ SupabaseService - Already initialized
- ✅ DeviceSelectionService - For device selection
- ✅ NotificationsService - For push notifications
- ✅ Authentication - Via Supabase

---

## 🗄️ STEP 3: Current Supabase Schema

**Your New Supabase Project**: `oyqecdcpicvzwwvwaeka`

**Existing Tables** (from setup guides):
```
✅ public.users (id, email, display_name, role, created_at)
✅ public.devices (id, user_id, device_code, device_secret, paired, online, battery_pct, last_sync)
✅ public.measurements (id, device_id, user_id, hand, posture, trial_1/2/3, peak, average, recorded_at)
✅ public.insights (id, device_id, user_id, severity, asymmetry, trend, title, body, tips)
✅ public.profiles (id, name, email, user_type - 'Patient' or from auth.users)
✅ public.specialists (id, user_id, name, email, phone, clinic_name, credentials)
✅ public.patients (id, user_id, name, email, phone, patient_code, DOB, gender, measurements)
✅ public.specialist_access (id, specialist_id, patient_id, access_level, linked_at)
✅ public.assessments (id, assessment_type, description, recommended_frequency_days)
✅ public.assessment_queue (id, patient_id, assessment_id, hand, posture, status, device_id, title)
✅ public.patient_readings (id, patient_id, latest_left/right, asymmetry, severity_level, totals)
✅ public.research_patients (id, patient_id, research_cohort, enrollment_date, target_completion)
✅ public.kill_switch (id, feature_name, is_enabled, description)
✅ public.device_audit (id, admin_id, action, device_code, details)
✅ public.device_inventory (id, device_code, device_secret, status, paired_user_id, notes)
```

---

## 🔍 STEP 4: What Features Need to Come From Old Repo?

Based on your requirements diagram, I need you to tell me:

### PATIENT SIDE:
- [ ] User login/signup screens (exist in old repo?)
- [ ] Dashboard & graphs (exist in old repo?)
- [ ] Test/assessment screen (exist in old repo?)
- [ ] Profile settings (exist in old repo?)
- [ ] Measurement history (exist in old repo?)
- [ ] All other UI screens?

### SPECIALIST SIDE:
- [ ] Specialist login/signup? (likely NOT in old repo)
- [ ] Specialist dashboard? (likely NOT in old repo)
- [ ] Patient management? (likely NOT in old repo)
- [ ] Test assignment? (likely NOT in old repo)
- [ ] Patient viewing? (may exist in old repo)

### DEVICE:
- [ ] Device pairing? (exist in old repo?)
- [ ] Test taking? (on device firmware, not app)
- [ ] Device UI? (in firmware code)

---

## 🔧 STEP 5: Required Supabase Schema Updates

**Based on Your Requirements**, here's what MIGHT be missing:

### POSSIBLY NEEDED:

```sql
-- Specialist role extension (may need in auth setup)
-- Check: Does auth.users have role field?
-- Or: Is role stored in public.specialists table only?

-- Assessment-Specialist linking (for assigning tests)
-- Check: Can specialist assign tests? How is this tracked?
-- May need: specialist_id in assessment_queue table

-- QR Code generation (app feature, not schema)
-- Check: Does patient table have qr_code_data column?
-- May need: Add if QR codes must be stored

-- Device-Specialist linking (for access control)
-- Check: Can specialist see device results?
-- May need: Add specialist_id to devices table

-- Test scheduling (if needed)
-- Check: Does assessment_queue track scheduling?
-- May need: scheduled_date, assigned_date fields

-- Offline sync tracking (device feature)
-- Check: How are offline measurements tracked?
-- May need: synced_at, sync_status fields
```

---

## 📝 WHAT I NEED FROM YOU

### IMMEDIATE QUESTIONS:

1. **Old Repository Structure**:
   - What are the main Dart packages in pubspec.yaml?
   - What backend tables were used?
   - What REST endpoints were called?
   - List all screens/pages that existed

2. **Features to Preserve**:
   - List all working screens from old app
   - What features are CRITICAL?
   - What can be deprioritized?

3. **Specialist Features**:
   - Does old repo have specialist functionality?
   - If not, are specialist features new requirements?
   - Should specialist be built from scratch?

4. **Current Supabase**:
   - Are all 13 tables you listed properly set up?
   - Do RLS policies work correctly?
   - Any errors when querying?
   - Are Edge Functions deployed?

5. **Database Mapping**:
   - How did old Digital Ocean maps to current Supabase?
   - Any field name changes needed?
   - Any data type conversions needed?

---

## 🎯 PROPOSED MIGRATION STEPS

### Phase 1: INVENTORY (You Do This)
1. Clone old repo
2. Identify all Dart files/screens
3. List all backend API calls
4. Note all data models
5. **Send me this list**

### Phase 2: MAPPING (I Do This)
1. Match old screens to new Supabase tables
2. Identify missing Supabase tables/fields
3. Create migration guide
4. List code that needs changes

### Phase 3: SUPABASE SETUP (You Do This)
1. Add missing tables (if needed) to Supabase
2. Verify RLS policies
3. Test with sample data
4. **Confirm readiness**

### Phase 4: CODE MIGRATION (I Do This)
1. Copy working screens from old repo
2. Update Supabase queries
3. Keep all features intact
4. Update colors (teal/coral)
5. Test all screens

### Phase 5: NEW FEATURES (I Do This)
1. Build specialist module (new)
2. Build QR code system (new)
3. Build test assignment (new)
4. Integrate with device

---

## ❌ WHAT NOT TO DO

- ❌ DO NOT delete old code - copy and adapt
- ❌ DO NOT change database schema without asking
- ❌ DO NOT remove any working features
- ❌ DO NOT skip the specialist module if it's required
- ❌ DO NOT skip RLS policy verification

---

## ✅ WHAT TO DO NEXT

**You Should**:
1. Clone: https://github.com/chetan0021/Multivitalstep-ML-Trained
2. List all screens/features
3. Send me the list
4. Tell me about any database structure from old app

**Then I Will**:
1. Map old code to new Supabase
2. Identify gaps in Supabase schema
3. Tell you what to add to Supabase (if anything)
4. Create detailed migration document

---

## 📞 CRITICAL QUESTION

**Are all 13 Supabase tables currently created and working in your Supabase instance?**

Current tables I see configured:
1. users ✅
2. devices ✅
3. measurements ✅
4. insights ✅
5. profiles ✅
6. specialists ✅
7. patients ✅
8. specialist_access ✅
9. assessments ✅
10. assessment_queue ✅
11. patient_readings ✅
12. research_patients ✅
13. kill_switch ✅
14. device_audit ✅
15. device_inventory ✅

**VERIFY**: Go to Supabase dashboard → SQL Editor → Run:
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
```

Send me the output. If any tables are missing, I'll tell you the SQL to create them.

---

## READY WHEN YOU ARE

Once you provide:
1. Old repo feature list
2. Supabase table verification
3. Any missing schema items

I can create the **FULL MIGRATION GUIDE** with exact code changes needed.

**No Surprises. No Deviations. Just Code Migration.**
