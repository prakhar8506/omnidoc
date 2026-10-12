import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/env/app_env.dart';
import '../../../core/models/family_member.dart';

class PendingFamilyInvite {
  const PendingFamilyInvite({required this.code, required this.relation});

  final String code;
  final String relation;
}

class FamilyInvitePreview {
  const FamilyInvitePreview({
    required this.code,
    required this.inviterName,
    required this.relation,
    required this.status,
  });

  final String code;
  final String inviterName;
  final String relation;
  final String status;
}

class FamilyCircleSnapshot {
  const FamilyCircleSnapshot({required this.members, required this.pending});

  final List<FamilyMember> members;
  final List<PendingFamilyInvite> pending;
}

class FamilyInviteService {
  static const unavailable =
      'Family invites need the cloud connection. Apply the family links migration and deploy the family-circle function, then try again.';

  static Future<String> create({
    required String userId,
    required String name,
    required String email,
    required String relation,
  }) async {
    final data = await _call({
      'action': 'create',
      'user_id': userId,
      'name': name,
      'email': email,
      'relation': relation,
    });
    final code = data['code'];
    if (code is! String || code.isEmpty) {
      throw StateError(unavailable);
    }
    return code;
  }

  static Future<FamilyInvitePreview> preview(String code) async {
    final data = await _call({'action': 'preview', 'code': code});
    return FamilyInvitePreview(
      code: code,
      inviterName: (data['inviter_name'] as String?) ?? 'A family member',
      relation: (data['relation'] as String?) ?? 'Family',
      status: (data['status'] as String?) ?? 'pending',
    );
  }

  static Future<void> accept({
    required String code,
    required String userId,
    required String name,
    required String email,
  }) async {
    await _call({
      'action': 'accept',
      'code': code,
      'user_id': userId,
      'name': name,
      'email': email,
    });
  }

  static Future<FamilyCircleSnapshot> list(String userId) async {
    final data = await _call({'action': 'list', 'user_id': userId});
    final members = <FamilyMember>[];
    final rawMembers = data['members'];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is! Map) continue;
        final memberId = item['member_id'] as String? ?? '';
        if (memberId.isEmpty) continue;
        members.add(FamilyMember(
          id: 'link-$memberId',
          name: (item['member_name'] as String?) ?? 'Family member',
          relation: (item['relation'] as String?) ?? 'Family',
          avatarUrl: '',
          accessLevel: 'Connected',
          ageAndGender: (item['member_email'] as String?) ?? '',
          linkedUserId: memberId,
          email: item['member_email'] as String?,
        ));
      }
    }
    final pending = <PendingFamilyInvite>[];
    final rawPending = data['pending'];
    if (rawPending is List) {
      for (final item in rawPending) {
        if (item is! Map) continue;
        final code = item['code'] as String? ?? '';
        if (code.isEmpty) continue;
        pending.add(PendingFamilyInvite(
          code: code,
          relation: (item['relation'] as String?) ?? 'Family',
        ));
      }
    }
    return FamilyCircleSnapshot(members: members, pending: pending);
  }

  static Future<void> remove({
    required String userId,
    required String memberId,
  }) async {
    await _call({
      'action': 'remove',
      'user_id': userId,
      'member_id': memberId,
    });
  }

  static String linkFor(String code) => 'cura://family-invite?code=$code';

  static String messageFor(String code, String relation) {
    final link = linkFor(code);
    return 'Join my family circle on Cura. I added you as my $relation. '
        'Open this link on the phone where Cura is installed:\n$link\n\n'
        'If the link does not open, install Cura, sign in, and paste this code: $code';
  }

  static Future<void> shareWhatsApp(String code, String relation) async {
    final text = messageFor(code, relation);
    final wa = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final opened = await launchUrl(wa, mode: LaunchMode.externalApplication);
    if (!opened) {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  static Future<void> copyLink(String code) async {
    await Clipboard.setData(ClipboardData(text: linkFor(code)));
  }

  static Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    if (!AppEnv.isSupabaseConfigured) {
      throw StateError(unavailable);
    }
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'family-circle',
        body: body,
      );
      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final error = map['error'];
        if (error is String && error.isNotEmpty) throw StateError(error);
        return map;
      }
      throw StateError(unavailable);
    } on StateError {
      rethrow;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] is String) {
        throw StateError(details['error'] as String);
      }
      throw StateError(unavailable);
    } catch (_) {
      throw StateError(unavailable);
    }
  }
}
