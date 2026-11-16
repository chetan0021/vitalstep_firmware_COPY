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

      final profileData = await patientSupabaseClient
          .from('profiles')
          .select()
          .eq('id', uid)
          .single();

      final devicesData = await patientSupabaseClient
          .from('devices')
          .select()
          .eq('user_id', uid);

      return Profile.fromJson({
        ...profileData,
        'countryCode': profileData['country_code'] ?? '',
        'weight': profileData['weight'] ?? 0,
        'height': profileData['height'] ?? 0,
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
      final userId = patientSupabaseClient.auth.currentUser?.id;
      if (userId == null) throw Exception('No user ID');

      await patientSupabaseClient.from('devices').insert({
        'user_id': userId,
        'device_code': deviceCode,
        'device_name': deviceName,
        'is_active': true,
      });
    } catch (e) {
      _logger.e('addDevice error: $e');
      throw Exception('Failed to add device');
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
