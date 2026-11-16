import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vital_step/Model/Device.dart';
import 'package:vital_step/Model/profile.dart';
import 'package:vital_step/app/app.logger.dart';
import 'package:vital_step/main.dart';

class AccountsService {
  final box = GetStorage();
  final _logger = getLogger("AccountsService");

  Future<Profile> getAccountDetails({String? patientUserId}) async {
    try {
      final uid = patientUserId ?? patientSupabaseClient.auth.currentUser?.id;
      if (uid == null) throw Exception('No user ID available');

      // Fetch minimal profile (id, name, email, user_type, dominant_hand)
      final profileData = await patientSupabaseClient
          .from('profiles')
          .select('id, name, email, user_type, dominant_hand')
          .eq('id', uid)
          .single();

      // Fetch full clinical data from patients table
      final patientData = await patientSupabaseClient
          .from('patients')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      final devicesData = await patientSupabaseClient
          .from('devices')
          .select()
          .eq('user_id', uid);

      // Merge both tables — patients columns take precedence for clinical data
      return Profile.fromJson({
        ...profileData,
        if (patientData != null) ...patientData,
        // Map patients column names to Profile model field names
        'countryCode': patientData?['country_code'] ?? '',
        'weight': patientData?['weight_kg'] ?? 0,
        'height': patientData?['height_cm'] ?? 0,
        'dob': patientData?['date_of_birth'],
        'dominant_hand': profileData['dominant_hand'] ?? patientData?['dominant_hand'],
        'palm_length': patientData?['palm_length_mm'],
        'palm_width': patientData?['palm_width_mm'],
        'knuckles_length': patientData?['knuckle_length_mm'],
        'phone': patientData?['phone'],
        'city': patientData?['city'],
        'country': patientData?['country'],
        'address': patientData?['address'],
        'pincode': patientData?['pincode'],
        'device': devicesData,
      });
    } catch (e) {
      _logger.e('getAccountDetails error: $e');
      rethrow;
    }
  }

  Future<List<Device>> getDevices() async {
    try {
      final userId = patientSupabaseClient.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await patientSupabaseClient
          .from('devices')
          .select()
          .eq('user_id', userId);

      return (data as List).map((d) => Device.fromJson(d)).toList();
    } catch (e) {
      _logger.e('getDevices error: $e');
      return [];
    }
  }

  Future<void> addDevice({
    required String deviceCode,
    required String deviceName,
  }) async {
    try {
      final token = patientSupabaseClient.auth.currentSession?.accessToken;
      if (token == null) throw Exception('No authentication token');

      // Call the pair-device edge function to:
      // 1. Verify device exists in device_inventory
      // 2. Update device_inventory.paired_user_id
      // 3. Create app-level pairing record
      final response = await patientSupabaseClient.functions.invoke(
        'pair-device',
        body: {
          'device_code': deviceCode,
          'device_name': deviceName,
        },
      );

      if (response.data is! Map) {
        throw Exception('Invalid response from pair-device');
      }

      final Map<String, dynamic> result = response.data as Map<String, dynamic>;

      if (result['ok'] != true || result['paired'] != true) {
        throw Exception(result['error'] ?? 'Failed to pair device');
      }

      _logger.i('Device paired successfully: $deviceCode');
    } catch (e) {
      _logger.e('addDevice error: $e');
      throw Exception('Failed to pair device: $e');
    }
  }

  Future<bool> killApp() async {
    try {
      final response = await Supabase.instance.client
          .from("vitalStep")
          .select()
          .eq("id", 1)
          .single()
          .timeout(const Duration(seconds: 3));
      return response['kill_switch'] ?? false;
    } catch (e) {
      _logger.w("Kill switch check skipped: $e");
      return false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = patientSupabaseClient.auth.currentUser?.id;
      if (userId == null) return;

      await patientSupabaseClient.from('profiles').delete().eq('id', userId);
      await patientSupabaseClient.auth.signOut();
      await box.erase();
      Fluttertoast.showToast(msg: "Account deleted successfully");
    } catch (e) {
      _logger.e('deleteAccount error: $e');
      Fluttertoast.showToast(
          msg: "Unable to delete the account, please try again later.");
    }
  }
}
