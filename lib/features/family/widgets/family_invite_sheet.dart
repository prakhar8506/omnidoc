import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../services/family_invite_service.dart';

class FamilyInviteSheet {
  static const relations = ['Parent', 'Spouse', 'Child', 'Sibling', 'Caregiver'];

  static Future<void> show(BuildContext context, AppState appState) async {
    var relation = relations.first;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final ink = Theme.of(sheetContext).colorScheme.onSurface;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(sheetContext).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite to your family circle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 8),
                  Text(
                    'Send a link on WhatsApp. When they open it in Cura and accept, you both see each other under Family.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: ink.withValues(alpha: 0.72)),
                  ),
                  const SizedBox(height: 16),
                  Text('They are my', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in relations)
                        ChoiceChip(
                          label: Text(item),
                          selected: relation == item,
                          onSelected: (_) => setSheetState(() => relation = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _send(sheetContext, appState, relation, whatsApp: true),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Share on WhatsApp'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _send(sheetContext, appState, relation, whatsApp: false),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Copy invite link'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _send(
    BuildContext context,
    AppState appState,
    String relation, {
    required bool whatsApp,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final code = await appState.createFamilyInvite(relation);
      if (whatsApp) {
        await FamilyInviteService.shareWhatsApp(code, relation);
      } else {
        await FamilyInviteService.copyLink(code);
      }
      if (navigator.canPop()) navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(whatsApp
              ? 'Invite ready in WhatsApp. They appear here after they accept.'
              : 'Invite link copied. They appear here after they accept.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceCardDark,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e is StateError ? e.message : FamilyInviteService.unavailable),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceCardDark,
        ),
      );
    }
  }

  static bool _scheduled = false;

  static void presentIncoming(BuildContext context, AppState appState) {
    final invite = appState.incomingInvite;
    final error = appState.familyInviteError;
    if (_scheduled) return;
    if (invite == null && (error == null || error.isEmpty)) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
      if (!context.mounted) return;
      if (error != null && error.isNotEmpty) {
        appState.clearFamilyInviteError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
      }
      final current = appState.takeIncomingInvite();
      if (current == null || !context.mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final ink = Theme.of(dialogContext).colorScheme.onSurface;
          final already = current.status == 'accepted';
          return AlertDialog(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            title: Text(
              already ? 'Already connected' : 'Family invite',
              style: TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
            content: Text(
              already
                  ? '${current.inviterName} is already in a family circle from this link.'
                  : '${current.inviterName} invited you. On their side you are their ${current.relation.toLowerCase()}. If you accept, you both see each other in Family.',
              style: TextStyle(color: ink, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Not now'),
              ),
              if (!already)
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Accept'),
                ),
            ],
          );
        },
      );
      if (accepted == true) {
        try {
          await appState.acceptFamilyInvite(current.code);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${current.inviterName} is now in your family circle.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is StateError ? e.message : FamilyInviteService.unavailable),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      } finally {
        _scheduled = false;
      }
    });
  }
}
