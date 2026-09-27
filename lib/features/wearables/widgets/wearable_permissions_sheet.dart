import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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

  static const _healthChannel = MethodChannel('cura/health_connect');

  static Future<bool> openHealthSettings() async {
    try {
      if (kIsWeb) return false;
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final opened = await _healthChannel.invokeMethod<bool>('openPermissions');
          if (opened == true) return true;
        } catch (e) {
          debugPrint('[WearablePermissions] health connect intent: $e');
        }
        final play = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
        );
        if (await canLaunchUrl(play)) {
          return launchUrl(play, mode: LaunchMode.externalApplication);
        }
        return false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final healthUri = Uri.parse('x-apple-health://');
        if (await canLaunchUrl(healthUri)) {
          return launchUrl(healthUri, mode: LaunchMode.externalApplication);
        }
        return launchUrl(Uri.parse('App-prefs:HEALTH'), mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (_) {
      return false;
    }
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
                      WearableService.platformSourceLabel,
                      style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          BouncingTap(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await WearableService.requestAuthorization();
              if (success) {
                final source = WearableService.platformSourceLabel;
                appState.connectWearable(source, source);
                final syncMsg = await appState.syncVitals();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(syncMsg.isNotEmpty
                        ? syncMsg
                        : 'Connected to $source. Sync when you have samples.'),
                    backgroundColor: AppColors.accentTeal,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      WearableService.isPlatformSupported
                          ? 'Health permissions denied. Use Settings to enable Health Connect / HealthKit.'
                          : 'Health sync requires iOS (HealthKit) or Android (Health Connect).',
                    ),
                    backgroundColor: AppColors.accentCoral,
                    action: WearableService.isPlatformSupported
                        ? SnackBarAction(
                            label: 'Settings',
                            textColor: Colors.white,
                            onPressed: () {
                              openHealthSettings();
                            },
                          )
                        : null,
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await openHealthSettings();
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Open Health Connect (Android) or Health (iOS) to grant access.'),
                      backgroundColor: AppColors.accentCoral,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text(
                'Open Health Settings',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          child: Icon(icon, size: 16, color: color),
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
