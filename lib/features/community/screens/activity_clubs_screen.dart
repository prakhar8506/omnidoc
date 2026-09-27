import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/holographic_background.dart';

class ActivityClubsScreen extends StatelessWidget {
  const ActivityClubsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final sharing = appState.shareActivityForCompetition;
        return Scaffold(
          body: HolographicBackground(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                      Expanded(child: Text('Clubs & ranks', style: AppTypography.editorialSm)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    borderRadius: 20,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Share activity in competitions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: const Text(
                        'Off means you cannot see other people\'s activity or join friendly competitions.',
                        style: TextStyle(fontSize: 12, height: 1.35),
                      ),
                      value: sharing,
                      onChanged: appState.setShareActivityForCompetition,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!sharing)
                    const GlassContainer(
                      padding: EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Text(
                        'Activity sharing is off. Your club scores stay hidden until you turn sharing back on.',
                        style: TextStyle(height: 1.4),
                      ),
                    )
                  else ...[
                    Text(
                      'Your week score: ${appState.activityPoints} points from steps, meals, and workouts.',
                      style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _createClub(context),
                            child: const Text('Create club'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _joinClub(context),
                            child: const Text('Join with code'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (appState.clubs.isEmpty)
                      const GlassContainer(
                        padding: EdgeInsets.all(16),
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No clubs yet',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Create a club and share the code with people you know. '
                              'Everyone competes with their own steps and meals — no medical details are shared.',
                              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ...appState.clubs.map((club) => _clubCard(context, club)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _clubCard(BuildContext context, Map<String, dynamic> club) {
    final code = club['code']?.toString() ?? '';
    final name = club['name']?.toString() ?? 'Club';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('You · ${appState.activityPoints} pts this week', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              'Friends who join with this code compete using their own steps and meals on their phone.',
              style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Join my private Cura health club "$name". '
                          'Open Cura, go to Clubs, and enter code $code. '
                          'We can compare steps and meals without sharing medical reports.',
                      subject: 'Join my Cura club $name',
                    ),
                  );
                },
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Invite friends', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Opens WhatsApp, Gmail, or any share app',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createClub(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ClubTextDialog(
        title: 'New club',
        label: 'Club name',
        hint: 'Morning walk group',
        action: 'Create',
      ),
    );
    if (name != null && name.isNotEmpty) {
      appState.createClub(name);
    }
  }

  Future<void> _joinClub(BuildContext context) async {
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ClubTextDialog(
        title: 'Join a club',
        label: 'Invite code',
        action: 'Join',
        uppercase: true,
      ),
    );
    if (code == null || !context.mounted) return;
    final ok = appState.joinClub(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'You joined the club.' : 'That code was not found.')),
    );
  }
}

class _ClubTextDialog extends StatefulWidget {
  const _ClubTextDialog({
    required this.title,
    required this.label,
    required this.action,
    this.hint,
    this.uppercase = false,
  });

  final String title;
  final String label;
  final String action;
  final String? hint;
  final bool uppercase;

  @override
  State<_ClubTextDialog> createState() => _ClubTextDialogState();
}

class _ClubTextDialogState extends State<_ClubTextDialog> {
  late final TextEditingController _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _text.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter ${widget.label.toLowerCase()}.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            textCapitalization: widget.uppercase ? TextCapitalization.characters : TextCapitalization.words,
            decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.accentCoral, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.action)),
      ],
    );
  }
}
