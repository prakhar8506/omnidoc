import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/health_event.dart';
import '../env/app_env.dart';

/// Abstract contract for backend operations. UI and state layers only interact
/// with this interface, never invoking Supabase client directly.
abstract class HealthBackendRepository {
  bool get isConfigured;
  String? get currentUserId;

  Future<void> initialize();

  // Auth Operations
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    String bloodType = 'Unknown',
  });

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  });

  /// Creates an account and asks Cura to send a greeting.
  ///
  /// Prefers the `welcome-email` function, which opens the account with no
  /// confirmation mail. If that function is unavailable the account is still
  /// created through GoTrue sign-up, so a missing deployment can never leave
  /// people unable to register. Returns null only when no path succeeded.
  Future<PreparedAccount?> prepareAccount({
    required String email,
    required String password,
    required String fullName,
    String bloodType = 'Unknown',
  });

  Future<void> signOut();

  // Data Operations
  Future<int> upsertHealthEvents(String userId, List<HealthEvent> events);
  Future<List<HealthEvent>> fetchHealthEvents(String userId, {String? metric, DateTime? since});

  Future<void> upsertScore({
    required String userId,
    required String scoreType,
    required double value,
    required double confidence,
    required List<Map<String, dynamic>> drivers,
    required Map<String, dynamic> inputs,
    required String modelVersion,
    required DateTime computedForDate,
  });

  Future<void> recordHabitLog({
    required String userId,
    required String behaviorKey,
    required bool value,
    required DateTime loggedAt,
  });

  Future<void> saveJournalEntry({
    required String userId,
    required String content,
    required String entryType,
    required String? mood,
    List<String> tags = const [],
  });

  Future<void> recordCheckIn({
    required String userId,
    required String checkInType,
    required int energy,
    required int soreness,
    required bool illnessFlag,
    required int stress,
    required int sleepQuality,
  });
}

/// Account opened without a Supabase confirmation email.
class PreparedAccount {
  final String userId;
  final bool greeted;

  const PreparedAccount({required this.userId, required this.greeted});
}

/// Production implementation of [HealthBackendRepository] backed by Supabase.
class SupabaseRepository implements HealthBackendRepository {
  SupabaseClient? _client;
  bool _initialized = false;

  SupabaseRepository({SupabaseClient? customClient}) : _client = customClient {
    if (customClient != null) {
      _initialized = true;
    }
  }

  @override
  bool get isConfigured => AppEnv.isSupabaseConfigured || _client != null;

  @override
  String? get currentUserId => _client?.auth.currentUser?.id;

  SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase is not initialized. Check AppEnv.isSupabaseConfigured.');
    }
    return _client!;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (!AppEnv.isSupabaseConfigured) {
      debugPrint('[SupabaseRepository] Running in offline/local-only mode: missing credentials.');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppEnv.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('[SupabaseRepository] Successfully initialized Supabase client.');
    } catch (e) {
      debugPrint('[SupabaseRepository] Initialization failed: $e');
    }
  }

  @override
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    String bloodType = 'Unknown',
  }) async {
    final prepared = await prepareAccount(
      email: email,
      password: password,
      fullName: fullName,
      bloodType: bloodType,
    );
    if (prepared == null) return null;
    return signIn(email: email, password: password);
  }

  @override
  Future<PreparedAccount?> prepareAccount({
    required String email,
    required String password,
    required String fullName,
    String bloodType = 'Unknown',
  }) async {
    if (!isConfigured || _client == null) return null;
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await _client!.functions.invoke(
        'welcome-email',
        body: {
          'email': normalizedEmail,
          'password': password,
          'full_name': fullName.trim(),
          'blood_type': bloodType,
        },
      );
      final data = response.data;
      if (data is Map) {
        final id = data['user_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          return PreparedAccount(userId: id, greeted: data['greeted'] == true);
        }
      }
    } on FunctionException catch (e) {
      final details = e.details?.toString().toLowerCase() ?? '';
      if (e.status == 409 || details.contains('already')) {
        throw Exception('already registered');
      }
      debugPrint('[welcome-email] ${e.status}');
    } catch (e) {
      if (e.toString().toLowerCase().contains('already registered')) rethrow;
      debugPrint('[welcome-email] unavailable');
    }

    return _signUpThroughAuth(
      email: normalizedEmail,
      password: password,
      fullName: fullName,
      bloodType: bloodType,
    );
  }

  /// Fallback registration straight through GoTrue. Used when the welcome
  /// function is not reachable so sign-up still works.
  Future<PreparedAccount?> _signUpThroughAuth({
    required String email,
    required String password,
    required String fullName,
    required String bloodType,
  }) async {
    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName.trim(), 'blood_type': bloodType},
      );
      final user = response.user;
      if (user == null) return null;
      return PreparedAccount(userId: user.id, greeted: false);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('already been registered') ||
          message.contains('user already exists')) {
        throw Exception('already registered');
      }
      debugPrint('[SupabaseRepository] signUp failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[SupabaseRepository] signUp failed');
      return null;
    }
  }

  @override
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!isConfigured || _client == null) return null;
    return await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    if (!isConfigured || _client == null) return;
    await _client!.auth.signOut();
  }

  @override
  Future<int> upsertHealthEvents(String userId, List<HealthEvent> events) async {
    if (!isConfigured || _client == null || events.isEmpty) return 0;

    final rows = events.map((e) {
      return {
        'user_id': userId,
        'metric': e.metric,
        'value': e.value,
        'unit': e.unit,
        'start_time': e.start.toIso8601String(),
        'end_time': e.end.toIso8601String(),
        'source': e.source,
        'source_record_id': e.sourceRecordId,
        'quality': e.quality,
        'model_version': e.modelVersion,
        'metadata': e.metadata,
      };
    }).toList();

    try {
      // Upsert on unique (user_id, source, source_record_id)
      final res = await _client!.from('health_events').upsert(
        rows,
        onConflict: 'user_id,source,source_record_id',
      ).select('id');
      return (res as List).length;
    } catch (e) {
      debugPrint('[SupabaseRepository] upsertHealthEvents error: $e');
      return 0;
    }
  }

  @override
  Future<List<HealthEvent>> fetchHealthEvents(
    String userId, {
    String? metric,
    DateTime? since,
  }) async {
    if (!isConfigured || _client == null) return [];

    try {
      var query = _client!.from('health_events').select().eq('user_id', userId);
      if (metric != null) {
        query = query.eq('metric', metric);
      }
      if (since != null) {
        query = query.gte('start_time', since.toIso8601String());
      }
      final rows = await query.order('start_time', ascending: false);
      return (rows as List).map((row) {
        final r = Map<String, dynamic>.from(row as Map);
        return HealthEvent(
          id: r['id'] as String?,
          metric: r['metric'] as String,
          value: (r['value'] as num).toDouble(),
          unit: r['unit'] as String,
          start: DateTime.parse(r['start_time'] as String),
          end: DateTime.parse(r['end_time'] as String),
          source: r['source'] as String,
          sourceRecordId: r['source_record_id'] as String? ?? '',
          quality: (r['quality'] as num?)?.toDouble() ?? 1.0,
          modelVersion: r['model_version'] as String? ?? 'recovery-0.1.0',
          metadata: Map<String, dynamic>.from(r['metadata'] as Map? ?? {}),
        );
      }).toList();
    } catch (e) {
      debugPrint('[SupabaseRepository] fetchHealthEvents error: $e');
      return [];
    }
  }

  @override
  Future<void> upsertScore({
    required String userId,
    required String scoreType,
    required double value,
    required double confidence,
    required List<Map<String, dynamic>> drivers,
    required Map<String, dynamic> inputs,
    required String modelVersion,
    required DateTime computedForDate,
  }) async {
    if (!isConfigured || _client == null) return;

    final dateStr = '${computedForDate.year}-${computedForDate.month.toString().padLeft(2, '0')}-${computedForDate.day.toString().padLeft(2, '0')}';
    final payload = {
      'user_id': userId,
      'score_type': scoreType,
      'value': value,
      'confidence': confidence,
      'drivers': drivers,
      'inputs': inputs,
      'model_version': modelVersion,
      'computed_for_date': dateStr,
    };

    try {
      await _client!.from('scores').upsert(
        payload,
        onConflict: 'user_id,score_type,computed_for_date',
      );
    } catch (e) {
      debugPrint('[SupabaseRepository] upsertScore error: $e');
    }
  }

  @override
  Future<void> recordHabitLog({
    required String userId,
    required String behaviorKey,
    required bool value,
    required DateTime loggedAt,
  }) async {
    if (!isConfigured || _client == null) return;
    try {
      await _client!.from('habit_logs').insert({
        'user_id': userId,
        'behavior_key': behaviorKey,
        'value': value,
        'logged_at': loggedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseRepository] recordHabitLog error: $e');
    }
  }

  @override
  Future<void> saveJournalEntry({
    required String userId,
    required String content,
    required String entryType,
    required String? mood,
    List<String> tags = const [],
  }) async {
    if (!isConfigured || _client == null) return;
    try {
      await _client!.from('journal_entries').insert({
        'user_id': userId,
        'content': content,
        'entry_type': entryType,
        'mood': mood,
        'tags': tags,
      });
    } catch (e) {
      debugPrint('[SupabaseRepository] saveJournalEntry error: $e');
    }
  }

  @override
  Future<void> recordCheckIn({
    required String userId,
    required String checkInType,
    required int energy,
    required int soreness,
    required bool illnessFlag,
    required int stress,
    required int sleepQuality,
  }) async {
    if (!isConfigured || _client == null) return;
    try {
      await _client!.from('check_ins').insert({
        'user_id': userId,
        'check_in_type': checkInType,
        'energy': energy,
        'soreness': soreness,
        'illness_flag': illnessFlag,
        'stress': stress,
        'sleep_quality': sleepQuality,
      });
    } catch (e) {
      debugPrint('[SupabaseRepository] recordCheckIn error: $e');
    }
  }
}
