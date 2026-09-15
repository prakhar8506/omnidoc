import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../state/app_state.dart';
import 'avatar_image.dart';
import '../../features/family/screens/family_connect_screen.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final AppState appState;

  const GlassAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.appState,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPad + 8,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 20, 40, 0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Health Companion',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        appState.clearNotifications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              appState.appointments.isEmpty
                                  ? 'You are all caught up.'
                                  : 'Updates: lab report ready & next visit ${DateFormat('EEE h:mm a').format(appState.appointments.first.dateTime)}.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.surfaceCardDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (appState.unreadNotificationsCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showProfileDialog(context),
                child: AvatarImage(
                  imageUrl: appState.userAvatar,
                  initials: initialsFromName(appState.userName),
                  radius: 19,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarImage(
              imageUrl: appState.userAvatar,
              initials: initialsFromName(appState.userName),
              radius: 36,
            ),
            const SizedBox(height: 12),
            Text(appState.userName, style: AppTypography.titleLg),
            const SizedBox(height: 4),
            if (appState.userEmail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(appState.userEmail, style: AppTypography.labelSm),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Emergency Blood ID: ${appState.bloodType}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.surfaceContainerHigh),
            ListTile(
              dense: true,
              leading: const Icon(Icons.people_outline_rounded, color: AppColors.primaryContainer),
              title: const Text('Family Connectivity', style: AppTypography.bodyMd),
              subtitle: Text(
                '${appState.familyMembers.length} members connected',
                style: AppTypography.labelSm,
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
              onTap: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FamilyConnectScreen(appState: appState),
                  ),
                );
              },
            ),
            const ListTile(
              dense: true,
              leading: Icon(Icons.shield_outlined, color: AppColors.primaryContainer),
              title: Text('Privacy & Data', style: AppTypography.bodyMd),
              subtitle: Text('Local demo session • Not clinical care', style: AppTypography.labelSm),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.emergency_outlined, color: AppColors.primaryContainer),
              title: const Text('Emergency SOS Contact', style: AppTypography.bodyMd),
              subtitle: Text(
                appState.familyMembers.isNotEmpty
                    ? '${appState.familyMembers.first.name} (${appState.familyMembers.first.relation})'
                    : 'No emergency contact set',
                style: AppTypography.labelSm,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.surfaceContainerHigh),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentCoral,
                  side: BorderSide(color: AppColors.accentCoral.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  appState.signOut();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
