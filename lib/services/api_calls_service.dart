import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:vital_step/Model/Assessment.dart';
import 'package:vital_step/Model/Comment.dart';
import 'package:vital_step/Model/accounts.dart';
import 'package:vital_step/Model/test.dart';
import 'package:vital_step/app/app.dialogs.dart';
import 'package:vital_step/app/app.locator.dart';
import 'package:vital_step/app/app.logger.dart';
import 'package:vital_step/app/app.router.dart';
import 'package:vital_step/main.dart';

class ApiCallsService {
  final box = GetStorage();
  final _logger = getLogger("ApiCallsService");
  final _dialogService = locator<DialogService>();

  // ── Assessments ──────────────────────────────────────────────────────────

  Future<List<Assessment>> getAllUserAssessments(
      {String? patientUserId}) async {
    try {
      final uid = patientUserId ?? patientSupabaseClient.auth.currentUser?.id;
      if (uid == null) return [];

      final data = await patientSupabaseClient
          .from('assessments')
          .select()
          .order('created_at', ascending: false);

      return (data as List).map((e) => Assessment.fromJson(e)).toList();
    } catch (e) {
      _logger.e('getAllUserAssessments error: $e');
      return [];
    }
  }

  // ── Tests ─────────────────────────────────────────────────────────────────

  Future<List<Test>> getAllUserTests() async {
    try {
      final uid = patientSupabaseClient.auth.currentUser?.id;
      if (uid == null) return [];

      final data = await patientSupabaseClient
          .from('measurements')
          .select()
          .eq('user_id', uid)
          .order('recorded_at', ascending: true);

      return (data as List).map((e) => _mapToTest(e)).toList();
    } catch (e) {
      _logger.e('getAllUserTests error: $e');
      return [];
    }
  }

  Future<Test> getLastTest() async {
    final tests = await getAllUserTests();
    if (tests.isNotEmpty) return tests.last;
    throw Exception('No tests found');
  }

  Future<List<Test>> getAllAssessmentTests({required int assessmentId}) async {
    try {
      final data = await patientSupabaseClient
          .from('measurements')
          .select()
          .eq('assessment_id', assessmentId.toString())
          .order('recorded_at', ascending: true);

      return (data as List).map((e) => _mapToTest(e)).toList();
    } catch (e) {
      _logger.e('getAllAssessmentTests error: $e');
      return [];
    }
  }

  Future<Map<String, Test?>> getHandsValues() async {
    try {
      final uid = patientSupabaseClient.auth.currentUser?.id;
      if (uid == null) return {'Left': null, 'Right': null};

      final leftData = await patientSupabaseClient
          .from('measurements')
          .select()
          .eq('user_id', uid)
          .eq('hand', 'Left')
          .order('recorded_at', ascending: false)
          .limit(1);

      final rightData = await patientSupabaseClient
          .from('measurements')
          .select()
          .eq('user_id', uid)
          .eq('hand', 'Right')
          .order('recorded_at', ascending: false)
          .limit(1);

      return {
        'Left': (leftData as List).isNotEmpty ? _mapToTest(leftData[0]) : null,
        'Right':
            (rightData as List).isNotEmpty ? _mapToTest(rightData[0]) : null,
      };
    } catch (e) {
      _logger.e('getHandsValues error: $e');
      return {'Left': null, 'Right': null};
    }
  }

  Future<void> deleteTest({required int id}) async {
    try {
      await patientSupabaseClient
          .from('measurements')
          .delete()
          .eq('id', id.toString());
      Fluttertoast.showToast(msg: 'Test deleted successfully');
    } catch (e) {
      _logger.e('deleteTest error: $e');
      Fluttertoast.showToast(msg: 'Unable to delete the test');
    }
  }

  // ── Assessment Queue (by assessment ID) ──────────────────────────────────

  /// Returns device IDs currently in the queue for a specific assessment.
  /// Used by test-taking flow to poll until the queue clears.
  Future<List<String>> getAssessmentQueue(
      {required String assessmentId}) async {
    try {
      final data = await patientSupabaseClient
          .from('assessment_queue')
          .select('id')
          .eq('assessment_id', int.tryParse(assessmentId) ?? 0)
          .eq('status', 'pending');

      return (data as List).map((q) => q['id'].toString()).toList();
    } catch (e) {
      _logger.e('getAssessmentQueue error: $e');
      return [];
    }
  }

  // ── Queue ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, int>>> getUserQueue() async {
    try {
      final uid = patientSupabaseClient.auth.currentUser?.id;
      if (uid == null) return [];

      // Get patient_id from patients table
      final patientData = await patientSupabaseClient
          .from('patients')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();

      if (patientData == null) return [];
      final patientId = patientData['id'] as String;

      final data = await patientSupabaseClient
          .from('assessment_queue')
          .select('id, assessment_id')
          .eq('patient_id', patientId)
          .eq('status', 'pending');

      return (data as List).map((q) {
        return {
          'assessmentId': (q['assessment_id'] as int?) ?? 0,
          'queueId': (q['id'] as int?) ?? 0,
        };
      }).toList();
    } catch (e) {
      _logger.e('getUserQueue error: $e');
      return [];
    }
  }

  Future<void> createTestQueue({
    required Assessment assessment,
    required String hand,
    required String deviceId,
  }) async {
    try {
      final uid = patientSupabaseClient.auth.currentUser?.id;
      if (uid == null) return;

      final patientData = await patientSupabaseClient
          .from('patients')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();

      if (patientData == null) return;
      final patientId = patientData['id'] as String;

      await patientSupabaseClient.from('assessment_queue').insert({
        'patient_id': patientId,
        'assessment_id': assessment.id,
        'hand': hand,
        'posture': assessment.posture,
        'device_id': deviceId,
        'status': 'pending',
      });
      _logger.i('Queue entry created');
    } catch (e) {
      _logger.e('createTestQueue error: $e');
    }
  }

  Future<void> cancelAssessment({required int queueId}) async {
    try {
      await patientSupabaseClient
          .from('assessment_queue')
          .delete()
          .eq('id', queueId);
      Fluttertoast.showToast(msg: 'Assessment cancelled successfully');
      NavigationService().clearStackAndShow(Routes.homeView,
          arguments: const HomeViewArguments(firstPage: 1));
    } catch (e) {
      _logger.e('cancelAssessment error: $e');
      Fluttertoast.showToast(msg: 'Error cancelling assessment');
    }
  }

  Future<int> getQueueId(Assessment assessment) async {
    final queue = await getUserQueue();
    for (final item in queue) {
      if (item['assessmentId'] == assessment.id) {
        return item['queueId']!;
      }
    }
    throw Exception('Queue Id not found');
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<List<Comment>> getComments({required int assessmentId}) async {
    try {
      final data = await patientSupabaseClient
          .from('remarks')
          .select()
          .eq('assessment_id', assessmentId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => Comment.fromJson(e)).toList();
    } catch (e) {
      _logger.e('getComments error: $e');
      return [];
    }
  }

  // ── Specialists (for patient side) ───────────────────────────────────────

  Future<List<Accounts>> getSpecialists() async {
    try {
      final uid = patientSupabaseClient.auth.currentUser?.id;
      if (uid == null) return [];

      final patientData = await patientSupabaseClient
          .from('patients')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();

      if (patientData == null) return [];
      final patientId = patientData['id'] as String;

      final data = await patientSupabaseClient
          .from('specialist_access')
          .select('specialist_id, specialists(id, name, email)')
          .eq('patient_id', patientId);

      return (data as List).map((row) {
        final s = row['specialists'] as Map<String, dynamic>? ?? {};
        return Accounts.fromJson({
          'id': s['id'],
          'name': s['name'],
          'email': s['email'],
        });
      }).toList();
    } catch (e) {
      _logger.e('getSpecialists error: $e');
      return [];
    }
  }

  // ── Password reset ────────────────────────────────────────────────────────

  Future<void> sendResetPasswordEmail({
    required String email,
    required String userType,
  }) async {
    try {
      await patientSupabaseClient.auth.resetPasswordForEmail(email);
      Fluttertoast.showToast(msg: 'Reset password email sent');
    } catch (e) {
      _logger.e('sendResetPasswordEmail error: $e');
      _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Error',
        description: 'Could not send reset email: $e',
      );
    }
  }

  /// Maps a Supabase `measurements` row to the [Test] model.
  /// Handles UUID → int conversion using hashCode for compat with old views.
  Test _mapToTest(Map<String, dynamic> e) {
    return Test(
      id: e['id']?.toString().hashCode ?? 0,
      userId: e['user_id']?.toString().hashCode ?? 0,
      deviceId: e['device_id']?.toString().hashCode ?? 0,
      assestmentId: e['assessment_id']?.toString().hashCode ?? 0,
      posture: e['posture'] as String? ?? '',
      trial1: (e['trial1'] ?? e['trial_1'] ?? '0').toString(),
      trial2: (e['trial2'] ?? e['trial_2'] ?? '0').toString(),
      trial3: (e['trial3'] ?? e['trial_3'] ?? '0').toString(),
      hand: e['hand'] as String? ?? '',
      createdAt: e['recorded_at'] != null
          ? DateTime.parse(e['recorded_at'])
          : e['created_at'] != null
              ? DateTime.parse(e['created_at'])
              : DateTime.now(),
    );
  }

  // ── Devices ───────────────────────────────────────────────────────────────

  Future<List<String>> getAllPossibleDevices() async {
    try {
      final data = await patientSupabaseClient
          .from('device_inventory')
          .select('device_code')
          .eq('status', 'manufactured');

      return (data as List).map((d) => d['device_code'] as String).toList();
    } catch (e) {
      _logger.e('getAllPossibleDevices error: $e');
      return [];
    }
  }
}
