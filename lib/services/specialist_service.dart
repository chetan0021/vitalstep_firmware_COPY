import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:vital_step/Model/accounts.dart';
import 'package:vital_step/Model/spcialist_profile.dart';
import 'package:vital_step/app/app.dialogs.dart';
import 'package:vital_step/app/app.locator.dart';
import 'package:vital_step/app/app.logger.dart';
import 'package:vital_step/app/app.router.dart';
import 'package:vital_step/main.dart';
import 'package:vital_step/services/login_service.dart';

class SpecialistService {
  final _logger = getLogger("SpecialistService");
  final box = GetStorage();
  final _loginService = locator<LoginService>();
  final _dialogService = locator<DialogService>();

  Future<ProfileSpecialist> getSpecialistProfile() async {
    final userId = await _loginService.getUserId();
    if (userId == null) throw Exception('No user ID');

    final data = await patientSupabaseClient
        .from('specialists')
        .select()
        .eq('user_id', userId)
        .single();

    return ProfileSpecialist.fromJson(data);
  }

  Future<String?> getSpecialistName() async {
    final profile = await getSpecialistProfile();
    return profile.name;
  }

  /// Returns all patients this specialist has access to.
  Future<List<Accounts>> getAccounts() async {
    final userId = await _loginService.getUserId();
    if (userId == null) return [];

    // Get specialist record
    final specialistData = await patientSupabaseClient
        .from('specialists')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (specialistData == null) return [];
    final specialistId = specialistData['id'] as String;

    // Get access list with patient details
    final accessData = await patientSupabaseClient
        .from('specialist_access')
        .select('patient_id, patients(id, name, email, patient_code)')
        .eq('specialist_id', specialistId);

    return (accessData as List).map((row) {
      final patient = row['patients'] as Map<String, dynamic>? ?? {};
      return Accounts.fromJson({
        'id': patient['id'],
        'name': patient['name'],
        'email': patient['email'],
        'patient_code': patient['patient_code'],
      });
    }).toList();
  }

  /// Add patient to specialist's list using email + patient code.
  Future<void> addPatient({
    required String patientEmail,
    required String patientAccessCode,
  }) async {
    try {
      final userId = await _loginService.getUserId();
      if (userId == null) throw Exception('No user ID');

      // Get specialist ID
      final specialistData = await patientSupabaseClient
          .from('specialists')
          .select('id')
          .eq('user_id', userId)
          .single();
      final specialistId = specialistData['id'] as String;

      // Find patient by email and patient_code
      final patientData = await patientSupabaseClient
          .from('patients')
          .select('id')
          .eq('email', patientEmail)
          .eq('patient_code', patientAccessCode)
          .maybeSingle();

      if (patientData == null) {
        _dialogService.showCustomDialog(
          variant: DialogType.infoAlert,
          title: 'Patient Not Found',
          description: 'No patient found with that email and code.',
        );
        return;
      }

      final patientId = patientData['id'] as String;

      // Create specialist_access record
      await patientSupabaseClient.from('specialist_access').upsert({
        'specialist_id': specialistId,
        'patient_id': patientId,
        'access_level': 'view',
      });

      Fluttertoast.showToast(msg: "Patient added successfully");
    } catch (e) {
      _logger.e('addPatient error: $e');
      Fluttertoast.showToast(msg: "Failed to add patient");
    }
  }

  Future<void> deleteAccountAccess({String? patientId}) async {
    try {
      final userId = await _loginService.getUserId();
      if (userId == null) return;

      final specialistData = await patientSupabaseClient
          .from('specialists')
          .select('id')
          .eq('user_id', userId)
          .single();
      final specialistId = specialistData['id'] as String;

      await patientSupabaseClient
          .from('specialist_access')
          .delete()
          .eq('specialist_id', specialistId)
          .eq('patient_id', patientId!);

      Fluttertoast.showToast(msg: "Patient removed successfully");
      NavigationService().clearStackAndShow(Routes.homeSpecialistView);
    } catch (e) {
      _logger.e('deleteAccountAccess error: $e');
      Fluttertoast.showToast(msg: "Unable to remove patient");
    }
  }

  /// Assign a test to a patient via assessment_queue.
  Future<void> createAssessment(
      String posture, String assessmentType, String patientId) async {
    try {
      // Look up assessment_id from assessments table
      final assessmentData = await patientSupabaseClient
          .from('assessments')
          .select('id')
          .eq('assessment_type', assessmentType)
          .maybeSingle();

      final assessmentId = assessmentData?['id'] as int?;
      if (assessmentId == null) {
        Fluttertoast.showToast(msg: "Assessment type not found");
        return;
      }

      // Determine hand from posture context (default Both / Left)
      await patientSupabaseClient.from('assessment_queue').insert({
        'patient_id': patientId,
        'assessment_id': assessmentId,
        'hand': 'Left',
        'posture': posture,
        'status': 'pending',
        'title': assessmentType,
      });

      Fluttertoast.showToast(msg: "Assessment assigned successfully");
    } catch (e) {
      _logger.e('createAssessment error: $e');
      Fluttertoast.showToast(msg: "Failed to create assessment");
    }
  }

  Future<void> deleteAssessment({required String assessmentId}) async {
    try {
      await patientSupabaseClient
          .from('assessment_queue')
          .delete()
          .eq('id', int.tryParse(assessmentId) ?? 0);
      Fluttertoast.showToast(msg: "Assessment deleted successfully");
    } catch (e) {
      _logger.e('deleteAssessment error: $e');
      Fluttertoast.showToast(msg: "Failed to delete assessment");
    }
  }

  Future<void> addComment({
    required String comment,
    required int assessmentId,
  }) async {
    try {
      final userId = await _loginService.getUserId();
      await patientSupabaseClient.from('remarks').insert({
        'assessment_id': assessmentId,
        'creator_id': userId,
        'content': comment,
      });
      Fluttertoast.showToast(msg: "Comment Added Successfully");
    } catch (e) {
      _logger.e('addComment error: $e');
      throw e;
    }
  }

  Future<void> deleteRemark({required int remarkId}) async {
    try {
      await patientSupabaseClient.from('remarks').delete().eq('id', remarkId);
      Fluttertoast.showToast(msg: "Comment deleted Successfully");
    } catch (e) {
      _logger.e('deleteRemark error: $e');
      Fluttertoast.showToast(msg: "Unable to delete the remark");
    }
  }

  Future<void> updateProfile(ProfileSpecialist info) async {
    try {
      final userId = await _loginService.getUserId();
      if (userId == null) return;

      final updates = info.toJson()
        ..removeWhere((k, v) => v == null || v == '');

      await patientSupabaseClient
          .from('specialists')
          .update(updates)
          .eq('user_id', userId);

      Fluttertoast.showToast(msg: "Profile Updated Successfully");
    } catch (e) {
      _logger.e('updateProfile error: $e');
      _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Error Updating Profile',
        description: 'An error occurred',
      );
    }
  }

  /// Register new specialist (goes into specialist_access pending approval).
  Future<void> signUp(ProfileSpecialist signUpInfo) async {
    try {
      // Auth signup
      final res = await patientSupabaseClient.auth.signUp(
        email: signUpInfo.email,
        password: signUpInfo.password ?? '',
      );

      if (res.user == null) throw Exception('Auth signup failed');
      final userId = res.user!.id;

      // Create profile
      await patientSupabaseClient.from('profiles').upsert({
        'id': userId,
        'email': signUpInfo.email,
        'name': signUpInfo.name,
        'user_type': 'Specialist',
      });

      // Create specialist record
      await patientSupabaseClient.from('specialists').insert({
        'user_id': userId,
        'name': signUpInfo.name,
        'email': signUpInfo.email,
        'phone': signUpInfo.phone?.toString(),
      });

      _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'SignUp Successful',
        description:
            'Your profile has been created. You can now log in as a Specialist.',
      );
    } catch (e) {
      _logger.e('Specialist signUp error: $e');
      _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Error Signing Up',
        description: e.toString(),
      );
    }
  }
}
