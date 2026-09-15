import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/consent/consent_manager.dart';
import '../../../core/state/app_state.dart';

class PermissionCenterScreen extends StatelessWidget {
  final AppState appState;

  const PermissionCenterScreen({super.key, required this.appState});

  IconData _iconForCategory(PermissionCategory cat) {
    switch (cat) {
      case PermissionCategory.hrv:
        return Icons.show_chart_rounded;
      case PermissionCategory.heartRate:
        return Icons.favorite_rounded;
      case PermissionCategory.sleep:
        return Icons.bedtime_rounded;
      case PermissionCategory.steps:
        return Icons.directions_walk_rounded;
      case PermissionCategory.bloodOxygen:
        return Icons.air_rounded;
      case PermissionCategory.respiratoryRate:
        return Icons.waves_rounded;
      case PermissionCategory.location:
        return Icons.location_on_rounded;
      case PermissionCategory.notifications:
        return Icons.notifications_active_rounded;
    }
  }

  Color _colorForCategory(PermissionCategory cat) {
    switch (cat) {
      case PermissionCategory.hrv:
        return const Color(0xFF6E5DF6);
      case PermissionCategory.heartRate:
        return const Color(0xFFFF5252);
      case PermissionCategory.sleep:
        return const Color(0xFF5C6BC0);
      case PermissionCategory.steps:
        return const Color(0xFF00E676);
      case PermissionCategory.bloodOxygen:
        return const Color(0xFF00E5FF);
      case PermissionCategory.respiratoryRate:
        return const Color(0xFF38BDF8);
      case PermissionCategory.location:
        return const Color(0xFFF59E0B);
      case PermissionCategory.notifications:
        return const Color(0xFFA855F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Consent & Permission Center', style: AppTypography.titleLg),
        centerTitle: false,
      ),
      body: HolographicBackground(
        child: ListenableBuilder(
          listenable: appState.consentManager,
          builder: (context, _) {
            final permissions = appState.consentManager.allPermissions;
            final qualityScore = appState.dataQualityService.computeDataQuality(appState.consentManager);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data Quality Hero Card
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (qualityScore.coveragePercentage >= 75
                                            ? AppColors.success
                                            : AppColors.warning)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    qualityScore.coveragePercentage >= 75
                                        ? Icons.verified_user_rounded
                                        : Icons.shield_outlined,
                                    color: qualityScore.coveragePercentage >= 75
                                        ? AppColors.success
                                        : AppColors.warning,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Data Quality & Coverage', style: AppTypography.titleMd),
                                    Text(
                                      qualityScore.statusLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: qualityScore.coveragePercentage >= 75
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '${qualityScore.coveragePercentage}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: qualityScore.coveragePercentage / 100.0,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              qualityScore.coveragePercentage >= 75 ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          qualityScore.description,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                        if (qualityScore.conflictWarning != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    qualityScore.conflictWarning!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Biometric & Sensor Permissions',
                    style: AppTypography.titleMd,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Least-privilege policy. You can toggle off any stream at any time. Turning off a metric stops new ingestion immediately.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // List of Permission Cards
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: permissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = permissions[index];
                      final icon = _iconForCategory(item.category);
                      final color = _colorForCategory(item.category);

                      return GlassContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            item.isEnabled ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                                            size: 13,
                                            color: item.isEnabled ? AppColors.success : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.isEnabled
                                                ? (item.lastSynced != null
                                                    ? 'Synced ${DateFormat('MMM d, h:mm a').format(item.lastSynced!)}'
                                                    : 'Active')
                                                : 'Ingestion Paused',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: item.isEnabled ? AppColors.textSecondary : AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: item.isEnabled,
                                  activeTrackColor: AppColors.primaryContainer,
                                  onChanged: (val) {
                                    appState.consentManager.toggleCategory(item.category, val);
                                    appState.onPermissionToggled(item.category, val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            if (item.dataGapWarning != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.dataGapWarning!,
                                      style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
