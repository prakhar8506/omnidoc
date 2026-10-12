import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/state/app_state.dart';

class EmergencySafetyScreen extends StatelessWidget {
  final AppState appState;

  const EmergencySafetyScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          body: HolographicBackground(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BouncingTap(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Emergency ID',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.editorialSm,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildMedicalIdCard(context),
                        const SizedBox(height: 18),
                        _buildFallDetectionCard(context),
                        const SizedBox(height: 18),
                        _buildAllergiesCard(context),
                        const SizedBox(height: 18),
                        _buildEmergencyContactsCard(context),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicalIdCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(22),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentCoral.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency_rounded, color: AppColors.accentCoral, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CRITICAL MEDICAL ID',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentCoral, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appState.userName,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentCoral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Blood ${appState.bloodType}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.accentCoral),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0x1A1C1A27)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MedicalIdField(
                label: 'Date of Birth',
                value: appState.dateOfBirth?.trim().isNotEmpty == true
                    ? appState.dateOfBirth!
                    : 'Not set',
              ),
              const _MedicalIdField(label: 'Organ Donor', value: 'Not set'),
              _MedicalIdField(label: 'Language', value: appState.currentLocale.languageCode.toUpperCase()),
            ],
          ),
          const SizedBox(height: 16),
          BouncingTap(
            onTap: () => _startEmergencyCallFlow(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accentCoral,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sos_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Emergency SOS Call',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallDetectionCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.accessibility_new_rounded, color: AppColors.watchHeartRate, size: 22),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Wearable Fall Detection',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: appState.isFallDetectionActive,
                activeTrackColor: AppColors.accentCoral,
                onChanged: (_) => appState.toggleFallDetection(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Optional preference only. Fall alerts require a connected wearable, OS motion/notification permissions, '
            'and at least one SOS-enabled family contact. Cura will not automatically notify family unless those '
            'are configured and a real alert path is available — use Emergency SOS Call to dial manually.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textSecondary.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 16),
          BouncingTap(
            onTap: () => _simulateFallTrigger(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentCoral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentCoral.withValues(alpha: 0.3)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.sensors_rounded, color: AppColors.accentCoral, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Practice dialer path (not a real fall sensor)',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentCoral),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Allergies & Medical Warnings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddAllergyDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (appState.allergies.isEmpty)
            Text(
              'No allergies listed. Add medications or food allergies for emergency responders.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: appState.allergies.map((a) {
                return InputChip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.accentCoral),
                  label: Text(
                    a,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentCoral),
                  ),
                  backgroundColor: AppColors.accentCoral.withValues(alpha: 0.10),
                  side: BorderSide(color: AppColors.accentCoral.withValues(alpha: 0.25)),
                  onDeleted: () => appState.removeAllergy(a),
                  deleteIconColor: AppColors.accentCoral,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddAllergyDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add allergy / warning'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Penicillin, Peanuts, Latex',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      appState.addAllergy(result);
    }
  }

  Widget _buildEmergencyContactsCard(BuildContext context) {
    final contacts = appState.emergencyContacts;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Emergency contacts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddContactDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (contacts.isEmpty)
            Text(
              'Add a name and phone number. It stays on this phone and can be dialed from SOS.',
              style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.textSecondary),
            )
          else
            ...contacts.map((contact) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: AppColors.accentTeal, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${contact.relation} · ${contact.phone}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Call',
                      onPressed: () => _dialNumber(context, contact.phone),
                      icon: const Icon(Icons.call_rounded, color: AppColors.accentTeal),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => appState.removeEmergencyContact(contact.id),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    final contact = await showDialog<_DraftContact>(
      context: context,
      builder: (ctx) => const _AddEmergencyContactDialog(),
    );
    if (contact == null) return;
    appState.addEmergencyContact(
      name: contact.name,
      phone: contact.phone,
      relation: contact.relation,
    );
  }

  Future<void> _startEmergencyCallFlow(BuildContext context) async {
    final contacts = appState.emergencyContacts;
    final names = contacts.map((c) => '${c.name} (${c.phone})').join('\n');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Confirm Emergency Call', style: AppTypography.titleMd),
        content: Text(
          contacts.isEmpty
              ? 'No saved contacts yet. You can still dial emergency services or type a number.'
              : 'Saved contacts:\n$names\n\nNext you can call one of them or type another number.',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (contacts.isNotEmpty && context.mounted) {
      final picked = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Call a saved contact', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              for (final contact in contacts)
                ListTile(
                  leading: const Icon(Icons.call_rounded),
                  title: Text(contact.name),
                  subtitle: Text(contact.phone),
                  onTap: () => Navigator.pop(ctx, contact.phone),
                ),
              ListTile(
                leading: const Icon(Icons.emergency_rounded),
                title: Text('Emergency services (112)'),
                onTap: () => Navigator.pop(ctx, '112'),
              ),
              ListTile(
                leading: const Icon(Icons.dialpad_rounded),
                title: Text('Type another number'),
                onTap: () => Navigator.pop(ctx, ''),
              ),
            ],
          ),
        ),
      );
      if (!context.mounted || picked == null) return;
      if (picked.isNotEmpty) {
        await _dialNumber(context, picked);
        return;
      }
    }

    if (!context.mounted) return;
    final phoneController = TextEditingController();
    final number = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Enter number to call', style: AppTypography.titleMd),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. 911 or +1 555 0100',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, phoneController.text.trim()),
            child: Text('Call'),
          ),
        ],
      ),
    );

    if (number == null || number.isEmpty || !context.mounted) return;
    await _dialNumber(context, number);
  }

  Future<void> _dialNumber(BuildContext context, String rawNumber) async {
    final digits = rawNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid phone number.'),
          backgroundColor: AppColors.accentCoral,
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open dialer for $digits'),
          backgroundColor: AppColors.accentCoral,
        ),
      );
    }
  }

  void _simulateFallTrigger(BuildContext context) {
    int countdown = 10;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (countdown > 1) {
              setDlgState(() => countdown--);
            } else {
              t.cancel();
              Navigator.pop(dlgCtx);
              _startEmergencyCallFlow(context);
            }
          });

          return AlertDialog(
            backgroundColor: const Color(0xFF1B1A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentCoral.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_rounded, color: AppColors.accentCoral, size: 48),
                ),
                const SizedBox(height: 18),
                Text(
                  'PRACTICE ALERT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a practice dialer path — not a real fall sensor. Opening emergency dial in $countdown seconds...',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                BouncingTap(
                  onTap: () {
                    timer?.cancel();
                    Navigator.pop(dlgCtx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'I AM OKAY (CANCEL)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MedicalIdField extends StatelessWidget {
  final String label;
  final String value;

  const _MedicalIdField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class _DraftContact {
  final String name;
  final String phone;
  final String relation;

  const _DraftContact({required this.name, required this.phone, required this.relation});
}

class _AddEmergencyContactDialog extends StatefulWidget {
  const _AddEmergencyContactDialog();

  @override
  State<_AddEmergencyContactDialog> createState() => _AddEmergencyContactDialogState();
}

class _AddEmergencyContactDialogState extends State<_AddEmergencyContactDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController(text: 'Family');
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Enter a name and phone number.');
      return;
    }
    Navigator.pop(
      context,
      _DraftContact(
        name: name,
        phone: phone,
        relation: _relation.text.trim().isEmpty ? 'Contact' : _relation.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add emergency contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: _relation,
            decoration: const InputDecoration(labelText: 'Relation'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: AppColors.accentCoral, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        TextButton(onPressed: _save, child: Text('Save')),
      ],
    );
  }
}
