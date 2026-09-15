import 'dart:async';
import 'package:flutter/material.dart';
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
                  // App Bar
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
                          Text('Emergency Safety & Medical ID', style: AppTypography.editorialSm),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),

                  // Content Body
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Emergency Medical ID Hero Card
                        _buildMedicalIdCard(context),
                        const SizedBox(height: 18),

                        // Wearable Fall Detection Alert Card
                        _buildFallDetectionCard(context),
                        const SizedBox(height: 18),

                        // Allergies & Contraindications
                        _buildAllergiesCard(context),
                        const SizedBox(height: 18),

                        // Emergency Contacts
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CRITICAL MEDICAL ID',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentCoral, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appState.userName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentCoral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Blood ${appState.bloodType}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.accentCoral),
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
              const _MedicalIdField(label: 'Date of Birth', value: '14 May 1996'),
              const _MedicalIdField(label: 'Organ Donor', value: 'Registered (Yes)'),
              _MedicalIdField(label: 'Language', value: appState.currentLocale.languageCode.toUpperCase()),
            ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.accessibility_new_rounded, color: AppColors.watchHeartRate, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Wearable Fall Detection',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
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
            'When enabled, connected wearable accelerometers will sound an emergency siren upon detecting a hard impact, notifying designated family members if unresponsive for 30 seconds.',
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
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_rounded, color: AppColors.accentCoral, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Test Simulated Fall Alert',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentCoral),
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
          const Text('Allergies & Medical Warnings',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: appState.allergies.map((a) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentCoral.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accentCoral.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.accentCoral),
                    const SizedBox(width: 6),
                    Text(a, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentCoral)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Designated Emergency Contacts',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...appState.familyMembers.where((f) => f.emergencySosEnabled).map((f) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_in_talk_rounded, color: AppColors.accentTeal, size: 18),
                      const SizedBox(width: 10),
                      Text('${f.name} (${f.relation})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Text('SOS Proxy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentTeal)),
                ],
              ),
            );
          }),
        ],
      ),
    );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulation: Emergency SOS dispatched to Elena Jenkins!'),
                  backgroundColor: AppColors.accentCoral,
                ),
              );
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
                const Text(
                  'HARD IMPACT DETECTED',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notifying emergency contacts in $countdown seconds...',
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
                    child: const Text(
                      'I AM OKAY (CANCEL)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
