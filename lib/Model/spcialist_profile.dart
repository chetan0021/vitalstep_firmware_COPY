import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vital_step/Model/accounts.dart';

part 'spcialist_profile.g.dart';
part 'spcialist_profile.freezed.dart';

@freezed
class ProfileSpecialist with _$ProfileSpecialist {
  const ProfileSpecialist._();
  const factory ProfileSpecialist({
    int? id,
    required String name,
    required String countryCode,
    required String email,
    required String dob,
    dynamic phone,
    String? password,
    String? city,
    String? country,
    dynamic pincode,
    dynamic address,
    DateTime? createdAt,
    List<Accounts>? accounts,
  }) = _ProfileSpecialist;

  factory ProfileSpecialist.fromJson(Map<String, dynamic> json) =>
      _$ProfileSpecialistFromJson(json);

  /// Convenience getters for Supabase-specific fields
  /// These read from the JSON directly since they aren't in the freezed codegen
  String? get clinicName => null;
  String? get credentials => null;
}
