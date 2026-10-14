import 'dart:convert';
import '../models/prescription_document.dart';
import '../models/vitals_data.dart';
import '../storage/secure_store.dart';

/// Per-user persisted health profile (isolated by user id).
class UserDataService {
  String _key(String userId) => 'hc_user_data_$userId';

  Future<Map<String, dynamic>> load(String userId) async {
    final raw = await SecureStore.readString(_key(userId));
    if (raw == null || raw.isEmpty) {
      return _emptyProfile();
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> save(String userId, Map<String, dynamic> data) async {
    await SecureStore.writeString(_key(userId), jsonEncode(data));
  }

  /// Removes everything stored on this device for [userId].
  Future<void> purge(String userId) async {
    await SecureStore.delete(_key(userId));
  }

  Map<String, dynamic> _emptyProfile() => {
        'restingHeartRate': 0,
        'sleepDuration': '—',
        'dailySteps': 0.0,
        'bloodOxygen': 0,
        'bloodPressure': '—',
        'lastSyncedTime': DateTime.now().toIso8601String(),
        'medications': <Map<String, dynamic>>[],
        'appointments': <Map<String, dynamic>>[],
        'familyMembers': <Map<String, dynamic>>[],
        'prescriptions': <Map<String, dynamic>>[],
        'unreadNotificationsCount': 0,
        'hasActiveReport': false,
      };

  static List<MedicationItem> medicationsFromJson(List<dynamic>? list) {
    if (list == null) return [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return MedicationItem(
        id: m['id'] as String,
        name: m['name'] as String,
        dosage: m['dosage'] as String? ?? '',
        scheduleTime: m['scheduleTime'] as String? ?? '',
        instruction: m['instruction'] as String? ?? '',
        isTaken: m['isTaken'] as bool? ?? false,
      );
    }).toList();
  }

  static List<Map<String, dynamic>> medicationsToJson(List<MedicationItem> list) {
    return list
        .map((m) => {
              'id': m.id,
              'name': m.name,
              'dosage': m.dosage,
              'scheduleTime': m.scheduleTime,
              'instruction': m.instruction,
              'isTaken': m.isTaken,
            })
        .toList();
  }

  static List<PrescriptionDocument> prescriptionsFromJson(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .map((e) => PrescriptionDocument.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<Map<String, dynamic>> prescriptionsToJson(List<PrescriptionDocument> list) {
    return list.map((e) => e.toJson()).toList();
  }
}
