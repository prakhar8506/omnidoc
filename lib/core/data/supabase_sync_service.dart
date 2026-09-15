import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/supabase_repository.dart';
import 'event_store.dart';

/// Non-blocking, offline-first background synchronizer.
/// Reconciles local EventStore data with Supabase whenever network connectivity exists.
class SupabaseSyncService {
  final HealthBackendRepository repository;
  final EventStore eventStore;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  SupabaseSyncService({
    required this.repository,
    required this.eventStore,
  });

  /// Flushes pending local health events to Supabase in the background.
  /// Never throws or blocks the caller; returns count of synchronized records.
  Future<int> syncPendingEvents(String userId) async {
    if (_isSyncing) return 0;
    if (!repository.isConfigured) return 0;

    _isSyncing = true;
    try {
      final allEvents = eventStore.getAllEvents();
      if (allEvents.isEmpty) return 0;

      // Upsert to Supabase in batches of 50
      int syncedCount = 0;
      const batchSize = 50;
      for (int i = 0; i < allEvents.length; i += batchSize) {
        final end = (i + batchSize < allEvents.length) ? i + batchSize : allEvents.length;
        final batch = allEvents.sublist(i, end);
        final added = await repository.upsertHealthEvents(userId, batch);
        syncedCount += added;
      }

      _lastSyncTime = DateTime.now();
      debugPrint('[SupabaseSyncService] Synced $syncedCount health events to Supabase.');
      return syncedCount;
    } catch (e) {
      debugPrint('[SupabaseSyncService] Background sync error (non-fatal): $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }

  /// Pulls remote events down into the local EventStore (idempotent, conflict-resolved).
  Future<int> pullRemoteEvents(String userId, {DateTime? since}) async {
    if (!repository.isConfigured) return 0;

    try {
      final remoteEvents = await repository.fetchHealthEvents(userId, since: since);
      if (remoteEvents.isEmpty) return 0;

      final recordedCount = await eventStore.recordEvents(remoteEvents);
      debugPrint('[SupabaseSyncService] Ingested $recordedCount new remote events into local store.');
      return recordedCount;
    } catch (e) {
      debugPrint('[SupabaseSyncService] Remote pull error (non-fatal): $e');
      return 0;
    }
  }
}
