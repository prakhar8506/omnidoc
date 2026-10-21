import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env/app_env.dart';
import 'trainer_offer.dart';

class TrainerIntro {
  const TrainerIntro({
    required this.trainerId,
    required this.trainerName,
    required this.status,
    required this.savedOnlyOnPhone,
  });

  final String trainerId;
  final String trainerName;
  final String status;
  final bool savedOnlyOnPhone;
}

class TrainerRequestView {
  const TrainerRequestView({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.city,
    required this.tracks,
    required this.note,
    required this.status,
  });

  final String id;
  final String userName;
  final String userEmail;
  final String city;
  final List<String> tracks;
  final String note;
  final String status;

  factory TrainerRequestView.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'];
    return TrainerRequestView(
      id: (json['id'] ?? '').toString(),
      userName: (json['user_name'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      tracks: rawTracks is List ? rawTracks.map((e) => e.toString()).toList() : const [],
      note: (json['note'] ?? '').toString(),
      status: (json['status'] ?? 'requested').toString(),
    );
  }
}

class TrainerService {
  static const offline =
      'The trainer desk is not reachable. Your request is saved on this phone.';

  static Future<List<TrainerOffer>> list() async {
    try {
      final data = await _call({'action': 'list'});
      final raw = data['trainers'];
      if (raw is! List) return openingTrainerRoster;
      final parsed = raw
          .whereType<Map>()
          .map((row) => TrainerOffer.fromJson(Map<String, dynamic>.from(row)))
          .where((offer) => offer.id.isNotEmpty && offer.monthlyRateInr > 0)
          .toList();
      return parsed.isEmpty ? openingTrainerRoster : parsed;
    } catch (_) {
      return openingTrainerRoster;
    }
  }

  static Future<TrainerIntro> request({
    required String userId,
    required String userName,
    required String userEmail,
    required TrainerOffer trainer,
    required List<String> tracks,
    required String city,
    required String note,
  }) async {
    try {
      final data = await _call({
        'action': 'request',
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'trainer_id': trainer.id,
        'tracks': tracks,
        'city': city,
        'note': note,
      });
      return TrainerIntro(
        trainerId: trainer.id,
        trainerName: trainer.name,
        status: (data['status'] ?? 'requested').toString(),
        savedOnlyOnPhone: false,
      );
    } catch (_) {
      return TrainerIntro(
        trainerId: trainer.id,
        trainerName: trainer.name,
        status: 'saved_on_phone',
        savedOnlyOnPhone: true,
      );
    }
  }

  static Future<List<TrainerRequestView>> desk(String code) async {
    final data = await _call({'action': 'desk', 'desk_code': code.trim()});
    final raw = data['requests'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((row) => TrainerRequestView.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<void> decide({
    required String deskCode,
    required String requestId,
    required String status,
  }) async {
    await _call({
      'action': 'decide',
      'desk_code': deskCode.trim(),
      'request_id': requestId,
      'status': status,
    });
  }

  static Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    if (!AppEnv.isSupabaseConfigured) {
      throw StateError(offline);
    }
    final response = await Supabase.instance.client.functions.invoke(
      'trainer-desk',
      body: body,
    );
    final data = response.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final error = map['error'];
      if (error is String && error.isNotEmpty) throw StateError(error);
      return map;
    }
    throw StateError(offline);
  }
}
