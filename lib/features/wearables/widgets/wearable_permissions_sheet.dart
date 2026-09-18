import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../../core/state/app_state.dart';
import '../services/wearable_service.dart';

/// Apple / Google Compliant Transparent Permissions Explanation Modal
class WearablePermissionsSheet extends StatelessWidget {
  final AppState appState;

  const WearablePermissionsSheet({
    super.key,
    required this.appState,
  });

  static Future<void> show(BuildContext context, AppState appState) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WearablePermissionsSheet(appState: appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: AppColors.dockShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with HealthKit / Health Connect Icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.accentRose, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync Health & Wearables', style: AppTypography.editorialSm),
                    const SizedBox(height: 2),
                    Text(
                      'Apple HealthKit & Google Health Connect',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Cura requests read access via Apple HealthKit (iOS) or Google Health Connect (Android). '
            'Your health data stays encrypted on your device and is never sold to third parties.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 18),

          // Permissions Explanation List
          _buildPermissionRow(
            icon: Icons.favorite_rounded,
            color: AppColors.watchHeartRate,
            title: 'Heart Rate & Resting HR',
            reason: 'To compute your Daily Balance recovery score and detect elevated cardiovascular stress.',
          ),
          const SizedBox(height: 12),
          _buildPermissionRow(
            icon: Icons.nightlight_round,
            color: AppColors.watchSleep,
            title: 'Sleep Architecture (REM/Deep)',
            reason: 'To calculate restorative sleep quality and correlate energy with your Feeling Journal.',
          ),
          const SizedBox(height: 12),
          _buildPermissionRow(
            icon: Icons.directions_walk_rounded,
            color: AppColors.watchActivity,
            title: 'Steps & Daily Movement',
            reason: 'To gauge physical activity levels and support non-sensitive community streak goals.',
          ),
          const SizedBox(height: 12),
          _buildPermissionRow(
            icon: Icons.air_rounded,
            color: AppColors.watchSpO2,
            title: 'Blood Oxygen (SpO2)',
            reason: 'To verify respiratory wellness baseline during rest and recovery periods.',
          ),
          const SizedBox(height: 24),

          // Connect Button
          BouncingTap(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await WearableService.requestAuthorization();
              if (success) {
                final source = WearableService.platformSourceLabel;
                appState.connectWearable(source, source);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Connected to $source successfully.'),
                    backgroundColor: AppColors.accentTeal,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      WearableService.isPlatformSupported
                          ? 'Health permissions were denied. Enable access in system settings for HealthKit / Health Connect.'
                          : 'Health sync requires iOS (HealthKit) or Android (Health Connect).',
                    ),
                    backgroundColor: AppColors.accentCoral,
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Authorize Health Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Works with Apple HealthKit • Google Health Connect',
              style: AppTypography.labelSm.copyWith(color: AppColors.textTertiary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String reason,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reason,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
